# tools/build-prompts.R
# ---------------------------------------------------------------------------
# 把 prompts/entries/*.yaml 轉成：
#   1. prompts.json（機讀索引，語言無關，仿 askLLM 的 learn-r.json 先例）
#   2. prompts/<id>.qmd（每條一頁，中英並列的簡化版頁面產生器）
#
# 純函式：read_entries / build_prompts_json / write_prompts_json /
#         render_entry_qmd / write_entry_qmds
# 可被 tests/testthat 直接 source，也可用 Rscript 當 CLI／Quarto pre-render
# hook 執行。
# ---------------------------------------------------------------------------

suppressWarnings(suppressMessages({
  if (!requireNamespace("yaml", quietly = TRUE)) stop("需要 yaml 套件")
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("需要 jsonlite 套件")
}))

#' 讀入目錄下所有條目，以 id（=檔名）為 list 的 name
#' @param dir character(1) entries 目錄路徑
#' @return named list，每個元素是 yaml::read_yaml() 讀入的條目
read_entries <- function(dir) {
  files <- list.files(dir, pattern = "\\.ya?ml$", full.names = TRUE)
  ids <- tools::file_path_sans_ext(basename(files))
  entries <- lapply(files, yaml::read_yaml)
  names(entries) <- ids
  entries
}

#' 將條目 list 轉成適合輸出為 JSON 的結構（保留所有欄位，id 統一補齊）
#' @param entries named list，來自 read_entries()
#' @return list（未命名，逐條為一個 element，方便輸出為 JSON array）
build_prompts_json <- function(entries) {
  ids <- names(entries)
  out <- lapply(ids, function(id) {
    e <- entries[[id]]
    e$id <- id
    e
  })
  out
}

#' 將 build_prompts_json() 的結果寫成合法 JSON 檔
#' @param entries named list，來自 read_entries()
#' @param out_path character(1) 輸出路徑
write_prompts_json <- function(entries, out_path) {
  built <- build_prompts_json(entries)
  jsonlite::write_json(built, out_path, auto_unbox = TRUE, pretty = TRUE, null = "null")
  invisible(out_path)
}

#' 將單一條目轉成簡化版 Quarto qmd 內容（中英並列）
#' Phase 0 範圍：先求「能產出、可讀」，排版細節留待 Phase 1 擴充。
#' @param entry list，單一條目（含 id）
#' @return character(1)，qmd 全文
render_entry_qmd <- function(entry) {
  id <- if (!is.null(entry$id)) entry$id else "unknown"

  #' 將雙語字串清單（prerequisites/expected：{zh, en} 的 list）取出指定語言，
  #' 轉成條列 Markdown
  fmt_list_lang <- function(x, lang) {
    paste(vapply(x, function(item) sprintf("- %s", item[[lang]]), character(1)),
          collapse = "\n")
  }
  #' 將 check（{step, what: {zh, en}} 的 list）取出指定語言，轉成條列
  #' Markdown；step 代號語言中立，兩種語言都原樣顯示。
  fmt_check_lang <- function(check, lang) {
    paste(vapply(check, function(c_i) sprintf("- **%s**: %s", c_i$step, c_i$what[[lang]]), character(1)),
          collapse = "\n")
  }
  fmt_links <- function(links) {
    if (is.null(links) || length(links) == 0) return("_（無）_")
    paste(vapply(links, function(l) sprintf("- [%s](%s)（%s）", l$title, l$url, l$license), character(1)),
          collapse = "\n")
  }
  fmt_tested <- function(tw) {
    paste(vapply(tw, function(t_i) sprintf("- %s | %s | %s | **%s** | %s",
                                             t_i$date, t_i$provider, t_i$model, t_i$result, t_i$note),
                 character(1)),
          collapse = "\n")
  }

  # 語言標記慣例（對應 assets/lang.css 的單站語言切換）：
  #   - 標題／行內：[中文]{.zh}[English]{.en}
  #   - 區塊：::: {.zh} ... ::: 與 ::: {.en} ... :::
  # 依 prompts/_schema.yaml（2026-09-08 擴充後），成對存在中英欄位的欄位有
  # title / scenario / prompt（system_prompt_override 目前本頁未輸出），
  # 以及 prerequisites／expected／check.what／stop_criteria（新增）——
  # 這四個欄位的中英文各自落進對應的 .zh / .en 區塊，不再整段只包進 .zh。
  # check 的 step 代號本身語言中立，兩種語言的區塊都原樣顯示。
  # stat_goal／persona／analysis／design／tested_with 的 date/provider/model
  # 是語言中立的代碼／識別碼，不包進任何語言區塊，兩種語言都看得到。
  bilingual_title <- sprintf("[%s]{.zh}[%s]{.en}", entry$title$zh, entry$title$en)

  glue_tpl <- '---
title: "%s"
---

## %s

**analysis**: `%s` &nbsp;|&nbsp; **design**: `%s` &nbsp;|&nbsp; **stat_goal**: `%s` &nbsp;|&nbsp; **persona**: `%s`

### [情境]{.zh}[Scenario]{.en}

::: {.zh}
%s
:::

::: {.en}
%s
:::

### [送出前必做]{.zh}[Prerequisites]{.en}

::: {.zh}
%s
:::

::: {.en}
%s
:::

### [提示詞]{.zh}[Prompt]{.en}

::: {.zh}
```
%s
```
:::

::: {.en}
```
%s
```
:::

### [期望回覆要素]{.zh}[Expected elements]{.en}

::: {.zh}
%s
:::

::: {.en}
%s
:::

### [查核點]{.zh}[Check]{.en}

::: {.zh}
%s
:::

::: {.en}
%s
:::

### [判準]{.zh}[Stop criteria]{.en}

::: {.zh}
- **solved**: %s
- **reopen**: %s
:::

::: {.en}
- **solved**: %s
- **reopen**: %s
:::

### [延伸閱讀]{.zh}[Links]{.en}

%s

### [實測記錄]{.zh}[Tested with]{.en}

%s
'

  sprintf(
    glue_tpl,
    bilingual_title,
    bilingual_title,
    entry$analysis, entry$design, entry$stat_goal, entry$persona,
    entry$scenario$zh,
    entry$scenario$en,
    fmt_list_lang(entry$prerequisites, "zh"),
    fmt_list_lang(entry$prerequisites, "en"),
    entry$prompt$zh,
    entry$prompt$en,
    fmt_list_lang(entry$expected, "zh"),
    fmt_list_lang(entry$expected, "en"),
    fmt_check_lang(entry$check, "zh"),
    fmt_check_lang(entry$check, "en"),
    entry$stop_criteria$solved$zh, entry$stop_criteria$reopen$zh,
    entry$stop_criteria$solved$en, entry$stop_criteria$reopen$en,
    fmt_links(entry$links),
    fmt_tested(entry$tested_with)
  )
}

