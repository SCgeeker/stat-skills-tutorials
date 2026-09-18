# regression-predictors_payne2008_zhTW

> 本檔是模型回覆的**穩定副本**。`.omv` 內的回覆會被 askLLM 的重跑覆蓋
> （`submit` 勾著時每次開檔都重打 API），因此不能只靠 `.omv` 保存。
> 抽取來源：`regression-predictors_payne2008_zhTW.omv` 的 `02 askllm`；jamovi 對照分析見
> `04 linReg`。

| 項目 | 值 |
|---|---|
| 分析 | jamovi Module Guider (askllm) |
| persona (`role`) | `explainer` |
| 提示詞語言 (`promptLang`) | `zh` |
| provider / model | `gemini` / `gemini-flash-latest` |

## 送出的問題

```
direct 是連續結果變項，indirect 是連續預測變項，manip 是編碼為 -1 與 1 的操弄變項，subject 是受試者編號。共 180 列，沒有遺漏。

請用初學者聽得懂的方式回答：
1. 我要用 indirect 與 manip 預測 direct，該用哪個分析？請給逐字選單路徑，並說明每個變項該放進哪一個欄位框。
2. 我列出的四個變項裡，有沒有哪一個不該進入這個模型？為什麼？
3. 共線性該怎麼查？這件事你能從我提供的摘要統計判斷嗎？
```

## 模型回覆（逐字）

為您逐步說明這三個問題：

### 1. 該使用哪個分析與欄位設定？

預測連續結果變項最合適且基礎的分析是**多元線性迴歸（Linear Regression）**。

* **選單路徑**：
  `Analyses > Regression > Linear Regression`
* **變項放置欄位**：
  * **Dependent Variable（依變項／結果變項）**：放入 `direct`（這是您想預測的目標）。
  * **Covariates（共變量／連續預測變項）**：放入 `indirect`。
  * **針對 `manip`**：因為資料摘要中 `manip` 為數值型（numeric，數值為 -1 與 1），您可以直接將它放入 **Covariates** 欄位；若您在資料欄位型態中將它設定為名義變項（Factor），則將它放入 **Factors（因子）** 欄位。

---

### 2. 有哪一個變項不該進入模型？為什麼？

* **不該放入的變項**：`subject`（受試者編號）。
* **原因**：
  `subject` 只是每位參與者的識別代碼（ID）。摘要顯示 180 列資料中就有 180 個不重複的代碼（每人僅一筆資料）。它不是具有實質預測意義的特徵。如果將它放進迴歸模型，會導致模型的估計自由度耗盡或嚴重過度配適（模型只是在死記每位受試者的代號，而無法學到普遍規律）。

---

### 3. 共線性該怎麼查？能從摘要統計判斷嗎？

* **什麼是共線性（Multicollinearity）？**
  共線性是指模型中的預測變項之間「高度重疊或高度相關」。當預測變項之間過度相關時，統計模型會難以分清各個預測變項對結果變項的個別影響力。
* **在 jamovi 中怎麼查？**
  在 `Analyses > Regression > Linear Regression` 分析面板中，展開下方的 **Assumption Checks（假設檢定）** 區塊，勾選 **Collinearity statistics（共線性統計量）**。
  Jamovi 會產出 **VIF（變異數膨脹因子，Variance Inflation Factor）**：
  * 一般標準認為，若 VIF 小於 5（嚴格標準）或小於 10，代表共線性問題不嚴重，可以安心解讀。
* **能從目前的摘要統計判斷嗎？**
  **不能。** 目前提供的摘要只有個別變項各自的平均數、標準差、極值等（單變項資訊），沒有包含 `indirect` 與 `manip` 兩者之間的相關性數據，因此無法單憑目前的摘要判斷共線性。
