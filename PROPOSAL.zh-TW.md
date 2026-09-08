# stat-skills-tutorials 方案草稿

> 狀態：規劃草稿，待作者拍板。日期：2026-09-08。
> 對應需求：`README.md`（本 repo）；對應實作：`../askLLM/`（v1.3.0）。
> 標記慣例：**[已查證]** 有原始出處；**[未查證]** 無法確認，不要據以行動；**★ 需拍板** 作者決策點。

## TL;DR

- **定位**：做「原創的 AI 協作素養教程 + 情境化提示詞庫」，外部教材只做**導讀與連結**，不搬運內容；跟 askLLM 的關係是「askLLM 結果面板連出去的常青頁」，沿用 v1.3 已建立的 link-out 模式，不隨 `.jmo` 打包。
- **技術選型**：Quarto website（非 book），提示詞庫以 YAML 為單一真相來源、建置時產生頁面與可機讀 JSON；雙語採「繁中為主、英文為必要子集」，用 Quarto profiles 分開建。
- **核心產物**：三層內容——(1) 協作素養 6 課、(2) 提示詞庫（有 schema、可驗證）、(3) 生成結果查核清單與可重複的查核流程（Module Guider 走路徑核對，R code tutor 走「讀碼 → 跑真資料 → 對照 jamovi GUI」三段）。
- **授權**：七套外部教材授權已逐一查證（六套 CC BY / BY-SA，一套 CC BY-NC-SA），只有 bradduthie/stats 因 NC 條款限制為「連結不改寫」；本站建議整體採 CC BY-SA 4.0。
- **先做什麼**：Phase 0 兩週內把骨架、schema、3 條提示詞、1 份查核清單上線並讓 askLLM 結果面板能連到，再決定要不要擴大。

---

## 1. 現況盤點：從 askLLM 實作讀出的設計約束

教材若脫離模組實際行為就會失效，以下事實直接決定後面每一節的取捨（來源：`askLLM/jamovi/*.a.yaml`、`R/askllm.b.R`、`R/r-tutor.R`、`R/llm-adapter.R`、`docs/LIMITATIONS.zh-TW.md`、`docs/learn-r.json`）。

| # | 事實 **[已查證]** | 對教材設計的含意 |
|---|---|---|
| F1 | 一個模組、兩種分析模式：**jamovi Module Guider**（`askllm`，推薦分析＋逐字引用選單路徑）與 **R code tutor**（`askllmr`，產出貼進 Rj Editor 的 R 程式碼）。兩者互相導流（system prompt 硬性附加邊界句）。 | 提示詞條目必須標明「給哪一個分析」；查核流程要分兩套。 |
| F2 | 使用者輸入是單一 `String` 選項 `question`，**單輪問答**，無對話歷史；勾 `submit` 才呼叫，payload 相同時快取回放。 | 提示詞必須是「一次講完」的自足句，不能設計多輪追問腳本；教材要教「改問題前先取消 Submit」。 |
| F3 | 送給 LLM 的資料只有所選變項的**摘要統計**（`summarize_data()`：n／遺漏／mean／sd／median／min／max；因子的水準次數），絕不送原始列。 | 提示詞不能要求 LLM 做「需要看原始資料」的事（如檢查離群值、常態性）；教材要教使用者自己在 jamovi 做這些。 |
| F4 | user prompt 結構固定：`<summary>` → `<installed_analyses>` → `<available_modules>` → `<rj_environment>` → 指令段 → `Question: …`。使用者只能控制 `Question:` 那一行。 | 提示詞庫只需設計 `question` 文字；不必（也不能）教使用者改 prompt 結構。 |
| F5 | 三種 Persona（consultant / tutor / explainer）× 兩種語言（en / zh）的 system prompt 模板寫死在程式碼；另可用**某變數的 Description** 當 custom system prompt（`systemPromptVar`）。 | 提示詞庫可以附「建議 Persona」欄位；進階條目可提供一段「貼進變數 Description 的 system prompt」，這是使用者唯一能自訂 system prompt 的管道。 |
| F6 | Module Guider 有硬查證：路徑必須逐字出現在掃描到的安裝清單（實測 18/18 零虛構，樣本小）。R code tutor **沒有等價查證**，設計上「教學不代跑」。 | 查核教程的兩條路線難度不對等：路徑核對可機械化；R 程式碼核對只能靠流程與對照。 |
| F7 | v1.3 已有兩個「常青頁」（`docs/learn-r.html`、`docs/choose-model.html`）以 GitHub Pages 發佈於 `scgeeker.github.io/askLLM/`，並從結果面板的 Html links 項連出；`learn-r.json` 是機讀索引，`tools/release-check.R` 會檢查外連是否存活。 | **link-out 模式已存在且有測試**。本 repo 最自然的整合方式就是成為第三個（或一組）常青頁的來源。 |
| F8 | `LIMITATIONS.zh-TW.md` 已列出四類實測錯誤與「給教學使用的建議設計」（先問 AI 再親手操作、比較模型、討論摘要的極限）。 | 這三條就是「查核教程」的種子，不必從零發想。 |
| F9 | askLLM 文件慣例：計畫與說明檔一律 `*.zh-TW.md` / `*.en.md` 成對；commit 訊息英文。 | 本 repo 的語言策略要跟母專案相容，不能只有單語。 |

