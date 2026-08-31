# G7 Truth Alignment Plan

Draft and provisional. This plan is for downstream planning only until G1 timing, G4 Part 2, G5 mitigation, and G6 product-freeze contracts are stable. It does not implement MATLAB code, does not supersede `ProjectPlan.md`, and does not authorize detector threshold tuning.

## Status And Purpose

G7 creates the radar-to-truth timing contract needed to validate detector and tracker outputs against ADS-B evidence. It must explicitly reconcile the known dataset timing caution: the manifest says `capture_repetition_spacing_s = 1`, but embedded `RecordingUTC` deltas are about `3.205 s` to `7.727 s`.

If truth alignment is insufficient, diagnostic detector work may continue later, but truth-correlated claims remain blocked.

## Truth Context Diagnostic Mode

`truth_context_diagnostic` mode is allowed before a formal G6 freeze only as capture-level context. It may parse ADS-B truth, reconcile manifest timing against embedded radar `RecordingUTC` and `DateTime`, and write truth import, timing audit, and capture-level truth-overlap tables.

This mode must keep `TruthClaimsEnabled = false` unless a future G6 bundle freezes a detector input product and G7 can derive product-level truth windows. On the current dataset, product/CPI-level truth claims remain blocked, and the output must not be used as detector validation.

The executable diagnostic entry point is `runG7TruthContextDiagnostic`. It does not tune detector thresholds, choose mitigation, freeze CPI/integration, score detections, or validate tracks.
## Native Function Discovery

| Proposed Workflow | Native MATLAB Documentation Example Analogue | Updates needed to fit current goal |
| :--- | :--- | :--- |
| Parse ADS-B truth artifact and normalize truth timestamps | `gunzip`, `readtable`, `detectImportOptions`, `datetime`, `timetable` workflows | Expand compressed truth text, preserve UTC, normalize ADS-B rows into a stable truth timetable keyed by aircraft/time |
| Reconcile radar timing sources | `datetime`, `duration`, `seconds`, `table`, `timetable`, `synchronize` workflows | Compare `radar_epoch_utc`, embedded `RecordingUTC`, embedded `DateTime`, repetition index, and manifest repetition spacing |
| Build radar CPI time intervals | `timerange`, `synchronize`, `retime`, `isbetween`, table filtering | Use the G1 authoritative timing source plus G6 frozen CPI/integration contract to produce per-CPI radar-relative and UTC intervals |
| Compute truth overlap and occupancy windows | `timetable`, `timerange`, `groupsummary`, `rowfun` or grouped table workflows | Produce per-capture/per-CPI overlap tables that state where truth can confirm/refute detector outputs and where claims are blocked |
| Define constrained validation windows | Native geospatial/time functions plus table workflows | Use aligned truth and fixed radar product timing to define time-window constraints; delay/Doppler spatial constraints remain conditional on available transmitter/receiver geometry |
| Evidence bundle reporting | `writetable`, `save`, `jsonencode`, `figure`, `tiledlayout`, `nexttile` | Emit G7 bundle files matching `docs/testing/EvidenceBundleSpec.md` |

| Proposed Feature / Algorithm | Native MATLAB Function/Toolbox Equivalent | Documentation Syntax Template Used |
| :--- | :--- | :--- |
| Compressed truth expansion | `gunzip` | `files = gunzip(filename, outputFolder)` |
| Truth text import | `detectImportOptions`, `readtable` | `opts = detectImportOptions(filename); truthTable = readtable(filename, opts)` |
| UTC timestamp handling | `datetime`, `duration`, `seconds` | `t = datetime(value, "TimeZone", "UTC")` |
| Radar/truth time series alignment | `timetable`, `synchronize`, `retime`, `timerange` | `aligned = synchronize(radarTT, truthTT, "union")` |
| Per-window logical filtering | `isbetween`, timetable row subscripting | `rows = isbetween(truthTT.Time, startTime, stopTime)` |
| Grouped overlap summaries | `groupsummary`, `findgroups`, `splitapply` | `summaryTable = groupsummary(inputTable, groupVars, method, dataVars)` |
| Geodetic coordinate support, if geometry is available | `wgs84Ellipsoid`, `geodetic2ecef`, `geodetic2enu`, `geodetic2aer` where licensed | `ecef = geodetic2ecef(wgs84Ellipsoid, lat, lon, h)` |
| Radar range/time unit conversion | `physconst`, `seconds`, native table arithmetic | `c = physconst("LightSpeed")` |
| Reporting figures | `figure`, `tiledlayout`, `nexttile`, `plot`, `scatter`, `xlabel`, `ylabel`, `title` | `figure; tiledlayout(...); nexttile; plot(...)` |

