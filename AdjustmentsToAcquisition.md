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

## Recommended Default For Future Sessions

For the next acquisition-pipeline revision, the strongest improvement would be:

1. Emit all machine-known facts automatically into the manifest and capture log.
2. Collect physical setup and site notes through a structured operator form at setup time.
3. Add a short preflight verification sequence for stream health, lock status, and channel mapping.
4. Save those results inside the session folder so Stage 1 does not depend on memory or source-code archaeology.

That combination would remove most of the manual backfill required for the current Stage 1 review and would make later G2 decisions much easier to defend.
