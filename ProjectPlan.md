# Passive Bistatic Restart Project Plan

This file is the stable gate roadmap and index for the council-derived planning package. It defines approved gate sequencing, evidence expectations, milestone meanings, and reopen rules, but it does not own current implementation status. See [PROJECT_STATE.md](PROJECT_STATE.md) for the active milestone, verified state, blocker, and next action; follow the active plan linked there for currently authorized work.

## Planning Reference Session

| Field | Value | Notes |
| :--- | :--- | :--- |
| Session ID | `20260622T102123` | Reference dataset for this documentation set |
| Radar captures | `15 x 1 s` | Listed in `session_manifest.json` |
| Sample rate | `6.144 MHz` | `sdr_defaults.sample_rate_hz` |
| Channels | Dual channel | Embedded header identifies `RF0:RX2` and `RF1:RX2` |
| Radar file format note | `BasebandVer2.0.0` header observed | G1 must confirm whether native baseband-file reading can be used directly |
| Truth artifact | `truth/0_20260622_102124_adsb_20260622T102123.txt.gz` | ADS-B artifact for truth alignment |
| Processing style | Manifest driven | Later implementation must key off the session manifest plus embedded radar headers |
| Timing caution | Manifest says `capture_repetition_spacing_s = 1`, but embedded `RecordingUTC` deltas are about `3.205 s` to `7.727 s` | G1 and G7 must reconcile this before truth-correlated claims |

## Council-Derived Technical Decisions

- Synchronization is an explicit gated step. A strong direct path is not sufficient evidence that the dataset is synchronized.
- `ambgfun` is the approved passive baseline oracle. Later `phased.RangeDopplerResponse` work is an equivalence or optimization path, not the initial baseline.
- `dsp.LMSFilter` is a candidate mitigation baseline for documentation and comparison work. It is not a locked final method.
- Truth alignment must be available before detector tuning is considered stable.
- Validated detection is the first success milestone that justifies opening tracking work.
- Every gate uses `pass / retune / reject` logic. Retuning stays inside the active gate's knob set; architecture or data-contract changes reopen the earliest affected upstream gate and trigger downstream regression.

## Current Implementation Posture

- `loadIQData` is the current stable helper-level ingest API beneath G1.
- `runG1Ingest` is the current G1 gate-validation runner and evidence-bundle writer.
- `runPassiveBistaticPiplineLiveScript.m` is the current single-session development/test live script used to exercise gate status and gate runners as implementation proceeds.
- `runG1G2SessionComparison` is the artifact-only hardware-comparison runner for saved G1 and G2 outputs, and `runPassiveBistaticSessionComparisonLiveScript.m` is the separate comparison live script layered on top of it.
- A later customer-facing live script should call stable helper APIs such as `loadIQData` and later helper-level gate functions, not the gate-validation runners.

## Gate Sequence

| Gate | Purpose | Why it sits here | Pass outcome | Retune or reject branch | Detail |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `G1 Ingest` | Reconcile manifest, file inventory, decode contract, seam continuity, and CPI segmentation | No RF or timing claim is valid until the file contract is trusted | Dataset is ingest-valid | Retune ingest assumptions only, or reject the capture set | [docs/checkpoints/G1_Ingest.md](docs/checkpoints/G1_Ingest.md) |
| `G2 RF Health` | Screen channel quality, direct-path usability, spectral cleanliness, and classification | RF health depends on valid ingest but precedes synchronization and mapping | Dataset classified as usable for sync/map work | Retune only health thresholds/diagnostics, or reject if reference quality is unusable | [docs/checkpoints/G2_RF_Health.md](docs/checkpoints/G2_RF_Health.md) |
| `G3 Sync` | Establish lag and residual frequency correction strategy across all 15 captures | Passive map formation is not meaningful until coherence is demonstrated explicitly | Stable sync/coherence model selected | Retune alignment strategy, CPI/window, or frequency correction; reject if no stable model exists | [docs/checkpoints/G3_Sync.md](docs/checkpoints/G3_Sync.md) |
| `G4 Passive Baseline Map` | Produce the baseline crossambiguity map with plausible axes and repeatability | Map plausibility must be proven before mitigation or detector work is trusted | Validated passive baseline milestone | Retune map parameters; implausible outputs reopen G1 or G3 | [docs/checkpoints/G4_Passive_Baseline_Map.md](docs/checkpoints/G4_Passive_Baseline_Map.md) |
| `G5 Mitigation` | Compare no-mitigation, conservative LMS, and aggressive LMS cases | Mitigation should only be judged after a credible baseline map exists | Mitigation candidate selected or explicitly deferred | Retune only mitigation knobs, or fall back to no mitigation | [docs/checkpoints/G5_Mitigation.md](docs/checkpoints/G5_Mitigation.md) |
| `G6 CPI / Integration Freeze` | Select CPI length, overlap, and integration rules and freeze the downstream product | Detector work must not chase a moving map product | Detector input product frozen | Retune CPI/integration choices; reopen upstream if map registration changes materially | [docs/checkpoints/G6_CPI_Integration.md](docs/checkpoints/G6_CPI_Integration.md) |
| `G7 Truth Alignment` | Convert radar-relative time to truth-relative search windows and timing checks | Detector validation cannot stabilize until truth timing is bounded | Truth alignment available for detector validation | Retune timing conversion/search windows, or block truth-correlated claims | [docs/checkpoints/G7_Truth_Alignment.md](docs/checkpoints/G7_Truth_Alignment.md) |
| `G8 Detection` | Tune and validate CFAR on frozen map products | Detection is the first programmatic success milestone | Validated detection milestone | Retune detector-only knobs, or reopen G6/G7 if failures indicate bad inputs | [docs/checkpoints/G8_Detection.md](docs/checkpoints/G8_Detection.md) |
| `G9 Tracker Readiness` | Decide whether the validated detections are fit for `trackerGNN` consumption | Tracking must not open until detection continuity is proven | Tracking work authorized or held | Retune only detection-to-measurement contract assumptions, or stop at validated detection | [docs/checkpoints/G9_Tracker_Readiness.md](docs/checkpoints/G9_Tracker_Readiness.md) |
| `G10 Tracking / Truth Validation` | Evaluate batch track performance against truth with fixed inputs | Tracking is the final stage and depends on every upstream contract being stable | Track-level success or truth-correlated success | Retune tracker-only knobs, or reopen earliest affected upstream gate if failures are upstream-caused | [docs/checkpoints/G10_Tracking_Truth_Validation.md](docs/checkpoints/G10_Tracking_Truth_Validation.md) |

