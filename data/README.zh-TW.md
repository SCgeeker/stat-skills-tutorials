> [English](README.md) · **繁體中文**

# 實測證據檔（`.omv`）

本目錄存放提示詞條目的實測記錄。每個 `.omv` 是一次完整的 jamovi 工作階段，內含 askLLM 的實際
回覆與用來查核的後續分析。條目 `tested_with` 欄位的 note 會引用這裡的檔名。

命名規則：`<條目 id>_<第一作者><年>_<語言>.omv`。`missing-data-triage` 的 `check` 含 cross-check
步驟（同一題換 persona 再問一次比對），需要兩次執行並存，故額外加 `_<persona>` 後綴。`mixed-anova-setup` 的提示詞於 2026-09-09 修正過，故其檔案以
`v1_fail` 或 `v2_fix` 標示是哪一版措辭產生的。

| 檔案 | 條目 | 語言 | 內含分析 |
|---|---|---|---|
| `ttest-assumptions_zwaan2018_zhTW.omv` | `ttest-assumptions` | 繁中 | askllm、ttestIS |
| `ttest-assumptions_zwaan2018_en.omv` | `ttest-assumptions` | 英文 | askllm、ttestIS、anovaNP |
| `missing-data-triage_dawtry2015_zhTW_explainer.omv` | `missing-data-triage` | 繁中 | askllm（explainer）、descriptives |
| `missing-data-triage_dawtry2015_zhTW_consultant.omv` | `missing-data-triage` | 繁中 | askllm（consultant）、descriptives |
| `missing-data-triage_dawtry2015_en_explainer.omv` | `missing-data-triage` | 英文 | askllm（explainer） |
| `missing-data-triage_dawtry2015_en_consultant.omv` | `missing-data-triage` | 英文 | askllm（consultant）、descriptives |
| `mixed-anova-setup_zhang2014_v1_fail_zhTW.omv` | `mixed-anova-setup` | 繁中 | askllmr、Rj（修正前的提示詞） |
| `mixed-anova-setup_zhang2014_v1_fail_en.omv` | `mixed-anova-setup` | 英文 | askllmr、Rj（修正前的提示詞） |
| `mixed-anova-setup_zhang2014_v2_fix_zhTW.omv` | `mixed-anova-setup` | 繁中 | askllmr、Rj、anovaRM（修正後的提示詞） |
| `mixed-anova-setup_zhang2014_v2_fix_en.omv` | `mixed-anova-setup` | 英文 | askllmr、Rj、anovaRM（修正後的提示詞） |

實測日期 2026-09-08，全部使用 provider `gemini`、模型 `gemini-flash-latest`。`missing-data-triage`
的中文 explainer 那次於 2026-09-09 重跑，原因見最後一節。

## 重跑這些實測

每條條目的 `prompt` 都帶 `{佔位符}`。下表是實測當時填入的值，以及各自的資料來源。三個下載連結
於 2026-09-09 實測皆回 HTTP 200。

| 條目 | 資料集 | 下載 |
|---|---|---|
| `ttest-assumptions` | Zwaan et al. (2018) Simon task | <https://psyteachr.github.io/analysis-v4/data/data_ch7.zip>（解壓後用 `MeansSimonTask.csv`） |
| `missing-data-triage` | Dawtry et al. (2015) | <https://psyteachr.github.io/quant-fun-v3/data/Dawtry_2015_clean.csv> |
| `mixed-anova-setup` | Zhang et al. (2014) Study 3 | <https://psyteachr.github.io/analysis-v4/data/data_ch13.zip>（含 `Zhang_2014_Study3.csv` 與 codebook） |

| 條目 | 佔位符 | 值 |
|---|---|---|
| `ttest-assumptions` | `{outcome}` / `{group}` / `{n1}` / `{n2}` | `simon_effect` / `similarity`（same、different）/ 80 / 80 |
| `missing-data-triage` | `{var_a}` / `{pct_a}` / `{var_b}` / `{pct_b}` | `Household_Income` / 1.3 / `Political_Preference` / 1.3 |
| `mixed-anova-setup` | `{id}` / `{group}` / `{t1}` / `{t2}` | `Participant_ID` / `Condition` / `T1_Pred_Interest_Comp` / `T2_Interest_Comp` |

看數字之前有兩件事要知道。`simon_effect` 不是檔案裡現成的欄位，實測時是以
`session1_incongruent − session1_congruent` 算出來的，這就是它與 psyteachr 數字不同的原因
（見下方陷阱一節）。另外 jamovi 的 Descriptives 面板顯示的遺漏是筆數不是百分比，上表的 1.3%
是 305 筆裡的 4 筆。

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
psyteachr 文中的 n = 130 是篩選後的數字，不是檔案列數。兩個數字並不矛盾：`T2_Interest_Comp`
有 22 筆遺漏，152 − 22 = 130，所以 304 列長格式裡有 282 筆有效觀察。重複量數 ANOVA 會排除
不完整的個案，這就是它的 residual df 為 128（130 − 2 組）的原因。

## `.omv` 裡存的回覆未必是當次執行的那一份

只要 `submit` 還勾著，jamovi 每次開檔或資料變更都會重跑分析，askLLM 就再打一次 API 並覆蓋畫面上
既有的回覆。英文 `v2_fix` 那份前後共產生三個樣本（變數名分別為 `id_col`、`time_cols`、`id_var`），
而 `08 Rjp` 裡保存的程式碼只屬於其中一次。

取消勾選 `submit` 也不能凍結答案：`askLLM/R/askllmr.b.R:58` 的守門會直接 return 並把結果區換成
導引文字，回覆就沒了。

**對記錄的要求**：`tested_with[].note` 必須寫明判定依據是「當次貼入 Rj 的程式碼與其執行結果」，
而非 `.omv` 當下顯示的回覆。回覆全文要另存一份（工作稿或 `spot-the-error.qmd` 題目），光靠 `.omv`
保不住。

附帶一提，英文那三個樣本全都符合修正後的格式規範，這是提示詞修正穩健的旁證，不是雜訊。

## cross-check 的變項控制（2026-09-09 記）

`missing-data-triage` 的 `check` 第三步是「換 consultant persona 再問一次，比對兩次的交回使用者
決定清單」。這是**單一變項比較**：除了 `role`，其餘設定都必須相同。

英文那組符合：兩份都未設 `promptLang`（預設 `en`），只有 `role` 不同。

中文那組**原本不符合**：`_zhTW_explainer` 未設 `promptLang`（因此是預設的 `en`），`_zhTW_consultant`
設為 `zh`，兩次同時變動了 persona 與 prompt 語言。已於 2026-09-09 以 `promptLang = zh` 重跑
explainer 修正，現在兩份僅 `role` 不同，問題文字 sha1 相同，比較成立。

驗證方式（不要只看 `index.html` 的呈現，要直讀 analysis payload）：

```bash
unzip -o -q <檔名>.omv -d <目錄>
strings "<目錄>/NN askllm/analysis" | grep -oE 'promptLang = "[a-z]+"|role = "[a-z]+"'
```

未列出的參數代表採用 `askllm.a.yaml` 的預設值：`role` 預設 `consultant`（第 95 行）、
`promptLang` 預設 `en`（第 105 行）。**參數沒出現不等於沒有作用**，這是最容易誤判的地方。
