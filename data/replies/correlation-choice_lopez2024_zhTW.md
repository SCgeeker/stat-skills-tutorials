# correlation-choice_lopez2024_zhTW

> 本檔是模型回覆的**穩定副本**。`.omv` 內的回覆會被 askLLM 的重跑覆蓋
> （`submit` 勾著時每次開檔都重打 API），因此不能只靠 `.omv` 保存。
> 抽取來源：`correlation-choice_lopez2024_zhTW.omv` 的 `02 askllm`。

| 項目 | 值 |
|---|---|
| 分析 | jamovi Module Guider (askllm) |
| persona (`role`) | `consultant (預設)` |
| 提示詞語言 (`promptLang`) | `zh` |
| provider / model | `gemini` / `gemini-flash-latest` |

## 送出的問題

```
CalEstimate 與 OzEstimate 都是連續變項，各有 622 與 622 筆有效值。

請回答以下三件事：
1. 該用 Pearson 還是 Spearman？判斷依據是什麼？請給逐字選單路徑。
2. 這個判斷需要哪些你從摘要統計看不到的資訊？請明說。
3. 若兩個變項的遺漏筆數不同，相關分析會怎麼處理？我該注意什麼？
```

## 模型回覆（逐字）

針對您的問題，依據提供的摘要資訊回答如下：

### 1. 該用 Pearson 還是 Spearman？判斷依據與選單路徑
* **建議優先考慮 Spearman 相關**（或兩者對照）：
  * **判斷依據**：Pearson 相關要求雙變項常態分佈且呈線性關係；Spearman 則適用於單調關係、偏態資料或有極端值的情況。摘要顯示 `CalEstimate`（平均數 138.3 vs 中位數 100，最大值 1000）與 `OzEstimate`（平均數 6.799 vs 中位數 4，最大值 100）的平均數均明顯大於中位數，且最大值極大，呈現明顯的**右偏與潛在極端值**，不符合 Pearson 常態性假設。
* **jamovi 逐字選單路徑**：
  * `Analyses > Regression > Correlation Matrix`
  * （在該分析設定中，可勾選「Pearson」或「Spearman」）

---

### 2. 判斷需要哪些摘要統計看不到的資訊？
* **散佈圖（Scatter plot）**：無法看出兩變項間是「線性關係」還是「非線性單調關係」，也無法確認是否存在嚴重的雙變量離群值（bivariate outliers）。
* **常態性檢定數據**：缺乏偏度（Skewness）、峰度（Kurtosis）之具體數值或常態性檢定（如 Shapiro-Wilk test）結果。

---

### 3. 遺漏筆數不同時的處理方式與注意事項
* **處理方式**：
  * jamovi 的相關矩陣預設會排除「任一變項有遺漏」的觀察值（Pairwise 或 Listwise 在兩兩相關時效果相同，僅保留兩變項皆有數值的成對資料）。
* **注意事項**：
  * **有效樣本數**：最終納入分析的樣本數可能少於個別變項的有效數（例如兩者各自遺漏 10 筆，若遺漏的列不重疊，實際分析樣本數可能介於 612 至 622 之間）。請在結果中確認報告的實際自由度或樣本數 $N$。
  * **遺漏機制**：需注意遺漏是否為隨機（Missing Completely at Random, MCAR），若遺漏與變項數值高低相關，可能導致相關係數估計產生偏誤。
