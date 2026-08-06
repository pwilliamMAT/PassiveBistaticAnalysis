# G4 Plan Part 2

## Why This Revision Exists

This Part 2 plan is needed because the first executable G4 helper slice produced internally consistent outputs, but those outputs did not yet answer the real G4 question strongly enough for manual audit.

The current baseline run on `20260622T102123` showed:

- `Q1`, `Q2`, `Q3`, and `Q4` all returned `ready`
- representative maps were visually near-identical and display-centered around a bright point at `(0,0)`
- grouped medians showed very large `DirectPathToClutter_dB` and `DirectPathToFloor_dB` values, plus `OffOriginEnergyFraction` near `1.0`
- repeatability values increased monotonically with CPI and the direct-path coordinate spread collapsed to zero

Those results are valuable, but they mainly prove that the current reduced-rate G4 path can produce a stable, dominant direct path after the frozen G3 correction is applied. They do not yet convincingly prove that the passive scene is informative enough for downstream mitigation, CPI freeze, or detection work.

This revision therefore updates the next G4 slice so the phase does due diligence before moving forward. The new plan keeps the current helper-first scope, but it changes the review contract to separate "stable direct path" from "usefully observable passive scene," adds a bounded CPI sensitivity check inside G4, and adds a targeted raw-rate audit to validate the current reduced-rate conclusions.

Reduced-rate here means the current helper decimates the corrected signals before running `ambgfun`. That reduced-rate path remains useful because it keeps repeated map formation tractable across many repetitions, windows, and CPI choices. Its risk is that coarser delay and Doppler sampling can overstate stability or hide scene detail. This Part 2 plan keeps the reduced-rate path as the main exploratory product, but it adds an explicit raw-rate spot-check so that risk is no longer implicit.

## Summary

This Part 2 plan updates the next executable G4 slice with three goals:

- rework the metric contract so `Q2` and `Q4` reflect scene observability and downstream usefulness rather than direct-path dominance alone
- add bounded CPI due diligence inside G4 using a small fixed sensitivity set, while leaving final CPI freeze and integration policy to G6
- add a targeted raw-rate `ambgfun` audit on a small subset of windows so reduced-rate conclusions are explicitly checked instead of assumed

This plan remains within G4 helper-level and live-script review scope only. It does not add a formal whole-gate G4 runner, does not change the placeholder whole-gate G4 row semantics yet, and does not collapse G6 responsibilities into G4.

## Native Audit

| Proposed Workflow | Native MATLAB Documentation Example Analogue | Updates needed to fit current goal |
| :--- | :--- | :--- |
| Helper-level passive baseline review on frozen G3 contracts | `ambgfun` crossambiguity workflow | Keep `ambgfun` as the baseline map method, but revise the review contract so scene observability is judged separately from direct-path stability |
| Bounded CPI sensitivity review inside G4 | `ambgfun`, MATLAB table workflows, Live Editor sections | Evaluate a small fixed CPI sensitivity set to test robustness of the G4 conclusion without turning G4 into a broad parameter sweep |
| Targeted reduced-rate versus raw-rate audit | `ambgfun` on bounded windows, `resample` for reduced-rate preparation | Add a tractable raw-rate spot-check on selected repetitions and windows to verify that the reduced-rate path is not creating a misleadingly stable view |
| Live-script manual-review surface for G4 | MATLAB Live Editor sections plus helper calls | Restore or add a G4 analysis-core review section that shows compact tables plus raw-axis and display-axis figures rather than relying on large raw tables alone |

| Proposed Feature / Algorithm | Native MATLAB Function/Toolbox Equivalent | Documentation Syntax Template Used |
| :--- | :--- | :--- |
| Baseline passive map generation | `ambgfun` | `[afmag, delay, doppler] = ambgfun(x, y, Fs, PRF)` |
| Reduced-rate map preparation | `resample` | `y = resample(x, p, q)` |
| Scene occupancy and energy metrics | `sum`, `mean`, `nnz`, logical indexing, `mag2db` | `ratioDb = mag2db(signalPower / backgroundPower)` |
| Compact grouped review tables | `groupsummary`, `table` | `summaryTable = groupsummary(tableValue, groupVars, method, dataVars)` |
| Review figures | `figure`, `tiledlayout`, `nexttile`, `imagesc`, `plot` | `figure; tiledlayout(...); nexttile; imagesc(...)` |

## Scope Boundary

### In scope for this G4 revision

- keep `ambgfun` as the only baseline map method
- keep the frozen G3-approved upstream contract:
  - dataset `20260622T102123`
  - reference `RF1:RX2`
  - surveillance `RF0:RX2`
  - required G3 overall label `ready` or `caveated`
  - required G3 strategy `global_session_correction`
