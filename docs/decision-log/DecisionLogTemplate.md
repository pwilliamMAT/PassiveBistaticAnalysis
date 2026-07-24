# Decision Log Template

Documentation scope only. This template records checkpoint decisions for later MATLAB implementation and review. It does not log live runs in this pass.

## Header

| Field | Value |
| :--- | :--- |
| Dataset ID | `<dataset_id>` |
| Gate ID | `<gate_id>` |
| Run timestamp | `<YYYYMMDDThhmmssZ>` |
| Author | `<name>` |
| Decision | `<pass | retune | reject>` |

## Requirement IDs Touched

- `<REQ-ID-1>`
- `<REQ-ID-2>`
- `<REQ-ID-3>`

## Parameter Baseline

| Parameter group | Value |
| :--- | :--- |
| Baseline profile name | `<baseline_name>` |
| CPI settings | `<value>` |
| Sync settings | `<value>` |
| Mitigation settings | `<value>` |
| Detection settings | `<value>` |
| Tracking settings | `<value>` |

## Thresholds Used

| Metric | Threshold | Observed value | Status |
| :--- | :--- | :--- | :--- |
| `<metric_name>` | `<threshold>` | `<observed>` | `<pass/fail>` |

## Evidence References

- `summary.md`
- `metrics.json`
- `metrics.mat`
- `decision.txt`
- `figures/<figure_name>.png`

## Next Branch

- Next gate: `<gate_id or hold state>`
- Next action: `<pass forward | retune current gate | reopen upstream>`

## Reopened Upstream Gates

- `<none>` or list the reopened gate IDs

## Notes

- `<freeform note>`
- `<freeform note>`

## Expert Note

This document is part of the broader council-derived plan and was informed primarily by requirements/V&V, MATLAB test architecture, and systems/customer-communication review inputs.
