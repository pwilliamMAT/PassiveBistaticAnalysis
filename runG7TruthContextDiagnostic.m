function results = runG7TruthContextDiagnostic(datasetId, repoRoot, options)
%RUNG7TRUTHCONTEXTDIAGNOSTIC Run capture-level G7 truth diagnostics.

arguments
    datasetId (1,1) string = "20260622T102123"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

stageArtifactId = "G7_Truth_Context_Diagnostic";
stageTimer = tic;
datasetId = string(datasetId);
repoRoot = helperResolveRepoRoot(repoRoot);
runTimestampZ = string(datetime("now", "TimeZone", "UTC", "Format", "yyyyMMdd'T'HHmmss'Z'"));
bundleRoot = fullfile(repoRoot, "artifacts", datasetId, stageArtifactId, runTimestampZ);
figureRoot = fullfile(bundleRoot, "figures");
runnerOptions = options;
runnerOptions.TruthWorkingRoot = bundleRoot;

fprintf("Running G7 truth-context diagnostic for dataset %s\n", datasetId);
fprintf("Repository root:\t%s\n", repoRoot);

try
    localEnsureFolder(bundleRoot);
    localEnsureFolder(figureRoot);
    analysis = helperAnalyzeG7TruthContextDiagnostic(datasetId, repoRoot, runnerOptions);
    localWriteArtifacts(bundleRoot, figureRoot, analysis, options);
    elapsed_s = toc(stageTimer);
    timingSummaryTable = localBuildTimingSummaryTable(analysis, elapsed_s, bundleRoot);
    performanceSummary = localBuildPerformanceSummary(analysis, elapsed_s, bundleRoot);
    writetable(timingSummaryTable, fullfile(bundleRoot, "timing_summary.csv"));
    localWriteJsonFile(fullfile(bundleRoot, "performance_summary.json"), performanceSummary);
    save(fullfile(bundleRoot, "metrics.mat"), "analysis", "timingSummaryTable", "performanceSummary");
    results = localBuildResults(datasetId, stageArtifactId, runTimestampZ, bundleRoot, analysis, timingSummaryTable, performanceSummary);
    localPrintRunSummary(results, analysis);
catch mainException
    localWriteFailureBundle(bundleRoot, mainException);
    rethrow(mainException);
end

end

function localWriteArtifacts(bundleRoot, figureRoot, analysis, options)

try
    writetable(analysis.TruthImportSummaryTable, fullfile(bundleRoot, "truth_import_summary_table.csv"));
    writetable(analysis.RadarTimingAuditTable, fullfile(bundleRoot, "radar_timing_audit_table.csv"));
    writetable(analysis.CaptureTruthOverlapTable, fullfile(bundleRoot, "capture_truth_overlap_table.csv"));
    writetable(analysis.TimingResidualSummaryTable, fullfile(bundleRoot, "timing_residual_summary_table.csv"));
    writetable(analysis.ClaimGateTable, fullfile(bundleRoot, "claim_gate_table.csv"));
    writetable(analysis.ValidationWindowTable, fullfile(bundleRoot, "validation_window_table.csv"));
    writetable(analysis.RequirementsCoverageTable, fullfile(bundleRoot, "requirements_coverage.csv"));
    writetable(analysis.PublicContractChangeTable, fullfile(bundleRoot, "public_contract_change_table.csv"));
catch writeException
    error("runG7TruthContextDiagnostic:WriteTableFailed", "Failed to write G7 tables: %s", writeException.message);
end

localWriteTextFile(fullfile(bundleRoot, "decision.txt"), analysis.GateDecision);
localWriteTextFile(fullfile(bundleRoot, "failure_cause.txt"), analysis.ClaimBlockReason);
localWriteTextFile(fullfile(bundleRoot, "next_branch.txt"), analysis.NextBranch);
localWriteTextFile(fullfile(bundleRoot, "summary.md"), localBuildSummaryLines(analysis, bundleRoot, figureRoot));
localWriteJsonFile(fullfile(bundleRoot, "metrics.json"), localBuildMetricsJson(analysis, bundleRoot));
localWriteJsonFile(fullfile(bundleRoot, "config_snapshot.json"), localBuildConfigSnapshot(analysis, options));

end

function metricsJson = localBuildMetricsJson(analysis, bundleRoot)