- keep the reduced-rate path as the main exploratory product
- add a bounded CPI sensitivity check inside G4 to test whether the present G4 conclusion is robust to modest CPI changes
- add a targeted raw-rate audit to validate the reduced-rate path
- add a compact human-review surface for G4 tables and figures

### Explicitly out of scope for this G4 revision

- final CPI freeze
- overlap sweep
- integration-rule freeze
- detector-facing product freeze
- replacing `ambgfun` with `phased.RangeDopplerResponse`
- formal whole-gate `pass / retune / reject` semantics

Those remain G6 or later parity work.

## Implementation Changes

### Implementation Clarifications Required Before Coding

These clarifications are binding for the next implementation slice. They fill gaps identified by the council review so the implementer does not need to invent scoring, eligibility, audit, or schema policy.

- Define `SceneObservabilityScore` explicitly before coding. It must be based on `OffOriginNonzeroDopplerEnergyFraction`, `OffOriginOccupiedFraction_abovePeakMinus20dB`, `ZeroDopplerRidgeEnergyFraction`, and `DirectPathToOffRidgeEnergy_dB`; it must not be dominated by `DirectPathToClutter_dB` or `DirectPathToFloor_dB`.
- Define numeric `Q2` thresholds for `ready`, `caveated`, and `blocked`. The phrase "nontrivial off-origin nonzero-Doppler structure" must be converted into explicit threshold values before implementation.
- Define intermediate CPI G3 eligibility policy. `short_mid` and `medium_long` are G4 sensitivity CPIs, not existing G3-approved anchor CPIs. Recommended policy: mark them `derived_from_bracketing_cpis` and allow ranking only when both adjacent G3 anchor CPIs are not blocked; otherwise mark them caveated or ineligible.
- Define raw-rate audit agreement tolerances. Specify maximum allowed delay mismatch, Doppler mismatch, and material scene-metric deltas for `agreement`, `caveated_agreement`, and `disagreement`.
- Define raw-rate versus reduced-rate coordinate units. Recommended policy: report both reduced-rate samples and native-equivalent samples where useful, but use native-equivalent samples for audit agreement and rationale.
- Define mask construction rules. Direct-path exclusion masks must be centered on the localized raw-axis direct path; zero-Doppler ridge masks must be defined in Hz on the raw Doppler axis; scoring masks must be rebuilt per map on that map's axes.
- Update expected row counts after CPI expansion. Reduced-rate `MapSummaryTable` should have `225` rows, `RepeatabilityTable` should have `15` rows, `RepresentativeMaps` should have `15` entries, and `CpiSelectionTable` should have `5` rows.
- Replace old map labels explicitly. Any old `reviewable` label should become `reviewable_scene_present`; the exact map-level label set is `implementation_suspect`, `scene_limited_direct_path_dominated`, and `reviewable_scene_present`.
- Treat live-script status reconciliation as an implementation prerequisite. Current inspected `runPassiveBistaticPiplineLiveScript.m` appears placeholder-only for G4 despite README language describing a G4 analysis-core section; implementation must reconcile the executable review surface and documentation.
- Add a direct-path-dominated test fixture. Expected outcome: origin containment and direct-path prominence pass, at least one map is `scene_limited_direct_path_dominated`, `Q2` is not `ready`, and `Q4` is not `ready`.

### 1. Keep the public helper stable

Keep the public helper entry point unchanged:

- `analysis = helperAnalyzeG4PassiveBaselineMap(sessionData, collectionMetadataInfo, g3SyncResults, options)`

Keep the current upstream validation behavior unchanged.

Do not introduce a standalone `runG4...` entry point in this slice.

### 2. Make the map-rate contract explicit

The next slice must document and expose the current reduced-rate path explicitly.

Reduced-rate product definition:

- corrected reference and surveillance signals remain the source data
- the helper applies the frozen G3 global-session correction before map formation
- both channels are reduced by `MapDecimationFactor = 200`
- reduced map sample rate is therefore `30720 Hz`
- reduced-rate `ambgfun` remains the main G4 review product

Add explicit output fields or option-report fields that record:

- `MapRateMode`
- `MapDecimationFactor`
- `MapSampleRateHz`
- whether a given summary or audit row is reduced-rate or raw-rate

### 3. Add a bounded CPI sensitivity set inside G4

The next slice must keep the current three CPI anchors and add two intermediate values for due diligence.

Use this exact fixed G4 CPI sensitivity set:

- `short` = `0.025 s` = `153600` native samples = `768` reduced-rate map samples
- `short_mid` = `0.0375 s` = `230400` native samples = `1152` reduced-rate map samples
- `medium` = `0.050 s` = `307200` native samples = `1536` reduced-rate map samples
- `medium_long` = `0.075 s` = `460800` native samples = `2304` reduced-rate map samples
- `long` = `0.100 s` = `614400` native samples = `3072` reduced-rate map samples

