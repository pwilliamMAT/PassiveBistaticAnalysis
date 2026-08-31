# Evaluate SyntheticDataGeneration Output Through G1-G5

## Plan Status

- **Objective:** Demonstrate that packaged IQ produced by the `flightTest` SyntheticDataGeneration workflow can traverse the existing `PassiveBistaticRestart` G1-G5 analysis path.
- **Active milestone:** Run one selected synthetic capture part through a quick, explanatory MATLAB Live Script and obtain useful G1-G5 results without invoking the full development or verification suites.
- **Primary deliverable:** `runSyntheticHDTVG1ThroughG5LiveScript.m`, implemented as a plain-text MATLAB Live Script.
- **Definition of done:** The exact SyntheticDataGeneration package identified below is ingested, one generated `.bb` part reaches G5, the Live Script presents concise findings and useful figures, and one compact result file is saved without raw IQ.
- **Later milestone:** Change the part selection to `"all"` and evaluate all capture parts only after the single-part integration is stable.

## Required SyntheticDataGeneration Input

The implementation must use the output of the SyntheticDataGeneration pipeline. It must not substitute a hand-built fixture, a zero-filled test signal, or the separate G4.5 real-background synthetic-target suite.

The initial integration dataset is:

```text
C:\Users\pwilliam\agenticProjects\flightTest_SynthDataBranch\captures\seed_demo_20260730T155438811
```

This package was produced by `SyntheticHDTVSimulation/generateSyntheticHDTVSession` and contains:

- `session_manifest.json`
- 15 generated `.bb` files under `radar/`
- one second of IQ per part
- an 8 MHz sample rate
- a 599 MHz center frequency
- CH1 as surveillance and CH2 as reference
- capture-backed ADS-B under `truth/`
- `truth/scenario_truth.mat`
- a conditioned target-echo dataset based on a field-derived waveform seed

The script must validate the following manifest values before running G1-G5:

```text
data_origin = synthetic
generator_name = generateSyntheticHDTVSession
synthetic_radar_data_product = synthetic_hdtv_iq_session_v2
signal_mode = seed_backed_bistatic_v1
target_echo_dataset_mode = conditioned_target_echo_dataset_v1
capture_repetitions = 15
```

The package's current generator-side readiness record is not fully passing:

```text
readiness_check.status = fail
failure_classes = seed_preservation_failure
packaging_integrity_pass = true
target_placement_pass = true
```

The Live Script must display this as an upstream generator caveat. It may continue with exploratory G1-G5 processing because package integrity and target placement passed, but it must not silently relabel the generator result as a pass.

The committed Live Script must not contain the absolute user-specific path above. It will construct the current default from the PBR repository parent:

```matlab
syntheticDataRoot = fullfile(fileparts(repoRoot), ...
    "flightTest_SynthDataBranch", "captures");
sessionId = "seed_demo_20260730T155438811";
sessionRoot = fullfile(syntheticDataRoot, sessionId);
```

`sessionRoot` remains an editable input so the same workflow can later consume another exported synthetic package or a field package. No MATLAB source code will be loaded from the neighboring repository; only the packaged data product crosses the repository boundary.

## Scope Boundaries

### In scope

- The packaged SyntheticDataGeneration output described above.
- G1 ingest and package-integrity checks.
- G2 acquisition-applicability, receiver-integrity, and pilot-aware spectral checks.
- G3 lag, residual-frequency, and coherence analysis.
- G4 reduced-rate passive ambiguity-map formation.
- G5 comparison of no mitigation, conservative LMS, and aggressive LMS.
- One selected capture part during initial development.
- An `"all"` part-selection mode for later use.
- Inline explanations, concise computed results, and high-value visualizations.
- One compact MAT result artifact.

### Out of scope

- G4.5 synthetic target recovery.
- G6-G10.
- Detector or tracker work.
- Truth-centered detection claims.
- The complete PBR verification suite.
- The full five-CPI G4 sensitivity campaign.
- The G4 full-rate audit.
- The G5 diagnostic sidecar study.
- Changes to the SyntheticDataGeneration implementation.
- Regeneration of synthetic IQ from the PBR repository.
- Formal approval of any existing PBR gate.

