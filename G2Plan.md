# G2 Plan

## Summary

This document integrates the G2 technical implementation plan and the G2 butterfly-visual communication plan into one scoped plan for `G2_RF_Health`. It is intended to sit beneath [ProjectPlan.md](ProjectPlan.md), which remains the canonical roadmap and gate authority for the full program.

The plan is sequenced deliberately:

1. complete the G2 technical work that defines inputs, metrics, decision logic, evidence, and implementation boundaries
2. use those stabilized technical outputs to drive the butterfly diagram, PNG, and editable PowerPoint slide so the visual package inherits the actual G2 artifacts rather than becoming a parallel, weaker story

The current default planning assumption is that a `diagnostic` classification can still be useful for development, but it is not by itself a formal G2 approval for later gates. The implementation should therefore keep the strict RF and legal verdicts intact while reporting a separate development-readiness status.

The core plan now separates three related but distinct conclusions:

- analysis validity and development readiness for pipeline work
- legal gate outcome under the canonical `pass / retune / reject` framework
- collection-validity verdict about whether the hardware and acquisition state were actually evidenced
- aircraft-analysis readiness verdict about whether the dataset gives a credible shot at later aircraft-related analysis instead of only diagnostic use

## Frozen Upstream Inputs

G2 must inherit the latest passed G1 ingest contract without reinterpretation:

- dataset: `20260622T102123`
- one file equals one repetition
- decoded shape per file: `[6144000 x 2]` complex `int16`
- channel order: column 1 = `RF0:RX2`, column 2 = `RF1:RX2`
- authoritative repetition timing: per-file `RecordingUTC`
- CPI segmentation: intra-file only by default
- `loadIQData` is the approved helper-level ingest API beneath G2

If any proposed G2 analysis requires redefining timing authority, file seam meaning, channel contract, or CPI formation across files, that is not a G2 retune. It reopens G1 or defers to a later gate.

## Scope and Gate Ownership

G2 is the RF and data-quality gate between frozen ingest and later sync/map work.

Official G2 scoring remains limited to:

- `RFH-001` channel amplitude, clipping, DC, and IQ health
- `RFH-002` spectral suitability and direct-path usability
- `RFH-003` dataset classification

The plan also includes a downstream-readiness annex. That annex exists to surface the recorded-data questions that matter for G3, G4, G5, and G7, but it is explicitly non-scoring for G2. It should never silently absorb ownership from those later gates.

## Native Function Audit

### Workflow Audit

| Proposed Workflow | Native MATLAB Documentation Example Analogue | Updates needed to fit current goal |
| :--- | :--- | :--- |
| Manifest-driven ingest into RF-health screening | `comm.BasebandFileReader` workflow for baseband-file ingest | Reuse the frozen G1 ingest output and metadata rather than redesigning file parsing |
| Per-repetition and aggregate RF-health screening | `pwelch`, `bandpower`, `obw`, `spectrogram`, Signal Analyzer workflows | Emit both per-repetition metrics and aggregate worst-case, median, and spread summaries |
| Direct-path and sync-readiness precheck | `mscohere`, `finddelay`, `xcorr`, and `ambgfun` workflows | Keep this as readiness evidence only and not formal G3 pass logic |
| Passive-map readiness preview | `ambgfun` crossambiguity workflow | Allow only limited annex preview metrics; G4 still owns baseline-map acceptance |
| Truth-readiness timing and metadata audit | `datetime`, `timetable`, and `synchronize` workflows | Use only to quantify completeness and uncertainty; G7 still owns truth alignment |
| Customer-facing communication artifact generation | Existing Markdown-driven PowerPoint generation pattern in this repo | Reuse the same repo-controlled source-of-truth pattern for the G2 butterfly assets |

### Function Audit

| Proposed Feature / Algorithm | Native MATLAB Function/Toolbox Equivalent | Documentation Syntax Template Used |
| :--- | :--- | :--- |
| Baseband ingest | `comm.BasebandFileReader` | `bbr = comm.BasebandFileReader(fname)` |
| Welch PSD | `pwelch` | `[pxx,f] = pwelch(x,win,noverlap,nfft,Fs)` |
| Band-limited power | `bandpower` | `p = bandpower(pxx,f,freqRange,"psd")` |
| Occupied bandwidth | `obw` | `bw = obw(x,Fs)` |
| Time-frequency contamination view | `spectrogram` | `[s,f,t] = spectrogram(x,win,noverlap,nfft,Fs)` |
| Cross-channel coherence | `mscohere` | `[cxy,f] = mscohere(x,y,win,noverlap,nfft,Fs)` |
| Delay observable | `finddelay` or `xcorr` | `d = finddelay(x,y,maxlag)` |
| Cross-ambiguity preview | `ambgfun` | `[afmag,delay,doppler] = ambgfun(x,y,Fs,PRF)` |
| IQ imbalance support metric | `iqimbal2coef` | `C = iqimbal2coef(A,P)` |
| Mitigation baseline reference for later planning | `dsp.LMSFilter` | `lms = dsp.LMSFilter(L)` |
| Timetable-based truth-readiness audit | `synchronize` | `TT = synchronize(TT1,TT2,newTimeBasis,method)` |

If a native MATLAB function covers the need, the implementation should use that function rather than custom loops, custom utilities, or manual reconstructions.

## Technical Implementation Plan

### Session Contract

The G2 implementation session should start with a short gate contract packet that fixes:

- active gate: `G2_RF_Health`
- approved dataset: `20260622T102123`
- approved upstream input: `loadIQData` output
- frozen inherited G1 contracts
- G2 output expectation: helper API, gate runner, pipeline integration update, evidence bundle, and visual-ready metrics
- explicit rule that G2 does not reopen G1 unless RF results prove an ingest or timing-contract defect

### Architecture and Code Layers

Preserve the three-layer split already established by the repo:

- stable helper-level RF-health API:
  reusable MATLAB functions that compute RF-health metrics from the frozen G1 session struct