#' 為目錄下每條條目各自寫出一個 <id>.qmd
#' @param entries named list，來自 read_entries()
#' @param out_dir character(1) 輸出目錄
write_entry_qmds <- function(entries, out_dir) {
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  paths <- character()
  for (id in names(entries)) {
    e <- entries[[id]]
    e$id <- id
    qmd <- render_entry_qmd(e)
    path <- file.path(out_dir, paste0(id, ".qmd"))
    writeLines(qmd, path, useBytes = TRUE)
    paths <- c(paths, path)
  }
  invisible(paths)
}

#' 依所有 tested_with.result 值決定總表頁要不要顯示「尚未實測」警語 callout。
#' 純函式：不觸碰檔案，方便單獨測試；由 render_index_qmd() 產生的 R chunk
#' 在 quarto render 當下呼叫，確保文字不會因為日後補了實測而過期。
#' 判準：
#'   - 全部 pending：印「這些提示詞尚未實測」（強語氣，讀者應把期望回覆當設計意圖）
#'   - 部分 pending：印「部分提示詞尚未實測」（提醒哪些條目還沒有實測依據）
#'   - 沒有任何 pending（含輸入為空）：不印，回傳 ""
#' @param results character vector，所有條目、所有 tested_with 項目的 result 值
#' @return character(1) callout 的 Markdown 全文；不需要顯示時回傳 ""
pending_notice <- function(results) {
  if (length(results) == 0 || !any(results == "pending")) return("")

  if (all(results == "pending")) {
    title_zh <- "這些提示詞尚未實測"
    title_en <- "These prompts have not been tested yet"
    body_zh <- paste(
      "本庫每一條條目的 `tested_with` 都記為 `pending`：沒有任何一條送給真實模型跑過。",
      "請把「期望回覆要素」當成設計意圖，不是已觀察到的行為。",
      sep = "\n"
    )
    body_en <- paste(
      "Every entry in this library records `pending` as its test result. No prompt here has been run",
      "against a live model. Treat the expected-response list as a design intention, not as observed",
      "behaviour.",
      sep = "\n"
    )
  } else {
    title_zh <- "部分提示詞尚未實測"
    title_en <- "Some prompts have not been tested yet"
    body_zh <- paste(
      "本庫部分條目的 `tested_with` 仍記為 `pending`：還沒有送給真實模型跑過。",
      "這些條目的「期望回覆要素」請當成設計意圖；只有標為 `pass`／`partial`／`fail` 的條目才代表已觀察到的實測行為。",
      sep = "\n"
    )
    body_en <- paste(
      "Some entries in this library still record `pending` as their test result and have not been run",
      "against a live model yet. Treat those entries' expected-response list as a design intention; only",
      "entries marked `pass`, `partial`, or `fail` reflect observed test behaviour.",
      sep = "\n"
    )
  }

  sprintf(
    paste(
      ':::: {.callout-warning}',
      '## [%s]{.zh}[%s]{.en}',
      '',
      '::: {.zh}',
      '%s',
      ':::',
      '',
      '::: {.en}',
      '%s',
      ':::',
      '::::',
      '',
      sep = "\n"
    ),
    title_zh, title_en, body_zh, body_en
  )
}

