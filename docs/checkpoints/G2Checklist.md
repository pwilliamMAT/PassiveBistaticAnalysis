# G2 Checklist

This checklist tracks only `G2_RF_Health`. Each customer-flow stage is treated as a separate collaborative implementation phase. Code for a stage should not be treated as approved until the manual review is complete and comments are recorded here.

## Scope Guardrails

- Active scope: `G2_RF_Health`
- Explicitly out of scope: `G1`, `G3`, and later phases
- Frozen upstream input: `loadIQData` output for dataset `20260622T102123` when making single-session G2 status calls
- Working mode: implement one stage, run manual checks, discuss outputs, then open the next stage only after approval
- Hardware iteration across later sessions uses the artifact-only `runG1G2SessionComparison` workflow and does not change this checklist status unless the result is manually reviewed and recorded here
- Stage 2 development readiness is tracked separately from formal approval. A dataset-limited Stage 2 result can leave development unblocked under caveat without opening Stage 3 in this checklist.

## Stage Status

| Stage | Flowchart Section | Status | Manual Check | Notes |
| :--- | :--- | :--- | :--- | :--- |
| 1 | Acquisition Evidence | `approved_ready_for_stage_2` | `complete` | Stage 1 accepted for progression on the single-session baseline `20260622T102123` based on current automatic evidence plus operator-provided session metadata. Future acquisition-path improvements are captured in `AdjustmentsToAcquisition.md`. |
| 2 | Receiver Integrity | `approved_ready_for_stage_3` | `complete` | Stage 2 manual review is complete for the single-session baseline `20260622T102123`. The RF outcome remains caveated and diagnostic, but the status is approved for progression to Stage 3 review. |
| 3 | Illuminator and Interference | `not_started` | `not_started` | Open for Stage 3 scope review now that Stage 2 manual review is complete. |
| 4 | Coherent Usability | `not_started` | `not_started` | Hold until Stage 3 is manually reviewed and approved. |
| 5 | Session Classification and Decision | `not_started` | `not_started` | Hold until Stages 1 through 4 are manually reviewed and approved. |

## Stage 1 - Acquisition Evidence

- Status: `approved_ready_for_stage_2`
- Primary code:
  - `runG2Stage1AcquisitionEvidence.m`
  - `helperAnalyzeG2AcquisitionEvidence.m`
  - `helperParseG2CaptureLog.m`
  - `helperReadCollectionMetadata.m`
- Supporting source file:
  - `20260622T102123/collection_metadata.json`
- Manual check items:
  - [x] Review the metadata presence audit against the manifest and capture log.
  - [x] Review the manual `collection_metadata.json` content and confirm the antenna-role mapping and site notes are correct.
  - [x] Review the receiver-state table for recovered hardware-configuration evidence.
  - [x] Review the channel-role and mapping evidence for whether the current inference is acceptable.
  - [x] Decide whether the Stage 1 verdict wording or thresholds need adjustment.
- Comments:
  - `2026-07-22`: Stage 1 accepted for progression to Stage 2 using the current automatic acquisition evidence plus manual operator-provided metadata.
  - `2026-07-22`: Missing lock, overrun, and explicit channel-verification evidence are treated as acquisition-pipeline follow-up rather than a blocker for moving into Stage 2.
  - `2026-07-22`: External acquisition-pipeline improvements to reduce manual backfill are recorded in `AdjustmentsToAcquisition.md`.
  - `2026-07-24`: `20260622T102123` remains the single-session Stage 1 baseline. Later hardware sessions should be compared with `runG1G2SessionComparison` first rather than replacing this checklist status directly.

## Stage 2 - Receiver Integrity

- Status: `approved_ready_for_stage_3`
- Primary code:
  - `runG2Stage2ReceiverIntegrity.m`
  - `helperAnalyzeG2ReceiverIntegrity.m`
- Supporting source file:
  - `20260622T102123/collection_metadata.json`
