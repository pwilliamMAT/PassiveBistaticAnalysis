# G3 Sync

Documentation scope only. This checkpoint defines the synchronization and coherence acceptance rules for later MATLAB implementation. It does not create sync estimation code in this pass.

## Objective

Select and validate a stable lag and residual-frequency correction strategy across all `15` radar captures.

## Pipeline Integration Note

- `runPassiveBistaticPipeline` is the long-lived orchestration entry point that will accumulate gate implementations over time.
- When this gate is implemented, its executable logic should be added to the pipeline script only after G1 and G2 have passed with stable upstream contracts.
- Until then, the pipeline should leave G3 as a placeholder and stop after the last implemented gate.

## Requirement IDs in Scope

- `SYN-001` lag estimation stability
- `SYN-002` residual frequency-offset stability
- `SYN-003` correction-strategy stability

## Technical Definition

- Estimate per-capture lag between reference and surveillance channels.
- Estimate residual frequency offset and its stability over time.
- Evaluate coherence stability over candidate CPI lengths.
- Check seam lag stability across file boundaries and repeated captures.
- Track peak-to-sidelobe ratio for the chosen synchronization observable.
- Compare global correction, per-capture correction, and subwindow correction strategies.

## Explicit Council Decision

The prior assumption that "a strong direct path means the data is already synchronized" is rejected. A visible direct path may exist even when lag drift, seam timing defects, or residual frequency error still degrade passive-map quality.

## Retune Path

Only synchronization choices may be retuned here:

- alignment observable or alignment strategy
- CPI and subwindow length used for synchronization estimates
- residual frequency-offset correction approach
- whether correction is global, per capture, or subwindow based
- coherence-summary thresholds

## Pass Metrics

- Stable lag estimates are available across all `15` captures.
- Residual frequency-offset estimates are bounded tightly enough that the passive baseline map is repeatable.
- Seam lag behavior is understood and does not invalidate CPI formation.
- A single synchronization correction strategy is selected and documented for downstream use.

## Reject Criteria

- No stable sync or coherence model exists across the `15` captures.
- Lag or residual frequency behavior varies so much that passive maps are not reproducible.
- The timing contract conflict inherited from G1 remains unresolved enough to invalidate correction estimates.

## Required Evidence

- Lag statistics summary
- Residual offset statistics summary
- Coherence stability summary
- Peak-to-sidelobe ratio summary
- CPI sensitivity summary comparing global, per-capture, and subwindow correction

## Expert Note

This checkpoint is part of the broader council-derived plan and was informed primarily by passive bistatic radar algorithm, RF/data-quality, and signal processing/detection QE review inputs.
