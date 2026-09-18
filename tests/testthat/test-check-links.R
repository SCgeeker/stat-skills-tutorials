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
