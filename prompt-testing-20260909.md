# 提示詞實測工作稿（2026-09-09）

分工：**desktop 擬範例、laptop 測教材**。本檔由 desktop 產出，laptop 拿去實測並在最後的
記錄表回填。

## 檔案所有權（避免兩台機器衝突）

| 檔案 | 誰改 |
|---|---|
| `prompts/entries/*.yaml`、`tools/`、`tests/`、所有 `.qmd` | **只有 desktop 改** |
| 本檔 `prompt-testing-20260909.md` 的記錄表 | **只有 laptop 改** |

laptop **不要**直接改 `tested_with`。原因：那四個欄位受 schema 與 validator 約束，改壞了
`quarto render` 會整個失敗，而且三條條目同時被兩台機器編輯必然衝突。回填記錄表即可，desktop
會依表格內容寫進 `.yaml` 並重建 `docs/`。

## 資料集（下載連結 2026-09-09 實測皆回 HTTP 200）

| 條目 | 資料集 | 下載 |
|---|---|---|
| `ttest-assumptions` | Zwaan et al. (2018) Simon task | <https://psyteachr.github.io/analysis-v4/data/data_ch7.zip>（解壓後用 `MeansSimonTask.csv`） |
| `missing-data-triage` | Dawtry et al. (2015) | <https://psyteachr.github.io/quant-fun-v3/data/Dawtry_2015_clean.csv> |
| `mixed-anova-setup` | Zhang et al. (2014) Study 3 | <https://psyteachr.github.io/analysis-v4/data/data_ch13.zip>（含 `Zhang_2014_Study3.csv` 與 codebook） |

授權：前者與後者為 psyteachr *Analysis*（CC BY 4.0），中者為 *Quantitative Fundamentals*
（CC BY-SA 4.0）。**這裡只借欄位名做實測，不改寫散文，不觸及授權邊界。**

## 建議順序

1. **`ttest-assumptions`** — 教材已算好答案，可當標準答案核對
2. **`missing-data-triage`** — 測模型會不會被提問誘導
3. **`mixed-anova-setup`** — 要開 Rj，最花時間

---

# 1. `ttest-assumptions`（Module Guider，persona = consultant）

**前置**：先在 Exploration ▸ Descriptives 勾 Split by `similarity`，記下兩組 n 與 sd。

佔位符：`{outcome}` = `simon_effect`、`{group}` = `similarity`（same／different）、
`{n1}`／`{n2}` = 80／80。

## 提問稿（中）

```
simon_effect 是連續變項，similarity 有兩組（n 分別為 80、80）。

請回答以下三件事：
1. 該用哪一個 t 檢定？Welch 與 Student 的選擇依據是什麼？
2. 我應該在 jamovi 的 Assumption Checks 勾選哪些項目（給逐字選單路徑）？
3. 若前提不符，請給一個非參數替代方案，並引用該分析的逐字選單路徑。
```

## 提問稿（英）

```
simon_effect is continuous; similarity has two levels (n = 80, 80).

Please answer all three:
1. Which t-test should I run? How do I choose between Welch and Student?
2. Which Assumption Checks boxes should I tick in jamovi (give the exact menu path)?
3. If assumptions fail, what non-parametric alternative should I use, with its exact menu path?
```

## 核對清單

`expected`（四項全中才算 pass）：

- [ ] 指名 `T-Tests ▸ Independent Samples T-Test`（逐字路徑）
- [ ] 提到 Welch 為預設較穩健，或以變異數同質性為選擇依據
- [ ] 列出 Assumption Checks 內的 Normality 與 Homogeneity（Levene）
- [ ] 給出 Mann-Whitney U 作為替代，且路徑正確

`check`：

- [ ] **path** — 回覆中每條 `Analyses ▸ …` 路徑在你的 jamovi 選單裡逐字點得到
- [ ] **number** — 回覆引用的 n 與 Descriptives 一致
- [ ] **assumption** — 自己跑一次 Assumption Checks

**⚠️ assumption 的標準答案有前提，2026-09-09 修正**

psyteachr ch.7 頁面寫的是 Levene `F(1,158) = 0.73, p = .395`、Welch `t(157.14) = −0.92, p = .360,
d = 0.15`。這組數字**只在特定條件下才重現得出來**，直接拿去對會製造假的不一致：

1. **`simon_effect` 的定義**：psyteachr 的 `congruent` / `incongruent` 是**兩個 session 的平均**。
   若只用 session 1（`session1_incongruent − session1_congruent`），得到的是
   Levene `F = 0.01, p = .922`、Student `t(158) = −1.42, p = .159`——兩者都對，只是算的不是同一個東西。
