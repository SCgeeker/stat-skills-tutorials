---
title: "外部教材真實例子盤點（第 2 輪）——多元迴歸與類別×類別關聯"
---

# 說明

承接 `external-examples-survey.md`（第 1 輪），補查 `examples_rewrite_20260908.md` §2
標記為「未找到」的第 6 組（多元迴歸：兩個連續預測變項 → 一個連續結果變項）與
第 8 組（兩個類別變項的關聯／列聯表）。查證日期 2026-09-08，方法：`WebFetch`
逐頁讀取各教材目錄頁與內容頁（章節 HTML）。

**這是研究文件，不是規格**：本檔案只記錄「讀到什麼」，不修改
`literacy/`、`prompts/entries/`、`external-examples-survey.md` 或其他既有檔案。

**標記說明（沿用第 1 輪體例）**：
- **[頁面實讀]**：我直接 WebFetch 該頁並讀到具體內容，下方引用可回溯到該 URL。
- **[目錄推測]**：只根據目錄標題推測，未打開內文頁確認，會在第 5 節列出。

**本輪查過的教材與結果總覽**：

| 教材 | 迴歸章節 | 是否有「兩個連續預測變項」 | 卡方／列聯表章節 | 是否為真實研究 |
|---|---|---|---|---|
| psyteachr **stat-models-v1** | `multiple-regression.html`（grades.csv） | **有**（3 個連續預測變項） | 無獨立章節 | 否，明講是模擬資料 |
| psyteachr **analysis-v4** | `11-multiple-regression.html`（Przybylski & Weinstein 2017） | 無（1 連續 + 1 類別 + 交互作用） | `06-chi-square-one-sample.html`（Ballou et al. 2024） | 迴歸：**是**；卡方：**是** |
| psyteachr **quant-fun-v3** | `14-multiple-regression.html`（同一 Przybylski & Weinstein 2017 資料集） | 無（同上，只 1 連續 + 1 類別） | 目錄無獨立卡方章節 | 迴歸：**是** |
| psyteachr **data-skills-v3** | `resilience-2.html`、`belonging-2.html` 讀過，均無迴歸模型 | 無 | 目錄未見 | — |
| **lsj-book** | ch.12 `Correlation-and-linear-regression.html`（parenthood.csv） | **有**（2 個連續預測變項） | ch.10 `Categorical-data-analysis.html`（chapek9.omv） | 兩者皆為**虛構教學資料**（頁面明文） |

**重要更正**：`examples_rewrite_20260908.md` 假設 lsj-book 卡方在 ch.12、迴歸在
ch.15；本輪實讀目錄後確認**實際章節是 ch.10（類別資料分析／卡方）與 ch.12（相關與線性迴歸）**，
ch.15 其實是「因素分析」，與本次任務無關。下表一律使用實際章節。

---

# 1. 多元迴歸候選清單（兩個連續預測變項 → 一個連續結果變項）

