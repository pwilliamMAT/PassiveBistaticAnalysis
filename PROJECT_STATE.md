# Project State

Updated: 2026-09-02

## Project Objective

[Build a trustworthy passive-bistatic capability that can detect and track aircraft in field data, while making clear what the evidence does and does not support.](NorthStar.md)

## Active Milestone

`G6-D Product-Discrimination Diagnostic`, governed by [G6ProductDiscriminationStudyPlan.md](G6ProductDiscriminationStudyPlan.md).

Current stage: Phase 0 context checkpoint awaiting user review. Phase 1 MATLAB implementation is not yet authorized.

## Definition of Done

- The preregistered 72-case campaign is regenerated without changing G5 or CFAR tuning.
- Exactly 648 maps, 5,832 map/Pfa operating points, and 7,047 truth opportunities are evaluated.
- Detection generation is truth-blind; truth is used only for post-hoc one-to-one association.
- The compact evidence bundle passes structural, count, map, axis, CFAR, association, and retention audits.
- The diagnostic recommendation is one of `blocked`, `insufficient`, `conservative`, `aggressive`, `none`, or `retune`.
- Existing one-output G5 behavior and tests remain unchanged.
- Formal G6 freeze and formal G8 detection remain disabled.

## Verified Current State

- Saved G5 evidence: [stressResults.mat](artifacts/g5_adsb_stress_20260901T141707747/G5_Synthetic_Stress/20260901T154549472Z/stressResults.mat).
- Campaign ID: `g5_adsb_stress_20260901T141707747`.
- Observed campaign size: 72 cases across 3 backgrounds and 648 range-Doppler maps.
- Integrity: inputs, counts, map axes, pairings, control-derived correction reuse, compact-result storage, and post-hoc truth use all passed.
- Compact-result audit: no raw IQ and no complete map collection are retained.
- G5 classification: `mixed_requires_retune`.
- Product state: `SelectedProduct = none_pending_retune`; no product is selected or formally approved.
- Readiness state: `G5AnalysisReady = false`, `G6Readiness = not_ready_mitigation_retune_required`, and `FormalG6FreezeEnabled = false`.
- Formal G8 remains a prerequisite-refusal scaffold with `CfarExecutionEnabled = false`, `DetectorTuningEnabled = false`, and no detection table emitted; evidence: [G8 metrics](artifacts/20260622T102123/G8_Detection_Prerequisite_Gate/20260807T124005Z/metrics.mat).

## Active Work and Ownership

| Work | Owner | Status | Integration point |
| :--- | :--- | :--- | :--- |
| Phase 0 context checkpoint and evidence reconciliation | Coordinating agent | Ready for user review | User approval of the populated context set |
| Phase 1 G6-D implementation | Supporting agent, not yet assigned | Blocked by Phase 0 review | Coordinating-agent review before project-state updates |

## Current Blocker

User review of the Phase 0 context checkpoint is required before MATLAB implementation, README history replacement, or supporting-agent assignment.

## Deferred Work

- Decide whether G5 should be retuned until G6-D measures detection-level benefit or harm.
- Formal G6 CPI/integration freeze under [G6Plan.md](G6Plan.md).
- Formal G7 product-level truth windows and G8 detector validation.
- `objectDetection` emission, tracker readiness, tracking, and customer-facing performance claims.
- README progress/lesson deduplication and archival, pending the preservation gate.

## Next Action

Review [NorthStar.md](NorthStar.md), this state file, [DECISIONS.md](DECISIONS.md), [LessonsLearned.md](LessonsLearned.md), and [G6ProductDiscriminationStudyPlan.md](G6ProductDiscriminationStudyPlan.md). After approval, preserve superseded README history under `archive/context/` and then begin the bounded Phase 1 implementation.
