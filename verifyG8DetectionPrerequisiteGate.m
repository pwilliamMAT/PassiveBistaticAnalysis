function verification = verifyG8DetectionPrerequisiteGate()
%VERIFYG8DETECTIONPREREQUISITEGATE Synthetic smoke test for formal G8 refusal.

options = struct();
options.SourceG6Metrics = struct();
options.SourceG6Metrics.freeze_status = "freeze_deferred";
options.SourceG6Metrics.detector_product_freeze_enabled = false;
options.SourceG7Metrics = struct();
options.SourceG7Metrics.review_status = "truth_context_diagnostic_only";
options.SourceG7Metrics.truth_claims_enabled = false;
options.SourceG7Metrics.claim_block_reason = "g6_product_freeze_not_enabled_freeze_deferred";
analysis = helperAnalyzeG8DetectionPrerequisiteGate("synthetic_g8_blocked", string(pwd), options);
localAssert(analysis.GateDecision == "reject", "G8 must reject formal detection without prerequisites.");
localAssert(analysis.ReviewStatus == "blocked_missing_prerequisites", "G8 must report missing prerequisites.");
localAssert(analysis.ExecutionRefused, "G8 must refuse execution.");
localAssert(~analysis.CfarExecutionEnabled, "G8 must not enable CFAR.");
localAssert(~analysis.DetectorTuningEnabled, "G8 must not tune detector thresholds.");
localAssert(~analysis.DetectionTableEmitted, "G8 must not emit detection rows.");
localAssert(height(analysis.PrerequisiteBlockTable) >= 2, "G8 must record G6 and G7 prerequisite blocks.");

verification = struct();
verification.Status = "passed";
verification.DatasetId = string(analysis.DatasetId);
verification.GateDecision = string(analysis.GateDecision);
verification.ReviewStatus = string(analysis.ReviewStatus);
verification.ExecutionRefused = logical(analysis.ExecutionRefused);
verification.RefusalReason = string(analysis.RefusalReason);
verification.PrerequisiteBlockRows = height(analysis.PrerequisiteBlockTable);

fprintf("Running G8 prerequisite gate smoke verification\n");
fprintf("G8 smoke status:\t%s\n", verification.Status);
fprintf("Gate decision:\t%s\n", verification.GateDecision);
fprintf("Review status:\t%s\n", verification.ReviewStatus);
fprintf("Execution refused:\t%d\n", verification.ExecutionRefused);
fprintf("Refusal reason:\t%s\n", verification.RefusalReason);
fprintf("Prerequisite block rows:\t%d\n", verification.PrerequisiteBlockRows);

end

function localAssert(condition, message)

if ~condition
    error("verifyG8DetectionPrerequisiteGate:AssertionFailed", "%s", message);
end

end
