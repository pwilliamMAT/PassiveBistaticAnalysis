# G5 Mitigation Plan

Draft and provisional. This plan is for downstream planning only until G4 Part 2 is implemented and manually reviewed. It does not implement MATLAB code, does not supersede `ProjectPlan.md`, and does not authorize mitigation work to hide G4 limitations.

## Status And Purpose

G5 owns mitigation comparison after a credible G4 passive baseline exists. The gate compares no mitigation, conservative LMS, and aggressive LMS against the same upstream map contract and decides whether to select a mitigation posture, retain no mitigation, retune G5-local mitigation knobs, or reject mitigation for the current evidence set.

The plan is intentionally conservative. A direct-path-dominated or raw-rate-disagreed G4 result can support diagnostic comparison only; it cannot become a normal mitigation success by producing cleaner plots.
## Current G4 Reality Check For G5

The current G4 manual-review runner can execute successfully while returning `OverallLabel = "blocked"` for the baseline dataset. In the observed baseline run, G4 showed:

- stable direct-path localization at the ambiguity-map origin
- highly repeatable representative maps across CPI and window choices
- `RawDirectPathDelayOffset_samples = 0` and `RawDirectPathDopplerOffset_Hz = 0` across the reviewed center-window repetitions
- scene-first metrics blocked because off-origin occupied structure remains weak relative to the direct path
- bounded raw-rate audit disagreement between raw-rate cut proxies and the reduced-rate map product

This is a valid G4 outcome and should be interpreted as dataset / RF scene limitation or rate-preservation caveat, not as a G4 helper execution failure.

G5 therefore has a diagnostic question before it has a normal gate-success question:

> Can mitigation reveal useful off-origin scene content that is already present in the recorded samples but hidden by direct-path leakage?

The answer may be no. Digital mitigation can suppress direct path or leakage that is present in the samples, but it cannot recover scene energy that the surveillance channel did not capture, energy lost to front-end compression, or returns that are below the recorded noise floor. A G5 implementation must preserve this distinction in its metrics, labels, and rationale strings.

Expected interpretation branches:

| G5 Observation | Interpretation |
| :--- | :--- |
| Direct-path peak drops, off-origin occupied fraction increases, and protected nonzero-Doppler structure is retained | Mitigation may be revealing hidden scene content; allow caveated/manual review and candidate comparison |
| Direct-path peak drops, but off-origin occupied fraction remains near zero and maps remain scene-empty | Mitigation cleaned leakage but did not recover useful scene evidence; treat as dataset/RF-limited |
| Direct-path peak drops while nonzero-Doppler energy or protected regions are also suppressed | Candidate is over-cancelling; retune or reject the mitigation profile |
| Maps look visually cleaner but detectability proxies do not improve | Do not count this as mitigation success |
| The raw-rate/reduced-rate disagreement worsens after mitigation | Treat candidate evidence as implementation/rate-caveated until explained |

Hardware and RF implications should remain visible in the G5 output. If mitigation cannot reveal scene content, the likely next action is not threshold relaxation; it is improved acquisition: better reference/surveillance antenna role separation, surveillance direct-path rejection, antenna isolation, gain staging, front-end linearity, illuminator geometry, and collection geometry.

## Native Function Discovery

| Proposed Workflow | Native MATLAB Documentation Example Analogue | Updates needed to fit current goal |
| :--- | :--- | :--- |
| Compare no mitigation, conservative LMS, and aggressive LMS on a credible passive baseline | Adaptive noise cancellation using `dsp.LMSFilter`; passive-map formation with `ambgfun` | Use G4-produced baseline map products as the comparison reference; report mitigation impact without changing G4 or G6 ownership |
| Adaptive direct-path and clutter cancellation before map formation | `dsp.LMSFilter` adaptive filtering workflow | Treat `dsp.LMSFilter` as a candidate baseline only; document reference input, filter length, step size, leakage, and adaptation span |
| Protected-region energy retention review | MATLAB table workflows plus masked energy summaries | Define protected nonzero-Doppler or reviewable-scene regions from G4 outputs; truth-window protection remains unavailable unless G7 later provides it |
| Mitigation evidence bundle generation | Gate evidence structure in `docs/testing/EvidenceBundleSpec.md` | Emit G5-specific metrics, figures, decisions, and branch files under the standard artifact convention |
| Manual comparison review before downstream freeze | MATLAB Live Editor/helper-result review surface | Provide tables and figures sufficient for manual pass, retune, or reject without freezing CPI or detector policy |

