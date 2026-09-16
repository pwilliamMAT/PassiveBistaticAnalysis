# G6-D Product-Discrimination Diagnostic Plan

Status: Active implementation contract, Phase 0 awaiting user review.

This plan is distinct from the preserved formal [G6 CPI / Integration Freeze Plan](G6Plan.md). G6-D is diagnostic and cannot change formal G6 or G8 state.

## Objective

Regenerate the preregistered 72-case campaign and compare detection behavior for `none`, `conservative_lms`, and `aggressive_lms` while each full G5 map exists. Determine whether one product robustly dominates, no mitigation dominates, the evidence crosses over, or the sweep is structurally blocked or detection-insufficient.

## Current Evidence Boundary

- The G5 campaign completed 72 cases and 648 maps with all integrity checks passing.
- Its classification is `mixed_requires_retune`; no product is selected.
- G5 map-level metrics do not establish whether mitigation helps or harms detection.
- Formal G6 freeze and formal G8 detection remain disabled.

Evidence: [stressResults.mat](artifacts/g5_adsb_stress_20260901T141707747/G5_Synthetic_Stress/20260901T154549472Z/stressResults.mat).

## Phase 0 — Context and Review Gate

- Establish and reconcile `NorthStar.md`, `PROJECT_STATE.md`, `DECISIONS.md`, `LessonsLearned.md`, `AGENTS.md`, and this active plan.
- Update `ProjectPlan.md` to identify it as the stable gate roadmap and point current status to `PROJECT_STATE.md`.
- Add a README entry linking the authoritative context set.
- Validate the saved G5 artifact directly and verify all context links and evidence paths.
- Stop for user review before MATLAB implementation.
- After approval, copy superseded README progress and lesson material to `archive/context/2026-09-02_readme-progress-history.md` before replacing duplicated README sections with links. Delete no history.
- Recommend, but do not automatically create, a documentation-only Git checkpoint.

## Study Boundary

G6-D:

- compares `none`, `conservative_lms`, and `aggressive_lms`;
- does not tune G5 or CFAR;
- does not select or freeze a formal detector product;
- does not emit `objectDetection` objects or start tracking; and
- makes campaign-conditional comparisons only.

## Native Function Audit

| Proposed workflow | Native MATLAB analogue | Use in G6-D |
| :--- | :--- | :--- |
| Two-dimensional cell-averaging CFAR | `phased.CFARDetector2D` | Obtain one CA noise estimate per map using the fixed guard/training geometry |
| Truth-blind local-maximum suppression | `imdilate` | Apply the fixed 7-by-3 Doppler/delay neighborhood before deterministic plateau resolution |
| One-to-one truth association | `matchpairs` | Associate detections to truth only after detection generation |
| Compact aggregation | `table`, `groupsummary`, `innerjoin`, `sortrows` | Build map, operating-point, truth-opportunity, summary, and paired-delta tables |
| Evidence persistence | `save`, `writetable`, `jsonencode`, figure export functions | Write one compact audited bundle without raw IQ or complete map collections |

Custom logic is limited to deterministic plateau tie resolution, normalized association costs and acceptance checks, recommendation policy, and integrity auditing around the native functions.

## MATLAB Interfaces

- Extend `helperAnalyzeG5Mitigation` with an optional second output containing the nine full map products for the current case. Preserve existing one-output behavior.
- Extend `helperAnalyzeG5MultiBackgroundStress` with an optional second output containing compact G6-D results. Process and clear full maps case by case.
- Add `helperAnalyzeG6ProductDiscrimination` for fixed CFAR, nonmaximum suppression, association, aggregation, integrity checks, and recommendation logic.
- Add `runG6ProductDiscriminationStudyLiveScript.m`.
- Add focused MATLAB tests.
- Do not alter the behavior or formal state emitted by `runG6CpiIntegrationFreeze` or `runG8Detection`.

## Fixed Detector Configuration

### Input and CUT

- Input is existing nonnegative `MapLinear` power.
- Rows are Doppler; columns are delay.
- Delay CUT region: `[-1.20e-3, -0.15e-3] s`.
- Doppler CUT region: `[-750, 750] Hz`.
- Expected CUT count: 12,832 per map.

### CA-CFAR

