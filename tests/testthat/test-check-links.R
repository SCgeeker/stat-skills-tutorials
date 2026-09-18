# tests/testthat/test-check-links.R
# ---------------------------------------------------------------------------
# 針對 tools/check-links.R 的純函式測試。
# TDD：本檔在 tools/check-links.R 存在對應函式之前應全數 FAIL（RED）。
# 全程用假 fetcher／假 wait 模擬網路行為，測試本身完全不連網。
# ---------------------------------------------------------------------------

source(file.path("..", "..", "tools", "check-links.R"), chdir = TRUE)

# ---------------------------------------------------------------------------
# collect_links
# ---------------------------------------------------------------------------

test_that("collect_links 依 url 去重，entries 欄列出字母序、逗號分隔的條目 id", {
  entries <- list(
    b_entry = list(links = list(
      list(title = "Shared page", url = "https://example.com/shared", license = "CC0", kind = "chapter")
    )),
    a_entry = list(links = list(
      list(title = "Shared page (dup title)", url = "https://example.com/shared", license = "CC0", kind = "chapter"),
      list(title = "Only in a", url = "https://example.com/only-a", license = "CC0", kind = "chapter")
    ))
  )
  links <- collect_links(entries)
  expect_s3_class(links, "data.frame")
  expect_equal(nrow(links), 2)
  expect_setequal(links$url, c("https://example.com/shared", "https://example.com/only-a"))

  shared_row <- links[links$url == "https://example.com/shared", ]
  expect_equal(shared_row$title, "Shared page") # 取第一次出現者
  expect_equal(shared_row$entries, "a_entry, b_entry")
})

test_that("collect_links 的 kind 缺省視為 chapter", {
  entries <- list(
    e1 = list(links = list(
      list(title = "No kind", url = "https://example.com/nokind", license = "CC0")
    ))
  )
  links <- collect_links(entries)
  expect_equal(links$kind, "chapter")
})

test_that("collect_links 對沒有 links 的條目不出錯，回傳 0 列", {
  entries <- list(e1 = list(links = list()), e2 = list())
  links <- collect_links(entries)
  expect_equal(nrow(links), 0)
})

# ---------------------------------------------------------------------------
# check_url：假 fetcher，全程不連網
# ---------------------------------------------------------------------------

#' 建立依序回傳指定結果的假 fetcher，並記錄每次呼叫用的 method
mk_fetch <- function(responses) {
  calls <- new.env()
  calls$i <- 0
  calls$methods <- character()
  fn <- function(url, method) {
    calls$i <- calls$i + 1
    calls$methods <- c(calls$methods, method)
    responses[[calls$i]]
  }
  attr(fn, "calls") <- calls
  fn
}

#' 建立記錄等待秒數序列的假 wait()，不真的睡覺
mk_wait_recorder <- function() {
  waited <- new.env()
  waited$secs <- numeric()
  fn <- function(s) {
    waited$secs <- c(waited$secs, s)
  }
  attr(fn, "waited") <- waited
  fn
}

test_that("check_url：200 -> ok", {
  fetch <- mk_fetch(list(
    list(code = 200L, final_url = "https://example.com/ok", error = NULL)
  ))
  res <- check_url("https://example.com/ok", fetch = fetch)
  expect_equal(res$status, "ok")
  expect_equal(res$code, 200L)
  expect_equal(res$attempts, 1)
})

test_that("check_url：轉址到不同網址 -> redirected，note 含 final_url", {
  fetch <- mk_fetch(list(
    list(code = 200L, final_url = "https://example.com/new-path", error = NULL)
  ))
  res <- check_url("https://example.com/old-path", fetch = fetch)
  expect_equal(res$status, "redirected")
  expect_equal(res$final_url, "https://example.com/new-path")
  expect_true(grepl("https://example.com/new-path", res$note, fixed = TRUE))
})

test_that("check_url：只差尾端斜線的轉址正規化後視為相同 -> ok", {
  fetch <- mk_fetch(list(
    list(code = 200L, final_url = "https://example.com/same/", error = NULL)
  ))
  res <- check_url("https://example.com/same", fetch = fetch)
  expect_equal(res$status, "ok")
})

test_that("check_url：404 -> broken，且只嘗試一次（不重試、不等待）", {
  fetch <- mk_fetch(list(
    list(code = 404L, final_url = "https://example.com/missing", error = NULL)
  ))
  wait_fn <- mk_wait_recorder()
  res <- check_url("https://example.com/missing", fetch = fetch, wait = wait_fn)
  expect_equal(res$status, "broken")
  expect_equal(res$code, 404L)
  expect_equal(res$attempts, 1)
  expect_equal(attr(wait_fn, "waited")$secs, numeric(0))
})

