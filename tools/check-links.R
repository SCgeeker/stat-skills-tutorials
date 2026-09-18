# tools/check-links.R
# ---------------------------------------------------------------------------
# 檢查所有提示詞條目（prompts/entries/*.yaml）裡 links 的網址是否仍可用。
#
# 純函式：collect_links / check_url / default_fetch / check_all / format_report
#   / parse_meta_refresh / resolve_url / psyteachr_book / default_fetch_body
#   / check_version
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
# meta refresh 轉址偵測：
#   有些短網址（例如 psyteachr 的章節短網址）不是用 HTTP 3xx 轉址，而是回
#   200 的網頁，網頁內容用 <meta http-equiv="refresh" content="N; url=...">
#   在瀏覽器端轉址。這種轉址用 HEAD／GET 的狀態碼看不出來，所以對
#   check_url() 判為 ok 的網址，check_all() 會額外抓一次網頁內容，解析有
#   沒有 meta refresh；若轉址目標與原網址不同，改記為 redirected。
#
# psyteachr 教材改版偵測（僅限 psyteachr，其他教材改版仍需人工注意）：
#   psyteachr 的教材網址帶版本號（如 .../analysis-v4/07-independent.html），
#   換版後短網址（.../analysis/）會用 meta refresh 指到最新版（如
#   .../analysis-v5/）。若連結用的版本號低於短網址目前指向的版本，代表
#   教材已改版、章節編號或內容可能已變動，記為 outdated（警告，不影響
#   exit code），提醒人工確認連結是否仍對應正確章節。此偵測邏輯專屬
#   psyteachr（網址格式為 https://psyteachr.github.io/<book>-v<N>/...），
#   其他教材站台的改版無法自動偵測，仍需人工留意。
#
# 用法（CLI，注意：這一步會連網）：
#   Rscript tools/check-links.R
#   讀入 prompts/entries/*.yaml、收集所有 links、逐一檢查，印出報告。
#   有任何 broken 連結時 exit code 1；unavailable／redirected／outdated
#   只是警告，印出但不影響 exit code；全部 ok（或只有這三種警告狀態）時
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

# parse_meta_refresh ----------------------------------------------------------------

#' 從 HTML 字串找出 <meta http-equiv="refresh" content="N; url=TARGET"> 的 TARGET
#' 容忍：大小寫、單雙引號、屬性順序對調、url= 前後空白、自結尾 />。
#' @param html character(1)
#' @return character(1) 轉址目標；沒有找到則回傳 NA_character_
parse_meta_refresh <- function(html) {
  if (is.null(html) || length(html) == 0 || is.na(html) || !nzchar(html)) return(NA_character_)

  # 抓出所有 <meta ...> 標籤（容忍跨行、大小寫、自結尾 />）
  tag_matches <- regmatches(html, gregexpr("<meta[^>]*>", html, ignore.case = TRUE, perl = TRUE))[[1]]
  if (length(tag_matches) == 0) return(NA_character_)

  for (tag in tag_matches) {
    is_refresh <- grepl("http-equiv\\s*=\\s*[\"']?refresh[\"']?", tag, ignore.case = TRUE, perl = TRUE)
    if (!is_refresh) next

    content_m <- regmatches(tag, regexec("content\\s*=\\s*[\"']([^\"']*)[\"']", tag,
                                          ignore.case = TRUE, perl = TRUE))[[1]]
    if (length(content_m) < 2) next
    content_val <- content_m[2]

    url_m <- regmatches(content_val, regexec("url\\s*=\\s*['\"]?\\s*([^'\";]+?)\\s*['\"]?\\s*$",
                                              content_val, ignore.case = TRUE, perl = TRUE))[[1]]
    if (length(url_m) >= 2 && nzchar(url_m[2])) return(url_m[2])
  }

  NA_character_
}

# resolve_url ----------------------------------------------------------------

