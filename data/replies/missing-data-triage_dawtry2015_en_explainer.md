# missing-data-triage_dawtry2015_en_explainer

> 本檔是模型回覆的**穩定副本**。`.omv` 內的回覆會被 askLLM 的重跑覆蓋
> （`submit` 勾著時每次開檔都重打 API），因此不能只靠 `.omv` 保存。
> 抽取來源：`missing-data-triage_dawtry2015_en_explainer.omv` 的 `06 askllm/analysis`。

| 項目 | 值 |
|---|---|
| 分析 | jamovi Module Guider (askllm) |
| persona (`role`) | `explainer` |
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
**No, it is generally considered minimal.** 
In your dataset, only 4 out of 305 responses (about 1.3%) are missing for each variable. In statistics, a missing rate under **5%** is widely viewed as negligible. At this low level, most standard analyses will not lose substantial statistical power (the ability to detect real effects) or suffer severe bias.

---

### 2. Which jamovi analysis lets you see whether missingness clusters by group?
To inspect whether missing values are concentrated in specific groups (for example, whether the 4 missing incomes all belong to a specific political preference), use:

* **`Analyses > Exploration > Descriptives`**

**How to use it:**
Place `Household_Income` into the **Variables** box and `Political_Preference` into the **Split by** box. Under the **Statistics** drop-down, ensure **Missing** is checked. This will display a table showing how many values are missing within each political group.

---

### 3. Which treatment decisions depend on your research design?
While the percentage is small, deciding *how* to handle missing data depends on your study's context:

* **Deletion (Complete-Case Analysis):** Automatically dropping rows with missing values. This is only safe if you can reasonably assume the data are *Missing Completely at Random* (MCAR)—meaning the missing values occurred purely by chance. If high-income respondents deliberately refused to answer, deleting them could bias your results.
* **Imputation:** Replacing missing values with estimated numbers (such as the group average or an algorithmically predicted value). This requires deciding whether artificial estimates are scientifically defensible for your research question.
* **Coding as a Distinct Category:** In survey research, refusing to answer political or income questions can sometimes be a meaningful attitude in itself (e.g., privacy concerns or political disaffection). Deciding whether "missing" holds substantive meaning depends entirely on what your study was designed to measure.r

