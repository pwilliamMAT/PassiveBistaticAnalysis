# Notation and Sign Contract

Deep Dive 2 distinguishes physical quantities, project display choices, and
analytic teaching visuals.

## Established equations shown

| Concept | Teaching expression | Constraint |
| --- | --- | --- |
| Excess path | `r_excess = R_T + R_R - B` | Physical path difference relative to the Tx–Rx baseline. |
| Excess delay | `tau_excess = r_excess / c` | Physical excess delay is positive for both final scenarios. |
| Echo amplitude | `a = 10^(G_dB/20)` | Relative normalized scenario amplitude only. |
| Synchronization residual phase | `phi(t) ≈ phi_0 + 2*pi*Delta_f*t` | Project correction convention is separately labeled. |
| Resampling | `F_s' = F_s / q` | Complete repetition is filtered/reduced before CPI selection. |
| CPI scale | `1 / T_CPI` | Nominal duration scale, not a separability guarantee. |
| LMS residual | `e[n] = d[n] − d_hat[n]` | Residual is the candidate map input. |
| CAF power | `P(tau,f) = |A(tau,f)|²` | Power representation only. |
| CFAR decision | `P_CUT > alpha(Pfa) P_hat_noise` | Conceptual local-threshold relation. |
| Association cost | `sqrt((Delta tau / h_tau)² + (Delta f / h_f)²)` | Normalized post-hoc matching cost. |

## Project-specific display conventions

| Item | Convention | Required viewer-facing limitation |
| --- | --- | --- |
| Displayed delay | `tau_display = -tau_excess` | Negative displayed delay is intentional, while physical excess delay is positive. |
| Displayed Doppler | `f_display = -f_bistatic` | This is not a universal Doppler sign rule. |
| Map orientation | rows = Doppler, columns = delay | Applies to this project display. |
| Final detector support | `[-1200, -150] µs × [-750, +750] Hz` | Frozen diagnostic support; no change is asserted. |

## CAF equation exclusion

The video does not add a signed or normalized CAF summation formula. The
project's `ambgfun` call, power conversion, display-coordinate signs, and
orientation evidence are individually identified, but this sequel does not
compress them into a broader formula.