truthSummary = analysis.TruthImportSummaryTable(1, :);
timingSummary = analysis.TimingResidualSummaryTable(1, :);
metricsJson = struct();
metricsJson.stage_id = string(analysis.StageId);
metricsJson.gate_id = string(analysis.GateId);
metricsJson.dataset_id = string(analysis.DatasetId);
metricsJson.bundle_root = string(bundleRoot);
metricsJson.mode = string(analysis.Mode);
metricsJson.gate_decision = string(analysis.GateDecision);
metricsJson.review_status = string(analysis.ReviewStatus);
metricsJson.truth_claims_enabled = logical(analysis.TruthClaimsEnabled);
metricsJson.claim_block_reason = string(analysis.ClaimBlockReason);
metricsJson.next_branch = string(analysis.NextBranch);
metricsJson.truth_row_count = double(truthSummary.RowCount);
metricsJson.truth_valid_time_row_count = double(truthSummary.ValidTimeRowCount);
metricsJson.truth_unique_aircraft_count = double(truthSummary.UniqueAircraftCount);
metricsJson.capture_overlap_rows = height(analysis.CaptureTruthOverlapTable);
metricsJson.capture_rows_with_truth = double(nnz(analysis.CaptureTruthOverlapTable.TruthRowCount > 0));
metricsJson.recording_delta_min_s = double(timingSummary.RecordingDeltaMin_s);
metricsJson.recording_delta_median_s = double(timingSummary.RecordingDeltaMedian_s);
metricsJson.recording_delta_max_s = double(timingSummary.RecordingDeltaMax_s);
metricsJson.max_abs_datetime_vs_recording_ms = double(timingSummary.MaxAbsDateTimeVsRecording_ms);
metricsJson.timing_source_decision = string(timingSummary.TimingSourceDecision);
metricsJson.source_g6_bundle_root = string(analysis.SourceG6.BundleRoot);

end

function configSnapshot = localBuildConfigSnapshot(analysis, options)

configSnapshot = struct();
configSnapshot.stage_id = string(analysis.StageId);
configSnapshot.dataset_id = string(analysis.DatasetId);
configSnapshot.execution_mode = string(analysis.Mode);
configSnapshot.truth_claims_enabled = logical(analysis.TruthClaimsEnabled);
configSnapshot.detector_tuning_enabled = false;
configSnapshot.cfar_execution_enabled = false;
configSnapshot.options = options;

end

function summaryLines = localBuildSummaryLines(analysis, bundleRoot, figureRoot)

truthSummary = analysis.TruthImportSummaryTable(1, :);
timingSummary = analysis.TimingResidualSummaryTable(1, :);
summaryLines = [
    "# G7 Truth-Context Diagnostic"
    ""
    sprintf("- Dataset: `%s`", analysis.DatasetId)
    sprintf("- Bundle root: `%s`", bundleRoot)
    sprintf("- Mode: `%s`", analysis.Mode)
    sprintf("- Gate decision: `%s`", analysis.GateDecision)
    sprintf("- Review status: `%s`", analysis.ReviewStatus)
    sprintf("- Truth claims enabled: `%s`", string(analysis.TruthClaimsEnabled))
    sprintf("- Claim block reason: `%s`", analysis.ClaimBlockReason)
    sprintf("- Next branch: `%s`", analysis.NextBranch)
    ""
    "## Truth Import"
    sprintf("- Truth file: `%s`", truthSummary.TruthFilePath)
    sprintf("- Truth rows: `%d`", truthSummary.RowCount)
    sprintf("- Valid timestamp rows: `%d`", truthSummary.ValidTimeRowCount)
    sprintf("- Unique aircraft count: `%d`", truthSummary.UniqueAircraftCount)
    sprintf("- First truth UTC: `%s`", string(truthSummary.FirstTruthUtc))
    sprintf("- Last truth UTC: `%s`", string(truthSummary.LastTruthUtc))
    ""
    "## Timing Audit"
    sprintf("- Manifest capture duration: `%.3f s`", timingSummary.ManifestCaptureDuration_s)
    sprintf("- Manifest repetition spacing: `%.3f s`", timingSummary.ManifestRepetitionSpacing_s)
    sprintf("- Recording delta min/median/max: `%.3f / %.3f / %.3f s`", timingSummary.RecordingDeltaMin_s, timingSummary.RecordingDeltaMedian_s, timingSummary.RecordingDeltaMax_s)
    sprintf("- Max |DateTime - RecordingUTC|: `%.3f ms`", timingSummary.MaxAbsDateTimeVsRecording_ms)
    sprintf("- Timing source decision: `%s`", timingSummary.TimingSourceDecision)
    ""
    "## Capture Overlap"
    sprintf("- Capture rows: `%d`", height(analysis.CaptureTruthOverlapTable))
    sprintf("- Captures with truth rows: `%d`", nnz(analysis.CaptureTruthOverlapTable.TruthRowCount > 0))
    ""
    "## Output Files"
    "- `truth_import_summary_table.csv`"
    "- `radar_timing_audit_table.csv`"
    "- `capture_truth_overlap_table.csv`"
    "- `timing_residual_summary_table.csv`"
    "- `claim_gate_table.csv`"
    "- `validation_window_table.csv`"
    "- `requirements_coverage.csv`"
    "- `public_contract_change_table.csv`"
    "- `metrics.json`"
    "- `metrics.mat`"
    "- `config_snapshot.json`"
    "- `decision.txt`"
    "- `failure_cause.txt`"
    "- `next_branch.txt`"
    "- `timing_summary.csv`"
    "- `performance_summary.json`"
    sprintf("- `figures/` at `%s`", figureRoot)
    ];