- gate-validation runner:
  `runG2RFHealth` style entry point that applies decision logic, writes the evidence bundle, and returns the gate decision
- development/test orchestration:
  `runPassiveBistaticPipeline` integration that runs G2 only after G1 passes and still stops at the last implemented gate

The later customer-facing live script remains out of scope for the first G2 implementation pass.

### Single-Session Baseline Versus Hardware Comparison

Keep the G2 stage logic and legal decisions single-session by default:

- `20260622T102123` remains the approved single-session baseline and planning reference
- `20260713T150404` and later hardware variants are comparison candidates, not automatic replacements for the baseline
- `runG2Stage1AcquisitionEvidence` and `runG2Stage2ReceiverIntegrity` remain single-session runners that write their normal evidence bundles plus a lightweight `comparison_snapshot.mat`
- Stage 2 keeps the strict RF verdict and legal recommendation, but it should also write a separate `AnalysisValidity` and `DevelopmentReadiness` status so a dataset-limited result is not mistaken for a broken analysis path
- hardware iteration across sessions should use an artifact-only comparison runner that loads saved G1, G2 Stage 1, and G2 Stage 2 snapshots rather than rerunning raw analysis inside the comparison workflow
- the separate comparison live script is for hardware-change evaluation only and does not replace the single-session gate review or open Stage 3 automatically

### Collection-Time Validation and Acquisition Controls

G2 should not rely on IQ appearance alone to infer that the hardware chain behaved correctly. The main plan should require explicit acquisition-state evidence so a later null result can be interpreted as hardware-limited, scene-limited, or genuinely uninformative.

Mandatory configuration metadata to capture in `config_snapshot.json` and summarize in `summary.md`:

- SDR make, model, serial number, and firmware or driver version
- center frequency, sample rate, analog bandwidth or filter setting, and gain per channel
- AGC or manual-gain state
- clock source, PPS source, LO reference source, and lock status
- channel-to-port mapping, antenna ID, antenna polarization, cable mapping, and any preamp or attenuator state
- host machine identifier, operator identifier, site identifier, and collection notes

Mandatory acquisition-status evidence:

- capture start and stop UTC
- file inventory, file sizes, and hashes
- dropped-sample, overflow, or overrun indicators if exposed by the SDR or driver
- retune events, setting changes, and temperature or reference-lock indicators when available

Required control or verification captures for future hardware sessions:

- one terminated-input or antenna-covered baseline capture
- one quiet-scene capture
- one stepped-gain capture
- one channel-mapping verification capture or injected-tone verification

Required operator checklist items:

- verify antenna labels and physical placement
- verify cable routing and channel mapping
- verify gains and clock settings against the run sheet
- verify no unlogged mid-run setting changes occurred
- verify overrun status remained acceptable during capture

If any of these items are missing, the gap must be carried into the collection-validity and aircraft-analysis readiness verdicts rather than being silently ignored.

### Core G2 Questions

These questions are formal G2 content and drive `RFH-001`, `RFH-002`, and `RFH-003`.

| Question | Why it matters | Quantification method | Data needed now | If insufficient, acquisition change | MathWorks tools | Requirement ID | Decision impact |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Was the receiver configuration and hardware state validated at collection time? | A bad clock, gain setting, lock state, or SDR event can masquerade as an RF-scene problem | Metadata presence audit, lock and overrun status review, channel power consistency relative to declared settings, receiver-baseline fingerprint comparison | Current logs, manifest, SDR status metadata, and any control captures | Add pre-run checklist, fixed run sheet, and required verification captures | MATLAB tables, JSON snapshots, `pwelch` for baseline fingerprint comparison | `RFH-001`, `RFH-003` | Missing evidence usually forces `diagnostic` and readiness downgrade |
| Are the declared reference and surveillance roles and physical channel mappings actually correct? | Later cancellation and crossambiguity work fail if the channel roles are wrong even when PSDs look plausible | Channel-mapping verification capture, reference-to-surveillance power asymmetry, coherence asymmetry, and illuminator dominance consistency | Current dual-channel IQ plus mapping evidence | Add channel-mapping verification capture or injected-tone proof | `pwelch`, `bandpower`, `mscohere`, `xcorr` | `RFH-001`, `RFH-002`, `RFH-003` | Ambiguous mapping forces `diagnostic` or readiness downgrade |
| Is the reference channel consistently stronger and cleaner than surveillance? | A weak or contaminated reference undermines sync and mitigation work | RMS power, channel power delta, in-band power ratio, PSD flatness, per-repetition worst case | Current dual-channel IQ for all 15 repetitions | Log antenna routing and gains, collect a controlled reference/surveillance swap capture | `pwelch`, `bandpower`, Signal Analyzer | `RFH-001`, `RFH-002` | Can force `diagnostic` or `rejected` |
| Are either channels clipping, saturating, or quantization-limited? | Severe clipping invalidates downstream RF interpretation | Clipped-sample fraction, PAR, histogram occupancy near rails | Current sample amplitudes | Repeat stepped-gain captures and record front-end gain state | Vectorized sample statistics, `spectrumAnalyzer` | `RFH-001` | Severe case can force `rejected` |
| Is DC or LO leakage large enough to contaminate near-zero interpretation? | Large DC can distort direct-path and later map interpretation | DC magnitude relative to RMS, narrowband DC-neighborhood power fraction | Current samples and PSD | Add terminated-input or covered-antenna noise captures | `pwelch`, `bandpower` | `RFH-001`, `RFH-002` | Usually `diagnostic` or `retune` |
| Is IQ imbalance or image energy material? | Image terms can distort channel-health interpretation and direct-path assessment | Image rejection proxy, amplitude and phase imbalance indicators, repetition spread | Current spectral content | Add calibration capture or single-tone reference if available | `iqimbal2coef`, PSD image analysis | `RFH-001` | Usually caveat-driven `diagnostic` |
| Is the illuminator band present, occupied, and stable across repetitions? | Sync and passive-map work depend on usable illuminator content | Occupied bandwidth, in-band power ratio, spectral centroid drift, PSD similarity across repetitions | Current IQ across all captures | Longer dwell or concurrent spectrum-monitor capture | `obw`, `bandpower`, `pwelch`, `spectrogram` | `RFH-002` | Weak stability can force `diagnostic` |
| Are narrowband spurs, impulsive bursts, or unexpected interferers dominating the band? | Dominant interference can make later sync and mapping untrustworthy | Spur count above mask, spur-to-bandpower ratio, burst duty cycle, worst-bin prominence | Current PSD and time-frequency views | Quiet-scene control capture and environment annotation | `spectrogram`, `islocalmax`, Signal Analyzer | `RFH-002` | Severe case can force `rejected` |
| Is usable direct-path energy present in the surveillance channel? | Direct-path usability is required before opening G3/G4 work | Coarse direct-path prominence over local floor, per-repetition peak spread | Current paired channels | Improve antenna geometry or collect a stronger reference-oriented setup | `xcorr`, `finddelay`, `ambgfun`, `mscohere` | `RFH-002` | Weak but usable becomes `diagnostic` |
| Are candidate CPI windows coherently usable and stationary enough for later processing? | A repetition can look good in aggregate PSD while still being unusable for coherent downstream processing | Subwindow coherence pass fraction, lag-spread percentile, abrupt power or spectrum change flags, phase or frequency stability trend | Current IQ with candidate CPI windowing | Add longer dwell and stable-clock captures intended specifically for CPI-level analysis | `mscohere`, `finddelay`, `spectrogram` | `RFH-002` | Weak CPI usability forces `diagnostic` or readiness downgrade |
| Is there enough usable surveillance dynamic range and local separation from direct-path or clutter to give a credible shot at aircraft-related signatures? | A dataset can be RF-clean yet still have no realistic chance of exposing later aircraft-related structure | Direct-path-to-floor ratio, direct-path-to-clutter ratio, usable dynamic range after excluding clipped and DC-contaminated regions, off-zero-Doppler occupancy | Current IQ and coarse ambiguity or time-frequency previews | Improve geometry, gain distribution, dwell length, or reference antenna isolation | `pwelch`, `bandpower`, `spectrogram`, `ambgfun` preview | `RFH-002`, `RFH-003` | Weak separation usually forces readiness downgrade |
| Are impairments isolated to a few repetitions or systemic across the session? | Gate decisions should not be based on averages that hide critical failures | Worst-case repetition index, failure count, median-vs-worst spread, repetition trend charts | Metrics from all captures | Add repeated-session acquisitions and notes on scene changes | MATLAB tables, `tiledlayout` figures | `RFH-003` | Controls `golden` vs `diagnostic` |
| Do we have enough acquisition metadata to explain RF-health results later? | Missing context weakens traceability and customer communication | Presence or absence audit in `config_snapshot.json` and classification note | Current manifest and session metadata | Add SDR clock, gain, geometry, illuminator, and environment metadata to future manifests | MATLAB tables, JSON snapshots | `RFH-003` | Usually caveat-driven `diagnostic` |

