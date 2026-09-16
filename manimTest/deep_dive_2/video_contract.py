"""Timing, source, and teaching-beat contract for Deep Dive 2."""

from __future__ import annotations

CHAPTERS = [
    {
        "id": "01_boundary",
        "duration_s": 70,
        "title": "1. Evidence boundary: paired control and injection",
        "source": "S1",
        "captions": [
            "Why: a controlled comparison isolates one declared change in real field background.",
            "What: reference and field control stay unchanged; only surveillance receives one synthetic echo.",
            "Visual change: two otherwise identical paths separate only at the surveillance injection block.",
            "Limit: diagnostic synthetic integration only—not field-aircraft detection, product selection, or tracking.",
        ],
    },
    {
        "id": "02_geometry",
        "duration_s": 110,
        "title": "2. From bistatic geometry to display coordinates",
        "source": "S11S12",
        "captions": [
            "Why: excess path locates an echo in a delay–Doppler coordinate system.",
            "What: r_excess = R_T + R_R - B and tau_excess = r_excess / c.",
            "Visual change: positive physical delay becomes negative displayed delay under this project convention.",
            "Limit: a physics-map coordinate does not by itself make a detector cell eligible.",
        ],
    },
    {
        "id": "03_echo",
        "duration_s": 75,
        "title": "3. Echo construction",
        "source": "S1",
        "captions": [
            "Why: a known injected echo makes a paired end-to-end diagnostic auditable.",
            "What: seed → conditioning → propagation → surveillance-only addition.",
            "Visual change: the echo acquires geometry-driven delay and Doppler before joining surveillance.",
            "Limit: the −18 dB scenario gain is normalized difficulty, not calibrated aircraft received power.",
        ],
    },
    {
        "id": "04_sync",
        "duration_s": 90,
        "title": "4. Synchronization",
        "source": "S4",
        "captions": [
            "Why: a passive comparison needs channels aligned before a map can be meaningful.",
            "What: estimate integer lag, fit residual cross-phase, then reuse the control-derived correction.",
            "Visual change: shifted peaks and a phase slope become coherent aligned traces.",
            "Limit: estimator signs and correction signs are implementation conventions, not universal rules.",
        ],
    },
    {
        "id": "05_cpi",
        "duration_s": 75,
        "title": "5. Resampling and coherent processing interval",
        "source": "S6",
        "captions": [
            "Why: rate reduction makes map formation tractable while preserving the defined signal bandwidth.",
            "What: filter and resample the whole corrected repetition, then select the 100 ms CPI.",
            "Visual change: many input samples reduce to a bounded map-domain CPI.",
            "Limit: F_s' = F_s / q and 1 / T_CPI do not independently prove physical resolution.",
        ],
    },
    {
        "id": "06_mitigation",
        "duration_s": 120,
        "title": "6. Direct-path mitigation: conceptual before and after",
        "source": "S7",
        "captions": [
            "Why: reference-correlated direct-path structure can dominate a passive map.",
            "What: normalized LMS predicts leakage and passes e[n] = d[n] − d_hat[n] to map formation.",
            "Visual change: analytic maps progress from dominant leakage to conservative and aggressive suppression.",
            "Limit: these are code-drawn teaching patterns, not recorded maps or a formal product decision.",
        ],
    },
    {
        "id": "07_caf",
        "duration_s": 80,
        "title": "7. CAF power map",
        "source": "S8",
        "captions": [
            "Why: delay and Doppler hypotheses test where synchronized signals agree.",
            "What: ambgfun supplies the ambiguity calculation; P(tau,f) = |A(tau,f)|^2 is displayed.",
            "Visual change: a localized target-like lobe appears in a code-drawn power map.",
            "Limit: no signed or normalized CAF summation formula is asserted here.",
        ],
    },
    {
        "id": "08_detector",
        "duration_s": 105,
        "title": "8. Fixed support, CFAR, and nonmaximum suppression",
        "source": "S9",
        "captions": [
            "Why: a map needs a declared search region and local decision rule before it yields candidates.",
            "What: fixed support → local CA-CFAR threshold → 7×3 NMS sparse candidates.",
            "Visual change: a rectangle limits eligible cells before candidate dots remain.",
            "Limit: Pfa is a detector-model design input, not a measured field false-alarm rate.",
        ],
    },
    {
        "id": "09_association",
        "duration_s": 60,
        "title": "9. Post-hoc association",
        "source": "S10",
        "captions": [
            "Why: truth is useful for evaluating candidates without steering their generation.",
            "What: normalize delay and Doppler error, then use one-to-one matchpairs association.",
            "Visual change: candidate dots appear first; truth windows and match lines arrive afterward.",
            "Limit: association cannot alter CAF formation, CFAR, NMS, or detector support.",
        ],
    },
    {
        "id": "10_cases",
        "duration_s": 115,
        "title": "10. Linked receiver-local 45 km / 15 km north-offset scenarios",
        "source": "S11S12",
        "captions": [
            "Why: geometry and detector support answer different questions about one coordinate.",
            "What: link receiver-local plan-view positions to displayed excess-delay–Doppler markers.",
            "Visual change: 45 km falls inside frozen support; 15 km remains visible outside its delay edge.",
            "Limit: the 15 km scenario is not evaluated—this does not widen, retune, or validate the detector.",
        ],
    },
]

PLANNED_DURATION_S = sum(int(chapter["duration_s"]) for chapter in CHAPTERS)
FRAME_RATE = 30
RESOLUTION = (1920, 1080)
EXPECTED_VIDEO_SECONDS = 900
