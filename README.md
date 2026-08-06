# Passive Bistatic Restart

This repository is an isolated restart of the passive-bistatic acquisition and analysis workflow. The goal is to rebuild the MATLAB analysis gate by gate, keep the evidence and decision logic explicit, and later integrate selected mature work back into `flightTest` without carrying over the older repo context wholesale.

The repo now contains a working single-session baseline review flow for `G1 Ingest`, `G2 Stage 1 Acquisition Evidence`, and `G2 Stage 2 Receiver Integrity`, plus an artifact-only hardware-comparison path for saved G1/G2 outputs. Later gates remain documentation-led or placeholder-only until they are explicitly opened.

## Start Here

- New users should open [runPassiveBistaticPiplineLiveScript.m](runPassiveBistaticPiplineLiveScript.m) in the MATLAB Live Editor first.
- That Live Script is the main single-session walkthrough for the current baseline dataset `20260622T102123`.
- It explains the active question at each implemented gate, runs the current code path, renders inline tables plus the visible G2 and G3 figures, keeps the whole-gate `G3` row as a non-final placeholder, and now follows it with a standalone-runner `G3 Sync Analysis Core` section before the later placeholder gates.
- If you want the hardware-change view after understanding the baseline, open [runPassiveBistaticSessionComparisonLiveScript.m](runPassiveBistaticSessionComparisonLiveScript.m). That Live Script compares saved artifacts only and does not replace the single-session gate review.

## Project Goal

- Re-establish a trusted passive-bistatic analysis workflow from ingest through later tracking, with explicit gate ownership and evidence at each step.
- Keep single-session gate decisions separate from cross-session hardware iteration so dataset and hardware changes do not silently rewrite the baseline review logic.
- Separate three questions whenever possible:
  - is the analysis path technically valid?
  - is the dataset or hardware acquisition good enough for the gate?
  - is the gate formally approved to open the next stage?
- Keep this repo isolated while the workflow is being rebuilt, then move only the mature pieces back into `flightTest` through selective integration.

## Current Progress Snapshot

- `loadIQData` is the stable ingest helper beneath the current gate runners.
- `runG1Ingest` is implemented and acts as the frozen upstream contract for current G2 work.
- `runG2Stage1AcquisitionEvidence` is implemented and manually accepted for progression on the baseline session `20260622T102123`.
- `runG2Stage2ReceiverIntegrity` is implemented and manually reviewed for the baseline session `20260622T102123`. The saved Stage 2 RF outcome remains caveated and diagnostic, but the checklist is now approved for progression to Stage 3 review.
- `helperAnalyzeG3SyncCore` is implemented as the Stage 3 analysis core for the baseline session `20260622T102123`.
- `private/helperPrepareG3SyncInputs.m` now holds the shared internal sync-preparation contract reused by both the Stage 3 helper and the new Stage 4 helper slice.
- `runG3SyncCore` now wraps that helper as the standalone Stage 3 manual-review runner, writes a full Stage 3 artifact bundle, exports three overview figures, and records a `comparison_snapshot.mat` for future comparison use.
- `helperAnalyzeG4PassiveBaselineMap` is implemented as the executable Stage 4 analysis helper for G4 Part 2 due diligence. It reuses the frozen Stage 3 contracts, forms fixed-window `ambgfun` baseline products on the explicit reduced map rate, evaluates the fixed five-CPI G4 sensitivity set, separates direct-path localization from scene observability, and returns the bounded 9-row raw-rate audit using `ambgfun` cut proxies.
- `runG4PassiveBaselineMap` now formalizes that helper into a Stage 4 manual-review runner. It writes `artifacts/<datasetId>/G4_Passive_Baseline_Map/<runTimestampZ>/`, exports CSV review tables, saves `metrics.mat` and `comparison_snapshot.mat`, exports representative-map figures, and keeps the formal G4 gate semantics non-final. The runner and Live Script summary distinguish helper execution status from dataset scene limitation or raw-rate audit caveats so a blocked G4 result is not confused with an analysis crash.
- `verifyG4PassiveBaselineMapSlice` is now available for helper-level G4 verification, including synthetic orientation checks, a direct-path-dominated scene fixture, real-session baseline checks, negative controls, and optional G3 regression against a saved pre-refactor snapshot.
- `helperAnalyzeG5Mitigation`, `runG5Mitigation`, and `verifyG5MitigationSlice` now implement the first G5 mitigation slice. The slice compares `none`, `conservative_lms`, and `aggressive_lms`, uses `dsp.LMSFilter` for LMS candidates, recomputes candidate maps with `ambgfun`, writes the required G5 evidence tables, and treats blocked G4 as diagnostic/manual-review rather than a formal G5 pass.
- `runG1G2SessionComparison` and [runPassiveBistaticSessionComparisonLiveScript.m](runPassiveBistaticSessionComparisonLiveScript.m) are implemented for artifact-only comparison of the baseline session against later hardware variants such as `20260713T150404`.
- `G2` Stage 3 through Stage 5 are not started, and `G6` through `G10` remain placeholder-only in the single-session Live Script. `G5` currently has a helper, runner, and smoke verifier, but the Live Script has not yet been promoted to execute G5 inline. `G4` still follows the early-G3 staged pattern: the whole-gate row stays placeholder-only while a separate `G4 Passive Baseline Analysis Core` section records helper-level execution in `pipelineResults.G4PassiveBaselineMapResult`.

