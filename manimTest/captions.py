"""Caption, glossary, and citation copy for the isolated ManimGL trial.

The timing is deliberately generous because there is no voiceover.  The
caption text is part of the evidence boundary: it repeatedly distinguishes
diagnostic synthetic integration from validated field detection or tracking.
"""

from __future__ import annotations

VIDEO_TITLE = "A detector boundary is not a detector miss"
VIDEO_SUBTITLE = (
    "Saved field-background synthetic-target evidence: 45 km positive control "
    "versus 15 km detector-ineligible geometry"
)

SCENES = [
    {
        "id": "01_claim_boundary",
        "title": "1. Diagnostic claim boundary",
        "duration_s": 45,
        "captions": [
            "This isolated video reads two compact saved diagnostic results. "
            "It does not rerun the passive-bistatic pipeline.",
            "At 45 km, the fixed paired criterion passed: an injected target "
            "matched after truth-blind detection, with no matched-control nuisance match.",
            "That result is diagnostic synthetic integration evidence—not a "
            "field-aircraft detection claim and not tracking validation.",
        ],
    },
    {
        "id": "02_geometry",
        "title": "2. One bistatic geometry, two target offsets",
        "duration_s": 55,
        "captions": [
            "The transmitter, receiver, and moving synthetic target define "
            "excess path delay and bistatic Doppler.",
            "The map display convention places the 45 km trajectory near "
            "−269 µs and +592 Hz, and the 15 km trajectory near −76 µs and +540 Hz.",
            "Both truth trajectories are physically valid in the saved map "
            "context. Eligibility is a separate detector-support question.",
        ],
    },
    {
        "id": "03_paired_inputs",
        "title": "3. Paired inputs isolate the injection",
        "duration_s": 45,
        "captions": [
            "The reference channel is unchanged in both cases. The control "
            "surveillance channel is the untouched field capture.",
            "Only the injected case adds the geometry-driven echo to "
            "surveillance. This makes the control-versus-injection comparison auditable.",
            "The video contains no raw IQ. It uses only retained compact "
            "trajectory, map-view, configuration, and outcome evidence.",
        ],
    },
    {
        "id": "04_g3_reuse",
        "title": "4. Synchronize once; reuse the correction",
        "duration_s": 45,
        "captions": [
            "G3 synchronization is derived from the untouched control, not "
            "separately fitted for the injected case.",
            "The saved correction is then reused exactly for both paired "
            "paths. That prevents a target-aware synchronization advantage.",
            "Only correction summary values were retained here; no "
            "synchronization waveform is invented for this visualization.",
        ],
    },
    {
        "id": "05_cpi_caf",
        "title": "5. From a 100 ms CPI to a CAF power map",
        "duration_s": 45,
        "captions": [
            "A 100 ms coherent processing interval has a nominal Fourier "
            "scale of 1/T = 10 Hz.",
            "The saved display grid is sampled more finely than that nominal "
            "scale. Grid spacing is a coordinate sampling property, not an independent resolution claim.",
            "This is a conceptual CAF-power flow. No signed CAF equation is "
            "shown because the compact artifact does not provide a standalone normalization contract.",
        ],
    },
    {
        "id": "06_mitigation",
        "title": "6. Three fixed mitigation candidates",
        "duration_s": 45,
        "captions": [
            "The same injected 45 km compact detector-region view is shown "
            "for no mitigation, conservative LMS, and aggressive LMS.",
            "These views support a diagnostic comparison. They do not select "
            "a formal G5 product or authorize detector retuning.",
            "The frozen Pfa sweep and detector geometry stay fixed while "
            "candidate products are compared.",
        ],
    },
    {
        "id": "07_detector_support",
        "title": "7. Physics-map context versus fixed detector support",
        "duration_s": 55,
        "captions": [
            "The full physics map can contain a valid truth coordinate beyond "
            "the detector’s frozen search rectangle.",
            "The fixed G6-D search support is delay −1200 to −150 µs and "
            "Doppler ±750 Hz, with 12,832 actual CUTs in the saved grid.",
            "CFAR Pfa is a design input for this detector. It is not a "
            "measured field false-alarm rate. No full-map power is invented here.",
        ],
    },
    {
        "id": "08_association_outcomes",
        "title": "8. Truth-blind detection, then post-hoc association",
        "duration_s": 60,
        "captions": [
            "Detection generation and NMS occur before truth association. "
            "Truth is used only after the detector has produced its candidates.",
            "The 45 km positive control was eligible and met its fixed "
            "diagnostic criterion at Pfa = 10⁻³.",
            "The 15 km truth lies in the physics map but outside fixed "
            "detector support. It was not evaluated—not missed.",
        ],
    },
]

GLOSSARY = {
    "CAF": "Cross-ambiguity-function power map: a delay–Doppler representation.",
    "CPI": "Coherent processing interval. This trial uses a saved 100 ms CPI.",
    "CUT": "Cell under test: a grid cell searched by the detector.",
    "CFAR": "Constant-false-alarm-rate thresholding. Pfa is a design input.",
    "NMS": "Nonmaximum suppression used to retain local candidate peaks.",
    "post-hoc association": "Truth is associated after truth-blind detection generation.",
}

SOURCE_CARD = [
    "Sources read once by extract_compact_results.py",
    "45 km: field_background_demo_final_20260908",
    "15 km: field_background_explained_20260914T153126038",
    "Both: fieldBackgroundSyntheticPipelineResults.mat",
    "Derived package: manim_video_data_v1 (source SHA-256 in manifest)",
]


def total_duration_s() -> int:
    """Return the planned no-voiceover duration."""

    return sum(scene["duration_s"] for scene in SCENES)