### Downstream Readiness Annex

These questions are non-scoring for G2. They exist so the session captures what the recorded data can or cannot support in later gates.

| Downstream area | Readiness question | Quantitative method | If insufficient, acquisition change | MathWorks tools | Status values |
| :--- | :--- | :--- | :--- | :--- | :--- |
| G3 Sync | Is direct-path or reference content stable enough to support repeatable lag estimation? | Lag spread, correlation peak-to-sidelobe ratio, in-band coherence | Improve reference antenna placement and collect longer reference-rich captures | `finddelay`, `xcorr`, `mscohere` | `ready`, `caveated`, `blocked` |
| G3 Sync | Is residual frequency or phase drift plausibly small enough for one correction strategy to be viable? | Cross-spectrum phase trend, coherence decay across subwindows, spectrogram ridge drift | Log shared-clock or GPSDO status and add calibration captures | `spectrogram`, `mscohere` | `ready`, `caveated`, `blocked` |
| G4 Passive Baseline Map | Is the occupied illuminator band clean enough to support a plausible baseline map? | In-band vs out-of-band power, occupied bandwidth, spur occupancy | Add quiet-scene and configuration-controlled captures | `pwelch`, `obw`, `bandpower` | `ready`, `caveated`, `blocked` |
| G4 Passive Baseline Map | Is surveillance direct path visible without saturating the receiver? | Zero-lag prominence proxy, clipping fraction, PAR, direct-path-to-floor ratio | Adjust gain and capture geometry | `xcorr`, `ambgfun` preview | `ready`, `caveated`, `blocked` |
| G5 Mitigation | Is reference-surveillance correlation high enough for adaptive cancellation to be worth trying? | Band-limited coherence, cross-spectrum consistency, power ratio | Add a cleaner dedicated reference channel | `mscohere`, `bandpower` | `ready`, `caveated`, `blocked` |
| G5 Mitigation | Is there observable nonzero-Doppler energy that later mitigation must protect? | Off-zero-Doppler energy fraction and time-frequency occupancy | Increase dwell or collect geometry with more bistatic velocity diversity | `spectrogram`, Signal Analyzer | `ready`, `caveated`, `blocked` |
| G7 Truth Alignment | Can each repetition or CPI be placed on an absolute radar timeline with explicit uncertainty? | Timestamp completeness, monotonicity, uncertainty budget against frozen G1 timing | Add PPS, trigger, and absolute-time status logs | `datetime`, `timetable`, `synchronize` | `ready`, `caveated`, `blocked` |
| G7 Truth Alignment | Do we have enough geometry and context metadata to define later truth windows? | Presence or absence audit for receiver position, illuminator ID, antenna orientation, and RF settings | Add site survey and receiver/illuminator metadata | `timetable`, metadata tables | `ready`, `caveated`, `blocked` |

Any readiness item marked `blocked` means there is acquisition debt or missing context. It does not, by itself, force G2 rejection unless it also violates core G2 RF-health criteria.

### Aircraft-Analysis Readiness Screen

