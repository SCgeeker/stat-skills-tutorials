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

**assumption 的標準答案**（psyteachr ch.7 已算好，可直接對）：
Levene `F(1,158) = 0.73, p = .395`（變異數同質）；Welch `t(157.14) = −0.92, p = .360, d = 0.15`。
若模型宣稱的前提檢定結論與此相反，記 `fail`。

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

**`code-run` 的基準有陷阱**：n = 130 是篩掉 `T2_Finished` 未完成者之後的數字。若直接載入未篩選
的原始檔，列數會大於 130，長格式就不是 260 列。**先確認你手上實際列數，再拿那個數字 × 2 當標準。**

---

# 判定標準（權威定義在 `PROPOSAL.zh-TW.md` §4.1）

| 值 | 判準 |
|---|---|
| `pass` | `expected` 全部命中，且所有 `check` 步驟零錯 |
| `partial` | `expected` 命中 ≥ 半數（無條件進位），但有任一 `check` 失敗，或 `expected` 有漏 |
| `fail` | `expected` 命中 < 半數；**或**回覆含錯誤資訊（幻覺選單路徑、不存在的選項、與資料不符的數字）——後者一律 `fail`，不論命中數 |

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