test_that("check_url：410 -> broken", {
  fetch <- mk_fetch(list(
    list(code = 410L, final_url = "https://example.com/gone", error = NULL)
  ))
  res <- check_url("https://example.com/gone", fetch = fetch)
  expect_equal(res$status, "broken")
  expect_equal(res$code, 410L)
})

test_that("check_url：405 -> 改用 GET 再試一次，成功後回傳 ok", {
  fetch <- mk_fetch(list(
    list(code = 405L, final_url = "https://example.com/head-blocked", error = NULL),
    list(code = 200L, final_url = "https://example.com/head-blocked", error = NULL)
  ))
  res <- check_url("https://example.com/head-blocked", fetch = fetch)
  expect_equal(res$status, "ok")
  expect_equal(attr(fetch, "calls")$methods, c("HEAD", "GET"))
})

test_that("check_url：502 兩次後 200 -> ok，attempts 為 3，等待序列為 backoff 前兩個值", {
  fetch <- mk_fetch(list(
    list(code = 502L, final_url = "https://example.com/flaky", error = NULL),
    list(code = 502L, final_url = "https://example.com/flaky", error = NULL),
    list(code = 200L, final_url = "https://example.com/flaky", error = NULL)
  ))
  wait_fn <- mk_wait_recorder()
  res <- check_url("https://example.com/flaky", fetch = fetch, retries = 3, wait = wait_fn,
                    backoff = c(2, 5, 10))
  expect_equal(res$status, "ok")
  expect_equal(res$attempts, 3)
  expect_equal(attr(wait_fn, "waited")$secs, c(2, 5))
})

test_that("check_url：持續 503 -> unavailable（不是 broken），attempts 為 retries+1", {
  fetch <- mk_fetch(list(
    list(code = 503L, final_url = "https://example.com/down", error = NULL),
    list(code = 503L, final_url = "https://example.com/down", error = NULL),
    list(code = 503L, final_url = "https://example.com/down", error = NULL),
    list(code = 503L, final_url = "https://example.com/down", error = NULL)
  ))
  res <- check_url("https://example.com/down", fetch = fetch, retries = 3,
                    wait = function(s) invisible(NULL), backoff = c(2, 5, 10))
  expect_equal(res$status, "unavailable")
  expect_equal(res$attempts, 4)
  expect_false(identical(res$status, "broken"))
})

test_that("check_url：網路錯誤持續 -> unavailable", {
  fetch <- mk_fetch(list(
    list(code = NA_integer_, final_url = "https://example.com/err", error = "Could not resolve host"),
    list(code = NA_integer_, final_url = "https://example.com/err", error = "Could not resolve host"),
    list(code = NA_integer_, final_url = "https://example.com/err", error = "Could not resolve host"),
    list(code = NA_integer_, final_url = "https://example.com/err", error = "Could not resolve host")
  ))
  res <- check_url("https://example.com/err", fetch = fetch, retries = 3,
                    wait = function(s) invisible(NULL))
  expect_equal(res$status, "unavailable")
  expect_true(is.na(res$code))
  expect_equal(res$attempts, 4)
})

# ---------------------------------------------------------------------------
# check_all
# ---------------------------------------------------------------------------

test_that("check_all 逐一檢查並補上 status/code/final_url/attempts/note 欄位", {
  links_df <- data.frame(
    url = c("https://example.com/a", "https://example.com/b"),
    title = c("A", "B"),
    kind = c("chapter", "chapter"),
    entries = c("e1", "e2"),
    stringsAsFactors = FALSE
  )
  fake_check <- function(url, ...) {
    if (url == "https://example.com/a") {
      list(status = "ok", code = 200L, final_url = url, attempts = 1, note = "")
    } else {
      list(status = "broken", code = 404L, final_url = url, attempts = 1, note = "HTTP 404")
    }
  }
  results <- check_all(links_df, check = fake_check)
  expect_equal(nrow(results), 2)
  expect_true(all(c("url", "title", "kind", "entries", "status", "code", "final_url", "attempts", "note") %in%
                    names(results)))
  expect_equal(results$status, c("ok", "broken"))
  expect_equal(results$code, c(200L, 404L))
})