Keep these other first-slice constraints unchanged:

- fixed `early`, `center`, and `late` windows
- no overlap
- fixed reference and surveillance mapping
- fixed G3 correction strategy

Interpretation rule for this CPI expansion:

- G4 may use the extended CPI set only to test robustness of the current passive-map conclusion
- G4 must not claim that the final CPI has been frozen for downstream use
- G4 must explicitly state that final CPI freeze remains a G6 responsibility

### 4. Rework Q2 so it measures scene observability honestly

The current G4 slice over-rewards a strong, stable direct path. The next slice must separate direct-path localization from scene usefulness.

Keep the current direct-path-localization observables for `Q1`, but revise `Q2` so it uses scene-first metrics.

Add these new per-map metrics to `MapSummaryTable`:

- `RawDirectPathDelayOffset_samples`
- `RawDirectPathDopplerOffset_Hz`
- `OffOriginNonzeroDopplerEnergyFraction`
- `ZeroDopplerRidgeEnergyFraction`
- `OffOriginOccupiedFraction_abovePeakMinus20dB`
- `DirectPathToOffRidgeEnergy_dB`
- `MapRateMode`

Metric semantics:

- `RawDirectPathDelayOffset_samples` and `RawDirectPathDopplerOffset_Hz` are the localized direct-path coordinates on the raw axes before any display recentering
- `OffOriginNonzeroDopplerEnergyFraction` is the fraction of total map linear power outside the direct-path exclusion mask and outside the zero-Doppler ridge exclusion band
- `ZeroDopplerRidgeEnergyFraction` is the fraction of total map linear power inside the zero-Doppler ridge exclusion band
- `OffOriginOccupiedFraction_abovePeakMinus20dB` is the fraction of bins outside the direct-path exclusion mask and outside the zero-Doppler ridge exclusion band whose power is at least `20 dB` below the direct-path peak or stronger
- `DirectPathToOffRidgeEnergy_dB` is the direct-path power relative to the median off-ridge off-origin power

Revise map-level interpretation labels to this exact set:

- `implementation_suspect`
- `scene_limited_direct_path_dominated`
- `reviewable_scene_present`

Map-level label rules:

- use `implementation_suspect` when origin containment fails or local direct-path prominence falls below the current implementation threshold
- use `scene_limited_direct_path_dominated` when the direct path is localizable but scene metrics show weak off-origin nonzero-Doppler structure
- use `reviewable_scene_present` only when the direct path is localizable and the scene metrics show nontrivial off-origin nonzero-Doppler structure

Q2 label rules:

- `ready` only if the median scene metrics across the recommended CPI and across all three window labels indicate that off-origin nonzero-Doppler structure is present and not dominated by the zero-Doppler ridge
- `caveated` if some off-origin structure is present but remains weak or inconsistent
- `blocked` if the result is effectively a stable direct-path product with inadequate scene evidence

Q2 must no longer become `ready` solely because `DirectPathToClutter_dB` and `DirectPathToFloor_dB` are large.

### 5. Rework Q4 so it ranks downstream usefulness, not just direct-path stability

The next slice must rank CPI candidates using scene observability first and repeatability second.

Use this exact deterministic ranking order:

1. G3 CPI eligibility
2. scene observability score
3. masked repeatability score
4. coordinate stability score
5. shorter-CPI tie-break only when the top candidates remain within a fixed epsilon

Use these exact epsilon values for the shorter-CPI tie-break:

- scene score epsilon = `2.0`
- masked repeatability epsilon = `0.03`
- coordinate score epsilon = `0.50`

Add these fields to `CpiSelectionTable`:

- `SceneObservabilityScore`
- `RepeatabilityScore`
- `CoordinateStabilityScore`
- `RateAuditAgreementLabel`
- `SensitivitySetMember`

Interpretation rule:

- if the top-ranked CPI is scene-limited, `Q4` must not be `ready`
- if the top-ranked CPI is repeatable but scene-limited, `Q4` must be `caveated`
- `Q4` may be `ready` only if the top-ranked CPI is both repeatable and scene-reviewable under the revised Q2 contract

### 6. Add a targeted raw-rate audit

The next slice must add a bounded raw-rate audit so reduced-rate conclusions are explicitly checked.

Use this exact audit subset:

- repetitions `1`, `8`, and `15`
- `center` window only
- CPI labels `short`, `medium`, and `long`

That produces `9` raw-rate audit maps total.

The raw-rate audit must compare raw-rate versus reduced-rate for:

- direct-path delay coordinate
- direct-path Doppler coordinate
- `DirectPathToOffRidgeEnergy_dB`
- `OffOriginNonzeroDopplerEnergyFraction`
- `ZeroDopplerRidgeEnergyFraction`

Add a new top-level helper output:

- `FullRateAuditSummaryTable`

That table must contain one row per raw-rate audit map and include:

- `Repetition`
- `CpiLabel`
- `WindowLabel`
- `RawRateDirectPathDelay_samples`
- `ReducedRateDirectPathDelay_samples`
- `RawRateDirectPathDoppler_Hz`
- `ReducedRateDirectPathDoppler_Hz`
- `RawRateDirectPathToOffRidgeEnergy_dB`
- `ReducedRateDirectPathToOffRidgeEnergy_dB`
- `RawRateOffOriginNonzeroDopplerEnergyFraction`
- `ReducedRateOffOriginNonzeroDopplerEnergyFraction`
- `RawRateZeroDopplerRidgeEnergyFraction`
- `ReducedRateZeroDopplerRidgeEnergyFraction`
- `AgreementLabel`
- `Rationale`

Agreement rules:

- `agreement` when raw-rate and reduced-rate support the same qualitative scene conclusion
- `caveated_agreement` when the direct-path coordinates remain consistent but scene metrics differ materially
- `disagreement` when raw-rate and reduced-rate imply different scene conclusions

If any audit row is `disagreement`, the top-level G4 interpretation must carry an explicit caveat code indicating reduced-rate audit disagreement.

### 7. Restore the human-review surface

The next slice must provide a compact review surface so G4 can be audited without reading the full `MapSummaryTable` first.

The G4 analysis-core review surface must display:

- a one-row overall summary table for the G4 helper run
- `QuestionSummaries`
- a CPI comparison table with the new scene, repeatability, and coordinate scores
- a grouped map-label count table
- grouped median scene metrics by CPI and window label
- a raw-axis representative-map grid
- a display-axis representative-map grid
- a direct-path raw-coordinate trend plot
- a raw-rate audit summary table

If the live script still lacks the intended G4 analysis-core section, the next slice must add or restore it and record helper execution in `pipelineResults.G4PassiveBaselineMapResult`.

### 8. Result-contract additions

The next slice keeps the current public helper call shape, but it extends the returned `analysis` struct.

Add these top-level fields:

- `FullRateAuditSummaryTable`
- `RawAxisRepresentativeMaps`

Update these existing fields:

- `MapSummaryTable` gains the scene-first metrics listed above
- `CpiSelectionTable` gains the new ranking-score and audit-agreement columns
- `QuestionSummaries` uses the revised `Q2` and `Q4` semantics
- `Interpretation` gains an explicit reduced-rate audit caveat code when needed

## Test Plan

1. Static and contract checks
- Run MATLAB Code Analyzer on any helper changes and new review-surface helpers.
- Confirm the public helper signature remains unchanged.
- Confirm upstream G3 gating behavior remains unchanged.

2. Baseline-behavior regression checks
- Re-run the baseline G4 helper on `20260622T102123`.
- Confirm the current dataset no longer reaches `Q2 = ready` solely because direct-path separation is large.
- Confirm a visually direct-path-dominated result is eligible to become `scene_limited_direct_path_dominated`.
- Confirm `Q4` cannot be `ready` if the top-ranked CPI is still scene-limited.

3. CPI sensitivity checks
- Confirm the extended G4 sensitivity set contains exactly the five CPI labels listed above.
- Confirm the helper still uses fixed `early`, `center`, and `late` windows with no overlap.
- Confirm the resulting CPI recommendation is reported as G4 due diligence only and not as a final freeze.

4. Raw-rate audit checks
- Confirm the raw-rate audit runs on exactly `9` maps.
- Confirm raw-rate and reduced-rate coordinates are both reported.
- Confirm any qualitative reduced-rate versus raw-rate disagreement is surfaced in `FullRateAuditSummaryTable`.
- Confirm the top-level interpretation carries a caveat when the audit shows disagreement.

5. Review-surface checks
- Confirm the review surface shows both raw-axis and display-axis representative maps.
- Confirm the grouped metric summaries make it obvious whether the result is direct-path-dominated or scene-reviewable.
- Confirm `pipelineResults.G4PassiveBaselineMapResult` stores success, blocked, or failure execution trace information without changing `GateResults(4)` from placeholder-only.

6. Failure-path checks
- Invoke G4 with a non-qualifying G3 result and confirm blocking behavior is unchanged.
- Force a raw-rate audit disagreement condition and confirm the disagreement propagates into the top-level interpretation.
- Confirm that a stable direct path with weak off-origin structure can no longer return `SceneObservabilityLabel = ready`.

## Assumptions and Defaults

