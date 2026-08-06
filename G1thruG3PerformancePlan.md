# G1 Through G3 Performance Instrumentation Plan

## Purpose

This plan captures a focused software-development rescope: add timing and performance instrumentation to the already implemented G1 through G3 runner stages without changing their scientific outputs, gate semantics, or review conclusions.

The immediate objective is observability, not optimization. The final project needs a fast analysis path for new data captures, but current development runners are intentionally verbose review tools that load data, generate evidence bundles, export figures, and preserve audit context. This plan adds the measurement layer needed to separate algorithm cost from review artifact cost before later optimization work begins.

## Native MATLAB Audit

| Proposed Workflow | Native MATLAB Documentation Example Analogue | Updates needed to fit current goal |
| :--- | :--- | :--- |
| Per-stage and per-substep runtime capture | `tic` / `toc` timing workflow | Add lightweight timing rows around load, analysis, artifact write, figure render, snapshot write, and total runner execution |
| Targeted performance profiling | MATLAB Profiler / `profile` | Add optional profile mode only; do not enable profiler in normal review runs |
| Reusable timing reports across bundles | `table`, `writetable`, `jsonencode`, `save` | Return `TimingSummaryTable`, write `timing_summary.csv`, and include a compact `performance_summary.json` in each G1-G3 evidence bundle |
| Future fast pipeline preparation | MATLAB runner options with `arguments` / `struct` options | Add backward-compatible `ExecutionMode` scaffolding while keeping default review behavior unchanged |

| Proposed Feature / Algorithm | Native MATLAB Function/Toolbox Equivalent | Documentation Syntax Template Used |
| :--- | :--- | :--- |
| Elapsed timing | `tic`, `toc` | `timerId = tic; elapsed_s = toc(timerId);` |
| Repeated benchmark timing, when needed | `timeit` | `elapsed_s = timeit(@() runStage());` |
| Hotspot profiling | `profile` | `profile on; runStage(); profile off; profile("info")` |
| Timing artifact export | `table`, `writetable` | `writetable(timingSummaryTable, timingSummaryPath)` |
| Structured performance summary | `jsonencode`, `save` | `jsonencode(performanceSummary, PrettyPrint=true)` |

## Agent Prompt

You are the implementation agent for a focused G1-G3 performance-instrumentation slice in the PassiveBistaticRestart MATLAB project.

### Context

The project currently has implemented runner/evidence-bundle flows for:

- `runG1Ingest.m`
- `runG2Stage1AcquisitionEvidence.m`
- `runG2Stage2ReceiverIntegrity.m`
- `runG3SyncCore.m`

These runners are development/review runners. They intentionally generate rich evidence bundles, figures, CSVs, MAT files, JSON/text summaries, and comparison snapshots. They are expected to be slower than a future production analysis-only pipeline.

The current rescope is a software engineering reality check: add timing and performance observability now so later optimization and analysis-only pipeline work is evidence-based rather than based on impressions.

### Scope

In scope:

- Add consistent timing instrumentation to G1 through G3 runners.
- Preserve existing default behavior and all current scientific/gate outputs.
- Preserve existing public calls:
  - `runG1Ingest(datasetId, repoRoot)`
  - `runG2Stage1AcquisitionEvidence(datasetId, repoRoot, options)`
  - `runG2Stage2ReceiverIntegrity(datasetId, repoRoot, options)`
  - `runG3SyncCore(datasetId, repoRoot, options)`
- If `runG1Ingest` needs options, add a backward-compatible third argument only:
  - `runG1Ingest(datasetId, repoRoot, options)`
- Add `ExecutionMode` scaffolding where practical, with default `"review"`.
- Add `TimingSummaryTable` and `PerformanceSummary` to returned `results`.
- Write `timing_summary.csv` and `performance_summary.json` into each successful evidence bundle.
- Include timing output in `metrics.mat` where runner result structs already save MAT artifacts.
- Update README usage/status notes accurately.

Out of scope:

- Do not add arbitrary timing pass/fail thresholds.
- Do not change G1/G2/G3 formal gate decisions or development-readiness semantics.
- Do not optimize algorithms unless a simple bug or accidental duplicate computation is obvious.
- Do not change detection, tracking, G4-G10 behavior, or downstream plans.
- Do not remove current review artifacts from default runs.
- Do not make Live Script display less informative in review mode.

### Required Timing Contract

Each instrumented runner should return:

```matlab
results.TimingSummaryTable
results.PerformanceSummary
```

Each successful bundle should include:

```text
timing_summary.csv
performance_summary.json
```

Use this common timing table schema unless a field is genuinely unavailable:

```text
StageId
StepName
Elapsed_s
ExecutionMode
InputSampleCount
InputRepetitionCount
OutputArtifactCount
OutputFigureCount
OutputBytes
Notes
```

Use `NaN` for numeric fields that are not applicable and `""` for empty notes. Keep row names deterministic so cross-run comparison is easy.

### Recommended Step Names

For `runG1Ingest.m`:

```text
total
resolve_inputs
load_iq_data
build_ingest_metrics
write_tables
write_text_artifacts
write_metrics_mat
write_comparison_snapshot
render_figures
```

