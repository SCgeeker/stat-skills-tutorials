# 例子替換提案 — 以有出處的真實素材取代自創情境（v2）

> v2 記入你在 v1 的六項批註。v1 存檔於
> `.examples_rewrite_20260908_v1_archive.md`。

依 `en_rewrite_20260908.md` 的 HTML 註解「Find the examples from the
external resource I listed in README.md. If it is OK, we can modify the
stories for our purpose」而作。 素材來源與授權見
`external-examples-survey.md`。

**本檔是提案，尚未套用到任何 `.qmd` 或 `.yaml`。**

------------------------------------------------------------------------

## 0. 先請你定調：兩種「真實」

盤點結果裡的素材分成兩類，性質不同，課文措辭會跟著不同。

| 類別 | 例子 | 性質 | 學生能拿到資料嗎 |
|----|----|----|----|
| **已發表研究** | Zwaan et al. (2018) Simon task、Zhang et al. (2014) time capsule、Lopez et al. (2024) 湯碗研究 | 真實研究，有 OSF 連結與論文 | 可，但要自己去 OSF 下載 |
| **教學用虛構資料** | lsj-book 的 `clinicaltrial.csv`、`harpo.csv` | 頁面明文寫 "fictitious, created for instructional purposes" | 可，隨 lsj 模組附帶，最容易取得 |

兩類都比現在的自創變項名好，因為**變項結構有出處、可查證**。差別在課文能不能說「這是真實研究」。

**我的建議**：兩類都用，但措辭分開。提示詞條目與需要「真實研究長什麼樣」的情境用已發表研究；純粹要學生馬上動手的練習用
lsj-book 的教學資料，因為取得成本最低。課文提到後者時寫 "a teaching
dataset from *Learning Statistics with jamovi*"，不寫 "a study"。

**這一項需要你點頭，下面的替換才有意義。**

------------------------------------------------------------------------

## 1. 第一課開場：三個選項

現況是虛構的「模型謊稱第 47 筆偏高」。外部教材沒有 LLM
犯錯的故事（`external-examples-survey.md` 第 5
節已逐頁確認），所以素材只能來自 `askLLM/docs/LIMITATIONS.zh-TW.md`
的真實實測記錄。

### 選項 A（推薦）：保留現有故事，補上真實案例佐證

現有故事的教學功能無可取代——它演示「模型指認了一個它根本看不到的列」，正好對上這一課的主旨。
問題只在於它讀起來像真事。加一句標示，再用真實案例佐證。

**擬新增於開場段之後：**

> ::: zh
> 這個對話是**示意範例**，不是實際記錄。但同一類錯誤是真的發生過的：askLLM
> 的實測記錄裡， 在未勾選 Attach data summary 的情況下，模型憑空生出「8
> 個樣本、Saguaro 與 Palo Verde 三個
> 物種」這種與手上資料毫無關係的內容（見
> `askLLM/docs/LIMITATIONS.zh-TW.md`）。模型沒有資料
> 時不會說「我沒有資料」，它會編一份出來。
> :::
>
> ::: en
> That exchange is **illustrative**, not a transcript. The same class of
> error is real, however. askLLM's own testing records a reply that
> invented "8 samples across three species, Saguaro and Palo Verde" for
> a dataset containing nothing of the kind, produced with the data
> summary switched off (see `askLLM/docs/LIMITATIONS.zh-TW.md`). Given
> no data, the model does not say it has no data. It makes some up.
> :::

### 選項 B：整段換成真實案例

把開場改寫成 Saguaro/Palo Verde
那則。代價：這一課的主旨是「摘要之外的事它看不到」，而該案例
的主旨是「完全沒摘要時它會編」——焦點會偏，後面第五課才是講這個。

### 選項 C：換成選單路徑幻覺對照表

`LIMITATIONS.zh-TW.md` §1 那組幻覺路徑，附 v1.1 緩解後「18/18
命中」的正向收尾。敘事更完整， 但那是第三課（判準）與
`spot-the-error.qmd` 的題材，放在第一課會重複。

**我選 A。** 它同時修好誠實性與教學功能，且不動既有結構。

------------------------------------------------------------------------

## 2. 第二課八組對照：六組可換，兩組待查

現況八組全部使用自創變項名。下表列出可替換者。**中文與英文兩張表都要同步改。**