## Sequence Rationale

- Ingest and RF health must pass before synchronization because a bad file contract or unusable reference channel makes lag and coherence estimates meaningless.
- Synchronization and coherence must pass before passive map formation because the map is otherwise contaminated by avoidable lag or frequency error.
- Passive map plausibility must pass before mitigation because mitigation should improve a known-good baseline, not mask ingest or synchronization defects.
- Mitigation and CPI/integration choices must stabilize before CFAR so that detector tuning is applied to a frozen map product.
- Truth alignment must constrain detector validation before acceptance thresholds are declared stable.
- Tracking must not open until detection continuity, false-alarm density, timestamp consistency, and measurement schema quality are proven.

## Gate Logic and QE Rules

- Each gate has three legal outcomes: `pass`, `retune`, or `reject`.
- Inner tuning loops are gate-local. They may change thresholds, CPI, windowing, mitigation strength, or other parameters that belong to the active gate, but they may not silently redefine upstream contracts.
- Outer regression loops rerun all affected downstream gates after any accepted retune or reopen event.
- Architecture changes, decode-contract changes, timing-contract changes, or measurement-contract changes reopen the earliest affected upstream gate.
- Evidence bundles are mandatory for all gate outcomes, including `retune` and `reject`, so later agents can understand why a branch closed.

## Milestone Definitions

| Milestone | Meaning | Typical entry gate |
| :--- | :--- | :--- |
| `capture rejected` | The session is not fit for further processing because ingest, RF, or synchronization prerequisites failed irrecoverably | `G1`, `G2`, or `G3` |
| `diagnostic only` | The dataset supports exploration and evidence collection but not customer-facing performance claims | Any point before `G4` pass, or after blocked `G7` |
| `validated passive baseline` | The baseline `ambgfun` map is plausible, repeatable, and suitable for mitigation and detector work | `G4` |
| `validated detection` | Detector outputs on the frozen map product meet false-alarm, persistence, and truth-window criteria; this is the first success milestone | `G8` |
| `track-level success` | Tracking metrics are acceptable with a fixed measurement contract, even if truth correlation is still limited | `G10` |
| `truth-correlated success` | Track and truth metrics support customer-facing performance statements | `G10` |

## Detailed Planning Documents

### Checkpoints

- [G1 Ingest](docs/checkpoints/G1_Ingest.md)
- [G2 RF Health](docs/checkpoints/G2_RF_Health.md)
- [G3 Sync](docs/checkpoints/G3_Sync.md)
- [G4 Passive Baseline Map](docs/checkpoints/G4_Passive_Baseline_Map.md)
- [G5 Mitigation](docs/checkpoints/G5_Mitigation.md)
- [G6 CPI / Integration](docs/checkpoints/G6_CPI_Integration.md)
- [G7 Truth Alignment](docs/checkpoints/G7_Truth_Alignment.md)
- [G8 Detection](docs/checkpoints/G8_Detection.md)
- [G9 Tracker Readiness](docs/checkpoints/G9_Tracker_Readiness.md)
- [G10 Tracking / Truth Validation](docs/checkpoints/G10_Tracking_Truth_Validation.md)

### Requirements, QE, and Evidence

- [Requirements Matrix](docs/requirements/RequirementsMatrix.md)
- [Dataset Registry](docs/requirements/DatasetRegistry.md)
- [Test Strategy](docs/testing/TestStrategy.md)
- [Evidence Bundle Specification](docs/testing/EvidenceBundleSpec.md)
- [Decision Log Template](docs/decision-log/DecisionLogTemplate.md)
- [Pipeline Flowchart Source](docs/flowcharts/PipelineFlowchart.md)

## Expert Note

This document was derived from a council-based planning review using these expert roles: passive bistatic radar algorithm expert, RF/data-quality expert, signal processing and detection QE expert, requirements and V&V expert, MATLAB test architecture expert, tracking metrics/V&V expert, and systems/customer-communication review inputs.
