# G6-G8 Downstream Status

Updated: 2026-08-07

## Current Dataset Interpretation

Dataset `20260622T102123` is diagnostic/negative-control evidence only.

- G4 is blocked: scene-limited/direct-path-dominated maps plus raw/reduced-rate disagreement.
- G5 is diagnostic-only: conservative LMS suppresses direct-path/reference-correlated content by about `4.2 dB`, default scene-reveal count is `0`, permissive-probe reveal count is `4`, and best causal label remains `visual_only_improvement`.
- G6-G8 must fail safely on this dataset and must not claim validated detection, truth-correlated success, or tracking readiness.

## Gate Status Table

| Gate | Files changed | Behavior implemented | Public contract changes | Verification run | Known blocked items | Next recommended action |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| G6 | `helperAnalyzeG6CpiIntegrationFreeze.m`, `runG6CpiIntegrationFreeze.m`, `verifyG6CpiIntegrationFreeze.m`, `G6Plan.md` | Consumes latest complete G4/G5/G5-diagnostic bundles and writes a blocked/deferred freeze evidence bundle. | Adds `FreezeStatus`, `DetectorProductFreezeEnabled`, `NormalFreezeRefused`, and explicit not-frozen product record. | `verifyG6CpiIntegrationFreeze`; `runG6CpiIntegrationFreeze` on `20260622T102123`; Code Analyzer clean. | Normal detector-product freeze blocked by G4/G5 evidence. | Acquire or identify evidence where G4 is ready and G5 emits a formal selectable mitigation posture. |
| G7 | `helperAnalyzeG7TruthContextDiagnostic.m`, `runG7TruthContextDiagnostic.m`, `verifyG7TruthContextDiagnostic.m`, `G7Plan.md` | Parses ADS-B truth, audits manifest vs embedded radar timing, and writes capture-level truth-overlap context. | Adds `truth_context_diagnostic` mode; keeps `TruthClaimsEnabled = false` without a frozen G6 product. | `verifyG7TruthContextDiagnostic`; `runG7TruthContextDiagnostic` on `20260622T102123`; Code Analyzer clean. | CPI/product-level truth claims blocked because G6 product freeze is not enabled. | After a future G6 freeze, extend G7 from capture-level context to product/CPI truth windows. |
| G8 | `helperAnalyzeG8DetectionPrerequisiteGate.m`, `runG8Detection.m`, `verifyG8DetectionPrerequisiteGate.m`, `docs/checkpoints/G8_Detection.md` | Refuses formal detection execution when G6/G7 prerequisites are missing; emits schema scaffold only. | Adds formal prerequisite refusal contract; CFAR execution and detector tuning remain disabled. | `verifyG8DetectionPrerequisiteGate`; `runG8Detection` on `20260622T102123`; Code Analyzer clean. | G6 frozen product missing and G7 truth claims disabled. | Keep G8 formal detection blocked until G6 freeze and G7 truth windows exist. |

## MATLAB Commands Run

```matlab
verifyG6CpiIntegrationFreeze;
verifyG7TruthContextDiagnostic;
verifyG8DetectionPrerequisiteGate;

g6Results = runG6CpiIntegrationFreeze;
g7Results = runG7TruthContextDiagnostic;
g8Results = runG8Detection;
```

Code Analyzer was run on every new MATLAB file:

- `helperAnalyzeG6CpiIntegrationFreeze.m`
- `runG6CpiIntegrationFreeze.m`
- `verifyG6CpiIntegrationFreeze.m`
- `helperAnalyzeG7TruthContextDiagnostic.m`
- `runG7TruthContextDiagnostic.m`
- `verifyG7TruthContextDiagnostic.m`
- `helperAnalyzeG8DetectionPrerequisiteGate.m`
- `runG8Detection.m`
- `verifyG8DetectionPrerequisiteGate.m`

## Artifact Bundles Created

- G6: `artifacts/20260622T102123/G6_CPI_Integration_Freeze/20260807T124003Z`
- G7: `artifacts/20260622T102123/G7_Truth_Context_Diagnostic/20260807T124004Z`
- G8: `artifacts/20260622T102123/G8_Detection_Prerequisite_Gate/20260807T124005Z`

## Code Analyzer Results

All nine new MATLAB files returned no Code Analyzer issues.

## Tests Passed, Failed, Or Not Run

- Passed: `verifyG6CpiIntegrationFreeze`
- Passed: `verifyG7TruthContextDiagnostic`
- Passed: `verifyG8DetectionPrerequisiteGate`
- Passed: G6/G7/G8 runner smoke execution on `20260622T102123`
- Not run: formal `matlab.unittest` suite, because no MATLAB unit-test class/script exists for these scaffolds yet.
- Not run: formal G8 detector validation, because prerequisites are intentionally missing and detector execution is disabled.

## Files Intentionally Not Touched

- G1-G5 runner files and helper semantics.
- `runPassiveBistaticPiplineLiveScript.m`.
- Shared timing/performance helper files.
- G4/G5 artifact bundles, except as read-only inputs.
- Detector CFAR implementation files, because no formal detector implementation was added.

## Open Decisions For Next Agent

- What dataset or controlled fixture should be used to produce a non-diagnostic G4/G5 evidence chain.
- Whether G6 should eventually freeze no-mitigation or a G5-selected mitigation product once G4/G5 are formally ready.
- The product/CPI truth-window tolerance policy for G7 after G6 freeze exists.
- The formal G8 detector threshold policy and false-alarm region definition, to be decided only after G6/G7 prerequisites exist.