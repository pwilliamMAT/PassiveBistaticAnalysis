# Passive Bistatic Restart

This repository now contains an initial MATLAB implementation for `G1 Ingest` plus the planning and checkpoint documentation for later gates. The approved technical direction, checkpoint structure, and QE rules are captured in the Markdown and Mermaid documents in this repo, while later gates remain to be added incrementally.

When you revisit the external collection path, see [AdjustmentsToAcquisition.md](AdjustmentsToAcquisition.md) for the Stage 1 acquisition-evidence gaps, the information that should be captured explicitly in future sessions, and suggestions for how to obtain it.

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
- The G1, G2 Stage 1, and G2 Stage 2 runners now also write a lightweight `comparison_snapshot.mat` file into each successful bundle. The comparison workflow consumes those saved snapshots only and does not rerun raw analysis.
- `runG2Stage1AcquisitionEvidence` now follows the same display pattern as Stage 2: in desktop MATLAB it shows the generated figures by default and still exports the PNG artifacts. Pass `struct("ShowFigures", false)` as the third argument when you want export-only behavior.
- When present, the Stage 1 runner also consumes a dataset-local sidecar file such as `20260622T102123/collection_metadata.json` for manual antenna, geometry, and acquisition-note evidence that was not captured automatically by the system logs.
- Run `comparisonResults = runG1G2SessionComparison("20260622T102123", "20260713T150404", pwd, struct("ShowFigures", true));` to compare the latest saved G1, G2 Stage 1, and G2 Stage 2 snapshots from the baseline and candidate sessions. This runner is artifact-only, fails clearly if a required snapshot is missing, and writes its bundle to `artifacts/comparisons/20260622T102123_vs_20260713T150404/<runTimestampZ>/`.
- Open `runPassiveBistaticPiplineLiveScript.m` in the MATLAB Live Editor and run the sections in order to use the current single-session baseline review script. The script includes per-section narrative text covering the question, current MATLAB-native approach, a computed G1 `gain_spec` ordering note derived from the current dataset metadata, a G1 manifest/acquisition-context summary with explicit `RF0 -> Surveillance` and `RF1 -> Reference` role rows plus the decoded gain-order mapping, and inline summary tables for G1 and the implemented G2 Stage 1 and Stage 2 manual-review slices. The Stage 2 section now also explains what was measured, why the whole-band role-power ordering matters, how to interpret clean clipping/DC/IQ metrics alongside a weak reference channel, why `DevelopmentReadiness = unblocked_with_dataset_caveat` is different from a formal Stage 2 approval, and how Figure 2 / Figure 3 map to the Stage 2 equations and thresholds.
- Open `runPassiveBistaticSessionComparisonLiveScript.m` in the MATLAB Live Editor when you want the separate hardware-change comparison view. That script keeps the baseline/candidate fields at the top, shows the artifact-only comparison tables inline, and relies on `runG1G2SessionComparison` for the visible Stage 2 comparison figures.
- When `runPassiveBistaticPiplineLiveScript.m` is run in desktop MATLAB, it explicitly requests visible G2 stage figures. G1 text summaries continue to render inline as tables in the Live Editor while the PNG evidence artifacts are still exported in the background.
- The full `G2_RF_Health` gate in `runPassiveBistaticPiplineLiveScript.m` remains non-final on purpose. The single-session live script keeps the whole-gate status as a placeholder while separately running the implemented `runG2Stage1AcquisitionEvidence` and `runG2Stage2ReceiverIntegrity` sections for manual review.
- When the Stage 2 RF verdict is dataset-limited but analytically trustworthy, the single-session Live Script now reports that downstream development can remain unblocked under caveat. That development status does not formally open Stage 3 or change the checklist approval state.
- The superseded top-level runner `runPassiveBistaticPipeline.m` has been moved to `archive/runPassiveBistaticPipeline.m` to reduce confusion at the repo root.
- The pipeline live script auto-resolves the real repo root, so it still works when the Live Editor executes from a temporary editor copy.
- After the live script runs, inspect `pipelineResults` for the overall pipeline state, and inspect `g2Stage1Results` and `g2Stage2Results` for the detailed manual-review outputs from the implemented G2 slices.
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
