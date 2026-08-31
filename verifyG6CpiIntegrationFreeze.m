function verification = verifyG6CpiIntegrationFreeze()
%VERIFYG6CPIINTEGRATIONFREEZE Synthetic smoke test for blocked G6 freeze.

options = struct();
options.SourceG4Metrics = struct();
options.SourceG4Metrics.overall_label = "blocked";
options.SourceG4Metrics.limitation_source_label = "dataset_scene_limited_with_raw_rate_audit_disagreement";
options.SourceG4Metrics.full_rate_audit_agreement_label = "disagreement";
options.SourceG4Metrics.scene_limited_map_fraction = 1.0;
options.SourceG4Metrics.recommended_baseline_cpi_label = "long";
options.SourceG4Metrics.map_rate_mode = "reduced_rate_main_product";
options.SourceG4Metrics.map_decimation_factor = 200.0;
options.SourceG4Metrics.map_sample_rate_hz = 30720.0;
options.SourceG5Metrics = struct();
options.SourceG5Metrics.gate_decision = "reject";
options.SourceG5Metrics.review_status = "manual_review_required";
options.SourceG5Metrics.decision_label = "blocked_by_g4";
options.SourceG5Metrics.formal_gate_decision_emitted = false;
options.SourceG5DiagnosticMetrics = struct();
options.SourceG5DiagnosticMetrics.default_gate_reveal_count = 0.0;
options.SourceG5DiagnosticMetrics.permissive_probe_reveal_count = 4.0;
options.SourceG5DiagnosticMetrics.best_causal_label = "visual_only_improvement";

analysis = helperAnalyzeG6CpiIntegrationFreeze("synthetic_g6_blocked", string(pwd), options);
localAssert(analysis.GateDecision == "reject", "G6 must reject normal freeze when upstream evidence is blocked.");
localAssert(analysis.ReviewStatus == "blocked_by_upstream", "G6 review status must identify upstream block.");
localAssert(analysis.FreezeStatus == "freeze_deferred", "G6 freeze status must be deferred.");
localAssert(~analysis.DetectorProductFreezeEnabled, "G6 must not enable detector product freeze.");
localAssert(height(analysis.UpstreamBlockTable) >= 5, "G6 must record blocking upstream evidence rows.");

verification = struct();
verification.Status = "passed";
verification.DatasetId = string(analysis.DatasetId);
verification.GateDecision = string(analysis.GateDecision);
verification.ReviewStatus = string(analysis.ReviewStatus);
verification.FreezeStatus = string(analysis.FreezeStatus);
verification.UpstreamBlockRows = height(analysis.UpstreamBlockTable);

fprintf("Running G6 freeze scaffold smoke verification\n");
fprintf("G6 smoke status:\t%s\n", verification.Status);
fprintf("Gate decision:\t%s\n", verification.GateDecision);
fprintf("Review status:\t%s\n", verification.ReviewStatus);
fprintf("Freeze status:\t%s\n", verification.FreezeStatus);
fprintf("Upstream block rows:\t%d\n", verification.UpstreamBlockRows);

end

function localAssert(condition, message)

if ~condition
    error("verifyG6CpiIntegrationFreeze:AssertionFailed", "%s", message);
end

end
