# Equation-Led Storyboard

Target duration: 800 s at 30 fps (13:20). The video has no generated audio;
`narration.md` is a timed voiceover script for later recording.

| Time | Chapter | General principle → equation | Implementation callout | Visual | Limitation / citation |
| --- | --- | --- | --- | --- | --- |
| 00:00–00:55 | 1. Evidence boundary | A controlled comparison changes one declared input. `x_surv,inj=x_surv,field+e_echo`. | Exact reference/control preservation checks in the paired runner. | Two-path block diagram with a red boundary card. | Diagnostic synthetic integration only. S1–S3. |
| 00:55–02:25 | 2. Bistatic geometry | `r_b=R_T+R_R-B`; `tau_b=r_b/c`. | Geometry-derived truth is saved with each synthetic case. | Tx/Rx/target geometry and excess-path ruler. | Display axes negate physical values; no field-aircraft claim. S1, S11–S12. |
| 02:25–03:50 | 3. Seed, propagation, injection | `e_echo=a·P{x_seed}` and `a=10^(G_dB/20)`. | Echo-only seed conditioning, RMS rematch, propagation, surveillance-only addition. | A seed waveform moving through a propagation box into surveillance. | `-18 dB` is a relative normalized gain, not RCS/radar-equation calibration. S1–S3. |
| 03:50–05:10 | 4. Synchronization | `k_hat=argmax|r_xy[k]|`; `phi(t)≈phi_0+2*pi*Delta_f*t`. | `finddelay`/`xcorr`, integer shift, cross-phase fit, unit-magnitude phase ramp. | Aligned analytic waveforms and phase-slope animation. | Estimator lag signs and correction sign are implementation conventions. S4–S5. |
| 05:10–06:25 | 5. Resampling and CPI | `F_s'=F_s/q`; `Delta_f_nominal=1/T_CPI`. | `resample` whole repetition first; select 100 ms center CPI. | Rate ladder plus coordinate-grid versus physical-scale comparison. | 3.75 Hz saved grid spacing does not independently claim 3.75 Hz resolution. S6. |
| 06:25–07:35 | 6. LMS candidate | `d[n]=y_hat[n]+e[n]`; the residual `e` is passed onward. | `dsp.LMSFilter` with none, conservative, aggressive profiles. | Adaptive filter coefficients and falling residual-energy curve. | Candidate comparison only; an adaptive filter can remove useful energy. S7. |
| 07:35–09:05 | 7. CAF power map | `P(tau,f)=|A(tau,f)|^2`. | `ambgfun(reference, surveillance, Fs, PRF)`, magnitude-to-power map. | Delay-shifted correlations accumulate into a code-drawn heatmap. | No formal signed/normalized CAF equation; rows=Doppler, columns=delay. S8. |
| 09:05–10:40 | 8. Fixed candidate generation | `P_CUT>alpha(Pfa)P_hat_noise`, then local-peak retention. | Fixed CA-CFAR support, `phased.CFARDetector2D`, 7×3 `imdilate`/`bwconncomp` NMS. | CA-CFAR stencil and NMS neighborhood over code-drawn power cells. | `Pfa` is a model design input, not measured field false-alarm rate. S9. |
| 10:40–11:50 | 9. Post-hoc association | `c=sqrt(d_tau^2+d_f^2)`. | `matchpairs` on normalized delay/Doppler error only after candidates exist. | Candidate dots appear before a truth ellipse and matching line. | Truth cannot steer map, threshold, NMS, or candidate generation. S10. |
| 11:50–13:20 | 10. Applied cases and sources | Fixed detector support is a search boundary, not a physics boundary. | Reuse compact final-example scalars; no map/replay is shown. | 45 km green “criterion passed”; 15 km amber “not evaluated”; references card. | No retune or support-widening conclusion. S11–S12. |

## Review gate checklist

- Every chapter contains a general principle, units-aware equation or explicit
  equation exclusion, implementation callout, visual, limitation, and source
  card.
- The CAF chapter has an explicit convention card rather than inventing a
  sign/normalization formula.
- The detector chapter calls `Pfa` a design input only.
- Candidate generation is shown before truth association.
- The 15 km baseline is called “not evaluated,” never “missed.”
- The video never names an `objectDetection` object, tracker, field-aircraft
  detection result, or formal gate transition.
