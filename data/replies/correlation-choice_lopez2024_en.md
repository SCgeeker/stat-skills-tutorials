# correlation-choice_lopez2024_en

> 本檔是模型回覆的**穩定副本**。`.omv` 內的回覆會被 askLLM 的重跑覆蓋
> （`submit` 勾著時每次開檔都重打 API），因此不能只靠 `.omv` 保存。
> 抽取來源：`correlation-choice_lopez2024_en.omv` 的 `02 askllm`。

| 項目 | 值 |
|---|---|
| 分析 | jamovi Module Guider (askllm) |
| persona (`role`) | `consultant (預設)` |
| 提示詞語言 (`promptLang`) | `en (預設)` |
| provider / model | `gemini` / `gemini-flash-latest` |

## 送出的問題

```
CalEstimate and OzEstimate are both continuous, with 622 and 622 valid values
respectively.

Please answer all three:
1. Should I use Pearson or Spearman? On what basis do I decide? Give the exact
   menu path.
2. Which information does that decision need that you cannot see in the summary
   statistics? Say so plainly.
3. If the two variables have different numbers of missing values, how does the
   correlation handle that, and what should I watch for?
```

## 模型回覆（逐字）

**1. Pearson vs. Spearman, basis for decision, and menu path**
* **Recommendation:** **Spearman’s $\rho$** is likely more appropriate here. 
* **Basis:** Pearson’s $r$ assumes bivariate normality, a linear relationship, and is sensitive to extreme values. In your data, both variables exhibit strong positive skew (means are substantially higher than medians: 138.3 vs. 100 for `CalEstimate`, and 6.8 vs. 4 for `OzEstimate`, with large maximum values). Spearman rank correlation evaluates monotonic relationships and is robust to skewness and extreme values.
* **Exact menu path:**  
  `Analyses > Regression > Correlation Matrix` (check **Spearman** and/or **Pearson** under *Correlation Coefficients*).

---

**2. Information needed that cannot be seen in the summary statistics**
The summary statistics only provide univariate marginal distributions. They do **not** reveal:
* **Bivariate linearity or monotonicity:** Whether the two variables share a linear, curvilinear, or non-monotonic joint relationship.
* **Bivariate outliers:** Data points that fall well off the joint regression line even if their individual values are not extreme.
* You need to visually inspect a scatterplot (available in the same menu under *Plot > Correlation matrix*) to evaluate these features.

---

**3. Handling of differing missing values and what to watch for**
* **How it is handled:** Correlation calculates association pairwise. Any case that is missing data on *either* variable is excluded from that pair (pairwise complete cases). 
* **What to watch for:**
  * **Effective sample size ($N$):** If missing values do not fully overlap, the analyzed sample size ($N$) will be lower than the valid count of either variable alone.
  * **Missing data bias:** Watch for patterns in the missing data; if values are missing systematically rather than completely at random (MCAR), the resulting correlation estimate may be biased.
