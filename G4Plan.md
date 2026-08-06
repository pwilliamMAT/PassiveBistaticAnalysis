# G4 Plan

## Summary

Implement G4 in the same staged pattern that G3 originally used: add a helper-level analysis core first, then wire a non-final live-script analysis section on top of it, and defer the standalone runner and formal whole-gate `pass / retune / reject` runner to a later parity pass.

This first G4 slice should:

- keep the existing `## G4 Passive Baseline Map` gate row as a placeholder
- add a helper `helperAnalyzeG4PassiveBaselineMap(sessionData, collectionMetadataInfo, g3SyncResults, options)`
- add a new `## G4 Passive Baseline Analysis Core` live-script section that runs only after a qualifying G3 result exists
- lock to the current G3-approved upstream contract:
  - reference `RF1:RX2`
  - surveillance `RF0:RX2`
  - recommended correction strategy `global_session_correction`
- freeze the baseline-product semantics now, while keeping scoring and manual-review interpretation tunable during development
- compare a small fixed CPI set with fixed early / center / late spot-check windows rather than doing a broad parameter sweep
- return scene-usability metrics, representative map products, compact review tables, a non-final `BaselineProductDefinition`, and non-final manual-review labels
- keep interpretation split across upstream validity, scene observability, and implementation confidence rather than flattening all caveats into one label
- not write a G4 artifact bundle yet
- not freeze hard acceptance thresholds yet
- not change the formal G4 gate row semantics yet

## Native Audit

| Proposed Workflow | Native MATLAB Documentation Example Analogue | Updates needed to fit current goal |
| :--- | :--- | :--- |
| Helper-level passive baseline map analysis on frozen G1/G2/G3 contracts | `ambgfun` crossambiguity workflow | Build a G4 helper that computes corrected baseline maps, scene-usability metrics, and repeatability metrics without yet writing a standalone bundle |
| CPI comparison helper for baseline-map selection | `ambgfun`, MATLAB table workflows, Live Editor sections | Evaluate a fixed CPI set plus early / center / late spot checks and return a provisional recommended baseline CPI label instead of running a broad sweep |
| Live-script manual-review section for G4 | MATLAB Live Editor sections plus helper calls | Add a non-final `G4 Passive Baseline Analysis Core` section while keeping the whole-gate G4 row placeholder-only |
| Sync reuse from G3 into G4 | shared helper extraction from existing MATLAB functions | Factor the reusable sync-preparation logic out of current G3 internals into one shared helper used by both G3 and G4 |

| Proposed Feature / Algorithm | Native MATLAB Function/Toolbox Equivalent | Documentation Syntax Template Used |
| :--- | :--- | :--- |
| Baseline passive map generation | `ambgfun` | `[afmag, delay, doppler] = ambgfun(x, y, Fs, PRF)` |
| Fixed-window CPI comparison | MATLAB function with arguments block plus table outputs | `analysis = helperAnalyzeG4PassiveBaselineMap(sessionData, collectionMetadataInfo, g3SyncResults, options)` |
| Axis plausibility and direct-path localization | `ambgfun` outputs plus indexed neighborhood checks | `peakValue = max(localPatch, [], "all")` |
| Map repeatability across captures | MATLAB correlation on masked linear-power map products | `r = corr(mapA(mask), mapB(mask))` |
| Scene-usability metrics | `mag2db`, logical indexing, `mean`, `nnz` | `ratioDb = mag2db(signalPower / clutterPower)` |
| Summary table generation | `table` | `summaryTable = table(...)` |
| Review figures in Live Editor | `figure`, `tiledlayout`, `nexttile`, `imagesc`, `plot` | `figure; tiledlayout(...); nexttile; imagesc(...)` |

## Key Changes

### 1. Helper contract and shared sync reuse

Add `helperAnalyzeG4PassiveBaselineMap(sessionData, collectionMetadataInfo, g3SyncResults, options)` as the first G4 executable slice.

The helper must:

- validate frozen upstream assumptions before any map work:
  - dataset ID matches the current baseline
  - accepted role mapping matches the current G3 and G2 contracts
  - `g3SyncResults.OverallLabel` is `ready` or `caveated`
  - `g3SyncResults.RecommendedStrategyCandidate` is exactly `global_session_correction`
- carry inherited upstream caveat codes and per-CPI admissibility into the G4 interpretation model when they are available
- reuse the G3 correction model rather than inventing a new one
- treat `g3SyncResults` as the upstream gate and contract check only; do not depend on runner-shaped G3 outputs for the applied lag and residual-frequency values that G4 needs
- extract exactly one narrow internal-facing sync-preparation helper from current G3 internals and reuse it from both G3 and G4
- keep that shared helper internal-facing only; the new public helper for this slice is still `helperAnalyzeG4PassiveBaselineMap`
- freeze a non-final `BaselineProductDefinition` for this slice that defines:
  - exact `ambgfun` signal order and `PRF` derivation
  - delay and Doppler sign conventions
  - raw-axis versus display-axis handling
  - direct-path origin-search radius and exclusion-mask semantics
  - normalization rules for review figures versus scoring metrics

The shared sync-preparation helper should provide G4 with:

- corrected role mapping
- fixed CPI definitions
- per-window lag and residual-frequency observations
- the global-session correction estimate used to align the surveillance channel before map formation
- the correction-source CPI label and exact applied correction values reused by G4
- per-CPI eligibility or admissibility from G3 when available

### 2. First-slice G4 analysis scope

The helper should be CPI-comparison based, not a broad sweep.

Fixed defaults for the first slice:

- CPI labels: reuse G3's `short`, `medium`, and `long`
- CPI durations: reuse the current G3 frozen values
- correction strategy: global-session only
- window selection for G4 maps: fixed early, center, and late spot-check windows per repetition and CPI
- overlap: none in this first slice, because each repetition/CPI uses one fixed early window, one fixed center window, and one fixed late window
- baseline method: `ambgfun` only
- `phased.RangeDopplerResponse`: explicitly out of scope for this slice
- no decimation sweep
- no normalization sweep
- no hard acceptance thresholds in this slice; keep scoring descriptive and manual-review-oriented

For each repetition, CPI, and selected window, the helper should:

- take the selected early, center, or late window from the corrected reference and surveillance signals
- apply the locked global lag and residual-frequency correction to the surveillance signal
- generate the baseline crossambiguity map with `ambgfun` using the frozen `BaselineProductDefinition`
- preserve the raw delay and Doppler axes and derive display-centered review axes as separate metadata only
- localize the direct-path feature in the raw-coordinate map and report both raw and display-centered coordinates
- normalize the map to a peak-referenced dB form for figure rendering only
- compute scoring metrics from linear-power and masked-map products rather than from figure-only dB products
- compute map-level metrics used for axis plausibility, scene usability, sync-smear interpretation, and repeatability
- record pre-correction versus post-correction summary values needed to separate scene-limited behavior from implementation-suspect behavior

### 3. Helper outputs and review model

The helper should return a single `analysis` struct with:

- `DatasetId`
- `StageId`
- `Options`
- `CpiDefinitions`
- `BaselineProductDefinition`
- `MapSummaryTable`
- `RepeatabilityTable`
- `CpiSelectionTable`
- `QuestionSummaries`
- `Interpretation`
- `RecommendedBaselineCpiLabel`
- `RepresentativeMaps`

`MapSummaryTable` should have 135 rows, one per repetition/CPI/window, and include at minimum:

- `QuestionId`
- `Repetition`
- `RelativePath`
- `CpiLabel`
- `WindowLabel`
- `WindowStartSample`
- `CpiDuration_s`
- `CpiSamples`
- `AppliedLag_samples`
- `AppliedResidualFrequency_Hz`
- `DirectPathDelay_samples`
- `DirectPathDelay_s`
- `DirectPathDoppler_Hz`
- `DirectPathPeak_dB`
- `DirectPathLocalProminence_dB`
- `DirectPathToClutter_dB`
- `DirectPathToFloor_dB`
- `UsableDynamicRange_dB`
- `OffOriginEnergyFraction`
- `ZeroDopplerRidgeWidth_bins`
- `DirectPathWidth_bins`
- `DirectPathSharpness_dB`
- `ZeroDelayZeroDopplerValue_dB`
- `InterpretationLabel`
- `Rationale`