---

## 2. 定位與範圍

### 2.1 建議：原創教程為主，外部教材只做導讀

README 的三件事（清晰描述問題、設定「解決／需再探討」的判準、檢驗 AI 生成方針）在七套外部教材裡**都沒有現成章節**——它們教統計與 R，不教「怎麼跟 LLM 協作做統計」。所以：

- **不是教材集散地**。搬運或改寫外部教材成本高、授權混雜（見 §6），而且 `learn-r.html` 已經是一個「從頭學 R」的連結頁，再做一個集散地是重複。
- **是原創教程**，內容嚴格限縮在「使用 askLLM 這類諮詢型 AI 做統計時的技能」：問題描述、判準設定、結果查核。統計知識本身**指向**外部教材對應章節，不重寫。

### 2.2 與 askLLM 的關係：常青頁，不打包

| 選項 | 評估 | 建議 |
|---|---|---|
| 隨 `.jmo` 打包（放 `inst/`，結果面板內顯示） | jamovi 結果面板是 Preformatted／Html，不適合長篇教材；每次改教材都要重發模組；`.jmo` 已 3 MB | 否 |
| jamovi 內建說明（`docs.jamovi.org` 或模組 help） | 模組 help 機制仰賴 jamovi 官方文件流程，本模組尚未進官方 library（Jonathon 暫緩收錄） | 否 |
| **獨立網站，askLLM 結果面板 link-out** | 與 F7 現有模式一致；教材可獨立迭代；`release-check.R` 已能驗連結 | **是** |

實作細節：本 repo 以 GitHub Pages 獨立發佈（建議 `scgeeker.github.io/stat-skills-tutorials/`），askLLM 這邊只需在 Html links 項多加一到兩個連結、在 `learn-r.json` 新增一個 section（那是 askLLM repo 的改動，不在本方案範圍，列為 Phase 1 的跨 repo 任務）。

### 2.3 範圍邊界（明確不做）

- 不做 LLM 供應商設定教學（已在 `askLLM/docs/SETUP-*.md`）。
- 不做模型選擇教學（已在 `choose-model.html`）。
- 不做 R 入門（已在 `learn-r.html` 連出 psyteachr / R4DS）。
- 不重寫任何統計方法的原理說明——一律連到 lsj-book 或 psyteachr 對應章。

---

## 3. 內容架構

### 3.1 三層對應 README 的三件事

| 層 | 名稱 | 對應 README | 形式 |
|---|---|---|---|
| L1 | **AI 協作素養**（Literacy） | 「有意識了解 AI 是協作者」＋「清晰描述問題」＋「設定明確指標」 | 6 課短文，每課 ≤ 1,500 字，附一個可在 jamovi 內 5 分鐘完成的練習 |
| L2 | **情境化提示詞庫**（Prompt Library） | 「彙整適用各種問題情境的提示詞」 | YAML 條目 → 自動產生頁面；每條可直接複製到 `question` 欄 |
| L3 | **生成結果查核**（Verification） | 「檢驗 AI 模型生成方針的教程」 | 兩套查核清單（Guider / R tutor）＋一套可重複的查核流程＋教學用「故意找錯」練習 |

### 3.2 L1 六課大綱

1. **它看得到什麼、看不到什麼**：拿 F3 的摘要統計實例，讓學生比對「LLM 收到的」與「自己在 jamovi 看到的」。練習：勾三個變項，把回覆裡每一個數字對回 Descriptives。
2. **把研究問題寫成一句可回答的問題**：從「幫我分析」改寫到「變項 X（連續）在 Y（兩組）之間是否有差異」。給改寫前後對照 8 組。
3. **先寫判準再送出**：每次提問前寫下「我會接受什麼答案」（例如：回覆須指名一個 T-Tests 底下的分析且說明為何不是 ANOVA）。練習：用 `docs/LIMITATIONS` 的 iris 例子。
4. **選對分析、選對 Persona**：Guider vs. R tutor；consultant / tutor / explainer 各適合什麼情境（F1、F5）。
5. **摘要之外的事自己來**：假設檢定、離群值、遺漏值型態——LLM 看不到，教學生在 jamovi Assumption Checks 做，並把結果寫回下一次的問題裡。
6. **問完之後**：改問題前取消 Submit（F2）、比較兩個模型、記錄「問題—判準—回覆—查核結果」四欄的協作日誌（提供範本）。

### 3.3 目錄結構草案

