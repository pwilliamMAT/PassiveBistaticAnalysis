# Requirements Matrix

Documentation scope only. This matrix defines the requirement categories, gate ownership, downstream confirmation points, evidence expectations, pass metrics, and failure branches for later implementation.

## Requirement Categories

- `ING-`: ingest, file contract, timing contract, and CPI segmentation
- `RFH-`: RF and data-quality screening
- `SYN-`: synchronization and coherence
- `MAP-`: passive baseline map and CPI/integration product definition
- `MIT-`: mitigation comparison and protection of useful energy
- `DET-`: detector input freeze, CFAR control, and detection record schema
- `TRK-`: tracker-readiness and track-level validation
- `VAL-`: truth alignment and truth-correlated claim gating

## Governing Rule

Architecture changes or data-contract changes reopen the earliest affected upstream gate. Downstream gates must be rerun after the upstream gate re-passes.

## Matrix

| Requirement ID | Intent | Primary Gate | Downstream Confirmation Gate | Planned Evidence | Pass Metric | Failure Branch |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `ING-001` | Reconcile manifest inventory against observed files | `G1` | `G2` | Manifest-vs-observed table | Required radar, truth, and log artifacts match exactly | Retune ingest assumptions or reject capture |
| `ING-002` | Define decode contract, channel order, and sample layout | `G1` | `G3`, `G4` | Decode contract summary | Channel/sample contract is reproducible across all radar files | Retune reader contract or reopen ingest |
| `ING-003` | Define authoritative timing and seam contract | `G1` | `G7` | Timing-contract note, seam summary | Manifest and embedded timing are reconciled | Retune timing precedence or reject capture |
| `ING-004` | Freeze CPI segmentation contract | `G1` | `G4`, `G6` | CPI segmentation summary | Later map windows can be formed consistently from declared segments | Retune segmentation or reopen ingest |
| `RFH-001` | Verify channel power, clipping, DC, and IQ health | `G2` | `G5` | RF health table | Both channels are usable for baseline processing | Retune RF-health thresholds or reject capture |
| `RFH-002` | Verify spectral suitability and direct-path usability | `G2` | `G4` | PSD plots, direct-path summary | Illuminator band and direct path are usable for sync/map work | Retune RF-health thresholds or reject capture |
| `RFH-003` | Classify dataset as `golden`, `diagnostic`, or `rejected` | `G2` | `G4` | Classification note | Dataset status is explicit and justified | Carry `diagnostic` caveats or reject capture |
| `SYN-001` | Establish stable lag estimation | `G3` | `G4` | Lag statistics | Lag solution is stable across repeated captures | Retune sync strategy or reject capture |
| `SYN-002` | Bound residual frequency error | `G3` | `G4` | Residual offset statistics | Residual error is small enough for repeatable maps | Retune frequency correction or reject capture |
| `SYN-003` | Select correction strategy for downstream use | `G3` | `G6` | CPI sensitivity summary | One correction strategy is documented and repeatable | Retune sync strategy or reopen G1 |
| `MAP-001` | Produce baseline passive map with `ambgfun` | `G4` | `G6` | Baseline map figures | `ambgfun` product is the trusted oracle baseline | Retune map parameters or reopen G3 |
| `MAP-002` | Confirm axis plausibility and direct-path location | `G4` | `G8` | Axis note, direct-path coordinate summary | Delay/Doppler axes and direct-path location are interpretable | Retune axis conventions or reopen G1/G3 |
| `MAP-003` | Demonstrate map repeatability across captures | `G4` | `G6` | Repeatability metrics, map correlations | Repeated captures produce correlated baseline maps | Retune map parameters or reopen G3 |
| `MAP-004` | Freeze CPI and integration registration rules | `G6` | `G8` | Frozen baseline configuration record | Detector input product is stable and repeatable | Retune CPI/integration or reopen G4 |
| `MIT-001` | Compare no mitigation, conservative LMS, and aggressive LMS | `G5` | `G6` | Mitigation comparison note | One mitigation posture is justified explicitly | Retune mitigation or retain no-mitigation baseline |
| `MIT-002` | Protect useful nonzero-Doppler or truth-window energy | `G5` | `G8` | Protected-region energy summary | Allowed energy loss budget is met | Retune mitigation or reject mitigation candidate |
| `MIT-003` | Show downstream detectability benefit | `G5` | `G8` | Before/after clutter and detectability summary | Mitigation helps or is explicitly deferred | Retune mitigation or retain baseline |
| `DET-001` | Freeze detector input product definition | `G6` | `G8` | Frozen product record | CFAR runs against a fixed map product | Reopen G6 if detector input keeps moving |
| `DET-002` | Control false alarms with explicit CFAR settings | `G8` | `G9` | False-alarm summary, detector config snapshot | False-alarm density is within declared limits | Retune detector-only knobs or reopen G6 |
| `DET-003` | Achieve stable hit rate and persistence | `G8` | `G9`, `G10` | Hit-rate and persistence summary | Detections are repeatable enough to justify tracking | Retune detector or hold at detection milestone |
| `DET-004` | Emit a fixed detection record schema | `G8` | `G9` | Detection table | Detection records contain the required fields and units | Retune record adapter or block tracking |
| `TRK-001` | Define tracker measurement schema and uncertainty contract | `G9` | `G10` | Measurement-schema definition | `trackerGNN` input contract is fixed | Retune measurement assumptions or hold at detection |
| `TRK-002` | Bound fragmentation and continuity risk | `G9` | `G10` | Continuity summary, fragmentation indicators | Detections can sustain track initiation and maintenance | Hold at detection or reopen G8 |
| `TRK-003` | Validate batch track performance against truth | `G10` | None | Track/truth metrics summary | Track metrics support the declared milestone | Retune tracker-only knobs or reopen upstream gate |
| `VAL-001` | Convert radar time to truth overlap windows | `G7` | `G8`, `G10` | Truth overlap tables, timing residuals | Truth windows are reproducible and bounded | Retune timing alignment or block truth claims |
| `VAL-002` | Define constrained association windows | `G7` | `G8` | Validation-window definitions | Delay/Doppler search bounds are explicit and usable | Retune truth windows or keep diagnostic-only status |
| `VAL-003` | Allow or block truth-correlated claims | `G10` | None | Milestone decision summary | Customer-facing claims are backed by truth metrics | Limit outcome to track-level success or diagnostic-only |

## Expert Note

This document is part of the broader council-derived plan and was informed primarily by requirements/V&V, signal processing/detection QE, MATLAB test architecture, and tracking metrics/V&V review inputs.