| Proposed Feature / Algorithm | Native MATLAB Function/Toolbox Equivalent | Documentation Syntax Template Used |
| :--- | :--- | :--- |
| LMS adaptive mitigation | `dsp.LMSFilter` from DSP System Toolbox | `[y, e, w] = lms(x, d)` |
| Leakage-capable LMS candidate | `dsp.LMSFilter` properties available in the installed MATLAB release | `lms = dsp.LMSFilter(...)` |
| Passive map recomputation after mitigation | `ambgfun` | `[afmag, delay, doppler] = ambgfun(x, y, Fs, PRF)` |
| Linear and dB energy summaries | `sum`, `mean`, `median`, `mag2db`, logical masks | `levelDb = mag2db(signalPower / referencePower)` |
| Comparison tables | `table`, `groupsummary`, `sortrows`, `rowfun` where useful | `summaryTable = groupsummary(metricTable, groupVars, method, dataVars)` |
| Review figures | `figure`, `tiledlayout`, `nexttile`, `imagesc`, `plot` | `figure; tiledlayout(...); nexttile; imagesc(...)` |
| Artifact serialization | `save`, `jsonencode`, `writetable`, `fprintf` | `save(fileName, "metrics")` |

All future MATLAB implementation must prefer the native functions above. If `dsp.LMSFilter` cannot express a needed leakage or adaptation option in the installed release, the implementation must document the limitation before adding custom adaptive-filter math.

## Firm Requirements

Firm requirements from `ProjectPlan.md`, `docs/checkpoints/G5_Mitigation.md`, and `docs/requirements/RequirementsMatrix.md`:

- G5 follows G4 and precedes G6.
- G5 owns `MIT-001`, `MIT-002`, and `MIT-003`: mitigation candidate comparison, protected useful-energy retention, and downstream detectability benefit evidence.
- The minimum comparison set is no mitigation, conservative LMS, and aggressive LMS.
- `dsp.LMSFilter` is a candidate baseline, not a final program commitment.
- Every formal G5 gate outcome is `pass`, `retune`, or `reject`.
- G5 may pass by selecting a mitigation candidate or by explicitly retaining the no-mitigation baseline when neither LMS variant improves the evidence.
- Retuning stays inside G5 knobs: reference input choice, filter length, step size, leakage, protected-region definition, and adaptation span relative to CPI.

## Provisional G4 Assumptions

G4 Part 2 is being implemented in parallel and remains provisional. G5 must consume G4 only through stable documented outputs.

Shared provisional helper call:

```matlab
analysis = helperAnalyzeG4PassiveBaselineMap(sessionData, collectionMetadataInfo, g3SyncResults, options)
```

Expected G4 fields may include:

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

G5 must handle these G4 states explicitly:

| G4 Condition | G5 Planning Response |
| :--- | :--- |
| `ready` with no blocking caveats | Allow formal G5 comparison if required fields are present |
| `caveated` | Allow comparison only with caveats carried into G5 outputs and evidence |
| `scene_limited_direct_path_dominated` | Diagnostic or manual-review comparison only; no normal mitigation pass without human acceptance |
| `implementation_suspect` | Block G5 and reopen G4 or earlier as appropriate |
| raw-rate audit disagreement affecting the candidate product | Block normal G5 pass until G4 resolves the disagreement or excludes the affected product |
| `blocked` | Do not run G5 as a formal gate |

## Gate Ownership

G5 owns:

- Candidate comparison across `none`, `conservative_lms`, and `aggressive_lms`.
- Mitigation parameter documentation.
- Before/after map and energy summaries.
- Protected-region energy retention.
- Decision logic for selecting LMS, retaining no mitigation, retuning mitigation knobs, or rejecting the mitigation comparison.

G5 does not own:

- G4 passive-baseline credibility.
- Final CPI length, overlap, map registration, or integration freeze.
- Truth alignment or truth-window definitions.
- CFAR threshold tuning or detector acceptance.
- Tracking readiness or customer-facing truth-correlated claims.

## Input Contract

Future G5 helper or runner inputs:

| Input | Required Content | Block Condition |
| :--- | :--- | :--- |
| `sessionData` | Manifest-driven IQ and metadata from G1 | Missing decode, timing, or CPI segmentation contract |
| `collectionMetadataInfo` | Acquisition metadata and sidecar context used upstream | Missing only blocks fields that require acquisition context |
| `g3SyncResults` | Frozen G3 correction contract used by G4 | Missing or non-qualifying G3 status |
| `g4Analysis` | Credible G4 baseline analysis output | Blocked, implementation-suspect, or schema-incomplete G4 output |
| `options` | Mitigation profiles, protected-region policy, evidence options, figure visibility | Missing required profile fields or invalid candidate set |

Minimum G4 fields for a formal G5 comparison:

- `Interpretation`
- `MapSummaryTable`
- `CpiSelectionTable`
- `BaselineProductDefinition`
- `RecommendedBaselineCpiLabel` or another explicitly documented baseline CPI candidate
- representative maps or enough source metadata to recompute the same map product
- raw-rate audit status when the selected product depends on reduced-rate conclusions

## Output Contract

Future G5 result struct fields:

| Field | Required Content |
| :--- | :--- |
| `GateDecision` | Formal `pass`, `retune`, or `reject` |
| `ReviewStatus` | `ready_for_gate_decision`, `manual_review_required`, or `blocked_by_upstream` |
| `DecisionLabel` | `select_no_mitigation`, `select_conservative_lms`, `select_aggressive_lms`, `retune_mitigation`, `reject_mitigation_comparison`, or `blocked_by_g4` |
| `MitigationCandidateTable` | One row per candidate posture with all profile parameters and eligibility labels |
| `MitigationMetricTable` | Per-repetition, per-window, per-CPI metrics for each candidate |
| `ProtectedRegionRetentionTable` | Protected energy retention by candidate and protected-region definition |
| `SuppressionSummaryTable` | Direct-path, zero-Doppler, clutter-floor, and residual-error summaries |
| `ResidualErrorPowerTable` | Residual error power by candidate, repetition, and CPI/window label |
| `DetectabilityProxyTable` | Detector-independent contrast, floor, and protected-region metrics; no CFAR thresholds |
| `MitigationCausalAssessmentTable` | Per-candidate cause/effect labels distinguishing `scene_revealed`, `leakage_cleaned_scene_still_limited`, `over_cancelled_scene`, `visual_only_improvement`, and `rate_caveated` |
| `AcquisitionImplicationTable` | Human-readable RF/acquisition implications when mitigation cannot reveal scene content, including antenna role separation, direct-path rejection, isolation, gain staging, front-end linearity, illuminator geometry, and collection geometry |
| `DecisionComparisonTable` | Candidate ranking and rationale |
| `UpstreamCaveatsCarriedForward` | G2, G3, and G4 caveats preserved for downstream gates |
| `EvidenceBundleRoot` | Standard evidence bundle root when a future runner writes artifacts |

## Candidate Profiles

Minimum candidate set:

| Candidate | Intent | Required Documentation |
| :--- | :--- | :--- |
| `none` | Baseline with no mitigation | Source G4 product, map-rate mode, CPI/window labels, protected-region policy |
| `conservative_lms` | Lower-risk adaptive cancellation | Reference input choice, desired/surveillance input, filter length, step size, leakage setting or unavailable note, adaptation span, initialization policy |
| `aggressive_lms` | Higher-suppression candidate with stricter failure checks | Same fields as conservative LMS plus explicit protected-energy risk controls |

The implementation must not silently add extra candidates to the formal comparison without also recording them as exploratory or tuning artifacts.

## Evidence Package

G5 must follow `docs/testing/EvidenceBundleSpec.md`:

- `summary.md`
- `requirements_coverage.csv`
- `config_snapshot.json`
- `metrics.json`
- `metrics.mat`
- `decision.txt`
- `failure_cause.txt` when the decision is not `pass`
- `next_branch.txt`
- `figures/`

Required G5 tables:

- `MitigationCandidateTable`
- `SuppressionSummaryTable`
- `ProtectedRegionRetentionTable`
- `ResidualErrorPowerTable`
- `DetectabilityProxyTable`
- `MitigationCausalAssessmentTable`
- `AcquisitionImplicationTable`
- `DecisionComparisonTable`
- `RequirementsCoverageTable`

