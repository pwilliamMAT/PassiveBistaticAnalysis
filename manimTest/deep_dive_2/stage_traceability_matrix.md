# Stage Traceability Matrix

| Stage | Purpose | Implementation transformation | Expected code-drawn visual | Limitation / source |
| --- | --- | --- | --- | --- |
| Paired evidence | Isolate a controlled intervention. | Preserve reference/control; add echo to surveillance only. | Two paths differ at one injection block. | Diagnostic synthetic integration only. S1–S3. |
| Geometry | Locate physical excess-delay/Doppler context. | WGS-84 Tx/Rx/target geometry and display-coordinate conversion. | Positive physical delay paired with intentional negative displayed delay. | Geometry does not confer detector eligibility. S11–S12. |
| Echo construction | Create a controlled echo input. | Seed → condition → propagate → surveillance-only injection. | Delayed/Doppler-shifted analytic echo. | Relative normalized gain is not aircraft calibration. S1–S3. |
| Synchronization | Align channels before hypothesis testing. | Lag estimate, residual-phase fit, correction reuse. | Misaligned traces become coherent. | Sign choices are implementation conventions. S4–S5. |
| Resampling/CPI | Form bounded map input. | Whole-repetition filter/reduce/select. | 6.144 MHz to 30.72 kHz to 100 ms CPI. | Coordinate spacing is not independent physical resolution. S6. |
| Mitigation | Reduce direct-path leakage candidate. | Normalized LMS residual `e[n]`. | Before/conservative/aggressive analytic maps. | Teaching patterns only; no product decision. S7. |
| CAF power | Evaluate delay/Doppler hypotheses. | `ambgfun`, magnitude-to-power conversion. | Localized analytic lobe. | No signed/normalized CAF summation formula. S8. |
| CFAR/NMS | Generate sparse candidates. | Frozen support, local threshold, 7×3 peak retention. | Rectangle then candidate dots. | No support change; `Pfa` is a design input. S9. |
| Association | Evaluate candidates after generation. | Normalize coordinate error; `matchpairs`. | Truth arrives after candidate dots. | Truth cannot steer map or candidate generation. S10. |
| Linked cases | Separate map context from detector boundary. | Native `geodetic2enu` scalar extraction and support test. | ENU plan view linked to schematic coordinate map. | 15 km is not evaluated under frozen support. S11–S12. |

## Native Function Audit

| Proposed feature | Native MATLAB function / object | Documentation syntax template | Sequel-specific use |
| --- | --- | --- | --- |
| Receiver-local geometry | `geodetic2enu` | `[xEast,yNorth,zUp] = geodetic2enu(lat,lon,h,lat0,lon0,h0,ellipsoid)` | Convert saved Tx and initial target waypoints to Rx-local ENU. |
| WGS-84 reference | `wgs84Ellipsoid` | `wgs84Ellipsoid("meter")` | Bind ENU conversion to a meter-based WGS-84 ellipsoid. |
| Hash-verified scalar package | `load`, `jsonencode` | `loaded = load(file,"results")`; `jsonencode(value)` | Read only `results.Trajectory` and write only compact scalar JSON. |
| Rate conversion | `resample` | `[y,b] = resample(x,p,q)` | Cite the established whole-repetition reduction contract. |
| Mitigation candidate | `dsp.LMSFilter` | `[y,e,w] = lms(x,d)` | Cite residual formation; render analytic maps only. |
| Passive map | `ambgfun` | `[af,delay,doppler] = ambgfun(x,y,Fs,PRF)` | Cite map formation; render analytic power only. |
| Candidate generation | `phased.CFARDetector2D` | `[det,noise] = cfar(map,CUTs)` | Cite the frozen truth-blind candidate sequence. |
| Association | `matchpairs` | `pairs = matchpairs(cost,costUnmatched,"min")` | Cite post-hoc normalized one-to-one labels. |
