# G6 CPI / Integration Freeze Plan

Draft and provisional. This plan is for downstream planning only until G4 Part 2 and G5 evidence are available. It does not implement MATLAB code, does not supersede `ProjectPlan.md`, and does not authorize G6 to perform CFAR detection or truth alignment.

## Status And Purpose

G6 freezes the detector input product definition after upstream map and mitigation evidence are stable enough to support a fixed downstream product. It owns CPI length, overlap, integration type, outlier rejection, weighting, registration rules, axes, units, map-rate identity, provenance, and timestamp convention.

G6 must not accept a single `RecommendedBaselineCpiLabel` without checking G4 caveats, scene labels, raw-rate audit status, axis plausibility, repeatability, and G5 mitigation status.

## Current Downstream Diagnostic Status

Current implementation is blocked/deferred freeze scaffolding only. On dataset `20260622T102123`, G6 must refuse normal detector-product freeze because the latest complete G4 evidence is `blocked` with `dataset_scene_limited_with_raw_rate_audit_disagreement`, and G5 remains diagnostic-only with `blocked_by_g4` formal posture.

The executable scaffold is `runG6CpiIntegrationFreeze`. It consumes the latest complete G4/G5/G5-diagnostic bundles, writes a G6 evidence bundle, records `FreezeStatus = freeze_deferred`, and sets `DetectorProductFreezeEnabled = false`. It does not tune CFAR, perform truth alignment, change G4/G5 semantics, or promote the current dataset beyond diagnostic negative-control evidence.
## Native Function Discovery

| Proposed Workflow | Native MATLAB Documentation Example Analogue | Updates needed to fit current goal |
| :--- | :--- | :--- |
| CPI and overlap freeze from G4/G5 evidence | MATLAB table-based parameter study workflows; `ambgfun` passive map evidence from G4 | Consume G4/G5 summaries without re-owning passive-map formation or mitigation selection |
| Single-look versus noncoherent integration comparison | Matrix aggregation and table summary workflows using `mean`, `sum`, `groupsummary`, `findgroups` | Apply only to detector input products; report integration gain, variance, contribution count, and outlier behavior |
| Coherent integration eligibility review | Phase stability checks using native complex arithmetic, `angle`, `unwrap`, `mean`, `std` | Allow coherent integration only when G3/G4 phase and registration evidence justify it explicitly |
| Map registration stability review | Native correlation/registration workflows using `xcorr2`, `normxcorr2`, `imregcorr` where toolbox availability supports it | Use only to confirm freeze suitability; if registration rules or axes change materially, reopen G4 or earlier |
| Evidence bundle production | MATLAB `table`, `writetable`, `jsonencode`, `save`, figure export workflows | Emit G6-specific freeze record, metrics, decision note, figures, and reopen/retune rationale |
| Manual review surface | MATLAB Live Editor sections with `figure`, `tiledlayout`, `nexttile`, table display | Present freeze evidence compactly without running CFAR or downstream truth validation |

| Proposed Feature / Algorithm | Native MATLAB Function/Toolbox Equivalent | Documentation Syntax Template Used |
| :--- | :--- | :--- |
| Grouped CPI/overlap summaries | `groupsummary`, `findgroups`, `splitapply`, `table` | `summaryTable = groupsummary(metricsTable, groupVars, "median", dataVars)` |
| Noncoherent integration | `sum`, `mean`, `median`, `omitnan` options | `integratedMap = sum(abs(mapStack).^2, dimension)` |
| Coherent integration eligibility | `angle`, `unwrap`, `std`, `mean`, complex `sum` | `phaseStd = std(unwrap(angle(complexSamples)), 0, dimension)` |
| Registration consistency | `xcorr2`, `normxcorr2`, optional `imregcorr` | `correlationSurface = xcorr2(referenceMap, candidateMap)` |
| Outlier rejection | `isoutlier`, `rmoutliers`, `median`, `mad` | `outlierMask = isoutlier(metricValues, "median")` |
| Peak smearing metrics | `max`, `find`, `regionprops` when Image Processing Toolbox is available | `[peakValue, peakIndex] = max(mapPower(:))` |
| Bin-spacing and axis reporting | Native vector arithmetic, `diff`, `median` | `delayBinSpacing = median(diff(delayAxis))` |
| Evidence serialization | `save`, `writetable`, `jsonencode`, `fprintf` | `save(metricsMatPath, "metricsStruct")` |
| Required plots | `figure`, `tiledlayout`, `nexttile`, `imagesc`, `plot`, `xlabel`, `ylabel`, `title` | `figure; tiledlayout(2, 2); nexttile; imagesc(...)` |