`RepeatabilityTable` should have 9 rows, one per CPI/window label, and include at minimum:

- `QuestionId`
- `CpiLabel`
- `WindowLabel`
- `RepetitionCount`
- `FullMapCorrelationMedian_diagnostic`
- `MaskedLinearCorrelationMedian`
- `MaskedLinearCorrelationMinimum`
- `DirectPathDelaySpread_samples`
- `DirectPathDopplerSpread_Hz`
- `DirectPathWidthMedian_bins`
- `InterpretationLabel`
- `Rationale`

`CpiSelectionTable` should have 3 rows, one per CPI, and include at minimum:

- `QuestionId`
- `CpiLabel`
- `G3EligibilityLabel`
- `WindowCoverage`
- `SceneUsabilitySummary`
- `RepeatabilitySummary`
- `ProvisionalRank`
- `Rationale`

`RepresentativeMaps` should be a 9-element struct array, one per CPI/window label, with figure-ready content:

- `CpiLabel`
- `WindowLabel`
- `RepresentativeRepetition`
- `Map_dB`
- `DelayAxis_s`
- `DelayAxis_samples`
- `DisplayDelayAxis_samples`
- `DopplerAxis_Hz`
- `DisplayDopplerAxis_Hz`
- `DirectPathDelay_samples`
- `DirectPathDelay_s`
- `DirectPathDoppler_Hz`

`QuestionSummaries` should have 4 rows:

- `Q1`: axis plausibility, raw/display coordinate consistency, and direct-path localization
- `Q2`: scene usability and stationary-scene interpretability
- `Q3`: map repeatability across captures and early / center / late spot-check windows
- `Q4`: provisional baseline CPI ranking for downstream use

`Interpretation` should use the same non-final overall label family as current G3 helper work:

- `ready`
- `caveated`
- `blocked`

`Interpretation` should also carry separate manual-review dimensions for:

- `UpstreamValidityLabel`
- `SceneObservabilityLabel`
- `ImplementationConfidenceLabel`
- `UpstreamCaveatCodes`

`RecommendedBaselineCpiLabel` should be chosen by a provisional manual-review ranking trace that:

1. excludes CPIs that G3 marks ineligible when that admissibility mask exists
2. compares CPI candidates using descriptive repeatability, scene-usability, and coordinate-stability metrics aggregated across the early / center / late spot checks
3. records a provisional ranking trace and reviewer rationale rather than imposing hard acceptance thresholds
4. prefers the shorter CPI only when the leading candidates remain materially similar by the recorded metrics

### 4. Live-script integration

Update `runPassiveBistaticPiplineLiveScript.m` to mirror the early G3 helper-only pattern:

- keep the existing `## G4 Passive Baseline Map` section as the whole-gate placeholder row
- add a new `## G4 Passive Baseline Analysis Core` section immediately after it
- gate the new G4 analysis section on a qualifying G3 result already in session
- if G3 is missing or blocked, show a blocked summary table and do not invoke the helper
- if G3 is present and `ready` or `caveated`, load the session with `IncludeSamples = true`, read `collection_metadata.json`, and call `helperAnalyzeG4PassiveBaselineMap`

The live-script section should display:

- a compact G4 review summary table
- a CPI comparison summary table
- the helper `CpiSelectionTable`
- the helper `QuestionSummaries`
- the helper `RepeatabilityTable`
- the raw `MapSummaryTable`

The live-script section should also render visible review figures from helper outputs:

- representative baseline map grid by CPI and window label
- repeatability summary plot by CPI and window label
- direct-path localization plot by repetition, CPI, and window label

Pipeline-record behavior for this slice:

- store the helper result as `pipelineResults.G4PassiveBaselineMapResult` on success
- on blocked or failure paths, still store a minimal execution record in `pipelineResults.G4PassiveBaselineMapResult` with `StageId`, `ExecutionStatus`, upstream-contract status, and rationale or failure message
- do not update `pipelineResults.GateResults(4)` out of placeholder status yet
- do not set `NextGate` based on G4 yet
- do not introduce `manual_review_executed` semantics for G4 until the later runner-parity pass

## Test Plan

1. Static/helper verification
- Run MATLAB Code Analyzer on the new helper and any extracted shared sync helper.
- Confirm the helper interface accepts `sessionData`, `collectionMetadataInfo`, `g3SyncResults`, and `options`.
- Confirm the extracted shared sync helper is the only new internal sync-reuse boundary and that baseline G3 outputs remain unchanged after the refactor.

2. Synthetic physics and orientation verification
- Run a synthetic known-delay / known-Doppler case through the exact G4 map path.
- Confirm the direct-path peak lands at the expected raw delay and Doppler bin, with the expected sign convention.
- Confirm the display-centered axes are derived from the raw axes without moving the underlying peak location.

3. Baseline helper execution
- Run the helper on `20260622T102123` using the in-session G3 result.
- Confirm `MapSummaryTable` has 135 rows.
- Confirm `RepeatabilityTable` has 9 rows.
- Confirm `CpiSelectionTable` has 3 rows.
- Confirm `QuestionSummaries` has 4 rows.
- Confirm `RepresentativeMaps` has 9 entries.
- Confirm `BaselineProductDefinition` is populated.
- Confirm `RecommendedBaselineCpiLabel` is populated.
- Confirm `Interpretation` includes `OverallLabel`, `UpstreamValidityLabel`, `SceneObservabilityLabel`, and `ImplementationConfidenceLabel`.

4. Negative controls and value-level consistency checks
- Swap signal order or invert the applied correction sign and confirm axis plausibility fails clearly.
- Confirm the G4 applied lag and residual-frequency values exactly match the extracted shared sync-preparation output.
- Confirm the raw and display axis vectors are monotonic, dimensionally consistent with each map, and zero-centered only in the display representation.
- Confirm the direct-path pick stays inside the declared origin-search neighborhood for valid baseline runs.
- Confirm the masked repeatability metrics are finite and bounded.

5. Live-script verification
- Run the live script through G1, G2 Stage 1, G2 Stage 2, G3 analysis core, the G4 placeholder row, and the new G4 analysis-core section.
- Confirm the G4 helper section executes only after qualifying G3 output exists.
- Confirm `pipelineResults.G4PassiveBaselineMapResult` exists.
- Confirm `pipelineResults.G4PassiveBaselineMapResult` carries a minimal execution record on both success and blocked or failure paths.
- Confirm the whole-gate G4 row remains placeholder-only in this first slice.

6. Failure-path verification
- Invoke the helper with a missing or blocked G3 result and confirm it fails clearly.
- Invoke the live-script G4 helper section without a qualifying G3 result and confirm it shows the blocked summary table instead of calling the helper.
- Invoke the helper with a non-global G3 recommended strategy and confirm it errors with a clear upstream-contract message.
- Invoke the helper with a role swap or sign-flipped correction and confirm the failure is labeled as implementation-suspect rather than scene-limited.

## Assumptions and Defaults

- First-slice maturity target: helper plus live-script analysis section only.
- Standalone G4 runner, artifact bundle, and formal whole-gate G4 decision runner are deferred.
- G4 inherits the current G3-approved correction strategy and does not compare sync strategies itself.
- The only supported upstream sync strategy in this slice is `global_session_correction`.
- The only supported baseline map method in this slice is `ambgfun`.
- The first slice compares only the fixed G3 CPI set and does not run a broad tuning sweep.
- The first slice uses fixed early / center / late spot-check windows per repetition/CPI to strengthen dwell-stability evidence without turning G4 into a sweep study.
- Product semantics are frozen in `BaselineProductDefinition`, but scoring remains tunable and manual-review-oriented while thresholds are still being explored.
- Upstream caveats from G2 and G3 remain explicit in G4 outputs and are not collapsed into a single scene verdict.
- The whole-gate G4 row remains non-implemented placeholder state until the later runner-parity pass.