- Manual check items:
  - [x] Review the accepted role mapping and confirm Stage 2 should use `RF1:RX2` as reference and `RF0:RX2` as surveillance for this session.
  - [x] Review the receiver-integrity table and confirm the reference-minus-surveillance power ordering is interpreted correctly.
  - [x] Review clipping, DC, and IQ/image metrics and confirm the current thresholds are reasonable for this dataset.
  - [x] Review the Stage 2 legal recommendation, dataset-classification wording, and the separate development-readiness wording.
  - [x] Decide whether the baseline Stage 2 result should remain `retune` and `diagnostic`, and whether the development status should remain `unblocked_with_dataset_caveat` until Stage 2 is formally approved.
- Comments:
  - `2026-07-22`: Stage 2 implementation completed with standalone artifacts under `artifacts/20260622T102123/G2_RF_Health_Stage2_ReceiverIntegrity/`.
  - `2026-07-22`: Latest Stage 2 bundle is `artifacts/20260622T102123/G2_RF_Health_Stage2_ReceiverIntegrity/20260722T200041Z/`.
  - `2026-07-22`: Current Stage 2 result is `receiver_integrity_caveated` with legal recommendation `retune` and dataset classification recommendation `diagnostic`.
  - `2026-07-22`: Main caveat is role-based power ordering: the accepted reference channel is about `9.7 dB` to `10.2 dB` weaker than surveillance in all repetitions, while clipping, DC, and IQ/image proxies remain low.
  - `2026-07-24`: `20260622T102123` remains the single-session Stage 2 approval baseline unless a later manual review records a different decision here.
  - `2026-07-24`: Hardware comparison against `20260713T150404` and later sessions should be reviewed through the artifact-only comparison workflow. Those comparisons are advisory until explicitly reflected in this checklist.
  - `2026-07-24`: The baseline Stage 2 bundle now reports `AnalysisValidity = valid` and `DevelopmentReadiness = unblocked_with_dataset_caveat` to distinguish a dataset-limited result from a broken Stage 2 analysis path.
  - `2026-07-24`: This dual-status wording does not open Stage 3 formally. Stage 3 remains blocked in the checklist until Stage 2 is manually reviewed and approved.
  - `2026-07-27`: Manual Stage 2 review completed for the single-session baseline `20260622T102123` using bundle `artifacts/20260622T102123/G2_RF_Health_Stage2_ReceiverIntegrity/20260724T184355Z/`.
  - `2026-07-27`: Confirmed Stage 2 should use `RF1:RX2` as `reference` and `RF0:RX2` as `surveillance` for this session, based on the accepted Stage 1 manual mapping and current collection metadata.
  - `2026-07-27`: Confirmed the reference-minus-surveillance power ordering is interpreted correctly under that accepted mapping. The current result remains that the accepted reference channel is weaker than surveillance across all repetitions.
  - `2026-07-27`: Confirmed the current clipping, DC, and IQ/image thresholds are reasonable for this dataset and remain acceptable for Stage 2 review at this time.
  - `2026-07-27`: Confirmed the current Stage 2 wording is acceptable: legal recommendation `retune`, dataset classification recommendation `diagnostic`, `AnalysisValidity = valid`, and `DevelopmentReadiness = unblocked_with_dataset_caveat`.
  - `2026-07-27`: Approved the baseline Stage 2 result as defendable for this session. Formal Stage 2 manual review is complete for progression to Stage 3 review, while retaining the Stage 2 RF outcome `receiver_integrity_caveated` and the dataset-limited caveat captured in the saved bundle.

## Stage 3 - Illuminator and Interference

- Status: `not_started`
- Manual check items:
  - [ ] Review Stage 3 scope before implementation.
- Comments:
  - `2026-07-27`: Stage 2 manual review is complete, so Stage 3 scope review may now proceed.
  - Development-only continuation under Stage 2 caveat is separate from formal Stage 3 approval.

## Stage 4 - Coherent Usability

- Status: `not_started`
- Manual check items:
  - [ ] Review Stage 4 scope before implementation.
- Comments:
  - `TBD`

## Stage 5 - Session Classification and Decision

- Status: `not_started`
- Manual check items:
  - [ ] Review Stage 5 scope before implementation.
- Comments:
  - `TBD`
