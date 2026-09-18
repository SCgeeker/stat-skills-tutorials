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
| `describe-first-look_stroop_zhTW.omv` | `describe-first-look` | Chinese | askllm (explainer), descriptives with a histogram |
| `describe-first-look_stroop_en.omv` | `describe-first-look` | English | askllm (explainer), descriptives with two plots |
| `paired-vs-independent_stroop_zhTW.omv` | `paired-vs-independent` | Chinese | askllm, gamljmixed, ttestIS |
| `paired-vs-independent_stroop_en.omv` | `paired-vs-independent` | English | askllm, gamljmixed, ttestIS |
| `correlation-choice_lopez2024_zhTW.omv` | `correlation-choice` | Chinese | askllm, corrMatrix, scat |
| `correlation-choice_lopez2024_en.omv` | `correlation-choice` | English | askllm, corrMatrix, scat |
| `describe-code-crosscheck_stroop_zhTW.omv` | `describe-code-crosscheck` | Chinese | askllmr, Rj, descriptives (jamovi cross-check) |
| `describe-code-crosscheck_stroop_en.omv` | `describe-code-crosscheck` | English | askllmr, Rj, descriptives (jamovi cross-check) |
| `long-to-wide-check_stroop_zhTW.omv` | `long-to-wide-check` | Chinese | askllmr, Rj |
| `long-to-wide-check_stroop_en.omv` | `long-to-wide-check` | English | askllmr, Rj |
| `contingency-association_ballou2024_zhTW.omv` | `contingency-association` | Chinese | askllmr, Rj |
| `contingency-association_ballou2024_en.omv` | `contingency-association` | English | askllmr, Rj |
| `regression-code-check_payne2008_zhTW.omv` | `regression-code-check` | Chinese | askllmr, Rj |
| `regression-code-check_payne2008_en.omv` | `regression-code-check` | English | askllmr, Rj |
| `regression-predictors_payne2008_zhTW.omv` | `regression-predictors` | Chinese | askllm, linReg |
| `regression-predictors_payne2008_en.omv` | `regression-predictors` | English | askllm, linReg |
| `three-group-comparison_monin2008_zhTW.omv` | `three-group-comparison` | Chinese | askllm, anovaOneW |
| `three-group-comparison_monin2008_en.omv` | `three-group-comparison` | English | askllm, anovaOneW |

Tested on 2026-09-08 with provider `gemini` and model `gemini-flash-latest`. The Chinese explainer
run for `missing-data-triage` was repeated on 2026-09-09; the reason is in the last section.

The last six files are batch A, tested on 2026-09-16 with the same provider and model. None of
them sets `role` except the two `describe-first-look` runs, so the other four ran under the
default `consultant`. They carry no persona suffix because none of their `check` lists asks for a
persona cross-check.

The next eight files are batch B, tested on 2026-09-17 (`describe-code-crosscheck` on 2026-09-18)
with the same provider and model. `describe-code-crosscheck`, `contingency-association`, and
`regression-code-check` set `role: tutor`; `long-to-wide-check` does not, so it ran under the
default `consultant`. The last four files are batch C, tested on 2026-09-17. `regression-predictors`
sets `role: explainer`; `three-group-comparison` does not, so it ran under the default
`consultant`. None of these ten entries sets `promptLang` in its English run; every Chinese run
sets `promptLang: zh`.

## Reproducing these tests

Each entry's `prompt` carries `{placeholder}` fields. The values below are what the recorded runs
used, together with the dataset each one came from. The first three download links returned HTTP 200 on
2026-09-09, the next two on 2026-09-16, and the batch B/C links on 2026-09-17.

| Entry | Dataset | Download |
|---|---|---|
| `ttest-assumptions` | Zwaan et al. (2018) Simon task | <https://psyteachr.github.io/analysis-v4/data/data_ch7.zip> (use `MeansSimonTask.csv` after unzipping) |
| `missing-data-triage` | Dawtry et al. (2015) | <https://psyteachr.github.io/quant-fun-v3/data/Dawtry_2015_clean.csv> |
| `mixed-anova-setup` | Zhang et al. (2014) Study 3 | <https://psyteachr.github.io/analysis-v4/data/data_ch13.zip> (contains `Zhang_2014_Study3.csv` and a codebook) |
| `describe-first-look` | psyteachr Stroop demonstration data | <https://psyteachr.github.io/data-skills-v3/data/stroop/stroop_data.zip> (use `experiment_data.csv`, 540 rows in long format) |
| `paired-vs-independent` | the same Stroop data | as above; the `cross-check` step needs a wide layout, see below |
| `correlation-choice` | Lopez et al. (2024) soup-bowl study | <https://psyteachr.github.io/analysis-v4/data/data_ch9.zip> (use `data_ch9_correlation.csv`, 632 rows and 60 columns) |
| `describe-code-crosscheck` | the same Stroop data | as above; long format, split by `condition` |
| `long-to-wide-check` | the same Stroop data | as above; the recorded runs reshape it to wide themselves |
| `contingency-association` | Ballou et al. (2024) chi-square dataset | <https://psyteachr.github.io/analysis-v4/data/data_ch6.zip> (codebook only; the data itself is `data_ballou_reduced.csv`, 1083 rows) |
| `regression-code-check` | Payne et al. (2008), RP:P #44 replication data | <https://osf.io/rc6mv/> (`Dataset.Replication.study4.Payneetal.2008.JPSP.sav`, 180 rows) |
| `regression-predictors` | the same Payne et al. (2008) data | as above |
| `three-group-comparison` | Monin et al. (2008), RP:P #43 replication data | <https://osf.io/pz0my/> (75 rows; the file uses old-style Mac line endings, a bare CR with no LF) |

