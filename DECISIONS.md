# Decisions

## D-001 — G5 Is Characterized but Not Selected

- Date: 2026-09-02
- Status: Accepted
- Decision: Treat the completed G5 campaign as characterization evidence only. No mitigation product is selected or formally approved.
- Rationale: The campaign is structurally valid but classified `mixed_requires_retune`, with `SelectedProduct = none_pending_retune` and `G5AnalysisReady = false`.
- Evidence: [G5 stress result](artifacts/g5_adsb_stress_20260901T141707747/G5_Synthetic_Stress/20260901T154549472Z/stressResults.mat).
- Reopen when: A complete, integrity-valid campaign provides product evidence under an approved decision policy.

## D-002 — Measure Detector Behavior Before Deciding Whether to Retune G5

- Date: 2026-09-02
- Status: Accepted
- Decision: Run the bounded G6-D product-discrimination diagnostic before deciding whether current G5 mitigation parameters should be retuned.
- Rationale: G5 map-level target and control metrics show background-dependent crossovers but do not establish whether mitigation helps or harms detection.
- Evidence: [G5 stress result](artifacts/g5_adsb_stress_20260901T141707747/G5_Synthetic_Stress/20260901T154549472Z/stressResults.mat) and [active diagnostic plan](G6ProductDiscriminationStudyPlan.md).
- Reopen when: G6-D is structurally blocked, produces no matched truth detections across the complete sweep, or reveals evidence that the fixed detector design cannot answer the discrimination question.

## D-003 — ADS-B Truth Remains Post-Hoc

- Date: 2026-09-02
- Status: Accepted
- Decision: ADS-B truth may define post-hoc evaluation and uncertainty-aware association, but it may not influence map generation, thresholding, nonmaximum suppression, or detection generation.
- Rationale: This preserves a truth-blind detector result and prevents target knowledge from leaking into the measurement process.
- Evidence: [G5 stress result](artifacts/g5_adsb_stress_20260901T141707747/G5_Synthetic_Stress/20260901T154549472Z/stressResults.mat) and [G5 campaign analyzer](helperAnalyzeG5MultiBackgroundStress.m).
- Reopen when: A formal validation design replaces ADS-B with another truth source or explicitly changes the truth-separation contract.

## D-004 — G6-D Cannot Enable Formal G6 or G8

- Date: 2026-09-02
- Status: Accepted
- Decision: G6-D is diagnostic. Its recommendation cannot freeze a formal detector product, enable formal CFAR tuning, emit validated detections, or open tracking.
- Rationale: The study compares detection behavior while retaining the existing upstream caveats; it does not satisfy the formal G6/G7/G8 gate contracts.
- Evidence: [active diagnostic plan](G6ProductDiscriminationStudyPlan.md), [formal G6 plan](G6Plan.md), [saved G6 refusal](artifacts/20260622T102123/G6_CPI_Integration_Freeze/20260807T124003Z/metrics.mat), and [saved G8 refusal](artifacts/20260622T102123/G8_Detection_Prerequisite_Gate/20260807T124005Z/metrics.mat).
- Reopen when: Formal G6 and G7 prerequisites are satisfied and a separate reviewed decision authorizes formal G8 execution.
