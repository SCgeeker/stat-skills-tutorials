# tools/validate-prompts.R
# ---------------------------------------------------------------------------
# 驗證 prompts/entries/*.yaml 是否符合 prompts/_schema.yaml 定義的 schema。
# 純函式（validate_entry / validate_entry_file / validate_all_entries），
# 可被 tests/testthat 直接 source 測試，也可用 Rscript 當 CLI 執行。
#
# 用法（CLI）：
#   Rscript tools/validate-prompts.R [entries_dir]
#   entries_dir 預設為 prompts/entries（相對於本檔所在目錄的上一層）。
#   全部 PASS 時 exit code 0；任何一條 FAIL 則 exit code 1。
# ---------------------------------------------------------------------------

suppressWarnings(suppressMessages({
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("需要 yaml 套件：install.packages('yaml')")
  }
}))

# 受控詞彙表（對應 _schema.yaml） -------------------------------------------

.ANALYSIS_VALUES <- c("guider", "rtutor")
.VAR_ROLE_VALUES <- c("outcome", "predictor", "grouping", "id", "covariate")
.VAR_TYPE_VALUES <- c("continuous", "nominal", "ordinal")
.DESIGN_VALUES <- c("between", "within", "mixed", "none")
.STAT_GOAL_VALUES <- c("describe", "compare-2", "compare-k", "associate",
                        "predict", "reliability", "screen")
.PERSONA_VALUES <- c("consultant", "tutor", "explainer")
.CHECK_STEP_VALUES <- c("path", "number", "assumption", "code-read",
                         "code-run", "cross-check")
.TESTED_RESULT_VALUES <- c("pass", "partial", "fail", "pending")

# 輔助函式 --------------------------------------------------------------

#' 字串是否為非空白內容（NULL、NA、"" 或全空白皆視為空）
.is_blank <- function(x) {
  is.null(x) || length(x) == 0 || is.na(x) || !nzchar(trimws(x))
}

#' 提示詞結尾是否有多餘空白行
#' Q4 已判定 prompt 允許多行；但 askLLM 端只用 trimws() 清頭尾，
#' 結尾殘留的空白行仍可能原樣送出，故視為 lint 錯誤。
.has_trailing_blank_line <- function(text) {
  if (.is_blank(text)) return(FALSE)
  grepl("\n[ \t]*\n[ \t]*$", text)
}

#' 檢查雙語欄位（title/scenario/prompt 等）zh 與 en 是否都非空
#' @return character()：錯誤訊息（可能為 0 筆）
.check_bilingual <- function(field, field_name, require_en = TRUE) {
  errs <- character()
  if (is.null(field) || !is.list(field)) {
    return(sprintf("%s 缺失或格式錯誤（需為 {zh: ..., en: ...}）", field_name))
  }
  if (.is_blank(field$zh)) {
    errs <- c(errs, sprintf("%s.zh 不得為空", field_name))
  }
  if (require_en && .is_blank(field$en)) {
    errs <- c(errs, sprintf("%s.en 不得為空（Q5：英文為必填）", field_name))
  }
  errs
}

#' 檢查「雙語字串清單」欄位（prerequisites/expected 等）
#' 每個項目須為 {zh: ..., en: ...}，英文預設必填（2026-09-08 擴充範圍）。
#' @param items list，來自 entry$prerequisites 或 entry$expected
#' @param field_name character(1) 欄位名稱（用於錯誤訊息與索引前綴）
#' @return character()：錯誤訊息（可能為 0 筆）
.check_bilingual_list <- function(items, field_name, require_en = TRUE) {
  errs <- character()
  if (is.null(items) || length(items) < 1) {
    return(sprintf("%s 至少須有 1 筆", field_name))
  }
  for (i in seq_along(items)) {
    errs <- c(errs, .check_bilingual(items[[i]], sprintf("%s[%d]", field_name, i), require_en))
  }
  errs
}

# 主驗證函式 ------------------------------------------------------------

