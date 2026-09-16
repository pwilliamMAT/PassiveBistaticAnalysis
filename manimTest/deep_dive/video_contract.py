"""Timing and claim-boundary constants for the deep-dive render."""

from __future__ import annotations

CHAPTERS = [
    {
        "id": "01_boundary",
        "duration_s": 55,
        "title": "1. Evidence boundary: a paired control",
        "source": "S1",
        "captions": [
            "Instructional boundary: synthetic injection through CFAR/NMS candidates and post-hoc association.",
            "Control: untouched field capture. Injection: same reference and field surveillance plus one echo.",
            "Diagnostic synthetic integration only — not field-aircraft detection, product selection, or tracking."
        ],
    },
    {
        "id": "02_geometry",
        "duration_s": 90,
        "title": "2. Bistatic geometry gives excess delay and Doppler",
        "source": "S1",
        "captions": [
            "Excess path r_b = R_T + R_R - B; excess delay tau_b = r_b / c.",
            "Path-rate magnitude sets bistatic Doppler magnitude; the displayed sign is a project convention.",
            "Geometry says where an echo belongs in physics-map coordinates. It does not make a detector CUT eligible."
        ],
    },
    {
        "id": "03_echo",
        "duration_s": 85,
        "title": "3. Condition, propagate, and inject one echo",
        "source": "S1",
        "captions": [
            "A reference-derived seed is conditioned only for the echo path, then RMS-matched.",
            "Propagation applies geometry-driven delay and Doppler. A relative amplitude a = 10^(G_dB/20) scales it.",
            "The -18 dB scenario setting is a controlled normalized gain — not a calibrated RCS or received-power model."
        ],
    },
    {
        "id": "04_sync",
        "duration_s": 80,
        "title": "4. Synchronize once; reuse the correction",
        "source": "S4",
        "captions": [
            "Integer lag: choose the correlation shift k_hat with the largest magnitude.",
            "Residual cross-phase follows phi(t) approximately phi_0 + 2*pi*Delta_f*t.",
            "The control-derived lag and phase correction are reused exactly for the injected path."
        ],
    },
    {
        "id": "05_cpi",
        "duration_s": 75,
        "title": "5. Resample, then select a 100 ms CPI",
        "source": "S6",
        "captions": [
            "The complete corrected repetition is resampled: 6.144 MHz / 200 = 30.72 kHz.",
            "A 100 ms CPI contains 3,072 reduced-rate samples and has nominal Fourier scale 1/T = 10 Hz.",
            "Coordinate grid spacing is not an independent physical-resolution claim."
        ],
    },
    {
        "id": "06_lms",
        "duration_s": 70,
        "title": "6. Normalized LMS produces a residual candidate",
        "source": "S7",
        "captions": [
            "LMS predicts reference-correlated leakage in surveillance; the residual error e goes to map formation.",
            "The demonstration compares none, conservative LMS, and aggressive LMS under fixed downstream settings.",
            "An adaptive filter can suppress desired energy, so these remain diagnostic candidates."
        ],
    },
    {
        "id": "07_caf",
        "duration_s": 90,
        "title": "7. From two signals to a CAF power map",
        "source": "S8",
        "captions": [
            "The cross-ambiguity representation compares delay and Doppler hypotheses between two received signals.",
            "The displayed map uses power P(tau,f) = |A(tau,f)|^2; rows are Doppler and columns are delay.",
            "No signed or normalized CAF equation is displayed until the MATLAB convention and saved orientation evidence are reconciled."
        ],
    },
    {
        "id": "08_detector",
        "duration_s": 95,
        "title": "8. Fixed CA-CFAR and 7×3 NMS generate candidates",
        "source": "S9",
        "captions": [
            "Each eligible CUT gets a local CA-CFAR noise estimate from its surrounding training cells.",
            "A candidate must exceed alpha(Pfa) times that local estimate, then survive 7×3 local-maximum suppression.",
            "Pfa is a detector-model design input, not a measured field false-alarm rate. Truth is absent here."
        ],
    },
    {
        "id": "09_association",
        "duration_s": 70,
        "title": "9. Associate truth after truth-blind candidate generation",
        "source": "S10",
        "captions": [
            "Normalize each detection's delay and Doppler error by the permitted truth-window half-extents.",
            "matchpairs selects one-to-one matches using the normalized Euclidean cost.",
            "Truth labels candidates afterward; it never steers CAF formation, CFAR, NMS, or candidate generation."
        ],
    },
    {
        "id": "10_cases",
        "duration_s": 90,
        "title": "10. Applied examples: a pass and a non-evaluation",
        "source": "S11S12",
        "captions": [
            "45 km: inside fixed support, criterion passed, injected truth associated post hoc, no matched-control nuisance association.",
            "15 km: physically valid map coordinate but outside the frozen delay support. Detector evaluation: no.",
            "Not evaluated is not missed. A detector boundary is a search contract, not a physics boundary."
        ],
    },
]

PLANNED_DURATION_S = sum(int(chapter["duration_s"]) for chapter in CHAPTERS)
FRAME_RATE = 30
RESOLUTION = (1920, 1080)
