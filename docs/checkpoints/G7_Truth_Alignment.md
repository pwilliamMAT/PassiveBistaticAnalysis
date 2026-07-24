# G7 Truth Alignment

Documentation scope only. This checkpoint defines the truth-alignment contract for later MATLAB implementation. It does not create truth-processing code in this pass.

## Objective

Create the radar-to-truth timing contract needed to validate detector and tracker outputs against ADS-B evidence.

## Pipeline Integration Note

- `runPassiveBistaticPipeline` is the long-lived orchestration entry point that will accumulate gate implementations over time.
- When this gate is implemented, its executable logic should be added to the pipeline script only after upstream timing and CPI contracts are frozen.
- Until then, the pipeline should leave G7 as a placeholder and stop after the last implemented gate.

## Requirement IDs in Scope

- `VAL-001` truth time conversion and overlap windows
- `VAL-002` constrained search and association windows

## Technical Definition

- Use `radar_epoch_utc`, per-file `RecordingUTC`, embedded `DateTime`, `Repetition`, and manifest timing fields together.
- Use ADS-B overlap windows from the compressed truth artifact and expanded text content.
- Convert every radar product to a radar-relative time referenced to the declared authoritative radar timing source from G1.
- Define expected truth occupancy intervals for each capture or CPI.
- If feasible, define constrained delay and Doppler search regions from the aligned truth.

## Dataset Timing Caution

- The ADS-B artifact starts well before the first observed radar header time and continues beyond the radar capture sequence.
- The manifest timing summary and embedded radar-header timing are not currently identical.
- Therefore, truth alignment must use reconciled timing, not a naive one-second repetition assumption.

## Council Rule

Truth alignment must be available before detector tuning is declared stable.

## Internal-Only Fallback

If truth alignment is insufficient, internal tuning may still proceed for diagnostic purposes, but truth-correlated claims are blocked. In that state the project remains at `diagnostic only` or `validated passive baseline`, not customer-facing performance validation.

## Pass Metrics

- Radar-to-truth time conversion is documented and reproducible.
- Truth overlap tables bound when truth can legitimately confirm or refute detector outputs.
- Validation windows are defined tightly enough to support detector and tracker acceptance metrics.

## Required Evidence

- Truth overlap tables
- Timing residual summary
- Validation-window definitions
- Decision note stating whether truth-correlated claims are enabled or blocked

## Expert Note

This checkpoint is part of the broader council-derived plan and was informed primarily by requirements/V&V, tracking metrics/V&V, passive bistatic radar algorithm, and systems/customer-communication review inputs.
