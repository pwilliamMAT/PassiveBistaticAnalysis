"""Source-card copy used by the math-first instructional scene."""

from __future__ import annotations

VIDEO_TITLE = "Passive bistatic, from equations to candidates"
VIDEO_SUBTITLE = (
    "A math-first diagnostic deep dive: synthetic injection through "
    "truth-blind CFAR/NMS and post-hoc association"
)

SOURCE_CARDS = {
    "S1": "S1–S3  Producer and paired runner (local source audit)",
    "S4": "S4–S5  G3: finddelay, xcorr, cross-phase correction",
    "S6": "S6  MathWorks resample; project complete-repetition contract",
    "S7": "S7  MathWorks dsp.LMSFilter; G5 candidate helper",
    "S8": "S8  MathWorks ambgfun; project power/orientation helper",
    "S9": "S9  phased.CFARDetector2D + imdilate + bwconncomp",
    "S10": "S10  MathWorks matchpairs; post-hoc association helper",
    "S11": "S11  Saved 45 km compact result (accepted positive control)",
    "S12": "S12  Saved 15 km baseline compact result (not evaluated)",
    "S11S12": "S11–S12  Saved compact 45 km positive control and 15 km baseline",
}

REFERENCES_CARD = [
    "Project sources: paired runner, G3 preparation, G4 map helper, G5 LMS helper, G6-D detector helper",
    "MathWorks: finddelay • xcorr • resample • dsp.LMSFilter • ambgfun",
    "MathWorks: phased.CFARDetector2D • imdilate • bwconncomp • matchpairs",
    "Full URLs and source locations: deep_dive/references.md",
]
