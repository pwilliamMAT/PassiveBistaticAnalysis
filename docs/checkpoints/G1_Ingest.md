# G1 Ingest

This checkpoint defines the ingest acceptance contract for the repo and now has an executable MATLAB path through `loadIQData` and `runG1Ingest`.

## Objective

Establish a trusted ingest contract for session `20260622T102123` before RF analysis, synchronization, map formation, mitigation, detection, or tracking work is allowed to proceed.

## Pipeline Integration Note

- `runPassiveBistaticPipeline` is the long-lived orchestration entry point that will accumulate gate implementations over time.
- `runG1Ingest` is the current executable implementation of this gate and is the G1 stage that the pipeline script should call.
- `loadIQData` is the reusable ingest primitive beneath the G1 gate runner.
- The pipeline must stop after the last implemented gate and must not silently start later-gate execution before those gates are implemented and passed.

## Dataset Anchors for This Gate

- `session_manifest.json` lists `15` radar files, `capture_duration_s = 1`, `capture_repetitions = 15`, and `sample_rate_hz = 6144000`.
- Every observed radar file begins with `BasebandVer2.0.0`, so the ingest path must account for embedded file metadata instead of assuming a headerless binary payload.
- The embedded radar header includes `Label='Passive_Radar_Dual_Channel'`, `Antenna1="RF0:RX2"`, `Antenna2="RF1:RX2"`, `SessionID="20260622T102123"`, `RecordingUTC`, `Duration_s`, and `Repetition`.
- Observed radar file sizes are `49,152,283` to `49,152,285` bytes. That is consistent with a nominal `49,152,000` byte dual-channel `int16` payload plus small wrapper overhead, but the payload contract must still be confirmed.
- The manifest reports `capture_repetition_spacing_s = 1`, while embedded `RecordingUTC` deltas are about `3.205 s` to `7.727 s`. This must be reconciled against the actual capture workflow before being treated as a defect.

## Capture Provenance

The available capture context indicates the radar files were created with `comm.BasebandFileWriter`, one file per repetition, with metadata stamped immediately before the file writer was opened:

```matlab
seg = seconds(1);
nSeg = ceil(args.dur / seconds(seg));

for rr = 1:args.reps
    meta.DateTime = string(datetime('now','Format','yyyy-MM-dd_HH-mm-ss.SSS'));
    meta.RecordingUTC = posixtime(datetime('now', 'TimeZone', 'UTC'));
    meta.Repetition = rr;

    bbw = comm.BasebandFileWriter(written_files(rr), ...
        'SampleRate',      bbrx.SampleRate, ...
        'CenterFrequency', args.cf, ...
        'Metadata',        meta);

    for i = 1:nSeg
        data = capture(bbrx, seg);
        bbw(data);
    end

    release(bbw);
    pause(args.repspace);
end
```

## Agent-Critical Implications

- Preferred ingest path is native-baseband-reader first. Do not start from a raw `fread` assumption when the file provenance already points to `comm.BasebandFileWriter`.
- Each radar file represents one capture repetition, not an automatically continuous shard of a single long recording.
- `capture(bbrx, seg)` returns an `[N x 2]` complex matrix when two antennas are configured, so the canonical decoded form should be two complex channels before any later reshaping.
- `RecordingUTC` is a per-repetition wall-clock marker written before the writer opens. It is not, by itself, proof that successive files must be exactly one second apart.
- Inter-file timing must distinguish two different concepts: per-file IQ duration derived from sample count and `Duration_s`, and wall-clock spacing between repetitions, which can include acquisition overhead plus `args.repspace`.
- Default ordering key is `Repetition`, corroborated by manifest order, `DateTime`, and filename suffix.
- Cross-file sample continuity is not the default assumption. The default assumption is repetition-to-repetition consistency with intentional gaps between captures unless evidence shows otherwise.
- Cross-file CPI formation is not allowed by default. A later agent must justify it explicitly after the repetition timing model is frozen.

## Requirement IDs in Scope

- `ING-001` manifest and file-inventory reconciliation
- `ING-002` decode contract definition
- `ING-003` timing and seam continuity contract
- `ING-004` CPI segmentation contract

## Recommended Agent Workflow

1. Reconcile the manifest file inventory against the observed radar, truth, and log artifacts.
2. Scan the embedded radar headers and confirm the per-file metadata contract: sample rate, center frequency, repetition index, antenna names, duration, and timestamp fields.
3. Attempt the native baseband-reader path first and freeze the canonical decoded representation.
4. Confirm the channel contract: expected two complex channels, expected antenna order, expected sample count for one nominal repetition, and any wrapper overhead.
5. Freeze the timing model by separating per-file sample-span timing from inter-repetition wall-clock timing.
6. Check repetition continuity and any boundary defects without assuming the files are one continuous recording.
7. Freeze the CPI segmentation contract, explicitly stating whether segmentation is intra-file only or allowed to cross repetitions.
8. Emit the required evidence and record the gate decision as `pass`, `retune`, or `reject`.