| Entry | Placeholder | Value |
|---|---|---|
| `ttest-assumptions` | `{outcome}` / `{group}` / `{n1}` / `{n2}` | `simon_effect` / `similarity` (same, different) / 80 / 80 |
| `missing-data-triage` | `{var_a}` / `{pct_a}` / `{var_b}` / `{pct_b}` | `Household_Income` / 1.3 / `Political_Preference` / 1.3 |
| `mixed-anova-setup` | `{id}` / `{group}` / `{t1}` / `{t2}` | `Participant_ID` / `Condition` / `T1_Pred_Interest_Comp` / `T2_Interest_Comp` |
| `describe-first-look` | `{outcome}` / `{group}` / `{k}` / `{id}` | `reaction_time` / `condition` / 2 / `participant_id` |
| `paired-vs-independent` | `{outcome}` / `{group}` / `{id}` | `reaction_time` / `condition` / `participant_id` |
| `correlation-choice` | `{var_a}` / `{var_b}` / `{n_a}` / `{n_b}` | `CalEstimate` / `OzEstimate` / 622 / 622 |
| `describe-code-crosscheck` | `{outcome}` / `{group}` / `{id}` | `reaction_time` / `condition` / `participant_id` |
| `long-to-wide-check` | `{outcome}` / `{group}` / `{id}` | `reaction_time` / `condition` / `participant_id` |
| `contingency-association` | `{var_a}` / `{var_b}` / `{n}` | `gender` / `eduLevel` / 1083 |
| `regression-code-check` | `{outcome}` / `{pred_a}` / `{pred_b}` / `{id}` | `direct` / `indirect` / `manip` / `subject` |
| `regression-predictors` | `{outcome}` / `{pred_a}` / `{pred_b}` / `{id}` / `{n}` | `direct` / `indirect` / `manip` / `subject` / 180 |
| `three-group-comparison` | `{outcome}` / `{group}` / `{k}` / `{g1}`/`{n1}` / `{g2}`/`{n2}` / `{g3}`/`{n3}` / `{n}` / `{scale_min}`-`{scale_max}` | `Intelligent` / `Condition` / 3 / `Obedient`/20 / `Rebel Affirmed`/27 / `Rebel Control`/28 / 75 / 1-7 |

Two things worth knowing before you read the numbers. `simon_effect` is not a column in the file;
the recorded runs computed it as `session1_incongruent - session1_congruent`, which is why the
figures differ from psyteachr's (see the traps section below). And jamovi's Descriptives panel
reports missing values as a count, not a percentage, so the 1.3% above is 4 out of 305.

## Data sources and licensing (important)

**These `.omv` files embed datasets from external teaching material.** Section 3 of this project's
`LICENSE` applies: third-party material keeps its own licence, and this project redistributes it
only under that licence, with the source named here.

| Data | Source | Licence |
|---|---|---|
| Zwaan et al. (2018) Simon task | psyteachr *Analysis* ch.7 (Mahrholz & Kuepper-Tetzel, 2025), <https://psyteachr.github.io/analysis-v4/07-independent.html> | CC BY 4.0 |
| Dawtry et al. (2015) | psyteachr *Fundamentals of Quantitative Analysis* ch.11 (Bartlett & Toivo, 2024), <https://psyteachr.github.io/quant-fun-v3/11-screening-data.html> | CC BY-SA 4.0 |
| Zhang et al. (2014) Study 3 | psyteachr *Analysis* ch.13 (Mahrholz & Kuepper-Tetzel, 2025), <https://psyteachr.github.io/analysis-v4/13-factorial-anova.html> | CC BY 4.0 |
| Stroop demonstration data | psyteachr *Data Skills for Reproducible Research* ch.2 (Nordmann & DeBruine, 2025), <https://psyteachr.github.io/data-skills-v3/stroop.html> | CC BY-SA 4.0 |
| Lopez et al. (2024) soup-bowl study | psyteachr *Analysis* ch.9 (Mahrholz & Kuepper-Tetzel, 2025), <https://psyteachr.github.io/analysis-v4/09-correlation.html> | CC BY 4.0 |
| Ballou et al. (2024) chi-square dataset | psyteachr *Analysis* ch.6 (Mahrholz & Kuepper-Tetzel, 2025), <https://psyteachr.github.io/analysis-v4/data/data_ch6.zip> | CC BY 4.0 |
| Payne et al. (2008) replication data | Reproducibility Project: Psychology, RP:P #44, <https://osf.io/rc6mv/> | CC0 1.0 |
| Monin et al. (2008) replication data | Reproducibility Project: Psychology, RP:P #43, <https://osf.io/pz0my/> | CC0 1.0 |