```
stat-skills-tutorials/
├── README.md                      # 既有，不動
├── PROPOSAL.zh-TW.md              # 本文件
├── _quarto.yml                    # 主設定（website）
├── _quarto-en.yml                 # profile: en（見 §7.2）
├── index.qmd
├── literacy/                      # L1
│   ├── 01-what-the-llm-sees.qmd
│   ├── 02-one-answerable-question.qmd
│   ├── 03-criteria-first.qmd
│   ├── 04-which-analysis-which-persona.qmd
│   ├── 05-beyond-the-summary.qmd
│   └── 06-after-the-answer.qmd
├── prompts/                       # L2
│   ├── index.qmd                  # 由 build 腳本產生的總表（勿手改）
│   ├── _schema.yaml               # 條目 schema（§4.1）
│   └── entries/
│       ├── ttest-assumptions.yaml
│       ├── missing-data-triage.yaml
│       └── mixed-anova-setup.yaml
├── verify/                        # L3
│   ├── checklist-guider.qmd
│   ├── checklist-rtutor.qmd
│   ├── workflow.qmd               # 可重複的查核流程
│   └── spot-the-error.qmd         # 教學用故意找錯練習（附答案）
├── external/                      # 外部教材導讀（§6）
│   └── reading-map.qmd            # 一頁：情境 → 教材章節
├── data/                          # 練習用資料（僅用授權明確的公開資料）
├── tools/
│   ├── build-prompts.R            # YAML → prompts/index.qmd + prompts.json
│   ├── validate-prompts.R         # schema 驗證（CI 用）
│   └── check-links.R              # 沿用 askLLM release-check 的外連檢查思路
├── tests/testthat/                # 針對 tools/ 純函式
├── LICENSE                        # CC BY-SA 4.0（★ 需拍板）
└── docs/                          # Quarto 輸出目錄（GitHub Pages）
```

---

## 4. 提示詞庫設計

### 4.1 條目 schema（`prompts/_schema.yaml`）

設計原則：(a) 只設計 `question` 一行（F4）；(b) 每條必有可驗證的 `check` 與 `stop_criteria`（呼應 README 的「明確指標」）；(c) 條目為單一真相，頁面與 JSON 皆由它產生。

```yaml
# 每個 entries/*.yaml 一條
id: string                 # kebab-case，與檔名一致
title: {zh: string, en: string}
analysis: guider | rtutor  # F1：給哪個 askLLM 分析用
scenario: {zh: string, en: string}   # 一句話情境，使用者用來對號入座
variables:                 # 使用者資料需長什麼樣
  - role: outcome | predictor | grouping | id | covariate
    type: continuous | nominal | ordinal
    n_levels: int | null   # 類別變項才填
design: between | within | mixed | none
stat_goal: string          # 受控詞彙：describe | compare-2 | compare-k | associate | predict | reliability | screen
prerequisites: [string]    # 使用者送出前必須自己在 jamovi 完成的事（F3）
persona: consultant | tutor | explainer   # 建議值（F5）
prompt:                    # 貼進 question 欄的文字；{占位} 由使用者代換
  zh: string
  en: string
system_prompt_override: {zh: string, en: string} | null  # 貼進變數 Description 的進階版（F5），多數條目為 null
expected:                  # 「好回覆」該有的元素，寫成可逐條勾的 bullets
  - string
check:                     # 查核點：每條指向 §5 流程中的一個步驟
  - step: path | number | assumption | code-read | code-run | cross-check
    what: string
stop_criteria:             # README「問題已解決／需再探討」的明確指標
  solved: string
  reopen: string
links:                     # 指向外部教材對應章（§6），非必要
  - {title: string, url: string, license: string}
tested_with:               # 至少一筆實測記錄，否則 validate 失敗
  - {date: YYYY-MM-DD, provider: string, model: string, result: pass | partial | fail | pending, note: string}
```

驗證規則（`tools/validate-prompts.R`，用 testthat 鎖住）：

- `prompt.zh` / `prompt.en` **允許多行**（Q4 已於 2026-09-08 判定：askLLM 以 `jamovi/js/askllm.js` 注入 textarea 承接 `question`，換行完整送進 API），故提示詞可用條列式判準。但**結尾不得有多餘空白行**——`trimws()` 只清頭尾，中間空行會原樣送出並浪費 token。
- `check` 至少 2 條且 `step` 在受控清單內。
- `tested_with` 至少 1 筆；`result` 須為受控值，且 `result: pending` 時 `note` 必填。
- `analysis: rtutor` 的條目 `check` 必含 `code-read` 與 `code-run`。
- `title` / `scenario` / `prompt` 的 `zh` 與 `en` 皆不得為空（Q5 已拍板：英文必填）。

**`tested_with.result` 判準**（2026-09-08 拍板；此處為權威定義，`prompts/_schema.yaml` 的 `result` 欄註解為單行摘要，兩處須同步）：

| 值 | 判準 |
|---|---|
| `pass` | `expected` 全部命中，且所有 `check` 步驟零錯 |
| `partial` | `expected` 命中 ≥ 半數（無條件進位），但有任一 `check` 失敗，或 `expected` 有漏 |
| `fail` | `expected` 命中 < 半數；**或**回覆含錯誤資訊（幻覺選單路徑、不存在的選項、與資料不符的數字）——後者一律 `fail`，不論命中數 |
| `pending` | 尚未送任何模型實測；不得以 `pass`/`partial`/`fail` 造假 |

為何要定死：不定義的話同一份回覆會被不同人（或不同時間的自己）記成不同值，§8 Phase 2 判準裡「依協作日誌把 reopen 比例最高的 3 條改版」的統計就失去意義。評定時以該條目的 `expected` 條目數為分母逐條核對。

### 4.2 範例一：獨立樣本 t 檢定前提（Guider）