#' 驗證單一條目（已讀入為 R list）
#'
#' @param entry list，通常來自 yaml::read_yaml()
#' @param expected_id character(1) 或 NULL；若提供，檢查 entry$id 是否與之相同
#'   （用來確保 id 與檔名一致）
#' @return list(valid = logical(1), errors = character())
validate_entry <- function(entry, expected_id = NULL) {
  errors <- character()

  required_fields <- c("id", "title", "analysis", "scenario", "variables",
                        "design", "stat_goal", "prerequisites", "persona",
                        "prompt", "expected", "check", "stop_criteria",
                        "tested_with")
  missing_fields <- setdiff(required_fields, names(entry))
  if (length(missing_fields) > 0) {
    errors <- c(errors, sprintf("缺少必填欄位：%s", paste(missing_fields, collapse = ", ")))
  }

  # id --------------------------------------------------------------
  if (!is.null(entry$id)) {
    if (!grepl("^[a-z0-9]+(-[a-z0-9]+)*$", entry$id)) {
      errors <- c(errors, sprintf("id 格式不合法（需為 kebab-case）：%s", entry$id))
    }
    if (!is.null(expected_id) && !identical(entry$id, expected_id)) {
      errors <- c(errors, sprintf("id（%s）與檔名（%s）不一致", entry$id, expected_id))
    }
  }

  # title / scenario（雙語，英文必填，Q5） ---------------------------
  if (!is.null(entry$title)) {
    errors <- c(errors, .check_bilingual(entry$title, "title"))
  }
  if (!is.null(entry$scenario)) {
    errors <- c(errors, .check_bilingual(entry$scenario, "scenario"))
  }

  # analysis ----------------------------------------------------------
  if (!is.null(entry$analysis) && !(entry$analysis %in% .ANALYSIS_VALUES)) {
    errors <- c(errors, sprintf("analysis 非受控詞彙：%s", entry$analysis))
  }

  # variables -----------------------------------------------------------
  if (!is.null(entry$variables)) {
    if (length(entry$variables) < 1) {
      errors <- c(errors, "variables 至少須有 1 筆")
    } else {
      for (i in seq_along(entry$variables)) {
        v <- entry$variables[[i]]
        if (is.null(v$role) || !(v$role %in% .VAR_ROLE_VALUES)) {
          errors <- c(errors, sprintf("variables[%d].role 非受控詞彙：%s", i, v$role))
        }
        if (is.null(v$type) || !(v$type %in% .VAR_TYPE_VALUES)) {
          errors <- c(errors, sprintf("variables[%d].type 非受控詞彙：%s", i, v$type))
        }
      }
    }
  }

  # design --------------------------------------------------------------
  if (!is.null(entry$design) && !(entry$design %in% .DESIGN_VALUES)) {
    errors <- c(errors, sprintf("design 非受控詞彙：%s", entry$design))
  }

  # stat_goal -----------------------------------------------------------
  if (!is.null(entry$stat_goal) && !(entry$stat_goal %in% .STAT_GOAL_VALUES)) {
    errors <- c(errors, sprintf("stat_goal 非受控詞彙：%s（允許值：%s）",
                                  entry$stat_goal, paste(.STAT_GOAL_VALUES, collapse = ", ")))
  }

  # prerequisites（雙語字串清單，英文必填，2026-09-08 擴充） ---------------
  if (!is.null(entry$prerequisites)) {
    errors <- c(errors, .check_bilingual_list(entry$prerequisites, "prerequisites"))
  }

  # persona -------------------------------------------------------------
  if (!is.null(entry$persona) && !(entry$persona %in% .PERSONA_VALUES)) {
    errors <- c(errors, sprintf("persona 非受控詞彙：%s", entry$persona))
  }

  # prompt（雙語必填；允許多行；結尾不得有多餘空白行） -------------------
  if (!is.null(entry$prompt)) {
    errors <- c(errors, .check_bilingual(entry$prompt, "prompt"))
    if (!.is_blank(entry$prompt$zh) && .has_trailing_blank_line(entry$prompt$zh)) {
      errors <- c(errors, "prompt.zh 結尾有多餘空白行（trimws() 只清頭尾，請自行移除）")
    }
    if (!.is_blank(entry$prompt$en) && .has_trailing_blank_line(entry$prompt$en)) {
      errors <- c(errors, "prompt.en 結尾有多餘空白行（trimws() 只清頭尾，請自行移除）")
    }
  }

  # system_prompt_override（選填；若非 null，zh/en 皆須有值） -------------
  if (!is.null(entry$system_prompt_override)) {
    spo <- entry$system_prompt_override
    if (is.list(spo)) {
      errors <- c(errors, .check_bilingual(spo, "system_prompt_override"))
    }
  }

  # expected（雙語字串清單，英文必填，2026-09-08 擴充） --------------------
  if (!is.null(entry$expected)) {
    errors <- c(errors, .check_bilingual_list(entry$expected, "expected"))
  }

  # check（step 語言中立；what 為雙語，英文必填，2026-09-08 擴充） ---------
  if (!is.null(entry$check)) {
    if (length(entry$check) < 2) {
      errors <- c(errors, "check 至少須有 2 條")
    }
    steps <- character()
    for (i in seq_along(entry$check)) {
      c_i <- entry$check[[i]]
      if (is.null(c_i$step) || !(c_i$step %in% .CHECK_STEP_VALUES)) {
        errors <- c(errors, sprintf("check[%d].step 非受控詞彙：%s", i, c_i$step))
      } else {
        steps <- c(steps, c_i$step)
      }
      errors <- c(errors, .check_bilingual(c_i$what, sprintf("check[%d].what", i)))
    }
    if (!is.null(entry$analysis) && identical(entry$analysis, "rtutor")) {
      if (!("code-read" %in% steps) || !("code-run" %in% steps)) {
        errors <- c(errors, "analysis: rtutor 的條目 check 必須同時包含 code-read 與 code-run")
      }
    }
  }

  # stop_criteria（solved/reopen 皆為雙語，英文必填，2026-09-08 擴充） -----
  if (!is.null(entry$stop_criteria)) {
    errors <- c(errors, .check_bilingual(entry$stop_criteria$solved, "stop_criteria.solved"))
    errors <- c(errors, .check_bilingual(entry$stop_criteria$reopen, "stop_criteria.reopen"))
  }

  # links（選填） ---------------------------------------------------------
  if (!is.null(entry$links) && length(entry$links) > 0) {
    for (i in seq_along(entry$links)) {
      l_i <- entry$links[[i]]
      for (f in c("title", "url", "license")) {
        if (.is_blank(l_i[[f]])) {
          errors <- c(errors, sprintf("links[%d].%s 不得為空", i, f))
        }
      }
    }
  }

  # tested_with（至少 1 筆；result 受控；pending 需附說明） ----------------
  if (!is.null(entry$tested_with)) {
    if (length(entry$tested_with) < 1) {
      errors <- c(errors, "tested_with 至少須有 1 筆")
    } else {
      for (i in seq_along(entry$tested_with)) {
        t_i <- entry$tested_with[[i]]
        for (f in c("date", "provider", "model", "result", "note")) {
          if (is.null(t_i[[f]]) || .is_blank(as.character(t_i[[f]]))) {
            errors <- c(errors, sprintf("tested_with[%d].%s 不得為空", i, f))
          }
        }
        if (!is.null(t_i$result) && !(t_i$result %in% .TESTED_RESULT_VALUES)) {
          errors <- c(errors, sprintf("tested_with[%d].result 非受控詞彙：%s", i, t_i$result))
        }
        if (identical(t_i$result, "pending") && .is_blank(t_i$note)) {
          errors <- c(errors, sprintf("tested_with[%d].note 於 result=pending 時必須說明待測狀態", i))
        }
      }
    }
  }

  list(valid = length(errors) == 0, errors = errors)
}

