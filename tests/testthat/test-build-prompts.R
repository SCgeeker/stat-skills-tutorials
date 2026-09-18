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

  # tested_with 的 date/provider/model 改由下方測試處理：它們在中英兩個區塊
  # 各列一次（兩種語言都看得到），因為中文 note 只能放進 .zh 區塊
  neutral_values <- c(entry$analysis, entry$design, entry$stat_goal, entry$persona)
  for (v in neutral_values) {
    expect_false(any(grepl(v, all_blocks, fixed = TRUE)),
                 info = sprintf("語言中立欄位值 '%s' 不應出現在語言區塊內", v))
  }
  # 這些欄位仍應出現在 qmd 全文中（只是不被語言 div 包住）
  expect_true(grepl(entry$stat_goal, qmd, fixed = TRUE))
  expect_true(grepl(entry$persona, qmd, fixed = TRUE))
})

#' 測試用：含中文 note 與證據路徑的 tested_with
mk_tested_entry <- function() {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  entry$tested_with <- list(list(
    date = "2026-09-18", provider = "gemini", model = "gemini-flash-latest", result = "pass",
    note = "zh 版，證據 data/x_zhTW.omv、回覆副本 data/replies/x_zhTW.md，[括號] 也在"
  ))
  entry
}

test_that("render_entry_qmd 的 tested_with 中文 note 只在 .zh 區塊，英文區塊列證據路徑", {
  qmd <- render_entry_qmd(mk_tested_entry())
  zh_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.zh\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  en_blocks <- unlist(regmatches(qmd, gregexpr("(?s)::: \\{\\.en\\}\\n.*?\\n:::", qmd, perl = TRUE)))
  expect_true(any(grepl("回覆副本 data/replies/x_zhTW.md", zh_blocks, fixed = TRUE)))
  expect_true(any(grepl("Evidence: `data/x_zhTW.omv`, `data/replies/x_zhTW.md`", en_blocks, fixed = TRUE)))
  expect_true(any(grepl("recorded in Chinese", en_blocks, fixed = TRUE)))
  # date/provider/model/result 兩種語言都看得到
  for (v in c("2026-09-18", "gemini-flash-latest", "**pass**")) {
    expect_true(any(grepl(v, zh_blocks, fixed = TRUE)), info = v)
    expect_true(any(grepl(v, en_blocks, fixed = TRUE)), info = v)
  }
})

test_that("render_entry_qmd 的 .en 區塊與語言中立處都不含中文字", {
  qmd <- render_entry_qmd(mk_tested_entry())
  no_zh <- gsub("(?s)::: \\{\\.zh\\}\\n.*?\\n:::", "", qmd, perl = TRUE)
  no_zh <- gsub("\\[[^]]*\\]\\{\\.zh\\}", "", no_zh, perl = TRUE)
  cjk <- regmatches(no_zh, gregexpr("[㐀-鿿＀-￯　-〿]+", no_zh, perl = TRUE))[[1]]
  expect_equal(cjk, character(0))
})

test_that("render_entry_qmd 的延伸閱讀用語言中立的分隔，不用全形括號", {
  entry <- yaml::read_yaml(fx("valid-entry.yaml"))
  entry$links <- list(list(title = "T", url = "http://t", license = "CC0"))
  qmd <- render_entry_qmd(entry)
  expect_true(grepl("- [T](http://t) · CC0", qmd, fixed = TRUE))
})

