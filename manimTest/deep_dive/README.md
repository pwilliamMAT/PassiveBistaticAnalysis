# Math-First Passive-Bistatic Deep Dive

This isolated ManimGL package teaches the mathematics behind the paired
field-background synthetic-target demonstration. It is an instructional
artifact, not a pipeline run, retune, detector validation, or tracking result.

The teaching boundary is:

```text
synthetic trajectory / echo injection
  → synchronization → resampling / CPI → LMS candidate
  → CAF-power map → fixed CFAR / NMS candidates
  → post-hoc truth association
```

It excludes `objectDetection`, tracking, field-aircraft detection claims, and
detector retuning. The final examples preserve the accepted 45 km
criterion-passed case and the 15 km baseline as **not evaluated**, not missed.

## Contents

- `stage_traceability_matrix.md` — equation-to-implementation audit.
- `notation_sign_contract.md` — universal mathematics versus project-specific
  display conventions.
- `source_register.md` and `references.md` — code and MathWorks sources.
- `storyboard.md` and `narration.md` — approved 13 minute 20 second teaching
  contract; narration is text only in this pass.
- `deep_dive_data_v1/` — compact scalar evidence and analytic arrays only.
- `deep_dive_video.py` — self-contained ManimGL scene.
- `validate_deep_dive.py` — data, claim-boundary, and MP4 checks.
- `tests/test_deep_dive_contract.py` — no-render contract checks.

## Render

From `manimTest`:

```powershell
.\.venv\Scripts\python.exe deep_dive\validate_deep_dive.py
.\.venv\Scripts\python.exe -m unittest deep_dive.tests.test_deep_dive_contract
.\.venv\Scripts\manimgl.exe deep_dive\deep_dive_video.py MathFirstPassiveBistaticDeepDive -w --fps 30 --resolution 1920x1080 --video_dir deep_dive\output
.\.venv\Scripts\python.exe deep_dive\validate_deep_dive.py --video deep_dive\output\math_first_passive_bistatic_deep_dive.mp4
```

The scene is exactly 800 seconds at 30 fps (13 minutes 20 seconds). It has no
audio. The output directory is ignored, while the compact package and source
remain reviewable in version control.

## Retention and isolation

`deep_dive_data_v1` contains no raw IQ, `.mat` file, full ambiguity map,
detector replay, or `objectDetection` object. The video reads only its local
compact package; it never calls MATLAB, changes the detector, opens
`r5aParallelPool`, or changes project-level state.