## What We Have Tried and Learned So Far

- We rebuilt the baseline around manifest-driven ingest rather than assuming a raw-IQ contract by inspection.
- We kept `20260622T102123` as the single-session baseline and added `20260713T150404` as a hardware-comparison candidate instead of replacing the baseline session silently.
- We added dataset-local manual acquisition metadata support through `collection_metadata.json` so Stage 1 can recover configuration and role evidence that was not captured automatically by the collection logs.
- We implemented a separate artifact-only comparison path so hardware changes can be reviewed from saved `comparison_snapshot.mat` files without rerunning raw analysis inside the comparison tool.
- The current Stage 2 baseline result is intentionally split:
  - strict RF/legal posture stays caveated, with legal recommendation `retune` and dataset classification recommendation `diagnostic`
  - analysis posture stays usable, with `AnalysisValidity = valid` and `DevelopmentReadiness = unblocked_with_dataset_caveat`
- The key Stage 2 finding so far is that the accepted reference channel is about `9.7 dB` to `10.2 dB` weaker than surveillance across repetitions, while clipping, DC, and IQ/image proxies stay low. The present interpretation is therefore dataset, hardware, gain, geometry, or acquisition limitation rather than immediate evidence that the Stage 2 analysis itself is broken.
- The Stage 2 desktop figure-export path now exports the tiled chart layout directly, so the single-session Live Script no longer stops on `figure_02_receiver_metrics_overview.png` or the later contamination overview export.
- Required acquisition-path improvements for future sessions are captured in [AdjustmentsToAcquisition.md](AdjustmentsToAcquisition.md).
- The acquisition-adjustment package now includes a next-session RF test matrix that treats the weak reference as a reference-path improvement problem first. The default hardware order is a dedicated narrowband directional reference antenna first, a broadband directional comparison second, with the current dipole retained only as a baseline control.

## Files To Read In Order