test_that("render_index_qmd 的頁首說明中英各自包進語言區塊", {
  dir <- test_path("fixtures", "read-entries-only6")
  dir.create(dir, showWarnings = FALSE)
  file.copy(fx("valid-entry.yaml"), file.path(dir, "valid-entry.yaml"), overwrite = TRUE)
  idx <- render_index_qmd(read_entries(dir))
  unlink(dir, recursive = TRUE)
  zh <- extract_div(idx, "zh")
  en <- extract_div(idx, "en")
  expect_true(grepl("請勿手動修改", zh, fixed = TRUE))
  expect_true(grepl("Do not edit this page by hand", en, fixed = TRUE))
  expect_true(grepl("title: \"[提示詞庫]{.zh}[Prompt Library]{.en}\"", idx, fixed = TRUE))
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

# ---------------------------------------------------------------------------
# 外部教材對照表（external/_reading-map-table.md）。
# link_kind()：讀單一 link 的 kind，缺省視同 chapter。
# render_reading_map_md()：依 entries 的 stat_goal x design 分組，產生「表一：
# Where to read」與「表二：Datasets used in the prompt library」兩張表格的
# Markdown；純函式，測試只用內建的最小條目 list，不依賴真實條目。
# write_reading_map()：把上面字串寫到檔案。
# ---------------------------------------------------------------------------

#' 建立測試用最小條目（不含 id；id 由 entries list 的 name 提供）
mk_entry <- function(stat_goal, design, links = list()) {
  list(stat_goal = stat_goal, design = design, links = links)
}

test_that("link_kind 缺省回傳 chapter，顯式設定時原樣回傳", {
  expect_equal(link_kind(list(title = "t", url = "u", license = "l")), "chapter")
  expect_equal(link_kind(list(title = "t", url = "u", license = "l", kind = "chapter")), "chapter")
  expect_equal(link_kind(list(title = "t", url = "u", license = "l", kind = "dataset")), "dataset")
})

test_that("render_reading_map_md 依 goal x design 分組，且依規定順序排序", {
  entries <- list(
    b = mk_entry("compare-2", "within",
                 links = list(list(title = "B chapter", url = "http://b", license = "CC0", kind = "chapter"))),
    a = mk_entry("screen", "none",
                 links = list(list(title = "A chapter", url = "http://a", license = "CC0", kind = "chapter"))),
    c = mk_entry("compare-2", "between",
                 links = list(list(title = "C chapter", url = "http://c", license = "CC0", kind = "chapter")))
  )
  md <- render_reading_map_md(entries)
  expect_true(grepl("## [該讀哪一章]{.zh}[Where to read]{.en}", md, fixed = TRUE))
  expect_true(grepl("Screen data before analysis", md, fixed = TRUE))
  expect_true(grepl("Compare two groups or conditions", md, fixed = TRUE))
  expect_true(grepl("Between-subjects", md, fixed = TRUE))
  expect_true(grepl("Within-subjects", md, fixed = TRUE))

  pos_screen <- regexpr("Screen data before analysis", md, fixed = TRUE)
  pos_between <- regexpr("Between-subjects", md, fixed = TRUE)
  pos_within <- regexpr("Within-subjects", md, fixed = TRUE)
  expect_true(pos_screen < pos_between)
  expect_true(pos_between < pos_within)
})

test_that("render_reading_map_md 的 Prompt entries 欄以反引號、字母序、逗號分隔", {
  entries <- list(
    zeta = mk_entry("screen", "none",
                     links = list(list(title = "Z chapter", url = "http://z", license = "CC0", kind = "chapter"))),
    alpha = mk_entry("screen", "none",
                      links = list(list(title = "Z chapter", url = "http://z", license = "CC0", kind = "chapter")))
  )
  md <- render_reading_map_md(entries)
  expect_true(grepl("`alpha`, `zeta`", md, fixed = TRUE))
})

test_that("render_reading_map_md 同組內 chapter 連結依 url 去重", {
  entries <- list(
    x1 = mk_entry("describe", "within",
                  links = list(list(title = "Same Chapter", url = "http://dup", license = "CC BY", kind = "chapter"))),
    x2 = mk_entry("describe", "within",
                  links = list(list(title = "Same Chapter", url = "http://dup", license = "CC BY", kind = "chapter")))
  )
  md <- render_reading_map_md(entries)
  matches <- regmatches(md, gregexpr("http://dup", md, fixed = TRUE))[[1]]
  expect_equal(length(matches), 1)
})

test_that("render_reading_map_md 該組沒有 chapter 時改列範例資料與實測檔位置，不出現待辦措辭", {
  entries <- list(
    y1 = mk_entry("predict", "none",
                  links = list(list(title = "Dataset Y", url = "http://data-y", license = "CC0", kind = "dataset")))
  )
  md <- render_reading_map_md(entries, data_dir_url = "http://example/data")
  table1_part <- sub("(?s)\n## [^\n]*Datasets used.*$", "", md, perl = TRUE)
  expect_true(grepl("Worked example in this library:", table1_part, fixed = TRUE))
  expect_true(grepl("[Dataset Y](http://data-y) · CC0", table1_part, fixed = TRUE))
  expect_true(grepl("Recorded test files: [data/ on GitHub](http://example/data)", table1_part, fixed = TRUE))
  expect_false(grepl("linked yet", md, fixed = TRUE))
})

test_that("render_reading_map_md 該組既無 chapter 也無 dataset 時只列實測檔位置", {
  entries <- list(
    v1 = mk_entry("screen", "none", links = list())
  )
  md <- render_reading_map_md(entries, data_dir_url = "http://example/data")
  expect_true(grepl("Recorded test files: [data/ on GitHub](http://example/data)", md, fixed = TRUE))
  expect_false(grepl("Worked example in this library:", md, fixed = TRUE))
  expect_false(grepl("linked yet", md, fixed = TRUE))
})

test_that("render_reading_map_md 的標籤與表頭中英並列", {
  entries <- list(
    a = mk_entry("screen", "none",
                 links = list(list(title = "A chapter", url = "http://a", license = "CC0"))),
    p = mk_entry("predict", "within",
                 links = list(list(title = "D", url = "http://d", license = "CC0", kind = "dataset")))
  )
  md <- render_reading_map_md(entries, data_dir_url = "http://example/data")
  expect_true(grepl("[分析前檢查資料]{.zh}[Screen data before analysis]{.en}", md, fixed = TRUE))
  expect_true(grepl("[無分組設計]{.zh}[No grouping design]{.en}", md, fixed = TRUE))
  expect_true(grepl("[受試者內]{.zh}[Within-subjects]{.en}", md, fixed = TRUE))
  expect_true(grepl("| [目標]{.zh}[Goal]{.en} | [設計]{.zh}[Design]{.en} |", md, fixed = TRUE))
  expect_true(grepl("[本庫的正式範例：]{.zh}[Worked example in this library:]{.en}", md, fixed = TRUE))
  expect_true(grepl("[實測檔：[GitHub 上的 data/](http://example/data)]{.zh}", md, fixed = TRUE))
  expect_true(grepl("| [資料集]{.zh}[Dataset]{.en} |", md, fixed = TRUE))
})

test_that("render_reading_map_md 的實測檔位置預設指向公開 repo 的 data/", {
  entries <- list(
    u1 = mk_entry("predict", "none",
                  links = list(list(title = "Dataset U", url = "http://data-u", license = "CC0", kind = "dataset")))
  )
  md <- render_reading_map_md(entries)
  expect_true(grepl("https://github.com/SCgeeker/stat-skills-tutorials/tree/main/data", md, fixed = TRUE))
})

test_that("render_reading_map_md 的 dataset 連結不進表一，只進表二", {
  entries <- list(
    z1 = mk_entry("predict", "none", links = list(
      list(title = "Chapter Z", url = "http://chapter-z", license = "CC BY", kind = "chapter"),
      list(title = "Dataset Z", url = "http://dataset-z", license = "CC0", kind = "dataset")
    ))
  )
  md <- render_reading_map_md(entries)
  table1_part <- sub("(?s)\n## [^\n]*Datasets used.*$", "", md, perl = TRUE)
  expect_false(grepl("Dataset Z", table1_part, fixed = TRUE))
  expect_true(grepl("Chapter Z", table1_part, fixed = TRUE))
  expect_true(grepl("## [本庫使用的資料集]{.zh}[Datasets used in the prompt library]{.en}", md, fixed = TRUE))
  expect_true(grepl("[Dataset Z](http://dataset-z)", md, fixed = TRUE))
  expect_true(grepl("`z1`", md, fixed = TRUE))
})

test_that("render_reading_map_md 沒有任何 dataset 連結時省略表二", {
  entries <- list(
    w1 = mk_entry("describe", "within",
                  links = list(list(title = "W chapter", url = "http://w", license = "CC BY", kind = "chapter")))
  )
  md <- render_reading_map_md(entries)
  expect_false(grepl("## [本庫使用的資料集]{.zh}[Datasets used in the prompt library]{.en}", md, fixed = TRUE))
})

test_that("render_reading_map_md 對標題與授權內含的 | 做跳脫", {
  entries <- list(
    p1 = mk_entry("screen", "none",
                  links = list(list(title = "A | B chapter", url = "http://pipe", license = "CC | BY", kind = "chapter")))
  )
  md <- render_reading_map_md(entries)
  expect_true(grepl("A \\| B chapter", md, fixed = TRUE))
  expect_true(grepl("CC \\| BY", md, fixed = TRUE))
})

test_that("render_reading_map_md 的 link.kind 缺省視同 chapter", {
  entries <- list(
    q1 = mk_entry("screen", "none",
                  links = list(list(title = "No kind chapter", url = "http://nokind", license = "CC BY")))
  )
  md <- render_reading_map_md(entries)
  expect_true(grepl("No kind chapter", md, fixed = TRUE))
  expect_false(grepl("No chapter linked yet", md, fixed = TRUE))
})

test_that("write_reading_map 把 render_reading_map_md 的結果寫入檔案", {
  entries <- list(
    w1 = mk_entry("describe", "within",
                  links = list(list(title = "W chapter", url = "http://w", license = "CC BY", kind = "chapter")))
  )
  out_path <- tempfile(fileext = ".md")
  write_reading_map(entries, out_path)
  expect_true(file.exists(out_path))
  content <- paste(readLines(out_path, warn = FALSE), collapse = "\n")
  expect_equal(content, render_reading_map_md(entries))
  unlink(out_path)
})
