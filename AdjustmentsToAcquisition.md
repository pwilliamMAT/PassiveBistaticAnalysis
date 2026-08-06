# Adjustments To Acquisition

This file captures the external data-acquisition improvements identified during `G2_RF_Health` Stage 1 review of session `20260622T102123`.

The goal is to reduce manual backfill, convert operator memory into explicit recorded evidence, and collect the missing proof needed for stronger Stage 1 acquisition-validation outcomes in future sessions.

## Recommended Artifact Split

- `session_manifest.json`
  Machine-known collection settings and named per-channel settings that the acquisition software can emit directly.
- `logs/flighttest_capture_*.log`
  Raw hardware initialization, lock/readback status, stream-health counters, and verification-step messages captured at collection time.
- `collection_metadata.json`
  Operator-entered physical setup, antenna identity, site geometry, and notes that the hardware/software stack cannot infer automatically.
- `verification/`
  Small dedicated preflight artifacts such as channel-mapping verification captures, lock snapshots, and any quick sanity-check measurements.

## Highest-Priority Gaps To Close

| Gap | Information needed | Why it matters | Suggested way to obtain it | Best artifact |
| :--- | :--- | :--- | :--- | :--- |
| Physical antenna identity is partly manual | Exact antenna installed on each receive port, including role, antenna name, antenna type, and any inline amplifier/attenuator | Prevents ambiguity between RF-chain labels and actual field hardware | Add a preflight operator form or config step that requires selecting the installed hardware for each port before capture starts | `collection_metadata.json` plus a short echo in the capture log |
| Per-channel gain meaning is not explicit in machine output | Requested gain mode and the named mapping from each gain value to each receive channel | A raw gain vector like `28,48` is not self-explanatory without logger-order knowledge | Emit a named mapping such as `RF0:RX2=28 dB`, `RF1:RX2=48 dB`, plus `gain_mode=manual` or `gain_mode=agc` | `session_manifest.json` and capture log |
| Overrun/drop evidence is missing | Explicit overrun, overflow, or dropped-sample counters, including zero counts | Stage 1 needs proof the stream was healthy, not just an absence of remembered problems | Record UHD stream-health counters or explicit overflow status at the end of each repetition and for the session total | Capture log and a JSON summary |
| Lock status evidence is missing | Configured clock/time source and actual lock/readback status | Configuration intent does not prove the hardware actually locked | Query and log available lock/readback flags before collection begins and after the device is configured | Capture log and a lock snapshot JSON |
| Channel-role mapping proof is missing | A deliberate verification showing which physical path is reference and which is surveillance | IQ-only inference is weaker than intentional proof | Add a short preflight mapping-verification step using a known perturbation or test capture | `verification/` artifact plus a note in the log |
| Site and geometry context is partly manual | Antenna pointing, location note, height, polarization, and obvious clutter/obstruction notes | Helps explain later null or weak results without relying on memory | Add a short operator form completed during setup, not after the run | `collection_metadata.json` |

## Specific Information To Capture For Each Session

### 1. Channel And Hardware Mapping

Capture the following for each receive path:

- N320 section and port, for example `RF0:RX2` and `RF1:RX2`
- Logical role, for example `surveillance` or `reference`
- Antenna name and antenna type
- Manufacturer and model, if known
- Inline components in order, for example antenna, balun, amplifier, attenuator, cable, adapter

Suggested collection method:

- Present the operator with a per-channel setup form before the run starts.
- Require confirmation that the declared `reference` and `surveillance` channels match the physical connections.
- Echo the final mapping into the capture log so the mapping is frozen in a machine-generated artifact.

### 2. Gain Settings And Gain Mode

Capture the following:

- Gain mode, explicitly `manual` or `agc`
- Per-channel requested gain with named channel labels
- Any later gain changes during the session

Suggested collection method:

- Have the acquisition path write the named gain mapping directly from the configuration object rather than storing only a positional gain vector.
- If AGC is unavailable, log `gain_mode=manual` explicitly rather than forcing later inference from source code.

### 3. Stream Health

Capture the following:

- Overrun count
- Overflow count
- Dropped-sample count
- Any buffer or disk-throughput warnings
- An explicit zero when no errors occurred

Suggested collection method:

- Add end-of-repetition and end-of-session stream-health summaries to the logger.
- If the radio API does not expose a numeric counter, log a strong textual statement such as `no overruns observed` so the evidence is still explicit.

### 4. Clock, Time, And Lock State

Capture the following:

- Configured `clock_source`
- Configured `time_source`
- Actual lock/readback status after configuration
- Any not-applicable cases, for example when an external lock signal is not being used

Suggested collection method:

- Query the device after the clock and time sources are set.
- Save both the raw readback and a normalized summary.
- If a source is intentionally internal, record that explicitly so later review can distinguish `not applicable` from `not checked`.

### 5. Channel-Mapping Verification

Capture one intentional proof step per session or per hardware reconfiguration.

Useful verification methods:

- Inject a known tone or signal into one receive path only.
- Temporarily terminate, disconnect, or cover one antenna and verify the expected channel changes.
- Swap the two receive paths in a short controlled test and confirm the channel labels move as expected.
- Record a short dedicated `mapping verification` capture before the main run.

Recommended minimum:

- Keep a short verification capture in a `verification/` folder.
- Log the method used and the expected outcome in the main capture log.

## Additional Antenna Information Worth Capturing

### Reference Dipole

The current reference description is already useful, but these additional details would help:

- Approximate polarization
- Mount height
- Feedline type and length
- Whether any matching hardware, balun, amplifier, or attenuator is in the path
- Whether `600 MHz tuned` refers to design frequency, measured resonance, or intended operating target

Suggested collection method:

- Add these as simple operator-entered fields in `collection_metadata.json`.
- If exact values are unknown, allow approximate text such as `~3 m AGL` or `assumed vertical polarization`.

### Surveillance Yagi

The current Yagi product-page details are useful, but the most important missing clarifications are:

- Polarization
- Mount height
- Approximate azimuth or compass heading, not just `pointed west`
- Beamwidth, if known
- Whether the quoted gain is passive antenna gain or active amplified-system gain
- Whether the amplifier is powered, bypassed, or suspected failed during the session
- If the antenna rotates, whether it was fixed or actively repositioned

Suggested collection method:

- Maintain a simple antenna inventory file with manufacturer, model, frequency range, and any trusted specs.
- During session setup, select the installed antenna from that inventory and record session-specific orientation and amplifier state separately.

## How To Better Characterize The Yagi And Amplifier

The current product listing appears to describe an amplified consumer TV antenna assembly, not a clean passive-antenna datasheet. For future sessions, the most valuable additions would be:

- Separate the passive antenna identity from the amplifier identity if they can be distinguished
- Record whether AC power was actually applied to the amplifier for the session
- Record whether the amplifier was intentionally in line, bypassed, or uncertain
- Run a quick A/B sanity check with amplifier powered versus unpowered or bypassed
- If practical, record a simple bench measurement or comparative field measurement showing whether the amplifier changes received power or noise floor

Suggested collection method:

- Add `amplifier_model`, `amplifier_powered`, and `amplifier_state_note` fields to the session metadata.
- During preflight, capture a short comparison snippet or operator observation such as `amp bypassed for verification` or `amp powered, no visible change`.

## RF Test Matrix For Next-Session Reference-Channel Improvement

This matrix is for the next field session and assumes off-the-shelf hardware only. It keeps the current architecture fixed:

- `reference` remains the transmitter-facing channel and should collect the strongest cleanest direct-path replica available.
- `surveillance` remains the scene-facing channel and should preserve the aircraft-observation geometry rather than being weakened just to make Stage 2 look cleaner.
- The present weakness should be treated as a reference-path improvement problem first, not as a reason to invert channel purpose blindly.
- Post-ADC digital gain is not an RF fix. It can rescale samples for display, but it does not improve the received direct-path SNR or ADC headroom.
- The current hardware-comparison result with an inline LNA on the accepted reference path did not resolve Stage 2 by itself, so the next campaign should isolate antenna, filter, and gain changes in a controlled order.

### Native MATLAB Workflow Audit

| Proposed Workflow | Native MATLAB Documentation Example Analogue | Updates needed to fit current goal |
| :--- | :--- | :--- |
| Compare reference-path hardware variants using saved captures and Stage 2 outputs | Signal-quality screening with `pwelch`, `bandpower`, `table`, `tiledlayout`, and `exportgraphics` | Reuse the current G2 Stage 2 evidence style, but organize captures as a controlled RF campaign rather than a single-session review |
| Compare antenna and gain-path hypotheses across repeated short captures | Table-based experiment logging and artifact comparison in MATLAB | Add explicit test IDs, hypothesis text, fixed-vs-varied controls, and pass/fail interpretation fields |
| Decide whether the reference path is geometry-limited, antenna-limited, or front-end-limited | Existing G2 Stage 1 and Stage 2 evidence workflow | Add mandatory mapping-verification, stepped-gain, and reference-aimed preflight captures before the main dwell |

| Proposed Feature / Algorithm | Native MATLAB Function/Toolbox Equivalent | Documentation Syntax Template Used |
| :--- | :--- | :--- |
| PSD and direct-path comparison | `pwelch` | `[pxx,f] = pwelch(x,window,noverlap,nfft,fs,"centered")` |
| In-band and DC-band power comparison | `bandpower` | `bp = bandpower(pxx,f,[f1 f2],"psd")` |
| Coherence comparison between channels | `mscohere` | `cxy = mscohere(x,y,window,noverlap,nfft,fs)` |
| Summary tables for campaign decisions | `table` and `writetable` | `T = table(...); writetable(T,path)` |

### Expert Default Recommendations

- Keep the current channel roles fixed unless a dedicated mapping-verification capture proves the physical mapping is wrong.
- Prioritize reference-antenna directivity, transmitter pointing, polarization match, and front-end filtering before increasing gain.
- Use analog gain changes and LNAs only with explicit headroom checks against clipping, exact-rail occupancy, and IQ/DC degradation.
- Do not reduce surveillance performance just to force a Stage 2 power-ordering pass unless receiver protection or shared dynamic-range limits require it.
- Avoid consumer amplified TV antennas as the primary reference-path recommendation until the passive antenna element and amplifier state are separately identified and controlled.

### Candidate Reference Antenna Classes

| Candidate class | Best use case | Why it is attractive | Main caveats | Recommendation |
| :--- | :--- | :--- | :--- | :--- |
| Narrowband directional UHF Yagi or Yagi-class antenna | Single dominant illuminator near `599 MHz` with a stable transmitter bearing | Highest practical off-the-shelf forward gain and front-to-back discrimination for the next session | Narrowband, sensitive to pointing error, polarization mismatch, and local multipath nulls | `Priority 1` for the next session |
| Broadband directional LPDA | Future multi-illuminator use or uncertainty about future reference frequency | Wider bandwidth and easier reuse across later illuminators without replacing the antenna | Lower peak gain than a tuned Yagi at the target frequency and typically larger physical size | `Priority 2` comparison candidate |
| Narrowband panel or patch-style directional antenna | Fixed geometry where compact mounting and controlled forward lobe matter more than frequency agility | Cleaner packaging and potentially simpler repeatable mounting than a long boom antenna | Usually narrower bandwidth and more sensitive to mounting and polarization details | Optional follow-up if Yagi mounting is awkward |