G2 must answer a separate question from basic RF health: does the dataset give a credible shot at later aircraft-related analysis, or is it only suitable for diagnostics and hardware validation?

Required screen inputs:

- collection validity established from hardware-state evidence and control captures
- reference and surveillance channel roles validated
- direct path is usable but does not consume the available surveillance dynamic range
- enough coherent CPI windows remain after excluding bad intervals
- illuminator continuity and bandwidth are compatible with later passive processing
- geometry and scene metadata are sufficient to interpret a null result

Required readiness verdicts:

- `fit_for_later_aircraft_related_analysis`
- `diagnostic_use_only`
- `insufficient_evidence`

This verdict is advisory and orthogonal to the legal gate outcome. A dataset may legally pass G2 as `diagnostic` while still being judged only `diagnostic_use_only` or `insufficient_evidence` for later aircraft-related analysis.

### Decision Logic

Keep the legal gate outcomes consistent with [ProjectPlan.md](ProjectPlan.md):

- `pass`
- `retune`
- `reject`

Lock the G2 classification policy as follows:

- `golden`:
  all critical G2 metrics maintain healthy margin across repetitions and no dominant impairment is likely to distort sync or map formation
- `diagnostic`:
  the data is still usable for later gate work, but one or more impairments or missing metadata items must be carried explicitly downstream
- `rejected`:
  the reference channel or illuminator-band environment is too poor to justify continued processing

G2 must also emit two orthogonal non-gate verdicts:

- collection-validity verdict:
  `hardware_configuration_validated`, `hardware_state_partially_evidenced`, or `hardware_state_not_established`
- aircraft-analysis readiness verdict:
  `fit_for_later_aircraft_related_analysis`, `diagnostic_use_only`, or `insufficient_evidence`

Decision rules:

- worst-case repetition and CPI-window behavior can override favorable averages
- G2 retune is limited to thresholds, averaging windows, reporting cut points, and diagnostic presentation choices
- missing hardware-state evidence, missing channel-mapping proof, or missing control captures cannot support a collection-validity verdict of `hardware_configuration_validated`
- missing collection-validity evidence or geometry/context evidence cannot support an aircraft-analysis readiness verdict of `fit_for_later_aircraft_related_analysis`
- a legal G2 `pass` is still allowed when the dataset is `diagnostic`, but `next_branch.txt` must explicitly hold downstream aircraft claims and recommend recollection or validation when readiness is `diagnostic_use_only` or `insufficient_evidence`
- acquisition-state uncertainty must not be silently reinterpreted as scene difficulty; it must be called out separately in the collection-validity verdict
- any finding that implies a changed ingest contract, changed timing authority, or changed CPI contract reopens G1
- RF hard-failures, severe clipping, or dominant interference still drive a legal `reject`

Recommended advisory branch values for `next_branch.txt`:

- `ProceedToG3_WithCaveats`
- `HoldForCollectionValidation`
- `RecollectBeforeAircraftClaims`

### Evidence Bundle Plan

Keep the standard bundle structure and predeclare the G2-specific filenames.

Bundle root:

```text
artifacts/<datasetId>/G2_RF_Health/<runTimestampZ>/
```

Required standard files:

- `summary.md`
- `requirements_coverage.csv`
- `config_snapshot.json`
- `metrics.json`
- `metrics.mat`
- `decision.txt`
- `failure_cause.txt` when needed
- `next_branch.txt`

Required G2-specific files:

- `dataset_classification_note.md`
- `receiver_state_table.csv`
- `collection_validity_note.md`
- `figures/figure_01_rf_health_table.png`
- `figures/figure_02_psd_reference.png`
- `figures/figure_03_psd_surveillance.png`
- `figures/figure_04_direct_path_prominence_summary.png`
- `figures/figure_05_repetition_health_overview.png`
- `figures/figure_06_frequency_phase_stability.png`
- `figures/figure_07_cpi_usability_summary.png`
- `figures/figure_08_spur_fingerprint_by_channel.png`

Minimum RF-health table fields:

- repetition index
- RMS power per channel
- PAR per channel
- clipped fraction per channel
- DC offset magnitude per channel
- in-band power per channel
- occupied bandwidth per channel
- spur occupancy metric
- direct-path prominence metric
- coherence precheck metric
- provisional repetition label
- caveat notes

Required decision-traceability content inside `summary.md`:

- decision item
- metric or evidence used
- threshold or threshold-selection rule
- worst-case repetition or CPI index
- supporting artifact path
- effect on gate decision, classification, collection-validity verdict, or aircraft-analysis readiness verdict

Annex status fields to include in `summary.md` and machine-readable metrics:

- downstream area
- readiness question
- status: `ready`, `caveated`, or `blocked`
- rationale
- acquisition recommendation

Required collection-validity fields inside `config_snapshot.json`:

- SDR make, model, serial number, and firmware or driver version
- center frequency, sample rate, analog bandwidth or filter setting, and gain per channel
- AGC state, clock source, PPS source, LO reference source, and lock status
- channel-to-port mapping, antenna ID, polarization, cable mapping, and preamp or attenuator state
- capture start and stop UTC
- dropped-sample, overflow, overrun, retune, and configuration-change indicators when available

Required additional machine-readable metrics in `metrics.json` and `metrics.mat`:

- CPI usability pass fraction
- worst-case CPI index
- frequency or phase stability summaries across repetitions
- spur fingerprint summaries by channel
- collection-validity verdict
- aircraft-analysis readiness verdict

### File and Function Plan

Planned implementation artifacts:

- helper-level RF-health metric functions in separate helper files
- `runG2RFHealth.m` gate runner
- `runPassiveBistaticPiplineLiveScript.m` update to replace the G2 placeholder with the real gate call
- unit and integration test scaffolding for G2 metrics and bundle completeness

Potential helper split:

- `helperComputeRFHealthMetrics.m`
- `helperClassifyRFHealth.m`
- `helperAssessCollectionValidity.m`
- `helperComputeCPIUsability.m`
- `helperBuildDecisionTraceabilityTable.m`
- `helperWriteG2EvidenceBundle.m`
- `helperRenderG2RFHealthFigures.m`
- `helperBuildG2ReadinessAnnex.m`

