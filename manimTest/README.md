# Isolated ManimGL Video Capability Trial

This directory is a self-contained, non-gating visualization trial. It reads
two compact saved MATLAB result bundles without modifying them, extracts only
small presentation data, and renders a caption-led MP4 with ManimGL.

The video compares:

- the accepted 45 km synthetic positive control, whose fixed diagnostic
  criterion passed; and
- the 15 km synthetic case, which is valid in the physics map but outside the
  frozen CFAR/NMS support and therefore **not evaluated**, not missed.

No MATLAB, raw IQ, full ambiguity map, pipeline recomputation, detector
retuning, or project-state update is part of this trial.

## Quick start

From this directory:

```powershell
.\.venv\Scripts\python.exe extract_compact_results.py
.\.venv\Scripts\python.exe validate_video_data.py
.\.venv\Scripts\manimgl.exe field_background_video.py FieldBackgroundTrial -w
.\.venv\Scripts\python.exe validate_video_data.py --video output\field_background_trial.mp4
```

`extract_compact_results.py` creates the ignored `data/manim_video_data_v1/`
package. It records SHA-256 values for both source files and rejects schema,
scenario, outcome, detector, retention, or compact-map inconsistencies.

`field_background_video.py` intentionally uses ManimGL (`manimlib`) only. Its
caption card names the saved sources and its claim boundary is diagnostic
synthetic integration, not field-aircraft detection or tracking validation.

## Deliverables

- `extract_compact_results.py` — read-only extraction from the two compact MAT
  files.
- `validate_video_data.py` — data contract and MP4 validation.
- `captions.py` — caption, glossary, and source-card copy.
- `field_background_video.py` — eight ManimGL scenes concatenated into one
  1080p, 30 fps video.
- `tests/` — lightweight extractor and caption contract tests.

Generated data, Python environments, frame sequences, logs, and MP4 output
are intentionally ignored and stay under this directory.
