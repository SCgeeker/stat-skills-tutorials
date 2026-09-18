# tools/check-links.R
# ---------------------------------------------------------------------------
# 檢查所有提示詞條目（prompts/entries/*.yaml）裡 links 的網址是否仍可用。
#
# 純函式：collect_links / check_url / default_fetch / check_all / format_report
# 可被 tests/testthat 直接 source（測試一律注入假 fetcher，不觸網），
# 也可用 Rscript 當 CLI 執行。
#
# entries 的讀入沿用 tools/build-prompts.R 的 read_entries()，不另寫一份：
# CLI 進入點從本檔所在的 tools/ 目錄 source build-prompts.R。該檔的 CLI 區塊
# 只在直接執行時才跑，被 source 時不會觸發。純函式只接收 entries，不讀檔，
# 所以測試不需要 read_entries()。
#
# 為什麼不放進 quarto 的 pre-render：
#   這個工具本質上要連網才能檢查連結是否還在，跟 pre-render 其他步驟
#   （build-prompts.R／validate-prompts.R）要求「離線、快速、確定性」相衝突
#   ——連外部網站的回應時間、暫時性錯誤（如 OSF 502）都會拖慢或弄髒每次
#   render。因此改成手動執行，或另外排程（cron／CI 排程）定期執行。
#
# 用法（CLI，注意：這一步會連網）：
#   Rscript tools/check-links.R
#   讀入 prompts/entries/*.yaml、收集所有 links、逐一檢查，印出報告。
#   有任何 broken 連結時 exit code 1；unavailable／redirected 只是警告，
#   印出但不影響 exit code；全部 ok（或只有 redirected／unavailable）時
#   exit code 0。
# ---------------------------------------------------------------------------

suppressWarnings(suppressMessages({
  if (!requireNamespace("yaml", quietly = TRUE)) stop("需要 yaml 套件")
}))

# collect_links ----------------------------------------------------------------

#' 從 read_entries() 的結果收集所有條目的 links，依 url 去重
#' @param entries named list，來自 read_entries()（id 為 list 的 name）
#' @return data.frame，欄位 url／title（第一次出現者）／kind（缺省視為
#'   chapter）／entries（使用此網址的條目 id，字母序、逗號分隔）
collect_links <- function(entries) {
  urls <- character()
  titles <- character()
  kinds <- character()
  entries_for_url <- list()

  for (id in names(entries)) {
    links <- entries[[id]]$links
    if (is.null(links) || length(links) == 0) next
    for (l in links) {
      url <- l$url
      if (!(url %in% urls)) {
        urls <- c(urls, url)
        titles <- c(titles, l$title)
        kinds <- c(kinds, if (is.null(l$kind) || !nzchar(l$kind)) "chapter" else l$kind)
        entries_for_url[[url]] <- character()
      }
      entries_for_url[[url]] <- c(entries_for_url[[url]], id)
    }
  }

  entries_col <- vapply(urls, function(u) {
    paste(sort(unique(entries_for_url[[u]])), collapse = ", ")
  }, character(1), USE.NAMES = FALSE)

  data.frame(
    url = urls, title = titles, kind = kinds, entries = entries_col,
    stringsAsFactors = FALSE, row.names = NULL
  )
}

# check_url ----------------------------------------------------------------

#' 網址正規化（只處理尾端斜線），用來判斷轉址是否「實質不同」
#' @param u character(1)
#' @return character(1)
.normalize_url <- function(u) sub("/+$", "", u)