```yaml
id: ttest-assumptions
title: {zh: 兩組比較前該檢查什麼, en: What to check before a two-group comparison}
analysis: guider
scenario:
  zh: 資料集有一個連續結果變項與一個兩水準分組變項，想知道該用哪個 t 檢定、以及前提不符時的替代方案。
  en: Data has one continuous outcome, one two-level group; which t-test, and what if assumptions fail.
variables:
  - {role: outcome, type: continuous, n_levels: null}
  - {role: grouping, type: nominal, n_levels: 2}
design: between
stat_goal: compare-2
prerequisites:
  - 已在 Exploration ▸ Descriptives 勾選 Split by 分組變項，看過兩組的 n、mean、sd
  - 兩組 n 與 sd 記下來（LLM 也會收到，但你要能核對）
persona: consultant
prompt:
  zh: "{outcome} 是連續變項，{group} 有兩組（n 分別為 {n1}、{n2}）。請建議該用哪一個 t 檢定，說明 Welch 與 Student 的選擇依據，並指出我應該在 jamovi 的 Assumption Checks 勾選哪些項目；若前提不符請給一個非參數替代並引用選單路徑。"
  en: "{outcome} is continuous; {group} has two levels (n = {n1}, {n2}). Which t-test should I run, how do I choose between Welch and Student, which Assumption Checks boxes should I tick in jamovi, and what non-parametric alternative (with its exact menu path) if assumptions fail?"
system_prompt_override: null
expected:
  - 指名 T-Tests ▸ Independent Samples T-Test（逐字路徑）
  - 提到 Welch 為預設較穩健、或以變異數同質性為選擇依據
  - 列出 Assumption Checks 內的 Normality 與 Homogeneity（Levene）
  - 給出 Mann-Whitney U 作為替代且路徑正確
check:
  - {step: path, what: 回覆中每條 "Analyses ▸ …" 路徑在你的 jamovi 選單裡點得到}
  - {step: number, what: 回覆引用的 n 與你在 Descriptives 看到的一致}
  - {step: assumption, what: 你自己跑 Assumption Checks，結果與回覆的預期一致或不一致都記下}
stop_criteria:
  solved: 四個 expected 全命中且 path 查核零錯 → 依建議執行
  reopen: 任一路徑點不到，或回覆未提 Assumption Checks → 換 explainer persona 重問一次；仍失敗則改查 lsj-book 第 11 章
links:
  - {title: "lsj-book ch.11 Comparing two means", url: "https://davidfoxcroft.github.io/lsj-book/", license: "CC BY-SA 4.0"}
tested_with:
  - {date: 2026-09-08, provider: TODO, model: TODO, result: TODO, note: 尚未實測，Phase 0 補}
```

### 4.3 範例二：遺漏值分流（Guider，explainer）

```yaml
id: missing-data-triage
title: {zh: 遺漏值先分流再處理, en: Triage missing data before you treat it}
analysis: guider
scenario:
  zh: 摘要顯示某些變項遺漏比例不低，想知道先該做什麼、哪些決定 LLM 不能替你做。
  en: Some variables show notable missingness; what to do first and what an LLM cannot decide for you.
variables:
  - {role: outcome, type: continuous, n_levels: null}
  - {role: predictor, type: continuous, n_levels: null}
design: none
stat_goal: screen
prerequisites:
  - 勾選所有你關心的變項再送出（摘要裡的「遺漏」欄是 LLM 唯一看得到的線索，F3）
persona: explainer
prompt:
  zh: "摘要裡 {var_a} 遺漏 {pct_a}%、{var_b} 遺漏 {pct_b}%。請用初學者聽得懂的方式說明：這個比例算不算嚴重、我該先在 jamovi 用哪個分析看遺漏是否集中在某些組別（引用路徑），以及哪些處理方式的選擇需要我自己根據研究設計決定、你無法替我判斷。"
  en: "The summary shows {var_a} has {pct_a}% missing and {var_b} {pct_b}%. In beginner terms: is this serious, which jamovi analysis (exact path) lets me see whether missingness clusters by group, and which treatment decisions depend on my design so you cannot make them for me?"
system_prompt_override: null
expected:
  - 明確說明它看不到遺漏的「型態」（MCAR/MAR/MNAR 無法從摘要判斷）
  - 建議 Exploration ▸ Descriptives（Split by）或 Frequencies 之類真實路徑觀察分佈
  - 把「刪除 vs. 插補」的決定交回使用者，並說明依據
check:
  - {step: path, what: 路徑逐字核對}
  - {step: number, what: 遺漏比例與 Descriptives 的 Missing 欄一致}
  - {step: cross-check, what: 換 consultant persona 再問一次，兩次的「交回使用者決定」清單是否一致}
stop_criteria:
  solved: 回覆明確承認摘要的極限且建議的觀察步驟可執行
  reopen: 回覆直接替你選了插補方法而未說明前提 → 記為「過度自信」案例，進 spot-the-error 練習
links:
  - {title: "lsj-book ch.6 (data handling)", url: "https://davidfoxcroft.github.io/lsj-book/", license: "CC BY-SA 4.0"}
tested_with:
  - {date: 2026-09-08, provider: TODO, model: TODO, result: TODO, note: 尚未實測}
```

### 4.4 範例三：混合設計 ANOVA 的資料整形（R tutor，tutor persona）

這條示範 `rtutor` 條目與 `code-read` / `code-run` 查核。