## Sequential Council Review

The plan above has now been revised using user-approved council guidance. The review notes below are retained as the review record that informed those updates.

### Review Status

- `1.` Passive bistatic radar algorithm expert: completed
- `2.` RF and data-quality expert: completed
- `3.` Signal processing and detection QE expert: completed
- `4.` MATLAB implementation and test architecture expert: completed

The reviews below were run sequentially in the order shown above. They are retained as the recorded review basis for the current plan text above.

### 1. Passive Bistatic Radar Algorithm Expert

1. Critical: The map product definition is still underspecified where it matters most. Relevant files: `G4Plan.md`, `docs/checkpoints/G4_Passive_Baseline_Map.md`.
Mitigation: Freeze a `BaselineProductDefinition` now with exact `ambgfun` call semantics, bin sizes, sign conventions, and a synthetic known-delay / known-Doppler verification case.

2. High: The direct-path plausibility test is partly circular because the plan recenters axes for review and then searches for the direct path in an origin-centered neighborhood. Relevant files: `G4Plan.md`.
Mitigation: Keep raw coordinates separate from display-centered coordinates, report both, and score plausibility against an explicit tolerance window derived from G3 residual bounds plus a fixed hardware / cable offset allowance.

3. High: G4 extrapolates a short-CPI G3 correction decision onto medium and long CPI maps without a stated smear budget. Relevant files: `G4Plan.md`, `G3Plan.md`.
Mitigation: Propagate G3 residual-frequency bounds into an expected phase-drift budget per CPI, and add per-CPI direct-path width and sharpness metrics so long-CPI degradation can be tagged as sync-limited versus map-limited.

4. Medium: The repeatability method is weak for passive maps because pairwise `corr(mapA(:), mapB(:))` on peak-normalized dB maps will be dominated by the direct-path or clutter ridge and is overly sensitive to one-bin misregistration. Relevant files: `G4Plan.md`.
Mitigation: Keep a linear-power or fixed-scale power version for repeatability, report both whole-map and origin-masked correlations, and add either a registration-aware shift metric or a light multi-window bootstrap.

5. Medium: Q2 is under-instrumented for passive-map plausibility because the proposed fields emphasize direct-path amplitude and the zero-delay / zero-Doppler cell, but not clutter-ridge width, direct-path-to-clutter separation, or off-zero-Doppler occupancy. Relevant files: `G4Plan.md`, `G2Plan.md`.
Mitigation: Add at least one clutter-structure metric and one off-origin energy metric, such as zero-Doppler ridge width, direct-path-to-local-clutter ratio, and off-zero-Doppler energy fraction outside an origin mask.

6. Medium: The G4-to-G5/G6 handoff is too thin. A single `RecommendedBaselineCpiLabel` risks becoming a de facto freeze without also freezing the ambiguity-grid definition, normalization rule, exclusion mask around the direct path, and registration rule. Relevant files: `G4Plan.md`, `docs/checkpoints/G6_CPI_Integration.md`, `docs/requirements/RequirementsMatrix.md`.
Mitigation: Return a non-final `BaselineProductDefinition` struct now so downstream gates inherit the same map contract instead of inventing one later.

Sound areas:
- Keeping `ambgfun` as the first oracle and leaving `phased.RangeDopplerResponse` out of scope is the right baseline choice for this slice.
- Inheriting the frozen G3 role mapping and blocking G4 when G3 is not qualifying is sound.
- Keeping the formal G4 gate row placeholder-only in this first slice is reasonable and avoids claiming checkpoint closure too early.

### 2. RF And Data-Quality Expert

1. High: The current plan still risks equating a stable near-origin direct path with a good passive baseline. Relevant files: `G4Plan.md`, `G2Plan.md`.
Mitigation: Add `DirectPathToClutter_dB`, `DirectPathToFloor_dB`, `UsableDynamicRange_dB`, off-zero occupancy, and masked-map repeatability. If only the origin ridge is stable, label the result `scene_limited_direct_path_dominated` rather than baseline-ready.