# ---------------------------------------------------------------------------
# format_report
# ---------------------------------------------------------------------------

test_that("format_report 先列 broken，再列 unavailable、redirected，最後一行彙總各狀態數量", {
  results <- data.frame(
    url = c("https://example.com/ok1", "https://example.com/broken1",
            "https://example.com/unavail1", "https://example.com/redir1"),
    title = c("OK1", "Broken1", "Unavail1", "Redir1"),
    kind = rep("chapter", 4),
    entries = c("e1", "e2", "e3", "e4"),
    status = c("ok", "broken", "unavailable", "redirected"),
    code = c(200L, 404L, NA_integer_, 200L),
    final_url = c("https://example.com/ok1", "https://example.com/broken1",
                   "https://example.com/unavail1", "https://example.com/redir1-new"),
    attempts = c(1, 1, 4, 1),
    note = c("", "HTTP 404", "重試 3 次後仍失敗", "轉址至 https://example.com/redir1-new"),
    stringsAsFactors = FALSE
  )
  report <- format_report(results)
  expect_type(report, "character")

  pos_broken <- regexpr("Broken1", report, fixed = TRUE)
  pos_unavail <- regexpr("Unavail1", report, fixed = TRUE)
  pos_redir <- regexpr("Redir1", report, fixed = TRUE)
  pos_summary <- regexpr("共 4 筆", report, fixed = TRUE)

  expect_true(pos_broken > 0)
  expect_true(pos_broken < pos_unavail)
  expect_true(pos_unavail < pos_redir)
  expect_true(pos_redir < pos_summary)

  last_line <- utils::tail(strsplit(report, "\n")[[1]], 1)
  expect_true(grepl("共 4 筆", last_line, fixed = TRUE))
})