#' 檢查單一網址是否仍可用
#'
#' 判定規則：
#'   - 2xx：ok；final_url 正規化後與原網址不同時，改記 redirected，並把
#'     final_url 寫入 note。
#'   - 404、410 及其他 4xx：broken，不重試。
#'   - 例外：405（方法不允許）時改用 GET 再試一次，不消耗 retries 額度。
#'   - 5xx 或網路錯誤：依 backoff 等待後重試，最多 retries 次；最後仍失敗
#'     記 unavailable（不是 broken），note 註明嘗試次數，用來容忍如 OSF
#'     暫時性 502 這種會自行恢復的狀況。
#'
#' @param url character(1)
#' @param fetch function(url, method) -> list(code, final_url, error)；
#'   method 為 "HEAD" 或 "GET"
#' @param retries integer(1) 5xx／網路錯誤最多重試次數
#' @param wait function(seconds) 用來注入的等待函式（測試時傳入不真的睡覺者）
#' @param backoff numeric vector 每次重試前等待的秒數；超過長度時沿用最後一個值
#' @return list(status, code, final_url, attempts, note)
check_url <- function(url, fetch = default_fetch, retries = 3,
                       wait = function(s) Sys.sleep(s), backoff = c(2, 5, 10)) {
  method <- "HEAD"
  attempt_count <- 0
  retry_count <- 0

  repeat {
    attempt_count <- attempt_count + 1
    res <- fetch(url, method)
    code <- if (is.null(res$code)) NA_integer_ else res$code
    err <- res$error
    final_url <- if (!is.null(res$final_url)) res$final_url else url

    is_2xx <- is.null(err) && !is.na(code) && code >= 200 && code < 300
    if (is_2xx) {
      if (!identical(.normalize_url(final_url), .normalize_url(url))) {
        return(list(
          status = "redirected", code = code, final_url = final_url,
          attempts = attempt_count, note = sprintf("轉址至 %s", final_url)
        ))
      }
      return(list(status = "ok", code = code, final_url = final_url,
                   attempts = attempt_count, note = ""))
    }

    # 405：改用 GET 再試一次，不算一次重試，也不進入下面的 broken／retry 判斷
    is_405 <- is.null(err) && !is.na(code) && code == 405
    if (is_405 && method == "HEAD") {
      method <- "GET"
      next
    }

    # 404、410 及其他 4xx：broken，不重試
    is_4xx <- is.null(err) && !is.na(code) && code >= 400 && code < 500
    if (is_4xx) {
      return(list(status = "broken", code = code, final_url = final_url,
                   attempts = attempt_count, note = sprintf("HTTP %d", code)))
    }

    # 走到這裡：5xx 或網路錯誤，準備依 backoff 等待後重試
    retry_count <- retry_count + 1
    if (retry_count > retries) {
      note <- if (!is.null(err)) {
        sprintf("重試 %d 次後仍失敗：%s", retries, err)
      } else {
        sprintf("重試 %d 次後仍失敗：HTTP %s", retries, code)
      }
      return(list(status = "unavailable", code = code, final_url = final_url,
                   attempts = attempt_count, note = note))
    }

    wait_idx <- min(retry_count, length(backoff))
    wait(backoff[wait_idx])
  }
}

# default_fetch ----------------------------------------------------------------

#' 預設的 fetch 實作：實際送出 HEAD／GET 請求，取得狀態碼與最終網址
#' 優先用 curl 套件（追蹤轉址、逾時 30 秒、帶 User-Agent；GET 時用
#' Range: bytes=0-0 只取檔案開頭，避免下載整檔）；若本機沒有 curl 套件，
#' 退回 base R 的 curlGetHeaders()。
#' @param url character(1)
#' @param method character(1) "HEAD" 或 "GET"
#' @return list(code, final_url, error)
default_fetch <- function(url, method = "HEAD") {
  ua <- "stat-skills-tutorials-link-checker/1.0"

  if (requireNamespace("curl", quietly = TRUE)) {
    h <- curl::new_handle(
      followlocation = TRUE,
      timeout = 30,
      useragent = ua
    )
    if (method == "HEAD") {
      curl::handle_setopt(h, nobody = TRUE)
    } else {
      curl::handle_setheaders(h, Range = "bytes=0-0")
    }
    out <- tryCatch({
      resp <- curl::curl_fetch_memory(url, handle = h)
      list(code = as.integer(resp$status_code), final_url = resp$url, error = NULL)
    }, error = function(e) {
      list(code = NA_integer_, final_url = url, error = conditionMessage(e))
    })
    return(out)
  }

  # 退回 base R：curlGetHeaders() 沒有分 HEAD/GET，兩種方法都用它取標頭
  out <- tryCatch({
    headers <- curlGetHeaders(url, redirect = TRUE)
    status_line <- headers[1]
    code <- suppressWarnings(as.integer(sub("^HTTP/[0-9.]+\\s+([0-9]+).*", "\\1", status_line)))
    final_url <- attr(headers, "url")
    if (is.null(final_url)) final_url <- url
    list(code = code, final_url = final_url, error = NULL)
  }, error = function(e) {
    list(code = NA_integer_, final_url = url, error = conditionMessage(e))
  })
  out
}