2. High: Upstream caveats are flattened instead of propagated into G4 outputs. Relevant files: `G4Plan.md`, `G2Plan.md`, `docs/checkpoints/G2Checklist.md`.
Mitigation: Carry forward upstream caveat codes and split G4 interpretation into separate dimensions for upstream validity, scene observability, and implementation confidence.

3. High: The proposed metrics do not clearly separate RF-scene limitations from G4 implementation defects. Relevant files: `G4Plan.md`, `docs/checkpoints/G4_Passive_Baseline_Map.md`, `docs/checkpoints/G3_Sync.md`.
Mitigation: Add pre- and post-correction comparisons, role-swap and sign-flip sanity checks, direct-path delay versus G3 lag consistency, and explicit raw-axis versus display-axis metadata. Emit `implementation_suspect` separately from `scene_limited`.

4. Medium: Full-map correlation on peak-normalized maps will overstate repeatability in a direct-path- or clutter-ridge-dominated scene. Relevant files: `G4Plan.md`, `docs/checkpoints/G4_Passive_Baseline_Map.md`, `G2Plan.md`.
Mitigation: Compute repeatability on both full maps and masked maps with the direct-path neighborhood and zero-Doppler clutter ridge removed, and use the masked score in CPI selection.

5. Medium: One center-aligned window per repetition and CPI is too thin for strong stationarity claims. Relevant files: `G4Plan.md`, `G2Plan.md`.
Mitigation: Add a light early / center / late spot check, or explicitly constrain the interpretation language to `center-window baseline only`.

Sound areas:
- Freezing the first slice to `ambgfun` and the current G3-selected `global_session_correction` is sound and keeps sync retuning out of G4 baseline evaluation.
- Keeping the whole-gate G4 row placeholder-only while returning raw tables and representative maps is sound and preserves reviewability without overstating gate closure.
- Gating G4 on a qualifying G3 result and frozen role mapping is also sound as long as inherited caveats remain explicit.

### 3. Signal Processing And Detection QE Expert

1. High: The ambiguity-map coordinate contract is still underdefined because the plan freezes `ambgfun`, but not the `PRF` derivation, taper or window choice, axis sign convention, or whether recentering is an axis shift or a data shift. Relevant files: `G4Plan.md`, `docs/checkpoints/G4_Passive_Baseline_Map.md`.
Mitigation: Freeze a first-slice coordinate contract before implementation, including deterministic `PRF` per CPI, the exact review-axis transform, fixed delay and Doppler sign conventions, a fixed origin-search radius derived from G3 residual bounds, and a hard fail if the direct-path peak lands outside that neighborhood.

2. High: The CPI recommendation rule is not reproducible enough to defend a frozen downstream baseline. Relevant files: `G4Plan.md`, `runPassiveBistaticPiplineLiveScript.m`.
Mitigation: Use a deterministic lexicographic rule for the first slice. Disqualify CPIs that miss minimum repeatability or coordinate-spread bounds, rank survivors by a declared score, and apply the shortest-CPI tie-break only within a fixed epsilon stored in the comparison table.

3. Medium-High: G4 inherits only the overall G3 verdict, not CPI-specific admissibility. Relevant files: `G4Plan.md`, `G3Plan.md`.
Mitigation: Carry a per-CPI eligibility mask from G3 into G4. If a CPI is below G3 coherence or drift support, either exclude it from `Q4` ranking or force its G4 label to `caveated` or `blocked`.

4. Medium-High: The proposed map metrics are too display-centric to support strong interpretability claims because peak-normalized dB maps make `DirectPathPeak_dB` nearly tautological and whole-map correlation will be dominated by the direct-path or clutter ridge. Relevant files: `G4Plan.md`, `docs/checkpoints/G4_Passive_Baseline_Map.md`.
Mitigation: Keep peak-referenced dB maps for figures only. For scoring, add linear-domain or masked-map diagnostics such as direct-path-to-local-floor ratio, direct-path width and sharpness, and correlation with the direct-path neighborhood excluded.