- [runPassiveBistaticPiplineLiveScript.m](runPassiveBistaticPiplineLiveScript.m): main single-session baseline walkthrough and the best first file for catching up quickly.
- [runPassiveBistaticSessionComparisonLiveScript.m](runPassiveBistaticSessionComparisonLiveScript.m): artifact-only baseline-versus-candidate hardware comparison walkthrough.
- [ProjectPlan.md](ProjectPlan.md): canonical roadmap, gate order, and milestone definitions for the full program.
- [G2Plan.md](G2Plan.md): detailed G2 technical plan, decision boundaries, and council-review context.
- [G3Plan.md](G3Plan.md): detailed Stage 3 synchronization plan, standalone-runner contract, evidence-bundle contract, manual-review model, and G4 handoff expectations.
- [G1thruG3PerformancePlan.md](G1thruG3PerformancePlan.md): focused rescope plan for adding timing/performance instrumentation and analysis-only scaffolding to the implemented G1-G3 runners without adding arbitrary runtime thresholds.
- [G4Plan.md](G4Plan.md): current Stage 4 passive-baseline-map first-slice plan plus appended sequential council review findings and mitigation suggestions.
- [G4Plan_Part2.md](G4Plan_Part2.md): follow-on G4 planning revision based on the first executable helper outputs, including scene-observability due diligence, bounded CPI sensitivity, targeted raw-rate audit scope, binding implementation clarifications, and appended council-review comments.
- [G5Plan.md](G5Plan.md): G5 mitigation comparison plan and first-slice implementation contract. [G6Plan.md](G6Plan.md) and [G7Plan.md](G7Plan.md) remain draft/provisional downstream planning for detector input product freeze and truth alignment.
- [docs/checkpoints/G2Checklist.md](docs/checkpoints/G2Checklist.md): current manual-review status for G2 stages and the formal statement of what is still blocked.
- [AdjustmentsToAcquisition.md](AdjustmentsToAcquisition.md): acquisition and hardware-evidence gaps to fix in future collections, plus the next-session RF test matrix for improving the reference channel without inverting channel purpose blindly.
- [runG1Ingest.m](runG1Ingest.m), [runG2Stage1AcquisitionEvidence.m](runG2Stage1AcquisitionEvidence.m), [runG2Stage2ReceiverIntegrity.m](runG2Stage2ReceiverIntegrity.m), [runG3SyncCore.m](runG3SyncCore.m), [runG4PassiveBaselineMap.m](runG4PassiveBaselineMap.m), and [runG1G2SessionComparison.m](runG1G2SessionComparison.m): batch runners behind the Live Script views.
- [helperAnalyzeG2AcquisitionEvidence.m](helperAnalyzeG2AcquisitionEvidence.m), [helperAnalyzeG2ReceiverIntegrity.m](helperAnalyzeG2ReceiverIntegrity.m), [helperAnalyzeG3SyncCore.m](helperAnalyzeG3SyncCore.m), [helperAnalyzeG4PassiveBaselineMap.m](helperAnalyzeG4PassiveBaselineMap.m), [helperAnalyzeG5Mitigation.m](helperAnalyzeG5Mitigation.m), [verifyG4PassiveBaselineMapSlice.m](verifyG4PassiveBaselineMapSlice.m), and [verifyG5MitigationSlice.m](verifyG5MitigationSlice.m): the current main analysis and helper-level verification entry points for the implemented G2, G3, G4, and G5 helper-slice work.

## Where Outputs Go

- Single-session evidence bundles are written under `artifacts/<datasetId>/...`.
- The comparison workflow writes hardware-comparison bundles under `artifacts/comparisons/<baseline>_vs_<candidate>/...`.
- G1, G2 Stage 1, G2 Stage 2, and G3 Sync Core now also save `comparison_snapshot.mat` so later session comparison can stay artifact-only.

When you revisit the external collection path, see [AdjustmentsToAcquisition.md](AdjustmentsToAcquisition.md) for the Stage 1 acquisition-evidence gaps, the information that should be captured explicitly in future sessions, the next-session RF test matrix for the weak reference channel, and suggestions for how to obtain the missing hardware evidence.

## Reference Dataset

- Session `20260622T102123` is the single-session regression baseline and the planning reference session.
- Session `20260713T150404` is the current hardware comparison candidate with an inline LNA added on the accepted reference-channel path. It is not the default single-session reference.
- The session contains `15` one-second radar captures at `6.144 MHz`.
- The radar data is dual-channel and carries embedded baseband metadata identifying `RF0:RX2` and `RF1:RX2`.
- The session includes an ADS-B truth artifact at `truth/0_20260622_102124_adsb_20260622T102123.txt.gz`.
- Processing is manifest driven through `20260622T102123/session_manifest.json`, with embedded radar-header timing metadata used as a second timing source.
- The baseline currently carries a strict Stage 2 dataset classification of `diagnostic`. The single-session Live Script now reports a separate development-readiness status so dataset limitations are not confused with analysis failures.

