# Narration Script and Timings

This is text for a future human or approved speech pass. No audio is generated
or embedded by the current render. Timing is intentionally roomy for a
technical newcomer and synchronized to the 800-second captioned video.

## 00:00–00:55 — Evidence boundary

We begin with the only claim this video is allowed to support. It is a
diagnostic synthetic-integration demonstration in real field background. It
does not establish field-aircraft detection, a selected mitigation product,
or tracking readiness. The comparison is paired. One path is an untouched
field control. The other has the same recorded reference, the same field
surveillance, and one geometry-driven synthetic echo added only to
surveillance. Written compactly, the injected surveillance is the field
surveillance plus an echo. That narrow change lets us ask whether a known,
controlled input survives the same processing sequence. It does not turn the
echo into a calibrated aircraft return. The key integrity checks are simple:
the reference must be exactly unchanged, the control must remain the original
capture, and the injected surveillance delta must be finite and nonzero.
Those checks keep the experiment interpretable before any signal processing
or detector result is discussed.

Source: S1–S3.

## 00:55–02:25 — Bistatic geometry

Passive bistatic geometry begins with three distances. The transmitter-to-
target range is R sub T. The target-to-receiver range is R sub R. The direct
transmitter-to-receiver baseline is B. Their difference, R sub T plus R sub R
minus B, is the excess path. Dividing it by the speed of light gives the
excess delay. A moving target also changes the two-hop path length, and that
path-rate produces bistatic Doppler. These are physical quantities. The
plotted display coordinates in this project use their negatives, so the
displayed delay and Doppler should never be mistaken for a universal sign
rule. A target can be physically well placed in a delay-Doppler map and still
be outside a detector’s permitted search region. That distinction is the
heart of the final 15 kilometre example. Geometry tells us where an injected
echo ought to appear. The detector contract decides whether a cell is allowed
to test that location.

Source: S1, S11, S12. Display convention: see `notation_sign_contract.md`.

## 02:25–03:50 — Echo seed, propagation, and injection

The synthetic echo starts from a reference-derived seed. The seed is not
simply copied into every target path. A strong narrowband pilot-like line can
turn a moving echo into an artificial full-height Doppler column. The
producer therefore creates an echo-only conditioned copy when needed, then
RMS-matches it to the original seed. Propagation applies the geometry-driven
delay and Doppler behavior, and a relative complex-amplitude factor scales
the result before it is added to surveillance only. When a gain is specified
in decibels, its amplitude factor is ten raised to the gain divided by twenty.
For these cases the configured gain is minus eighteen decibels after that RMS
normalization. That is a useful controlled difficulty setting. It is not a
radar equation, a target radar-cross-section estimate, an antenna-pattern
model, or a prediction of calibrated field-aircraft received power. The
point is controlled placement and paired comparison, not aircraft
phenomenology.

Source: S1–S3.

## 03:50–05:10 — Synchronization

The two received channels must be synchronized before forming a passive map.
First, we estimate an integer lag. Conceptually, cross-correlation slides one
signal past the other and chooses the lag with the largest correlation
magnitude. The implementation deliberately checks both `finddelay` and
normalized `xcorr`. Their reported lag signs differ, so agreement requires a
sign-aware comparison; the current helper keeps the `xcorr` report as the
canonical lag. After that integer shift, small residual frequency mismatch
appears as a linearly changing cross-phase. The phase is fit as a constant
plus two pi times residual frequency times time. A unit-magnitude complex
phase ramp cancels the estimated slope. Finally, coherence, phase-fit error,
and estimator agreement check whether the correction is defensible. In the
paired demonstration, that correction is derived from the untouched control
and reused exactly for the injection path. It is not re-fitted to make the
target look better.

Source: S4–S5.

## 05:10–06:25 — Resampling and the 100 millisecond CPI

The field samples begin at 6.144 megahertz. The map path reduces the rate by
a factor of 200, yielding 30.72 kilohertz, and it filters the complete
corrected repetition before extracting the chosen CPI. This order matters:
filtering only a small selected slice can make a comparison represent a
different bandwidth. The selected coherent processing interval is 100
milliseconds, or 3,072 samples at the reduced rate. A duration of one tenth
of a second gives a nominal Fourier scale of one divided by T, which is ten
hertz. The saved map grid has a 3.75 hertz Doppler coordinate spacing and a
32.55 microsecond delay coordinate spacing. Those values describe how the
display samples coordinates. They are not independent declarations of
physical target resolution. Separating grid spacing from physical resolution
protects us from claiming more than finite-duration, finite-bandwidth data
can support.