end

function timingSummaryTable = localBuildTimingSummaryTable(analysis, elapsed_s, bundleRoot)

stageId = string(analysis.StageId);
stepName = "truth_context_diagnostic";
elapsedColumn_s = double(elapsed_s);
executionMode = string(analysis.Mode);
inputSampleCount = NaN;
inputRepetitionCount = height(analysis.RadarTimingAuditTable);
outputArtifactCount = localCountOutputFiles(bundleRoot);
outputFigureCount = 0.0;
outputBytes = localCountOutputBytes(bundleRoot);
notes = string(analysis.ClaimBlockReason);
timingSummaryTable = table(stageId, stepName, elapsedColumn_s, executionMode, inputSampleCount, inputRepetitionCount, outputArtifactCount, outputFigureCount, outputBytes, notes, VariableNames = {'StageId', 'StepName', 'Elapsed_s', 'ExecutionMode', 'InputSampleCount', 'InputRepetitionCount', 'OutputArtifactCount', 'OutputFigureCount', 'OutputBytes', 'Notes'});

end

function performanceSummary = localBuildPerformanceSummary(analysis, elapsed_s, bundleRoot)

performanceSummary = struct();
performanceSummary.stage_id = string(analysis.StageId);
performanceSummary.elapsed_s = double(elapsed_s);
performanceSummary.execution_mode = string(analysis.Mode);
performanceSummary.output_artifact_count = double(localCountOutputFiles(bundleRoot));
performanceSummary.output_figure_count = 0.0;
performanceSummary.output_bytes = double(localCountOutputBytes(bundleRoot));

end

function fileCount = localCountOutputFiles(bundleRoot)

listing = dir(fullfile(bundleRoot, "**", "*"));
isFile = ~[listing.isdir];
fileCount = double(nnz(isFile));

end

function outputBytes = localCountOutputBytes(bundleRoot)

listing = dir(fullfile(bundleRoot, "**", "*"));
isFile = ~[listing.isdir];
fileBytes = [listing(isFile).bytes];
outputBytes = double(sum(fileBytes));

end

function results = localBuildResults(datasetId, stageArtifactId, runTimestampZ, bundleRoot, analysis, timingSummaryTable, performanceSummary)

results = struct();
results.DatasetId = string(datasetId);
results.StageArtifactId = string(stageArtifactId);
results.RunTimestampZ = string(runTimestampZ);
results.BundleRoot = string(bundleRoot);
results.GateDecision = string(analysis.GateDecision);
results.ReviewStatus = string(analysis.ReviewStatus);
results.TruthClaimsEnabled = logical(analysis.TruthClaimsEnabled);
results.ClaimBlockReason = string(analysis.ClaimBlockReason);
results.TimingSummaryTable = timingSummaryTable;
results.PerformanceSummary = performanceSummary;

end

function localPrintRunSummary(results, analysis)

fprintf("G7 bundle root:\t%s\n", results.BundleRoot);
fprintf("Gate decision:\t%s\n", results.GateDecision);
fprintf("Review status:\t%s\n", results.ReviewStatus);
fprintf("Truth claims enabled:\t%d\n", results.TruthClaimsEnabled);
fprintf("Claim block reason:\t%s\n", results.ClaimBlockReason);
fprintf("Capture rows:\t%d\n", height(analysis.CaptureTruthOverlapTable));
fprintf("Captures with truth rows:\t%d\n", nnz(analysis.CaptureTruthOverlapTable.TruthRowCount > 0));

end

function localEnsureFolder(folderPath)

if isfolder(folderPath)
    return
end

try
    mkdir(folderPath);
catch mkdirException
    error("runG7TruthContextDiagnostic:CreateFolderFailed", "Failed to create folder %s: %s", folderPath, mkdirException.message);
end

end

function localWriteJsonFile(filePath, inputStruct)

try
    jsonText = jsonencode(inputStruct, PrettyPrint = true);
catch encodeException
    error("runG7TruthContextDiagnostic:JsonEncodeFailed", "Failed to encode JSON for %s: %s", filePath, encodeException.message);
end

localWriteTextFile(filePath, jsonText);

end

function localWriteTextFile(filePath, lines)

try
    writelines(string(lines), filePath);
catch writeException
    error("runG7TruthContextDiagnostic:WriteTextFailed", "Failed to write %s: %s", filePath, writeException.message);
end

end

function localWriteFailureBundle(bundleRoot, mainException)

if strlength(string(bundleRoot)) == 0
    return
end

try
    localEnsureFolder(bundleRoot);
    localWriteTextFile(fullfile(bundleRoot, "decision.txt"), "reject");
    localWriteTextFile(fullfile(bundleRoot, "failure_cause.txt"), string(mainException.message));
    localWriteTextFile(fullfile(bundleRoot, "next_branch.txt"), "fix_g7_truth_context_execution_failure");
catch
end

end
