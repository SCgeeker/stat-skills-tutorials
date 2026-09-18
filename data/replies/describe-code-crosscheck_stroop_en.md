# describe-code-crosscheck_stroop_en

> 本檔是模型回覆的**穩定副本**。`.omv` 內的回覆會被 askLLM 的重跑覆蓋
> （`submit` 勾著時每次開檔都重打 API），因此不能只靠 `.omv` 保存。
> 抽取來源：`describe-code-crosscheck_stroop_en.omv` 的 `02 askllmr`；Rj 實際執行的程式碼與輸出見
> `04 Rjp`；jamovi 對照分析見 `06 descriptives`。

| 項目 | 值 |
|---|---|
| 分析 | R code tutor (askllmr) |
| persona (`role`) | `tutor` |
| 提示詞語言 (`promptLang`) | `en (預設)` |
| provider / model | `gemini` / `gemini-flash-latest` |

## 送出的問題

```
The data has reaction_time (continuous), condition (2 levels), and participant_id (participant identifier).

Please give me R code that computes descriptive statistics for reaction_time split by condition, so that I can compare it cell by cell against jamovi's Descriptives.

Rules:
1. Put every blank as a variable assignment at the top, with a string placeholder as its value. Do not use comments as placeholders.
2. Use data only. No read.csv, no install.packages, no setwd.
3. Tell me which statistics may not come out to the same number in R and in jamovi, and why.
```

## 模型回覆（逐字）

程式碼：

```r
library(tidyverse)

# Assign your dataset's column names here
grouping_variable <- "REPLACE_WITH_GROUP_NAME"
numeric_variable  <- "REPLACE_WITH_NUMERIC_NAME"

# Descriptive summary skeleton
data %>%
  group_by(.data[[grouping_variable]]) %>%
  summarise(
    N      = n(),
    Mean   = mean(.data[[numeric_variable]], na.rm = TRUE),
    SD     = sd(.data[[numeric_variable]], na.rm = TRUE),
    Median = median(.data[[numeric_variable]], na.rm = TRUE),
    Min    = min(.data[[numeric_variable]], na.rm = TRUE),
    Max    = max(.data[[numeric_variable]], na.rm = TRUE),
    Q1     = quantile(.data[[numeric_variable]], probs = 0.25, type = 6, na.rm = TRUE),
    Q3     = quantile(.data[[numeric_variable]], probs = 0.75, type = 6, na.rm = TRUE)
  )
```

說明：

### Discrepancies Between R and jamovi Statistics

1. **Skewness and Kurtosis**: jamovi reports sample-adjusted values (Type 2, equivalent to SPSS/SAS). If you compute standard moment-based skewness/kurtosis (Type 1 or base formulas) in R, the values will differ slightly.
2. **Quartiles (25th and 75th percentiles)**: Base R’s `quantile()` defaults to `type = 7`, whereas jamovi uses `type = 6` (standard in SPSS/Minitab). To match jamovi, you must specify `type = 6` in R's `quantile()` function.

---

### Starter Code Skeleton

Fill in the column names in the string placeholders at the top:

Paste this code into the Rj Editor, press Run, and report back any errors.

## Rj 實際執行的程式碼與輸出

> 判定依據是 Rj 實際執行的程式碼與輸出（下方），不是上面回覆文字本身。這裡 Rj 貼的是把佔位符
> 填好之後的版本（`grouping_variable <- "condition"`、`numeric_variable <- "reaction_time"`），
> 邏輯與回覆的骨架一致，`type = 6` 的說法未變。

```r
library(tidyverse)

# Assign your dataset's column names here
grouping_variable <- "condition"
numeric_variable  <- "reaction_time"

# Descriptive summary skeleton
data %>%
  group_by(.data[[grouping_variable]]) %>%
  summarise(
    N      = n(),
    Mean   = mean(.data[[numeric_variable]], na.rm = TRUE),
    SD     = sd(.data[[numeric_variable]], na.rm = TRUE),
    Median = median(.data[[numeric_variable]], na.rm = TRUE),
    Min    = min(.data[[numeric_variable]], na.rm = TRUE),
    Max    = max(.data[[numeric_variable]], na.rm = TRUE),
    Q1     = quantile(.data[[numeric_variable]], probs = 0.25, type = 6, na.rm = TRUE),
    Q3     = quantile(.data[[numeric_variable]], probs = 0.75, type = 6, na.rm = TRUE)
  )
```

輸出：

```text
# A tibble: 2 × 9
  condition       N  Mean    SD Median   Min   Max    Q1    Q3
  <fct>       <int> <dbl> <dbl>  <dbl> <dbl> <dbl> <dbl> <dbl>
1 congruent     270  744.  105.   746.  419. 1021.  667.  819.
2 incongruent   270  891.  142.   901.  443. 1359.  796.  985.
```

## jamovi Descriptives（交叉核對用，取自 `06 descriptives`／index.html）

| condition | N | Mean | Median | SD | Min | Max | Skewness | Kurtosis | 25th | 50th | 75th |
|---|---|---|---|---|---|---|---|---|---|---|---|
| congruent | 270 | 744.11 | 746.26 | 104.95 | 418.93 | 1020.82 | -0.08 | -0.00 | 667.93 | 746.26 | 818.76 |
| incongruent | 270 | 891.34 | 900.77 | 141.76 | 442.96 | 1358.57 | -0.01 | 0.34 | 796.78 | 900.77 | 984.23 |

用 `type = 6` 在原始資料上重算得到 congruent Q1/Q3 = 667.48／819.07、incongruent Q1/Q3 = 796.22／984.68，
四個數字都對不上 jamovi 實際顯示的 667.93／818.76／796.78／984.23（jamovi 用的是 `type = 7`）。
