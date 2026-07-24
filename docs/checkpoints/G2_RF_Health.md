# G2 RF Health

Documentation scope only. This checkpoint defines the RF and data-quality screening rules for later MATLAB implementation. It does not create signal-analysis scripts or figures in this pass.

## Objective

Determine whether the ingested reference and surveillance channels are fit for synchronization and passive-map work, and classify the dataset as `golden`, `diagnostic`, or `rejected`.

## Pipeline Integration Note

- `runPassiveBistaticPipeline` is the current development/test orchestration live script that will accumulate gate implementations over time.
- When this gate is implemented, keep separate layers: reusable helper-level RF-health APIs, a G2 gate-validation runner for pass/retune/reject plus evidence, and the development/test pipeline section that invokes that runner after G1 passes.
- A later customer-facing live script should call the stable helper-level APIs rather than the gate-validation runner.
- Until then, the pipeline should leave G2 as a placeholder and stop after the last implemented gate.

## Requirement IDs in Scope

- `RFH-001` channel amplitude, clipping, DC, and IQ health
- `RFH-002` spectral suitability and direct-path usability
- `RFH-003` dataset classification

## Technical Definition

### Required Metrics Per Channel

- RMS power
- peak-to-average ratio (PAR)
- clipped-sample fraction
- DC offset magnitude
- IQ imbalance indicators
- spur occupancy across the illuminator band

### Required Cross-Channel Comparisons

- reference-vs-surveillance PSD comparison
- direct-path prominence in the surveillance channel
- coherence precheck between the channels before formal synchronization work
- spectral evidence of unexpected interferers that dominate the illuminator band

### Dataset Classification Outcomes

- `golden`: channel health margins are strong, direct path is usable, and no dominant impairment is likely to distort synchronization or map formation
- `diagnostic`: data is still useful for checkpoint development or limited baseline work, but margins are weak or one or more impairments must be carried explicitly downstream
- `rejected`: the reference channel or illuminator-band environment is too poor to justify continued processing

## Decision Logic

### Pass

- Both channels have acceptable power, clipping, DC, and IQ-balance behavior.
- The reference channel is usable for synchronization and mitigation experiments.
- The surveillance channel shows direct-path evidence without overwhelming unexpected interference.
- The dataset classification is documented as either `golden` or `diagnostic` with explicit caveats.

### Retune

Retune only RF-health diagnostics or thresholds:

- window lengths and averaging for PSD and RMS summaries
- clipping thresholds
- spur-occupancy thresholds
- direct-path prominence reporting thresholds
- dataset classification cut points

### Reject

- unusable reference channel
- severe clipping on either channel
- dominant unexpected interference over the illuminator band
- RF impairments so large that synchronization would be untrustworthy even if tuned aggressively

## Required Evidence

- RF health table
- PSD plots for reference and surveillance channels
- direct-path prominence summary
- dataset classification note stating `golden`, `diagnostic`, or `rejected`

## Expert Note

This checkpoint is part of the broader council-derived plan and was informed primarily by RF/data-quality, passive bistatic radar algorithm, and signal processing/detection QE review inputs.