Use separate helper files unless there is a strong local reason not to.

## Butterfly Visual Plan

This section is intentionally sequenced after the technical plan. The butterfly assets should inherit the stabilized outputs of the technical G2 implementation rather than define separate logic.

### Visual Intent

Create a G2-specific communication package that helps both internal teams and customers understand:

- what data enters G2
- what questions G2 answers
- what evidence G2 produces
- how G2 decides `golden`, `diagnostic`, or `rejected`
- whether the hardware and acquisition state were actually validated
- whether the dataset is fit for later aircraft-related analysis or only diagnostic use
- what downstream readiness signals are surfaced without claiming later gates are complete

### Butterfly Content Model

The butterfly layout should be organized around a central `G2 RF Health` node.

Left wing content:

- frozen G1 ingest contract
- available recorded data and metadata
- core recorded-data questions
- per-repetition plus aggregate quantitative metrics

Center content:

- `RFH-001`, `RFH-002`, `RFH-003`
- gate-local decision logic
- `pass / retune / reject`

Right wing content:

- required evidence bundle outputs
- dataset classification
- collection-validity verdict
- aircraft-analysis readiness verdict
- carry-forward caveats
- hold or recollect advisory when applicable
- downstream-readiness annex for G3, G4, G5, and G7

The downstream-readiness annex must be visually separated from scoring G2 content so it is obvious that later gate ownership remains intact.

### Visual Deliverables

The butterfly package should include:

- source-of-truth Markdown file for the G2 butterfly content
- standalone PNG overview for quick sharing
- editable PowerPoint deck for customer communication

Planned output artifacts:

- `docs/flowcharts/G2_RF_Health_Butterfly.md`
- `artifacts/communication/G2_RF_Health/G2_RF_Health_Butterfly.png`
- `artifacts/communication/G2_RF_Health/G2_RF_Health_Butterfly.pptx`

These communication assets are gate-level deliverables, not run-specific evidence-bundle files. They should therefore live outside:

```text
artifacts/<datasetId>/G2_RF_Health/<runTimestampZ>/
```

The run-specific G2 bundle remains the source for technical evidence, while the communication folder provides stable, reusable customer-facing assets for the gate.

### Visual Generation Approach

Reuse the existing repo pattern used for the pipeline flowchart:

- repo-controlled Markdown source
- MATLAB generator entry point
- layout helper
- PowerPoint COM automation for editable slides
- PNG export driven from the same source content

Planned MATLAB artifact-generation files:

- `generateG2RFHealthButterflyPpt.m`
- `helperParseG2ButterflyMarkdown.m`
- `helperBuildG2ButterflyPptLayout.m`
- `helperRenderG2ButterflyFigure.m`

Recommended PowerPoint structure:

- slide 1:
  customer-facing G2 butterfly overview
- slide 2:
  regeneration notes, source markdown path, and traceability to the G2 evidence outputs

### Dependency of Butterfly on Technical Outputs

The butterfly content should be populated from the technical G2 outputs in this order:

1. frozen G1 session contract
2. approved G2 question set
3. approved quantitative metrics and thresholds
4. approved G2 evidence bundle structure
5. approved classification policy
6. approved downstream-readiness annex fields

The butterfly diagram should not invent any metric, artifact, or decision rule that does not already exist in the technical portion of this plan.

The generated PNG and PowerPoint should consume the approved G2 outputs and then be written to the gate-level communication folder:

```text
artifacts/communication/G2_RF_Health/
```

That separation keeps customer-facing communication assets distinct from evidence bundles that are tied to a specific dataset and run timestamp.

## Test and Acceptance Checks

### Technical Checks

- every core G2 question maps to `RFH-001`, `RFH-002`, or `RFH-003`
- every question has both a quantification path and an acquisition-change fallback
- collection-validity evidence is captured and evaluated separately from RF-scene quality
- aircraft-analysis readiness verdict is emitted separately from the legal gate outcome
- helper API can run independently from the gate runner
- gate runner writes a complete evidence bundle
- pipeline integration runs G1 then G2 and stops at the next unimplemented gate
- worst-case repetition behavior is preserved in decision logic and not hidden by averages
- worst-case CPI-window behavior is preserved in decision logic and not hidden by repetition averages
- missing hardware-state metadata or missing control captures downgrade the collection-validity and readiness verdicts
- decision-traceability content is written into `summary.md` and machine-readable metrics
- `next_branch.txt` uses a hold or recollection advisory when downstream aircraft claims should not proceed

### Visual Checks

- the butterfly slide clearly separates scoring G2 content from non-scoring readiness content
- the PNG is legible as a standalone overview artifact
- the PowerPoint slide is editable and text remains editable shapes
- the butterfly output inherits the exact technical outputs and filenames defined earlier in this plan
- the butterfly explicitly shows dataset classification, collection-validity verdict, and aircraft-analysis readiness verdict as distinct outputs
- regeneration is deterministic:
  edit the source markdown, rerun the generator, review updated PNG and PPT

## Assumptions

- `ProjectPlan.md` stays canonical
- `G2Plan.md` is the integrated working plan for manual refinement before coding
- `diagnostic` remains a G2 pass with explicit caveats
- the current reference dataset for G2 planning is still `20260622T102123`
- `20260713T150404` is the current hardware comparison candidate and not the default single-session reference
- cross-session hardware evaluation is advisory and should use saved comparison snapshots rather than changing the single-session stage logic
- the latest passed G1 bundle is the upstream truth for planning
- existing MATLAB, Communications Toolbox, Signal Processing Toolbox, DSP System Toolbox, Phased Array System Toolbox, and PowerPoint COM automation remain available for later implementation

## Council Review - RF Engineering Expert