#' 產生嵌入總表頁的「尚未實測」R chunk 原始碼。
#' 該 chunk 在 quarto render 當下才執行：讀入 docs/prompts.json（此時工作
#' 目錄是 index.qmd 所在的 prompts/ 目錄，故用 "../docs/prompts.json"、
#' "../tools/build-prompts.R" 這種相對於 prompts/ 的路徑，已用實際
#' `quarto render` 驗證過工作目錄假設成立），取出所有 tested_with.result，
#' 呼叫 pending_notice() 印出（或略過）警語——文字不因日後補實測而過期。
#' @return character(1) chunk 原始碼（含前後的 ```` ``` ```` 圍欄）
render_pending_chunk <- function() {
  paste(
    '```{r}',
    '#| echo: false',
    '#| output: asis',
    'source("../tools/build-prompts.R", chdir = TRUE)',
    'pending_notice_entries <- jsonlite::fromJSON("../docs/prompts.json", simplifyVector = FALSE)',
    'pending_notice_results <- unlist(lapply(pending_notice_entries, function(pn_e) {',
    '  vapply(pn_e$tested_with, function(pn_t) pn_t$result, character(1))',
    '}))',
    'cat(pending_notice(pending_notice_results))',
    '```',
    '',
    sep = "\n"
  )
}

#' 把所有條目合併成單一總表頁（prompts/index.qmd）
#' 對應 PROPOSAL §3.3 目錄結構：「index.qmd（由 build 腳本產生的總表，勿手改）」。
#' 作法：重用 render_entry_qmd() 產出的每條內容，去掉各自的 YAML frontmatter
#' 後以分隔線接起來，最外層只留一份總表用的 frontmatter。
#' @param entries named list，來自 read_entries()
#' @return character(1)，index.qmd 全文
render_index_qmd <- function(entries) {
  bodies <- vapply(names(entries), function(id) {
    e <- entries[[id]]
    e$id <- id
    qmd <- render_entry_qmd(e)
    sub("^---\\n.*?\\n---\\n\\n", "", qmd)
  }, character(1))

  header <- paste(
    "---",
    "title: \"提示詞庫 / Prompt Library\"",
    "---",
    "",
    "本頁由 `tools/build-prompts.R` 依 `prompts/entries/*.yaml` 自動產生，**請勿手動修改本頁內容**——",
    "要修改條目請改對應的 yaml 檔後重新執行 build 腳本。",
    "",
    "This page is generated by `tools/build-prompts.R` from `prompts/entries/*.yaml`.",
    "**Do not edit this page by hand** -- edit the corresponding YAML entry and rerun the build script instead.",
    "",
    sep = "\n"
  )

  # header 結尾已有一個換行，這裡再補一個空行，確保 R chunk 的圍欄不會被
  # pandoc 併進前一段落（fenced div 對「上一行是不是空白行」很敏感，實測
  # 過沒有空行時 ":::: {.callout-warning}" 會被吃進上一段文字，導致整個
  # callout 沒有被解析成 fenced div，只剩一坨純文字）。
  paste0(header, "\n", render_pending_chunk(), "\n", paste(bodies, collapse = "\n\n---\n\n"))
}

#' 寫出 prompts/index.qmd 總表
#' @param entries named list，來自 read_entries()
#' @param out_path character(1) 輸出路徑（通常是 prompts/index.qmd）
write_index_qmd <- function(entries, out_path) {
  writeLines(render_index_qmd(entries), out_path, useBytes = TRUE)
  invisible(out_path)
}

# CLI 進入點 ----------------------------------------------------------------
if (identical(environment(), globalenv()) && sys.nframe() == 0 && !interactive()) {
  file_arg <- grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  this_file <- normalizePath(sub("--file=", "", file_arg))
  base_dir <- normalizePath(file.path(dirname(this_file), ".."))

  entries_dir <- file.path(base_dir, "prompts", "entries")
  json_out <- file.path(base_dir, "docs", "prompts.json")
  qmd_out_dir <- file.path(base_dir, "prompts", "generated")
  index_out <- file.path(base_dir, "prompts", "index.qmd")

  cat(sprintf("讀入條目目錄：%s\n", entries_dir))
  entries <- read_entries(entries_dir)
  cat(sprintf("共讀入 %d 條條目：%s\n", length(entries), paste(names(entries), collapse = ", ")))

  dir.create(dirname(json_out), recursive = TRUE, showWarnings = FALSE)
  write_prompts_json(entries, json_out)
  cat(sprintf("已寫出 JSON：%s\n", json_out))

  write_entry_qmds(entries, qmd_out_dir)
  cat(sprintf("已寫出 %d 個 qmd 頁面於：%s\n", length(entries), qmd_out_dir))

  write_index_qmd(entries, index_out)
  cat(sprintf("已寫出總表：%s\n", index_out))
}