All future MATLAB implementation must use native import, timing, timetable, and mapping functions where applicable. File I/O and truth import must be wrapped in `try`/`catch` blocks.

## Firm Requirements

Firm requirements from `ProjectPlan.md`, `docs/checkpoints/G7_Truth_Alignment.md`, and `docs/requirements/RequirementsMatrix.md`:

- G7 owns `VAL-001` and `VAL-002`: radar-to-truth time conversion and constrained association/search windows.
- Truth alignment must be available before detector tuning is declared stable.
- Manifest repetition spacing alone is not a valid timing basis for truth-correlated claims.
- G7 must use `radar_epoch_utc`, per-file `RecordingUTC`, embedded `DateTime`, `Repetition`, and manifest timing fields together.
- G7 must define expected truth occupancy intervals for each capture or CPI.
- G7 must define when truth-correlated claims are enabled, manually reviewable, or blocked.
- G7 does not tune detector thresholds, choose mitigation, freeze CPI/integration, or validate tracks.

## Provisional Upstream Assumptions

G4 Part 2 is provisional and may expose:

- `MapSummaryTable`
- `RepeatabilityTable`
- `CpiSelectionTable`
- `QuestionSummaries`
- `Interpretation`
- `RecommendedBaselineCpiLabel`
- `RepresentativeMaps`
- `RawAxisRepresentativeMaps`
- `FullRateAuditSummaryTable`
- `BaselineProductDefinition`

G7 should consume only stable upstream contracts:

- G1 authoritative timing decision and per-repetition timing metadata.
- G6 frozen product definition, including product timestamp convention.
- G4/G6 caveats relevant to map timing or registration stability.
- ADS-B truth artifact `truth/0_20260622_102124_adsb_20260622T102123.txt.gz`.

If G6 is not frozen, G7 may produce capture-level timing diagnostics and truth-import evidence, but CPI/product-level truth claims remain blocked.

## Gate Ownership

G7 owns:

- truth artifact discovery and parsing
- radar UTC and radar-relative timing reconciliation
- capture-level and CPI-level truth overlap windows
- timing residual summaries
- truth occupancy tables
- claim gating: truth-enabled, manual-review-required, or truth-blocked
- radar-relative-to-truth validation windows

G7 does not own:

- detector threshold tuning or CFAR parameter selection
- mitigation selection or LMS parameters
- final CPI/integration freeze
- track initiation logic
- customer-facing performance claims

## Input Contract

| Input | Required Content | Block Condition |
| :--- | :--- | :--- |
| `sessionData` | Manifest path, embedded radar metadata, per-repetition timing, radar epoch, CPI segmentation, and file inventory | Missing authoritative timing or per-repetition timing metadata |
| Collection metadata | Receiver site and acquisition context when available | Missing geometry blocks geometry-derived delay/Doppler windows but not time-only overlap |
| G6 `FrozenProductDefinition` | CPI length, overlap, integration type, registration, axes, units, and timestamp convention | Missing product timestamps block CPI/product-level validation windows |
| ADS-B truth artifact | Compressed truth text for the reference dataset | Missing, unreadable, or no relevant UTC overlap |
| Upstream gate caveats | G1 through G6 status and caveat codes | Timing or registration caveats may block truth-correlated claims |

