# G4 Passive Baseline Map

Documentation scope only. This checkpoint defines the baseline passive-map acceptance rules for later MATLAB implementation. It does not create map-generation code in this pass.

## Objective

Produce a plausible, repeatable passive baseline map that can serve as the oracle product for mitigation and detection work.

## Pipeline Integration Note

- `runPassiveBistaticPipeline` is the long-lived orchestration entry point that will accumulate gate implementations over time.
- When this gate is implemented, its executable logic should be added to the pipeline script only after the upstream ingest, RF-health, and synchronization gates have passed.
- Until then, the pipeline should leave G4 as a placeholder and stop after the last implemented gate.

## Requirement IDs in Scope

- `MAP-001` baseline map generation with `ambgfun`
- `MAP-002` axis plausibility and direct-path localization
- `MAP-003` map repeatability across captures

## Technical Definition

- The baseline passive map method is `ambgfun` crossambiguity.
- The map must expose plausible direct-path coordinates under the declared axis convention.
- Stationary-scene structure must be interpretable and repeatable across repeated captures.
- Map-to-map correlation across captures is a required repeatability metric.

## Explicit Council Decision

- `ambgfun` is the first baseline and the passive-map oracle for this documentation set.
- `phased.RangeDopplerResponse` is not the first baseline. It may be evaluated later only for equivalence, performance, or packaging reasons after the `ambgfun` baseline has passed.

## Tuning Dimensions

- CPI length
- overlap
- windowing
- normalization
- decimation
- delay and Doppler axis conventions

## Pass Metrics

- The direct-path feature sits at plausible near-zero coordinates under the declared axis convention.
- Stationary-scene structure is stable enough to support repeatability claims.
- Map-to-map correlation across repeated captures shows the baseline is reproducible.
- The chosen axis convention is documented and does not require reinterpretation in downstream gates.

## Retune and Reopen Rules

- Retune only G4 map-formation parameters listed above.
- If baseline maps are implausible, reopen G1 or G3. Do not jump ahead to detector tuning and try to compensate there.
- Any later proposal to change the baseline method away from `ambgfun` reopens this gate and all downstream gates.

## Required Evidence

- Baseline map figures
- Repeatability metrics summary
- Map-to-map correlation summary
- Axis plausibility note and direct-path coordinate summary

## Expert Note

This checkpoint is part of the broader council-derived plan and was informed primarily by passive bistatic radar algorithm, signal processing/detection QE, and requirements/V&V review inputs.