## Technical Definition

### Manifest and Inventory Reconciliation

- Confirm that the manifest radar-file list, ADS-B file list, and log-file list match the observed filesystem inventory exactly.
- Verify byte counts for all radar files and explain any non-payload overhead explicitly.
- Lock the primary repetition order to embedded `Repetition` metadata, with manifest order and filename suffix used as corroborating checks.
- Confirm that there is one radar artifact per declared repetition and no silent missing repetition index.

### Decode Contract

- Document the chosen reader contract before any signal work begins.
- Preferred native MATLAB path: because the files were written with `comm.BasebandFileWriter`, first attempt the corresponding native baseband-file reader path and record the result.
- Fallback path: if a raw-reader path is required, document why the native path was rejected, then document the sample datatype, I/Q interleaving, channel order, header offset, footer handling, and complex-sample packing exactly.
- The canonical decoded representation should preserve the two-channel complex capture contract before any later reshaping for CPI or map formation.
- Explicitly record whether channel order is `RF0:RX2` then `RF1:RX2`, or the reverse, and how that is verified from metadata plus loaded data.

### Epoch Mapping and Timing Contract

- Map manifest `radar_epoch_utc`, per-file `RecordingUTC`, `DateTime`, and `Repetition` into a single session timing model.
- Explicitly separate `sample-span time` from `wall-clock repetition time`.
- `sample-span time` is derived from sample count, sample rate, and `Duration_s` and should support the expectation of one nominal second of IQ per file.
- `wall-clock repetition time` is derived from `RecordingUTC`, `DateTime`, loop overhead, and `pause(args.repspace)` and therefore may legitimately exceed one second between files.
- Declare the authoritative radar time base for downstream truth alignment and state whether `radar_epoch_utc` is a session anchor, a first-capture anchor, or only a corroborating field.
- If manifest spacing and embedded header spacing disagree, the decision log must state whether this is explained by the repetition capture model or whether it remains a true defect.

### Seam Continuity and CPI Segmentation

- Check repetition-to-repetition continuity at every file boundary for dropped repetitions, duplicated repetitions, metadata resets, decode-contract changes, or unexpected sample-count shifts.
- Do not require sample-contiguous stitching across file boundaries unless a later agent explicitly chooses and justifies a cross-file integration mode.
- Define the CPI segmentation contract in terms of allowable window starts, overlap, and whether segmentation is intra-file only or can cross repetitions.
- CPI segmentation must preserve later equivalence testing by keeping indexing and timing conventions stable.

## Inner Retune Loop

Only ingest assumptions may be retuned in this gate:

- reader selection
- header offset or wrapper handling
- sample datatype
- I/Q interleaving rule
- channel order
- stitch order
- epoch-mapping precedence
- interpretation of `RecordingUTC` versus sample-span timing
- CPI segmentation boundaries

No RF, synchronization, mitigation, or detector parameters may be tuned until G1 passes.

## Pass Metrics

- Manifest and observed inventory agree with no missing or extra required artifacts.
- Byte counts are reconciled to a declared decode contract.
- The decode contract reproduces channel count, sample count, and timing fields consistently across all `15` radar files.
- The timing model explains both one nominal second of IQ per repetition and the observed wall-clock spacing between repetitions.
- Repetition continuity checks show no unexplained defects at file boundaries after accounting for the per-repetition capture model.
- A single CPI segmentation contract is declared and is compatible with downstream map formation.

## Reject Conditions

- Missing files or duplicated files in the required radar/truth inventory
- Irreconcilable byte counts or undecidable header/footer handling
- Unresolved timing semantics after accounting for the per-repetition capture loop and `RecordingUTC` meaning
- Channel-order ambiguity that cannot be resolved from metadata or direct evidence
- Repetition or boundary defects that prevent stable per-file or explicitly approved cross-file CPI handling

## Required Evidence

- Manifest-vs-observed table
- Capture-provenance interpretation summary
- Seam continuity summary
- Decode contract summary
- Timing-contract note documenting the manifest-versus-header reconciliation decision
- CPI segmentation contract summary

## Expert Note

This checkpoint is part of the broader council-derived plan and was informed primarily by passive bistatic radar algorithm, RF/data-quality, requirements/V&V, and MATLAB test architecture review inputs.