Required G5 figures:

- Before/after representative maps for no mitigation, conservative LMS, and aggressive LMS.
- Zero-Doppler/direct-path suppression comparison.
- Clutter-floor comparison.
- Protected-region retention comparison.
- Residual-error power trend.

Every future figure must explicitly call `figure`, use `tiledlayout` and `nexttile` for multi-panel reporting, and include `xlabel`, `ylabel`, and `title`.

## Decision Semantics

| Formal Decision | Meaning | Next Branch |
| :--- | :--- | :--- |
| `pass` | A mitigation candidate improves suppression and detectability proxies while preserving protected energy, or no LMS candidate beats baseline and no mitigation is explicitly retained | Proceed to G6 with selected mitigation posture and all caveats |
| `retune` | A candidate helps one metric but violates a G5-local tunable condition | Retune only G5 knobs and rerun G5 evidence |
| `reject` | Mitigation consistently destroys protected energy, only cleans plots without improving proxy metrics, or no G5-local retune remains | Retain diagnostic status, reopen upstream if evidence shows upstream cause, or hold mitigation |

`manual_review_required` is a review status, not a formal gate decision. It applies when G4 is caveated, the scene is direct-path dominated, raw-rate audit status is ambiguous, or protected regions are not stable enough for automatic selection.

## Edge Cases And Failure Modes

- G4 returns `blocked`: do not run G5 as a formal gate.
- G4 returns `scene_limited_direct_path_dominated`: allow only diagnostic/manual-review comparison unless human acceptance explicitly authorizes a diagnostic downstream path.
- LMS suppresses the direct path but removes off-origin nonzero-Doppler energy: candidate fails protected-energy retention.
- Conservative and aggressive LMS underperform no mitigation: retain no mitigation if evidence is complete.
- Aggressive LMS improves floor but creates artifacts or smearing: retune or reject the aggressive profile.
- Reference channel remains RF-caveated from G2: carry the caveat forward and do not relabel as G5 success.
- Truth windows are unavailable: use G4 protected regions and state truth-window retention is deferred to G7/G8 confirmation.

## Test Plan

Unit tests:

- Validate G5 option schema and candidate profile names.
- Validate required G4 input fields and caveat handling.
- Validate protected-region mask construction from G4 axes and labels.
- Validate `pass`, `retune`, and `reject` mapping from synthetic metric tables.

Integration tests:

- Run a bounded real-data G5 comparison only after credible G4 output exists.
- Confirm all three required candidates are evaluated.
- Confirm no-mitigation baseline is always included.
- Confirm protected-region retention failure prevents candidate selection.
- Confirm direct-path suppression without increased off-origin occupied structure is labeled as leakage cleanup rather than scene recovery.
- Confirm a visual-only improvement cannot produce a normal mitigation success label.
- Confirm acquisition implications are reported when mitigation fails to reveal useful scene content.
- Confirm upstream caveats are carried into G5 output.

Evidence and regression tests:

- Confirm all required evidence bundle files exist.
- Confirm `MIT-001`, `MIT-002`, and `MIT-003` are represented in `requirements_coverage.csv`.
- Confirm `decision.txt`, `failure_cause.txt`, and `next_branch.txt` match the selected branch.
- Confirm generated figures include labels and titles.

## Open Decisions Blocked On Upstream Outputs

- Whether G4 Part 2 returns `ready`, `caveated`, `blocked`, or scene-limited diagnostic evidence.
- Final G4 protected-region fields and mask definitions.
- Numeric protected-energy loss budget.
- Numeric suppression and detectability-proxy thresholds.
- Whether `dsp.LMSFilter` leakage settings are available and appropriate in the installed MATLAB release.
- Whether G5 is first implemented as helper-only, runner-level, or Live Script review surface.
- How to handle normal G5 pass if G4 raw-rate audit disagreement remains unresolved.

## Out Of Scope

- Final CPI, overlap, map registration, and integration freeze belong to G6.
- Truth alignment and truth-window definitions belong to G7.
- CFAR threshold tuning and detector acceptance belong to G8.
- Detection schema readiness belongs to G9.
- Tracking and truth-correlated validation belong to G10.
- Customer-facing performance claims are not enabled by G5 alone.