All future MATLAB implementation must use these native functions where applicable. If registration or integration needs exceed native tooling, the implementation must first document why the built-in function is insufficient.

## Firm Requirements

Firm requirements from `ProjectPlan.md`, `docs/checkpoints/G6_CPI_Integration.md`, and `docs/requirements/RequirementsMatrix.md`:

- G6 follows G5 and precedes G7/G8 in downstream product stabilization.
- G6 owns `MAP-004` and `DET-001`: CPI/integration registration freeze and detector input product definition.
- G6 may retune only CPI length, overlap, integration type, outlier rejection, weighting, and registration choices.
- Any change that redefines delay or Doppler axes, map registration, timing segmentation, or upstream map semantics reopens G4 or earlier as appropriate.
- G8 may not begin if G6 cannot stabilize the detector input product.
- G6 does not perform CFAR detection, truth alignment, detection scoring, tracking readiness, or customer-facing claim validation.

## Provisional G4 And G5 Assumptions

G4 Part 2 is provisional. G6 must consume G4 only through stable documented outputs and must check caveats before freezing products.

Shared provisional G4 helper call:

```matlab
analysis = helperAnalyzeG4PassiveBaselineMap(sessionData, collectionMetadataInfo, g3SyncResults, options)
```

Possible G4 fields:

- `MapSummaryTable`
- `RepeatabilityTable`
- `CpiSelectionTable`
- `QuestionSummaries`
- `Interpretation`
- `RecommendedBaselineCpiLabel`
- `RepresentativeMaps`
- `RawAxisRepresentativeMaps`
- `FullRateAuditSummaryTable`
- `BaselineProductDefinition`

G6 must treat these G4 conditions as follows:

| G4 Condition | G6 Planning Response |
| :--- | :--- |
| `ready` with complete schema and no blocking audit caveats | Eligible for normal freeze consideration |
| `caveated` | Eligible only with caveats preserved in the frozen product record |
| `scene_limited_direct_path_dominated` | Diagnostic freeze or manual review only; not an ordinary detector baseline |
| `implementation_suspect` | Block freeze and reopen G4 or earlier |
| raw-rate audit `disagreement` affecting selected CPI or map product | Block pass until resolved or choose unaffected candidate with explicit rationale |
| `blocked` | Do not freeze detector input product |

G5 is also provisional. G6 consumes only the selected mitigation posture and evidence record from G5; it does not choose LMS parameters.

## Gate Ownership

G6 owns:

- final detector-facing CPI label and duration
- overlap fraction or overlap rule
- single-look versus noncoherent integration rule
- coherent integration eligibility decision if considered
- weighting and outlier rejection rules
- map registration rule and allowed registration tolerances
- frozen product schema, axes, units, map-rate mode, provenance, and timestamp convention
- reopen rules when G4/G5 product registration or semantics change

G6 consumes:

- G4 passive baseline map evidence
- G5 mitigation decision: no mitigation, conservative LMS, aggressive LMS, or mitigation deferred
- G1/G3 timing and segmentation contracts as inherited evidence

G6 does not own:

- G4 map plausibility or raw-rate audit correction
- G5 mitigation tuning
- G7 truth overlap and association windows
- G8 CFAR settings or detection metrics
- G9/G10 tracking contracts

## Input Contract