## Phase 0: Protect the Existing PBR Work

### Question

Can the new integration work begin without losing or obscuring the substantial uncommitted progress already present in `PassiveBistaticRestart`?

### Actions

1. Review the staged, unstaged, and untracked PBR changes.
2. Confirm that raw `.bb` files, ZIP files, generated artifacts, and editor backups remain excluded.
3. Create a reviewed safety checkpoint of the existing work before changing shared ingestion or gate helpers.
4. Record the checkpoint commit SHA in the implementation notes.
5. Keep the synthetic quick-path changes in a separate outcome-focused commit.

### Completion evidence

- The pre-existing work is recoverable from Git.
- The worktree changes attributable to this milestone can be reviewed independently.
- No raw capture is added to Git.

## Phase 1: Identify and Bound the Input Session

### Question

Are we operating on a real output of the SyntheticDataGeneration pipeline, and exactly which acquisition parts will this run analyze?

### Actions

1. Resolve `repoRoot` with the existing PBR helper.
2. Resolve `sessionRoot` and read `session_manifest.json`.
3. Validate the generator-identifying fields listed above.
4. Inventory every manifest-declared radar and truth file.
5. Verify that all 15 radar parts exist even when only part 1 is selected for decoding.
6. Record the producer readiness status and failure classes.
7. Resolve channel roles explicitly from the generator contract:
   - surveillance channel index: 1
   - reference channel index: 2
8. Reject invalid, duplicate, out-of-range, or empty role assignments.

### Part-selection behavior

The implementation target is all acquisition parts, but the checked-in development setting is:

```matlab
partSelection = 1;
```

Later full-session execution is enabled by changing only:

```matlab
partSelection = "all";
```

Initial support is intentionally limited to part 1 or `"all"`. Arbitrary sparse selections such as `[1 8 15]` are deferred because existing G3/G4 logic assumes contiguous repetition numbering.

### Presentation

- Show a short setup summary using concise scalar output.
- Plot a selected-part signal overview.
- Do not print the entire manifest or long path-heavy tables.

### Stop conditions

Stop before G1 if:

- the manifest is missing or invalid;
- the package does not identify itself as SyntheticDataGeneration output;
- any selected radar file is missing;
- the selected `.bb` file is not two-channel complex IQ; or
- channel roles are ambiguous.

The existing `seed_preservation_failure` is a caveat, not an ingestion stop condition.

## Phase 2: G1 Ingest

### Question

Can PBR trust the selected generated `.bb` part's decode, timing, channel layout, and CPI boundary while retaining awareness of the complete 15-part package?

### Existing implementation to reuse

- `loadIQData`
- `helperScanBasebandCaptureFile`
- `comm.BasebandFileReader`

The Live Script will use the G1 ingest core directly. It will not call the artifact-heavy `runG1Ingest` runner.

### Required compatibility changes

1. Add a `PartSelection` option to `loadIQData`.
2. Preserve `"all"` as the default so existing callers do not change behavior.
3. Reconcile the entire manifest, but decode only selected radar parts.
4. Return both:
   - full package inventory information; and
   - selected-part analysis information.
5. Allow synthetic metadata that omits `Antenna1` and `Antenna2`.
6. Assign neutral labels such as `CH1` and `CH2` when antenna labels are absent.
7. Record the channel-label source as generated index labels.
8. Never use neutral labels to infer channel roles; use the explicit synthetic role mapping.

### Evidence to present

- Manifest session ID and generator identity.
- Declared, observed, and selected part counts.
- Sample rate, center frequency, sample count, and duration.
- Channel count and complex-data status.
- Selected-part decode path.
- Timing agreement between manifest and embedded metadata.
- Finite-sample and nonempty-data status.

### G1 success condition

