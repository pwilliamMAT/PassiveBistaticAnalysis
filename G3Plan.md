# G3 Plan

## Summary

This document captures the current Stage 3 synchronization plan and execution method for `G3_Sync`. It is intended to sit beneath [ProjectPlan.md](ProjectPlan.md) and [docs/checkpoints/G3_Sync.md](docs/checkpoints/G3_Sync.md), and to mirror the same single-session manual-review runner pattern already used by `runG2Stage1AcquisitionEvidence` and `runG2Stage2ReceiverIntegrity`.

This is not a raw transcript of a planning conversation. It is the durable external-review version of the Stage 3 plan reconstructed from the implemented runner-parity work and the current repository state.

The current Stage 3 implementation now has:

- a helper-level sync-analysis core in `helperAnalyzeG3SyncCore`
- a standalone Stage 3 manual-review runner in `runG3SyncCore`
- a full Stage 3 evidence bundle written under `artifacts/<datasetId>/G3_Sync_Core/<runTimestampZ>/`
- live-script integration through `runPassiveBistaticPiplineLiveScript.m`

The current G3 slice remains intentionally non-final. It emits manual-review labels `ready`, `caveated`, and `blocked`, records `manual_review_executed` and `manual_review_nonfinal` in the live script, and does not yet replace the formal checkpoint acceptance logic in [docs/checkpoints/G3_Sync.md](docs/checkpoints/G3_Sync.md).

## Frozen Upstream Inputs

G3 must inherit the latest accepted G1 and G2 contracts without reinterpretation:

- approved baseline dataset: `20260622T102123`
- one file equals one repetition
- repetition count: `15`
- decoded shape per file: `[6144000 x 2]` complex `int16`
- frozen sample rate: `6.144 MHz`
- approved role mapping inherited from G2 Stage 2:
  - reference = `RF1:RX2`
  - surveillance = `RF0:RX2`
- approved low-level data access beneath G3:
  - `loadIQData(datasetId, repoRoot, struct("IncludeSamples", true))`
- approved collection metadata input:
  - `<datasetId>/collection_metadata.json`

If proposed G3 work requires reopening G1 timing authority, redefining the per-file repetition contract, or changing the accepted G2 role mapping, that is not a G3 retune. It reopens G1 or G2.

## Scope and Gate Ownership

G3 owns synchronization and coherence readiness between frozen RF health and later passive-map formation.

The current Stage 3 plan is limited to:

- lag estimation stability across all `15` captures
- residual frequency and phase-drift stability across candidate CPI windows
- coherence usability across fixed CPI definitions
- correction-strategy comparison across global-session, per-capture, and subwindow candidates
- manual-review export and evidence-bundle writing for the implemented sync-analysis core

The current Stage 3 plan explicitly does not yet claim:

- a final formal `pass / retune / reject` whole-gate runner
- a completed G3 checkpoint closure decision
- ownership of G4 passive-map plausibility
- ownership of cross-session G3 comparison review

## Native Function Audit

### Workflow Audit

| Proposed Workflow | Native MATLAB Documentation Example Analogue | Updates needed to fit current goal |
| :--- | :--- | :--- |
| Standalone Stage 3 manual-review runner with bundle writing | Live scripts and functions, `writetable`, `save`, `jsonencode`, `exportgraphics` | Add a G3 runner that mirrors the current G2 runner pattern and writes artifacts under `artifacts/<datasetId>/G3_Sync_Core/<runTimestampZ>/` |
| Lag, residual-frequency, and coherence review on frozen contracts | `finddelay`, `xcorr`, `spectrogram`, `mscohere` | Reuse `helperAnalyzeG3SyncCore` as the analysis core and expose its outputs through a runner-shaped result contract |
| Exported summary figures for manual review | `figure`, `tiledlayout`, `nexttile`, `exportgraphics` | Add a fixed three-figure Stage 3 overview set and export it as PNG artifacts, with visible figures in desktop MATLAB when requested |
| Live-script integration for single-session review | MATLAB Live Editor sections plus function calls | Replace the direct helper call with `runG3SyncCore` while keeping the whole-gate `G3` row non-final |

### Function Audit