#' 讀入單一 yaml 檔並驗證；expected_id 自動取自檔名
validate_entry_file <- function(path) {
  entry <- yaml::read_yaml(path)
  expected_id <- tools::file_path_sans_ext(basename(path))
  validate_entry(entry, expected_id = expected_id)
}

#' 驗證目錄下所有 *.yaml 條目
#' @return data.frame(id, valid, n_errors, errors)
validate_all_entries <- function(dir) {
  files <- list.files(dir, pattern = "\\.ya?ml$", full.names = TRUE)
  ids <- tools::file_path_sans_ext(basename(files))
  results <- lapply(files, validate_entry_file)
  data.frame(
    id = ids,
    valid = vapply(results, function(r) r$valid, logical(1)),
    n_errors = vapply(results, function(r) length(r$errors), integer(1)),
    errors = vapply(results, function(r) paste(r$errors, collapse = " | "), character(1)),
    stringsAsFactors = FALSE
  )
}

# CLI 進入點 --------------------------------------------------------------
if (identical(environment(), globalenv()) && sys.nframe() == 0 && !interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  entries_dir <- if (length(args) >= 1) args[[1]] else file.path(dirname(sys.script <- normalizePath(
    sub("--file=", "", grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE))
  )), "..", "prompts", "entries")

  if (length(args) < 1) {
    # 以本檔所在目錄反推 prompts/entries
    this_file <- normalizePath(sub("--file=", "", grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE)))
    entries_dir <- normalizePath(file.path(dirname(this_file), "..", "prompts", "entries"))
  } else {
    entries_dir <- normalizePath(args[[1]])
  }

  cat(sprintf("驗證目錄：%s\n", entries_dir))
  summary <- validate_all_entries(entries_dir)
  for (i in seq_len(nrow(summary))) {
    status <- if (summary$valid[i]) "PASS" else "FAIL"
    cat(sprintf("[%s] %s\n", status, summary$id[i]))
    if (!summary$valid[i]) {
      cat(sprintf("       %s\n", summary$errors[i]))
    }
  }
  n_fail <- sum(!summary$valid)
  cat(sprintf("\n共 %d 條，PASS %d，FAIL %d\n", nrow(summary), nrow(summary) - n_fail, n_fail))
  if (n_fail > 0) quit(status = 1)
}