Required timing fields to reconcile:

- manifest `capture_repetition_spacing_s`
- `radar_epoch_utc`
- per-file embedded `RecordingUTC`
- embedded `DateTime`
- `Repetition`
- CPI start/stop offsets within each radar capture
- G6 detector product timestamp convention

## Output Contract

Future G7 result struct fields:

| Field | Required Content |
| :--- | :--- |
| `GateDecision` | Formal `pass`, `retune`, or `reject` |
| `ReviewStatus` | `ready_for_gate_decision`, `manual_review_required`, or `blocked_by_upstream` |
| `TruthClaimsEnabled` | Logical scalar; true only when bounded truth windows support claims |
| `ClaimBlockReason` | Empty only when truth claims are enabled |
| `TimingSourceDecision` | Authoritative radar timing source and rejected alternatives |
| `RadarTimingAuditTable` | Per-repetition manifest time, embedded time, delta from previous repetition, residuals, and timing label |
| `TruthImportSummaryTable` | Truth file metadata, row counts, UTC span, aircraft/ICAO counts, and parse caveats |
| `TruthOverlapTable` | Capture/CPI overlap with truth rows and occupancy intervals |
| `ValidationWindowTable` | Per detector-product interval, allowed UTC window, radar-relative window, and claim status |
| `TimingResidualSummaryTable` | Residual statistics and pass/manual-review/block labels |
| `AssociationWindowDefinition` | Timing tolerances and, if available, delay/Doppler search-window definitions |
| `Interpretation` | Human-readable decision and caveat codes |
| `EvidenceBundleRoot` | Standard evidence bundle root when a future runner writes artifacts |

## Evidence Package

G7 must follow `docs/testing/EvidenceBundleSpec.md`:

- `summary.md`
- `requirements_coverage.csv`
- `config_snapshot.json`
- `metrics.json`
- `metrics.mat`
- `timing_summary.csv`
- `performance_summary.json`
- `decision.txt`
- `failure_cause.txt` when the decision is not `pass`
- `next_branch.txt`
- `figures/`

## Runner Performance Instrumentation Requirement

The future G7 runner must implement the same timing/performance contract used by the G1-G3 runners.

- Return `results.TimingSummaryTable` and `results.PerformanceSummary`.
- Write `timing_summary.csv` and `performance_summary.json` into each successful evidence bundle.
- Append `timingSummaryTable` and `performanceSummary` to `metrics.mat`.
- Use the common timing table schema: `StageId`, `StepName`, `Elapsed_s`, `ExecutionMode`, `InputSampleCount`, `InputRepetitionCount`, `OutputArtifactCount`, `OutputFigureCount`, `OutputBytes`, and `Notes`.
- Default `ExecutionMode` is `"review"`; accept and report `"analysis_only"` and `"profile"` where runner options exist.
- Do not add arbitrary runtime pass/fail thresholds. Timing is observability evidence unless a later requirements document defines explicit performance gates.

Required G7 figures:

- Radar embedded UTC versus manifest-assumed UTC.
- Repetition spacing residual plot.
- Truth coverage timeline over radar captures.
- CPI validation-window timeline.
- Optional aircraft truth occupancy plot if geospatial fields are reliable.

Every future figure must explicitly call `figure`, use `tiledlayout` and `nexttile` for multi-panel reporting, and include `xlabel`, `ylabel`, and `title`.

## Decision Semantics

| Formal Decision | Meaning | Next Branch |
| :--- | :--- | :--- |
| `pass` | Authoritative radar timing is documented, manifest/embedded discrepancy is reconciled, truth windows are reproducible, and truth-correlated claims are enabled only where support is adequate | Permit G8/G10 truth-aware validation within the declared windows |
| `retune` | Timing conversion is plausible but tolerances, window widths, or product-window definitions need adjustment | Retune G7 timing-window and association settings only |
| `reject` | Truth artifact is missing/unusable, no reproducible radar-to-truth conversion exists, or upstream timing/product timestamps are unresolved | Block truth-correlated claims and reopen G1/G6 if the cause is upstream |

