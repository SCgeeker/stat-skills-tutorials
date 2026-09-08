# tests/testthat/test-build-prompts.R
# ---------------------------------------------------------------------------
# 針對 tools/build-prompts.R 的純函式測試。
# TDD：本檔在 tools/build-prompts.R 存在對應函式之前應全數 FAIL（RED）。
# ---------------------------------------------------------------------------

source(file.path("..", "..", "tools", "build-prompts.R"), chdir = TRUE)

fx <- function(name) {
  testthat::test_path("fixtures", name)
}

test_that("read_entries 讀入目錄下所有 yaml 並以 id 命名", {
  dir <- test_path("fixtures", "read-entries-only")
  dir.create(dir, showWarnings = FALSE)
  file.copy(fx("valid-entry.yaml"), file.path(dir, "valid-entry.yaml"), overwrite = TRUE)
  entries <- read_entries(dir)
  expect_type(entries, "list")
  expect_true("valid-entry" %in% names(entries))
  unlink(dir, recursive = TRUE)
})

test_that("build_prompts_json 產出的結構含每條的核心欄位", {
  dir <- test_path("fixtures", "read-entries-only2")
  dir.create(dir, showWarnings = FALSE)
  file.copy(fx("valid-entry.yaml"), file.path(dir, "valid-entry.yaml"), overwrite = TRUE)
  entries <- read_entries(dir)
  built <- build_prompts_json(entries)
  expect_type(built, "list")
  expect_equal(length(built), 1)
  expect_equal(built[[1]]$id, "valid-entry")
  expect_true(!is.null(built[[1]]$title$en))
  expect_true(!is.null(built[[1]]$prompt$zh))
  unlink(dir, recursive = TRUE)
})

test_that("write_prompts_json 寫出合法 JSON 且能被 jsonlite 讀回", {
  dir <- test_path("fixtures", "read-entries-only3")
  dir.create(dir, showWarnings = FALSE)
  file.copy(fx("valid-entry.yaml"), file.path(dir, "valid-entry.yaml"), overwrite = TRUE)
  out_path <- tempfile(fileext = ".json")
  entries <- read_entries(dir)
  write_prompts_json(entries, out_path)
  expect_true(file.exists(out_path))
  parsed <- jsonlite::fromJSON(out_path, simplifyVector = FALSE)
  expect_equal(length(parsed), 1)
  expect_equal(parsed[[1]]$id, "valid-entry")
  unlink(dir, recursive = TRUE)
  unlink(out_path)
})

test_that("render_index_qmd 合併所有條目且各自標題都在", {
  dir <- test_path("fixtures", "read-entries-only4")
  dir.create(dir, showWarnings = FALSE)
  file.copy(fx("valid-entry.yaml"), file.path(dir, "valid-entry.yaml"), overwrite = TRUE)
  entries <- read_entries(dir)
  idx <- render_index_qmd(entries)
  expect_type(idx, "character")
  expect_true(grepl("勿手動修改|Do not edit", idx))
  expect_true(grepl(entries[["valid-entry"]]$title$en, idx, fixed = TRUE))
  unlink(dir, recursive = TRUE)
})

test_that("render_entry_qmd 產出含中英文標題的 qmd 文字", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  qmd <- render_entry_qmd(entry)
  expect_type(qmd, "character")
  expect_true(grepl(entry$title$zh, qmd, fixed = TRUE))
  expect_true(grepl(entry$title$en, qmd, fixed = TRUE))
  expect_true(grepl(entry$prompt$zh, qmd, fixed = TRUE))
})