| Proposed Feature / Algorithm | Native MATLAB Function/Toolbox Equivalent | Documentation Syntax Template Used |
| :--- | :--- | :--- |
| Standalone runner entry point | MATLAB function with arguments block | `results = runG3SyncCore(datasetId, repoRoot, options)` |
| Summary and raw table artifact writing | `writetable` | `writetable(tableValue, csvPath)` |
| Metrics persistence | `save`, `jsonencode` | `save(metricsMatPath, "analysis")` |
| Manual-review figure export | `exportgraphics` | `exportgraphics(layoutHandle, figurePath)` |
| Lag and delay observables | `finddelay`, `xcorr` | `d = finddelay(x, y, maxlag)` |
| Residual frequency and phase-drift estimation | `spectrogram` and derived phase-fit measurements | `[s, f, t] = spectrogram(x, win, noverlap, nfft, Fs)` |
| CPI coherence estimation | `mscohere` | `[cxy, f] = mscohere(x, y, win, noverlap, nfft, Fs)` |
| Comparison snapshot persistence | existing repo helper `helperWriteComparisonSnapshot` built on `save` | `snapshotPath = helperWriteComparisonSnapshot(bundleRoot, comparisonSnapshot)` |

If a native MATLAB function covers the need, the implementation should use that function rather than custom math utilities or manual matrix reconstruction.

## Requirement IDs in Scope

- `SYN-001` lag estimation stability
- `SYN-002` residual frequency-offset stability
- `SYN-003` correction-strategy stability

## Current Stage 3 Questions

| Question ID | Stage 3 question | Primary observables | Primary output artifact |
| :--- | :--- | :--- | :--- |
| `Q1` | Can we estimate a repeatable lag between reference and surveillance for each repetition? | `finddelay` lag, `xcorr` peak lag, peak-to-sidelobe sharpness, delay-estimate agreement | `lag_table.csv` |
| `Q2` | Is residual frequency or phase drift small enough to support a consistent correction model? | residual-frequency estimate, phase excursion, phase-fit RMSE | `residual_frequency_table.csv` |
| `Q3` | Are candidate CPI windows coherently usable, or does coherence collapse at the window sizes we care about? | band-mean coherence, coherence percentile spread, coherence pass fraction by CPI | `cpi_coherence_table.csv` |
| `Q4` | Which correction strategy is most defensible for downstream use? | short-CPI lag residuals, short-CPI phase residuals, observable pass fraction, simplicity-first margin rule | `strategy_comparison_table.csv` |

## Technical Implementation Plan

### Architecture and Code Layers

Preserve the same three-layer split already established by the repo:

- helper-level Stage 3 analysis API:
  `helperAnalyzeG3SyncCore(sessionData, collectionMetadataInfo, options)`
- single-session manual-review runner:
  `runG3SyncCore(datasetId, repoRoot, options)`
- live-script orchestration:
  `runPassiveBistaticPiplineLiveScript.m`

The full formal whole-gate G3 acceptance path remains separate from the current analysis-core runner.

### Helper-Level Analysis Core

`helperAnalyzeG3SyncCore` remains the core Stage 3 analysis contract.

It must:

- validate the frozen dataset and role-mapping assumptions
- enforce the accepted baseline reference/surveillance mapping
- build per-window observations across fixed CPI definitions
- return question-linked tables rather than a single opaque score
- emit an interpretation struct with:
  - `OverallLabel`
  - `OverallRationale`
  - `ReferenceLabel`
  - `SurveillanceLabel`
  - `RecommendedStrategyCandidate`
  - `BlockingFindings`

### Standalone Runner Contract

`runG3SyncCore` is the Stage 3 standalone manual-review entry point.

Runner contract:

- signature:
  - `results = runG3SyncCore(datasetId, repoRoot, options)`
- defaults:
  - `datasetId = "20260622T102123"`
  - `repoRoot = helperResolveRepoRoot(...)`
  - `options = struct()`
- runner-only option:
  - `ShowFigures`
- all other option fields pass through to `helperAnalyzeG3SyncCore`

Runner behavior:

- resolve the repo root and build `runTimestampZ`
- create the bundle root:
  - `artifacts/<datasetId>/G3_Sync_Core/<runTimestampZ>/`
- load session data with `IncludeSamples = true`
- read `collection_metadata.json`
- run `helperAnalyzeG3SyncCore`
- write the Stage 3 evidence bundle
- write `comparison_snapshot.mat` for future comparison use
- return a top-level results struct shaped for manual review
- on failure:
  - write a failure bundle
  - write `failure_cause.txt`
  - rethrow the error

### Stage 3 Evidence Bundle Contract

Successful Stage 3 bundles should contain:

- `summary.md`
- `sync_interpretation_note.md`
- `question_summaries.csv`
- `lag_table.csv`
- `residual_frequency_table.csv`
- `cpi_coherence_table.csv`
- `strategy_comparison_table.csv`
- `cpi_definitions.csv`
- `interpretation_summary.csv`
- `blocking_findings.csv` when nonempty
- `config_snapshot.json`
- `metrics.json`
- `metrics.mat`
- `comparison_snapshot.mat`
- `figures/figure_01_lag_stability_overview.png`
- `figures/figure_02_residual_frequency_overview.png`
- `figures/figure_03_coherence_and_strategy_overview.png`

