"""Citation card copy for the standalone Deep Dive 2 scene."""

from __future__ import annotations

VIDEO_TITLE = "Reading the passive-bistatic map and detector boundary"
VIDEO_SUBTITLE = (
    "A diagnostic sequel: geometry, processing transformations, "
    "fixed candidate generation, and post-hoc association"
)

SOURCE_CARDS = {
    "S1": "S1–S3  Paired producer and runner (local source audit)",
    "S4": "S4–S5  G3 synchronization: lag, cross-phase, correction reuse",
    "S6": "S6  MathWorks resample; whole-repetition filter/reduce/select contract",
    "S7": "S7  MathWorks dsp.LMSFilter; diagnostic mitigation candidates",
    "S8": "S8  MathWorks ambgfun; project CAF-power orientation contract",
    "S9": "S9  phased.CFARDetector2D + imdilate + bwconncomp",
    "S10": "S10  MathWorks matchpairs; post-hoc normalized association",
    "S11S12": "S11–S12  Hash-verified saved trajectories and frozen detector support",
}

REFERENCES_CARD = [
    "Project sources: paired runner, G3 preparation, G4 map helper, G5 mitigation helper, G6-D detector helper",
    "MathWorks: finddelay • xcorr • resample • dsp.LMSFilter • ambgfun",
    "MathWorks: phased.CFARDetector2D • imdilate • bwconncomp • matchpairs • geodetic2enu",
    "Full source register and claim boundary: deep_dive_2/references.md",
]
