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

# ---------------------------------------------------------------------------
# 以下為「語言標記」寫法（單站語言切換）新增測試。
# 站台由 assets/lang.css 依 <html> 的 lang-zh／lang-en class 決定顯示哪一種，
# 內容標記慣例：
#   - 標題／行內：[中文]{.zh}[English]{.en}
#   - 區塊：::: {.zh} ... ::: 與 ::: {.en} ... :::
# ---------------------------------------------------------------------------

#' 取出第一個指定語言 fenced div 的內容（不含 ::: 標記本身）
#' @param qmd character(1) qmd 全文
#' @param lang character(1) "zh" 或 "en"
#' @return character(1) div 內文字；找不到則為 NA_character_
extract_div <- function(qmd, lang) {
  pat <- sprintf("(?s)::: \\{\\.%s\\}\\n(.*?)\\n:::", lang)
  m <- regmatches(qmd, regexpr(pat, qmd, perl = TRUE))
  if (length(m) == 0 || identical(m, "")) return(NA_character_)
  sub(pat, "\\1", m, perl = TRUE)
}

test_that("render_entry_qmd 同時含 .zh 與 .en 語言標記", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  qmd <- render_entry_qmd(entry)
  expect_true(grepl("{.zh}", qmd, fixed = TRUE))
  expect_true(grepl("{.en}", qmd, fixed = TRUE))
})

test_that("render_entry_qmd 標題以 [中文]{.zh}[English]{.en} 行內標記呈現", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  qmd <- render_entry_qmd(entry)
  expect_true(grepl(sprintf("[%s]{.zh}[%s]{.en}", entry$title$zh, entry$title$en),
                    qmd, fixed = TRUE))
})

test_that("render_entry_qmd 的 scenario 中英文各自落在對應語言區塊", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  qmd <- render_entry_qmd(entry)
  zh_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.zh\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  en_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.en\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  expect_true(any(grepl(entry$scenario$zh, zh_blocks, fixed = TRUE)))
  expect_true(any(grepl(entry$scenario$en, en_blocks, fixed = TRUE)))
  expect_false(any(grepl(entry$scenario$en, zh_blocks, fixed = TRUE)))
  expect_false(any(grepl(entry$scenario$zh, en_blocks, fixed = TRUE)))
})

test_that("render_entry_qmd 的 prompt 中英文各自包在對應語言區塊內的程式碼框", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  qmd <- render_entry_qmd(entry)
  zh_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.zh\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  en_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.en\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  zh_with_prompt <- zh_blocks[grepl(entry$prompt$zh, zh_blocks, fixed = TRUE)]
  en_with_prompt <- en_blocks[grepl(entry$prompt$en, en_blocks, fixed = TRUE)]
  expect_true(length(zh_with_prompt) >= 1)
  expect_true(length(en_with_prompt) >= 1)
  expect_true(all(grepl("```", zh_with_prompt, fixed = TRUE)))
  expect_true(all(grepl("```", en_with_prompt, fixed = TRUE)))
  expect_false(any(grepl(entry$prompt$en, zh_blocks, fixed = TRUE)))
  expect_false(any(grepl(entry$prompt$zh, en_blocks, fixed = TRUE)))
})

test_that("render_entry_qmd 的 prerequisites 中英文各自落在對應語言區塊", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  qmd <- render_entry_qmd(entry)
  zh_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.zh\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  en_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.en\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  expect_true(any(grepl(entry$prerequisites[[1]]$zh, zh_blocks, fixed = TRUE)))
  expect_true(any(grepl(entry$prerequisites[[1]]$en, en_blocks, fixed = TRUE)))
  expect_false(any(grepl(entry$prerequisites[[1]]$en, zh_blocks, fixed = TRUE)))
  expect_false(any(grepl(entry$prerequisites[[1]]$zh, en_blocks, fixed = TRUE)))
})

test_that("render_entry_qmd 的 expected 中英文各自落在對應語言區塊", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  qmd <- render_entry_qmd(entry)
  zh_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.zh\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  en_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.en\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  expect_true(any(grepl(entry$expected[[1]]$zh, zh_blocks, fixed = TRUE)))
  expect_true(any(grepl(entry$expected[[1]]$en, en_blocks, fixed = TRUE)))
  expect_false(any(grepl(entry$expected[[1]]$en, zh_blocks, fixed = TRUE)))
  expect_false(any(grepl(entry$expected[[1]]$zh, en_blocks, fixed = TRUE)))
})

test_that("render_entry_qmd 的 check.what 中英文各自落在對應語言區塊，step 代號兩邊都在", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  qmd <- render_entry_qmd(entry)
  zh_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.zh\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  en_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.en\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  expect_true(any(grepl(entry$check[[1]]$what$zh, zh_blocks, fixed = TRUE)))
  expect_true(any(grepl(entry$check[[1]]$what$en, en_blocks, fixed = TRUE)))
  expect_false(any(grepl(entry$check[[1]]$what$en, zh_blocks, fixed = TRUE)))
  expect_false(any(grepl(entry$check[[1]]$what$zh, en_blocks, fixed = TRUE)))
  # step 代號語言中立，兩邊語言區塊都要看得到
  expect_true(any(grepl(entry$check[[1]]$step, zh_blocks, fixed = TRUE)))
  expect_true(any(grepl(entry$check[[1]]$step, en_blocks, fixed = TRUE)))
})

