# Deep Dive 2 Narration and Timing

This is a text-only script synchronized to a 900-second / 15:00 caption-led
video. No generated or embedded audio is part of the deliverable.

## 00:00–01:10 — Evidence boundary recap

The starting claim is deliberately narrow. This is a diagnostic
synthetic-integration exercise in real field background. The control keeps
the recorded reference and surveillance unchanged. The injected path keeps
the same reference and field surveillance, then adds one geometry-driven echo
to surveillance only. That paired structure makes the intervention visible:
the reference stays fixed, the control remains untouched, and the synthetic
delta must be finite and nonzero. It does not establish field-aircraft
detection, select a mitigation product, validate a detector, or open
tracking.

Source: S1–S3.

## 01:10–03:00 — Geometry to display coordinates

The physical quantity is excess path: transmitter-to-target distance plus
target-to-receiver distance minus the direct transmitter-to-receiver
baseline. Dividing by the speed of light gives positive physical excess
delay. Motion changes the two-hop path and produces bistatic Doppler. The
final coordinate map displays the negative of each physical quantity:
`tau_display = -tau_excess` and `f_display = -f_bistatic`. Those signs are
this project's display convention, not a universal passive-bistatic or CAF
sign rule. A physical coordinate explains where an echo belongs in a map; it
does not decide whether a detector may inspect that coordinate.

Source: S11–S12.

## 03:00–04:15 — Echo construction

The controlled echo begins with a reference-derived seed. The seed may be
conditioned for the echo path and RMS-matched before propagation. Geometry
then supplies delay and Doppler, and a relative amplitude scales the echo
before it is added to surveillance. The configured minus eighteen decibel
gain is a normalized scenario difficulty setting. It is not a radar equation,
target radar-cross-section estimate, antenna-pattern model, or calibrated
aircraft received-power prediction. The expected visual change is simply a
delayed, Doppler-shifted echo joining surveillance while the reference remains
unchanged.

Source: S1–S3.

## 04:15–05:45 — Synchronization

Before map formation, the channels must be aligned. An integer lag estimate
chooses the correlation shift with the strongest magnitude. A remaining
linear cross-phase slope estimates residual frequency, and a unit-magnitude
phase ramp removes the estimated slope. The visual begins with displaced
peaks and a sloped phase relationship, then shows coherence after correction.
For the paired diagnostic, the correction is derived from the field-only
control and reused exactly for injection. Lag and phase-correction sign
choices are implementation conventions; synchronization evidence does not
prove every impairment has disappeared.

Source: S4–S5.

## 05:45–07:00 — Resampling and CPI

The processing path filters and reduces the whole corrected repetition before
selecting a coherent processing interval. Here the input rate is 6.144 MHz,
the reduction factor is 200, and the map rate is 30.72 kHz. The selected CPI
is 100 milliseconds, or 3,072 reduced-rate samples. Its nominal Fourier
scale is one over CPI duration, or ten hertz. That scale and the saved
coordinate-grid spacing help interpret a display, but neither independently
proves physical target resolution. The order—whole repetition, then reduce,
then select—also prevents a small selected slice from silently representing a
different filtered bandwidth.

Source: S6.

## 07:00–09:00 — Direct-path mitigation

Reference-correlated direct-path structure can dominate a passive map. The
normalized LMS candidate predicts that component and forms the residual
`e[n] = d[n] − d_hat[n]`. The three maps in this chapter are analytic teaching
patterns. Before mitigation, near-zero-Doppler leakage dominates. Conservative
mitigation reduces that leakage while retaining a target-like lobe.
Aggressive mitigation suppresses more leakage but can weaken the target-like
lobe. These illustrations show the risk that cancellation can remove useful
energy. They are not recorded maps and do not choose a formal mitigation
product.

Source: S7.

## 09:00–10:20 — CAF power map

A cross-ambiguity representation tests delayed and frequency-shifted
hypotheses between synchronized signals. The project uses `ambgfun` for that
calculation and displays power as `P(tau,f) = |A(tau,f)|²`. Rows represent
Doppler and columns represent delay in the project map orientation. The
localized lobe is an analytic teaching visual, not a saved ambiguity image.
The video intentionally does not display a signed or normalized CAF
summation formula, because those details would require a broader convention
reconciliation than the compact evidence establishes.

Source: S8.

## 10:20–12:05 — Fixed support, CFAR, and NMS

Candidate generation first declares a search rectangle. Only eligible cells
inside that rectangle receive a local CA-CFAR noise estimate and a conceptual
threshold comparison, `P_CUT > alpha(Pfa) P_hat_noise`. A seven-by-three
nonmaximum-suppression neighborhood then retains sparse local peaks. The
visual moves from a full coordinate frame to a frozen rectangle and then to
candidate dots. `Pfa` is a detector-model design input, not a measured field
false-alarm rate. Truth has not participated in this candidate-generation
sequence.

Source: S9.

## 12:05–13:05 — Post-hoc association

After candidates exist, expected truth coordinates can be compared with them.
Delay and Doppler errors are normalized by permitted truth-window half
extents, and `matchpairs` selects allowed one-to-one links. The visual makes
the order explicit: amber candidates appear before the green truth window and
match line. Association labels a result afterward. It cannot select the map
crop, move the support rectangle, set a CFAR threshold, or change NMS.

Source: S10.

## 13:05–15:00 — Linked receiver-local 45 km / 15 km north-offset scenarios

The final plan view is receiver-local East/North. Receiver is at the origin;
the transmitter is derived from the hash-verified saved geometry at about
east 9.290 km and north 1.155 km. The scenario markers are initial
receiver-local north offsets of about 45.021 km and 15.007 km. Altitude is
omitted from this horizontal inset.

The linked coordinate map is schematic, not a saved ambiguity image. The
45 km receiver-local north-offset scenario maps near minus 269.5 microseconds
and plus 591.9 hertz, inside the frozen rectangle
`[-1200, -150] µs × [-750, +750] Hz`. The 15 km receiver-local north-offset
scenario maps near minus 76.5 microseconds and plus 540.5 hertz. It remains
visible in the coordinate map but lies outside the negative 150 microsecond
delay edge. Its physical excess delay is positive; its negative displayed
delay is intentional. Under the frozen rectangle, the 15 km scenario is not
evaluated. That conclusion does not widen the rectangle, retune the detector,
or validate field-aircraft detection.

Source: S11–S12.