| \# | 現況（自創） | 建議替換 | 出處 | 授權 |
|----|----|----|----|----|
| 1 | `score` / `group`（實驗組／對照組） | `simon_effect` / `similarity`（same／different） | Zwaan et al. (2018) Simon task，analysis-v4 ch.7 | CC BY 4.0 |
| 2 | `income` 的遺漏比例 | `Household Income` / `Political Preference` 的遺漏 | Dawtry et al. (2015)，quant-fun-v3 ch.11 | CC BY-SA 4.0 |
| 3 | `anxiety` / `sleep_hours` 相關 | `CalEstimate` 與實際攝取量的相關 | Lopez et al. (2024) 湯碗研究，analysis-v4 ch.9 | CC BY 4.0 |
| 4 | 泛稱「跑完 t 檢定」 | 同 #1 的 Zwaan 資料，接 Levene／Welch 判斷 | analysis-v4 ch.7 | CC BY 4.0 |
| 5 | `satisfaction` / `department`（3 水準） | `mood.gain` / `drug`（placebo／anxifree／joyzepam） | lsj-book ch.13 `clinicaltrial.csv` | CC BY-SA 4.0 |
| 7 | `reaction_time` 的 max 遠大於 mean | 同名變項，改指 Stroop 資料集 | psyteachr data-skills-v3 stroop | CC BY-SA 4.0 |
| 6 | `age` + `hours_studied` → `exam_score` | **未找到**替代 | — | — |
| 8 | `pass_fail` × `condition` 列聯表 | **未找到**替代 | — | — |

### ⚠️ 第 6、8 組沒有素材

本次盤點沒有涵蓋迴歸章與卡方章。lsj-book 有對應章節（ch.12 卡方、ch.15
迴歸），但 agent 未讀， **我不會憑目錄推測變項名**。兩個處理方式：

- 補一次針對這兩章的盤點，再一起替換（乾淨，但多一輪）
- 這兩組維持自創變項名，並在該列註明「示意」（八組裡兩組不同調，讀者會發現）

**建議補盤點。** 八組對照的說服力來自一致性，混用會削弱它。

### ~~第 5 組附帶的一個教學點~~（已作廢：多重比較不納入本教程，改為只連結推薦資源）

lsj-book ch.13 對 `clinicaltrial.csv` 明講「no reason to use Bonferroni
since it is always outperformed by Holm」，且**完全未討論
Tukey**。本站現有提示詞未指定事後檢定方法。這是一個可以
寫進課文的對照：教材有明確立場，而你問 LLM
時如果不指定，它給的未必是教材建議的那個。
**這需要你同意才寫進去**，因為它等於在課文裡對事後檢定表態。

------------------------------------------------------------------------

## 3. 提示詞條目：三處替換

### 3.1 `mixed-anova-setup.yaml` — 情境換成真正的 2×2 混合設計

現況情境是自創的「三個時間點欄 + 一個組別欄」。Zhang et al. (2014)
是真正的 2×2 混合設計 （between = Condition，within = Time），我已用
WebFetch 親自核對過 analysis-v4 ch.13 的頁面內容。

**授權邊界**：`prompts/entries/*.yaml` 在本 repo 是 MIT，不能放 CC BY-SA
的改寫文字。所以情境 **用我們自己的話重寫**，只在 `links`
標出處。以下擬稿是自撰文字，非教材節錄。

``` yaml
scenario:
  zh: 資料是寬格式：每位受試者一列，兩個時間點各一欄（事前預測與事後實際），另有一個兩水準的
      組別欄。想在 Rj 裡先確認長寬轉換是否正確，再回 jamovi 跑混合設計 ANOVA。
  en: >-
    Data is in wide format: one row per participant, one column for each of two
    time points (a prediction beforehand and the actual rating afterwards), plus
    a two-level group column. You want to verify a long-format reshape in Rj
    before running the mixed ANOVA in jamovi.
```

連帶要改的兩處：

- `prerequisites` 的「三個時間點欄名記下來」→「兩個時間點欄名記下來」
- `links` 增加
  `{title: "psyteachr analysis ch.13 Factorial ANOVA (Zhang et al. 2014 time capsule)", url: "https://psyteachr.github.io/analysis-v4/13-factorial-anova.html", license: "CC BY 4.0"}`

