# G5 Mitigation

Documentation scope only. This checkpoint defines the mitigation comparison rules for later MATLAB implementation. It does not create adaptive-filter code in this pass.

## Objective

Evaluate whether direct-path and clutter mitigation improves downstream detectability without destroying protected target energy.

## Pipeline Integration Note

- `runPassiveBistaticPipeline` is the long-lived orchestration entry point that will accumulate gate implementations over time.
- When this gate is implemented, its executable logic should be added to the pipeline script only after the baseline passive-map gate is producing a stable reference product.
- Until then, the pipeline should leave G5 as a placeholder and stop after the last implemented gate.

## Requirement IDs in Scope

- `MIT-001` mitigation candidate comparison
- `MIT-002` protected-region energy retention
- `MIT-003` downstream detectability benefit

## Technical Definition

- Run a no-mitigation baseline first.
- Compare that baseline against a conservative LMS configuration and a more aggressive LMS configuration.
- The reference input choice, filter length, step size, leakage, and protected regions must all be documented explicitly.
- `dsp.LMSFilter` is a candidate baseline for this gate, not a final commitment for the program.

## Acceptance Logic

- Clutter and direct-path suppression must improve relative to the no-mitigation baseline.
- Protected nonzero-Doppler regions, or truth-window energy where available, must remain within the allowed loss budget.
- Mitigation is only successful if it improves downstream detectability on the frozen passive-map product.

## Failure Logic

- "Cleaner plots" without improved downstream detectability are not success.
- A mitigation setting that suppresses the direct path but destroys protected energy fails this gate.
- If no mitigation variant beats the no-mitigation case, the gate may pass with an explicit "no mitigation baseline retained" decision.

## Retune Dimensions

- reference input choice
- filter length
- step size
- leakage
- protected-region definition
- adaptation span relative to CPI length

## Required Evidence

- Before-and-after zero-Doppler power summary
- Clutter-floor change summary
- Protected-region energy-retention summary
- Residual error power summary
- Decision note comparing no mitigation, conservative LMS, and aggressive LMS cases

## Expert Note

This checkpoint is part of the broader council-derived plan and was informed primarily by passive bistatic radar algorithm, signal processing/detection QE, and RF/data-quality review inputs.