The CC BY-SA 4.0 material (Dawtry, and the Stroop data) is shared under the same licence. The two
RP:P replication datasets are **CC0 1.0**, a different licence from the CC BY and CC BY-SA material
above: CC0 places the data in the public domain, with no attribution requirement, so it is called
out separately here rather than folded into the CC BY-SA note.

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

## Four more pitfalls found in batch B/C testing

These surfaced while testing `describe-code-crosscheck`, `contingency-association`,
`regression-predictors`, and `three-group-comparison`. Each is recorded here so the next person
does not repeat it.

**jamovi's Descriptives quartiles are R's default `type = 7`, not `type = 6`.** With jamovi 28.2
bundling jmv 2.8.0, the Stroop congruent condition's 25th and 75th percentiles come out to 667.93
and 818.76. That matches `quantile(x, type = 7)` (667.9336, 818.764) and not `type = 6` (667.4837,
819.0694). Skewness and kurtosis are the sample-adjusted G1/G2 statistics that SPSS also reports. Both `describe-code-crosscheck`
replies, in Chinese and in English, told the user that jamovi uses `type = 6`; the cross-check step
caught it because all four quartiles (Q1 and Q3 for both conditions) failed to match.

**Rj does not surface R's `warning()`.** `chisq.test()` emits `Chi-squared approximation may be
incorrect` when an expected cell count is low, but that warning never appears in the Rj output pane.
In the `contingency-association` data, the expected-count table's smallest cell (Non-binary ×
Vocational or Similar) is 4.88, below the rule-of-thumb minimum of 5, and you can only catch that by
reading the printed `$expected` table yourself, not by waiting for a warning to show up.

**jamovi reads Payne's `subject` column as Nominal, not as a number.** Loading the `.sav` file, jamovi
sets `subject` to Nominal with 180 levels, and the summary askLLM sends the model describes it as "factor,
180 levels". If it were entered as a factor in a regression, it would consume all 180 degrees of
freedom.

**jamovi's Levene's test centres on the mean.** For the Monin et al. (2008) data, actually running
`three-group-comparison`'s One-Way ANOVA gives Levene's test **F = 0.00, p = .996**: the three
groups' variances are, for practical purposes, identical.

## A reply stored in an `.omv` is not necessarily the one that was run

While `submit` is ticked, jamovi re-runs the analysis whenever the file is opened or the data
change. askLLM then calls the API again and overwrites the reply already on screen. The English
`v2_fix` file went through three such samples, whose variable names were `id_col`, `time_cols` and
`id_var`, and the code preserved in `08 Rjp` belongs to one of them.

Unticking `submit` does not freeze the answer either. The guard at `askLLM/R/askllmr.b.R:58`
returns early and replaces the results area with guidance text, so the reply is gone.

**What follows for the records.** A `tested_with[].note` must state that its verdict rests on the
code pasted into Rj and the result of running it, not on whatever reply the `.omv` happens to
display.

The full reply text is therefore kept separately, in `data/replies/`. One Markdown file per `.omv`,
sharing its base name, holding the run's options, the question that was sent, and the reply
verbatim. Those files sit next to the `.omv` on purpose: they are part of the same evidence chain,
and anyone who later questions a verdict can read what the model actually said. A working document
would have been the wrong home, because working documents go stale and get retired.

Where a stored reply is known not to be the one that was executed, the file says so at the top.

For what it is worth, all three English samples satisfied the revised format rules. That is
evidence the prompt fix is robust rather than noise.

## A menu path can depend on which modules you have installed

Both `paired-vs-independent` runs noted that jamovi's built-in paired t-test wants a wide layout,
and offered `Analyses > Linear Models > GAMLj3 > Linear Mixed Model` for the long layout instead.
That path is exact: `GAMLj3/jamovi.yaml` gives `menuGroup: Linear Models`,
`menuSubgroup: GAMLj3` and `menuTitle: Linear Mixed Model`.

The model did not know this. askLLM's `includeCatalog` option defaults to `true`, so the request
carried a list of the modules installed on this machine. **Ask the same question on a machine
without GAMLj3 and that path will not come back.** A menu path in a reply is therefore evidence
about one installation, not about jamovi in general, which is why every `check` list opens with a
step that makes you click the path yourself.

Running that mixed model is also what verified the advice. It returns `t(269) = 13.50`, the same
value as the paired t-test on the wide layout, `t(269) = -13.50`, differing only in the direction
of the contrast. Treating the same data as two independent groups gives Welch `t(495.76) = -13.72`,
still `p < .001`. The wrong choice is not caught by the p value.

### Reshaping the Stroop data for that cross-check

`experiment_data.csv` is long, 540 rows with two per participant. jamovi's Paired Samples T-Test
needs one row per participant, so the recorded runs reshaped it in Rj:

```r
wide <- reshape(data, idvar = "participant_id", timevar = "condition",
                v.names = "reaction_time", direction = "wide")
```

This yields 270 rows and three columns, with 270 complete cases.

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