The plan already captures the right RF backbone for G2. It correctly treats G2 as an RF-health gate, keeps scoring focused on channel health and spectral suitability, and emphasizes per-repetition plus worst-case metrics rather than relying on averages that can hide a bad capture. The current inclusion of clipping, DC, IQ imbalance, illuminator occupancy, interference, and direct-path usability is strong and is aligned with what an RF engineer would want before trusting downstream bistatic processing.

The main RF gap is that the plan is still more data-quality-centric than hardware-state-centric. A future bad collection could look like a difficult RF scene when the real problem is hardware misconfiguration or degraded front-end behavior. G2 should explicitly confirm that the receiver chain was operating in a valid state at collection time, not just that the resulting IQ looks plausible.

- Add explicit hardware-state checks or metadata for each collection:
  RF center frequency, sample rate, analog bandwidth or filter setting, gain per channel, AGC state, clock source, LO reference source, lock status, antenna assignments, antenna polarization, cable mapping, preamp or attenuator state, and any front-end overload indicator available from the SDR.
- Add RF sanity checks that separate hardware faults from scene effects:
  reference-channel SNR margin over surveillance, band-edge roll-off asymmetry, persistent spur fingerprint by channel, DC and image stability across repetitions, channel-to-channel power consistency relative to declared gain settings, and evidence of clock or LO instability from phase drift or spectral wandering.
- Add a receiver-baseline acquisition recommendation:
  one terminated-input or antenna-covered capture, one quiet-sky or low-activity capture, and one stepped-gain capture. Those three captures give a much better basis for deciding whether spurs, DC, or compression are receiver-generated versus environmental.
- Add a known-signal calibration recommendation:
  if the illuminator has stable pilot or carrier structure, verify frequency placement and drift against that known feature. If not, add a controlled calibration source or tone when feasible. This is one of the cleanest ways to detect LO error, sample-rate error, or unexpected retuning.

For aircraft-detection credibility, the plan should be more explicit about dynamic range and geometry sufficiency. A dataset can pass basic RF-health checks and still be a poor candidate for aircraft signatures if the direct path dominates too heavily, the surveillance channel has insufficient headroom, the illuminator is intermittent, or the expected Doppler region is buried under clutter or interference.

- Add checks that answer "do we have a credible shot?" instead of only "is the capture clean?":
  direct-path-to-noise-floor ratio, direct-path-to-clutter-floor ratio, usable surveillance dynamic range after excluding clipped and DC-contaminated regions, stability of the illuminator over the full dwell, and whether off-zero-Doppler energy is observable above interference and receiver artifacts.
- Add geometry-aware acquisition metadata:
  receiver location, antenna pointing or boresight, antenna separation, expected illuminator azimuth, illuminator identity and frequency, approximate collection time relative to expected air traffic, and any known obstructions or moving clutter sources. Without this, a later non-detection is hard to interpret as hardware failure versus an unfavorable scene.
- Add an explicit "insufficient for aircraft-signature assessment" outcome inside the annex:
  use it when RF health is acceptable but the collection lacks the dynamic range, geometry context, dwell stability, or metadata needed to make a defensible statement about aircraft detectability.

Recommended evidence additions are modest but important:

- add a receiver-state table to `summary.md` and `config_snapshot.json`
- add a spur fingerprint summary by channel to `metrics.json`
- add a phase or frequency stability plot across repetitions to the figures set
- add a short collection-readiness note that states whether the evidence supports:
  hardware appears to be operating correctly,
  hardware state cannot be confirmed from available evidence,
  or data is RF-clean but still insufficient to support a credible aircraft-detection attempt

From an RF engineering standpoint, the plan is close, but it should more clearly distinguish three decisions: whether the hardware behaved correctly, whether the RF environment was usable, and whether the combination gives a realistic chance of observing later aircraft-related signatures. Those are related, but they are not the same decision, and G2 should report them separately.

## Council Review - Bistatic Radar Expert

The plan already captures several of the right bistatic gate questions. It correctly treats direct-path usability, illuminator-band stability, coherence-readiness, and repetition-to-repetition consistency as prerequisites for later passive processing instead of assuming that a clean RF capture is automatically useful for aircraft detection. It also correctly keeps G2 from over-claiming G3 synchronization or G4 map success.

- The largest remaining gap is geometry accountability. Passive bistatic viability depends on whether the transmitter, receiver, and aircraft can create usable bistatic delay and Doppler separation, not just whether both channels look healthy. G2 should explicitly state that a dataset can be RF-clean yet still be a poor aircraft-detection candidate if the collection geometry places targets too close to the direct-path ridge or strong clutter regions.
- Channel-role confidence needs to be stronger. The plan assumes one channel acts as reference and one as surveillance, but aircraft-detection confidence depends on knowing that the reference channel is dominated by illuminator energy and that the surveillance channel preserves the same illuminator with additional scene returns. If that role separation is weak or ambiguous, later cancellation and cross-ambiguity products can fail even when PSD metrics look acceptable.
- Coherence-readiness should include a bistatic decision threshold, not only a general readiness note. For aircraft detection, it is not enough to observe some lag estimate or some coherence. G2 should ask whether the direct path is stable enough in delay, phase, and frequency over a CPI that later range-Doppler formation has a plausible chance of producing a sharp direct-path reference and interpretable target sidelobe environment.
- Illuminator suitability needs a passive-radar framing. The plan checks occupancy and stability, which is good, but it should also ask whether the chosen transmitter has enough bandwidth, continuity, and waveform structure to support bistatic range and Doppler discrimination for aircraft. A strong but narrow or highly intermittent illuminator can still be a poor aircraft-detection source.
- Collection-time knowledge is still underspecified for deciding whether a non-detection means bad hardware, bad geometry, or simply no favorable target opportunity. G2 should require collection metadata for receiver location, receiver heading or antenna boresight, reference and surveillance antenna placement, antenna polarization, baseline separation, illuminator identity and approximate location, collection start and stop time, and any expected aircraft traffic window or scene notes.
- Add explicit evidence that links RF health to passive detectability:
  a geometry note or simple bistatic sketch in `summary.md`,
  a channel-role confidence statement in `dataset_classification_note.md`,
  a direct-path stability figure showing lag or phase consistency across repetitions,
  an illuminator suitability note that states whether the transmitter bandwidth and continuity are compatible with aircraft detection,
  and an annex verdict such as `plausible for aircraft detection`, `usable for hardware validation only`, or `not sufficient to assess aircraft detectability`.
