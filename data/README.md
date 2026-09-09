# 實測證據檔（`.omv`）

本目錄存放提示詞條目的實測記錄。每個 `.omv` 是一次完整的 jamovi 工作階段，內含 askLLM 的實際
回覆與用來查核的後續分析。條目 `tested_with` 欄位的 note 會引用這裡的檔名。

命名規則：`<條目 id>_<第一作者><年>_<語言>.omv`

| 檔案 | 條目 | 語言 | 內含分析 |
|---|---|---|---|
| `ttest-assumptions_zwaan2018_zhTW.omv` | `ttest-assumptions` | 繁中 | askllm、ttestIS |
| `ttest-assumptions_zwaan2018_en.omv` | `ttest-assumptions` | 英文 | askllm、ttestIS、anovaNP |
| `missing-data-triage_dawtry2015_zhTW.omv` | `missing-data-triage` | 繁中 | askllm、descriptives |
| `missing-data-triage_dawtry2015_en.omv` | `missing-data-triage` | 英文 | askllm |
| `mixed-anova-setup_zhang2014_zhTW.omv` | `mixed-anova-setup` | 繁中 | askllmr、Rj |
| `mixed-anova-setup_zhang2014_en.omv` | `mixed-anova-setup` | 英文 | askllmr、Rj |

實測日期 2026-09-08，全部使用 provider `gemini`、模型 `gemini-flash-latest`。

## 資料來源與授權（重要）

**這些 `.omv` 內嵌了外部教材的資料集。** 本專案的 `LICENSE` 第 3 節適用：第三方素材維持其原授權，
本專案僅依授權條款再散布，並在此標明出處。

| 資料 | 出處 | 授權 |
|---|---|---|
| Zwaan et al. (2018) Simon task | psyteachr *Analysis* ch.7（Mahrholz & Kuepper-Tetzel, 2025），<https://psyteachr.github.io/analysis-v4/07-independent.html> | CC BY 4.0 |
| Dawtry et al. (2015) | psyteachr *Fundamentals of Quantitative Analysis* ch.11（Bartlett & Toivo, 2024），<https://psyteachr.github.io/quant-fun-v3/11-screening-data.html> | CC BY-SA 4.0 |
| Zhang et al. (2014) Study 3 | psyteachr *Analysis* ch.13（Mahrholz & Kuepper-Tetzel, 2025），<https://psyteachr.github.io/analysis-v4/13-factorial-anova.html> | CC BY 4.0 |

CC BY-SA 4.0 的素材（Dawtry）以相同方式分享。

## 變項定義的兩個陷阱

實測時踩過，記在這裡免得下次重蹈。

**`simon_effect` 的算法決定你會得到什麼數字。** psyteachr ch.7 頁面上的
`Levene F(1,158) = 0.73, p = .395`、`Welch t(157.14) = −0.92, p = .360` 是用**兩個 session 的
平均**算的。本目錄的 `.omv` 只用 session 1（`session1_incongruent − session1_congruent`），
因此得到 `Levene F = 0.01, p = .922`、`Student t(158) = −1.42, p = .159`。兩者都對，算的不是
同一個東西。

**Levene 的中心化方式也會造成落差。** 即使改用兩 session 平均，jamovi 印出的仍是
`F = 0.67, p = .416` 而非 0.73——`car::leveneTest` 預設 `center = median`，jamovi 的 ttestIS
用 `mean`。

**Zhang 資料的列數**：檔案原始為 152 列（35 欄，`T2_Finished` 未篩選），長格式應為 304 列。
psyteachr 文中的 n = 130 是篩選後的數字，不是檔案列數。