# check_all ----------------------------------------------------------------

#' 逐一檢查 collect_links() 的結果，補上檢查結果欄位
#' @param links_df data.frame，來自 collect_links()
#' @param check function，預設 check_url；其餘參數（...）透傳給它
#' @return data.frame，links_df 加上 status/code/final_url/attempts/note 欄位
check_all <- function(links_df, check = check_url, ...) {
  n <- nrow(links_df)
  status <- character(n)
  code <- integer(n)
  final_url <- character(n)
  attempts <- integer(n)
  note <- character(n)

  for (i in seq_len(n)) {
    res <- check(links_df$url[i], ...)
    status[i] <- res$status
    code[i] <- if (is.null(res$code) || is.na(res$code)) NA_integer_ else res$code
    final_url[i] <- res$final_url
    attempts[i] <- res$attempts
    note[i] <- res$note
  }

  cbind(
    links_df,
    data.frame(status = status, code = code, final_url = final_url,
               attempts = attempts, note = note, stringsAsFactors = FALSE)
  )
}

# format_report ----------------------------------------------------------------

#' 把某個 status 的檢查結果列印成一段文字（含標題）
#' @param df data.frame，已篩選為單一 status 的子集
#' @param heading character(1) 這段的標題
#' @param tag character(1) 每一列前綴的標籤（如 "[BROKEN]"）
#' @return character(1)
.format_report_section <- function(df, heading, tag) {
  if (nrow(df) == 0) return(character())
  rows <- vapply(seq_len(nrow(df)), function(i) {
    sprintf("%s %s (%s) -- %s -- entries: %s",
            tag, df$url[i], df$title[i], df$note[i], df$entries[i])
  }, character(1))
  c(heading, rows, "")
}

#' 把 check_all() 的結果整理成文字報告
#' 順序：先列 broken，再列 unavailable、redirected，最後一行彙總各狀態數量。
#' @param results data.frame，來自 check_all()
#' @return character(1) 報告全文
format_report <- function(results) {
  lines <- character()

  lines <- c(lines, .format_report_section(
    results[results$status == "broken", , drop = FALSE],
    "== 已失效（broken）==", "[BROKEN]"
  ))
  lines <- c(lines, .format_report_section(
    results[results$status == "unavailable", , drop = FALSE],
    "== 暫時無法連線（unavailable）==", "[UNAVAILABLE]"
  ))
  lines <- c(lines, .format_report_section(
    results[results$status == "redirected", , drop = FALSE],
    "== 已轉址（redirected）==", "[REDIRECTED]"
  ))

  status_levels <- c("ok", "redirected", "unavailable", "broken")
  tbl <- table(factor(results$status, levels = status_levels))
  summary_line <- sprintf(
    "共 %d 筆：ok %d、redirected %d、unavailable %d、broken %d",
    nrow(results), tbl[["ok"]], tbl[["redirected"]], tbl[["unavailable"]], tbl[["broken"]]
  )
  lines <- c(lines, summary_line)

  paste(lines, collapse = "\n")
}

# CLI 進入點 ----------------------------------------------------------------
if (identical(environment(), globalenv()) && sys.nframe() == 0 && !interactive()) {
  file_arg <- grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  this_file <- normalizePath(sub("--file=", "", file_arg))
  base_dir <- normalizePath(file.path(dirname(this_file), ".."))
  entries_dir <- file.path(base_dir, "prompts", "entries")

  # 沿用 build-prompts.R 的 read_entries()，避免兩份讀檔邏輯各自演變
  source(file.path(dirname(this_file), "build-prompts.R"), encoding = "UTF-8")

  cat(sprintf("讀入條目目錄：%s\n", entries_dir))
  entries <- read_entries(entries_dir)
  cat(sprintf("共讀入 %d 條條目：%s\n", length(entries), paste(names(entries), collapse = ", ")))

  links_df <- collect_links(entries)
  cat(sprintf("共 %d 個不重複網址待檢查（連網中，請稍候）...\n", nrow(links_df)))

  results <- check_all(links_df)
  cat("\n")
  cat(format_report(results))
  cat("\n")

  if (any(results$status == "broken")) {
    quit(status = 1)
  } else {
    quit(status = 0)
  }
}
