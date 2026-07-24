# Evidence Bundle Specification

Documentation scope only. This specification defines the required structure and naming of checkpoint evidence bundles for later MATLAB implementation. It does not create artifacts in this pass.

## Bundle Root Convention

Each gate execution should write to a unique bundle root:

```text
artifacts/<datasetId>/<gateId>/<runTimestampZ>/
```

Example:

```text
artifacts/20260622T102123/G4_Passive_Baseline_Map/20260721T150000Z/
```

## Required Bundle Contents

| File or folder | Required content |
| :--- | :--- |
| `summary.md` | Human-readable summary of the run, scoped to the gate |
| `requirements_coverage.csv` | Requirement IDs covered, status, and evidence references |
| `config_snapshot.json` | Parameter baseline and environment summary used for the run |
| `metrics.json` | Machine-readable metrics table for the gate |
| `metrics.mat` | MATLAB-native metrics structure for later analysis |
| `decision.txt` | Final gate decision: `pass`, `retune`, or `reject` |
| `failure_cause.txt` | Required when the decision is not `pass` |
| `next_branch.txt` | Next action, next gate, or reopened upstream gate |
| `figures/` | Required plots or rendered tables as `.png` artifacts |
| `logs/` | Optional detailed runtime logs for internal use |

## Required Metadata Inside Every Bundle

- dataset ID
- gate ID
- run timestamp
- parameter baseline name
- requirement coverage
- metrics table
- decision
- failure cause when applicable
- next branch or reopened upstream gate

## Figure and Table Minimums by Gate

| Gate | Minimum required figures or tables |
| :--- | :--- |
| `G1` | Manifest-vs-observed table, seam continuity summary, decode contract summary |
| `G2` | RF health table, PSD figures, direct-path prominence summary |
| `G3` | Lag statistics, residual offset statistics, CPI sensitivity summary |
| `G4` | Baseline map figures, repeatability metrics, map-to-map correlation summary |
| `G5` | Before-and-after clutter summaries, protected-region energy summary |
| `G6` | Bin-spacing, integration-gain, peak-smearing, and outlier summaries |
| `G7` | Truth overlap tables, timing residual summary, validation-window definitions |
| `G8` | Detection table, false-alarm summary, hit-rate and persistence summary |
| `G9` | Continuity summary, fragmentation indicators, measurement-schema definition |
| `G10` | Track/truth metrics summary, assignment-history summary, milestone decision summary |

## Filename Conventions

- Markdown summaries use lowercase snake case such as `summary.md`.
- Scalar decision files use lowercase snake case such as `decision.txt`.
- Figures use a numbered prefix for stable ordering, for example `figure_01_baseline_map.png`.
- Multiple plots of the same family should use descriptive suffixes, for example `figure_02_psd_reference.png` and `figure_03_psd_surveillance.png`.

## Customer-Facing vs Internal V&V Artifacts

### Internal V&V Bundle

- includes all metrics, rejected branches, retune notes, and threshold history
- may include diagnostic plots that are too detailed for customer delivery
- is required for every `pass`, `retune`, and `reject` outcome

### Customer-Facing Bundle

- is generated only from passed gates and approved milestone states
- includes curated figures, summary metrics, and milestone language
- excludes exploratory tuning sweeps and intermediate rejected branches unless explicitly required for explanation

## Expert Note

This document is part of the broader council-derived plan and was informed primarily by requirements/V&V, MATLAB test architecture, signal processing/detection QE, and systems/customer-communication review inputs.
