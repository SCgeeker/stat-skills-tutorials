# tests/testthat/test-validate-prompts.R
# ---------------------------------------------------------------------------
# 針對 tools/validate-prompts.R 的純函式測試。
# TDD：本檔在 tools/validate-prompts.R 存在對應函式之前應全數 FAIL（RED）。
# ---------------------------------------------------------------------------

source(file.path("..", "..", "tools", "validate-prompts.R"), chdir = TRUE)

fx <- function(name) {
  testthat::test_path("fixtures", name)
}

test_that("合法條目通過驗證", {
  result <- validate_entry_file(fx("valid-entry.yaml"))
  expect_true(result$valid)
  expect_length(result$errors, 0)
})

test_that("缺英文欄位的條目被擋下", {
  result <- validate_entry_file(fx("missing-english.yaml"))
  expect_false(result$valid)
  expect_true(any(grepl("en", result$errors, ignore.case = TRUE)))
})

test_that("缺必填欄位（stop_criteria）的條目被擋下", {
  result <- validate_entry_file(fx("missing-required.yaml"))
  expect_false(result$valid)
  expect_true(any(grepl("stop_criteria", result$errors)))
})

test_that("非法 stat_goal 的條目被擋下", {
  result <- validate_entry_file(fx("bad-statgoal.yaml"))
  expect_false(result$valid)
  expect_true(any(grepl("stat_goal", result$errors)))
})

test_that("rtutor 條目缺 code-read/code-run 被擋下", {
  result <- validate_entry_file(fx("rtutor-missing-code-checks.yaml"))
  expect_false(result$valid)
  expect_true(any(grepl("code-read", result$errors) | grepl("code-run", result$errors)))
})

test_that("prompt 允許多行（Q4 已判定 question 欄以 textarea 承接、換行會送進 API）", {
  entry <- yaml::read_yaml(fx("trailing-blank-line.yaml"))
  entry$prompt$en <- "Line one.\nLine two.\n- criterion one\n- criterion two"
  result <- validate_entry(entry)
  # 多行本身不是錯誤；此條目其餘欄位皆合法，應通過驗證
  expect_true(result$valid)
})

test_that("prompt 結尾多餘空白行的條目被擋下", {
  result <- validate_entry_file(fx("trailing-blank-line.yaml"))
  expect_false(result$valid)
  expect_true(any(grepl("空白行|blank.line|trailing", result$errors, ignore.case = TRUE)))
})

test_that("check 少於 2 條的條目被擋下", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  entry$check <- entry$check[1]
  result <- validate_entry(entry)
  expect_false(result$valid)
  expect_true(any(grepl("check", result$errors, ignore.case = TRUE)))
})

test_that("tested_with 為空的條目被擋下", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  entry$tested_with <- list()
  result <- validate_entry(entry)
  expect_false(result$valid)
  expect_true(any(grepl("tested_with", result$errors, ignore.case = TRUE)))
})

test_that("id 與檔名不一致時被擋下", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  result <- validate_entry(entry, expected_id = "not-the-same-id")
  expect_false(result$valid)
  expect_true(any(grepl("id", result$errors, ignore.case = TRUE)))
})

test_that("prerequisites 缺英文的條目被擋下", {
  entry <- yaml::read_yaml(fx("missing-english-fields.yaml"))
  result <- validate_entry(entry)
  expect_false(result$valid)
  expect_true(any(grepl("prerequisites.*en", result$errors)))
})

test_that("expected 缺英文的條目被擋下", {
  entry <- yaml::read_yaml(fx("missing-english-fields.yaml"))
  result <- validate_entry(entry)
  expect_false(result$valid)
  expect_true(any(grepl("expected.*en", result$errors)))
})

test_that("check.what 缺英文的條目被擋下", {
  entry <- yaml::read_yaml(fx("missing-english-fields.yaml"))
  result <- validate_entry(entry)
  expect_false(result$valid)
  expect_true(any(grepl("check\\[\\d+\\]\\.what\\.en", result$errors)))
})

test_that("stop_criteria.solved/.reopen 缺英文的條目被擋下", {
  entry <- yaml::read_yaml(fx("missing-english-fields.yaml"))
  result <- validate_entry(entry)
  expect_false(result$valid)
  expect_true(any(grepl("stop_criteria\\.solved\\.en", result$errors)))
  expect_true(any(grepl("stop_criteria\\.reopen\\.en", result$errors)))
})

test_that("prerequisites 為雙語物件清單且皆完整時通過驗證", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  result <- validate_entry(entry)
  expect_true(result$valid)
  expect_length(result$errors, 0)
})

test_that("validate_all_entries 對目錄下所有合法條目回傳全 PASS", {
  dir <- test_path("fixtures", "valid-only")
  dir.create(dir, showWarnings = FALSE)
  file.copy(fx("valid-entry.yaml"), file.path(dir, "valid-entry.yaml"), overwrite = TRUE)
  summary <- validate_all_entries(dir)
  expect_true(all(summary$valid))
  unlink(dir, recursive = TRUE)
})