- Guard cells: `[3, 1]`.
- Training cells: `[12, 4]`.
- Training-cell count: 320.
- Nominal Pfa sweep: `[1e-2, 3e-3, 1e-3, 3e-4, 1e-4, 3e-5, 1e-5, 3e-6, 1e-6]`.
- Call `phased.CFARDetector2D` once per map to obtain the CA noise estimate.
- For each Pfa, compute `alpha = 320 * (Pfa^(-1/320) - 1)` and `threshold = alpha .* noiseEstimate`.

### Nonmaximum Suppression

- Apply truth-blind 7-by-3 `[Doppler, delay]` nonmaximum suppression using `imdilate`.
- Resolve plateaus deterministically by retaining the lowest row/column index.

### Association

- Generate all detections before consulting truth.
- Use `matchpairs` with normalized delay and Doppler errors.
- Use the existing uncertainty-aware truth-search half-extents.
- Reject a pair outside either half-extent.
- Count matched-control detections as nuisance/control alarms, not proven false alarms.

## Processing Sequence

1. Regenerate each preregistered campaign case through the existing producer and G5 analysis path.
2. Obtain the nine full G5 maps for that case through the new optional output.
3. Validate map nonnegativity, dimensions, axes, CUT membership, and fixed CFAR geometry.
4. Obtain one native CA noise estimate per map and evaluate all nine fixed Pfa thresholds.
5. Apply truth-blind nonmaximum suppression and deterministic plateau handling.
6. Associate detections to truth post hoc and record unmatched and matched-control outcomes with bounded terminology.
7. Append compact rows and clear full maps before the next case.
8. Aggregate product/background/Pfa summaries, paired product deltas, integrity results, and the diagnostic recommendation.

## Output Contract

Write one compact bundle under:

`artifacts/<campaignId>/G6_Product_Discrimination/<timestamp>/`

Required compact tables:

- map table: exactly 648 rows;
- map/Pfa operating-point table: exactly 5,832 rows;
- truth-opportunity table: exactly 7,047 rows;
- NMS detection table: variable row count;
- product/background summaries; and
- paired product deltas.

Retain configuration, provenance, recommendation, integrity results, compact tables, and a small set of summary figures. Retain no raw IQ or complete map collection.

Transient generated IQ may be removed only after results are saved, reloaded, and audited successfully.

## Recommendation Policy

- `blocked`: any structural, count, map, axis, CFAR, or association integrity failure.
- `insufficient`: valid execution but no matched truth detections anywhere in the complete sweep.
- `conservative`: `conservative_lms` is no worse in target hits and control-alarm count for every background/Pfa cell than both alternatives, and strictly better somewhere.
- `aggressive`: `aggressive_lms` satisfies the same robust-dominance rule.
- `none`: no mitigation robustly dominates and `none` dominates both alternatives, or all products are exactly tied with usable detections.
- `retune`: valid, informative evidence contains product/background or operating-point crossovers without a robust winner.

Every recommendation is diagnostic and cannot change formal G6 or G8 state.

## Verification and Acceptance

- Existing one-output G5 calls and G5 tests remain unchanged.
- CFAR thresholds increase as Pfa decreases; detection counts cannot increase.
- Tests cover CUT boundaries, NMS suppression and ties, one-to-one multi-target association, controls, malformed maps, and truth-blind detection invariance.
- The full campaign produces exactly 648 map rows, 5,832 operating-point rows, and 7,047 truth-opportunity rows.
- The compact-result audit confirms that no IQ or complete maps are retained.
- MATLAB Code Analyzer and relevant existing and new tests pass.
- Formal G6 freeze and G8 detection remain disabled.

## Supporting-Agent Contract After Phase 0 Approval

Assign Phase 1 to one supporting agent with write authority limited to:

- the optional-output seams in `helperAnalyzeG5Mitigation.m` and `helperAnalyzeG5MultiBackgroundStress.m`;
- the new G6-D helper and runner; and
- focused tests.

The supporting agent must not modify formal G6/G8 gate semantics or the external producer worktree. Before changing ADS-B truth handling, it must consult the pinned `matlab-import-tracking-data` skill and record that use in `sftt_skillUseSummary.md`.

The handoff must include changed files, verification commands and results, artifact path, recommendation, assumptions, unresolved issues, integration guidance, and proposed context updates. The coordinating agent reviews and integrates the result before changing project-level context.

## Out of Scope

- G5 or CFAR retuning.
- Formal G6 product freeze.
- Formal G7/G8 acceptance.
- `objectDetection` creation.
- Tracking or tracker evaluation.
- Field-performance, calibrated-RCS, or customer-facing claims.