| Input | Required G6 Use | Reject Or Block Condition |
| :--- | :--- | :--- |
| G4 `Interpretation` and `QuestionSummaries` | Establish whether baseline maps are usable for freeze | `blocked`, `implementation_suspect`, or unresolved raw-rate audit disagreement blocks freeze |
| G4 `MapSummaryTable` | Evaluate scene label distribution, axes, direct-path location, off-origin content, and map-rate identity | Missing axis units, mixed-rate ambiguity, or dominant implementation-suspect labels block freeze |
| G4 `RepeatabilityTable` | Compare repeatability across CPI candidates and windows | Unstable repeatability without explainable cause forces retune or reject |
| G4 `CpiSelectionTable` | Seed CPI candidates but not blindly accept final CPI | Missing caveat/audit columns or scene-limited top CPI requires manual review |
| G4 `FullRateAuditSummaryTable` | Confirm reduced-rate conclusions are not misleading | Any selected-product `disagreement` blocks normal pass |
| G4 `RepresentativeMaps` and `RawAxisRepresentativeMaps` | Manual check of display axes and physical raw axes | Display-only evidence is insufficient |
| G5 mitigation output | Select product family to freeze | Unresolved G5 decision, protected-energy loss, or incomparable CPI evidence blocks freeze |
| G1/G3 timing and segmentation metadata | Preserve time/CPI provenance and product timestamps | Segmentation or timing contract change reopens upstream |

## Output Contract

Future G6 result struct fields:

| Field | Required Content |
| :--- | :--- |
| `GateDecision` | Formal `pass`, `retune`, or `reject` |
| `ReviewStatus` | `ready_for_gate_decision`, `manual_review_required`, or `blocked_by_upstream` |
| `FrozenProductDefinition` | Dataset ID, upstream bundle IDs, mitigation posture, CPI duration, overlap, integration type, weighting, outlier rule, registration rule, axes, units, map-rate mode, and timestamp convention |
| `CpiIntegrationSelectionTable` | Candidate CPI/overlap/integration rows with repeatability, integration gain, peak smearing, outlier rate, contribution count, caveats, and decision label |
| `RegistrationFreezeTable` | Delay/Doppler bin spacing, axis origin rule, registration offsets, allowed tolerances, and reopen triggers |
| `IntegrationEvidenceTable` | Single-look and integrated product summaries: gain, variance reduction, smearing, false-alarm-risk proxy, and retained scene metric |
| `ProductProvenanceTable` | Source G4/G5 evidence IDs, map labels used, raw-rate audit labels, mitigation label, and product hash or config ID |
| `DecisionSummary` | Human-readable rationale and next branch |
| `EvidenceBundleRoot` | Standard evidence bundle root when a future runner writes artifacts |

## Evidence Package

G6 must follow `docs/testing/EvidenceBundleSpec.md`:

- `summary.md`
- `requirements_coverage.csv`
- `config_snapshot.json`
- `metrics.json`
- `metrics.mat`
- `timing_summary.csv`
- `performance_summary.json`
- `decision.txt`
- `failure_cause.txt` when the decision is not `pass`
- `next_branch.txt`
- `figures/`

## Runner Performance Instrumentation Requirement

The future G6 runner must implement the same timing/performance contract used by the G1-G3 runners.

- Return `results.TimingSummaryTable` and `results.PerformanceSummary`.
- Write `timing_summary.csv` and `performance_summary.json` into each successful evidence bundle.
- Append `timingSummaryTable` and `performanceSummary` to `metrics.mat`.
- Use the common timing table schema: `StageId`, `StepName`, `Elapsed_s`, `ExecutionMode`, `InputSampleCount`, `InputRepetitionCount`, `OutputArtifactCount`, `OutputFigureCount`, `OutputBytes`, and `Notes`.
- Default `ExecutionMode` is `"review"`; accept and report `"analysis_only"` and `"profile"` where runner options exist.
- Do not add arbitrary runtime pass/fail thresholds. Timing is observability evidence unless a later requirements document defines explicit performance gates.

Required G6 figures:

- `figure_01_bin_spacing.png`: CPI versus delay/Doppler bin-spacing summary.
- `figure_02_integration_gain.png`: single-look versus integration-gain comparison.
- `figure_03_peak_smearing.png`: peak width/location stability by candidate.
- `figure_04_outlier_contribution.png`: contribution counts and rejected-look statistics.
- `figure_05_frozen_product_preview.png`: representative frozen detector input product, not CFAR output.

Every future figure must explicitly call `figure`, use `tiledlayout` and `nexttile` for multi-panel reporting, and include `xlabel`, `ylabel`, and `title`.

## Decision Semantics

| Formal Decision | Meaning | Next Branch |
| :--- | :--- | :--- |
| `pass` | Detector input product is frozen with stable CPI, overlap, integration, registration, and provenance | Open G8 detector tuning, subject to G7 truth-alignment dependency for stable validation claims |
| `retune` | Product is close, but G6-local knobs need adjustment | Retune CPI, overlap, integration type, weighting, outlier rejection, or registration tolerance only |
| `reject` | No detector input product can be responsibly frozen from current G4/G5 evidence | Stop downstream detector work or reopen earliest affected upstream gate |

