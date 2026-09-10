> **English** · [繁體中文](README.zh-TW.md)

# Test-evidence files (`.omv`)

This directory holds the test records for the prompt library entries. Each `.omv` is a complete
jamovi session containing askLLM's actual reply together with the follow-up analyses used to check
it. The `note` field of an entry's `tested_with` record refers to these filenames.

Naming: `<entry id>_<first author><year>_<language>.omv`. The `check` list for
`missing-data-triage` includes a cross-check step, which asks the same question again under a
different persona and compares the two replies. That step needs both runs side by side, so those
files carry an additional `_<persona>` suffix. The `mixed-anova-setup` prompt was revised on
2026-09-09, so its files carry `v1_fail` or `v2_fix` to say which wording produced them.

| File | Entry | Language | Analyses inside |
|---|---|---|---|
| `ttest-assumptions_zwaan2018_zhTW.omv` | `ttest-assumptions` | Chinese | askllm, ttestIS |
| `ttest-assumptions_zwaan2018_en.omv` | `ttest-assumptions` | English | askllm, ttestIS, anovaNP |
| `missing-data-triage_dawtry2015_zhTW_explainer.omv` | `missing-data-triage` | Chinese | askllm (explainer), descriptives |
| `missing-data-triage_dawtry2015_zhTW_consultant.omv` | `missing-data-triage` | Chinese | askllm (consultant), descriptives |
| `missing-data-triage_dawtry2015_en_explainer.omv` | `missing-data-triage` | English | askllm (explainer) |
| `missing-data-triage_dawtry2015_en_consultant.omv` | `missing-data-triage` | English | askllm (consultant), descriptives |
| `mixed-anova-setup_zhang2014_v1_fail_zhTW.omv` | `mixed-anova-setup` | Chinese | askllmr, Rj (prompt before the fix) |
| `mixed-anova-setup_zhang2014_v1_fail_en.omv` | `mixed-anova-setup` | English | askllmr, Rj (prompt before the fix) |
| `mixed-anova-setup_zhang2014_v2_fix_zhTW.omv` | `mixed-anova-setup` | Chinese | askllmr, Rj, anovaRM (prompt after the fix) |
| `mixed-anova-setup_zhang2014_v2_fix_en.omv` | `mixed-anova-setup` | English | askllmr, Rj, anovaRM (prompt after the fix) |

Tested on 2026-09-08 with provider `gemini` and model `gemini-flash-latest`. The Chinese explainer
run for `missing-data-triage` was repeated on 2026-09-09; the reason is in the last section.

## Data sources and licensing (important)

**These `.omv` files embed datasets from external teaching material.** Section 3 of this project's
`LICENSE` applies: third-party material keeps its own licence, and this project redistributes it
only under that licence, with the source named here.

| Data | Source | Licence |
|---|---|---|
| Zwaan et al. (2018) Simon task | psyteachr *Analysis* ch.7 (Mahrholz & Kuepper-Tetzel, 2025), <https://psyteachr.github.io/analysis-v4/07-independent.html> | CC BY 4.0 |
| Dawtry et al. (2015) | psyteachr *Fundamentals of Quantitative Analysis* ch.11 (Bartlett & Toivo, 2024), <https://psyteachr.github.io/quant-fun-v3/11-screening-data.html> | CC BY-SA 4.0 |
| Zhang et al. (2014) Study 3 | psyteachr *Analysis* ch.13 (Mahrholz & Kuepper-Tetzel, 2025), <https://psyteachr.github.io/analysis-v4/13-factorial-anova.html> | CC BY 4.0 |

The CC BY-SA 4.0 material (Dawtry) is shared under the same licence.

## Two traps in how variables are defined

Both were hit during testing. They are recorded here so the next person does not repeat them.

**How you compute `simon_effect` decides which numbers you get.** The figures printed in psyteachr
ch.7, `Levene F(1,158) = 0.73, p = .395` and `Welch t(157.14) = −0.92, p = .360`, come from the
**mean of two sessions**. The `.omv` files here use session 1 only
(`session1_incongruent − session1_congruent`) and therefore give `Levene F = 0.01, p = .922` and
`Student t(158) = −1.42, p = .159`. Both are correct. They are not the same quantity.

**How Levene's test centres its data causes a second gap.** Even after switching to the two-session
mean, jamovi prints `F = 0.67, p = .416` rather than 0.73. `car::leveneTest` defaults to
`center = median`, while jamovi's ttestIS uses `mean`.

**Row count of the Zhang data**: the file holds 152 rows and 35 columns, with `T2_Finished`
unfiltered, so the long format should have 304 rows. The n = 130 quoted in psyteachr is the count
after filtering, not the number of rows in the file. The two figures do not contradict each other:
`T2_Interest_Comp` has 22 missing values, and 152 - 22 = 130, so the 304 long-format rows hold 282
valid observations. The repeated-measures ANOVA drops the incomplete cases, which is why its
residual df is 128, that is 130 - 2 groups.

## A reply stored in an `.omv` is not necessarily the one that was run

While `submit` is ticked, jamovi re-runs the analysis whenever the file is opened or the data
change. askLLM then calls the API again and overwrites the reply already on screen. The English
`v2_fix` file went through three such samples, whose variable names were `id_col`, `time_cols` and
`id_var`, and the code preserved in `08 Rjp` belongs to one of them.

Unticking `submit` does not freeze the answer either. The guard at `askLLM/R/askllmr.b.R:58`
returns early and replaces the results area with guidance text, so the reply is gone.

**What follows for the records.** A `tested_with[].note` must state that its verdict rests on the
code pasted into Rj and the result of running it, not on whatever reply the `.omv` happens to
display. Save the full reply text somewhere else as well, in a worksheet or as a
`spot-the-error.qmd` item. The `.omv` alone does not preserve it.

For what it is worth, all three English samples satisfied the revised format rules. That is
evidence the prompt fix is robust rather than noise.

## Controlling the variable in a cross-check (recorded 2026-09-09)

Step three of the `check` list for `missing-data-triage` reads: ask the same question again under
the consultant persona, then compare the two lists of decisions handed back to the user. This is a
**single-variable comparison**. Everything except `role` has to stay the same.

The English pair satisfies that. Neither file sets `promptLang`, so both use the default `en`, and
only `role` differs.

The Chinese pair **did not satisfy it at first**. `_zhTW_explainer` did not set `promptLang`, so it
ran under the default `en`, while `_zhTW_consultant` set it to `zh`. That run varied the persona
and the prompt language at the same time. The explainer run was repeated with `promptLang = zh` on
2026-09-09 to correct it. The two files now differ only in `role`, and the question text has an
identical sha1, so the comparison holds.

How to verify this. Do not rely on what `index.html` displays; read the analysis payload directly:

```bash
unzip -o -q <file>.omv -d <directory>
strings "<directory>/NN askllm/analysis" | grep -oE 'promptLang = "[a-z]+"|role = "[a-z]+"'
```

A parameter that does not appear takes its default from `askllm.a.yaml`: `role` defaults to
`consultant` (line 95) and `promptLang` to `en` (line 105). **An absent parameter is still in
effect.** This is the easiest thing to misread here.