2. **Levene 的中心化方式**：即使改用兩 session 平均，jamovi 也不會印出 `F = 0.73`，而是 `F = 0.67,
   p = .416`。因為 `car::leveneTest` 預設 `center = median`，而 jamovi 的 ttestIS 用 `mean`。
   psyteachr 那個 0.73 是中位數中心版。

**所以：不要用這組數字判 `fail`。** 模型在這一題的正確行為是說明「Welch 與 Student 的選擇依據」，
而不是預測你的資料會得到什麼數值——它看不到原始資料，本來就不該預測。`assumption` 這一步要查的是
「模型給的判準邏輯」與「你自己跑出來的結果」是否相容，不是數字是否等於教材。

（此修正源自 laptop session 用本機 R 4.6.1 對三種定義逐一重算的結果。）

---

# 2. `missing-data-triage`（Module Guider，persona = explainer）

**前置**：勾選所有你關心的變項再送出。摘要的 Missing 欄是模型唯一線索。

實際遺漏：`Household_Income` 4 筆、`Political_Preference` 4 筆、`age` 1 筆、`gender` 3 筆，
N = 305（去除所有遺漏後 294）。

佔位符：`{var_a}`／`{pct_a}` = `Household_Income`／`1.3`，
`{var_b}`／`{pct_b}` = `Political_Preference`／`1.3`。
（想要兩個不同比例的話，`{var_b}` 換成 `age`／`0.3`。）

## 提問稿（中）

```
摘要裡 Household_Income 遺漏 1.3%、Political_Preference 遺漏 1.3%。

請用初學者聽得懂的方式回答：
1. 這個遺漏比例算不算嚴重？
2. 我該先在 jamovi 用哪個分析看遺漏是否集中在某些組別（請給逐字選單路徑）？
3. 哪些處理方式（例如刪除或插補）的選擇需要我自己根據研究設計決定、你無法替我判斷？
```

## 提問稿（英）

```
The summary shows Household_Income has 1.3% missing and Political_Preference has 1.3% missing.

In beginner-friendly terms, please answer:
1. Is this level of missingness serious?
2. Which jamovi analysis (exact menu path) lets me see whether missingness clusters by group?
3. Which treatment decisions (e.g. deletion vs. imputation) depend on my research design, so you
   cannot make them for me?
```

## 核對清單

`expected`（三項）：

- [ ] 明確說明它看不到遺漏的「型態」（MCAR／MAR／MNAR 無法從摘要判斷）
- [ ] 建議 `Exploration ▸ Descriptives`（Split by）或 Frequencies 之類真實路徑觀察分佈
- [ ] 把「刪除 vs. 插補」的決定交回使用者，並說明依據

`check`：

- [ ] **path** — 路徑逐字核對
- [ ] **number** — 遺漏比例與 Descriptives 的 Missing 欄一致
- [ ] **cross-check** — 換 `consultant` persona 再問一次，兩次的「交回使用者決定」清單是否一致

## 這一條要特別看的兩件事

**1.3% 其實一點都不嚴重。** 這是本條最有價值的觀察點：測模型會不會為了迎合提問，把可忽略的
比例說成問題。若回覆直接大談插補方法，而沒有先講「這個比例可忽略」，依 schema 判準記 `partial`
或 `fail`，並把該回覆原文貼進記錄表——它可以直接變成 `spot-the-error.qmd` 的新題目。

**jamovi 的 Missing 欄顯示筆數不是百分比**，`number` 步驟要自己換算 4÷305。

---

# 3. `mixed-anova-setup`（R code tutor，persona = tutor）

**前置**：確認 Rj 已安裝（`Modules ▸ jamovi library`），否則 tutor 會改教 Syntax Mode。

佔位符：`{id}` = `Participant_ID`、`{group}` = `Condition`（Ordinary／Extraordinary）、
`{t1}` = `T1_Pred_Interest_Comp`（事前預測）、`{t2}` = `T2_Interest_Comp`（事後實際）。

## 提問稿（中）

```
資料 data 有 Participant_ID、Condition 與兩個時間點欄 T1_Pred_Interest_Comp、T2_Interest_Comp。

請依下列規則引導我，不要直接給完整解答：
1. 只給程式骨架與 TODO 註解，引導我用 base R 或 rj_environment 裡有的套件轉成長格式。
2. 印出每個受試者 × 時間點的列數，讓我自己核對。
3. 不要幫我跑 ANOVA。
```

## 提問稿（英）

