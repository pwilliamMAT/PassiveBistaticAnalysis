# Suggestions from G1 Experience

  # G2 Session Efficiency Playbook

  ## Summary

  Use the G1 experience to make the next G2 session more deterministic: reduce ambiguity up front, separate stable APIs from gate-test runners, and predeclare the exact G2 evidence/decision rules before implementation starts. The main lesson from G1 is that most delay came from hidden policy
  questions surfacing mid-session: inventory scope, timing interpretation, dev/test-vs-customer script roles, and which checks truly belong to the active gate.

  ## Key Changes to How We Run G2

  ### 1. Start G2 with a short “gate contract packet”

  Before the next agentic session, prepare a compact G2 kickoff packet in the prompt or in a small markdown note. It should explicitly state:

  - active gate: G2_RF_Health only
  - approved inputs: loadIQData output and session 20260622T102123
  - stable upstream contracts inherited from G1:
      - one file = one repetition
      - [N x 2] complex int16
      - channel order RF0:RX2, RF1:RX2
      - intra-file CPI only by default
  - what belongs to G2 vs not G2:
      - G2 owns RF/data-quality screening and dataset classification
      - G2 does not reopen G1 unless an RF-health result proves an ingest-contract defect
  - preferred deliverables:
      - helper-level RF-health API
      - runG2RFHealth gate-validation runner
      - pipeline placeholder replacement in the development/test live script

  This should be treated as the authoritative session brief, not implied from scattered docs.

  ### 2. Tighten G2 requirements before coding

  For G2 specifically, pre-answer these requirement questions before the implementation session starts:

  - what numeric thresholds are provisional defaults for:
      - clipping fraction
      - DC offset magnitude
      - PAR
      - spur occupancy
      - direct-path prominence
  - whether G2 pass allows both golden and diagnostic, or only golden
  - whether a diagnostic outcome is a pass with caveats or a retune
  - whether RF-health checks are evaluated:
      - per repetition only
      - aggregated across all repetitions
      - both, with which one controls the decision
  - whether PSD/direct-path figures should be generated for:
      - the first repetition only
      - all repetitions
      - summary-selected worst/best examples

  If these are not locked, the next session will spend time negotiating policy instead of implementing G2.

  ### 3. Use a fixed prompting format for gate sessions

  For the next G2 session, use a prompt with these sections in this order:

  1. Gate in scope
  2. Read first
  3. Must preserve from previous gate
  4. Native Function Audit rule
  5. Required outputs
  6. Decision criteria
  7. Known policy decisions already approved
  8. Questions you should ask only if still ambiguous after reading docs/code

  This will reduce back-and-forth and keep the agent from rediscovering settled decisions.

  A good G2 session prompt should also explicitly say:

  - whether doc updates are expected in the same turn
  - whether the development/test pipeline script should be updated now
  - whether a customer-facing script is out of scope for this gate

  ### 4. Separate three artifact layers from the start

  Continue enforcing the separation that became clear in G1:

  - stable helper APIs:
      - reusable analysis/load functions used by later gates
  - gate-validation runners:
      - runG2RFHealth-style scripts that decide pass/retune/reject and emit evidence
  - development/test orchestration:
      - runPassiveBistaticPipeline

  For G2, require the implementation to name and describe all three layers before code is written. This avoids accidentally building the customer-facing workflow out of test runners.

  ### 5. Predeclare the G2 evidence bundle shape

  The G2 checkpoint and evidence spec already say the minimum evidence is:

  - RF health table
  - PSD figures
  - direct-path prominence summary
  - dataset classification note

  For efficiency, predeclare the exact filenames and summary metrics before implementation:

  - dataset_classification_note.md
  - figure_01_rf_health_table.png
  - figure_02_psd_reference.png
  - figure_03_psd_surveillance.png

  Also predeclare the minimum metrics table fields, for example:

  - repetition index
  - RMS power per channel
  - PAR per channel
  - clipped fraction per channel
  - DC offset magnitude per channel
  - direct-path prominence metric
  - provisional per-repetition health label

  This prevents bundle structure redesign during implementation.

  ## Test Plan for the Next Session

  - Before coding G2, inspect the current G1 bundle and confirm the G2 implementation will consume its frozen contracts rather than re-deriving them.
  - Before coding G2, confirm threshold/default decisions are explicitly present in the session prompt or checkpoint note.
  - During G2 implementation, verify:
      - helper API can run independently from the gate runner
      - gate runner writes a full G2 evidence bundle
      - development/test pipeline runs G1 then G2 and stops at G3
  - After G2 implementation, verify both:
      - normal native-reader ingest path inherited from G1
      - forced G1 fallback path still allows G2 to run from loadIQData outputs

  ## Assumptions and Recommended Defaults

  - Treat G1 outputs as frozen unless a G2 result proves an upstream contract problem.
  - Keep using loadIQData as the upstream ingest dependency for G2.
  - Continue using runPassiveBistaticPipeline as a development/test live script only.
  - Recommended default: define diagnostic as a G2 pass with explicit caveats unless you want G2 to block downstream work more aggressively.
  - Recommended default: compute RF-health metrics per repetition and also emit aggregate summary ranges, with pass/fail driven by both worst-case repetition behavior and overall trend.
  - Recommended default: include a short “Known approved decisions from G1” block in every future gate-session prompt so the agent does not reopen settled policy.