5. Medium: One center-aligned window per repetition and CPI is too weak to support robust repeatability claims. Relevant files: `G4Plan.md`, `G3Plan.md`.
Mitigation: For this first slice, either downgrade the claim to `center-window repeatability` in the interpretation text or add a minimal sensitivity check with one or two nearby offsets for the selected CPI.

6. Medium: The test plan validates plumbing more than map physics. Relevant files: `G4Plan.md`.
Mitigation: Add three helper-level tests: a synthetic known-lag / known-frequency smoke case, a negative-control case with swapped roles or inverted correction sign that must fail axis plausibility, and a determinism / perturbation test that verifies CPI recommendation stability across reruns.

Sound areas:
- Locking the first baseline to `ambgfun` only is technically sound for a first oracle pass and matches the checkpoint decision.
- Reusing frozen G3 CPI definitions and the current `global_session_correction` handoff is a sensible scope cut for this slice.
- Keeping G4 as helper plus live-script analysis while leaving the gate row placeholder is good QE scoping because it avoids over-claiming gate closure before the metric contract is mature.
- The upstream split is clean because G2 already owns illuminator-band cleanliness and direct-path visibility screening while G4 focuses on map-level plausibility and repeatability.

### 4. MATLAB Implementation And Test Architecture Expert

1. High: The planned `small internal refactor` is not small against the current Stage 3 structure because the reusable sync-preparation logic is not isolated today and MATLAB will force an explicit visibility choice for any shared helper. Relevant files: `G4Plan.md`, `helperAnalyzeG3SyncCore.m`.
Mitigation: Extract exactly one narrow sync-prep helper as a `private` or package-scoped function, keep the existing G3 question-table builders unchanged, and require a baseline G3 regression check proving the Stage 3 outputs stay unchanged before adding G4 behavior.

2. High: The proposed G4 helper contract is under-specified relative to current Stage 3 contracts because `g3SyncResults` in session is runner-shaped output, while the actual applied lag and residual-frequency values that G4 needs are still internal Stage 3 computations. Relevant files: `G4Plan.md`, `runG3SyncCore.m`, `runPassiveBistaticPiplineLiveScript.m`, `helperAnalyzeG3SyncCore.m`.
Mitigation: Treat `g3SyncResults` only as the upstream gate and contract check, and make applied lag and frequency come only from the extracted sync-prep helper. Include the correction-source CPI label and exact applied values in that shared output so G4 reuse is testable.

3. Medium: The verification plan is too shape-based for a map-forming slice because it mostly confirms row counts and field presence and would not catch a wrong delay or Doppler convention, a bad direct-path pick, or a mismatch between applied correction and shared Stage 3 state. Relevant files: `G4Plan.md`, `docs/checkpoints/G4_Passive_Baseline_Map.md`.
Mitigation: Add value-level checks for this first slice, including monotonic and zero-centered axes per the declared convention, map sizes that match axis lengths, direct-path picks that stay inside the intended origin-centered search region, finite and bounded repeatability correlations, and exact equality between G4 applied correction and the shared Stage 3 correction output.

4. Medium: The live-script plan creates real G4 execution without any corresponding gate-state record. That is intentional, but it means a failed or caveated G4 helper run can disappear from pipeline state while G4 still appears placeholder-only at the gate row. Relevant files: `runPassiveBistaticPiplineLiveScript.m`, `G4Plan.md`.
Mitigation: Keep `GateResults(4)` placeholder-only as planned, but make `pipelineResults.G4PassiveBaselineMapResult` carry a minimal execution record on both success and failure, including `StageId`, execution status, and rationale or failure message, so the Live Script has a stable review trace even before runner parity exists.

Sound areas:
- Locking the first slice to the current Stage 3-approved dataset, role mapping, CPI set, and `global_session_correction` is the right scope control.
- Using `ambgfun` as the oracle baseline and keeping `phased.RangeDopplerResponse` out of scope is technically sound for this stage.
- The helper-first plus live-script-section pattern is consistent with the repo's staged G3 rollout, and the question-linked table structure is a good fit for MATLAB review and test workflows.
