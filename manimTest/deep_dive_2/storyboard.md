# Deep Dive 2 Storyboard

Target duration: exactly 900 seconds / 15:00 at 30 fps. The render has no
audio; `narration.md` is a timed text script for a future approved voice pass.

| Time | Chapter | Purpose → transformation → visual change → limitation | Visual | Source |
| --- | --- | --- | --- | --- |
| 00:00–01:10 | Evidence boundary recap | Isolate one intervention → preserve control/reference and inject surveillance only → paired paths split at the echo block → diagnostic scope only. | Paired field-control and injected-path diagram. | S1–S3 |
| 01:10–03:00 | Geometry to display coordinates | Locate physics-map coordinate → compute excess path/delay and bistatic Doppler → positive physical delay becomes negative displayed delay → geometry does not grant detector eligibility. | Tx/Rx/target geometry plus convention card. | S11–S12 |
| 03:00–04:15 | Echo construction | Create a controlled echo → seed → condition → propagate → inject → delayed/Doppler-shifted trace joins surveillance → normalized gain is not aircraft calibration. | Signal-path pipeline and analytic waveform. | S1–S3 |
| 04:15–05:45 | Synchronization | Align channel evidence → lag and residual-phase correction → shifted peaks and phase slope become coherent traces → signs remain implementation conventions. | Before/after traces and correction card. | S4–S5 |
| 05:45–07:00 | Resampling and CPI | Form a bounded map input → whole-repetition filter/reduce/select → input samples become a 100 ms CPI → coordinate spacing is not independent physical resolution. | Whole-repetition rate ladder. | S6 |
| 07:00–09:00 | Direct-path mitigation | Reduce reference-correlated leakage → normalized LMS residual → conceptual leakage suppression with target-like-lobe tradeoff → teaching patterns only, no product decision. | Three code-drawn conceptual maps. | S7 |
| 09:00–10:20 | CAF power map | Test signal agreement hypotheses → `ambgfun` then power → localized lobe in a code-drawn map → no signed/normalized CAF summation formula. | Analytic power map and orientation card. | S8 |
| 10:20–12:05 | Fixed support, CFAR, NMS | Create candidates inside a declared boundary → support → threshold → sparse peaks → rectangle and dots → `Pfa` is a design input. | Frozen support, local decision rule, candidate dots. | S9 |
| 12:05–13:05 | Post-hoc association | Evaluate truth-blind candidates → normalized cost and `matchpairs` → truth window arrives after candidate dots → truth cannot steer candidate generation. | Ordered candidate-to-association diagram. | S10 |
| 13:05–15:00 | Linked receiver-local 45 km / 15 km north-offset scenarios | Separate geometry from detector eligibility → connect ENU plan view to displayed map markers → 45 km inside and 15 km visible outside delay edge → no widening, retune, or detector validation. | Receiver-local plan view plus schematic coordinate map. | S11–S12 |

## Final composition contract

- Horizontal receiver-local East/North plan view: Rx at `[0, 0]`, Tx derived
  from saved geometry at approximately `[E=9.290 km, N=1.155 km]`, and
  initial waypoint markers at approximately `[E=0, N=45.021 km]` and
  `[E=0, N=15.007 km]`. Altitude is explicitly omitted.
- Schematic **Range–Doppler (excess-delay–Doppler) coordinate map**, not a
  saved ambiguity image. Its displayed axes span about `−1250` to `+50 µs`
  and `−750` to `+750 Hz`.
- Frozen detector rectangle: `[-1200, -150] µs × [-750, +750] Hz`.
- 45 km marker: `(-269.5 µs, +591.9 Hz)`, inside frozen support.
- 15 km marker: `(-76.5 µs, +540.5 Hz)`, visible but outside the `−150 µs`
  delay edge and therefore not evaluated under this frozen support.
- Convention card: `tau_display = -tau_excess` and
  `f_display = -f_bistatic`. This is this project's display convention, not
  a universal passive-bistatic or CAF sign rule.