```yaml
id: mixed-anova-setup
title: {zh: 混合設計 ANOVA 前的資料整形, en: Reshaping data for a mixed ANOVA}
analysis: rtutor
scenario:
  zh: 資料是寬格式（每個受試者一列、三個時間點三欄）加一個組別欄；想在 Rj 裡先確認長寬轉換是否正確，再回 jamovi 跑 Repeated Measures ANOVA。
  en: Wide data (one row per subject, three time columns) plus a group column; verify a long-format reshape in Rj before running RM ANOVA in jamovi.
variables:
  - {role: id, type: nominal, n_levels: null}
  - {role: grouping, type: nominal, n_levels: 2}
  - {role: outcome, type: continuous, n_levels: null}   # ×3 時間點
design: mixed
stat_goal: compare-k
prerequisites:
  - 確認 Rj 已安裝（否則 R tutor 會改教 Syntax Mode）
  - 三個時間點欄名記下來
persona: tutor
prompt:
  zh: "資料 data 有 {id}、{group} 與三個時間點欄 {t1}、{t2}、{t3}。請只給程式骨架與 TODO 註解，引導我用 base R 或 rj_environment 裡有的套件把它轉成長格式，並印出每個受試者 × 時間點的列數讓我核對；不要幫我跑 ANOVA。"
  en: "data has {id}, {group}, and three time columns {t1}, {t2}, {t3}. Give only a skeleton with TODO comments guiding me to reshape to long format using base R or packages in rj_environment, and print the rows per subject × time so I can verify; do not run the ANOVA for me."
system_prompt_override: null
expected:
  - 只用 `data`，不出現 read.csv / install.packages（R tutor 的硬規則）
  - 長格式列數 = n 受試者 × 3
  - 有一行驗證輸出（table 或 nrow）
check:
  - {step: code-read, what: 逐行讀：有無 setwd／檔案路徑／未列在 rj_environment 的套件}
  - {step: code-run, what: 貼進 Rj 執行；nrow 是否等於 n × 3；有錯誤訊息就原文貼回下一次問題}
  - {step: cross-check, what: 回 jamovi 用 ANOVA ▸ Repeated Measures ANOVA 跑寬格式原資料，比對描述統計是否與長格式一致}
stop_criteria:
  solved: code-run 列數正確且 cross-check 描述統計一致
  reopen: 列數不對或程式碼用了環境沒有的套件 → 把錯誤訊息貼回、換 consultant 要完整版
links:
  - {title: "psyteachr quant-fun (wrangling / ANOVA)", url: "https://psyteachr.github.io/quant-fun-v3/", license: "CC BY-SA 4.0"}
tested_with:
  - {date: 2026-09-08, provider: TODO, model: TODO, result: TODO, note: 尚未實測}
```

### 4.5 條目擴充順序（Phase 1 目標 12 條）

以 `stat_goal` 為軸各 2 條、Guider / R tutor 各半：describe、compare-2、compare-k、associate、predict、screen。優先挑 lsj-book 有對應章的題目，方便 `links` 直接指過去。

---

## 5. AI 生成結果的查核教程

### 5.1 原則

- **查核不是「再問一次 AI」**，是拿 AI 看不到的東西（你的 jamovi 介面、你的原始資料、你的研究設計）去對。
- 兩條路線難度不同（F6）：Guider 的輸出有有限集合可核；R tutor 的輸出只能靠流程。
- 每次查核產出一筆「協作日誌」（L1 第 6 課的四欄），這是可教、可重複、可交作業的單位。

### 5.2 查核流程（`verify/workflow.qmd`）

```
送出前   P0 寫判準（我會接受什麼答案）           ← L1 第 3 課
         P1 記下摘要裡的關鍵數字（n、mean、遺漏）

收到後   V1 路徑核對（Guider）：每條 Analyses ▸ … 在選單點得到？逐條打勾
         V2 數字核對：回覆引用的數字 = P1 記下的？
         V3 範圍核對：回覆有沒有宣稱它「看不到」的事（常態性、離群值、原始列）？有 → 標「越界」
         V4 程式碼核對（R tutor）：
              4a 讀：只用 data？library() 都在 rj_environment？無 setwd／路徑／system？
              4b 跑：貼進 Rj，記錄輸出或錯誤原文
              4c 對：同一分析在 jamovi GUI 跑一次，關鍵數字一致？（Syntax Mode 的 jmv:: 呼叫可作第二對照）
         V5 交叉：換 persona 或換模型再問一次，結論一致？路徑仍須各自核對

結案     C1 對照 P0 判準：solved / reopen
         C2 填協作日誌（問題｜判準｜回覆摘要｜查核結果）
```

### 5.3 兩份查核清單

- `checklist-guider.qmd`：P0–P1、V1–V3、V5、C1–C2，做成可列印一頁。
- `checklist-rtutor.qmd`：P0–P1、V2–V4、V5、C1–C2，4a 那段附「紅旗字串表」（`install.packages`、`read.csv`、`setwd`、`system(`、絕對路徑、`library(` 後接不在清單的套件）。

### 5.4 教學用「故意找錯」（`spot-the-error.qmd`）

直接取材 `docs/LIMITATIONS.zh-TW.md` 表格裡的真實錯誤路徑（`分析 > 比較 > 獨立樣本t檢定`、`探索 > 相關性`、`Regression > General Linear Model > Linear Regression` 等），做成 8–10 題「這條路徑錯在哪」與 3–4 題「這段 R 違反哪條紅旗」，附答案與對應的查核步驟編號。這是 F8 建議的「讓學生親身發現幻覺」的可批改版本。

---

## 6. 外部教材整合策略