G1 is `executed` when the full package inventory is coherent and the selected part decodes successfully. It is `caveated` if nonessential provenance is missing or the producer readiness record is not passing. It is `blocked` for missing files, decode failure, invalid timing, nonfinite data, or channel-contract failure.

## Phase 3: G2 RF and Pre-Detection Health

### Primary question

Are the generated reference and surveillance channels numerically healthy and spectrally suitable for synchronization and passive ambiguity processing?

### Secondary question

Which G2 acquisition checks are meaningful for synthetic data, and which are field-hardware questions that must not affect the synthetic result?

### Existing implementation to reuse

- `helperAnalyzeG2AcquisitionEvidence`
- `helperAnalyzeG2ReceiverIntegrity`
- `helperAnalyzeG2PilotAwareSignalQuality`
- `pwelch`
- `bandpower`
- `mscohere`
- `xcorr`

The Live Script will call helper-level analysis rather than the G2 evidence-bundle runners.

### Required compatibility changes

1. Add a `DataProfile` option with supported values:
   - `"field_capture"`
   - `"synthetic"`
2. Add an explicit role-mapping option shared by G2-G5.
3. For the synthetic profile, mark these checks `NOT_APPLICABLE`:
   - SDR serial number and hardware identity;
   - antenna model, orientation, and boresight;
   - hardware gain and cabling provenance;
   - clock and lock evidence;
   - acquisition overrun logs;
   - operator and site notes.
4. Do not manufacture `collection_metadata.json` or pretend synthetic metadata is hardware evidence.
5. Continue all transferable numerical checks:
   - mean power;
   - peak-to-average ratio;
   - headroom;
   - near-rail and exact-rail occupancy;
   - DC mean and DC spectral spike;
   - low-frequency concentration;
   - I/Q amplitude, phase-proxy, and impropriety metrics;
   - ATSC pilot prominence and occupied-band behavior;
   - reference/surveillance spectral relationship.
6. Retain field-profile defaults unchanged.

### Presentation

Use one tiled G2 figure showing:

- reference and surveillance PSD;
- pilot-region detail;
- power/headroom comparison; and
- compact DC/IQ health indicators.

Use short computed statements for the important findings. Do not display the existing large decision-trace or long-string tables.

### G2 success condition

G2 is `executed` when all transferable calculations return finite results and the role mapping remains consistent. Numerical problems such as clipping, severe DC, or unusable spectral content produce `caveated` or `blocked` results as appropriate. Missing field-only evidence produces `NOT_APPLICABLE`, not failure.

## Phase 4: G3 Synchronization and Coherence

### Question

Does the generated reference/surveillance pair provide a measurable and internally consistent delay, residual-frequency, and coherence relationship over useful CPI durations?

### Existing implementation to reuse

- `helperAnalyzeG3SyncCore`
- `private/helperPrepareG3SyncInputs`
- `finddelay`
- `xcorr`
- `spectrogram`
- `mscohere`

The Live Script will not call `runG3SyncCore`, because that runner reloads data and writes a full evidence bundle.

### Required compatibility changes

1. Pass the selected session ID rather than requiring `20260622T102123`.
2. Pass the selected repetition count rather than requiring 15.
3. Pass neutral channel labels and explicit role indices rather than requiring `RF1:RX2` and `RF0:RX2`.
4. Retain the existing 25, 50, and 100 ms CPI definitions for the first integration run.
5. Reuse the already loaded selected-part samples.
6. Do not require manual field collection metadata for a synthetic profile.

### Presentation

Use one tiled G3 figure showing:

- estimated lag by CPI;
- residual frequency by CPI; and
- mean/pass-fraction coherence by CPI.

Print the selected correction strategy and the most important lag, frequency, and coherence values in short statements.

### Single-part interpretation

Part 1 can establish that the computations work within a generated capture. It cannot establish cross-part repeatability. Repeatability-dependent G3 findings must therefore be labeled `NOT_ASSESSED_SINGLE_PART`, not `ready` or `pass`.

### G3 success condition