For `runG2Stage1AcquisitionEvidence.m`:

```text
total
resolve_inputs
load_session_metadata
run_acquisition_evidence_helper
write_tables
write_text_artifacts
write_metrics_mat
write_comparison_snapshot
render_figures
```

For `runG2Stage2ReceiverIntegrity.m`:

```text
total
resolve_inputs
load_session_metadata
run_receiver_integrity_helper
write_tables
write_text_artifacts
write_metrics_mat
write_comparison_snapshot
render_figures
```

For `runG3SyncCore.m`:

```text
total
resolve_inputs
load_session_with_samples
run_g3_sync_helper
write_tables
write_text_artifacts
write_metrics_json
write_metrics_mat
write_comparison_snapshot
render_figures
```

If the existing code structure makes finer-grained timing natural, add rows, but do not rename the core rows above without a clear reason.

### Execution Mode Policy

Add or scaffold:

```matlab
options.ExecutionMode = "review";
```

Allowed values for this slice:

- `"review"`: default current behavior; write all normal artifacts and figures according to existing `ShowFigures` behavior.
- `"analysis_only"`: accepted and reported, but may initially behave like review except for suppressing visible figures and optionally skipping nonessential figure export only where this is trivial and safe.
- `"profile"`: accepted and reported; may enable MATLAB profiler only if implemented cleanly and safely.

Do not force full `analysis_only` optimization in this slice. The priority is making stage costs visible.

### Implementation Guidance

- Prefer a small reusable helper if it reduces duplication, for example:
  - `helperStartTimingStep`
  - `helperFinishTimingStep`
  - `helperBuildPerformanceSummary`
- If a shared helper would create too much churn, use small local functions in each runner first.
- Use `tic` / `toc` for timing.
- Use `dir` to count bundle artifacts and bytes after writing outputs.
- Store `ShowFigures`, `ExecutionMode`, MATLAB release, dataset ID, stage ID, and bundle root in `PerformanceSummary`.
- Make timing instrumentation robust to failure paths, but do not over-engineer failure bundles.
- Keep comments short and focused.
- Keep all changes minimal and local to G1-G3 performance instrumentation.

### Acceptance Criteria

Manual checks should show:

```matlab
g1 = runG1Ingest("20260622T102123", pwd);
isfield(g1, "TimingSummaryTable")
isfield(g1, "PerformanceSummary")
isfile(fullfile(g1.BundleRoot, "timing_summary.csv"))
isfile(fullfile(g1.BundleRoot, "performance_summary.json"))
```

```matlab
g2s1 = runG2Stage1AcquisitionEvidence( ...
    "20260622T102123", pwd, struct("ShowFigures", false));
isfield(g2s1, "TimingSummaryTable")
isfile(fullfile(g2s1.BundleRoot, "timing_summary.csv"))
```

```matlab
g2s2 = runG2Stage2ReceiverIntegrity( ...
    "20260622T102123", pwd, struct("ShowFigures", false));
isfield(g2s2, "TimingSummaryTable")
isfile(fullfile(g2s2.BundleRoot, "timing_summary.csv"))
```

```matlab
g3 = runG3SyncCore( ...
    "20260622T102123", pwd, struct("ShowFigures", false));
isfield(g3, "TimingSummaryTable")
isfield(g3, "PerformanceSummary")
isfile(fullfile(g3.BundleRoot, "timing_summary.csv"))
isfile(fullfile(g3.BundleRoot, "performance_summary.json"))
```

The timing tables should contain one `total` row and at least three meaningful substep rows for each runner.

### Verification Requirements

Run MATLAB Code Analyzer on touched MATLAB files:

```matlab
checkcode("runG1Ingest.m")
checkcode("runG2Stage1AcquisitionEvidence.m")
checkcode("runG2Stage2ReceiverIntegrity.m")
checkcode("runG3SyncCore.m")
```

Run at least one low-display smoke test:

```matlab
g3 = runG3SyncCore("20260622T102123", pwd, struct("ShowFigures", false));
g3.TimingSummaryTable
```

If full G1-G3 execution is too slow for the implementation session, run the fastest representative subset and clearly report what was and was not run.

### Final Response Requirements

The implementation agent must summarize:

- files changed
- timing schema added
- execution mode behavior added
- verification performed
- any stages not smoke-tested and why
- whether any scientific outputs or gate semantics changed

Expected answer for the last item: no scientific outputs or gate semantics should change in this slice.

## Design Rationale

Performance should be treated as a cross-cutting software requirement, not deferred entirely to a late gate. However, hard runtime thresholds are premature before G5-G10 define the full detection and tracking workload. This slice therefore creates timing observability and analysis-only scaffolding without imposing arbitrary pass/fail budgets.

The long-term target is a clean fast pipeline that can run on new captures and quickly answer:

- whether the dataset is usable
- whether RF and synchronization are adequate
- whether passive scene structure exists
- whether detections and range-Doppler tracks are reliable

The current review runners should remain verbose and auditable. A future production-style pipeline can consume the same helpers with `ExecutionMode = "analysis_only"` and reduced artifact generation once the full G1-G10 chain is stable.