#' 把相對於 base 的轉址目標轉為絕對網址
#' @param base character(1) 原始網址
#' @param target character(1) 轉址目標（可能是絕對網址、以 / 開頭的路徑、
#'   或其他相對路徑）
#' @return character(1) 絕對網址
resolve_url <- function(base, target) {
  if (grepl("^https?://", target, ignore.case = TRUE, perl = TRUE)) {
    return(target)
  }

  origin_m <- regmatches(base, regexec("^(https?://[^/]+)", base, ignore.case = TRUE, perl = TRUE))[[1]]
  origin <- if (length(origin_m) >= 2) origin_m[2] else ""

  if (grepl("^/", target)) {
    return(paste0(origin, target))
  }

  # 其他相對路徑：接在 base 的目錄後（去掉 base 最後一段檔名／保留結尾斜線）
  base_dir <- sub("/[^/]*$", "/", base)
  paste0(base_dir, target)
}

# psyteachr_book ----------------------------------------------------------------

#' 判斷網址是否為 psyteachr 帶版本號的教材網址
#' @param url character(1)
#' @return list(book = character(1), version = integer(1))；不符合則回傳 NULL
psyteachr_book <- function(url) {
  m <- regmatches(url, regexec("^https://psyteachr\\.github\\.io/(.+)-v([0-9]+)(?:/.*)?$",
                                url, perl = TRUE))[[1]]
  if (length(m) < 3) return(NULL)
  list(book = m[2], version = as.integer(m[3]))
}

# default_fetch_body ----------------------------------------------------------------

#' 預設的抓取網頁內容實作（取前面一小段，足夠解析 meta refresh 即可）
#' 優先用 curl 套件（追蹤轉址、逾時 30 秒、Range bytes=0-16383）；
#' 若本機沒有 curl 套件，退回 base R 的 url()＋readLines() 讀前幾行。
#' @param url character(1)
#' @return list(code, body, error)
default_fetch_body <- function(url) {
  ua <- "stat-skills-tutorials-link-checker/1.0"

  if (requireNamespace("curl", quietly = TRUE)) {
    h <- curl::new_handle(followlocation = TRUE, timeout = 30, useragent = ua)
    curl::handle_setheaders(h, Range = "bytes=0-16383")
    out <- tryCatch({
      resp <- curl::curl_fetch_memory(url, handle = h)
      body <- tryCatch(rawToChar(resp$content), error = function(e) {
        # Range 截斷可能切到多位元組字元中間，退而求其次去掉尾端無法轉換的位元組
        raw <- resp$content
        rawToChar(raw[seq_len(max(0, length(raw) - 4))])
      })
      list(code = as.integer(resp$status_code), body = body, error = NULL)
    }, error = function(e) {
      list(code = NA_integer_, body = NA_character_, error = conditionMessage(e))
    })
    return(out)
  }

  # 退回 base R：讀前幾行文字即可（足夠解析 <head> 內的 meta refresh）
  out <- tryCatch({
    con <- url(url)
    on.exit(close(con), add = TRUE)
    lines <- readLines(con, n = 200, warn = FALSE)
    list(code = 200L, body = paste(lines, collapse = "\n"), error = NULL)
  }, error = function(e) {
    list(code = NA_integer_, body = NA_character_, error = conditionMessage(e))
  })
  out
}

# check_version ----------------------------------------------------------------

#' 檢查 psyteachr 帶版本網址是否已被短網址的 meta refresh 指到更新版本
#' 同一本書（book）只抓一次短網址內容，用 cache 快取抓取結果。
#' @param url character(1) 帶版本號的章節網址
#' @param fetch_body function(url) -> list(code, body, error)
#' @param cache environment，用來快取「已抓過的書」，key 為 book 名稱
#' @return list(status = "outdated", note = character(1))；
#'   非 psyteachr、同版、抓取失敗或解析不到時回傳 NULL（不下判定）
check_version <- function(url, fetch_body = default_fetch_body, cache = new.env()) {
  info <- psyteachr_book(url)
  if (is.null(info)) return(NULL)

  book <- info$book
  n <- info$version
  short_url <- sprintf("https://psyteachr.github.io/%s/", book)

  if (exists(book, envir = cache, inherits = FALSE)) {
    cached <- get(book, envir = cache, inherits = FALSE)
  } else {
    cached <- fetch_body(short_url)
    assign(book, cached, envir = cache)
  }

  if (!is.null(cached$error)) return(NULL)
  if (is.null(cached$body) || length(cached$body) == 0 || is.na(cached$body)) return(NULL)

  target <- parse_meta_refresh(cached$body)
  if (is.na(target)) return(NULL)

  target_abs <- resolve_url(short_url, target)
  target_info <- psyteachr_book(target_abs)
  if (is.null(target_info)) return(NULL)

  m <- target_info$version
  if (m > n) {
    return(list(
      status = "outdated",
      note = sprintf("短網址 %s 已指向 v%d，此連結仍用 v%d", short_url, m, n)
    ))
  }

  NULL
}

