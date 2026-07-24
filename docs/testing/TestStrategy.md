# Test Strategy

Documentation scope only. This is a future testing architecture specification for later MATLAB implementation. It does not create `matlab.unittest` classes or executable tests in this pass.

## Testing Principles

- The testing stack follows the gate sequence in [ProjectPlan.md](../../ProjectPlan.md).
- Inner tuning loops are exploratory and produce evidence artifacts, but they are not default CI gates.
- Outer regression loops protect previously passed checkpoints when an upstream contract changes.
- Real-data checkpoints use the reference session `20260622T102123` first, then expand to additional sessions later.

## Test Pyramid

| Layer | Target share | Purpose |
| :--- | :--- | :--- |
| `Unit` | `60-70%` | Validate small contracts, transforms, schema rules, and config checks quickly |
| `Integration` | `20-30%` | Validate checkpoint behavior and cross-component contracts on controlled slices or real-data subsets |
| `Regression` | `10-15%` | Re-run full-session or evidence-completeness flows after approved changes |
| `Tuning` | Separate from CI gating | Explore thresholds, CPIs, mitigation variants, and sensitivity sweeps without changing the default pass/fail suite |

## Intended Suite Layout

```text
tests/
  shared/
    PassiveBistaticTestBase.m
    CheckpointTestBase.m
  unit/
    ingest/
    rfhealth/
    sync/
    mapping/
    mitigation/
    detection/
    tracking/
    validation/
  integration/
    G1/
    G2/
    G3/
    G4/
    G5/
    G6/
    G7/
    G8/
    G9/
    G10/
  regression/
    session/
    evidence/
  tuning/
    exploratory/
```

## Planned Base Classes

- `PassiveBistaticTestBase`
  - shared dataset discovery
  - reference-session metadata loading
  - evidence-folder management
  - common assertion helpers for units, timing, and schema contracts
- `CheckpointTestBase`
  - gate decision helpers
  - requirement-coverage helpers
  - standard evidence bundle assertions

## Planned Unit-Test Coverage

- manifest parsing
- raw IQ contract and embedded-header interpretation
- CPI segmentation rules
- delay and Doppler axis definitions
- truth time-conversion math
- config validation
- detection-record adapter behavior
- tracker initialization and measurement-schema validation

## Planned Integration-Test Coverage

- one integration suite per gate from `G1` through `G10`
- gate-to-gate contract checks, especially G1-to-G3, G4-to-G6, G6-to-G8, and G8-to-G10
- real-data slices for evidence generation and gate-decision logic

## Planned Regression-Test Coverage

- full-session detection regression
- full-session tracking regression
- evidence-pack completeness regression
- reopen-upstream regression whenever architecture or data-contract changes are approved

## Tags

- `Unit`
- `Integration`
- `Regression`
- `Slow`
- `RealData`
- `Tuning`
- checkpoint tags such as `G1`, `G4`, `G8`, `G10`
- release tags such as `ReleaseGate`, `Smoke`, and `EvidencePack`

## Fixtures

| Fixture | Purpose |
| :--- | :--- |
| Path fixture | Resolve repo-root and dataset-relative paths consistently |
| Working-folder fixture | Prevent tests from depending on caller location |
| Temporary evidence folder | Keep test-generated artifacts isolated |
| Manifest and session metadata fixture | Provide session facts without hard-coded duplication |
| Parameterized profiles | Provide baseline, conservative, aggressive, and diagnostic parameter sets |

## Standard Evidence Files Per Checkpoint

Every future checkpoint implementation should emit these standard files in addition to gate-specific plots or tables:

- `metrics.mat`
- `metrics.json`
- `decision.txt`
- `.png` figures

## CI-Gating Rule

Exploratory sweeps are `Tuning` artifacts and not default pass/fail CI gates. CI should only evaluate stable unit, integration, and regression suites that correspond to the currently approved gate baselines.

## Expert Note

This document is part of the broader council-derived plan and was informed primarily by MATLAB test architecture, requirements/V&V, signal processing/detection QE, and tracking metrics/V&V review inputs.