For the next session, the default expert choice is a dedicated narrowband directional reference antenna aimed at the transmitter. Another Yagi therefore does fit the bill as the first candidate, but it should be a transmitter-facing reference antenna chosen for the illuminator band rather than a generic consumer TV assembly. The smarter off-the-shelf comparison is not to skip the Yagi, but to compare that narrowband reference candidate against a broadband directional option such as an LPDA so future flexibility is priced in explicitly.

### Fixed Campaign Controls

Hold these items fixed across the comparison rows unless the row explicitly says otherwise:

- Site and receiver placement
- Illuminator frequency near `599 MHz`
- Sample rate `6.144 MHz`
- Surveillance antenna hardware, pointing, and cable path
- Main dwell format of `15 x 1 s` captures when practical so Stage 2 outputs stay comparable
- Named per-channel gain mapping in the manifest and capture log
- One mapping-verification artifact before the main dwell

### RF Test Matrix

| Test ID | Hypothesis | Reference-path change | What stays fixed | Required capture type | Expected improvement signal | Primary acceptance metrics | Failure interpretation | Next action |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `RFM-00` | The current baseline is repeatable and should be frozen before hardware changes | Keep the current dipole reference path and current gains exactly as used in the baseline | All fixed campaign controls | Mapping verification plus one main dwell | Reproduce the current weak-reference result within normal field variation | Reference-minus-surveillance median remains close to the current baseline and no new clipping, DC, or IQ issue appears | The setup is not stable enough to compare hardware changes yet | Stop and re-baseline before interpreting later rows |
| `RFM-01` | The declared reference and surveillance channels are physically correct | No RF hardware change; perform a deliberate mapping proof by cover, disconnect, or injected-tone method | All fixed campaign controls | Dedicated verification capture only | The deliberate perturbation appears on the declared channel and nowhere ambiguous | Channel mapping is explicit and reviewable from the saved artifact | Channel purpose is still ambiguous or mislabeled | Fix the mapping before further RF tuning |
| `RFM-02` | The current dipole is mainly limited by placement or polarization rather than by antenna type alone | Reposition and orient the dipole for the best direct transmitter view and polarization match without changing gain | Surveillance path, site, and main dwell | Short diagnostic capture plus one main dwell | Reference power improves materially without new contamination | At least `3 dB` improvement versus `RFM-00`, no clipping, and no worse DC/IQ metrics | The dipole remains fundamentally directivity-limited | Move to a directional reference antenna |
| `RFM-03` | A narrowband directional reference antenna is the highest-value next hardware change | Replace the dipole with a dedicated UHF Yagi-class antenna aimed at the transmitter, keeping the initial gain settings unchanged | Surveillance path and all non-reference controls | Short diagnostic capture plus one main dwell | Large improvement in direct-path capture and cleaner reference PSD | Reference-minus-surveillance median reaches `>= 0 dB` minimum and ideally `>= +3 dB` target, with no exact rails and no new severe IQ/DC issue | Geometry or front-end loss still dominates the reference path | Keep the directional antenna and test filtering next |
| `RFM-04` | The reference path is being limited by out-of-band energy or local contamination rather than raw gain alone | Add a reference-path bandpass or preselector filter ahead of the SDR using the best `RFM-03` antenna configuration | Antenna, surveillance path, and gains from `RFM-03` | Short diagnostic capture plus one main dwell | Cleaner reference PSD or equal power with lower contamination risk | No more than `1 dB` loss in reference advantage while DC, spur, or IQ-related metrics improve or stay flat | Filter insertion loss hurts more than the cleanup helps | Remove the filter or add a pre-filter LNA test next |
| `RFM-05` | Cable loss or front-end noise is limiting the reference path after the antenna is fixed | Add or relocate a low-noise amplifier on the best directional reference path, preferably before long cable loss | Antenna, surveillance path, and filter state from the best prior row | Short diagnostic capture plus one main dwell | Stronger reference at the ADC without creating headroom problems | Reference advantage improves and near-rail fraction stays below `1.0e-4`, with no exact-rail samples | The LNA adds compression, instability, or little useful gain | Revert the LNA change and inspect cable loss or site geometry |
| `RFM-06` | After the antenna path is corrected, analog gain allocation may still be suboptimal | Use the best antenna and front-end path from earlier rows, then run a reference-gain sweep at current gain minus `12 dB`, minus `6 dB`, and current gain while keeping surveillance gain fixed | Surveillance gain and hardware path | Short diagnostic capture plus one main dwell per gain setting | A lower or equal manual gain may preserve the new reference advantage with more headroom | Best setting maximizes reference advantage without any clipping and without worsening DC/IQ metrics relative to the best prior row | If only the highest gain works, the reference path is still hardware- or geometry-limited | Keep the best safe gain and compare broadband antenna flexibility next |
| `RFM-07` | A broadband directional antenna may be good enough while preserving future illuminator flexibility | Replace the narrowband directional antenna with an LPDA or equivalent broadband directional candidate using the same best front-end chain | Surveillance path and best gain policy from earlier rows | Short diagnostic capture plus one main dwell | Reference performance remains competitive while bandwidth flexibility improves | Reference-minus-surveillance median stays within `3 dB` of the best narrowband row and no new impairments appear | Broadband flexibility costs too much direct-path quality for this site | Keep the narrowband directional antenna as the default reference choice |
| `RFM-08` | Surveillance-path rebalance should be considered only after the reference path is already optimized | Make only a small surveillance-path gain or attenuation trim after the best reference path is locked | Best reference-path hardware and pointing | Short diagnostic capture plus one main dwell | Better shared headroom without sacrificing the scene-facing role | Reference advantage stays positive and surveillance channel remains usable for later aircraft work | The only way to pass is to degrade surveillance | Treat the reference path or site geometry as still unresolved |