G3 is `executed_with_single_part_caveat` when lag, residual-frequency, and coherence calculations complete with finite values and yield a usable correction for downstream mapping. It is `blocked` if role resolution, signal length, correlation, or coherence calculation fails.

## Phase 5: G4 Passive Baseline Map

### Question

After the G3 correction is applied, can the selected SyntheticDataGeneration IQ produce a finite, correctly oriented, interpretable passive range-Doppler ambiguity map?

### Existing implementation to reuse

- `helperAnalyzeG4PassiveBaselineMap`
- `ambgfun`

The Live Script will not call `runG4PassiveBaselineMap`, its verification workflow, or G4.5.

### Quick-profile behavior

1. Use one 50 ms CPI.
2. Use the center window of selected part 1.
3. Use the existing reduced-rate map path and coordinate conventions.
4. Generate one representative map.
5. Disable the full-rate audit.
6. Disable the five-CPI/three-window sensitivity sweep.
7. Record skipped work explicitly as `NOT_RUN_QUICK_MODE`.
8. Do not use synthetic truth coordinates to select peaks or search regions.

### Required compatibility changes

- Make explicit G4 CPI and window selections override defaults instead of being overwritten internally.
- Add a bounded option to disable the full-rate audit cleanly.
- Return a stable status when the audit is skipped rather than treating the missing audit as a pass.

### Presentation

Show one range-Doppler map with:

- physical delay or bistatic-range axis;
- Doppler or bistatic range-rate axis;
- labeled units;
- a descriptive title containing session ID and selected part;
- no truth-centered annotation.

Print map dimensions, peak location, origin/direct-path prominence, and off-origin observability in concise form.

### G4 success condition

G4 is `executed_quick_map` when `ambgfun` returns finite map data and valid axes under the existing PBR coordinate convention. A strong origin or weak off-origin scene is a scientific result, not an execution failure. Repeatability and full-rate-equivalence claims remain unassessed.

## Phase 6: G5 Mitigation

### Question

On the same selected G4 map product, does the existing LMS mitigation reduce direct-path or zero-Doppler dominance without destroying potentially useful off-origin structure?

### Existing implementation to reuse

- `helperAnalyzeG5Mitigation`
- `dsp.LMSFilter`
- `ambgfun`

The Live Script will not call the full G5 runner, smoke-verification suite, or diagnostic sidecar.

### Quick-profile behavior

1. Reuse the in-memory G3 and G4 results.
2. Evaluate exactly one selected G4 row.
3. Compare:
   - `none`
   - `conservative_lms`
   - `aggressive_lms`
4. Require identical map dimensions and coordinate axes across candidates.
5. Preserve the existing PBR candidate parameters.
6. Treat target-retention metrics as diagnostic unless they can be evaluated without truth-centered tuning.

### Presentation

Use one tiled figure with the three candidate maps on identical axes and color limits. Print concise suppression, residual-power, and off-origin-retention results.

### G5 success condition

G5 is `executed_quick_comparison` when all three candidates run, produce finite and coordinate-compatible outputs, and provide interpretable comparison metrics. It is not a formal mitigation recommendation from one part.

## Phase 7: Integrated Interpretation

### Question

Did genuine SyntheticDataGeneration IQ traverse G1-G5, what did each phase reveal, and what specifically prevents the next claim?

### Required summary

Create a compact five-row table with only:

- gate;
- execution status;
- runtime in seconds; and
- one short result label.

Long explanations must remain in Live Script narrative text. Data-dependent conclusions should use short `fprintf` statements, per project preference.

The final interpretation must separate:

1. **Generator status:** Existing producer readiness and known `seed_preservation_failure`.
2. **Interoperability status:** Whether PBR consumed the generated package without manual data rewriting.
3. **Pre-detection status:** Whether G2-G5 produced meaningful, finite diagnostics and maps.
4. **Coverage limitation:** Only part 1 was processed.
5. **Claim limitation:** Detection, tracking, field equivalence, and formal gate approval were not evaluated.

