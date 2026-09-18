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
    if (is.null(links) || length(links) == 0) return("_[無]{.zh}[None]{.en}_")
    paste(vapply(links, function(l) sprintf("- [%s](%s) · %s", l$title, l$url, l$license), character(1)),
          collapse = "\n")
  }
  #' tested_with 的 note 只有中文：完整 note 放進 .zh 區塊；.en 區塊列同樣的
  #' date/provider/model/result，再附上從 note 抽出的證據檔路徑（.omv 與回覆副本）
  fmt_tested <- function(tw) {
    meta <- vapply(tw, function(t_i) sprintf("- %s | %s | %s | **%s**",
                                             t_i$date, t_i$provider, t_i$model, t_i$result),
                   character(1))
    zh <- paste(sprintf("%s | %s", meta, vapply(tw, function(t_i) t_i$note, character(1))),
                collapse = "\n")
    evidence <- vapply(tw, function(t_i) {
      p <- unique(regmatches(t_i$note, gregexpr("data/[A-Za-z0-9_./-]+\\.(omv|md)", t_i$note))[[1]])
      if (length(p) == 0) "" else paste0(" | Evidence: ", paste(sprintf("`%s`", p), collapse = ", "))
    }, character(1))
    en <- paste(
      "Full test notes are recorded in Chinese. Use the language toggle to read them.",
      "",
      paste(paste0(meta, evidence), collapse = "\n"),
      sep = "\n"
    )
    sprintf("::: {.zh}\n%s\n:::\n\n::: {.en}\n%s\n:::", zh, en)
  }

  # 語言標記慣例（對應 assets/lang.css 的單站語言切換）：
  #   - 標題／行內：[中文]{.zh}[English]{.en}
  #   - 區塊：::: {.zh} ... ::: 與 ::: {.en} ... :::
  # 依 prompts/_schema.yaml（2026-09-08 擴充後），成對存在中英欄位的欄位有
  # title / scenario / prompt（system_prompt_override 目前本頁未輸出），
  # 以及 prerequisites／expected／check.what／stop_criteria（新增）——
  # 這四個欄位的中英文各自落進對應的 .zh / .en 區塊，不再整段只包進 .zh。
  # check 的 step 代號本身語言中立，兩種語言的區塊都原樣顯示。
  # stat_goal／persona／analysis／design 是語言中立的代碼，不包進任何語言區塊。
  # tested_with 的 note 只有中文，故實測記錄分成 .zh／.en 兩個區塊（見 fmt_tested），
  # date/provider/model/result 在兩個區塊各列一次，兩種語言都看得到。
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
#' index.qmd 是由本腳本產生的總表，勿手改。
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
    "title: \"[提示詞庫]{.zh}[Prompt Library]{.en}\"",
    "---",
    "",
    "::: {.zh}",
    "本頁由 `tools/build-prompts.R` 依 `prompts/entries/*.yaml` 自動產生，**請勿手動修改本頁內容**——",
    "要修改條目請改對應的 yaml 檔後重新執行 build 腳本。",
    ":::",
    "",
    "::: {.en}",
    "This page is generated by `tools/build-prompts.R` from `prompts/entries/*.yaml`.",
    "**Do not edit this page by hand** -- edit the corresponding YAML entry and rerun the build script instead.",
    ":::",
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

# 外部教材對照表（external/_reading-map-table.md） -------------------------

#' 取得單一 link 的 kind；未填（NULL 或空字串）視同 "chapter"
#' @param link list，單一 link（title/url/license，可能有 kind）
#' @return character(1) "chapter" 或 "dataset"
link_kind <- function(link) {
  if (is.null(link$kind) || !nzchar(link$kind)) "chapter" else link$kind
}

#' Markdown 表格欄位內容跳脫：把 "|" 轉成 "\|"，避免破壞表格分隔
.escape_md_cell <- function(x) gsub("|", "\\|", x, fixed = TRUE)

#' 對照表中「本庫實測檔」的位置：公開 repo 的 data/ 資料夾
READING_MAP_DATA_URL <- "https://github.com/SCgeeker/stat-skills-tutorials/tree/main/data"

