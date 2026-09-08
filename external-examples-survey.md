---
title: "外部教材真實例子盤點（供 literacy／prompts 改寫使用）"
---

# 說明

本檔案盤點 README 所列外部教材中，**可改寫用於本站教學情境的具體例子**，並確認授權與署名要求。查證日期 2026-09-08，方法：`WebFetch` 逐頁讀取各教材目錄頁與內容頁（章節 HTML）。

**這是研究文件，不是規格**：本檔案只記錄「讀到什麼」，不修改 `literacy/`、`prompts/entries/` 或其他既有檔案。

**標記說明**：
- **[頁面實讀]**：我直接 WebFetch 該頁並讀到具體內容，下方引用可回溯到該 URL。
- **[目錄推測]**：只根據目錄標題推測，未打開內文頁確認，會在「查不到或無法確認」一節列出。
- **[承襲 PROPOSAL]**：`PROPOSAL.zh-TW.md` §6 已在同日（2026-09-08）查證過的授權資訊，本次未重新驗證，直接引用。

---

# 1. 可用資料集清單

| # | 資料集 | 出自 | 章節 URL | 變項結構 | 樣本數 | 是否可下載／內建 | 適配對象 |
|---|---|---|---|---|---|---|---|
| 1 | `experiment_data.csv` + `participant_data.csv`（Stroop） | psyteachr **data-skills-v3** | [`stroop.html`](https://psyteachr.github.io/data-skills-v3/stroop.html) **[頁面實讀]** | 連續：`reaction_time`（毫秒）；類別：`condition`（congruent/incongruent, 2 水準）、`gender`；`participant_id` 為 key。長格式 540 列、寬格式（人口學）270 列 | 270 位參與者 | 可下載，課程材料站的 `stroop_data.zip`（頁面未給出直接 URL，僅提到檔名） | **第 1 課**（連續 + 類別對照範例，比 harpo.csv 更貼近心理實驗情境） |
| 2 | `harpo.csv`（Dr. Harpo 統計課成績） | **lsj-book** ch.11 | [`11-Comparing-two-means.html`](https://davidfoxcroft.github.io/lsj-book/11-Comparing-two-means.html) **[頁面實讀]** | 連續：`grade`；類別：`tutor`（Anastasia/Bernadette, 2 水準）；`ID` | 33（15 + 18） | 課本原生範例資料（Navarro 原作沿用），jamovi 可透過 lsj 附加模組取得（頁面提及但未給直接連結） | **第 1 課**（最簡單的「連續 + 類別」對照，變項只有 3 欄，適合初學者一眼看懂） |
| 3 | Zwaan et al. (2018) Simon task（縮減版） | psyteachr **analysis-v4** ch.7 | [`07-independent.html`](https://psyteachr.github.io/analysis-v4/07-independent.html) **[頁面實讀]** | 連續：`congruent`、`incongruent`（反應時間 ms）、`simon_effect`（=incongruent − congruent）；類別：`similarity`（same/different, 2 水準，between-subjects）、`gender`、`education` | 160（80 + 80） | 原始資料在 OSF：https://osf.io/ghv6m/ | **提示詞「t 檢定前提」**：頁面本身就示範了 Shapiro-Wilk、Levene's test、Welch vs Student 的完整判斷流程，比虛構的 `score`/`group` 例子更真實 |
| 4 | `zeppo.csv` / `chico.csv` / `awesome.csv` / `happiness.csv` / `afl.margins` | **lsj-book** ch.11 | 同上 URL **[頁面實讀]** | `zeppo`：一樣本；`chico`：`ID`、`grade_test1`、`grade_test2`（配對）；`awesome`/`happiness`：兩組非參數比較範例 | zeppo N=20；chico N=20 | Navarro 原作沿用的經典教學資料（非真實研究資料，是虛構的教學情境，但變項結構真實可查） | 次要備選，若需要「配對 t 檢定」或「非參數替代方案」的具體例子可用 |
| 5 | Zhang et al. (2014) Study 3（time capsule effect） | psyteachr **analysis-v4** ch.13 | [`13-factorial-anova.html`](https://psyteachr.github.io/analysis-v4/13-factorial-anova.html) **[頁面實讀]** | between：`Condition`（Ordinary/Extraordinary, 2 水準）；within：`Time`（T1 預測興趣 vs. T2 實際興趣，2 水準）；連續結果：興趣分數（`T1_Pred_Interest_Comp`/`T2_Interest_Comp`） | 130（完成兩時間點者） | 原始資料在 OSF：https://osf.io/t2wby/ | **提示詞「混合設計 ANOVA」**：這是真正的 2×2 mixed factorial（1 between + 1 within），比目前 `mixed-anova-setup.yaml` 情境描述（自創三時間點+組別）更貼近教材原例，可直接標出處 |
| 6 | `clinicaltrial.csv`（drug × therapy × mood.gain） | **lsj-book** ch.13／ch.14 | [`13-Comparing-several-means-one-way-ANOVA.html`](https://davidfoxcroft.github.io/lsj-book/13-Comparing-several-means-one-way-ANOVA.html)、[`14-Factorial-ANOVA.html`](https://davidfoxcroft.github.io/lsj-book/14-Factorial-ANOVA.html) **[頁面實讀]** | `drug`（placebo/anxifree/joyzepam, 3 水準）、`therapy`（CBT/no therapy, 2 水準）、`mood.gain`（連續） | 18（3×2 平衡設計，每格 3 人） | Navarro 原作沿用；**頁面明文說明這是虛構資料**（"fictitious, created for instructional purposes"），不是真實研究 | **第 2 課 ANOVA 情境**（目前 `satisfaction`/`department` 是自創變項，這組雖是教學虛構資料但變項名稱與設計均真實可查、有出處） |
| 7 | `rtfm.csv`、`ancova.csv` | **lsj-book** ch.14 | 同上（`14-Factorial-ANOVA.html`）**[頁面實讀]** | `rtfm`：`grade`、`attend`(2)、`reading`(2)，2×2；`ancova`：`happiness`、`stress`(2)、`commute`(2) + 共變量 `age` | rtfm N=8；ancova 未列 | 同上，Navarro 原作虛構教學資料 | 備選（rtfm 用於示範 ANOVA=迴歸；ancova 用於 ANCOVA，超出目前 8 組對照範圍） |
| 8 | Lopez et al. (2024) 湯碗研究（soup bowl） | psyteachr **analysis-v4** ch.9 | [`09-correlation.html`](https://psyteachr.github.io/analysis-v4/09-correlation.html) **[頁面實讀]** | 連續：`CalEstimate`、`OzEstimate`（估計攝取量）、`M_postsoup` 等實際攝取量；類別：`Condition`（對照組／實驗組） | 464（原始 632，篩選後） | 已發表於 *JEP: General*（2024），資料可能隨論文公開（頁面未給直接下載連結） | **第 2 課相關情境**（目前 `anxiety`/`sleep_hours` 是自創變項，此例是真實已發表複現研究，可替換） |
| 9 | Dawtry et al. (2015)、Lopez et al. (2023) | psyteachr **quant-fun-v3** ch.11 | [`11-screening-data.html`](https://psyteachr.github.io/quant-fun-v3/11-screening-data.html) **[頁面實讀]** | Dawtry：`Household Income`、`Political Preference`、`age`、`gender`、Gini 指數等；Lopez：`ParticipantID`、`Sex`、`Age`、`Ethnicity`、`OzEstimate`、`Condition` | 未在頁面列出精確 N | 頁面提供已清理版 CSV 檔名（`Dawtry_2015_clean.csv`、`Lopez_2023.csv`），但未給下載連結 | **提示詞「遺漏值分流」**：章節直接教 `summary()` 抓 NA、`tidyr::drop_na()` 刪除、記錄刪除前後 `nrow()`，可對應目前 `missing-data-triage.yaml` 的三步驟問法 |
| 10 | reprores-v6 附錄 E 資料集庫（含 `stroop.csv`、`disgust_scores.csv`、`personality.csv` 等 54 個檔） | psyteachr **reprores-v6** | [`app-datasets.html`](https://psyteachr.github.io/reprores-v6/app-datasets.html) **[頁面實讀，但變項細節未讀到]** | 頁面只列檔名，變項與 codebook 在另外的 Psych-DS JSON 檔，本次未下載確認 | 未知 | 有 zip 打包下載 | 僅供「還有更多資料可選」備查，**細節需下載才能用，見第 4 節** |

---

# 2. 可用分析情境清單

| # | 情境 | 出自 | 章節 URL | 內容重點 | 適配對象 |
|---|---|---|---|---|---|
| A | 獨立樣本 t 檢定的完整假設檢查流程 | analysis-v4 ch.7 + lsj-book ch.11 | 見上表 #3、#2 | analysis-v4：對 Zwaan 資料做 Q-Q plot、Shapiro-Wilk、Levene's test（`F(1,158) = 0.73, p = .395`），並明文寫出「Welch 適用於變異數不等時，且不受 Levene 結果影響仍建議優先用」。lsj-book ch.11：「in real life I tend to prefer the Welch test, because almost no-one actually believes that the population variances are identical」 | **提示詞「t 檢定前提」**（`prompts/entries/ttest-assumptions.yaml`）：目前的 `expected` 清單（Welch 優先、Levene、Mann-Whitney 替代）與這兩章的實際內容**高度吻合**，可直接把 `links` 從泛泛的「ch.11」改指到這兩個具體 URL |
| B | 遺漏值篩檢三步驟：`summary()` 找 NA → `drop_na()` 刪除 → 記錄刪除前後列數 | quant-fun-v3 ch.11 | `11-screening-data.html` **[頁面實讀]** | 章節坦承「未深入處理遺漏機制（MCAR/MAR/MNAR）與插補」，這點與目前 `missing-data-triage.yaml` 的 expected 條目「明確說明它看不到遺漏的『型態』」**互相呼應**——可以在 prompt 條目的參考連結旁加一句「連教科書本身都止步於刪除法，插補需要你自己判斷前提」 | **提示詞「遺漏值分流」** |
| C | 2×2 混合設計 ANOVA（1 個 between + 1 個 within） | analysis-v4 ch.13 | `13-factorial-anova.html` **[頁面實讀]** | Zhang et al. (2014) time capsule effect：between=`Condition`（Ordinary/Extraordinary），within=`Time`（T1 預測 vs. T2 實際） | **提示詞「混合設計 ANOVA」**（`prompts/entries/mixed-anova-setup.yaml`）：目前情境是自創「三時間點欄+組別欄」，若改用這個真實 2×2 例子，變項換成 `Condition`（2 水準 between）與 `Time`（2 水準 within），流程（寬轉長格式）完全適用，且有出處可查 |
| D | 三水準單因子 ANOVA + 事後檢定（Holm 優於 Bonferroni） | lsj-book ch.13 | `13-Comparing-several-means-one-way-ANOVA.html` **[頁面實讀]** | `clinicaltrial.csv`：`drug`(3) × `mood.gain`；文中明講「no reason to use Bonferroni since it is always outperformed by Holm」；**未討論 Tukey** | **第 2 課**「Help me pick a model」那組改寫（目前用自創 `satisfaction`/`department`），可換成 `mood.gain`/`drug`，並註明教材建議事後檢定用 Holm 而非 Tukey（與本站目前提示詞未指定事後檢定方法形成對照，值得在課文提一句） |
| E | 相關分析：估計值 vs. 實測值 | analysis-v4 ch.9 | `09-correlation.html` **[頁面實讀]** | Lopez et al. (2024)：`CalEstimate`/`OzEstimate` vs. 實際攝取量，比較 `Condition` 兩組 | **第 2 課**「幫我做統計」那組改寫（目前用自創 `anxiety`/`sleep_hours`），可換成這組已發表複現研究的變項名 |
| F | 配對 t 檢定、非參數替代（Mann-Whitney、Wilcoxon） | lsj-book ch.11 | 同上 #2 | `chico.csv`（配對）、`awesome.csv`（Mann-Whitney）、`happiness.csv`（Wilcoxon） | 備選：若提示詞庫日後要新增「配對比較」或「非參數替代」條目可用 |

---

# 3. 授權與署名寫法範例（每句可直接貼進 `.qmd`，英文）

授權底色沿用 `PROPOSAL.zh-TW.md` §6 的既有查證結果（**[承襲 PROPOSAL]**，同日 2026-09-08，本次未重新驗證授權文字本身，只重新驗證了「內容页面上實際顯示的版權腳注」，見下方各條的頁面實讀補充）：

| 來源 | 授權 | 建議署名句（英文，可直接貼） |
|---|---|---|
| psyteachr **data-skills-v3**（Stroop 章） | CC BY-SA 4.0（repo LICENSE，**[承襲 PROPOSAL]**；頁面本身未顯示授權字樣，本次 WebFetch 確認） | `Example adapted from psyteachr's *Data Skills* (Nordmann), stroop.csv / participant data, CC BY-SA 4.0, https://psyteachr.github.io/data-skills-v3/stroop.html — this adaptation is shared under the same license.` |
| psyteachr **analysis-v4**（two-sample / correlation / factorial-ANOVA 章） | CC BY 4.0 — 頁腳實讀確認為 **"CC-BY (2025) Gaby Mahrholz Carolina E. Kuepper-Tetzel"** | `Example adapted from psyteachr's *Analysis* (Mahrholz & Kuepper-Tetzel, 2025), CC BY 4.0, https://psyteachr.github.io/analysis-v4/07-independent.html.` （依章節換 URL） |
| psyteachr **quant-fun-v3**（遺漏值章） | CC BY-SA 4.0 — 頁腳實讀確認為 **"CC-BY-SA-4.0 (2024) James Bartlett & Wilhelmiina Toivo"** | `Example adapted from psyteachr's *Fundamentals of Quantitative Analysis* (Bartlett & Toivo, 2024), CC BY-SA 4.0, https://psyteachr.github.io/quant-fun-v3/11-screening-data.html — this adaptation is shared under the same license.` |
| **lsj-book**（比較兩均數 / ANOVA 章） | CC BY-SA 4.0（**[承襲 PROPOSAL]**，repo README） | `Example adapted from *Learning Statistics with jamovi* (Navarro & Foxcroft, 2025, Open Book Publishers, DOI 10.11647/OBP.0333), CC BY-SA 4.0, https://davidfoxcroft.github.io/lsj-book/11-Comparing-two-means.html — this adaptation is shared under the same license.` |
| psyteachr **reprores-v6**（附錄 E 資料集庫，若日後要用） | CC BY — 頁腳實讀確認為 **"CC-BY 2026, psyTeachR"** | `Dataset list adapted from psyteachr's *Reproducible Research with R* (2026), CC BY, https://psyteachr.github.io/reprores-v6/app-datasets.html.` |
| **bradduthie/stats** | CC BY-NC-SA 4.0 — **不改寫、不節錄**，只可放純連結 | `Further reading (external, not adapted): bradduthie's *Stats*, https://bradduthie.github.io/stats/ (CC BY-NC-SA 4.0).` |

**共同注意事項**：
- 凡標「this adaptation is shared under the same license」的（BY-SA 來源），本站若整體授權為 CC BY-SA 4.0（PROPOSAL §6 的建議），這句話才成立；若本站最終授權不是 BY-SA，改寫 BY-SA 來源時必須**該頁單獨聲明**沿用 BY-SA，不能套用全站授權。
- CC BY（無 SA）來源（analysis-v4、reprores-v6）改寫後可用本站自己的授權，只需保留署名句，不需「相同方式分享」字樣。

---

# 4. 查不到或無法確認的項目

| 項目 | 原因 |
|---|---|
| reprores-v6 附錄 E 內 54 個資料集各自的變項名稱、樣本數 | 頁面只列檔名與下載連結，變項/codebook 在 Psych-DS JSON 檔內，**需要下載 zip 才能確認**，本次未下載，不假裝已確認 |
| data-skills-v3 `stroop_data.zip` 的實際下載 URL | 頁面提到檔名但 WebFetch 摘要未回傳完整超連結，需要另外開頁面原始碼核對 |
| lsj-book 資料集（`harpo.csv`、`clinicaltrial.csv` 等）在 jamovi 內建模組或 learnstatswithjamovi.com 的確切下載路徑 | 目錄頁提到「可透過附加模組取得」，但未實際點開下載頁核對連結是否有效 |
| stat-models-v1 各章的具體資料集 | 只讀了目錄頁（**[目錄推測]**），未進入任何章節內文；本教材超出 jamovi GUI 範圍（線性混合模型），依 PROPOSAL §6 定位為「進階閱讀」連結而非改寫來源，故未深入查證 |
| quant-fun-v3 ch.13 Factorial ANOVA 的具體資料集 | 只確認了 ch.11（遺漏值）與目錄頁；ch.13 內文本次未 WebFetch，不確定是否與 lsj-book 的 `clinicaltrial.csv` 重複或另有情境 |
| psyteachr data-skills-v3 除 Stroop 外的其他 7 個資料集（Corsi Blocks、Belonging、Big Five、Resilience） | 只讀了目錄頁標題（**[目錄推測]**），本次未逐一開章節確認，若後續要找更多「連續+類別」候選，這些章節值得追查但本次未做 |
| Dawtry (2015) / Lopez (2023) 資料集的精確樣本數與下載連結 | quant-fun-v3 ch.11 頁面給了清理後檔名，但未提供直接下載 URL 或精確 N，本次 WebFetch 摘要未回傳 |
| 各 lsj-book 資料集在頁面上是否有明確版權聲明 | 章節內文本次 WebFetch 摘要未回傳版權腳注文字（只回傳「Open Book Publishers」等出版資訊），授權判斷沿用 PROPOSAL §6 的 repo README 查證，未在頁面本身找到逐字聲明 |

---

# 5. 對「第 1 課開場故事」的具體建議

**結論：外部教材裡沒有「LLM 犯錯」的故事可用——這些書全是統計教材，不涉及生成式 AI。** 我讀過的六本／目錄頁完全沒有任何段落討論 LLM、AI 協作或幻覺；這點不是推測，是逐頁讀過目錄與多個章節內文後的確認結果。

**建議：改用 `askLLM/docs/LIMITATIONS.zh-TW.md` 裡的真實實測記錄**，具體理由與可用素材如下（此檔為母專案文件，只讀不改）：

1. **最貼合現有敘事結構的一段**：`LIMITATIONS.zh-TW.md` §3（綜合使用建議第 3 點）提到「不勾選 Attach data summary 時模型完全在猜（實測曾憑空生出『8 個樣本、Saguaro/Palo Verde 三個物種』這種與資料無關的內容）」——這是**真實發生過**的幻覺案例，且與目前 `01-what-the-llm-sees.qmd` 「第 47 筆偏高」的故事結構完全對應（模型自信地講出資料裡不存在的具體內容），可以直接取代虛構故事，且更有說服力，因為它是本專案自己的實測記錄而非杜撰情境。

2. **另一個可用、甚至更適合當開場的段落**：LIMITATIONS §1「jamovi 選單路徑最常出錯」列出一整張**逐字對照表**（模型寫的路徑 vs. 為什麼錯，例如「分析 > 比較 > 獨立樣本t檢定」——jamovi 根本沒有「比較」這個選單；「分類 > 判別分析」——jamovi 內建根本沒有這個選單）。這張表本身就是「語氣篤定但全錯」的絕佳示範，且已有 v1.1 緩解機制的對照數據（0/N 可機械核對 → 18/18 命中），故事張力比虛構的「第 47 筆」更強，還能自然帶出第 4 課「選對分析、選對 Persona」與第 6 課「問完之後」的查核動作。

3. **具體改寫建議**：
   - 若只換開場情境、保留「摘要看不到什麼」的教學重點不變，用 LIMITATIONS §3 的 Saguaro/Palo Verde 案例最省事，句型可直接套用原本「有個使用者問…回覆很篤定…」的敘事骨架。
   - 若想同時強化「路徑要逐字核對」這個貫穿全站的原則，用 LIMITATIONS §1 的選單路徑錯誤表更合適，且可以順勢引用 v1.1 緩解機制的「18/18 命中」數字，讓學生看到「這件事後來被系統性修好了」，帶出正向結尾。
   - 兩者都應標明來源為「本專案 `askLLM` 的實測記錄（`tools/compare-models.R`，2026-07-21／2026-07-23）」，不是外部教材，避免讀者誤以為這是 psyteachr 或 lsj-book 的內容。
   - 外部教材（尤其 lsj-book、analysis-v4）仍可在第 1 課「動手做」環節派上用場——例如把「動手做」的示範資料換成本檔第 1 節列出的 `harpo.csv` 或 Stroop 資料，讓練習素材與開場故事分開處理：**開場故事用 askLLM 真實案例，練習資料用外部教材真實資料集**，兩者互補。
