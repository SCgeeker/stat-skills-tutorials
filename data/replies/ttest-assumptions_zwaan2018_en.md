# ttest-assumptions_zwaan2018_en

> 本檔是模型回覆的**穩定副本**。`.omv` 內的回覆會被 askLLM 的重跑覆蓋
> （`submit` 勾著時每次開檔都重打 API），因此不能只靠 `.omv` 保存。
> 抽取來源：`ttest-assumptions_zwaan2018_en.omv` 的 `06 askllm/analysis`。

| 項目 | 值 |
|---|---|
| 分析 | jamovi Module Guider (askllm) |
| persona (`role`) | `consultant (預設)` |
| 提示詞語言 (`promptLang`) | `en (預設)` |
| provider / model | `gemini` / `gemini-flash-latest` |

## 送出的問題

```
simon_effect is continuous; similarity has two levels (n = 80, 80).

Please answer all three:
1. Which t-test should I run? How do I choose between Welch and Student?
2. Which Assumption Checks boxes should I tick in jamovi (give the exact menu path)?
3. If assumptions fail, what non-parametric alternative should I use, with its exact menu path?
```

## 模型回覆（逐字）

### 1. Which t-test to run and how to choose between Welch and Student
* **Analysis:** Run an **Independent Samples T-Test** comparing `simon_effect` (Dependent Variable) across the two levels of `similarity` (Grouping Variable).
  * Menu path: `Analyses > T-Tests > Independent Samples T-Test`
* **Student vs. Welch:** 
  * **Student's t-test** assumes equal variances between the two groups (homogeneity of variance).
  * **Welch's t-test** adjusts degrees of freedom and does not assume equal variances.
  * If Levene’s test of homogeneity is significant ($p < .05$), use **Welch's t-test**. If Levene's test is non-significant ($p \ge .05$), **Student's t-test** is acceptable (though Welch's is robust and commonly reported by default).

---

### 2. Assumption Checks to tick in jamovi
Open `Analyses > T-Tests > Independent Samples T-Test` and, under the **Assumption Checks** section, check:
* **Homogeneity** (runs Levene's test to test the equal-variance assumption).
* **Normality** (runs the Shapiro-Wilk test to test if distributions deviate from normality; you can also tick **Q-Q plot** for visual inspection).

---

### 3. Non-parametric alternative
If the normality assumption is violated:
* **Mann-Whitney U test**: Within the same analysis window (`Analyses > T-Tests > Independent Samples T-Test`), check the **Mann-Whitney U** box under the **Tests** section.
* Alternatively, run:
  * `Analyses > ANOVA > Non-Parametric > One-Way ANOVA — Kruskal-Wallis` (which is mathematically equivalent for two groups).r

