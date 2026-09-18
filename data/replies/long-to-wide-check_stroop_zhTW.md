# long-to-wide-check_stroop_zhTW

> 本檔是模型回覆的**穩定副本**。`.omv` 內的回覆會被 askLLM 的重跑覆蓋
> （`submit` 勾著時每次開檔都重打 API），因此不能只靠 `.omv` 保存。
> 抽取來源：`long-to-wide-check_stroop_zhTW.omv` 的 `02 askllmr`；Rj 實際執行的程式碼與輸出見
> `06 Rjp`；jamovi 對照分析見 `10 descriptives`。

| 項目 | 值 |
|---|---|
| 分析 | R code tutor (askllmr) |
| persona (`role`) | `consultant (預設)` |
| 提示詞語言 (`promptLang`) | `zh` |
| provider / model | `gemini` / `gemini-flash-latest` |

## 送出的問題

```
data 是長格式，540 列：每位 participant_id 在 condition 的兩個水準（congruent、incongruent）各有一列 reaction_time。

jamovi 的 Paired Samples T-Test 需要寬格式。請給我一段 R 程式碼把它轉過去。

規則：
1. 待填處寫成開頭的變數指派、值放字串佔位符，不要用註解當佔位符。
2. 只用 data，不要 read.csv、不要 install.packages。
3. 轉完之後印出可以讓我自己核對「有沒有轉錯」的東西，並說明我該看到什麼數字。
4. 不要幫我跑 t 檢定。
```

## 模型回覆（逐字）

程式碼：

```r
library(tidyverse)

# --- 變數名稱設定（可依需求修改字串） ---
id_col <- "participant_id"
names_col <- "condition"
values_col <- "reaction_time"

# 長格式轉寬格式
data_wide <- pivot_wider(
  data,
  id_cols = all_of(id_col),
  names_from = all_of(names_col),
  values_from = all_of(values_col)
)

# 核對轉換結果
cat("【維度檢查】\n")
print(dim(data_wide))

cat("\n【前 6 筆資料】\n")
print(head(data_wide))

cat("\n【遺漏值檢查】\n")
print(colSums(is.na(data_wide)))
```

說明：

這段程式碼使用 `tidyr::pivot_wider` 將原本長格式的反應時間資料依受試者轉換為包含 `congruent` 與 `incongruent` 兩欄的寬格式資料。

### 如何核對是否轉成功：
1. **維度檢查**：你應該會看到 `[1] 270   3`（因為 540 列除以 2 個條件，寬格式應剛好為 270 位受試者、共 3 個欄位：`participant_id`、`congruent`、`incongruent`）。
2. **遺漏值檢查**：各欄位的遺漏值加總應全為 `0`，代表每位受試者在兩種情境下都成功對應到資料。

請將上述程式碼貼進 jamovi 的 Rj Editor 並按下 Run，若有任何錯誤訊息請回報給我。

## Rj 實際執行的程式碼與輸出

判定依據是 Rj 實際執行的程式碼與輸出。本次貼進 `06 Rjp` 的程式碼與上方回覆的程式碼**逐字相同**
（去除註解與空行後逐行比對），所以回覆與執行同源。

輸出：

```text
【維度檢查】
[1] 270   3

【前 6 筆資料】
# A tibble: 6 × 3
  participant_id congruent incongruent
  <fct>              <dbl>       <dbl>
1 1                   847.        910.
2 2                   748.        967.
3 3                   786.        976.
4 4                   951.        951.
5 5                   632.       1112.
6 6                   674.        744.

【遺漏值檢查】
participant_id      congruent    incongruent 
             0              0              0 
```

## jamovi 對照分析（`10 descriptives`）

`Exploration ▸ Descriptives`，`reaction_time` 以 `condition` 分組（長格式原始資料）：

| condition | N | Missing | Mean | Median | SD | Minimum | Maximum |
|---|---|---|---|---|---|---|---|
| congruent | 270 | 0 | 744.11 | 746.26 | 104.95 | 418.93 | 1020.82 |
| incongruent | 270 | 0 | 891.34 | 900.77 | 141.76 | 442.96 | 1358.57 |

兩個水準各 270 筆且無遺漏，與寬格式的 270 列、各欄遺漏值 0 一致，表示轉換沒有遺失或重複觀察值。
回覆程式碼沒有印出各欄平均數，所以這個對照只驗證筆數與完整性。欄位對應另以原始資料核對：
Rj 顯示的前 6 位受試者的 `congruent`／`incongruent` 數值，與長格式資料中對應的列逐一相符。

## 本檔的歷史

2026-09-17 的第一版中，Rj 只執行了 `summary(data)`，沒有執行模型的轉換程式碼，也沒有做 cross-check，
因此判為 partial。2026-09-18 重做：先將畫面上當下顯示的回覆程式碼貼進 Rj 執行，再加上 Descriptives
對照分析。回覆在這之間經 askLLM 重跑而改變，本檔保存的是與 Rj 執行同源的版本。