Failure bundles should contain at minimum:

- `summary.md`
- `failure_cause.txt`

### Result Struct Contract

`runG3SyncCore` should return a manual-review result struct with these fields:

- `DatasetId`
- `StageId`
- `RunTimestampZ`
- `BundleRoot`
- `OverallLabel`
- `OverallRationale`
- `RecommendedStrategyCandidate`
- `ReferenceLabel`
- `SurveillanceLabel`
- `BlockingFindings`
- `QuestionSummaries`
- `LagTable`
- `ResidualFrequencyTable`
- `CpiCoherenceTable`
- `StrategyComparisonTable`
- `Interpretation`
- `Metrics`
- `Options`
- `FigurePaths`
- `ComparisonSnapshotPath`

### Decision Semantics

Current Stage 3 analysis semantics remain:

- `ready`
- `caveated`
- `blocked`

Current live-script recording semantics remain:

- `ExecutionStatus = manual_review_executed`
- `Decision = manual_review_nonfinal`

The current Stage 3 implementation intentionally does not yet add final formal `pass / retune / reject` logic.

### Fixed CPI Definitions

The current G3 implementation uses fixed non-overlapping CPI definitions:

| CPI label | Duration | Sample count | Current intent |
| :--- | :--- | :--- | :--- |
| `short` | `0.025 s` | `153600` | strategy-comparison anchor and fine sync review |
| `medium` | `0.050 s` | `307200` | intermediate coherence and drift review |
| `long` | `0.100 s` | `614400` | longest current coherent review window |

### Manual-Review Figure Set

Current figure scope is intentionally fixed at three overview figures.

Figure 1: lag stability overview

- lag median and lag spread across repetitions by CPI label
- delay-estimate agreement fraction across repetitions by CPI label
- correlation peak-to-sidelobe behavior across repetitions by CPI label

Figure 2: residual-frequency overview

- residual-frequency median and maximum across repetitions by CPI label
- phase excursion median and maximum across repetitions by CPI label
- phase-fit RMSE median and maximum across repetitions by CPI label

Figure 3: coherence and strategy overview

- coherence median and P10 across repetitions by CPI label
- coherence pass fraction across repetitions by CPI label
- strategy pass fraction across correction candidates
- strategy residual summaries for global-session, per-capture, and subwindow candidates

All figures must:

- explicitly call `figure`
- use `tiledlayout`
- provide explicit `xlabel`, `ylabel`, and descriptive `title`
- manage `hold on` and `hold off` cleanly
- export through `exportgraphics`
- remain visible in desktop MATLAB when `ShowFigures = true`

### Live-Script Integration

The current live-script integration path is:

- keep the whole-gate `## G3 Sync` row as a non-final placeholder
- keep `localRunG3SyncGate` as the controlled whole-gate placeholder state
- in `## G3 Sync Analysis Core`, call:
  - `runG3SyncCore(datasetId, repoRoot, struct("ShowFigures", true))`
- keep the existing G2 downstream-readiness gate before G3 is invoked
- display compact G3 summary tables from the runner output
- preserve `localRecordG3SyncResults` label mapping from:
  - `ready` to `ready_for_gate_progression`
  - `caveated` to `unblocked_with_dataset_caveat`
  - `blocked` to `blocked`

The current live-script record for G3 must continue to show:

- `Implemented = true`
- `ExecutionStatus = manual_review_executed`
- `Decision = manual_review_nonfinal`

### Comparison Snapshot and Future Cross-Session Use

Stage 3 now writes `comparison_snapshot.mat` so later cross-session comparison can include G3 if the comparison workflow is expanded.

That snapshot is current-future infrastructure only. The current `runG1G2SessionComparison` workflow is not yet extended to consume Stage 3 snapshots.

## Deferred Full-Gate Items

The current Stage 3 plan deliberately defers:

- a completed whole-gate G3 runner aligned to [docs/checkpoints/G3_Sync.md](docs/checkpoints/G3_Sync.md)
- a final formal `pass / retune / reject` G3 decision
- any rewrite of the checkpoint’s retune and reject rules
- any attempt to prove G4 passive-map plausibility
- any change to the current G4 readiness semantics

## Baseline Execution Method

### Standalone Runner

Run the standalone Stage 3 manual-review runner from MATLAB at the repo root:

```matlab
results = runG3SyncCore("20260622T102123", pwd, struct("ShowFigures", false));
```

Use visible figures when manual review should include live desktop plots:

```matlab
results = runG3SyncCore("20260622T102123", pwd, struct("ShowFigures", true));
```