| # | 資料集 | 出處 | 章節 URL | 變項結構 | 樣本數 | 真實／虛構 | 授權 |
|---|---|---|---|---|---|---|---|
| R1 | `grades.csv`（統計課成績） | psyteachr **stat-models-v1** | [`multiple-regression.html`](https://psyteachr.github.io/stat-models-v1/multiple-regression.html) **[頁面實讀]** | 結果：`grade`（期末成績）；連續預測變項：`lecture`（出席次數，0–10）、`nclicks`（下載教材點擊數）、`GPA`（先前 GPA，0–4）——**三個連續預測變項**，符合「兩個連續預測變項」的最小情境（可只取 `lecture`+`GPA` 或 `nclicks`+`GPA` 兩個）。有「Multicollinearity and its discontents」專節討論預測變項間相關，但**未計算 VIF** | 100 位統計課學生 | **虛構**——頁面原文："made up, but realistic"（模擬資料，模擬真實課堂情境） | CC BY-SA 4.0（bookdown 頁腳僅顯示作者 Dale J. Barr／bookdown 建置資訊，未見明確授權字樣頁腳；授權依專案 README，沿用第 1 輪對 stat-models-v1 的判斷） |
| R2 | Przybylski & Weinstein (2017) Goldilocks 假說（青少年螢幕使用與幸福感） | psyteachr **analysis-v4** ch.11 | [`11-multiple-regression.html`](https://psyteachr.github.io/analysis-v4/11-multiple-regression.html) **[頁面實讀]** | 結果：`WEMWBS_sum`（幸福感量表總分，14–70）；連續預測變項：**只有一個**——`average_hours`（智慧型手機使用時數，已置中）；另一個預測變項 `gender_recoded` 是類別變項（離差編碼 −0.5/0.5），模型含交互作用項。**不是「兩個連續預測變項」的情境**，但有 VIF（皆 < 2.0）與真實出處 | N = 120,115（篩選使用 >1 小時／天後 N = 71,033） | **真實已發表研究**：Przybylski, A. K., & Weinstein, N. (2017). *Psychological Science*, 28(2), 204–215. https://doi.org/10.1177/0956797616678438；資料在 OSF：https://osf.io/bk7vw/ | CC BY 4.0（頁腳實讀確認："CC-BY (2025) Gaby Mahrholz Carolina E. Kuepper-Tetzel"） |
| R3 | 同上 Przybylski & Weinstein (2017) | psyteachr **quant-fun-v3** ch.14 | [`14-multiple-regression.html`](https://psyteachr.github.io/quant-fun-v3/14-multiple-regression.html) **[頁面實讀]** | 與 R2 相同資料集，唯一擬合的模型是 `total_wellbeing ~ total_hours_c * male_c`——**同樣只有一個連續預測變項**（`total_hours_c`）加一個類別預測變項（`male_c`），我已確認全章**沒有**任何模型用到兩個連續預測變項 | N 同上（原始資料 120,115，篩選後分析用 71,033） | **真實已發表研究**（同 R2，OSF：https://osf.io/82ybd/，這是同一篇論文資料的不同 OSF 節點） | CC BY-SA 4.0（頁腳實讀確認："CC-BY-SA-4.0 (2024) James Bartlett & Wilhelmiina Toivo"） |
| R4 | `parenthood.csv`（Dan 的暴躁指數） | **lsj-book** ch.12 | [`12-Correlation-and-linear-regression.html`](https://davidfoxcroft.github.io/lsj-book/12-Correlation-and-linear-regression.html) **[頁面實讀]** | 結果：`dani.grump`（暴躁指數，0–100）；連續預測變項：`dani.sleep`（自己睡眠時數）、`baby.sleep`（嬰兒睡眠時數）——**正好兩個連續預測變項**，模型即 `dani.grump ~ dani.sleep + baby.sleep`。第 12.10.5 節專門講「Checking for collinearity」並報告 VIF | 100（天，非受試者，是同一位家長 100 天的觀察） | **教學用虛構資料**——頁面原文："The data set we'll use is fictitious, but based on real events."（第 1 輪已用同一教材，措辭一致） | CC BY-SA 4.0（**[承襲 PROPOSAL]**；本次未在頁面找到逐字授權腳注，只見 Open Book Publishers 出版資訊與 Quarto 建置資訊，未見版權字樣） |

## 1.1 推薦度與理由

**推薦：R4（lsj-book `parenthood.csv`）優先，R1（stat-models-v1 `grades.csv`）為備選。**

- **R4 最貼合現有情境結構**：目前 `literacy/02-one-answerable-question.qmd` 第 6 組的自創情境是
  「用連續變項 `age` 和 `hours_studied` 預測連續結果變項 `exam_score`，如何檢查共線性？」——
  R4 的 `dani.sleep` + `baby.sleep` → `dani.grump` **結構完全對應**（兩個連續預測變項 + 一個連續
  結果 + 共線性檢查），且該章節本身就有「Checking for collinearity」小節與 VIF 報告，換句話說
  「共線性」這個提問動機在原教材裡就有現成呼應，改寫幾乎不需要調整敘事重點。缺點：資料是虛構的，
  課文措辭必須寫成「a teaching dataset from *Learning Statistics with jamovi*」而非「a study」，
  且第 1 輪已用過同一本書的 `clinicaltrial.csv`（第 5 組），若第 6 組再用同一本書，會讓「有出處」
  的八組對照集中在少數幾本教材，說服力略打折扣（但仍優於自創變項名）。

- **R1 是本輪唯一符合「真實已發表研究」優先序但结构吻合度略低的選項**：嚴格說 R1 也是模擬資料
  （頁面自承 "made up, but realistic"），並非真實已發表研究——**本輪確認 psyteachr 全系列都沒有
  「兩個連續預測變項 + 真實已發表研究」同時成立的例子**（詳見下方「查不到的項目」）。R1 的優勢是
  三個連續預測變項可任選兩個，且明確在 stat-models-v1（迴歸建模專書）脈絡下，教學設計比 lsj-book
  更聚焦於「該放哪些預測變項」的判斷過程，若第二課想強調「不只共線性，還要判斷該不該把某變項放進
  模型」，R1 的敘事空間更大。

- **R2／R3（Przybylski 真實研究）不建議直接套用第 6 組**，因為它結構上是「1 連續 + 1 類別（含交互
  作用）」，與現況「兩個連續預測變項」的教學重點（共線性）不符——若照抄會需要把情境重寫成「連續 +
  類別」，這會讓第 6 組的教學重點從「共線性」偏向「交互作用／調節效果」，超出這一課的範圍。**但
  R2／R3 非常適合作為「多元迴歸」提示詞條目（若日後要建立類似 `mixed-anova-setup.yaml` 的
  `multiple-regression-setup.yaml`）的真實案例**，因為它是本輪查到最強的「真實已發表研究 + 多元
  迴歸 + VIF」組合，樣本數巨大（N > 71,000）也很適合示範大樣本下的效果量判讀。

**結論**：若堅持「這一組必須是真實已發表研究」，本輪**沒有找到同時滿足「兩個連續預測變項」的候選**；
若接受「教學用虛構資料但結構與共線性教學點都對應」，**R4 是最佳選擇**。

---

# 2. 類別 × 類別關聯候選清單（列聯表／卡方）

| # | 資料集 | 出處 | 章節 URL | 變項結構 | 樣本數 | 真實／虛構 | 授權 |
|---|---|---|---|---|---|---|---|
| C1 | Ballou et al. (2024) 成人 Nintendo 玩家研究 | psyteachr **analysis-v4** ch.6 | [`06-chi-square-one-sample.html`](https://psyteachr.github.io/analysis-v4/06-chi-square-one-sample.html) **[頁面實讀]** | 類別 × 類別關聯（卡方獨立性檢定，非單樣本適合度）：`Gender`（3 水準：Woman／Man／Non-binary）× `Education`（5 水準：完成中學／曾就讀大學未取得學位／大學學士／職業或同等學歷／研究所或專業學位）；觀察次數 4–250 不等；檢定結果 χ²(8) = 13.59, p = .093, Cramér's V = .079 | N = 1,083 | **真實已發表研究**：Ballou, N., Vuorre, M., Hakman, T., Magnusson, K., & Przybylski, A. K. (2024). "Perceived value of video games, but not hours played, predicts mental well-being in adult Nintendo players." PsyArXiv；資料在 OSF：https://osf.io/6xkdg/ | CC BY 4.0（頁腳實讀確認："CC-BY (2025) Gaby Mahrholz Carolina E. Kuepper-Tetzel"，與同書其他章節一致） |
| C2 | `chapek9.omv`（Futurama 機器人辨識情境） | **lsj-book** ch.10 | [`10-Categorical-data-analysis.html`](https://davidfoxcroft.github.io/lsj-book/10-Categorical-data-analysis.html) **[頁面實讀]** | 類別 × 類別關聯：`species`（robot／human，2 水準）× `choice`（puppy／flower／data，3 水準）；交叉表：puppy（機器人13／人類15）、flower（機器人30／人類13）、data（機器人44／人類65） | N = 180（93 人類、87 機器人） | **教學用虛構情境**——頁面以 *Futurama* 影集情節包裝（"the civil authorities of Chapek 9"），本次 WebFetch **未在文中找到逐字聲明「fictitious」的句子**（不同於 ch.12 的 `parenthood.csv` 明文自承），但敘事本身（科幻情境、虛構星球「Chapek 9」）已足以判定非真實研究資料，這點以敘事內容佐證而非逐字聲明，特此註明區別 | CC BY-SA 4.0（**[承襲 PROPOSAL]**；本次頁面實讀只看到 Quarto 建置資訊 "This book was built with Quarto"，**未見到逐字版權腳注**，與第 1 輪對 lsj-book 其他章節的結果一致——lsj-book 頁面本身普遍不顯示逐頁版權字樣） |

## 2.1 推薦度與理由

**推薦：C1（analysis-v4，Ballou et al. 2024）。**

- 目前 `literacy/02-one-answerable-question.qmd` 第 8 組的自創情境是「類別變項 `pass_fail`
  （通過／不通過）在類別變項 `condition`（A／B）之間的分布是否有關聯？」——**C1 結構上更豐富**
  （3 水準 × 5 水準，比 2×2 更能示範「列聯表不是只有 2×2」），且是**本輪唯一同時符合「真實已發表
  研究」與「psyteachr 系列」兩項作者優先序**的候選，檢定結果本身是「不顯著」（p = .093），這對
  課文反而是個好素材——可以順勢提醒讀者：「有出處的真實資料不保證顯著，別預設 LLM 建議的分析一定
  會給出漂亮的顯著結果」。
- 若嫌 3×5 列聯表對「第二課：一句可回答的問題」這種入門情境過於複雜（該課重點是教「怎麼把模糊問題
  寫清楚」，不是列聯表本身的複雜度），可以只挑資料裡的兩個類別水準來簡化敘述（例如只講
  Woman／Man 兩水準），但**變項名稱與出處仍應保留 C1**，不建議改用 C2。
- **C2（lsj-book chapek9）為次要備選**：優點是 2×2（robot/human）× 3 水準（puppy/flower/data）
  結構更簡單、故事性強，且與第 1 輪、本輪 R4 同屬 lsj-book，若最終你決定「這一課的例子全部只用
  lsj-book 以降低授權管理複雜度」，C2 是唯一現成的類別×類別候選。缺點：本次實讀**沒有找到頁面上
  逐字聲明「虛構」的句子**（不像 `clinicaltrial.csv`／`parenthood.csv` 那樣有明文），只能以敘事
  科幻設定佐證，嚴謹度略低於 C1 與其他 lsj-book 候選，若採用需在課文註明「本情境為教學設計的虛構
  情境（Futurama 主題），非真實研究資料」。

**結論**：第 8 組建議用 **C1**，因為它是本輪唯一「真實已發表研究 + psyteachr」的類別×類別候選，
且不顯著結果本身可以成為教學亮點。

---

# 3. 可直接貼用的英文署名句

沿用 `external-examples-survey.md` 第 3 節體例，新增本輪用到的兩章：

| 來源 | 授權 | 建議署名句（英文，可直接貼） |
|---|---|---|
| psyteachr **stat-models-v1**（Multiple regression 章，`grades.csv`） | CC BY-SA 4.0（依專案 README；頁面本身未見逐字版權腳注，僅見作者與 bookdown 建置資訊） | `Example adapted from psyteachr's *Learning Statistical Models Through Simulation in R* (Barr), grades.csv, https://psyteachr.github.io/stat-models-v1/multiple-regression.html — this is a simulated ("made up, but realistic") teaching dataset, not a published study; this adaptation is shared under the same license.` |
| psyteachr **analysis-v4**（Multiple regression 章，Przybylski & Weinstein 2017） | CC BY 4.0 — 頁腳實讀確認為 **"CC-BY (2025) Gaby Mahrholz Carolina E. Kuepper-Tetzel"** | `Example adapted from psyteachr's *Analysis* (Mahrholz & Kuepper-Tetzel, 2025), CC BY 4.0, https://psyteachr.github.io/analysis-v4/11-multiple-regression.html, using data from Przybylski & Weinstein (2017, Psychological Science), OSF: https://osf.io/bk7vw/.` |
| psyteachr **analysis-v4**（Chi-square 章，Ballou et al. 2024） | CC BY 4.0 — 頁腳實讀確認為 **"CC-BY (2025) Gaby Mahrholz Carolina E. Kuepper-Tetzel"** | `Example adapted from psyteachr's *Analysis* (Mahrholz & Kuepper-Tetzel, 2025), CC BY 4.0, https://psyteachr.github.io/analysis-v4/06-chi-square-one-sample.html, using data from Ballou, Vuorre, Hakman, Magnusson, & Przybylski (2024), OSF: https://osf.io/6xkdg/.` |
| psyteachr **quant-fun-v3**（Multiple regression 章，同一 Przybylski & Weinstein 2017 資料） | CC BY-SA 4.0 — 頁腳實讀確認為 **"CC-BY-SA-4.0 (2024) James Bartlett & Wilhelmiina Toivo"** | `Example adapted from psyteachr's *Fundamentals of Quantitative Analysis* (Bartlett & Toivo, 2024), CC BY-SA 4.0, https://psyteachr.github.io/quant-fun-v3/14-multiple-regression.html, using data from Przybylski & Weinstein (2017, Psychological Science), OSF: https://osf.io/82ybd/ — this adaptation is shared under the same license.` |
| **lsj-book**（ch.12 Correlation and linear regression，`parenthood.csv`） | CC BY-SA 4.0（**[承襲 PROPOSAL]**） | `Example adapted from *Learning Statistics with jamovi* (Navarro & Foxcroft, 2025, Open Book Publishers, DOI 10.11647/OBP.0333), parenthood.csv — described on the page as "fictitious, but based on real events" — CC BY-SA 4.0, https://davidfoxcroft.github.io/lsj-book/12-Correlation-and-linear-regression.html — this adaptation is shared under the same license.` |
| **lsj-book**（ch.10 Categorical data analysis，`chapek9.omv`） | CC BY-SA 4.0（**[承襲 PROPOSAL]**） | `Example adapted from *Learning Statistics with jamovi* (Navarro & Foxcroft, 2025, Open Book Publishers, DOI 10.11647/OBP.0333), chapek9.omv — a fictional teaching scenario framed around the animated series *Futurama*, not real research data — CC BY-SA 4.0, https://davidfoxcroft.github.io/lsj-book/10-Categorical-data-analysis.html — this adaptation is shared under the same license.` |

**共同注意事項（沿用第 1 輪）**：標「this adaptation is shared under the same license」的（BY-SA
來源），僅在本站整體授權為 CC BY-SA 4.0 時才成立；CC BY（無 SA）來源（analysis-v4）改寫後可用本站
自己的授權，只需保留署名句。

---

# 4. 查不到或無法確認的項目

| 項目 | 原因 |
|---|---|
| 「兩個連續預測變項 → 一個連續結果變項」且**同時是真實已發表研究**的組合 | 本輪逐頁讀了 stat-models-v1（`multiple-regression.html`、`correlation-and-regression.html`）、analysis-v4 ch.11、quant-fun-v3 ch.14、data-skills-v3（`resilience-2.html`、`belonging-2.html`）。真實研究的迴歸例子（Przybylski & Weinstein 2017）在 analysis-v4 與 quant-fun-v3 都只用了一個連續預測變項（`average_hours`/`total_hours_c`）加一個類別變項及交互作用；模擬資料的迴歸例子（stat-models-v1 grades.csv、lsj-book parenthood.csv）才有兩個以上連續預測變項。**兩者無法同時滿足**，這不是沒查到，是查過後確認材料裡沒有這個組合 |
| stat-models-v1 `interactions.html` 章節 | 只查了目錄與 TOC 摘要（**[目錄推測]**），未實讀內文；若該章對 Przybylski 式資料或其他資料加了第二個連續預測變項，本輪未確認 |
| data-skills-v3 除 `resilience-2.html`／`belonging-2.html` 外的其他章節（`corsi-blocks-*.html`、`big-five-personality-*.html`、`project-analysis.html`） | 只讀了目錄標題（**[目錄推測]**），本次未逐一開章節確認是否有多元迴歸或卡方情境 |
| reprores-v6 是否有獨立的迴歸或卡方教學章節 | 本輪未重新查詢 reprores-v6 目錄（第 1 輪僅查過附錄 E 資料集庫的檔名列表），不確定該書是否有分析教學章節 |
| lsj-book ch.10（`chapek9.omv`）頁面是否有逐字「虛構」聲明 | WebFetch 摘要中沒有看到類似 `parenthood.csv` 那句 "fictitious, but based on real events" 的逐字宣告，只能以科幻敘事佐證虛構性質，可能是頁面確實沒有逐字聲明，也可能是摘要漏抓，未進一步用其他方式核對原始 HTML 原始碼 |
| lsj-book 各章頁腳的逐字版權聲明 | 與第 1 輪相同問題：本輪 WebFetch 摘要多次只回傳 Quarto／Open Book Publishers 建置資訊，未見逐字版權字樣，授權判斷延續 **[承襲 PROPOSAL]** 而非本輪頁面實讀確認 |
| Przybylski & Weinstein (2017) 原始資料集是否含 `age`（年齡）等其他連續變項可作第二預測變項 | 兩本教材的章節內文都只呈現了作者選定使用的變項（`average_hours`/`total_hours`、`gender`），未列出資料集完整欄位清單；若要確認資料集本身是否含其他連續變項（可能可以拼出「兩個連續預測變項」的真實研究情境），需要直接下載 OSF 上的原始資料，本輪未做 |

---

# 5. 給下一步的建議

1. **第 6 組**：採用 **R4**（lsj-book `parenthood.csv`，`dani.sleep` + `baby.sleep` → `dani.grump`），
   在課文明確標註「教學用虛構資料，非真實研究」，並可提及原書本身就有共線性檢查小節，呼應提問裡
   「如何檢查共線性」的要求。若日後想另建一條「多元迴歸」提示詞條目（類似
   `prompts/entries/mixed-anova-setup.yaml` 的模式），改用 **R2/R3**（Przybylski & Weinstein 2017，
   真實已發表研究，N > 71,000，含 VIF），但情境需改寫為「連續 + 類別 + 交互作用」而非「兩個連續」。
2. **第 8 組**：採用 **C1**（analysis-v4，Ballou et al. 2024，`Gender` × `Education`），真實已發表
   研究，且不顯著的檢定結果本身是個可以在課文裡加分利用的教學點。
3. 若你希望第 6、8 組與第 1 輪找到的六組在「真實研究 vs. 教學虛構」的比例上更平衡，目前狀態是：
   第 6 組落在「教學虛構」（R4），第 8 組落在「真實研究」（C1）——與第 1 輪六組（四個真實研究 +
   兩個 lsj-book 虛構）合併來看，八組裡共有 5 個真實研究、3 個教學虛構資料，這個比例本身可以直接
   寫進課文最後一節「資料來源」，讓讀者知道兩種素材的差別與各自的可信度定位。
