# Lessons Learned

## LL-001 — 2026-07-31 — Repeatability Is Not Scene Readiness

- Attempt or hypothesis: Use the G4 passive baseline study to establish a credible, repeatable detector-input map.
- Observed result: Helper execution, direct-path localization, and repeatability were ready, but every reviewed map remained scene-limited and the nine-row raw/reduced-rate audit disagreed.
- Lesson: A stable direct-path-dominated map does not by itself establish useful off-origin scene observability.
- Resulting action: Keep downstream mitigation and detector work diagnostic; see [D-001](DECISIONS.md#d-001--g5-is-characterized-but-not-selected).
- Evidence: [G4 metrics](artifacts/20260622T102123/G4_Passive_Baseline_Map/20260731T182401Z/metrics.mat).

## LL-002 — 2026-08-06 — Suppression Alone Does Not Establish Detection Utility

- Attempt or hypothesis: Compare no mitigation with conservative and aggressive LMS, then probe whether direct-path suppression reveals scene content.
- Observed result: The formal G5 slice was blocked by G4. The diagnostic sweep achieved about 4.2 dB direct-path suppression for the leading profile, but its best causal label remained `visual_only_improvement`.
- Lesson: Cleaner maps and direct-path suppression are insufficient evidence that target detection improves.
- Resulting action: Require target/control discrimination evidence before product selection; see [D-002](DECISIONS.md#d-002--measure-detector-behavior-before-deciding-whether-to-retune-g5).
- Evidence: [G5 mitigation metrics](artifacts/20260622T102123/G5_Mitigation/20260806T201621Z/metrics.mat) and [G5 diagnostic metrics](artifacts/20260622T102123/G5_Mitigation_Diagnostic/20260806T213800Z/metrics.mat).

## LL-003 — 2026-08-10 — Synthetic Recovery Is Useful but Sensitivity-Dependent

- Attempt or hypothesis: Inject known targets into a real background and verify map localization before broader mitigation comparison.
- Observed result: Easy, medium, and multi-target cases passed; marginal and hard cases were warning-level; the real-only control passed its control criteria.
- Lesson: The map path can recover and localize injected targets, but the result is diagnostic and varies with target difficulty.
- Resulting action: Expand to multiple RF backgrounds and geometries without promoting the formal gates.
- Evidence: [easy-case metrics](artifacts/g4_5_real_background_20260807T162306840/easy_single_target/G4_5_SyntheticTargetRecovery/20260810T133148Z/metrics.mat), [hard-case metrics](artifacts/g4_5_real_background_20260807T162306840/hard_single_target/G4_5_SyntheticTargetRecovery/20260810T133148Z/metrics.mat), [multi-target metrics](artifacts/g4_5_real_background_20260807T162306840/multi_target/G4_5_SyntheticTargetRecovery/20260810T133148Z/metrics.mat), and [control metrics](artifacts/g4_5_real_background_20260807T162306840/real_only_control/G4_5_SyntheticTargetRecovery/20260810T133148Z/metrics.mat).

## LL-004 — 2026-09-01 — G5 Behavior Depends on RF Background

- Attempt or hypothesis: Test the three fixed G5 products across a preregistered 72-case, three-background ADS-B-derived campaign.
- Observed result: All 72 cases and 648 maps passed integrity checks, but neither LMS profile was consistently supported across backgrounds; the result was `mixed_requires_retune`.
- Lesson: A small or pooled map-level improvement can hide background-specific regressions and cannot establish detection benefit.
- Resulting action: Run fixed-CFAR product discrimination before deciding whether to retune G5; see [D-002](DECISIONS.md#d-002--measure-detector-behavior-before-deciding-whether-to-retune-g5).
- Evidence: [G5 stress result](artifacts/g5_adsb_stress_20260901T141707747/G5_Synthetic_Stress/20260901T154549472Z/stressResults.mat) and [campaign explanation](G5_Campaign_ELI5.md).

## LL-005 — 2026-08-07 — Downstream Refusal Guards Are Working

- Attempt or hypothesis: Exercise the G6 and G8 scaffolds against the current blocked/caveated upstream evidence.
- Observed result: G6 emitted `freeze_deferred` with detector-product freeze disabled; G8 refused execution with CFAR and detector tuning disabled and emitted no detection table.
- Lesson: Downstream gate code currently fails safely when formal prerequisites are absent.
- Resulting action: Preserve those semantics during G6-D; see [D-004](DECISIONS.md#d-004--g6-d-cannot-enable-formal-g6-or-g8).
- Evidence: [G6 metrics](artifacts/20260622T102123/G6_CPI_Integration_Freeze/20260807T124003Z/metrics.mat), [G8 metrics](artifacts/20260622T102123/G8_Detection_Prerequisite_Gate/20260807T124005Z/metrics.mat), and [downstream status](docs/downstream/G6_G8_Status.md).
