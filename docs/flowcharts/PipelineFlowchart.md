# Pipeline Flowchart

Documentation scope only. This Mermaid source defines the approved planning flow for later implementation and does not create executable pipeline logic in this pass.

Expert roles: passive bistatic radar algorithm expert, RF/data-quality expert, signal processing and detection QE expert, requirements and V&V expert, MATLAB test architecture expert, tracking metrics/V&V expert, and systems/customer-communication review inputs.

## PowerPoint Generation

- Source of truth: this Markdown file
- Generator: `generatePipelineFlowchartPpt.m`
- Output artifact: `artifacts/ppt/PipelineFlowchart.pptx`
- Platform note: the generator uses MATLAB with Microsoft PowerPoint COM automation on Windows so the slide remains editable

## Preview-Safe Diagram

```mermaid
flowchart TB
  classDef gate fill:#eef5ff,stroke:#1f4e79,stroke-width:1px,color:#111827;
  classDef lane fill:#f3f4f6,stroke:#64748b,stroke-width:1px,color:#111827;
  classDef outcome fill:#fff4e6,stroke:#c47f00,stroke-width:1px,color:#111827;
  classDef reject fill:#fdecec,stroke:#b42318,stroke-width:1px,color:#111827;
  classDef support fill:#e8f5e9,stroke:#2f6b2f,stroke-width:1px,color:#111827;
  linkStyle default stroke:#cbd5e1,stroke-width:2px;

  G1["G1 Ingest"]
  G2["G2 RF Health"]
  G3["G3 Sync"]
  G4["G4 Passive Baseline Map"]
  G5["G5 Mitigation"]
  G6["G6 CPI / Integration Freeze"]
  G7["G7 Truth Alignment"]
  G8["G8 Detection"]
  G9["G9 Tracker Readiness"]
  G10["G10 Tracking / Truth Validation"]

  IVV["Internal V&V Lane"]
  CUST["Customer Evidence Lane"]

  RJ["Outcome: capture rejected"]
  DIAG["Outcome: diagnostic only"]
  M4["Milestone: validated passive baseline"]
  M8["Milestone: validated detection"]
  MT["Milestone: track-level success"]
  MC["Milestone: truth-correlated success"]
  RU["Reopen earliest affected upstream gate"]

  G1 -->|pass| G2
  G1 -->|retune| G1
  G1 -->|reject| RJ

  G2 -->|pass| G3
  G2 -->|retune| G2
  G2 -->|reject| RJ

  G3 -->|pass| G4
  G3 -->|retune| G3
  G3 -->|reject| RJ

  G4 -->|pass| G5
  G4 -->|retune| G4
  G4 -->|reopen upstream| RU
  G4 -.->|milestone| M4

  G5 -->|pass| G6
  G5 -->|retune| G5
  G5 -->|retain baseline| G6

  G6 -->|pass| G7
  G6 -->|retune| G6
  G6 -->|reopen upstream| RU

  G7 -->|pass| G8
  G7 -->|retune| G7
  G7 -->|truth blocked| DIAG

  G8 -->|pass| G9
  G8 -->|retune detector only| G8
  G8 -->|reopen upstream| RU
  G8 -.->|first success| M8

  G9 -->|pass| G10
  G9 -->|retune contract| G9
  G9 -->|hold at detection| M8

  G10 -->|retune tracker only| G10
  G10 -->|track-level pass| MT
  G10 -->|truth-correlated pass| MC
  G10 -->|reopen upstream| RU

  RU --> G1
  RU --> G3
  RU --> G4
  RU --> G6
  RU --> G7
  RU --> G8
  RU --> G9

  G1 -. evidence .-> IVV
  G4 -. evidence .-> IVV
  G8 -. evidence .-> IVV
  G10 -. evidence .-> IVV
  IVV --> CUST

  class G1,G2,G3,G4,G5,G6,G7,G8,G9,G10 gate;
  class IVV,CUST lane;
  class DIAG,M4,M8,MT,MC outcome;
  class RJ reject;
  class RU support;
```

## Gate Summary

| Gate | Purpose | Key MATLAB method | Acceptance metric family | Evidence artifact |
| :--- | :--- | :--- | :--- | :--- |
| `G1 Ingest` | Manifest, decode, timing, and CPI contract | `jsondecode`, native baseband reader or `fread` fallback | Inventory reconciliation, seam continuity, decode consistency | Manifest table, seam summary, decode note |
| `G2 RF Health` | Channel quality and dataset classification | `pwelch` plus signal-quality metrics | RMS, PAR, clipping, DC, IQ imbalance, direct-path prominence | RF table, PSD plots, classification note |
| `G3 Sync` | Lag and residual frequency model | Correlation and coherence analysis | Lag stability, residual offset stability, CPI sensitivity | Lag stats, offset stats, sensitivity summary |
| `G4 Passive Baseline Map` | Trusted passive-map oracle | `ambgfun` | Axis plausibility, direct-path plausibility, repeatability | Baseline maps, repeatability summary |
| `G5 Mitigation` | Compare no mitigation and LMS baselines | `dsp.LMSFilter` candidate | Clutter suppression, protected-energy retention, downstream detectability | Before/after clutter metrics |
| `G6 CPI / Integration Freeze` | Freeze detector input product | CPI and integration comparisons | Integration gain, peak smearing, repeatability | Frozen config record, gain summary |
| `G7 Truth Alignment` | Radar-to-truth timing contract | Manifest and embedded-header time conversion | Overlap quality, timing residuals, validation-window quality | Overlap tables, timing residuals |
| `G8 Detection` | Validated CFAR on frozen products | `phased.CFARDetector2D` | False-alarm density, hit rate, persistence | Detection table, false-alarm summary |
| `G9 Tracker Readiness` | Decide if detections can feed `trackerGNN` | Measurement-schema validation | Continuity, fragmentation risk, schema completeness | Continuity summary, schema note |
| `G10 Tracking / Truth Validation` | Batch track-to-truth evaluation | `trackerGNN`, `trackAssignmentMetrics`, `trackErrorMetrics` | Assignment quality, continuity, coast, initiation delay, error | Track metrics, assignment history, milestone note |

## Decision Logic

- `pass`: move to the next gate.
- `retune`: stay inside the current gate's parameter space.
- `reject`: stop at `capture rejected`.
- `reopen upstream`: reopen the earliest affected upstream gate when a contract changes.
- `truth blocked`: remain `diagnostic only`.
- `first success`: `validated detection` is the first success milestone that unlocks tracking work.