- Add concrete mitigation paths before the next collection:
  capture one session with a deliberately strengthened reference antenna view,
  record exact antenna placements and pointing during setup,
  capture enough dwell to observe stable direct-path behavior across multiple CPIs,
  log clock-sharing or timing-reference configuration explicitly,
  and, when possible, choose a time and geometry with known air traffic or another cooperative opportunity so that a later null result is interpretable.

From a bistatic radar perspective, the key missing decision is not just "is the IQ healthy?" but "does this collection geometry and illuminator/reference arrangement give us a credible path to aircraft observability?" G2 should report that explicitly so future hardware runs can be judged as usable, geometry-limited, or fundamentally inadequate for passive aircraft detection.

## Council Review - Signal Processing Expert

The plan already captures several of the right signal-processing foundations. It uses native MATLAB spectral and coherence tools, separates scored G2 checks from later-gate readiness, and emphasizes per-repetition plus worst-case behavior instead of hiding failures behind session averages. That is the right starting point for deciding whether the IQ is merely well-formed or actually usable for later coherent processing.

- The current plan is strongest on gross RF-health observables: clipping, DC, IQ image risk, occupied bandwidth, spur screening, direct-path presence, and repetition-to-repetition stability. Those are necessary checks for signal integrity and spectral usability, and they should stay in the core G2 path.
- The largest signal-processing gap is CPI-level coherence and stationarity. A repetition can look acceptable in aggregate PSD while still containing phase discontinuities, drift, dropped-sample effects, burst interference, or gain changes that break coherent integration. G2 should add windowed metrics over candidate CPI lengths: in-band coherence percentile, lag spread percentile, and abrupt change flags for power or spectrum over time.
- The plan should be more explicit about continuity and sample-integrity checks. Add evidence for exact sample counts, per-file continuity, timestamp monotonicity, unexpected amplitude or phase jumps, and whether any SDR overflow or dropped-sample indicators were logged. If those checks are absent, the data may be suitable only for diagnostic PSD review rather than later aircraft-related detection work.
- Spectral usability needs a stronger mask-based framing. In addition to occupied bandwidth and total in-band power, G2 should measure how much of the presumptive illuminator band is actually usable after excluding DC neighborhoods, persistent spurs, and burst-contaminated intervals. A strong illuminator that is only clean over a small fraction of the band may still be poor for later range or Doppler discrimination.
- Coherence-readiness should not rely on one average `mscohere` result per repetition. Use subwindow distributions and report the fraction of CPI windows that satisfy the coherence and lag-stability criteria. This gives a much better decision boundary for "plausible for aircraft detection" versus "diagnostic only."
- Detectability potential is still under-specified. G2 should add a non-scoring plausibility screen for whether coherent processing is likely to produce interpretable off-direct-path structure later. That screen should be based on direct-path peak sharpness, local ambiguity-floor separation, off-zero-Doppler energy occupancy, and how consistently those observables persist across repetitions. If those indicators are weak or unstable, the current IQ should be labeled as hardware-validation or diagnostic data, not aircraft-detection-ready data.
- Thresholding should be defined as a combination of worst-case behavior and pass fraction. A good pattern is to require both:
  a minimum percentage of CPI windows to meet coherence and direct-path-prominence criteria,
  and no severe clipping or dominant-interference failure in any repetition.
  Without a CPI pass-fraction concept, the plan risks accepting data that is only intermittently coherent.
- Add acquisition metadata that directly supports signal-processing interpretation: exact center frequency, sample rate, clock source and lock status, gain state per channel, overflow or overrun flags, any retune event, channel-to-physical-antenna mapping, and a note on whether the illuminator has known pilot or carrier structure that can be used as a stability reference.
- The mitigation path should include three concrete additions for future collections:
  one receiver-baseline capture with antennas covered or terminated,
  one stepped-gain capture to expose compression and quantization margins,
  and one longer dwell intended specifically to test CPI-to-CPI coherence stability.
- The evidence bundle should add a few compact but high-value items:
  a CPI usability summary table,
  a PSD or spectrogram consistency heatmap across repetitions,
  a lag-stability or direct-path-sharpness trend plot,
  and an annex verdict with explicit wording such as `sufficient for later detection processing`, `diagnostic only`, or `insufficient to assess aircraft detectability`.

From a signal-processing perspective, the key missing distinction is between data that is spectrally plausible and data that is coherently usable. G2 should explicitly report that distinction so a future collection can be judged not just as RF-clean, but as having a realistic chance of supporting later aircraft-related detection products.

## Council Review - SDR Hardware and Data Acquisition Expert

The current G2 plan already captures several things well for hardware-facing review. It asks the right downstream questions about clipping, direct-path usability, coherence readiness, metadata sufficiency, and per-repetition stability, which are all necessary if you want to tell the difference between a clean collection and one that only looks acceptable in aggregate. The existing evidence-bundle structure is also strong enough to carry hardware-state evidence if that evidence is explicitly collected.

The main gap is that the plan still assumes the SDR chain state can be inferred from IQ alone. That is not reliable enough for future aircraft-related runs. A bad clock source, unintended AGC change, swapped channels, wrong antenna connection, intermittent overrun, retune event, or front-end overload can all produce data that is ambiguous later. G2 should explicitly prove whether the collection setup was valid at the time of capture, not just whether the saved IQ passes spectral checks.

- Add mandatory collection metadata to `config_snapshot.json` and summarize it in `summary.md`:
  SDR make/model and serial number, firmware/driver version, center frequency, sample rate, channel bandwidth, gain per channel, AGC/manual state, clock source, PPS or trigger source, lock status, channel-to-port mapping, antenna ID per channel, antenna polarization, cable path, preamp/attenuator state, and host machine identifier.