`manual_review_required` is a review status, not a formal gate decision. It applies when evidence is internally mixed, usually because of G4 caveats, scene-limited maps, unresolved G5 mitigation, or raw-rate audit ambiguity.

## Retune And Reopen Rules

G6-local retune may change:

- CPI duration
- overlap fraction
- number of looks
- single-look versus noncoherent integration
- coherent integration eligibility choice
- weighting rule
- outlier rejection rule
- fixed registration tolerance

Reopen upstream if:

- selected product requires different map axes or bin definitions: reopen G4
- reduced-rate versus raw-rate disagreement affects selected product: reopen G4
- mitigation changes protected regions or map semantics: reopen G5, then rerun G6
- CPI segmentation or timing changes: reopen G1/G3 as applicable
- synchronization strategy changes to make integration possible: reopen G3
- detector failures in G8 imply moving input-product definitions: reopen G6, not CFAR-only retune

## Edge Cases And Failure Modes

| Case | G6 Handling |
| :--- | :--- |
| G4 recommends a CPI but top map label is `scene_limited_direct_path_dominated` | Require manual review; do not freeze as normal detector baseline automatically |
| G4 raw-rate audit has `disagreement` for selected CPI | Block pass; reopen G4 or choose an unaffected candidate with explicit rationale |
| G5 selects mitigation that improves plots but harms protected energy | Do not freeze mitigated product; retain no-mitigation baseline or reopen G5 |
| Longer CPI improves gain but smears peaks | Prefer shorter or moderate CPI unless smearing is bounded and explainable |
| Overlap improves density but creates correlated false-alarm risk proxy | Freeze lower overlap or document correlation penalty |
| Coherent integration improves gain but phase stability is not proven | Disallow coherent integration; use single-look or noncoherent integration |
| Registration offsets vary by repetition | Retune registration/overlap or reject freeze if offsets are not stable |
| G4 field schema changes during Part 2 | Treat G6 as blocked until input contract is reconciled |
| Truth alignment not yet available | G6 can freeze detector input product, but cannot enable truth-correlated detector acceptance claims |

## Test Plan

Unit tests:

- Validate CPI/overlap candidate table schema, units, bin spacing, contribution counts, and frozen product struct fields.
- Confirm `RecommendedBaselineCpiLabel` alone is insufficient when caveats or raw-rate audit disagreement exist.
- Validate `pass`, `retune`, `reject`, and manual-review status mapping from controlled synthetic tables.

Integration tests:

- Run G6 on a fixed G4/G5 fixture and confirm evidence bundle completeness.
- Confirm G6 blocks on missing or unresolved `FullRateAuditSummaryTable` when selected product depends on reduced-rate evidence.
- Confirm scene-limited G4 evidence cannot produce ordinary `pass` without manual-review flag.

Regression and tuning tests:

- Rerun G6 after any G4 registration or G5 mitigation product change and confirm downstream freeze record changes intentionally.
- Keep CPI/overlap/integration exploration as `Tuning`; only promoted freeze configs become CI-gated.

## Open Decisions Blocked On Upstream Outputs

- Exact final G6 candidate CPI set, blocked until G4 Part 2 stabilizes `CpiSelectionTable`, caveat semantics, and raw-rate audit tolerances.
- Whether G6 freezes no mitigation or a G5-selected mitigation product.
- Coherent integration eligibility, blocked unless G3/G4 provide sufficient phase stability and registration evidence.
- Final `BaselineProductDefinition` schema.
- Normal detector-facing freeze, blocked if G4 remains `blocked`, implementation-suspect, or raw-rate-audit-disagreed.
- Final detector product timestamp convention, which G7 will consume.

## Out Of Scope

- CFAR threshold tuning and detection scoring belong to G8.
- Truth overlap, ADS-B timing reconciliation, and validation windows belong to G7.
- Detection record schema for tracker consumption belongs to G8/G9.
- Tracking, `trackerGNN`, and truth-correlated track metrics belong to G9/G10.
- Replacing `ambgfun` with `phased.RangeDopplerResponse` remains later equivalence or optimization work, not G6 freeze work.
