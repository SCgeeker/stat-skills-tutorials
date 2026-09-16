# describe-first-look_stroop_en

> 本檔是模型回覆的**穩定副本**。`.omv` 內的回覆會被 askLLM 的重跑覆蓋
> （`submit` 勾著時每次開檔都重打 API），因此不能只靠 `.omv` 保存。
> 抽取來源：`describe-first-look_stroop_en.omv` 的 `06 askllm`。

| 項目 | 值 |
|---|---|
| 分析 | jamovi Module Guider (askllm) |
| persona (`role`) | `explainer` |
| 提示詞語言 (`promptLang`) | `en (預設)` |
| provider / model | `gemini` / `gemini-flash-latest` |

## 送出的問題

```
reaction_time is continuous, condition has 2 levels, and participant_id identifies the
participant. Each participant has one row per level.

Please answer in beginner-friendly terms:
1. Which descriptive statistics should I look at first? Give the exact menu path.
2. Can you judge the shape of the distribution from this summary? If not, what
   should I do myself to judge it?
3. Which questions about this data can you not answer from summary statistics,
   so that I have to look at the raw data myself?
```

## 模型回覆（逐字）

### 1. Which descriptive statistics to look at first

Because you want to compare reaction times between the two conditions, you should look at the descriptives **split by condition**:

* **Mean** (the mathematical average) and **Median** (the middle value when all numbers are ordered from lowest to highest) for each condition.
* **Standard Deviation (SD)** (a measure of how spread out the reaction times are around the average).
* **Minimum and Maximum** (the fastest and slowest responses in each condition).

To do this in jamovi, use this exact menu path:
* `Analyses > Exploration > Descriptives`

Put `reaction_time` into the **Variables** box, and put `condition` into the **Split by** box.

---

### 2. Can you judge the shape of the distribution from this summary?

**Only partially.** 
* The overall mean (817.7 ms) is fairly close to the median (811 ms), but the maximum (1359 ms) stretches further away from the median than the minimum does (418.9 ms). This suggests a possible slight **right skew** (a tail of unusually slow reaction times), which is very common in reaction time studies.
* However, this summary pools all 540 trials together. It cannot show you whether the distribution is **bimodal** (has two peaks), has extreme outliers, or whether each condition has a different shape.

**What you should do:**
In `Analyses > Exploration > Descriptives`, open the **Plots** section and check:
* **Histogram** or **Density**: To visually inspect whether the reaction times form a symmetrical bell curve or are skewed.
* **Box plot**: To visually spot potential outliers (extreme values shown as isolated dots).

---

### 3. Questions that cannot be answered without looking at the raw data

From the pooled summary alone, you cannot see:
1. **The condition effect:** How reaction times actually differ between `congruent` and `incongruent` trials.
2. **Within-participant differences:** Because each participant took part in both conditions (a paired design), the crucial question is *how much faster or slower each individual participant was in the congruent vs. incongruent condition*. Summary statistics of the whole column hide these individual pair-by-pair differences.
3. **Participant-level anomalies:** Whether specific participants were consistently very slow, made impossible responses, or had missing pairings.
