# G4.5 Real-Background Synthetic Target Recovery Suite

Suite ID: `g4_5_real_background_20260807T162306840`

This folder contains local handoff artifacts for synthetic target recovery testing.
Synthetic cases keep the recorded reference channel unchanged and add ADS-B-backed target echoes only to the surveillance channel.

## Base Capture

- Capture ID: `20260622T102123`
- Base part: `C:\Users\pwilliam\agenticProjects\flightTest_SynthDataBranch\captures\20260622T102123\radar\n320_hdtv_capture_20260622T102123_part1`
- Sample rate: 6144000 Hz
- Center frequency: 599000000 Hz

## Datasets

- `real_only_control`: control, targets=0, validation=PASS
- `easy_single_target`: easy, targets=1, validation=PASS
- `medium_single_target`: medium, targets=1, validation=PASS
- `hard_single_target`: hard, targets=1, validation=PASS
- `marginal_single_target`: marginal, targets=1, validation=PASS
- `multi_target`: multi_target, targets=2, validation=PASS

## Files

- `synthetic_suite_manifest.json` is the top-level machine-readable manifest.
- Each dataset folder contains `radar/*.bb`, `truth/*_truth.json`, and a compact `session_manifest.json`.

## Limitations

- Echo strength is controlled by generator amplitude gain, not calibrated aircraft RCS.
- Direct-path-to-target ratio is intentionally null unless a future calibrated measurement is added.
- No PassiveBistaticRestart code is required or modified by this suite.