**要注意**：這會讓條目從「三時間點」變成「兩時間點」，`expected` 與
`check` 裡若有提到欄數需一併 核對。我尚未逐條檢查，套用時會做。

### 3.2 `ttest-assumptions.yaml` — links 指到具體章節

現況：`{title: "lsj-book ch.11 Comparing two means", url: "https://davidfoxcroft.github.io/lsj-book/"}`
——標題寫 ch.11，URL 卻是書的首頁，讀者點過去要自己找。

**擬改為兩條：**

``` yaml
links:
  - {title: "lsj-book ch.11 Comparing two means", url: "https://davidfoxcroft.github.io/lsj-book/11-Comparing-two-means.html", license: "CC BY-SA 4.0"}
  - {title: "psyteachr analysis ch.7 Independent-samples t-test (Shapiro-Wilk, Levene, Welch)", url: "https://psyteachr.github.io/analysis-v4/07-independent.html", license: "CC BY 4.0"}
```

這一條的 `expected` 清單（Welch 優先、Levene、Mann-Whitney
替代）與這兩章的實際教法高度吻合， 指到具體頁面後學生可以直接對照。

### 3.3 `missing-data-triage.yaml` — links 指到具體章節

同樣的問題：現況指向 quant-fun 首頁。擬改指
`https://psyteachr.github.io/quant-fun-v3/11-screening-data.html`。

我已用 WebFetch 核對該章確實教 `summary()` 找 NA、`drop_na()`
刪除、`nrow()` 記錄刪除前後 （305 → 301 → 294）。該章也坦承未處理
MCAR/MAR/MNAR 與插補——這正好呼應本條目 `expected` 裡
「模型應說明它看不到遺漏的型態」。可在課文或條目說明補一句：連教科書都止步於刪除法，插補的前提
判斷需要你自己來。

------------------------------------------------------------------------

## 4. 署名要怎麼寫

改寫自 CC BY-SA 來源的文字，本站散文（`.qmd`）已是 CC BY-SA
4.0，相容；CC BY 來源只需署名。 `external-examples-survey.md` 第 3
節備有可直接貼用的英文署名句。

放置方式建議：**不要逐段插署名**，在使用該素材的頁面底部設一個
`## [資料來源]{.zh}[Data sources]{.en}`
小節統一列出。第二課會用到四個來源，逐段標註會壓垮版面。

`prompts/entries/*.yaml` 因為是 MIT，情境一律自撰、只在 `links`
標出處，不承載改寫文字。

------------------------------------------------------------------------

## 5. 對 P-CSO 改寫的影響

第二課的八組對照若照本提案替換，那兩張表會整段重寫。**建議第二課的 P-CSO
批次等這件事定案後 再做**，否則同一段文字會被改兩次。第一課若採選項
A，只是新增一段，不影響已完成的批 1 草稿。

------------------------------------------------------------------------

## 2b. 第 6、8 組的補盤點結果（`external-examples-survey-2.md`）

### 第 8 組｜類別 × 類別 — 已解決，用真實研究

| 項目 | 內容 |
|---|---|
| 資料 | Ballou et al. (2024)，`Gender`（3 水準：Woman／Man／Non-binary）× `Education`（5 水準） |
| 樣本數 | N = 1,083 |
| 出處 | psyteachr analysis-v4，https://psyteachr.github.io/analysis-v4/06-chi-square-one-sample.html |
| 授權 | CC BY 4.0（頁腳實讀："CC-BY (2025) Gaby Mahrholz Carolina E. Kuepper-Tetzel"） |
| 我的核對 | 已用 WebFetch 親自確認：該章確實做兩個類別變項的關聯檢定，χ²(8) = 13.59, p = .093 |

**附帶的教學價值**：這個真實研究的結果**不顯著**。八組對照全用「一定會顯著」的例子會給錯印象，
放一個有出處、真實、且不顯著的例子反而誠實。

### 第 6 組｜多元迴歸 — 需要你選一條路

補盤點的結論是：**逐頁查過六本教材，找不到「兩個連續預測變項 + 真實已發表研究」同時成立的例子。**
這是查證後的確認，不是漏查。所以只能二選一。

#### 路線甲：保留現況的提問結構，改用教學虛構資料