Source: S6.

## 06:25–07:35 — Normalized LMS cancellation

The reference often predicts a strong direct-path or interference component
inside surveillance. An LMS filter learns a short filter whose output is that
prediction. The difference between surveillance and the prediction is the
residual passed to the map. The diagram shows adaptation reducing residual
error power, but that is deliberately only a conceptual curve. The current
code uses MATLAB’s normalized LMS System object. It compares three fixed
products: no filter, a conservative filter with a short length and lower step
size, and an aggressive filter with a longer length and larger step size.
Those names are relative profile labels, not universal good and bad settings.
More cancellation can reduce unwanted leakage and can also remove useful
target-like energy. Therefore the video calls them candidates and does not
select a formal G5 product. The detector settings remain fixed when the
candidates are compared.

Source: S7.

## 07:35–09:05 — CAF power map

Now we form a delay-Doppler representation. At a conceptual level, a
cross-ambiguity function compares delayed versions of one signal against
frequency-shifted versions of the other. Its magnitude tells us how strongly
the two signals agree at each delay and Doppler coordinate. The displayed
power map squares that magnitude. MATLAB’s `ambgfun` performs the actual
ambiguity calculation in the project, and the production helper records a
matrix orientation of rows equal Doppler and columns equal delay. There is an
important limit here. We do not display a formal signed or normalized CAF
equation. The current project combines `ambgfun` documentation, saved display
coordinates that negate physical geometry values, and a separately verified
streamed-cut orientation path. Compressing those into one formula before
reconciliation would be misleading. The picture is therefore an analytic
teaching visual, while the callout identifies the real map function and
matrix convention.

Source: S8 and the notation/sign contract.

## 09:05–10:40 — Fixed CA-CFAR and NMS

A map is not yet a list of candidates. The fixed detector first defines a
search rectangle. For every eligible cell under test, CA-CFAR uses surrounding
training cells to form a local power estimate. A threshold multiplier derived
from the chosen Pfa design input scales that estimate. The current geometry
has a three-by-one guard band, a twelve-by-four training band, and 320
training cells around each valid CUT. The configuration restricts the search
to displayed delay from minus 1200 to minus 150 microseconds and Doppler from
minus 750 to plus 750 hertz. After thresholding, a seven-by-three
nonmaximum-suppression neighborhood retains local peaks and resolves plateaus
deterministically. The value Pfa is a detector-model design input. It is not
a measured field false-alarm rate. The training stencil and peak grouping are
truth-blind: at this point no target trajectory has entered the algorithm.

Source: S9.

## 10:40–11:50 — Post-hoc association

Only after CFAR and NMS have created candidate rows do we compare them with
truth. Each candidate is measured against an expected delay and Doppler using
its delay error divided by the allowed delay half-width and its Doppler error
divided by the allowed Doppler half-width. The Euclidean length of those two
dimensionless errors is the association cost. MATLAB’s `matchpairs` then
selects one-to-one pairings among allowed matches. This ordering matters. If
truth moved a threshold, chose a local maximum, or selected the map crop, the
reported detection could no longer be called truth-blind. Here truth labels
the result afterward: target hit, nuisance control alarm, or unmatched
candidate. It does not create an `objectDetection` and it does not start a
tracker. Association makes the diagnostic experiment auditable; it does not
convert it into field-aircraft performance validation.

Source: S10.

## 11:50–13:20 — The 45 kilometre and 15 kilometre cases

The accepted 45 kilometre positive control sits near minus 269.5 microseconds
and plus 591.9 hertz in the project’s display convention. It lies inside the
fixed detector support. At Pfa equal to one times ten to the minus three, its
fixed diagnostic criterion passed: the injected truth associated after
truth-blind candidate generation, and the matched control had no nuisance
association. This is controlled synthetic-integration evidence. The 15
kilometre baseline lies near minus 76.5 microseconds and plus 540.5 hertz. It
is valid in the full physics-map context, but its delay is outside the fixed
upper support edge of minus 150 microseconds. Therefore the baseline detector
did not evaluate it. “Not evaluated” is not another word for “missed.” A
separate workspace-only support probe exists, but it does not widen the
production detector and is deliberately outside this video. The final
message is simple: a detector boundary is a declared search contract, not a
physical boundary and not evidence that a target disappeared.

Source: S11–S12.
