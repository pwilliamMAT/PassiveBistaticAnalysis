# G10 Tracking / Truth Validation

Documentation scope only. This checkpoint defines the tracking-validation rules for later MATLAB implementation. It does not create tracking or metric code in this pass.

## Objective

Evaluate tracker output against truth after a fixed measurement contract has been established, and decide whether the program reaches `track-level success` or `truth-correlated success`.

## Pipeline Integration Note

- `runPassiveBistaticPipeline` is the long-lived orchestration entry point that will accumulate gate implementations over time.
- When this gate is implemented, its executable logic should be added to the pipeline script only after G9 authorizes tracking work and the measurement contract is fixed.
- Until then, the pipeline should leave G10 as a placeholder and stop after the last implemented gate.

## Runner Performance Instrumentation Requirement

The future G10 runner must implement the same timing/performance contract used by the G1-G3 runners.

- Return `results.TimingSummaryTable` and `results.PerformanceSummary`.
- Write `timing_summary.csv` and `performance_summary.json` into each successful evidence bundle.
- Append `timingSummaryTable` and `performanceSummary` to `metrics.mat` when a metrics MAT artifact is written.
- Use the common timing table schema: `StageId`, `StepName`, `Elapsed_s`, `ExecutionMode`, `InputSampleCount`, `InputRepetitionCount`, `OutputArtifactCount`, `OutputFigureCount`, `OutputBytes`, and `Notes`.
- Default `ExecutionMode` is `"review"`; accept and report `"analysis_only"` and `"profile"` where runner options exist.
- Do not add arbitrary runtime pass/fail thresholds. Timing is observability evidence unless a later requirements document defines explicit performance gates.

## Requirement IDs in Scope

- `TRK-003` batch track and truth metrics
- `VAL-003` truth-correlated claim gating

## Technical Definition

- Tracking may begin only after G9 fixes the measurement contract.
- Batch evaluation must use `trackAssignmentMetrics` and `trackErrorMetrics`.
- Required metric families include continuity, coast behavior, initiation delay, assignment history, and track error.
- The evaluation must separate internal tuning metrics from customer-facing acceptance claims.

## Explicit Council Decision

Tracker smoothness is not an acceptance metric. Acceptance depends on truth-aware assignment quality, continuity, and quantitative error behavior.

## Pass Metrics

- Assignment behavior is acceptable over the evaluated batch.
- Coast behavior and initiation delay are bounded relative to the declared tracker design.
- Error metrics support either `track-level success` or `truth-correlated success`.
- Customer-facing claims are made only when G7 truth alignment and G10 track-to-truth metrics are both strong enough.

## Required Evidence

- Batch track-to-truth metrics summary
- Assignment-history summary
- Continuity, coast, and initiation-delay summary
- `timing_summary.csv` and `performance_summary.json`
- Milestone decision summary stating `track-level success`, `truth-correlated success`, or reopen decision

## Expert Note

This checkpoint is part of the broader council-derived plan and was informed primarily by tracking metrics/V&V, requirements/V&V, passive bistatic radar algorithm, and systems/customer-communication review inputs.
