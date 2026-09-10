# missing-data-triage_dawtry2015_en_consultant

> 本檔是模型回覆的**穩定副本**。`.omv` 內的回覆會被 askLLM 的重跑覆蓋
> （`submit` 勾著時每次開檔都重打 API），因此不能只靠 `.omv` 保存。
> 抽取來源：`missing-data-triage_dawtry2015_en_consultant.omv` 的 `06 askllm/analysis`。

| 項目 | 值 |
|---|---|
| 分析 | jamovi Module Guider (askllm) |
| persona (`role`) | `consultant (預設)` |
| 提示詞語言 (`promptLang`) | `en (預設)` |
| provider / model | `gemini` / `gemini-flash-latest` |

## 送出的問題

```
The summary shows Household_Income has 1.3% missing and Political_Preference has 1.3% missing.

In beginner-friendly terms, please answer:
1. Is this level of missingness serious?
2. Which jamovi analysis (exact menu path) lets me see whether missingness clusters by group?
3. Which treatment decisions (e.g. deletion vs. imputation) depend on my research design, so you cannot make them for me?
```

## 模型回覆（逐字）

### 1. Is this level of missingness serious?
**No.** With only 4 missing cases out of 305 (1.3%), the missingness is very low. In applied statistics, missing data below 5% is generally considered negligible and rarely introduces meaningful bias or loss of statistical power.

---

### 2. Which jamovi analysis lets you see whether missingness clusters by group?
To inspect missing counts across categories directly:
* **`Analyses > Exploration > Descriptives`**  
  *(Place `Household_Income` in the **Variables** box and `Political_Preference` in the **Split by** box. The descriptives table will display the exact count of missing values for each political group.)*

If you create an indicator variable in the spreadsheet to flag missing values (e.g., `0 = Present, 1 = Missing`), you can formally test whether missingness is associated with group membership using:
* **`Analyses > Frequencies > Contingency Tables > Independent Samples — χ² test of association`**

---

### 3. Which treatment decisions depend on your research design?
* **Assessing the Missingness Mechanism (MCAR vs. MAR vs. MNAR):** You must determine *why* the data are missing based on how the survey was administered. For example, if higher-income respondents deliberately refused to disclose their income, the data are *Missing Not at Random (MNAR)*, which can introduce bias regardless of the sample size.
* **Complete-Case Deletion vs. Imputation:** With only ~1.3% missing, default listwise deletion (dropping those 4 rows in analyses requiring both variables) is standard and usually safe if the data are missing at random. However, if your research protocol, field standards, or preregistration require retaining every case, you would need to justify and choose an imputation method.r