### Live Script

Open [runPassiveBistaticPiplineLiveScript.m](runPassiveBistaticPiplineLiveScript.m) in the MATLAB Live Editor and run the sections in order.

The Stage 3 section should:

- keep the whole-gate `G3_Sync` row non-final
- execute the `G3 Sync Analysis Core` section through `runG3SyncCore`
- store the recorded result in `pipelineResults.G3SyncResult`
- update the G3 gate row bundle path from the runner output

## Manual Review Checklist

Before treating Stage 3 as ready for downstream G4 implementation work, the reviewer should confirm:

1. `summary.md` and `sync_interpretation_note.md` are internally consistent.
2. `question_summaries.csv` shows all four Stage 3 questions with acceptable labels.
3. `strategy_comparison_table.csv` supports the recommended correction candidate.
4. The fixed role mapping remains `RF1:RX2` reference and `RF0:RX2` surveillance.
5. The three exported figures match the table-level interpretation and do not hide unstable subsets.
6. Any `blocking_findings.csv` output is either empty or explicitly accepted.
7. The review remains recorded as non-final until the formal whole-gate G3 closure path exists.

## Stage 4 Handoff

The current Stage 3 slice is sufficient to open Stage 4 implementation work when:

- G2 Stage 2 remains analytically valid for downstream development
- the Stage 3 manual-review output is `ready` or an accepted `caveated`
- the reviewer accepts the exported evidence bundle and recommended correction strategy

That does not mean G3 is formally closed. It means G4 implementation may begin under the current non-final manual-review model.

The present baseline expectation is:

- `OverallLabel = ready`
- `RecommendedStrategyCandidate = global_session_correction`
- `NextGate = G4_Passive_Baseline_Map` in the live script when G3 is `ready` or `caveated`

## Verification Plan

### Runner Verification

- run:
  - `results = runG3SyncCore("20260622T102123", pwd, struct("ShowFigures", false));`
- confirm the bundle root exists under:
  - `artifacts/20260622T102123/G3_Sync_Core/<runTimestampZ>/`
- confirm `question_summaries.csv` has `4` rows
- confirm `strategy_comparison_table.csv` has `3` rows
- confirm `lag_table.csv`, `residual_frequency_table.csv`, and `cpi_coherence_table.csv` each have `45` rows
- confirm `results.OverallLabel` is `ready` on the current baseline dataset
- confirm `results.RecommendedStrategyCandidate` is populated
- confirm `comparison_snapshot.mat` is written

### Figure and Export Verification

- run:
  - `results = runG3SyncCore("20260622T102123", pwd, struct("ShowFigures", true));`
- confirm all `3` PNG figures are exported
- confirm no figure-export failure occurs in desktop MATLAB

### Live-Script Verification

- run the live script through G1, G2 Stage 1, G2 Stage 2, the G3 gate row, and the G3 analysis core
- confirm the G3 analysis section executes through `runG3SyncCore`
- confirm the compact G3 summary tables still display
- confirm `pipelineResults.G3SyncResult` exists
- confirm `gateStatusTable(3, :)` shows:
  - `Implemented = true`
  - `ExecutionStatus = manual_review_executed`
  - `Decision = manual_review_nonfinal`
- confirm `NextGate = "G4_Passive_Baseline_Map"` when the baseline result remains `ready` or `caveated`

### Failure-Path Verification

- run the G3 runner with an invalid or missing dataset ID
- confirm a failure bundle is written with `failure_cause.txt`
- run the live-script G3 section without a qualifying G2 result in session
- confirm the blocked summary table is shown instead of invoking the runner

## Assumptions and Defaults

- chosen maturity target:
  parity with the current G2 standalone manual-review runner pattern, not the final formal G3 gate
- chosen runner name:
  `runG3SyncCore.m`
- chosen artifact ID and bundle path segment:
  `G3_Sync_Core`
- chosen semantics:
  keep `ready / caveated / blocked` at the runner level and `manual_review_nonfinal` at the live-script record level
- chosen figure scope:
  exactly `3` overview figures
- chosen upstream role contract:
  keep `RF1:RX2` as reference and `RF0:RX2` as surveillance
- chosen live-script behavior:
  replace direct helper invocation with runner invocation while keeping the whole-gate `G3` row non-final

## Expert Note

This plan remains aligned to the broader council-derived program direction captured in [ProjectPlan.md](ProjectPlan.md) and [docs/checkpoints/G3_Sync.md](docs/checkpoints/G3_Sync.md), with the current implementation emphasis on passive bistatic radar synchronization, RF/data-quality continuity from G2, and signal-processing reviewability through exported evidence.