授權查證日期 2026-09-08，方法：WebFetch 各站首頁／GitHub repo。README 列的五個 psyteachr 短網址**全部是轉址頁**，實際版本如下。

| 教材 | 實際位置 **[已查證]** | 授權 | 查證來源 | 建置工具 | 取什麼 | 怎麼取 | 要不要改寫 |
|---|---|---|---|---|---|---|---|
| psyteachr **data-skills** | `psyteachr.github.io/data-skills-v3/`（站頁標示 source repo 為 `psyteachr/data-skills-v2`） | **CC BY-SA 4.0**（repo LICENSE） | GitHub repo `psyteachr/data-skills-v2` LICENSE；v3 站頁未顯示授權 **[部分查證]** | bookdown | 資料匯入、描述統計章節作為 L1 第 1、5 課的延伸閱讀 | 連結到章 | 否 |
| psyteachr **analysis** | `psyteachr.github.io/analysis-v4/` | **CC BY 4.0**（站頁「CC-BY (2025) Mahrholz & Kuepper-Tetzel」＋ repo footer CC-BY-4.0） | 站頁 + GitHub `psyteachr/analysis-v4` | 未標示 **[未查證]** | t-test／相關／迴歸／ANOVA 走讀章，對應 L2 的 compare-2、associate、predict | 連結到章；若需引用範例資料可改寫（BY 允許） | 僅在 spot-the-error 需要示例時擷取小段，附出處 |
| psyteachr **stat-models** | `psyteachr.github.io/stat-models-v1/` | **CC BY-SA 4.0** | 站頁 + repo `psyteachr/stat-models-v1` | bookdown | 混合效果模型章，作為 mixed 設計條目的「進階閱讀」 | 連結 | 否（超出 jamovi GUI 範圍） |
| psyteachr **quant-fun** | `psyteachr.github.io/quant-fun-v3/` | **CC BY-SA 4.0** | 站頁 + repo `PsyTeachR/quant-fundamentals-v3` | Quarto／R Markdown | wrangling、ANOVA、多元迴歸，對應 R tutor 條目 | 連結 | 否 |
| psyteachr **reprores** | `psyteachr.github.io/reprores-v6/` | **CC BY**（站頁「CC-BY 2026, psyTeachR」；版本號未標示 **[部分查證]**） | 站頁 + repo `psyteachr/reprores-v6` | Quarto 1.9 | Debugging 附錄、Data Types 附錄，對應 V4a 讀碼 | 連結；可節錄 | 否 |
| **lsj-book**（Foxcroft 改編自 Navarro） | `davidfoxcroft.github.io/lsj-book/`；Open Book Publishers 2025，DOI `10.11647/OBP.0333` | **CC BY-SA 4.0**（repo README 明文；站頁本身未顯示授權 **[部分查證]**） | GitHub `davidfoxcroft/lsj-book` README | Quarto | **主要對照教材**：每條提示詞的 `links` 首選；jamovi 選單路徑的權威截圖來源 | 連結到章；截圖不轉載（自己截） | 否；若未來要改寫任何段落，衍生部分須 BY-SA |
| **bradduthie/stats**（Duthie，生物／環境科學） | `bradduthie.github.io/stats/` | **CC BY-NC-SA 4.0** | 站頁明文 | bookdown | 非心理學情境的 jamovi 操作章（給非心理系使用者對號） | **只連結** | **不改寫、不節錄**：NC 條款與本站 BY-SA 不相容，混入會讓整站授權不清 |

整合方式統一為 `external/reading-map.qmd` 一頁：左欄「你的情境（stat_goal × design）」、右欄「去哪一章」，每格附授權標記。這頁的資料也從提示詞條目的 `links` 欄位彙整產生，避免兩處維護。

**授權結論**：本站若採 **CC BY-SA 4.0**，可安全「連結」全部七套、「節錄」六套（BY 與 BY-SA）、「改寫」六套（改寫部分維持 BY-SA）；bradduthie/stats 永遠只連結。提示詞條目與 `tools/` 程式碼建議另以 **MIT** 授權（★ 需拍板，見 §9），讓使用者複製提示詞時無署名負擔。

---

## 7. 技術實作選項

### 7.1 靜態網站產生器比較

| | Quarto（website） | bookdown | mkdocs（Material） |
|---|---|---|---|
| 與母專案工具鏈 | R 已在（`D:\Apps\R`）；lsj-book、reprores、quant-fun 都用 Quarto，格式互通 | R 已在；data-skills、stat-models 用 | 需 Python；母專案規則要求 uv+venv，多一套環境 |
| 多語 | **profiles**（`_quarto-en.yml`）＋ `{{< include >}}`，原生支援 | 需分兩本書或自製 | i18n 外掛，可用 |
| YAML → 頁面自動產生 | R 腳本產 `.qmd` 即可；可在 `pre-render` hook 執行 | 同上但 hook 較弱 | Python 腳本；`mkdocs-macros` |
| 可執行 R 區塊（示範 `summarize_data()` 的輸出長什麼樣） | 是 | 是 | 否 |
| 與 askLLM 常青頁的視覺一致性 | 現有 `learn-r.html` 是手寫 HTML；Quarto 可套自訂 CSS 靠齊 | 同 | 同 |
| 未來若要合併回 askLLM `docs/` | 輸出純 HTML，可直接搬 | 可 | 可 |