- The next executable slice remains helper-level plus live-script review only.
- `ambgfun` remains the only supported baseline map method in this phase.
- The reduced-rate path remains the main exploratory product because it is tractable across many windows and CPI candidates.
- The targeted raw-rate audit exists only to validate the reduced-rate path, not to replace it.
- G4 owns bounded CPI due diligence, not final CPI freeze.
- G6 remains responsible for final CPI length, overlap, and integration policy.
- The current baseline dataset may legitimately downgrade from `ready` once scene-first metrics are applied. That is acceptable and is the intended result if the current product is strong on direct-path stability but weak on scene observability.

## Sequential Council Review

The Part 2 plan above has been reviewed against the current repository status and the gate trajectory in `ProjectPlan.md`. The review comments below are retained as the manual-review record that should guide implementation of the next G4 slice.

### Current Status Facts Used By Reviewers

- `helperAnalyzeG4PassiveBaselineMap` exists as the first executable G4 helper slice and currently uses reduced-rate `ambgfun` map formation with `MapDecimationFactor = 200`.
- The current helper remains first-slice shaped: it uses the original `short`, `medium`, and `long` CPI set, does not yet return `FullRateAuditSummaryTable`, and does not yet implement the raw-rate audit in this Part 2 plan.
- Current `Q2` resolution still relies materially on `DirectPathToClutter_dB` and `DirectPathToFloor_dB`; it does not yet make off-origin nonzero-Doppler scene content the primary readiness criterion.
- Current CPI ranking still emphasizes repeatability before scene observability, while this Part 2 plan correctly proposes scene-first CPI ranking for downstream usefulness.
- `README.md` describes a separate G4 analysis-core live-script section, but inspected `runPassiveBistaticPiplineLiveScript.m` still shows the G4 section as placeholder-only. This documentation/executable-surface mismatch must be reconciled before claiming the G4 review surface is implemented.
- `ProjectPlan.md` defines G4 as the `validated passive baseline` milestone only when the `ambgfun` map is plausible, repeatable, and suitable for mitigation and detector work. G4 may support downstream decisions, but G6 still owns final CPI and integration freeze.

### Review Status

- `1.` Passive bistatic radar algorithm expert: completed
- `2.` RF and data-quality engineer: completed
- `3.` Signal processing and detection QE expert: completed
- `4.` MATLAB implementation and test architecture expert: completed
- `5.` Systems, requirements, and downstream-pipeline reviewer: completed

### 1. Passive Bistatic Radar Algorithm Expert

1. Critical: The Part 2 plan correctly identifies the main technical risk: the current G4 result proves a stable direct path, not necessarily a useful passive bistatic scene. A bright origin-centered feature can be a synchronization and leakage success while still providing little bistatic target or clutter structure for downstream processing.
Mitigation: Keep the proposed `scene_limited_direct_path_dominated` label and make it the default downgrade path when off-origin nonzero-Doppler energy is weak, inconsistent, or dominated by the zero-Doppler ridge.

2. High: The raw-rate audit must be treated as a physics check, not a convenience comparison. A reduced-rate map can make the direct path look stable by coarsening delay/Doppler bins, hiding sidelobe structure, or smoothing narrow clutter and target-like features.
Mitigation: Require raw-rate versus reduced-rate agreement on direct-path delay, direct-path Doppler, off-ridge energy, off-origin nonzero-Doppler energy fraction, and zero-Doppler ridge fraction. A qualitative scene-label comparison alone is not enough.

3. High: The proposed CPI expansion is useful, but G4 must not let the extended CPI set become an undeclared G6 freeze. The passive radar question in G4 is whether plausible maps exist and are repeatable; the downstream detector-product question belongs to G6.
Mitigation: Keep all five CPI labels as G4 sensitivity evidence only, and explicitly label `RecommendedBaselineCpiLabel` or any top-ranked CPI as provisional due diligence rather than a detector input freeze.

4. Medium: The plan should preserve raw axes as the authority for physical claims. Display-centered axes are useful for manual review, but they can hide sign errors, lag offsets, and implementation mistakes if reviewers only see recentered pictures.
Mitigation: Keep raw direct-path delay/Doppler fields, raw-axis representative maps, and direct-path raw-coordinate trend plots mandatory in the review surface.

Sound areas:

- Keeping `ambgfun` as the baseline oracle remains the right G4 scope decision.
- Separating direct-path localization from scene observability is the correct technical pivot for Part 2.
- Deferring `phased.RangeDopplerResponse`, mitigation, and final CPI freeze avoids broadening G4 into later gates.

### 2. RF And Data-Quality Engineer

1. Critical: The baseline dataset still carries RF and acquisition caveats, especially the weak accepted reference-channel history from G2. A scene-limited map may be a real RF/acquisition limitation rather than a G4 algorithm failure.
Mitigation: Carry upstream caveat codes and RF-readiness language into the G4 interpretation. Do not collapse weak scene observability into `implementation_suspect` unless axis containment, direct-path localization, or correction-consistency checks fail.