## Approved Documentation Set

- [ProjectPlan.md](ProjectPlan.md) is the canonical roadmap and document index.
- [G2Plan.md](G2Plan.md) is the integrated working plan for G2 RF-health implementation, collection-validity and aircraft-analysis readiness decisions, and the follow-on butterfly communication artifacts.
- [G3Plan.md](G3Plan.md) is the integrated working plan for the current Stage 3 sync-analysis core, standalone manual-review runner, artifact bundle, and non-final gate-recording model.
- [G4Plan.md](G4Plan.md) is the current working plan for the first Stage 4 passive-baseline-map helper slice and includes the recorded sequential council review appended after the plan.
- [G4Plan_Part2.md](G4Plan_Part2.md) is the follow-on working plan for the next G4 due-diligence slice after the first executable helper review and now includes binding implementation clarifications plus the appended council-review record.
- [G5Plan.md](G5Plan.md) is the working plan for the implemented first G5 mitigation slice. [G6Plan.md](G6Plan.md) and [G7Plan.md](G7Plan.md) remain draft/provisional downstream plans for CPI/integration freeze and truth alignment.
- [docs/checkpoints/G2Checklist.md](docs/checkpoints/G2Checklist.md) tracks the phase-by-phase G2 implementation and manual-review status for the customer-flow stages.
- [docs/checkpoints/](docs/checkpoints/) defines the ten pass/retune/reject checkpoints from ingest through tracking truth validation.
- [docs/requirements/](docs/requirements/) defines requirement IDs, dataset registry state, and reopen rules.
- [docs/testing/](docs/testing/) defines the future MATLAB QE architecture, evidence bundle contract, and separation between CI-gated testing and exploratory tuning.
- [docs/flowcharts/PipelineFlowchart.md](docs/flowcharts/PipelineFlowchart.md) provides the pipeline flowchart source aligned to the written plan.
- [docs/flowcharts/G2_RF_Health_Butterfly.md](docs/flowcharts/G2_RF_Health_Butterfly.md) is the source of truth for the G2 butterfly communication assets and includes a simplified dark-mode-friendly Mermaid flowchart for VS Code preview.
- [docs/flowcharts/G2_RF_Health_CustomerFlow.md](docs/flowcharts/G2_RF_Health_CustomerFlow.md) is the source of truth for the customer-facing G2 WHY/HOW/decision flowchart and includes a Mermaid preview.
- [docs/decision-log/DecisionLogTemplate.md](docs/decision-log/DecisionLogTemplate.md) defines how later implementation turns should record parameter baselines and gate decisions.

## Generated PowerPoint

- The editable PowerPoint deck is generated from [docs/flowcharts/PipelineFlowchart.md](docs/flowcharts/PipelineFlowchart.md).
- Run `generatePipelineFlowchartPpt` from MATLAB at the repo root to regenerate the deck.
- The generator writes `artifacts/ppt/PipelineFlowchart.pptx`.
- The G2 butterfly communication assets are generated from [docs/flowcharts/G2_RF_Health_Butterfly.md](docs/flowcharts/G2_RF_Health_Butterfly.md).
- Run `generateG2RFHealthButterflyPpt` from MATLAB at the repo root to regenerate the editable G2 butterfly slide deck and PNG.
- The G2 butterfly generator writes `artifacts/communication/G2_RF_Health/G2_RF_Health_Butterfly.pptx` and `artifacts/communication/G2_RF_Health/G2_RF_Health_Butterfly.png`.
- The customer-facing G2 flow assets are generated from [docs/flowcharts/G2_RF_Health_CustomerFlow.md](docs/flowcharts/G2_RF_Health_CustomerFlow.md).
- Run `generateG2RFHealthCustomerFlowPpt` from MATLAB at the repo root to regenerate the editable customer-facing G2 deck and PNG.
- The customer-facing generator writes `artifacts/communication/G2_RF_Health/G2_RF_Health_CustomerFlow.pptx` and `artifacts/communication/G2_RF_Health/G2_RF_Health_CustomerFlow.png`.
- The generator uses MATLAB on Windows plus Microsoft PowerPoint through COM automation, because that path produces an editable slide rather than a pasted screenshot.

