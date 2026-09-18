# long-to-wide-check_stroop_zhTW

> 本檔是模型回覆的**穩定副本**。`.omv` 內的回覆會被 askLLM 的重跑覆蓋
> （`submit` 勾著時每次開檔都重打 API），因此不能只靠 `.omv` 保存。
> 抽取來源：`long-to-wide-check_stroop_zhTW.omv` 的 `02 askllmr`；Rj 實際執行的程式碼與輸出見
> `06 Rjp`。

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

library(tidyverse)

# --- 參數設定 ---
id_col <- "participant_id"
names_col <- "condition"
values_col <- "reaction_time"

# --- 長格式轉寬格式 ---
wide_data <- data %>%
  pivot_wider(
    id_cols = all_of(id_col),
    names_from = all_of(names_col),
    values_from = all_of(values_col)
  )

# --- 核對結果 ---
# 1. 檢查資料維度 (列數與欄數)
dim(wide_data)

# 2. 檢查是否有任何遺漏值 (轉置完整應為 0)
sum(is.na(wide_data))

# 3. 預覽前 6 筆資料
head(wide_data)

這段程式碼使用 `tidyverse` 將長格式的 `data` 依照受試者編號與實驗情境重組成寬格式，方便後續進行成對樣本 t 檢定。

### 核對說明：
執行後請檢查輸出結果是否符合以下數值：
1. **`dim(wide_data)`**：應顯示 `[1] 270   3`（代表 270 位受試者，以及 `participant_id`、`congruent`、`incongruent` 共 3 個欄位）。
2. **`sum(is.na(wide_data))`**：應顯示 `[1] 0`（代表每位受試者在兩種情境下都有對應的反應時間，沒有產生遺漏值）。
3. **`head(wide_data)`**：確認每位受試者的 `congruent` 與 `incongruent` 反應時間數值各自獨立成欄。

請將上述程式碼複製貼進 jamovi 的 Rj Editor 並按下 Run，若有任何錯誤訊息請再回報給我！

## Rj 實際執行的程式碼與輸出

> **⚠️ 這一份 Rj 實際執行的不是上面回覆貼的程式碼。** 檔案裡 `06 Rjp` 貼進去執行的是
> `summary(data)`，並不是模型回覆的 `pivot_wider()` 骨架。判定依據是這裡的 Rj 實際執行
> 程式碼與輸出，不是回覆文字本身。

```r
summary(data)
```

輸出：

```text
 participant_id       condition   reaction_time   
 1      :  2    congruent  :270   Min.   : 418.9  
 2      :  2    incongruent:270   1st Qu.: 716.7  
 3      :  2                      Median : 811.0  
 4      :  2                      Mean   : 817.7  
 5      :  2                      3rd Qu.: 913.6  
 6      :  2                      Max.   :1358.6  
 (Other):528                                      
```
