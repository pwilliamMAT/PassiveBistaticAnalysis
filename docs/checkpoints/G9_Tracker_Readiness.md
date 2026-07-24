# G9 Tracker Readiness

Documentation scope only. This checkpoint defines the tracker-readiness decision for later MATLAB implementation. It does not create tracker code in this pass.

## Objective

Decide whether the validated detections support a fixed measurement contract suitable for `trackerGNN`, or whether the effort should remain at the `validated detection` milestone.

## Pipeline Integration Note

- `runPassiveBistaticPipeline` is the long-lived orchestration entry point that will accumulate gate implementations over time.
- When this gate is implemented, its executable logic should be added to the pipeline script only after G8 has produced a stable detection record schema and persistence evidence.
- Until then, the pipeline should leave G9 as a placeholder and stop after the last implemented gate.

## Requirement IDs in Scope

- `TRK-001` tracker measurement schema and uncertainty contract
- `TRK-002` detection continuity and fragmentation acceptability

## Technical Definition

- Verify detection continuity across time.
- Verify timestamp consistency and declared units.
- State measurement uncertainty assumptions explicitly.
- Quantify false-alarm density and fragmentation risk.
- Define the measurement contract needed for `trackerGNN`, including time base, measurement vector, units, covariance or uncertainty assumptions, and record metadata.

## Gate Decision

This gate decides whether the program remains at `validated detection` or opens tracking work. Tracking is not mandatory if the data only supports a stable detector milestone.

## Pass Metrics

- The measurement schema is fixed and sufficient for tracker consumption.
- Detection continuity is adequate for track initiation and maintenance.
- Fragmentation risk is bounded and documented.
- False-alarm density does not obviously overwhelm the tracker design point.

## Required Evidence

- Continuity summary
- Fragmentation indicators
- Measurement-schema definition
- Readiness decision note stating either "open G10" or "hold at validated detection"

## Expert Note

This checkpoint is part of the broader council-derived plan and was informed primarily by tracking metrics/V&V, signal processing/detection QE, and requirements/V&V review inputs.