test_that("format_report 加入 outdated 段落，順序為 broken、unavailable、outdated、redirected，彙總行含 outdated 數", {
  results <- data.frame(
    url = c("https://example.com/ok1", "https://example.com/broken1",
            "https://example.com/unavail1", "https://example.com/outdated1",
            "https://example.com/redir1"),
    title = c("OK1", "Broken1", "Unavail1", "Outdated1", "Redir1"),
    kind = rep("chapter", 5),
    entries = c("e1", "e2", "e3", "e4", "e5"),
    status = c("ok", "broken", "unavailable", "outdated", "redirected"),
    code = c(200L, 404L, NA_integer_, 200L, 200L),
    final_url = c("https://example.com/ok1", "https://example.com/broken1",
                   "https://example.com/unavail1", "https://example.com/outdated1",
                   "https://example.com/redir1-new"),
    attempts = c(1, 1, 4, 1, 1),
    note = c("", "HTTP 404", "重試 3 次後仍失敗", "短網址已指向新版",
             "轉址至 https://example.com/redir1-new"),
    stringsAsFactors = FALSE
  )
  report <- format_report(results)

  pos_broken <- regexpr("Broken1", report, fixed = TRUE)
  pos_unavail <- regexpr("Unavail1", report, fixed = TRUE)
  pos_outdated <- regexpr("Outdated1", report, fixed = TRUE)
  pos_redir <- regexpr("Redir1", report, fixed = TRUE)
  pos_summary <- regexpr("共 5 筆", report, fixed = TRUE)

  expect_true(pos_broken > 0)
  expect_true(pos_broken < pos_unavail)
  expect_true(pos_unavail < pos_outdated)
  expect_true(pos_outdated < pos_redir)
  expect_true(pos_redir < pos_summary)

  last_line <- utils::tail(strsplit(report, "\n")[[1]], 1)
  expect_true(grepl("共 5 筆", last_line, fixed = TRUE))
  expect_true(grepl("outdated 1", last_line, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# parse_meta_refresh
# ---------------------------------------------------------------------------

test_that("parse_meta_refresh：標準雙引號寫法", {
  html <- '<html><head><meta http-equiv="refresh" content="0; url=/analysis-v4/" /></head></html>'
  expect_equal(parse_meta_refresh(html), "/analysis-v4/")
})

test_that("parse_meta_refresh：單引號寫法", {
  html <- "<html><head><meta http-equiv='refresh' content='0; url=/analysis-v4/'></head></html>"
  expect_equal(parse_meta_refresh(html), "/analysis-v4/")
})

test_that("parse_meta_refresh：屬性順序對調（content 在前）", {
  html <- '<meta content="0;url=/analysis-v4/" http-equiv="refresh">'
  expect_equal(parse_meta_refresh(html), "/analysis-v4/")
})

test_that("parse_meta_refresh：大小寫不拘", {
  html <- '<META HTTP-EQUIV="Refresh" CONTENT="0; URL=/analysis-v4/">'
  expect_equal(parse_meta_refresh(html), "/analysis-v4/")
})

test_that("parse_meta_refresh：url= 前後有空白", {
  html <- '<meta http-equiv="refresh" content="0;  url =  /analysis-v4/ ">'
  expect_equal(parse_meta_refresh(html), "/analysis-v4/")
})

test_that("parse_meta_refresh：無自結尾斜線也可解析", {
  html <- '<meta http-equiv="refresh" content="0; url=/analysis-v4/">'
  expect_equal(parse_meta_refresh(html), "/analysis-v4/")
})

test_that("parse_meta_refresh：找不到 refresh meta 時回傳 NA", {
  html <- '<html><head><meta charset="utf-8"><title>頁面</title></head><body>沒有轉址</body></html>'
  expect_true(is.na(parse_meta_refresh(html)))
})

test_that("parse_meta_refresh：空字串回傳 NA", {
  expect_true(is.na(parse_meta_refresh("")))
})

# ---------------------------------------------------------------------------
# resolve_url
# ---------------------------------------------------------------------------

test_that("resolve_url：以 / 開頭的絕對路徑，接上 base 的 scheme+host", {
  res <- resolve_url("https://psyteachr.github.io/analysis-v3/07-independent.html", "/analysis-v4/")
  expect_equal(res, "https://psyteachr.github.io/analysis-v4/")
})

test_that("resolve_url：target 已是 http(s) 開頭則原樣回傳", {
  res <- resolve_url("https://psyteachr.github.io/analysis/", "https://other.example.com/x")
  expect_equal(res, "https://other.example.com/x")
})

test_that("resolve_url：其他相對路徑接在 base 的目錄後", {
  res <- resolve_url("https://psyteachr.github.io/analysis-v3/07-independent.html", "another.html")
  expect_equal(res, "https://psyteachr.github.io/analysis-v3/another.html")
})

# ---------------------------------------------------------------------------
# psyteachr_book
# ---------------------------------------------------------------------------

test_that("psyteachr_book：帶版本號的章節網址", {
  res <- psyteachr_book("https://psyteachr.github.io/analysis-v4/07-independent.html")
  expect_equal(res, list(book = "analysis", version = 4L))
})

test_that("psyteachr_book：書名含連字號", {
  res <- psyteachr_book("https://psyteachr.github.io/data-skills-v3/")
  expect_equal(res, list(book = "data-skills", version = 3L))
})

test_that("psyteachr_book：短網址（無版本號）回傳 NULL", {
  res <- psyteachr_book("https://psyteachr.github.io/analysis/")
  expect_null(res)
})

test_that("psyteachr_book：非 psyteachr 網址回傳 NULL", {
  res <- psyteachr_book("https://example.com/analysis-v4/")
  expect_null(res)
})

# ---------------------------------------------------------------------------
# check_version：全程用假 fetch_body，不連網
# ---------------------------------------------------------------------------

#' 建立記錄呼叫次數與參數的假 fetch_body()
mk_fetch_body_recorder <- function(handler) {
  calls <- new.env()
  calls$urls <- character()
  fn <- function(url) {
    calls$urls <- c(calls$urls, url)
    handler(url)
  }
  attr(fn, "calls") <- calls
  fn
}

test_that("check_version：短網址指向較新版 -> outdated", {
  fetch_body <- mk_fetch_body_recorder(function(url) {
    list(code = 200L, body = '<meta http-equiv="refresh" content="0; url=/analysis-v5/">', error = NULL)
  })
  res <- check_version("https://psyteachr.github.io/analysis-v4/07-independent.html", fetch_body = fetch_body)
  expect_equal(res$status, "outdated")
  expect_true(grepl("v5", res$note, fixed = TRUE))
  expect_true(grepl("v4", res$note, fixed = TRUE))
})

test_that("check_version：短網址指向相同版本 -> NULL", {
  fetch_body <- mk_fetch_body_recorder(function(url) {
    list(code = 200L, body = '<meta http-equiv="refresh" content="0; url=/analysis-v4/">', error = NULL)
  })
  res <- check_version("https://psyteachr.github.io/analysis-v4/07-independent.html", fetch_body = fetch_body)
  expect_null(res)
})

test_that("check_version：抓取失敗 -> NULL", {
  fetch_body <- mk_fetch_body_recorder(function(url) {
    list(code = NA_integer_, body = NA_character_, error = "Could not resolve host")
  })
  res <- check_version("https://psyteachr.github.io/analysis-v4/07-independent.html", fetch_body = fetch_body)
  expect_null(res)
})

test_that("check_version：非 psyteachr 版本網址 -> NULL，且不呼叫 fetch_body", {
  fetch_body <- mk_fetch_body_recorder(function(url) {
    list(code = 200L, body = "", error = NULL)
  })
  res <- check_version("https://example.com/foo-v2/", fetch_body = fetch_body)
  expect_null(res)
  expect_equal(length(attr(fetch_body, "calls")$urls), 0)
})

test_that("check_version：同一本書只抓一次（快取）", {
  fetch_body <- mk_fetch_body_recorder(function(url) {
    list(code = 200L, body = '<meta http-equiv="refresh" content="0; url=/analysis-v5/">', error = NULL)
  })
  cache <- new.env()
  res1 <- check_version("https://psyteachr.github.io/analysis-v4/07-independent.html",
                         fetch_body = fetch_body, cache = cache)
  res2 <- check_version("https://psyteachr.github.io/analysis-v4/01-intro.html",
                         fetch_body = fetch_body, cache = cache)
  expect_equal(res1$status, "outdated")
  expect_equal(res2$status, "outdated")
  expect_equal(length(attr(fetch_body, "calls")$urls), 1)
})

# ---------------------------------------------------------------------------
# check_all：整合 meta refresh 與 psyteachr 改版偵測（假 fetch_body，不連網）
# ---------------------------------------------------------------------------

test_that("check_all：狀態為 ok 且抓到 meta refresh -> redirected，note 含絕對網址", {
  links_df <- data.frame(
    url = c("https://example.com/shortlink"),
    title = c("Shortlink"),
    kind = c("chapter"),
    entries = c("e1"),
    stringsAsFactors = FALSE
  )
  fake_check <- function(url, ...) {
    list(status = "ok", code = 200L, final_url = url, attempts = 1, note = "")
  }
  fetch_body <- mk_fetch_body_recorder(function(url) {
    list(code = 200L, body = '<meta http-equiv="refresh" content="0; url=/new-path/">', error = NULL)
  })
  results <- check_all(links_df, check = fake_check, fetch_body = fetch_body)
  expect_equal(results$status, "redirected")
  expect_true(grepl("https://example.com/new-path/", results$note, fixed = TRUE))
})

test_that("check_all：狀態為 ok 且為 psyteachr 較新版章節 -> outdated", {
  links_df <- data.frame(
    url = c("https://psyteachr.github.io/analysis-v4/07-independent.html"),
    title = c("Independent"),
    kind = c("chapter"),
    entries = c("e1"),
    stringsAsFactors = FALSE
  )
  fake_check <- function(url, ...) {
    list(status = "ok", code = 200L, final_url = url, attempts = 1, note = "")
  }
  fetch_body <- mk_fetch_body_recorder(function(url) {
    if (identical(url, "https://psyteachr.github.io/analysis-v4/07-independent.html")) {
      # 章節網址本身沒有 meta refresh
      return(list(code = 200L, body = "<html><body>內容</body></html>", error = NULL))
    }
    # 短網址指向較新版
    list(code = 200L, body = '<meta http-equiv="refresh" content="0; url=/analysis-v5/">', error = NULL)
  })
  results <- check_all(links_df, check = fake_check, fetch_body = fetch_body)
  expect_equal(results$status, "outdated")
  expect_true(grepl("v5", results$note, fixed = TRUE))
})

test_that("check_all：非 ok 狀態的網址不呼叫 fetch_body", {
  links_df <- data.frame(
    url = c("https://example.com/broken"),
    title = c("Broken"),
    kind = c("chapter"),
    entries = c("e1"),
    stringsAsFactors = FALSE
  )
  fake_check <- function(url, ...) {
    list(status = "broken", code = 404L, final_url = url, attempts = 1, note = "HTTP 404")
  }
  fetch_body <- mk_fetch_body_recorder(function(url) {
    list(code = 200L, body = "", error = NULL)
  })
  results <- check_all(links_df, check = fake_check, fetch_body = fetch_body)
  expect_equal(results$status, "broken")
  expect_equal(length(attr(fetch_body, "calls")$urls), 0)
})