2. High: Direct-path dominance is not inherently bad, but it is not sufficient evidence for G5/G6/G8. Passive bistatic downstream processing needs evidence that non-direct-path content survives the map process.
Mitigation: Use the proposed off-origin nonzero-Doppler and off-ridge metrics as first-class fields. Report zero-Doppler ridge fraction separately so reviewers can distinguish stationary leakage/clutter dominance from broader scene occupancy.

3. High: The current reduced-rate path is a necessary tractability compromise, but it can bias RF conclusions. Decimation can suppress narrowband impairments, smear weak moving energy, and make a leakage-dominated scene look artificially clean.
Mitigation: Keep the raw-rate audit subset bounded but mandatory. If raw-rate and reduced-rate conclusions disagree, the top-level G4 interpretation must carry a reduced-rate caveat and block downstream readiness claims.

4. Medium: The review surface must make poor RF utility obvious to a human reviewer. Large `DirectPathToClutter_dB` and `DirectPathToFloor_dB` values can read like success even when they really mean the direct path overwhelms everything else.
Mitigation: Present grouped scene metrics and map-label counts before or next to direct-path contrast metrics. The manual-review layout should make `scene_limited_direct_path_dominated` visually and tabularly obvious.

Sound areas:

- The plan correctly treats raw-rate validation as a spot-check, not a wholesale replacement for the reduced-rate exploratory product.
- The exact audit subset of repetitions `1`, `8`, and `15` gives useful early/mid/late session coverage without making Part 2 too expensive.
- Keeping accepted reference/surveillance roles locked to the G2/G3 contract prevents RF role drift inside G4.

### 3. Signal Processing And Detection QE Expert

1. Critical: CPI selection must rank scene observability before repeatability. A perfectly repeatable direct-path-only map is not a useful detector input and should not make `Q4` ready.
Mitigation: Implement the proposed deterministic ranking order exactly: G3 eligibility, scene observability score, masked repeatability score, coordinate stability score, then shorter-CPI tie-break only inside the declared epsilons.

2. High: The scene score must not be a repackaged direct-path contrast score. If `SceneObservabilityScore` is dominated by `DirectPathToClutter_dB`, the Part 2 change will not fix the first-slice failure mode.
Mitigation: Define the score around off-origin nonzero-Doppler occupancy, off-ridge energy, zero-Doppler ridge suppression, and consistency across early/center/late windows. Direct-path contrast should support implementation confidence, not scene readiness.

3. High: `Q2` and `Q4` labels need hard coupling. If the top-ranked CPI is scene-limited, `Q4` cannot be `ready` even if repeatability and coordinate stability are excellent.
Mitigation: Make `Q4 = ready` conditional on the top-ranked CPI being both repeatable and scene-reviewable under the revised Q2 contract. Otherwise return `caveated` or `blocked` with an explicit rationale.

4. Medium: The raw-rate audit needs bounded numeric tolerances or at least explicit material-difference rules. Without tolerances, `agreement`, `caveated_agreement`, and `disagreement` risk becoming subjective labels that are hard to test.
Mitigation: Record the exact comparison deltas in `FullRateAuditSummaryTable` and make the rationale text name which metric drove the agreement label.

5. Medium: The test plan should include a direct-path-dominated synthetic or forced fixture. Current verification catches orientation and contract failures, but Part 2 specifically needs to prove that stable direct-path-only products downgrade correctly.
Mitigation: Add a test case where origin containment and local prominence pass, while off-origin nonzero-Doppler scene metrics fail. Expected result: map label `scene_limited_direct_path_dominated`, `Q2` not ready, and `Q4` not ready.

Sound areas:

- The proposed five-CPI sensitivity set is narrow enough for G4 due diligence and broad enough to catch monotonic CPI artifacts.
- The explicit epsilon values make the shorter-CPI tie-break reproducible.
- Keeping peak-normalized dB maps for figures while scoring from linear-power products is the right signal-processing separation.

### 4. MATLAB Implementation And Test Architecture Expert

1. Critical: The executable review surface appears out of sync with the README description. `README.md` says the G4 analysis-core section records `pipelineResults.G4PassiveBaselineMapResult`, but inspected live-script text still shows placeholder-only G4 behavior.
Mitigation: Before or during Part 2 implementation, reconcile `runPassiveBistaticPiplineLiveScript.m`, `README.md`, and `G4Plan_Part2.md`. Either add/restore the G4 analysis-core section or downgrade the README statement until the section exists.

2. High: The result-contract expansion is large enough that downstream code should not infer field presence casually. `MapSummaryTable`, `CpiSelectionTable`, and `Interpretation` are all changing semantics, not merely adding display columns.
Mitigation: Add contract checks in `verifyG4PassiveBaselineMapSlice` for every new required field and for the changed Q2/Q4 behavior. Tests should assert semantics, not only table shape.