**推薦：Quarto website**。理由：零新環境、與三套外部教材同工具（未來若要引用其 `.qmd` 片段最省事）、profiles 解決雙語、`pre-render` 能跑 `tools/build-prompts.R`。取捨：Quarto 的 website 沒有 book 的章節導航；但本站是「三塊各自扁平」的結構，website 的 sidebar 已足夠，且日後轉 book 只是改 `project: type`。

### 7.2 語言策略

- **繁中為主、英文為必要子集**：L1 六課與 L3 查核流程做完整雙語（呼應 F9 的成對慣例，也因為 askLLM 的 Persona 支援 en／zh，使用者兩種語言都會用）。L2 條目說明頁**亦為完整雙語**（Q5 已拍板）：`prompt`、`expected`、查核點與說明文字都需人工撰寫或校對的英文，不接受機器翻譯佔位——因為要向英文教材原作者徵求回饋。schema 須把英文欄位列為必填並由 validator 強制。`external/reading-map` 單一英文頁（教材全是英文）。
- **實作（2026-09-08 修正）：單一站台 + 語言切換鈕，不做雙站。** 原設計為 `_quarto-en.yml` profile 輸出到 `docs/en/`，實作後發現行不通——內容是中英對照寫在同一檔，profile 只能換掉 navbar 與 `lang` 屬性，切不出單語頁面，兩站內容完全相同（實測同為 1,082 個中文字元），且 `docs/en` 位於 `docs/` 之內會被中文站 render 清空。改為：內容以 `[中文]{.zh}[English]{.en}`（標題、行內）與 `::: {.zh}` / `::: {.en}`（區塊）標記，`assets/lang.css` 依 `<html>` 的 `lang-zh`／`lang-en` class 隱藏另一語言，`_includes/lang-init.html` 在 `<head>` 內先定語言（localStorage → 瀏覽器語言 → 預設中文）避免閃爍，`_includes/lang-toggle.html` 提供右上角切換鈕並記憶選擇。`_quarto-en.yml` 已刪除。程式碼區塊與語言中立的表格不包 div，兩種語言都顯示。
- 提示詞 JSON（`docs/prompts.json`）語言無關，供 askLLM 或其他工具日後讀取（F7 的 `learn-r.json` 已是同型先例）。

### 7.3 測試與 CI

- `tools/validate-prompts.R` 與 `tools/build-prompts.R` 為純函式，`tests/testthat/` 覆蓋（母專案規則：R 用 testthat，先寫失敗測試）。
- GitHub Actions：`quarto render` 前跑 validate；週期性跑 `check-links.R`（比照 `release-check.R` 的 WARN／FAIL 分級，docs.jamovi.org 403 視為 WARN）。

---

## 8. 分階段路線圖

| 階段 | 產出物 | 完成判準（可驗證） |
|---|---|---|
| **Phase 0 — 骨架與可行性**（約 2 週） | `_quarto.yml`、目錄骨架、`_schema.yaml`、`validate-prompts.R` + 測試、§4 的 3 條提示詞（`tested_with` 填入真實實測）、`checklist-guider.qmd`、GitHub Pages 上線 | (1) `devtools::test()` 全綠；(2) `quarto render` 零錯誤且 `docs/prompts.json` 含 3 條；(3) 3 條提示詞各在至少 1 個 provider 實測並記錄 pass／partial／fail；(4) 網址可公開存取；(5) 已確認 `question` 欄是否單行（F2 的未定項）並更新 schema 規則 |
| **Phase 1 — 最小可教版本**（約 4 週） | L1 六課（zh 完整 + en 完整）、L3 兩份清單 + `workflow.qmd`、L2 擴到 12 條、`reading-map.qmd`、askLLM 側 link-out（跨 repo：Html links 項 + `learn-r.json` 新 section） | (1) 12 條全過 validate 且每條 ≥ 1 筆實測；(2) 一位非作者（學生或助教）照 `workflow.qmd` 走完一條 Guider 與一條 R tutor 條目，能填出完整協作日誌，過程中不需口頭補充；(3) askLLM `release-check.R` 對新連結回 PASS；(4) `check-links.R` 對七套外部教材連結全 PASS 或 WARN（無 FAIL） |
| **Phase 2 — 課堂驗證**（一個學期） | `spot-the-error.qmd`（≥ 10 題附答案）、協作日誌範本、課堂回收資料的摘要（去識別） | (1) 至少一班用過，回收 ≥ 20 份協作日誌；(2) 依日誌把「reopen」比例最高的 3 條提示詞改版並重測；(3) 找出至少 1 個 LIMITATIONS 未記錄的新錯誤類型並回饋到 askLLM repo（issue 或 dev-note） |
| **Phase 3 — 擴充（視需求）** | 英文條目說明頁校對、非心理學情境條目（連 bradduthie）、`prompts.json` 被 askLLM 讀取（例如結果面板依 `stat_goal` 推薦條目） | 每項各自立判準；此階段不在本方案承諾範圍 |

---

## 9. 風險與開放問題（★ 需拍板，最多 6 條）