## MATLAB Entry Points

- Run `sessionData = loadIQData;` from MATLAB at the repo root to load the reference dataset `20260622T102123` into a reusable manifest-driven session struct. By default this returns the decoded IQ samples for each repetition plus the embedded metadata, timing model, channel contract, and CPI contract.
- Run `sessionData = loadIQData("20260622T102123", pwd, struct("IncludeSamples", false));` when you want the same manifest-driven decode and contract information without retaining the full IQ matrices in memory.
- `loadIQData` attempts the native `comm.BasebandFileReader` path first for `comm.BasebandFileWriter` captures. If that reader is unavailable because of Communications Toolbox licensing or toolbox availability, it falls back to a calibrated raw `fread` decode for this dataset and records the exact reason in the returned contract struct and the G1 evidence bundle.
- Run `results = runG1Ingest;` to execute the G1 ingest gate on the reference dataset. This gate-validation runner uses `loadIQData` internally, freezes the G1 decode, timing, seam, and CPI segmentation contracts, and writes a full evidence bundle to `artifacts/20260622T102123/G1_Ingest/<runTimestampZ>/`.
- Run `results = runG2Stage1AcquisitionEvidence;` to execute the current standalone Stage 1 G2 manual-review slice. This is not the final `runG2RFHealth` gate runner; it writes Stage 1 acquisition-evidence artifacts to `artifacts/20260622T102123/G2_RF_Health_Stage1_AcquisitionEvidence/<runTimestampZ>/`.
- Run `results = runG2Stage2ReceiverIntegrity;` to execute the current standalone Stage 2 G2 manual-review slice. This Stage 2 runner uses the accepted Stage 1 channel-role mapping when available, shows the generated plots during desktop MATLAB runs by default, and writes receiver-integrity artifacts to `artifacts/20260622T102123/G2_RF_Health_Stage2_ReceiverIntegrity/<runTimestampZ>/`. Pass `struct("ShowFigures", false)` as the third argument when you want to suppress figure display. The returned result struct and saved bundle now separate the strict RF verdict from `AnalysisValidity` and `DevelopmentReadiness`.
- Run `results = runG3SyncCore("20260622T102123", pwd, struct("ShowFigures", false));` to execute the current standalone Stage 3 manual-review runner. This runner keeps the accepted Stage 2 role mapping fixed at `RF1:RX2` reference and `RF0:RX2` surveillance, evaluates non-overlapping `short`, `medium`, and `long` CPI windows of `153600`, `307200`, and `614400` samples, writes a full Stage 3 bundle to `artifacts/20260622T102123/G3_Sync_Core/<runTimestampZ>/`, and returns the question-linked tables plus the non-final `ready` / `caveated` / `blocked` interpretation contract. Pass `struct("ShowFigures", true)` when you want the three overview figures visible during the run.
- `helperAnalyzeG3SyncCore` remains the Stage 3 analysis core beneath `runG3SyncCore`. Use it directly only when you explicitly want the raw helper contract without bundle writing or figure export.
- Run `results = runG4PassiveBaselineMap("20260622T102123", pwd, struct("ShowFigures", false));` to execute the current Stage 4 manual-review runner. The runner recomputes or consumes a qualifying G3 result, calls `helperAnalyzeG4PassiveBaselineMap`, writes a G4 evidence bundle, saves `metrics.mat` plus `comparison_snapshot.mat`, and returns the helper analysis in `results.Analysis`. It keeps the accepted `RF1:RX2` reference and `RF0:RX2` surveillance mapping fixed, reuses the G3 `global_session_correction` contract, evaluates fixed early / center / late windows across `short`, `short_mid`, `medium`, `medium_long`, and `long` G4 sensitivity CPIs, reports `MapRateMode`, `MapDecimationFactor`, and `MapSampleRateHz`, returns scene-first map/repeatability/CPI-selection tables plus a 9-row `FullRateAuditSummaryTable` using the bounded `ambgfun_cut_proxy` raw-rate audit method, and does not freeze the final downstream CPI.
- Run `analysis = helperAnalyzeG4PassiveBaselineMap(sessionData, collectionMetadataInfo, g3SyncResults);` only when you explicitly want the raw helper contract without bundle writing or figure export.
- Run `verification = verifyG4PassiveBaselineMapSlice("20260622T102123", pwd);` to execute the helper-level G4 verification workflow. The optional flags `RunG3Regression`, `RunSyntheticOrientation`, `RunBaselineExecution`, and `RunNegativeControls` let you split the expensive checks into smaller runs when needed.
- Run `results = runG5Mitigation("20260622T102123", pwd, struct("ShowFigures", false));` to execute the first G5 mitigation manual-review runner. The runner recomputes or consumes a qualifying G3/G4 result, compares `none`, `conservative_lms`, and `aggressive_lms`, writes `artifacts/<datasetId>/G5_Mitigation/<runTimestampZ>/`, and keeps blocked G4 evidence diagnostic/manual-review rather than promoting mitigation to formal G5 success.
- Run `analysis = helperAnalyzeG5Mitigation(sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis);` only when you explicitly want the raw G5 helper contract without bundle writing or figure export.
- Run `verification = verifyG5MitigationSlice;` to execute the bounded synthetic G5 smoke verification workflow.
- The G1, G2 Stage 1, G2 Stage 2, and G3 runners now also write a lightweight `comparison_snapshot.mat` file into each successful bundle. The comparison workflow consumes those saved snapshots only and does not rerun raw analysis.
- `runG2Stage1AcquisitionEvidence` now follows the same display pattern as Stage 2: in desktop MATLAB it shows the generated figures by default and still exports the PNG artifacts. Pass `struct("ShowFigures", false)` as the third argument when you want export-only behavior.
- When present, the Stage 1 runner also consumes a dataset-local sidecar file such as `20260622T102123/collection_metadata.json` for manual antenna, geometry, and acquisition-note evidence that was not captured automatically by the system logs.
- Run `comparisonResults = runG1G2SessionComparison("20260622T102123", "20260713T150404", pwd, struct("ShowFigures", true));` to compare the latest saved G1, G2 Stage 1, and G2 Stage 2 snapshots from the baseline and candidate sessions. This runner is artifact-only, fails clearly if a required snapshot is missing, and writes its bundle to `artifacts/comparisons/20260622T102123_vs_20260713T150404/<runTimestampZ>/`.
- Open `runPassiveBistaticPiplineLiveScript.m` in the MATLAB Live Editor and run the sections in order to use the current single-session baseline review script. The script includes per-section narrative text covering the question, current MATLAB-native approach, a computed G1 `gain_spec` ordering note derived from the current dataset metadata, a G1 manifest/acquisition-context summary with explicit `RF0 -> Surveillance` and `RF1 -> Reference` role rows plus the decoded gain-order mapping, inline summary tables for G1 and the implemented G2 Stage 1 and Stage 2 manual-review slices, a split G3 presentation that keeps the whole-gate row non-final while the `G3 Sync Analysis Core` section runs the sync helper, and now a separate `G4 Passive Baseline Analysis Core` section that runs `runG4PassiveBaselineMap`, records the helper result in `pipelineResults.G4PassiveBaselineMapResult`, records the runner bundle root, and still leaves `GateResults(4)` placeholder-only. The G4 review summary includes `AnalysisExecutionAssessment` and `LimitationSourceLabel` to separate successful helper execution from dataset scene limitation or raw-rate audit disagreement.
- Open `runPassiveBistaticSessionComparisonLiveScript.m` in the MATLAB Live Editor when you want the separate hardware-change comparison view. That script keeps the baseline/candidate fields at the top, shows the artifact-only comparison tables inline, and relies on `runG1G2SessionComparison` for the visible Stage 2 comparison figures.
- When `runPassiveBistaticPiplineLiveScript.m` is run in desktop MATLAB, it explicitly requests visible G2 stage figures. G1 text summaries continue to render inline as tables in the Live Editor while the PNG evidence artifacts are still exported in the background.
- The full `G2_RF_Health` gate in `runPassiveBistaticPiplineLiveScript.m` remains non-final on purpose. The single-session live script keeps the whole-gate status as a placeholder while separately running the implemented `runG2Stage1AcquisitionEvidence` and `runG2Stage2ReceiverIntegrity` sections for manual review.
- When the Stage 2 RF verdict is dataset-limited but analytically trustworthy, the single-session Live Script now reports that downstream development can remain unblocked under caveat. That development status does not formally open Stage 3 or change the checklist approval state.
- The superseded top-level runner `runPassiveBistaticPipeline.m` has been moved to `archive/runPassiveBistaticPipeline.m` to reduce confusion at the repo root.
- The pipeline live script auto-resolves the real repo root, so it still works when the Live Editor executes from a temporary editor copy.
- After the live script runs, inspect `pipelineResults` for the overall pipeline state, `pipelineResults.G3SyncResult` for the recorded Stage 3 manual-review result and bundle path, and `g2Stage1Results`, `g2Stage2Results`, and `g3SyncResults` for the detailed outputs from the implemented sections.
- After the comparison live script or comparison runner runs, inspect `comparisonResults` for the overall summary table, the per-stage comparison tables, and the comparison bundle root.
- A later customer-facing live script is still planned. That script should call stable helper APIs such as `loadIQData` and later helper-level gate functions rather than the gate-validation runners.

