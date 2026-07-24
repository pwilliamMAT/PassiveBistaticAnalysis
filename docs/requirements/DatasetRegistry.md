# Dataset Registry

Documentation scope only. This registry records the current planning status of reference datasets for later implementation and V&V use.

## Registered Dataset

| Field | Value |
| :--- | :--- |
| Session ID | `20260622T102123` |
| Current status | `diagnostic until G1-G4 pass` |
| Manifest location | `20260622T102123/session_manifest.json` |
| Radar content | `15` one-second dual-channel captures at `6.144 MHz` |
| Truth content | ADS-B artifact `truth/0_20260622_102124_adsb_20260622T102123.txt.gz` |
| Logs | `logs/flighttest_capture_20260622T102123_ohvZ.log`, `logs/adsb_capture_20260622T102123.log` |

## Current Status Rationale

- The radar files carry embedded `BasebandVer2.0.0` metadata, so the ingest contract must be confirmed before any raw-IQ assumptions are treated as authoritative.
- Embedded radar-header `RecordingUTC` spacing is not identical to the manifest's `capture_repetition_spacing_s = 1` summary, so timing alignment remains unresolved.
- The passive baseline map has not yet been validated with `ambgfun`.
- Therefore the dataset remains `diagnostic` rather than `golden`.

## Promotion Criteria

The dataset may be promoted to `golden` only if all of the following become true:

- G1 confirms the decode contract, seam contract, and authoritative timing model.
- G2 confirms strong enough RF health for repeatable sync and passive-map work.
- G3 confirms a stable lag and residual-frequency correction model.
- G4 confirms a plausible and repeatable `ambgfun` baseline map.

## Reasons the Dataset May Remain Diagnostic

- RF quality is usable for experimentation but not strong enough for confident customer-facing claims.
- Truth alignment remains bounded only loosely.
- The dataset supports a validated passive baseline or validated detection milestone, but not truth-correlated success.

## Reasons the Dataset May Be Rejected

- Required radar or truth artifacts cannot be reconciled.
- The reference channel is unusable.
- No stable synchronization model exists across the repeated captures.
- Passive baseline maps remain implausible even after G1-G3 retuning.

## Expert Note

This document is part of the broader council-derived plan and was informed primarily by RF/data-quality, passive bistatic radar algorithm, requirements/V&V, and systems/customer-communication review inputs.