| # | 決策點 | 我的推薦 | 理由／風險 |
|---|---|---|---|
| Q1 | ~~**本站授權**~~ **已拍板 2026-09-08：文字 CC BY-SA 4.0 + 提示詞/程式碼 MIT**。 | — | 已建立 `LICENSE`，逐段列出適用檔案範圍。第三方教材維持原授權，逐條記於 `links[].license`；bradduthie/stats 為 CC BY-NC-SA 4.0，僅連結不改寫。 |
| Q2 | ~~**repo 形態**~~ **已拍板 2026-09-08：獨立 git repo**。 | — | 比照 askLLM（`SCgeeker/askLLM`，nested 於 `jmv_modules/` 但自成 repo，母 repo 不追蹤）。已 `git init`（分支 `main`）。GitHub remote 與 Pages 待建立。 |
| Q3 | **與 askLLM 的耦合深度**：只 link-out（Phase 1），還是讓 askLLM 讀 `prompts.json` 在結果面板推薦條目（Phase 3）？ | Phase 1 只 link-out；Phase 3 再議 | 讀外部 JSON 意味 askLLM 執行期要抓網路或打包快照，與「不 runtime 抓」的既有決策（`dev-notes/r-tutor-bridge-plan.zh-TW.md`）衝突，必須由作者改變決策才能做 |
| Q4 | ~~**`question` 欄的多行支援**~~ **已判定 2026-09-08：支援多行，提示詞可用 `\n` 結構化**。 | — | 證據：`askllm.a.yaml:25-28` 為 `type: String` 無長度限制；`askllm.u.yaml:34-39` 的 TextBox 確實無 multiline 屬性，但 `jamovi/js/askllm.js:84-86` 與 `askllmr.js:83-85` 皆注入 `<textarea rows="5">` 並以 `ui.question.setValue()` 回寫（含換行）；`askllm.b.R:96,469` 只用 `trimws()` 去頭尾空白，`llm-adapter.R:181` 直接 `paste0('Question: ', question)`，全檔無 `gsub`/`strsplit` 處理換行。**兩個模組（askllm 與 askllmr）行為一致，已逐檔確認。** 注意：多行是專案自行以 view-layer JS 擴充，非 jamovi schema 原生功能——日後新模組要多行需複製同一套 JS 注入。 |
| Q5 | ~~**英文覆蓋範圍**：L2 條目說明頁要不要完整英文？~~ **已拍板 2026-09-08：要**。 | — | 決策理由：將向英文教材原作者（psyteachr、lsj-book 等）徵求回饋，條目說明頁必須是可直接閱讀的英文，機器翻譯佔位不可接受。代價：L2 維護成本翻倍（PLAN W4-2 已警告），故 Phase 1 的 12 條目標需重新評估工時。 |
| Q6 | **練習資料**：用 jamovi 內建範例（Tooth Growth、Big 5 等）還是自製模擬資料？ | jamovi 內建範例優先，不足處以 R 模擬並附產生腳本 | 內建範例學生手邊就有、零授權問題；lsj-book 的 `data_and_tables/` 雖為 BY-SA 可用，但版本會漂移，不建議複製 |

### 其他風險（不需拍板，但要知道）

- **外部教材網址漂移**：psyteachr 五套全是轉址頁，版本號在路徑裡（v3／v4／v1／v3／v6），每年會換。`check-links.R` 必須定期跑，`reading-map` 的連結一律指向短網址（如 `psyteachr.github.io/analysis/`）讓轉址吸收變動。
- **`tested_with` 會過期**：模型與 provider 更迭快（LIMITATIONS 記錄過目錄有、實際 400 的模型）。建議條目頁顯示「最近實測日期」，超過 6 個月自動標黃。
- **與 LIMITATIONS 文件重疊**：本站 L3 與 `askLLM/docs/LIMITATIONS.*.md` 有內容重疊風險。分工：LIMITATIONS 記「觀察到什麼」（實測記錄），本站記「怎麼查」（流程與練習），互相連結不互抄。

---

## 附錄 A：查證記錄

| 項目 | 結果 | 備註 |
|---|---|---|
| psyteachr 五個短網址 | 全為轉址頁 | 指向 data-skills-v3 / analysis-v4 / stat-models-v1 / quant-fun-v3 / reprores-v6 |
| data-skills-v3 站頁授權 | **未顯示** | 改查 source repo `psyteachr/data-skills-v2` LICENSE = CC BY-SA 4.0（站頁自稱 source 為 v2 repo，v3 是否同授權**未查證**） |
| analysis-v4 建置工具 | **未查證** | 站頁與 repo 摘要皆未標示 |
| reprores-v6 授權版本號 | 站頁僅「CC-BY 2026」，未標 4.0 | 合理推定 4.0，**未查證** |
| lsj-book 站頁授權 | 站頁未顯示；`lsj_about.html` 404 | 以 GitHub README「CC BY-SA 4.0」為準 |
| bradduthie/stats 原始碼 repo | 站頁只給資料集與 shiny 的 GitHub 連結、OSF `osf.io/dxwyv` | 書的原始 `.Rmd` repo 位置**未查證**；不影響「只連結」策略 |
| `question` 選項是否單行 TextBox | **未查證**（需 jamovi 內實測） | 見 Q4 |
| askLLM GitHub Pages 是否從 `docs/` 目錄發佈 | 依 README 連結 `scgeeker.github.io/askLLM/learn-r.html` 與檔案位置 `docs/learn-r.html` 推定 | **推定**，未看 repo settings |