## Working Intent

Later implementation should follow the sequence and constraints captured in the planning package:

- `G1 Ingest` treats one-second IQ duration separately from wall-clock repetition spacing and documents the `comm.BasebandFileWriter` capture provenance
- synchronization is an explicit gate, not an assumed property of a strong direct path
- `ambgfun` is the passive-map baseline oracle
- `phased.RangeDopplerResponse` is a later equivalence or optimization path
- `dsp.LMSFilter` is only a mitigation baseline candidate
- truth alignment must be available before detector tuning is considered stable
- validated detection is the first milestone that unlocks tracking work

## Expert Note

This document was derived from a council-based planning review using these expert roles: passive bistatic radar algorithm expert, RF/data-quality expert, signal processing and detection QE expert, requirements and V&V expert, MATLAB test architecture expert, tracking metrics/V&V expert, and systems/customer-communication review inputs.

## Repository Boundary

`PassiveBistaticRestart` is intentionally kept as a standalone development repository rather than being developed directly inside `flightTest`.

- Keep MATLAB source, planning documents, manifests, and manually curated sidecar metadata under version control here.
- Keep generated artifacts, temporary editor state, and large raw radar captures out of git for this repo.
- Treat this repo as the isolated design and review space for the passive-bistatic restart effort, not as the long-term system-of-record for flight-test integration.

## Future Integration Back Into `flightTest`

To limit merge friction later, use this repo as a clean commit source rather than trying to merge the repositories wholesale.

- Keep commits small and single-purpose so they can be cherry-picked into `flightTest` one change at a time.
- Avoid mixing structural renames, formatting-only edits, and algorithm changes in the same commit.
- Keep function names, folder names, and artifact contracts as close as practical to the eventual `flightTest` landing zone.
- When integration starts, create a dedicated `flightTest` integration branch, add this repository as a temporary remote, and cherry-pick the selected commits that should land there.
- If a change needs review outside of git history transfer, use `git format-patch` from this repo and `git am` in `flightTest` as the fallback path.