# check_all ----------------------------------------------------------------

#' 逐一檢查 collect_links() 的結果，補上檢查結果欄位
#'
#' 對 check() 判為 ok 的網址，額外用 fetch_body() 抓網頁內容：
#'   1. 若解析到 meta refresh 且目標與原網址不同（正規化尾端斜線後比較），
#'      改記為 redirected，note 寫「meta refresh → 絕對網址」。
#'   2. 若仍為 ok，再跑 check_version()；判定 outdated 時改記為 outdated，
#'      note 沿用 check_version() 的說明。
#' 非 ok 的網址不做這兩項內容檢查。
#'
#' @param links_df data.frame，來自 collect_links()
#' @param check function，預設 check_url；其餘參數（...）透傳給它
#' @param fetch_body function(url) -> list(code, body, error)，預設
#'   default_fetch_body；測試時注入假函式，避免連網
#' @return data.frame，links_df 加上 status/code/final_url/attempts/note 欄位
check_all <- function(links_df, check = check_url, fetch_body = default_fetch_body, ...) {
  n <- nrow(links_df)
  status <- character(n)
  code <- integer(n)
  final_url <- character(n)
  attempts <- integer(n)
  note <- character(n)
  version_cache <- new.env()

  for (i in seq_len(n)) {
    url_i <- links_df$url[i]
    res <- check(url_i, ...)
    cur_status <- res$status
    cur_note <- res$note

    if (identical(cur_status, "ok")) {
      body_res <- fetch_body(url_i)
      if (is.null(body_res$error) && !is.null(body_res$body) &&
          length(body_res$body) > 0 && !is.na(body_res$body)) {
        refresh_target <- parse_meta_refresh(body_res$body)
        if (!is.na(refresh_target)) {
          abs_target <- resolve_url(url_i, refresh_target)
          if (!identical(.normalize_url(abs_target), .normalize_url(url_i))) {
            cur_status <- "redirected"
            cur_note <- sprintf("meta refresh \u2192 %s", abs_target)
          }
        }
      }
    }

    if (identical(cur_status, "ok")) {
      version_res <- check_version(url_i, fetch_body = fetch_body, cache = version_cache)
      if (!is.null(version_res) && identical(version_res$status, "outdated")) {
        cur_status <- "outdated"
        cur_note <- version_res$note
      }
    }

    status[i] <- cur_status
    code[i] <- if (is.null(res$code) || is.na(res$code)) NA_integer_ else res$code
    final_url[i] <- res$final_url
    attempts[i] <- res$attempts
    note[i] <- cur_note
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
#' 順序：broken、unavailable、outdated、redirected，最後一行彙總各狀態數量。
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
    results[results$status == "outdated", , drop = FALSE],
    "== 教材已改版（outdated）==", "[OUTDATED]"
  ))
  lines <- c(lines, .format_report_section(
    results[results$status == "redirected", , drop = FALSE],
    "== 已轉址（redirected）==", "[REDIRECTED]"
  ))

  status_levels <- c("ok", "redirected", "outdated", "unavailable", "broken")
  tbl <- table(factor(results$status, levels = status_levels))
  summary_line <- sprintf(
    "共 %d 筆：ok %d、redirected %d、outdated %d、unavailable %d、broken %d",
    nrow(results), tbl[["ok"]], tbl[["redirected"]], tbl[["outdated"]],
    tbl[["unavailable"]], tbl[["broken"]]
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
