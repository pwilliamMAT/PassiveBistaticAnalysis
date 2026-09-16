# Notation and Sign Contract

## Purpose

The video separates reusable signal-processing mathematics from the
repository’s implementation and display conventions. A viewer should not
mistake a plot axis sign or a normalization choice for a universal physical
law.

## Universal equations shown

| Concept | Teaching expression | Meaning |
| --- | --- | --- |
| Excess path | `r_b = R_T + R_R - B` | Additional bistatic path relative to the Tx–Rx baseline. |
| Delay | `tau_b = r_b / c` | Excess-path delay, in seconds. |
| Doppler magnitude | `|f_b| = |d(R_T+R_R)/dt| / lambda` | Magnitude follows bistatic path-rate magnitude; the displayed sign requires a convention. |
| Echo amplitude | `a = 10^(G_dB/20)` | Relative complex-amplitude factor from a gain specified in dB. |
| Lag observable | `k_hat = argmax_k |r_xy[k]|` | Integer sample lag from correlation. |
| Residual phase | `phi(t) ~= phi_0 + 2*pi*Delta_f*t` | Linear phase slope identifies a residual frequency. |
| CPI scale | `Delta_f_nominal = 1/T_CPI` | Duration-limited Fourier scale, not a guarantee of separability. |
| CAF power display | `P(tau,f) = |A(tau,f)|^2` | Power representation after an ambiguity-function calculation. |
| CA-CFAR decision | `P_CUT > alpha(Pfa)*P_hat_noise` | Conceptual thresholding relation. |
| Association cost | `c = sqrt(d_tau^2 + d_f^2)` | Dimensionless normalized delay/Doppler distance. |

## Project-specific conventions shown

| Item | Convention | Video treatment |
| --- | --- | --- |
| Roles | Field-demo channel 2 is reference; channel 1 is surveillance. | Label as “this demonstration.” |
| Saved display delay | `display delay = -excess delay`. | Label displayed coordinates, not physical delay. |
| Saved display Doppler | `display Doppler = -bistatic Doppler`. | Label displayed coordinates, not universal Doppler sign. |
| Synchronization correction | Current helper multiplies by `exp(-j2*pi*f_hat*n/F_s)` after its cross-phase estimate. | State this as the implementation’s cancellation convention. |
| Map matrix orientation | Map rows are Doppler; columns are delay. | State explicitly on CAF and detector cards. |
| Map power | Current production helper squares `ambgfun` magnitude and applies its stored native normalization. | Explain the magnitude-to-power step; do not generalize the normalization. |
| Detector geometry | Fixed G6-D support, 3×1 guard band, 12×4 training band, 7×3 NMS. | State fixed diagnostic configuration and avoid retune language. |

## CAF equation exclusion

The video intentionally does **not** display a formal signed or normalized CAF
equation. The following are individually established but not yet compressed
into one viewer-facing formula:

1. `ambgfun` owns the MATLAB ambiguity-function convention.
2. Current production map formation calls `ambgfun(reference, surveillance, Fs, PRF)`.
3. Saved geometry display coordinates negate physical excess delay and
   bistatic Doppler.
4. R1 streamed-cut validation used `CutValue=-physicalDoppler` and reversed
   returned delay samples to reconcile a specific orientation path.
5. Production full-map power is `max(single(magnitude).^2, eps("single"))`
   with `ambgfun_native_normalization`.

Presenting a single sign/normalization formula without reconciling all five
would overstate what the saved evidence establishes. The video therefore
teaches the general role of a CAF and labels the saved axes as an
implementation convention.
