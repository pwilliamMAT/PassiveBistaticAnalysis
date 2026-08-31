function verification = verifyG7TruthContextDiagnostic()
%VERIFYG7TRUTHCONTEXTDIAGNOSTIC Smoke test current capture truth context.

options = struct();
options.SourceG6Metrics = struct();
options.SourceG6Metrics.freeze_status = "freeze_deferred";
options.SourceG6Metrics.detector_product_freeze_enabled = false;
analysis = helperAnalyzeG7TruthContextDiagnostic("20260622T102123", string(pwd), options);
localAssert(analysis.Mode == "truth_context_diagnostic", "G7 must run in truth_context_diagnostic mode.");
localAssert(~analysis.TruthClaimsEnabled, "G7 diagnostic must not enable truth claims without G6 freeze.");
localAssert(height(analysis.TruthImportSummaryTable) == 1, "G7 must emit one truth import summary row.");
localAssert(analysis.TruthImportSummaryTable.ValidTimeRowCount(1) > 0, "G7 must parse valid ADS-B timestamps.");
localAssert(height(analysis.RadarTimingAuditTable) == 15, "G7 must audit the 15 radar captures.");
localAssert(height(analysis.CaptureTruthOverlapTable) == 15, "G7 must emit capture-level overlap rows.");
localAssert(analysis.TimingResidualSummaryTable.RecordingDeltaMax_s(1) > 3.0, "G7 must preserve embedded timing deltas, not naive 1 s spacing.");

verification = struct();
verification.Status = "passed";
verification.DatasetId = string(analysis.DatasetId);
verification.Mode = string(analysis.Mode);
verification.GateDecision = string(analysis.GateDecision);
verification.ReviewStatus = string(analysis.ReviewStatus);
verification.TruthClaimsEnabled = logical(analysis.TruthClaimsEnabled);
verification.ClaimBlockReason = string(analysis.ClaimBlockReason);
verification.ValidTruthRows = analysis.TruthImportSummaryTable.ValidTimeRowCount(1);
verification.CaptureOverlapRows = height(analysis.CaptureTruthOverlapTable);

fprintf("Running G7 truth-context smoke verification\n");
fprintf("G7 smoke status:\t%s\n", verification.Status);
fprintf("Mode:\t%s\n", verification.Mode);
fprintf("Gate decision:\t%s\n", verification.GateDecision);
fprintf("Review status:\t%s\n", verification.ReviewStatus);
fprintf("Truth claims enabled:\t%d\n", verification.TruthClaimsEnabled);
fprintf("Claim block reason:\t%s\n", verification.ClaimBlockReason);
fprintf("Valid truth rows:\t%d\n", verification.ValidTruthRows);
fprintf("Capture overlap rows:\t%d\n", verification.CaptureOverlapRows);

end

function localAssert(condition, message)

if ~condition
    error("verifyG7TruthContextDiagnostic:AssertionFailed", "%s", message);
end

end