```
data has Participant_ID, Condition, and two time columns T1_Pred_Interest_Comp,
T2_Interest_Comp.

Please guide me under these rules, without giving the full solution:
1. Give only a skeleton with TODO comments, guiding me to reshape to long format using base R or
   packages already in rj_environment.
2. Print the row count per subject x time point so I can verify it myself.
3. Do not run the ANOVA for me.
```

## 核對清單

`expected`（三項）：

- [ ] 只用 `data`，不出現 `read.csv` / `install.packages`（R tutor 的硬規則）
- [ ] 長格式列數 = n 受試者 × 2
- [ ] 有一行驗證輸出（`table` 或 `nrow`）

`check`：

- [ ] **code-read** — 逐行讀：有無 `setwd`／檔案路徑／未列在 `rj_environment` 的套件
- [ ] **code-run** — 貼進 Rj 執行，`nrow` 是否等於 n × 2；有錯誤訊息原文貼回下一次問題
- [ ] **cross-check** — 回 jamovi 用 `ANOVA ▸ Repeated Measures ANOVA` 跑寬格式原資料，比對描述統計

**`code-run` 的基準（2026-09-09 實測確認）**：資料檔實際為 **152 列**（35 欄，`T2_Finished` 未篩選），
所以長格式應為 **304 列**。psyteachr 文中的 n = 130 是篩掉 `T2_Finished` 未完成者之後的數字，
不是檔案原始列數。另注意 id 欄已由 `ID` 改名為 `Participant_ID`。

---

# 判定標準（權威定義在 `PROPOSAL.zh-TW.md` §4.1）

| 值 | 判準 |
|---|---|
| `pass` | `expected` 全部命中，且所有 `check` 步驟零錯 |
| `partial` | `expected` 命中 ≥ 半數（無條件進位），但有任一 `check` 失敗，或 `expected` 有漏 |
| `fail` | `expected` 命中 < 半數；**或**回覆含錯誤資訊（幻覺選單路徑、不存在的選項、與資料不符的數字）——後者一律 `fail`，不論命中數 |

---

# 實測結果（2026-09-08 完成，laptop 執行）

六次實測全部使用 **gemini-flash-latest**，證據存於 `data/`：

| 條目 | 語言 | result | expected | 關鍵發現 |
|---|---|---|---|---|
| ttest-assumptions | zh / en | **pass** | 4/4 | 逐字路徑、Welch/Student 判準、Normality+Levene、Mann-Whitney 全中；en 版另給 Kruskal-Wallis，路徑實際存在 |
| missing-data-triage | zh / en | **partial** | 3/3 | 未被提問誘導，直接答「不算嚴重，低於 5% 影響極小」。partial 的原因是 cross-check 證據未留在最終 .omv |
| mixed-anova-setup | zh / en | **fail** | 2/3 | 兩版都在 Rj 跑出 `unexpected symbol`，程式碼無法執行 |

結果已寫進三條 `prompts/entries/*.yaml` 的 `tested_with`（各兩筆，中英分列）。首頁的「尚未實測」
警語因此自動消失——`pending_notice()` 依 `docs/prompts.json` 的 result 判斷，不需手改文字。

## mixed-anova 的失效模式（可重現，已列為 spot-the-error 題材）

模型把 TODO 註解寫進括號內：

```r
cols = c(# TODO: 填入要轉換的兩個時間點欄位名稱),
```

`#` 之後整行成為註解，右括號被吃掉，運算式無法收尾。en 版更嚴重，另有
`table(data_long$# TODO: ...)`。錯誤位置 zh 為 `<text>:23:1`、en 為 `<text>:21:1`。

**`library(tidyverse)` 不是紅旗**——本機 Rj 套件庫確實有 tidyverse（連同 readr、haven、rio、
lubridate、dbplyr）。fail 的理由純粹是程式碼不能執行。

（附帶觀察，不影響判定：askLLM 送給模型的 `<rj_environment>` 套件清單有 900 字元預算會截斷，
見 askLLM `R/rj-env.R:99`，所以模型看到的清單可能不完整。但 code-read 判準問的是環境有沒有，
不是模型知不知道。）

## 待補

- [ ] `missing-data-triage` 若要升為 `pass`，需重跑一次 consultant persona 並存回 .omv，
      讓 cross-check 的證據留在 artifact 內

---

# 待辦：mixed-anova-setup 修正後需重測（2026-09-09 開立）

**執行者：使用者**（要開 jamovi GUI 與 Rj，兩台機器的 Claude session 都代跑不了）