### Milestone success statement

The milestone is a major win if the exact generated part traverses G1-G5 and produces useful diagnostics and figures despite carrying an explicit producer caveat. It is not necessary for every scientific metric to pass; the purpose is to establish integration, expose assumptions, and identify the next data or analysis constraint.

## Live Script Structure and Formatting

The new file will be:

```text
runSyntheticHDTVG1ThroughG5LiveScript.m
```

It must be a version-controlled plain-text MATLAB Live Script, not an `.mlx` file.

Required sections:

1. Purpose and claim boundaries.
2. Setup and exact synthetic dataset.
3. Source-package and producer-readiness review.
4. G1 ingest.
5. G2 RF and pre-detection health.
6. G3 synchronization and coherence.
7. G4 passive ambiguity map.
8. G5 mitigation comparison.
9. Integrated G1-G5 result.
10. Saved-result location and next step.

Formatting requirements:

- Use `%[text]` for narrative text.
- Use `%%` followed by `%[text] ## Section Title` for sections.
- Keep one paragraph on each `%[text]` line.
- Do not include blank lines or empty `%[text]` lines.
- Do not use `clear`, `close all`, or explicit `figure` calls.
- Use one plot per section unless a tiled layout is necessary.
- Use `tiledlayout` and `nexttile` for meaningful comparisons.
- Use doubled backslashes in Live Editor LaTeX.
- End the file with:

```matlab
%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
```

- Prefer figures over large MATLAB tables.
- Never display tables with long narrative strings.
- Use native Live Script text for static explanations.
- Use a small number of short `fprintf` statements for computed findings.
- Leave semicolons on intermediate calculations so the Live Editor does not dump large structs or arrays.
- Every visible output must help a reader understand the dataset or analysis result.

## Live Script Configuration Contract

The setup section will expose:

```matlab
repoRoot
syntheticDataRoot
sessionId
sessionRoot
partSelection
surveillanceChannelIndex
referenceChannelIndex
showFigures
saveCompactResult
```

Initial values:

```matlab
sessionId = "seed_demo_20260730T155438811";
partSelection = 1;
surveillanceChannelIndex = 1;
referenceChannelIndex = 2;
showFigures = true;
saveCompactResult = true;
```

The script will fail clearly if the configured package cannot be found. It will not search silently for another synthetic dataset.

## Result Contract

The script will leave one `quickResults` struct in the workspace with:

```text
Configuration
SourceProvenance
ProducerReadiness
PartSelection
StageStatus
Timing
G1
G2
G3
G4
G5
OverallInterpretation
```

The saved artifact will be:

```text
artifacts/quick/<session-id>/<run-timestamp>/quickResults.mat
```

It may contain:

- configuration and provenance;
- compact numeric summaries;
- short result labels;
- timings;
- reduced representative G4 and G5 maps;
- axes needed to reproduce the displayed plots.

It must not contain:

- raw IQ;
- complete `sessionData.RadarScans` sample arrays;
- copied `.bb` files;
- large narrative tables;
- a forest of per-gate CSV, JSON, Markdown, or PNG files.

Generated quick artifacts remain excluded from Git.

## Error and Progression Policy

- G1 failure stops the script.
- G2 field-only `NOT_APPLICABLE` findings do not stop synthetic processing.
- Severe numerical corruption in G2 stops G3-G5.
- G3 computational failure stops G4-G5.
- Single-part repeatability limitations do not stop G4-G5; they propagate as caveats.
- G4 computational failure stops G5.
- G4 scene weakness does not stop G5 if the map itself is valid.
- G5 produces a comparison, not an automatic hardware or algorithm recommendation.
- Each downstream result carries upstream caveats.

## Native MATLAB Function Audit