3. High: The raw-rate audit can become computationally expensive or memory-heavy if implemented with accidental full-session products.
Mitigation: Keep the audit subset exactly bounded to `9` maps, use local windows only, and avoid retaining unnecessary full-rate intermediate arrays beyond the returned audit metrics and representative review products.

4. Medium: The proposed `MapRateMode` field should be present in every mixed-rate table. Without that, later reviewers may accidentally compare raw-rate and reduced-rate metrics as if they came from the same grid.
Mitigation: Add `MapRateMode`, `MapDecimationFactor`, and `MapSampleRateHz` to option/report fields, and include row-level rate identity in any table containing mixed-rate values.

5. Medium: The Part 2 plan should preserve the public helper signature, but internal helper boundaries will likely need tightening. A monolithic implementation will be hard to verify.
Mitigation: Keep `helperAnalyzeG4PassiveBaselineMap` as the public entry point, but factor raw-rate audit and scene metric calculations into local helper functions with deterministic table outputs.

Sound areas:

- Keeping the public helper signature unchanged protects the current live-script and direct-helper usage pattern.
- Adding fields rather than replacing the whole result struct is compatible with staged MATLAB review.
- The proposed failure-path checks are aligned with the repo's current helper-level verification style.

### 5. Systems, Requirements, And Downstream-Pipeline Reviewer

1. Critical: G4 is the `validated passive baseline` milestone in `ProjectPlan.md`, but Part 2 remains helper-level and non-final. The plan must not imply formal gate closure just because the helper returns richer evidence.
Mitigation: Keep formal `pass / retune / reject` semantics out of this slice. The strongest permitted claim is that Part 2 produces evidence for manual G4 review and later runner parity.

2. High: G4 must maximize downstream utility without taking over downstream ownership. G5 needs to know whether there is a baseline worth mitigating; G6 needs map-product metadata for freeze decisions; G8 needs confidence that detector tuning will not chase map artifacts.
Mitigation: Return stable map semantics, scene labels, rate-audit caveats, and representative products. Do not choose mitigation settings, final overlap, final integration rules, CFAR thresholds, or tracking readiness.

3. High: If Part 2 downgrades the baseline dataset from `ready`, that should not be treated as a project failure. It may be the correct result given the diagnostic RF posture and direct-path-dominated maps.
Mitigation: Use explicit outcomes: `implementation_suspect` for broken map formation, `scene_limited_direct_path_dominated` for limited passive-scene evidence, and `reviewable_scene_present` for credible G4 scene utility.

4. Medium: The plan should preserve reopen discipline. If raw-rate audit disagreement indicates a reduced-rate artifact, G4 owns map-rate retuning. If the direct path is not physically plausible under raw axes, reopen G3 or G1 rather than pushing the issue into G5/G8.
Mitigation: Add caveat codes that distinguish reduced-rate disagreement, implementation-suspect axes, upstream-sync caveats, and scene-limited RF/acquisition behavior.

Sound areas:

- The plan stays aligned with the ProjectPlan gate sequence: G4 before mitigation, CPI freeze, truth alignment, detection, and tracking.
- The plan correctly treats validated detection, not G4, as the first programmatic success milestone.
- The appended review record gives later agents a clear rationale for why Part 2 may downgrade current first-slice results.

## Implementation Update: Raw-Rate Audit Memory Fix Required

Manual verification of the G4 Part 2 implementation exposed a raw-rate audit feasibility issue. The Live Script G4 analysis-core section is integrated and records `pipelineResults.G4PassiveBaselineMapResult`, but the helper currently fails on the real baseline session during the raw-rate audit with a native-rate full 2-D `ambgfun` allocation request of approximately `153600x307199` (`175.8 GB`) for the `short` CPI. This confirms that native-rate full-surface raw-rate audit maps are not tractable for this dataset.

The next corrective implementation slice must keep the reduced-rate full 2-D `ambgfun` map as the primary G4 review product and replace only the raw-rate audit internals with a bounded native-rate cut-based audit.

### Required corrective changes

- Preserve the public helper signature:
  - `analysis = helperAnalyzeG4PassiveBaselineMap(sessionData, collectionMetadataInfo, g3SyncResults, options)`
- Preserve `GateResults(4)` placeholder-only semantics.
- Preserve the current Live Script G4 analysis-core section and `pipelineResults.G4PassiveBaselineMapResult` execution trace.
- Do not add a standalone `runG4...` runner.
- Do not implement G5-G7 behavior.

### Raw-rate audit replacement

Replace native-rate full 2-D raw audit map formation with native MATLAB `ambgfun` cuts:

- Use `ambgfun(..., Cut="Doppler", CutValue=...)` to estimate raw-rate delay near the expected direct-path Doppler.
- Use `ambgfun(..., Cut="Delay", CutValue=...)` to estimate raw-rate Doppler near the localized delay.
- Use a small fixed set of delay cut values to estimate raw-rate scene proxy metrics without materializing the full native-rate ambiguity matrix.
- Keep the audit subset fixed at 9 rows:
  - repetitions `1`, `8`, `15`
  - center window only
  - CPI labels `short`, `medium`, `long`

### Contract expectations after the fix

`FullRateAuditSummaryTable` must still be returned with 9 rows and must still report:

- raw-rate and reduced-rate direct-path delay coordinates
- raw-rate and reduced-rate direct-path Doppler coordinates
- raw-rate and reduced-rate scene comparison metrics
- `AgreementLabel`
- `Rationale`

Because the raw-rate scene values will be cut-sampled proxies rather than full native-rate 2-D map metrics, the implementation must label this clearly in options, metadata, or rationale strings. Recommended option/default fields:

- `FullRateAuditMethod = "ambgfun_cut_proxy"`
- `FullRateAuditDelayCutSearchRadius_nativeSamples`
- `FullRateAuditDopplerCutSearchRadius_Hz`
- `FullRateAuditSceneDelayCutCount`
- `FullRateAuditSceneDelaySpan_nativeSamples`
- `FullRateAuditSceneDopplerExclusion_Hz`

### Verification expectations

After the fix, manual verification should include:

```matlab
checkcode("helperAnalyzeG4PassiveBaselineMap.m")
checkcode("verifyG4PassiveBaselineMapSlice.m")
checkcode("runPassiveBistaticPiplineLiveScript.m")
```

Fast checks:

```matlab
verificationSynthetic = verifyG4PassiveBaselineMapSlice( ...
    "20260622T102123", pwd, ...
    struct("RunG3Regression", false, ...
           "RunBaselineExecution", false, ...
           "RunNegativeControls", false));

verificationNegative = verifyG4PassiveBaselineMapSlice( ...
    "20260622T102123", pwd, ...
    struct("RunG3Regression", false, ...
           "RunSyntheticOrientation", false, ...
           "RunBaselineExecution", false));
```

Real-session smoke check:

```matlab
verificationBaseline = verifyG4PassiveBaselineMapSlice( ...
    "20260622T102123", pwd, ...
    struct("RunG3Regression", false, ...
           "RunSyntheticOrientation", false, ...
           "RunNegativeControls", false));
```

Manual Live Script acceptance:

- Run through `G3 Sync Analysis Core`.
- Run `G4 Passive Baseline Analysis Core`.
- Confirm:

```matlab
pipelineResults.G4PassiveBaselineMapResult.ExecutionStatus == "executed"
height(pipelineResults.G4PassiveBaselineMapResult.Analysis.FullRateAuditSummaryTable) == 9
```

This update supersedes any interpretation that the raw-rate audit should form full native-rate 2-D ambiguity maps. The raw-rate audit remains mandatory, but it must be implemented as a bounded `ambgfun` cut-based physics spot-check.

## Implementation Update: Runner Formalization Authorized

After the G4 Part 2 helper and Live Script review surface were implemented and manually reviewed, the next user-authorized implementation phase formalizes the current G4 code into a standalone manual-review runner.

This update supersedes the earlier helper-slice-only instruction not to add a `runG4...` entry point for that completed slice. The runner phase remains constrained to G4 and must preserve the existing helper contract and non-final gate semantics.

Implementation scope for this runner phase:

- add `runG4PassiveBaselineMap(datasetId, repoRoot, options)` as the Stage 4 manual-review runner
- keep `helperAnalyzeG4PassiveBaselineMap(sessionData, collectionMetadataInfo, g3SyncResults, options)` as the analysis core called by the runner
- write a G4 evidence bundle under `artifacts/<datasetId>/G4_Passive_Baseline_Map/<runTimestampZ>/`
- export compact CSV review tables, `summary.md`, `passive_baseline_interpretation_note.md`, `config_snapshot.json`, `metrics.json`, `metrics.mat`, `comparison_snapshot.mat`, and representative-map figures
- keep the formal `GateResults(4)` pass / retune / reject semantics unchanged and non-final in the Live Script
- surface `AnalysisExecutionAssessment` and `LimitationSourceLabel` so a blocked result caused by dataset scene limitation or raw-rate audit disagreement is not confused with a helper execution failure
- do not implement G5 mitigation, G6 CPI freeze, G7 truth alignment, detection, or tracking behavior in this runner phase

Manual invocation target:

```matlab
results = runG4PassiveBaselineMap("20260622T102123", pwd, struct("ShowFigures", false));
```

Expected current baseline interpretation remains conservative: the runner can execute successfully while returning `OverallLabel = "blocked"` when the current dataset is scene-limited or the bounded raw-rate audit disagrees. That is a valid G4 manual-review outcome, not a runner failure.