# G6 CPI / Integration

Documentation scope only. This checkpoint defines the CPI and integration selection rules for later MATLAB implementation. It does not create integration code in this pass.

## Objective

Freeze the downstream baseline configuration by selecting a stable CPI and integration strategy that improves detectability without unstable smearing or false-alarm growth.

## Pipeline Integration Note

- `runPassiveBistaticPipeline` is the long-lived orchestration entry point that will accumulate gate implementations over time.
- When this gate is implemented, its executable logic should be added to the pipeline script only after the upstream map and mitigation choices are stable enough to freeze.
- Until then, the pipeline should leave G6 as a placeholder and stop after the last implemented gate.

## Requirement IDs in Scope

- `MAP-004` CPI and integration registration freeze
- `DET-001` frozen detector input product

## Technical Definition

- Compare short versus moderate CPI lengths.
- Evaluate overlap options.
- Compare single-look products to noncoherent integration.
- Allow coherent integration only when phase stability and registration are justified explicitly.
- Document outlier rejection, weighting, and map-registration rules.

## Explicit Council Decision

This gate freezes the downstream baseline configuration. After G6 passes, G8 detector work may tune detector parameters only against the frozen product definition.

## Decision Criteria

- Detectability improves or remains stable with better repeatability.
- Peak smearing remains bounded and explainable.
- False-alarm growth does not erase the benefit of additional integration.
- Registration is stable enough that repeated captures can be compared or integrated consistently.

## Retune and Reopen Rules

- Retune only CPI length, overlap, integration type, outlier rejection, weighting, and registration choices.
- If a proposed change redefines delay or Doppler axes, map registration, or time segmentation, reopen G4 or earlier as appropriate.
- If G6 cannot stabilize the detector input product, G8 may not begin.

## Required Evidence

- Bin-spacing summary
- Integration-gain summary
- Peak-smearing metrics
- Contribution and outlier statistics
- Frozen baseline-configuration record for downstream gates

## Expert Note

This checkpoint is part of the broader council-derived plan and was informed primarily by passive bistatic radar algorithm, signal processing/detection QE, and requirements/V&V review inputs.