test_that("render_entry_qmd 的 stop_criteria 中英文各自落在對應語言區塊", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  qmd <- render_entry_qmd(entry)
  zh_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.zh\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  en_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.en\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  expect_true(any(grepl(entry$stop_criteria$solved$zh, zh_blocks, fixed = TRUE)))
  expect_true(any(grepl(entry$stop_criteria$solved$en, en_blocks, fixed = TRUE)))
  expect_true(any(grepl(entry$stop_criteria$reopen$zh, zh_blocks, fixed = TRUE)))
  expect_true(any(grepl(entry$stop_criteria$reopen$en, en_blocks, fixed = TRUE)))
  expect_false(any(grepl(entry$stop_criteria$solved$en, zh_blocks, fixed = TRUE)))
  expect_false(any(grepl(entry$stop_criteria$reopen$zh, en_blocks, fixed = TRUE)))
})

test_that("render_entry_qmd 語言中立欄位不被包進任一語言區塊", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  qmd <- render_entry_qmd(entry)
  zh_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.zh\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  en_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.en\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  all_blocks <- c(zh_blocks, en_blocks)

  neutral_values <- c(
    entry$analysis, entry$design, entry$stat_goal, entry$persona,
    entry$tested_with[[1]]$date, entry$tested_with[[1]]$provider,
    entry$tested_with[[1]]$model
  )
  for (v in neutral_values) {
    expect_false(any(grepl(v, all_blocks, fixed = TRUE)),
                 info = sprintf("語言中立欄位值 '%s' 不應出現在語言區塊內", v))
  }
  # 這些欄位仍應出現在 qmd 全文中（只是不被語言 div 包住）
  expect_true(grepl(entry$stat_goal, qmd, fixed = TRUE))
  expect_true(grepl(entry$persona, qmd, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# 「尚未實測」警語 callout。
# pending_notice() 是純函式：輸入所有條目、所有 tested_with 項目的 result
# 值，依「全部 pending／部分 pending／全部已測」三種狀態回傳 callout 的
# Markdown 全文（全部已測時回傳空字串 ""）。
# render_index_qmd() 應把對應的 R chunk（在 quarto render 當下才執行、依
# docs/prompts.json 現況判斷）嵌進總表頁，而不是寫死靜態文字。
# ---------------------------------------------------------------------------

test_that("pending_notice：全部 pending 時回傳「尚未實測」警語，中英皆有", {
  txt <- pending_notice(c("pending", "pending", "pending"))
  expect_type(txt, "character")
  expect_true(grepl("callout-warning", txt, fixed = TRUE))
  expect_true(grepl("{.zh}", txt, fixed = TRUE))
  expect_true(grepl("{.en}", txt, fixed = TRUE))
  expect_true(grepl("pending", txt, fixed = TRUE))
})

test_that("pending_notice：部分 pending 時回傳「部分已實測」措辭，且與全部 pending 的文字不同", {
  all_pending_txt <- pending_notice(c("pending", "pending"))
  partial_txt <- pending_notice(c("pending", "pass"))
  expect_type(partial_txt, "character")
  expect_true(grepl("callout-warning", partial_txt, fixed = TRUE))
  expect_true(grepl("{.zh}", partial_txt, fixed = TRUE))
  expect_true(grepl("{.en}", partial_txt, fixed = TRUE))
  expect_false(identical(partial_txt, all_pending_txt))
})

test_that("pending_notice：全部已實測時不印任何警語", {
  txt <- pending_notice(c("pass", "partial", "fail"))
  expect_equal(txt, "")
})

test_that("pending_notice：空輸入時不印任何警語", {
  expect_equal(pending_notice(character(0)), "")
})

test_that("render_index_qmd 嵌入依資料判斷的 R chunk，而非寫死的靜態警語文字", {
  dir <- test_path("fixtures", "read-entries-only5")
  dir.create(dir, showWarnings = FALSE)
  file.copy(fx("valid-entry.yaml"), file.path(dir, "valid-entry.yaml"), overwrite = TRUE)
  entries <- read_entries(dir)
  idx <- render_index_qmd(entries)

  # 必須是可執行的 R chunk（RED 前這裡不存在）
  expect_true(grepl("```{r}", idx, fixed = TRUE))
  expect_true(grepl("#| echo: false", idx, fixed = TRUE))
  expect_true(grepl("#| output: asis", idx, fixed = TRUE))
  expect_true(grepl("pending_notice", idx, fixed = TRUE))

  # 不應該把「尚未實測」的警語內文直接寫死進 qmd（那應該是 render 當下
  # 由 R chunk 執行 pending_notice() 才印出來的東西）
  expect_false(grepl("callout-warning", idx, fixed = TRUE))

  unlink(dir, recursive = TRUE)
})
