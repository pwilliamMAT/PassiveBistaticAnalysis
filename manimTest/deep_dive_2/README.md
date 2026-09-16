# Deep Dive 2 — Reading the Passive-Bistatic Map and Detector Boundary

This standalone ManimGL sequel teaches the diagnostic field-background
synthetic-target path as:

```text
purpose → implementation transformation → expected visual change → limitation
```

It is an instructional artifact, not a pipeline run, detector retune,
detector-support change, field-aircraft result, `objectDetection` output, or
tracking result. Every dynamic visual is analytic/code-drawn. The only saved
evidence used by the final linked composition is compact scalar geometry
extracted from two hash-verified `results.Trajectory` structures.

The 15 km / 45 km wording always means a receiver-local north-offset
scenario. It is not a range label. The 15 km scenario is **not evaluated**
under the frozen detector rectangle; this video does not alter that boundary.

## Contents

- `extractDeepDive2CompactGeometryEvidence.m` — MATLAB-only, read-only
  scalar extractor using native WGS-84 `geodetic2enu`.
- `deep_dive_2_data_v1/` — compact JSON scalars and analytic teaching arrays.
- `video_contract.py` — exact 900-second timing and four-beat chapter contract.
- `deep_dive_2_video.py` — self-contained ManimGL scene and fast smoke scene.
- `storyboard.md` and `narration.md` — 15:00 teaching contract; narration is
  text only and no audio is generated.
- `validate_deep_dive_2.py` and `tests/` — data, claim-boundary, MATLAB, and
  no-render Python contract checks.

## Render

From `manimTest`:

```powershell
.\.venv\Scripts\python.exe deep_dive_2\validate_deep_dive_2.py
.\.venv\Scripts\python.exe -m unittest deep_dive_2.tests.test_deep_dive_2_contract
.\.venv\Scripts\manimgl.exe deep_dive_2\deep_dive_2_video.py DeepDive2Smoke -s --resolution 1920x1080 --video_dir deep_dive_2\output
.\.venv\Scripts\manimgl.exe deep_dive_2\deep_dive_2_video.py ReadingPassiveBistaticMapDeepDive2 -w --fps 30 --resolution 1920x1080 --video_dir deep_dive_2\output
ffmpeg -y -i deep_dive_2\output\ReadingPassiveBistaticMapDeepDive2.mp4 -frames:v 27000 -an -c copy deep_dive_2\output\reading_passive_bistatic_map_deep_dive_2_900s.mp4
.\.venv\Scripts\python.exe deep_dive_2\validate_deep_dive_2.py --video deep_dive_2\output\reading_passive_bistatic_map_deep_dive_2_900s.mp4
```

To regenerate the committed compact geometry JSON from the repository root:

```matlab
addpath(fullfile(pwd, "manimTest", "deep_dive_2"))
extractDeepDive2CompactGeometryEvidence(pwd)
```

ManimGL appends a three-frame end-of-scene tail, so the explicit 27,000-frame
copy step names the delivered exact-900-second MP4. It is 30 fps,
1920×1080 H.264, with no audio. Generated output remains under this package's
ignored `output/` directory. The original `manimTest/deep_dive/` package is
neither read nor modified by this package.
