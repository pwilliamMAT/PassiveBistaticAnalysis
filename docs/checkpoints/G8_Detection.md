# G8 Detection

Documentation scope only. This checkpoint defines the detector-validation rules for later MATLAB implementation. It does not create CFAR code in this pass.

## Objective

Validate detections on frozen passive-map products and establish the first success milestone for the project.

## Pipeline Integration Note

- `runPassiveBistaticPipeline` is the long-lived orchestration entry point that will accumulate gate implementations over time.
- When this gate is implemented, its executable logic should be added to the pipeline script only after the detector input product and truth-window contracts are frozen upstream.
- Until then, the pipeline should leave G8 as a placeholder and stop after the last implemented gate.

## Requirement IDs in Scope

- `DET-001` frozen detector input product
- `DET-002` CFAR false-alarm control
- `DET-003` truth-window hit rate and persistence
- `DET-004` detection record schema

## Technical Definition

- Run CFAR only on map products that passed G6.
- Document guard cells, training cells, `Pfa`, exclusion masks, and post-pruning rules.
- Measure empirical false alarms in truth-free regions.
- Measure truth-window hit rate where G7 supports truth correlation.
- Measure persistence across repeated captures or repeated looks.

## Explicit Council Decision

Visual overlays alone are insufficient. Detector acceptance must be metric driven and recorded in a structured detection table.

## Stop or Go Criteria Before Tracking

- acceptable false-alarm density
- stable hit rate in allowed truth windows
- persistence across repeated looks or captures
- fixed detection record fields suitable for later tracker adaptation

## Pass Metrics

- False-alarm density is bounded on truth-free regions.
- Truth-window hit rate or protected-region hit behavior is stable enough to justify the `validated detection` milestone.
- Detection records are emitted in a fixed schema with time, delay or range, Doppler, threshold, noise, and association fields.

## Required Evidence

- Detection table containing frame or capture identifier, delay or range, Doppler, SNR, threshold, local noise estimate, and truth-window association
- False-alarm summary
- Hit-rate and persistence summary
- Decision note stating whether tracking work is unlocked

## Expert Note

This checkpoint is part of the broader council-derived plan and was informed primarily by signal processing/detection QE, passive bistatic radar algorithm, requirements/V&V, and tracking metrics/V&V review inputs.