`manual_review_required` is a review status, not a formal gate decision. It applies when radar timing sources disagree materially, truth coverage exists but aircraft identity/field quality is ambiguous, or geometry-dependent delay/Doppler windows are unavailable but time-only validation may be usable with caveats.

Truth-correlated claims are blocked when:

- G1 has not reconciled authoritative timing.
- G6 has not frozen detector product timing.
- embedded `RecordingUTC` deltas cannot be reconciled with product timestamps.
- ADS-B truth has no overlap with radar products under the reconciled timing source.
- validation windows are too broad to confirm or refute detections.
- upstream G4/G6 caveats imply map-product timing or registration is unstable.

## Edge Cases And Failure Modes

- Manifest says 15 captures at 1 s spacing, but embedded UTC spacing is multi-second and variable.
- Truth starts before radar and ends after radar, so apparent coverage does not guarantee aligned overlap.
- ADS-B rows may be irregular, duplicated, missing fields, or delayed relative to actual aircraft state.
- Radar capture duration may be 1 s of IQ while wall-clock repetition spacing is not 1 s.
- CPI integration may span only part of a capture or combine products after G6.
- Time zones or naive datetimes may silently shift UTC interpretation.
- G4/G6 may recommend or freeze products with caveats that prevent truth-backed claims.
- Receiver/transmitter geometry may be insufficient for constrained delay/Doppler windows.
- Multiple aircraft may occupy the same radar-time window, requiring manual review or ambiguous-truth status.

## Test Plan

Unit tests:

- Parse compressed ADS-B artifact into a UTC truth table.
- Validate UTC timezone preservation.
- Compute repetition spacing from embedded `RecordingUTC`.
- Detect the manifest `1 s` versus embedded multi-second discrepancy.
- Build capture-level and CPI-level time intervals.
- Classify overlap, no-overlap, partial-overlap, and ambiguous-overlap cases.

Integration tests:

- Run G7 on reference session `20260622T102123` metadata and truth artifact.
- Confirm timing audit table reports embedded deltas around `3.205 s` to `7.727 s`.
- Confirm naive 1 s repetition spacing is not accepted as the sole truth alignment basis.
- Confirm output tables cover `VAL-001` and `VAL-002`.
- Confirm G7 blocks truth-correlated claims when upstream timing or G6 product freeze is unavailable.

Evidence and regression tests:

- Verify required evidence bundle files exist.
- Verify `metrics.json` and `metrics.mat` contain the same required table names.
- Verify `decision.txt`, `failure_cause.txt`, and `next_branch.txt` follow the bundle spec.
- Verify all generated plots have axis labels and titles.
- Verify no detector thresholds or CFAR settings are modified by G7.

## Open Decisions Blocked On Upstream Outputs

- Which G1 timing source is authoritative when manifest timing and embedded header timing disagree.
- Final G6 detector product timestamp convention: CPI start, midpoint, end, or integration-weighted effective time.
- Whether G6 products are per-CPI, integrated across CPIs, or noncoherently accumulated across repetitions.
- Whether receiver/transmitter geometry is sufficient and approved for delay/Doppler truth-window constraints.
- Final G4/G6 caveat propagation rules when maps are scene-limited or raw-rate audit disagreement exists.
- Numeric timing tolerances for `pass`, manual review, and blocked outcomes.

## Out Of Scope

- Detector threshold tuning and CFAR configuration.
- Hit-rate, false-alarm, and persistence acceptance thresholds.
- Tracker measurement schema and `trackerGNN` initialization.
- Track/truth metric scoring.
- Customer-facing truth-correlated performance claims.
- Mitigation choice or LMS parameter selection.
- Final CPI/integration freeze.