- Add mandatory acquisition-status evidence:
  capture start/stop UTC, file manifest with sizes and hashes, dropped-sample or overrun counters, retune events, operator-entered notes, and whether any setting changed mid-run. If the radio or driver exposes temperature, reference lock, or overflow flags, capture them too.
- Add an explicit channel-mapping proof step:
  before the main collection, record a short verification capture where only the intended reference chain sees the strongest illuminator view, or inject a known tone into one receive path. The evidence should show that the declared reference and surveillance channels are physically correct.
- Add a receiver-baseline procedure:
  one terminated or antenna-covered capture, one quiet-scene capture, and one stepped-gain capture. These establish the receiver noise floor, DC/spur fingerprint, compression margin, and whether gain changes behave as expected.
- Add a clock-validity procedure:
  log the selected clock and PPS source before capture, record lock status, and keep a short stable-source verification capture that can expose drift or sample-rate error. If shared clocking is intended, the absence of lock evidence should force a caveat or invalid collection outcome.
- Add an operator checklist that must be completed at collection time:
  confirm antenna labels and placement, confirm cable routing, confirm gains match the run sheet, confirm manual gain is fixed if required, confirm no overruns during capture, confirm storage path and dataset ID, and record a site photo or sketch when geometry matters.
- Add an explicit acquisition verdict in the annex:
  `hardware configuration validated`, `hardware state partially evidenced`, or `hardware state not validated`. This should sit alongside the RF-health and detectability language so a future non-detection is not misread as an aircraft or algorithm issue when the collection itself was not trustworthy.

For later aircraft-related analysis, G2 should make one additional decision explicit: whether the run is valid for aircraft observability assessment, not just for RF diagnostics. That requires both acceptable IQ metrics and trustworthy acquisition evidence. If clocking, channel mapping, gain state, antenna identity, or overrun status cannot be proven from metadata and verification captures, the dataset should be labeled as unsuitable for a defensible aircraft-detection conclusion even if the RF plots look reasonable.

Recommended mitigation for the next hardware session is straightforward: require a pre-run checklist, collect short verification captures before the main dwell, freeze and log all receiver settings, forbid unlogged mid-run changes, capture baseline noise and stepped-gain references, and write enough operator metadata that a later reviewer can say with confidence whether the hardware was configured correctly. That is the difference between "interesting IQ was recorded" and "this collection is technically valid for later aircraft-related analysis."

## Council Review - Verification and Validation Expert

From a V&V perspective, the plan already captures several important strengths. It fixes the upstream contract, preserves gate ownership, requires per-repetition and worst-case evaluation, and predeclares an evidence bundle instead of relying on informal plots and narrative judgment. That is the right foundation for a defensible decision because it makes later review reproducible and limits silent reinterpretation of the dataset.

The main remaining risk is that the plan is currently easier to execute than to defend. The observables are strong, but the acceptance logic still needs clearer objective boundaries and a specific branch for cases where the data is not invalid yet still cannot support a defensible aircraft-analysis claim.

- Add an orthogonal readiness verdict alongside `golden`, `diagnostic`, and `rejected`:
  `fit for later aircraft-related analysis`, `diagnostic use only`, or `insufficient evidence`.
  This prevents a technically acceptable G2 run from being overstated as aircraft-detection-ready when geometry, metadata, continuity, or acquisition-state evidence is missing.
- Add a decision-traceability table in `summary.md` and `metrics.json`:
  each verdict should cite the exact metric, threshold or threshold-selection rule, worst-case repetition or CPI index, and the evidence artifact that supports it.
  Without this, proceed, hold, or reject outcomes will be hard to defend in later customer or internal review.
- Define objective acceptance checks, not just candidate metrics:
  required files present, all repetitions analyzed, no unexplained sample-count mismatch, timestamps monotonic, configuration captured, no severe clipping or dominant-interference hard-fail, and a minimum pass fraction across repetitions or CPI windows for coherence and direct-path readiness.
- Add an explicit `hold` branch:
  use it when the IQ is not demonstrably invalid but the evidence package is incomplete, the hardware state cannot be confirmed, or the dataset is only suitable for diagnostic learning.
  Reserve `reject` for data that is affirmatively unfit because of severe RF or acquisition failures.
- Add evidence-completeness checks as first-class acceptance criteria:
  if channel-mapping proof, clock or lock status, gain state, or required collection metadata is missing, the plan should automatically downgrade the dataset to `diagnostic use only` or `hold`, even if the PSD figures look reasonable.
- Add negative-control and baseline evidence requirements for future collections:
  terminated or covered-input capture, quiet-scene capture, stepped-gain capture, and a channel-mapping verification capture.
  These are essential V&V controls because they separate hardware faults from scene effects.
- Add repeatability checks that support aircraft-related claims:
  require stability not only in averages, but also in worst-case repetition behavior and CPI-window pass fraction for direct-path prominence, coherence, and continuity.
  A dataset with intermittent usability should not be treated as equivalent to a stable dataset.
- Add failure-cause precedence rules:
  ingest or timing-contract defect reopens G1,
  acquisition-state uncertainty produces `hold` or `diagnostic use only`,
  RF hard-fail produces `reject`,
  aircraft-readiness uncertainty remains a non-scoring annex output and must not be silently upgraded by a passing RF-health score.
- Add one concise collection-validity statement to the evidence bundle:
  `hardware/configuration validated`,
  `RF usable but collection validity partially evidenced`,
  or `collection validity not established`.
  This is the minimum wording needed to defend whether a future non-detection says something about the scene, the hardware, or neither.
- Add implementation-time verification tests for the gate logic itself:
  missing-metadata case, missing-artifact case, worst-case override case, diagnostic-only case, hold case, and full reject case.
  G2 is not fully validated unless the decision branches are tested as rigorously as the metric calculations.

Closing these gaps will make G2 much more defensible. The plan is already strong on measuring signal condition; it now needs equally explicit checks for evidence completeness, decision traceability, and the distinction between "clean enough to study" and "fit to support later aircraft-related conclusions."
