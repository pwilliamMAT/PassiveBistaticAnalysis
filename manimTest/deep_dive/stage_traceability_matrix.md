# Stage Traceability Matrix

This matrix is the pre-animation audit. “Universal” means a teaching equation
whose physical interpretation does not depend on this repository. “Project
convention” means a code/data-display choice and is explicitly labeled as
such in the video.

| Stage | Signal definition / equation | Units | Input → output | MATLAB implementation | Project convention and source | Validation evidence / claim boundary |
| --- | --- | --- | --- | --- | --- | --- |
| Evidence boundary | paired inputs: `x_ref` unchanged; `x_surv,inj = x_surv,field + e_echo` | complex IQ samples | field capture → control and injected inputs | External `generateRealBackgroundSyntheticSuite`; `runRealBackgroundSyntheticPipeline` | Reference is channel 2 and surveillance is channel 1 in this demo; echo is surveillance-only | Runner requires exact reference/control preservation and finite nonzero surveillance delta. Diagnostic synthetic integration only. |
| Bistatic geometry | `r_b(t)=R_T(t)+R_R(t)-B`; `tau_b(t)=r_b(t)/c` | m; s | Tx/Rx/target geometry → excess delay | trajectory construction and saved truth bundle | Video displays `-tau_b`; see notation contract | 45 km and 15 km geometry are valid in physics-map context. Geometry does not make a target detector-eligible. |
| Echo seed and injection | `e_echo[n]=a·P{x_seed}[n]`; `a` is a relative amplitude after RMS matching | complex samples; dimensionless amplitude ratio | reference-derived seed → propagated echo → surveillance delta | `helperSyntheticBuildConditionedEchoSeed`; `phased.WidebandFreeSpace` | `a=10^(G_dB/20)` is not a calibrated radar-equation or RCS model. The applied scenario gain is `-18 dB`. | Conditioning avoids a dominant-line artifact; it does not model field-aircraft received power. |
| Integer synchronization | `r_xy[k]=Σ x[n]y*[n-k]`; `k̂=argmax_k |r_xy[k]|` | samples; normalized correlation | reference + surveillance → integer-aligned surveillance | `finddelay`, normalized `xcorr`, local integer shift | `finddelay` and `xcorr` use opposite lag sign reports; code selects the `xcorr` lag as canonical | Both estimators are retained as agreement evidence. The video uses an analytic waveform, not saved IQ. |
| Residual frequency | `φ(t)≈φ_0+2πΔf t`; correction has unit magnitude `exp(-j2πΔf n/F_s)` | rad; Hz; samples/s | aligned signal → phase-corrected signal | STFT cross-phase fit; complex phase ramp | Minus sign is the current cancellation convention after the G3 estimate; see source lines in register | Coherence and fit residuals are checks, not a claim that all synchronization error is removed. |
| Resampling and CPI | `F_s' = F_s/q`; `T_CPI=N/F_s`; nominal Doppler scale `1/T_CPI` | Hz; s; Hz | corrected repetition → reduced-rate 100 ms CPI | `resample`; CPI extraction | Factor `q=200`: `6.144 MHz → 30.72 kHz`; full repetition is filtered before CPI extraction | Grid spacing is coordinate sampling; it is not an independent physical-resolution claim. |
| LMS mitigation | `d[n]=y_hat[n]+e[n]`; normalized-LMS adapts `y_hat` from reference | complex samples; power | reference + surveillance → residual error | `dsp.LMSFilter` | Current profiles: conservative `(L=16, μ=.02, leakage=1)` and aggressive `(L=64, μ=.15, leakage=.999)` | Candidate comparison only; no formal G5 selection. An adaptive filter can suppress desired energy. |
| CAF power map | `A(τ,f)` is a cross-ambiguity representation; displayed map power is `|A|²` | s; Hz; arbitrary normalized power | reference + candidate surveillance → delay-Doppler power map | `ambgfun`; magnitude squared | Rows are Doppler and columns are delay. No formal signed/normalized CAF equation is shown. | `ambgfun` remains the map oracle. Sign/normalization terms are intentionally withheld until reconciled; see notation contract. |
| CA-CFAR and NMS | local noise estimate `P̂_N`; candidate condition `P_CUT > α(P_fa)P̂_N` | linear power; probability design input | power map → truth-blind candidate cells | `phased.CFARDetector2D`, `imdilate`, `bwconncomp` | Fixed support is delay `[-1200,-150] µs`, Doppler `±750 Hz`; 7×3 NMS is `[Doppler, delay]` | `Pfa` is a detector-model design input, not a measured field false-alarm rate. No detector retuning occurs. |
| Post-hoc association | `d_τ=|τ_truth-τ_det|/h_τ`; `d_f=|f_truth-f_det|/h_f`; cost `sqrt(d_τ²+d_f²)` | dimensionless | candidates + truth → one-to-one association labels | `matchpairs` | Match only if both normalized errors are at most 1; truth enters after candidate generation | Truth-blind CFAR/NMS is preserved. The 15 km baseline has no eligible detector CUT and is not a miss. |

## Native Function Audit

| Proposed feature | Native MATLAB function / object | Documentation syntax template | Current implementation delta |
| --- | --- | --- | --- |
| Integer lag estimate | `finddelay`, `xcorr` | `d = finddelay(x,y,maxlag)`; `[c,lags] = xcorr(x,y,maxlag,"normalized")` | Cross-check both reports; retain the `xcorr` lag as canonical. |
| Rate conversion | `resample` | `[y,b] = resample(x,p,q)` | Use `p=1`, `q=200`, filter complete repetitions before CPI extraction. |
| Adaptive cancellation | `dsp.LMSFilter` | `[y,e,w] = lms(x,d)` | Use residual `e` as candidate surveillance. |
| Passive map | `ambgfun` | `[af,delay,doppler] = ambgfun(x,y,Fs,PRF)` | Square magnitude for map power; retain rows=Doppler, columns=delay. |
| CA-CFAR noise estimate | `phased.CFARDetector2D` | `[det,noise] = cfar(map,CUTs)` | Use custom threshold factor 1 for local noise, then apply fixed `α(Pfa)` externally. |
| Local maxima | `imdilate`, `bwconncomp` | `d = imdilate(A,SE)` | Use fixed 7×3 neighborhood and deterministic plateau tie resolution. |
| One-to-one association | `matchpairs` | `pairs = matchpairs(cost,costUnmatched,"min")` | Cost is normalized delay/Doppler Euclidean error; association is post hoc only. |

All five core anchors had zero MATLAB Code Analyzer issues on 2026-09-15;
see [code_analyzer_audit.md](code_analyzer_audit.md).
