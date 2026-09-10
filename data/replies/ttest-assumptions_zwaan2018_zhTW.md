# ttest-assumptions_zwaan2018_zhTW

> 本檔是模型回覆的**穩定副本**。`.omv` 內的回覆會被 askLLM 的重跑覆蓋
> （`submit` 勾著時每次開檔都重打 API），因此不能只靠 `.omv` 保存。
> 抽取來源：`ttest-assumptions_zwaan2018_zhTW.omv` 的 `02 askllm/analysis`。

| 項目 | 值 |
|---|---|
| 分析 | jamovi Module Guider (askllm) |
| persona (`role`) | `consultant (預設)` |
| 提示詞語言 (`promptLang`) | `zh` |
| provider / model | `gemini` / `gemini-flash-latest` |

## 送出的問題

```
simon_effect 是連續變項，similarity 有兩組（n 分別為 80、80）。

請回答以下三件事：
1. 該用哪一個 t 檢定？Welch 與 Student 的選擇依據是什麼？
2. 我應該在 jamovi 的 Assumption Checks 勾選哪些項目（給逐字選單路徑）？
3. 若前提不符，請給一個非參數替代方案，並引用該分析的逐字選單路徑。
```

## 模型回覆（逐字）

針對您的問題，回答如下：

### 1. 該用哪一個 t 檢定與選擇依據
* **適用分析**：獨立樣本 t 檢定。
* **選擇依據**：
  * **Student's t**：需滿足「兩組變異數相等（同質性）」與「常態分佈」假設。
  * **Welch's t**：當兩組變異數不相等（Levene's 檢定 $p < .05$）時使用；即使變異數同質，Welch's t 的表現也相當穩健，因此現代統計實務常建議直接採用 Welch's t。

---

### 2. jamovi 的 Assumption Checks 與路徑
請前往以下逐字選單路徑：
* `Analyses > T-Tests > Independent Samples T-Test`

將 `simon_effect` 放入 **Dependent Variables**，`similarity` 放入 **Grouping Variable**。在下方 **Assumption Checks** 區塊中勾選：
* **Homogeneity test**（Levene 變異數同質性檢定）
* **Normality test**（Shapiro-Wilk 常態性檢定，可一併勾選 **Q-Q plot** 輔助視覺化判斷）

---

### 3. 前提不符的非參數替代方案
若常態性嚴重違規（或偏態過大），可採用以下非參數檢定方案：

* **方案 A（直接在 t 檢定介面中勾選）**：
  在 `Analyses > T-Tests > Independent Samples T-Test` 介面中的 **Tests** 區塊勾選 **Mann-Whitney U**。
* **方案 B（獨立模組選單）**：
  `Analyses > ANOVA > Non-Parametric > One-Way ANOVA — Kruskal-Wallis`（兩組情況下結果等同於 Mann-Whitney U 檢定）。r