| Analysis need | Native MATLAB implementation retained | Planned adaptation |
| --- | --- | --- |
| Baseband decode | `comm.BasebandFileReader` | Add synthetic metadata tolerance and selected-part ingest |
| Power and spectrum | `mean`, `pwelch`, `bandpower` | Apply to selected generated part |
| Delay relationship | `finddelay`, `xcorr` | Remove fixed dataset and hardware-label assumptions |
| Time-frequency behavior | `spectrogram` | Retain existing G3 method |
| Coherence | `mscohere` | Retain existing G2/G3 method |
| Passive map | `ambgfun` | Run one reduced-rate center-window map |
| Leakage mitigation | `dsp.LMSFilter` | Compare existing three G5 profiles on one row |

No replacement signal-processing algorithms are introduced in this milestone.

## Verification Plan

### Static verification

1. Run MATLAB Code Analyzer on the new Live Script and changed helpers.
2. Confirm existing default options retain field-session behavior.
3. Confirm the Live Script satisfies the plain-text Live Code formatting checklist.
4. Confirm no source file imports code from `flightTest_SynthDataBranch`.

### End-to-end synthetic execution

Run the entire Live Script in MATLAB using:

```text
session = seed_demo_20260730T155438811
part = 1
```

Verify:

- the exact expected manifest is reported;
- all 15 parts are inventoried;
- only part 1 is decoded for analysis;
- the generated part is read from the SyntheticDataGeneration capture folder;
- CH1 is surveillance and CH2 is reference;
- G1-G5 reach their expected quick execution states;
- all displayed scalar metrics are finite unless explicitly marked unavailable;
- G4 provides nonempty map data and valid axes;
- G5 provides three coordinate-compatible maps;
- the final summary carries the producer readiness caveat;
- `quickResults.mat` contains no raw IQ.

### Focused selection verification

Exercise the `"all"` selection-resolution path without running the expensive complete G2-G5 workflow. Confirm it resolves 15 ordered parts and preserves their original repetition numbers.

### Focused compatibility check

Run a bounded field-profile ingest check to ensure the new optional profile and part-selection interfaces do not change existing field defaults. Do not run the full field pipeline.

### Explicitly omitted verification

- Do not run the complete PBR test directory.
- Do not run all 15 synthetic parts through G1-G5 during initial development.
- Do not run the G4 full-rate audit.
- Do not run G4.5 or G6-G10.
- Do not claim detector or tracker readiness.

## Documentation and Commit Plan

After successful execution:

1. Add a short README entry identifying the new Live Script as the quick SyntheticDataGeneration-to-G1-G5 path.
2. State that the existing large baseline Live Script remains the field-development walkthrough.
3. Record the exact tested session, selected part, PBR commit, and result path.
4. Do not add a new concept entry unless implementation introduces a genuinely new signal-processing concept.
5. Commit the implementation as a focused change, for example:

```text
Run SyntheticDataGeneration IQ through quick G1-G5 analysis
```

The commit should include the Live Script, required compatibility changes, focused verification code if needed, and the concise README update. It must not include input captures or generated artifacts.

## Acceptance Criteria

The milestone is complete only when all of the following are true:

- The input is verified as output from `generateSyntheticHDTVSession`.
- Part 1 from `seed_demo_20260730T155438811` is the IQ actually analyzed.
- G1-G5 execute in one Live Script session.
- The script uses existing PBR signal-processing helpers and native MATLAB functions.
- Hardware-only checks are clearly separated from synthetic-applicable checks.
- Figures are the primary technical communication mechanism.
- Dynamic text is concise and no long-string tables are displayed.
- The script records the existing generator failure without masking it.
- Single-part limitations are explicit.
- One compact MAT result is saved without raw IQ.
- No G4.5, G6+, detector, tracker, or full-suite work is pulled into this milestone.

## Next Decision After Completion

After reviewing the part-1 G1-G5 output, decide whether the evidence supports:

1. running the same quick profile across all 15 parts;
2. addressing the generator's seed-preservation caveat first;
3. adjusting only the synthetic interpretation thresholds; or
4. opening a separate follow-on milestone for deeper G4/G5 analysis.

That decision will be based on the executed evidence rather than made during this implementation.
