# G4.5 Synthetic Target Recovery Plan

## Native MATLAB Function Audit

| Proposed Workflow | Native MATLAB Documentation Example Analogue | Updates needed to fit current goal |
| :--- | :--- | :--- |
| Synthetic suite manifest and case validation | JSON workflows using `jsondecode` / `jsonencode` documented in MATLAB data import/export | Add G4.5-local normalization from `truth_files`-style manifests into the existing baseband-loading expectations without editing handoff files |
| Baseband capture loading | Communications Toolbox baseband file workflow using `comm.BasebandFileReader`, consistent with the repo's existing `helperScanBasebandCaptureFile` path | Keep `.bb` reading on the existing helper/baseband reader path and adapt missing synthetic metadata locally |
| Baseline ambiguity/map formation | Ambiguity function workflow using `ambgfun` documentation examples | Use baseline/no-mitigation processing and preserve G4 raw delay/Doppler sign conventions |
| Numeric target recovery and association | Peak detection and tabular reporting workflows using `max`, `median`, `mad`, `table`, `writetable`, `save` | Associate truth by `expected_delay_s` and `expected_bistatic_doppler_hz`; treat bin fields as optional cross-checks |
| Diagnostic report generation | MATLAB report-style artifact workflows using `fprintf`, `writetable`, `jsonencode`, `save`, `tic`/`toc` | Emit Markdown, JSON, MAT, CSV, decision, failure-cause, next-branch, timing, and performance artifacts under the requested artifact root |

| Proposed Feature / Algorithm | Native MATLAB Function/Toolbox Equivalent | Documentation Syntax Template Used |
| :--- | :--- | :--- |
| JSON manifest/truth parsing | `jsondecode`, `fileread` | `data = jsondecode(fileread(filename))` |
| JSON output | `jsonencode`, `fprintf` / `writelines` | `encoded = jsonencode(data, "PrettyPrint", true)` |
| Baseband file read | `comm.BasebandFileReader`, repo `helperScanBasebandCaptureFile` | `reader = comm.BasebandFileReader(filename)` |
| Ambiguity map formation | `ambgfun` | `[afmag, delay, doppler] = ambgfun(x, y, fs, prf)` |
| Nearest-neighbor truth association | `min`, `abs`, `ind2sub` | `[~, idx] = min(abs(axis - truthValue))` |
| Robust local scoring | `median`, `mad`, `pow2db` | `z = (x - median(bg)) ./ (1.4826 .* mad(bg, 1))` |
| Metrics and artifacts | `table`, `writetable`, `save` | `writetable(T, filename); save(filename, "analysis")` |
| Optional figures | `figure`, `imagesc`, `scatter`, `bar`, `exportgraphics` | `figure; imagesc(...); xlabel(...); ylabel(...); title(...)` |

## Scope

G4.5 is a standalone diagnostic gate between `G4_Passive_Baseline_Map` and `G5_Mitigation`. It evaluates whether the current PassiveBistaticRestart baseline map path can recover known injected target echoes in real RF background data from `g4_5_real_background_20260807T162306840/`.

The gate is diagnostic only. It does not promote G5, G6, G8, real aircraft observability, detector tuning, or mitigation readiness.

## Implementation Contract

- `helperAnalyzeG45SyntheticTargetRecovery.m` analyzes one case.
- `runG45SyntheticTargetRecovery.m` runs one case or all canonical cases and writes required artifact bundles.
- `verifyG45SyntheticTargetRecovery.m` runs the canonical suite by default.
- Handoff files are read-only inputs.
- Per-case manifests are normalized locally so `truth_files` can satisfy compatibility checks without modifying source data.
- `.bb` reading first attempts `helperScanBasebandCaptureFile`; if synthetic metadata lacks legacy antenna fields, the local G4.5 adapter uses `comm.BasebandFileReader` and records the adapter path in validation output.

## Map and Truth Convention

G4.5 uses baseline no-mitigation map formation:

```matlab
[mapMagnitude, delayAxis_s, dopplerAxis_Hz] = ambgfun(referenceWindow, surveillanceWindow, mapSampleRateHz, prfVector_Hz);
```

The raw G4 `ambgfun(reference, surveillance, ...)` convention is preserved. Expected truth fields remain primary, and the association axis applies the documented G4 sign conversion:

- `G4AssociationDelay_s = -expected_delay_s`
- `G4AssociationDoppler_Hz = -expected_bistatic_doppler_hz`

`expected_range_bin` and `expected_doppler_bin` are recorded as optional convention audits, not primary pass/fail inputs.

## Decisions

Allowed labels are `PASS`, `WARN`, `BLOCKED`, `FAIL`, `CONTROL_PASS`, and `CONTROL_FAIL`.

- `real_only_control`: `CONTROL_PASS` unless pass-level target-like responses occur at synthetic truth probes.
- `easy_single_target`: must recover numerically for `PASS`.
- `medium_single_target`: `PASS` or `WARN`.
- `hard_single_target`: `WARN` or `FAIL`; it must not crash.
- `marginal_single_target`: threshold sensitivity only; no visual-only pass.
- `multi_target`: validates association when feasible; otherwise emits explicit `WARN`.

## Artifact Contract

Each case writes:

`artifacts/<suite_id>/<case_dataset_id>/G4_5_SyntheticTargetRecovery/<runTimestampZ>/`

Required outputs:

- `summary.md`
- `summary.json`
- `metrics.json`
- `metrics.mat`
- `target_recovery_table.csv`
- `manifest_validation_table.csv`
- `truth_convention_audit_table.csv`
- `false_alarm_summary_table.csv`
- `diagnostic_interpretation_table.csv`
- `requirements_coverage.csv`
- `decision.txt`
- `failure_cause.txt` when the decision is not `PASS` or `CONTROL_PASS`
- `next_branch.txt`
- `timing_summary.csv`
- `performance_summary.json`
- optional `figures/`

## Diagnostic Interpretation Labels

The diagnostic interpretation table always includes:

- `pipeline_suspect`
- `acquisition_or_scene_likely`
- `threshold_policy_suspect`
- `sensitivity_limited`