#' 依 stat_goal x design 分組，產生「外部教材對照表」的 Markdown（兩張表）
#' 純函式：只讀 entries（list 的 name 即 id）裡的 stat_goal / design / links，
#' 不觸碰檔案。
#'
#' 表一「Where to read」：依資料中實際出現的 (stat_goal, design) 組合各一
#' 列，goal 依 screen/describe/compare-2/compare-k/associate/predict/
#' reliability 排序，design 依 between/within/mixed/none 排序。Where to
#' read 欄只收該組所有條目裡 kind 為 chapter 的 link，依 url 去重。該組沒有
#' 任何 chapter link 時，改列本庫的正式範例：該組條目的 dataset link（範例
#' 資料），以及實測檔所在的 data/ 位置。公開頁面不出現待辦措辭。
#'
#' 表二「Datasets used in the prompt library」：收所有條目裡 kind 為
#' dataset 的 link，依 url 去重；沒有任何 dataset link 時整張表省略。
#'
#' @param entries named list，來自 read_entries()
#' @param data_dir_url character(1) 實測檔所在位置的網址，預設為公開 repo 的 data/
#' @return character(1) Markdown 全文
render_reading_map_md <- function(entries, data_dir_url = READING_MAP_DATA_URL) {
  # 中英並列的行內標記：[中文]{.zh}[English]{.en}
  bi <- function(zh, en) sprintf("[%s]{.zh}[%s]{.en}", zh, en)
  goal_labels <- c(
    screen       = bi("分析前檢查資料", "Screen data before analysis"),
    describe     = bi("描述變項", "Describe variables"),
    `compare-2`  = bi("比較兩組或兩種條件", "Compare two groups or conditions"),
    `compare-k`  = bi("比較三組以上", "Compare three or more groups"),
    associate    = bi("檢視兩個變項的關聯", "Relate two variables"),
    predict      = bi("預測結果變項", "Predict an outcome"),
    reliability  = bi("檢查信度", "Check reliability")
  )
  design_labels <- c(
    between = bi("受試者間", "Between-subjects"),
    within  = bi("受試者內", "Within-subjects"),
    mixed   = bi("混合設計（受試者間與受試者內）", "Mixed (between and within)"),
    none    = bi("無分組設計", "No grouping design")
  )
  goal_order <- names(goal_labels)
  design_order <- names(design_labels)

  ids <- names(entries)
  goals <- vapply(ids, function(id) entries[[id]]$stat_goal, character(1))
  designs <- vapply(ids, function(id) entries[[id]]$design, character(1))

  # 只列資料中實際出現的 (goal, design) 組合，依規定順序排序
  combos <- unique(data.frame(goal = goals, design = designs, stringsAsFactors = FALSE))
  combos <- combos[order(match(combos$goal, goal_order), match(combos$design, design_order)), , drop = FALSE]

  table1_rows <- character()
  for (r in seq_len(nrow(combos))) {
    g <- combos$goal[r]
    d <- combos$design[r]
    group_ids <- sort(ids[goals == g & designs == d])

    # 收集該組某一 kind 的 link，依 url 去重
    group_links <- function(kind) {
      out <- list()
      seen_urls <- character()
      for (id in group_ids) {
        for (l in entries[[id]]$links) {
          if (identical(link_kind(l), kind) && !(l$url %in% seen_urls)) {
            out[[length(out) + 1]] <- l
            seen_urls <- c(seen_urls, l$url)
          }
        }
      }
      out
    }
    fmt_links <- function(links) {
      vapply(links, function(l) {
        sprintf("[%s](%s) · %s", .escape_md_cell(l$title), l$url, .escape_md_cell(l$license))
      }, character(1))
    }

    chapter_links <- group_links("chapter")
    where <- if (length(chapter_links) > 0) {
      paste(fmt_links(chapter_links), collapse = "<br>")
    } else {
      # 沒有教材章節：改列本庫的正式範例（範例資料＋實測檔位置）
      dataset_links <- group_links("dataset")
      recorded <- bi(sprintf("實測檔：[GitHub 上的 data/](%s)", data_dir_url),
                     sprintf("Recorded test files: [data/ on GitHub](%s)", data_dir_url))
      if (length(dataset_links) > 0) {
        paste(c(bi("本庫的正式範例：", "Worked example in this library:"), fmt_links(dataset_links), recorded),
              collapse = "<br>")
      } else {
        recorded
      }
    }

    prompt_col <- paste(sprintf("`%s`", .escape_md_cell(group_ids)), collapse = ", ")

    table1_rows <- c(table1_rows, sprintf(
      "| %s | %s | %s | %s |",
      .escape_md_cell(goal_labels[[g]]), .escape_md_cell(design_labels[[d]]), where, prompt_col
    ))
  }

  table1 <- paste(
    paste("##", bi("該讀哪一章", "Where to read")),
    "",
    sprintf("| %s | %s | %s | %s |", bi("目標", "Goal"), bi("設計", "Design"),
            bi("該讀哪一章", "Where to read"), bi("提示詞條目", "Prompt entries")),
    "|---|---|---|---|",
    paste(table1_rows, collapse = "\n"),
    sep = "\n"
  )

  # 表二：資料集出處，依 url 去重，收集每個資料集被哪些條目使用
  dataset_links <- list()
  dataset_urls <- character()
  dataset_users <- list()
  for (id in ids) {
    for (l in entries[[id]]$links) {
      if (identical(link_kind(l), "dataset")) {
        if (!(l$url %in% dataset_urls)) {
          dataset_links[[length(dataset_links) + 1]] <- l
          dataset_urls <- c(dataset_urls, l$url)
          dataset_users[[l$url]] <- character()
        }
        dataset_users[[l$url]] <- c(dataset_users[[l$url]], id)
      }
    }
  }

  if (length(dataset_links) == 0) {
    return(table1)
  }

  table2_rows <- vapply(dataset_links, function(l) {
    used_by <- paste(sprintf("`%s`", .escape_md_cell(sort(unique(dataset_users[[l$url]])))), collapse = ", ")
    sprintf("| [%s](%s) | %s | %s |", .escape_md_cell(l$title), l$url, .escape_md_cell(l$license), used_by)
  }, character(1))

  table2 <- paste(
    paste("##", bi("本庫使用的資料集", "Datasets used in the prompt library")),
    "",
    sprintf("| %s | %s | %s |", bi("資料集", "Dataset"), bi("授權", "License"), bi("使用條目", "Used by")),
    "|---|---|---|",
    paste(table2_rows, collapse = "\n"),
    sep = "\n"
  )

  paste(table1, table2, sep = "\n\n")
}

#' 把 render_reading_map_md() 的結果寫成檔案
#' @param entries named list，來自 read_entries()
#' @param out_path character(1) 輸出路徑
write_reading_map <- function(entries, out_path) {
  writeLines(render_reading_map_md(entries), out_path, useBytes = TRUE)
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

  reading_map_out <- file.path(base_dir, "external", "_reading-map-table.md")
  write_reading_map(entries, reading_map_out)
  cat(sprintf("已寫出外部教材對照表：%s\n", reading_map_out))
}