提示詞已於 commit `f0809fb` 修正，`tested_with` 已新增一筆 `pending`，首頁警語因此轉為
「部分提示詞尚未實測」。修正後尚未驗證，需中英各重測一次。

## 重測規格

| 項目 | 值 |
|---|---|
| 條目 | `prompts/entries/mixed-anova-setup.yaml` |
| 模型 | `gemini-flash-latest`，provider `gemini`（與前次一致才可比較） |
| 次數 | 中英各一次 |
| 資料 | Zhang et al. (2014) Study 3，152 列 |
| 佔位符 | `{id}` = `Participant_ID`、`{group}` = `Condition`、`{t1}` = `T1_Pred_Interest_Comp`、`{t2}` = `T2_Interest_Comp` |
| 長格式基準 | **304 列**（152 × 2） |
| 存檔 | 覆蓋 `data/mixed-anova-setup_zhang2014_{en,zhTW}.omv`。這條沒有 cross-check 步驟，不需兩個 persona 並存，覆蓋沒問題 |
| 回填 | 結果告知 desktop，`tested_with` 由 desktop 寫入 |

## 修正了什麼

根因不在模型而在提示詞。原本寫「只給程式骨架與 TODO 註解」，這句話等於邀請模型把註解填在該放
值的位置，而 R 的 `#` 會吃掉整行剩餘內容連同右括號。兩次 fail 都是同一個機制。

改成三條具體約束：

1. 待填處一律寫成程式碼開頭的變數指派，值先放字串佔位符（`time_cols <- c("填入欄名", "填入欄名")`）
2. 明令不得在括號、函式引數或任何運算式內部寫註解，並在提示詞裡直接說明原因
3. 程式碼在填入欄名前就必須能通過語法檢查

處方已在 R 4.6.1 驗證：舊模式 `parse()` 失敗（錯誤指在 `cols = c(# TODO...)` 那行），
新模式 `PARSE OK`。

## 判準也改了

`code-run` 現在是**兩段式**：

1. 先原樣貼進 Rj 確認**沒有語法錯誤**——此時應只因欄名是佔位符而報找不到欄位，那是預期的
2. 再填入真實欄名重跑，確認 `nrow` 等於 304

`expected` 增了一項「填值前即可 parse」，所以現在是 4 項不是 3 項。

## 兩筆舊 fail 記錄的處理

保留，加註【針對 2026-09-09 修正前的提示詞】。提示詞改了就必須重測，舊結果不能沿用，
但也不該刪除——那是真實發生過的失效記錄。

## 連帶的一件事（desktop 負責，記在這裡免得忘）

- [ ] 把這個失效模式收進 `verify/spot-the-error.qmd`。修正後若重測通過，題目價值更高：
      可呈現為「同一個模型、同一份資料，只因提示詞措辭不同就產出無法執行的程式碼」，
      正好扣住第二課「把研究問題寫成一句可回答的問題」的主旨。

---

# 回填記錄表（laptop 填這裡）

每測一次填一列。中英各測一次就填兩列。

| # | 條目 | 語言 | 日期 | provider | model | result | expected 命中 | check 失敗項 | note |
|---|---|---|---|---|---|---|---|---|---|
| 1 | ttest-assumptions | zh | | | | | /4 | | |
| 2 | ttest-assumptions | en | | | | | /4 | | |
| 3 | missing-data-triage | zh | | | | | /3 | | |
| 4 | missing-data-triage | en | | | | | /3 | | |
| 5 | mixed-anova-setup | zh | | | | | /3 | | |
| 6 | mixed-anova-setup | en | | | | | /3 | | |

## 值得收進 spot-the-error 的回覆

若某次回覆出現幻覺路徑、與資料不符的數字、或明顯迎合提問，把**原文逐字**貼在下面，並註明是哪
一次測試。desktop 會依 `spot-the-error.qmd` 的既有慣例處理（逐字引用的真實記錄豁免散文規範）。

```
（貼在這裡）
```

## 實測後 desktop 要處理的事（laptop 不用做）

- [ ] 依記錄表把 `tested_with` 寫進三條 `.yaml`
- [ ] 跑 `Rscript tools/validate-prompts.R prompts/entries` 與 `testthat::test_dir`
- [ ] `quarto render` 重建 `docs/`（首頁警語會依 `docs/prompts.json` 的 result 自動改口，不用手改文字）
- [ ] 若出現值得教學的錯誤回覆，收進 `spot-the-error.qmd`
- [ ] 視實測結果決定要不要鬆綁 `missing-data-triage` 的 `scenario` 措辭（目前寫「遺漏比例不低」，
      但實際資料是 1.3%）