| 項目 | 內容 |
|---|---|
| 資料 | lsj-book ch.12 `parenthood.csv`：`dani.sleep` + `baby.sleep`（兩個連續預測）→ `dani.grump` |
| 出處 | https://davidfoxcroft.github.io/lsj-book/12-Correlation-and-linear-regression.html |
| 性質 | 虛構。頁面自承 "fictitious, but based on real events" |
| 好處 | 與現況那一列的結構完全吻合（兩連續預測 + 共線性提問），原書就有 Checking for collinearity 小節 |
| 代價 | 違背你「優先用真實資料」的偏好；八組裡會有一組是虛構的 |

#### 路線乙（我推薦）：改寫這一列的提問，改用真實研究

| 項目 | 內容 |
|---|---|
| 資料 | Przybylski & Weinstein (2017)：結果變項 `WEMWBS_sum`（連續，14–70）；預測變項為平均置中的智慧型手機使用時數（連續）與 gender（類別，deviation coding），另含兩者的交互作用項 |
| 樣本數 | N = 71,033 |
| 出處 | psyteachr analysis-v4 https://psyteachr.github.io/analysis-v4/11-multiple-regression.html （quant-fun-v3 ch.14 用同一份資料）；原始資料 OSF |
| 授權 | CC BY 4.0（頁腳實讀同上） |
| 我的核對 | 已用 WebFetch 親自確認變項組成、樣本數，以及該章確實用 `check_collinearity()` 講 VIF |

**代價**：這一列從「兩個連續預測變項」變成「一個連續 + 一個類別預測變項」。

**為什麼我仍推薦乙**：這一列要教的是「把『我要跑迴歸』改寫成一句可回答的問題」，不是「多元迴歸必須
有兩個連續預測變項」。連續 + 類別的組合在實際研究裡更常見，共線性檢查一樣要做，而且該章本來就在
講 VIF。用真實研究換掉一個不必要的結構限制，我認為划算。

**擬改寫（若採乙）：**

> 改寫前：我要跑迴歸
>
> 改寫後（中）：用連續變項「每日使用時數」與類別變項 gender（兩水準）預測連續結果變項
> 「心理幸福感量表總分」，該用哪個迴歸分析？如何檢查預測變項之間的共線性？
>
> 改寫後（英）：Predict the continuous outcome `WEMWBS_sum` from continuous daily screen time
> and categorical `gender` (two levels). Which regression should I use, and how do I check
> collinearity between the predictors?
>
> 補進了什麼：預測變項與結果變項的名稱、型態、數量、分析目標（預測）、想要的額外檢查。

------------------------------------------------------------------------

## 已裁決事項（2026-09-08，依你在 v1 的批註）

| \# | 決定 | 對後續的影響 |
|----|----|----|
| §0 措辭 | **引用來源時加簡易說明**，不另立兩套措辭規則 | 每處引用附一句話說明它是什麼，例如 "a published replication study (Zwaan et al., 2018)" 或 "a teaching dataset from *Learning Statistics with jamovi*"。讀者自己看得出真實研究與教學資料的差別，不需要課文額外解釋 |
| 第一課開場 | **採選項 A** | 保留現有故事，加註示意，並補 Saguaro/Palo Verde 真實案例佐證。文字見上方 §1 選項 A |
| 第 6、8 組 | **補盤點，優先深挖 psyteachr 的真實資料** | 已派工，產出將寫入 `external-examples-survey-2.md`。lsj-book ch.12／ch.15 列為次選，因其資料多為教學虛構 |
| 事後檢定 | **多重比較不納入本教程**，只提示推薦學習資源 | §2「第 5 組附帶的教學點」作廢，不在課文對 Holm／Tukey 表態。改為在該列的資料來源註記處連到 lsj-book ch.13，讓想深入的讀者自己去讀 |
| 署名 | **頁尾統一列出** | 每個用到外部素材的頁面底部設 `## [資料來源]{.zh}[Data sources]{.en}` 小節 |
| `mixed-anova-setup.yaml` | 未批註，維持我的規劃 | 改成兩時間點後，`expected` 與 `check` 裡的欄數敘述由我在套用時逐條核對 |

------------------------------------------------------------------------

## Open items（尚未解決）

- [ ] 等 `external-examples-survey-2.md` 出爐，補上第 6、8 組的替換方案
- [ ] 全部定案後，本檔升為可套用的施工清單，逐檔套用並重建 `docs/`
- [ ] 第二課的 P-CSO
  英文改寫，待八組對照定稿後才做（否則同段文字改兩次）