### Acceptance And Stop Rules

- Minimum Stage 2 improvement goal: move the reference-minus-surveillance median from the current approximately `-10 dB` range toward at least `>= 0 dB`.
- Target Stage 2 improvement goal: achieve a reference advantage of at least `+3 dB` under the current Stage 2 thresholding.
- Hard stop on a row if either channel shows exact-rail samples or near-rail fraction `>= 1.0e-4`.
- Treat `DC spike < 3 dB` and `IQ impropriety < 0.05` as the preferred diagnostic limits unless a justified threshold revision is approved separately.
- If the best directional reference configuration still cannot approach `>= 0 dB` without creating new impairments, classify the problem as geometry-limited or front-end-limited rather than forcing a role inversion.

### Interpreting The Outcome

- If `RFM-03` succeeds clearly, the broad reference dipole was the main limitation and the next default should be a dedicated directional reference antenna.
- If `RFM-03` helps only modestly but `RFM-04` or `RFM-05` helps strongly, the main limitation is front-end filtering, cable loss, or low-noise gain placement.
- If `RFM-03` through `RFM-06` all help only marginally, the site geometry, transmitter visibility, or channel mapping assumptions need to be rechecked before further hardware redesign.
- If `RFM-07` lands close to the best narrowband result, the LPDA becomes a defensible future-ready default; otherwise the narrowband directional antenna remains the recommended reference solution for the next session.

## Recommended Default For Future Sessions

For the next acquisition-pipeline revision, the strongest improvement would be:

1. Emit all machine-known facts automatically into the manifest and capture log.
2. Collect physical setup and site notes through a structured operator form at setup time.
3. Add a short preflight verification sequence for stream health, lock status, and channel mapping.
4. Run the RF test matrix in this document with the reference-path hardware isolated from surveillance-path changes.
5. Save those results inside the session folder so Stage 1 and Stage 2 do not depend on memory or source-code archaeology.

That combination would remove most of the manual backfill required for the current Stage 1 review and would make later G2 decisions much easier to defend.
