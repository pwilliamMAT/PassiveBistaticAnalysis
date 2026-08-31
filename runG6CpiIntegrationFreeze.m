function results = runG6CpiIntegrationFreeze(datasetId, repoRoot, options)
%RUNG6CPIINTEGRATIONFREEZE Run conservative G6 blocked/deferred freeze scaffold.

arguments
    datasetId (1,1) string = "20260622T102123"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

stageArtifactId = "G6_CPI_Integration_Freeze";
stageTimer = tic;
datasetId = string(datasetId);
repoRoot = helperResolveRepoRoot(repoRoot);
runTimestampZ = string(datetime("now", "TimeZone", "UTC", "Format", "yyyyMMdd'T'HHmmss'Z'"));
bundleRoot = fullfile(repoRoot, "artifacts", datasetId, stageArtifactId, runTimestampZ);
figureRoot = fullfile(bundleRoot, "figures");

fprintf("Running G6 CPI/integration freeze scaffold for dataset %s\n", datasetId);
fprintf("Repository root:\t%s\n", repoRoot);

try
    localEnsureFolder(bundleRoot);
    localEnsureFolder(figureRoot);
    analysis = helperAnalyzeG6CpiIntegrationFreeze(datasetId, repoRoot, options);
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
    writetable(analysis.SourceGateSummaryTable, fullfile(bundleRoot, "source_gate_summary.csv"));
    writetable(analysis.UpstreamBlockTable, fullfile(bundleRoot, "upstream_block_table.csv"));
    writetable(analysis.FreezeDecisionTable, fullfile(bundleRoot, "freeze_decision_table.csv"));
    writetable(analysis.FrozenProductDefinition, fullfile(bundleRoot, "frozen_product_definition.csv"));
    writetable(analysis.RequirementsCoverageTable, fullfile(bundleRoot, "requirements_coverage.csv"));
    writetable(analysis.PublicContractChangeTable, fullfile(bundleRoot, "public_contract_change_table.csv"));
catch writeException
    error("runG6CpiIntegrationFreeze:WriteTableFailed", "Failed to write G6 tables: %s", writeException.message);
end

localWriteTextFile(fullfile(bundleRoot, "decision.txt"), analysis.GateDecision);
localWriteTextFile(fullfile(bundleRoot, "failure_cause.txt"), analysis.RefusalReason);
localWriteTextFile(fullfile(bundleRoot, "next_branch.txt"), analysis.NextBranch);
localWriteTextFile(fullfile(bundleRoot, "summary.md"), localBuildSummaryLines(analysis, bundleRoot, figureRoot));
localWriteJsonFile(fullfile(bundleRoot, "metrics.json"), localBuildMetricsJson(analysis, bundleRoot));
localWriteJsonFile(fullfile(bundleRoot, "config_snapshot.json"), localBuildConfigSnapshot(analysis, options));

end

function metricsJson = localBuildMetricsJson(analysis, bundleRoot)

metricsJson = struct();
metricsJson.stage_id = string(analysis.StageId);
metricsJson.gate_id = string(analysis.GateId);
metricsJson.dataset_id = string(analysis.DatasetId);
metricsJson.bundle_root = string(bundleRoot);
metricsJson.gate_decision = string(analysis.GateDecision);
metricsJson.review_status = string(analysis.ReviewStatus);
metricsJson.freeze_status = string(analysis.FreezeStatus);
metricsJson.detector_product_freeze_enabled = logical(analysis.DetectorProductFreezeEnabled);
metricsJson.normal_freeze_refused = logical(analysis.NormalFreezeRefused);
metricsJson.refusal_reason = string(analysis.RefusalReason);
metricsJson.next_branch = string(analysis.NextBranch);
metricsJson.g4_overall_label = string(analysis.DatasetInterpretation.g4_status);
metricsJson.g4_limitation_source = string(analysis.DatasetInterpretation.g4_limitation_source);
metricsJson.g4_full_rate_audit = string(analysis.DatasetInterpretation.g4_full_rate_audit);
metricsJson.g5_gate_decision = string(analysis.DatasetInterpretation.g5_gate_decision);
metricsJson.g5_decision_label = string(analysis.DatasetInterpretation.g5_decision_label);
metricsJson.g5_default_gate_reveal_count = double(analysis.DatasetInterpretation.g5_default_gate_reveal_count);
metricsJson.g5_permissive_probe_reveal_count = double(analysis.DatasetInterpretation.g5_permissive_probe_reveal_count);
metricsJson.g5_best_causal_label = string(analysis.DatasetInterpretation.g5_best_causal_label);
metricsJson.upstream_block_rows = height(analysis.UpstreamBlockTable);
metricsJson.source_gate_rows = height(analysis.SourceGateSummaryTable);

end

function configSnapshot = localBuildConfigSnapshot(analysis, options)

configSnapshot = struct();
configSnapshot.stage_id = string(analysis.StageId);
configSnapshot.dataset_id = string(analysis.DatasetId);
configSnapshot.execution_mode = "blocked_deferred_freeze_scaffold";
configSnapshot.detector_tuning_enabled = false;
configSnapshot.truth_alignment_enabled = false;
configSnapshot.cfar_execution_enabled = false;
configSnapshot.options = options;

end

function summaryLines = localBuildSummaryLines(analysis, bundleRoot, figureRoot)

summaryLines = [
    "# G6 CPI / Integration Freeze Scaffold"
    ""
    sprintf("- Dataset: `%s`", analysis.DatasetId)
    sprintf("- Bundle root: `%s`", bundleRoot)
    sprintf("- Gate decision: `%s`", analysis.GateDecision)
    sprintf("- Review status: `%s`", analysis.ReviewStatus)
    sprintf("- Freeze status: `%s`", analysis.FreezeStatus)
    sprintf("- Detector product freeze enabled: `%s`", string(analysis.DetectorProductFreezeEnabled))
    sprintf("- Normal freeze refused: `%s`", string(analysis.NormalFreezeRefused))
    sprintf("- Refusal reason: `%s`", analysis.RefusalReason)
    sprintf("- Next branch: `%s`", analysis.NextBranch)
    ""
    "## Current Dataset Interpretation"
    sprintf("- G4 status: `%s`", analysis.DatasetInterpretation.g4_status)
    sprintf("- G4 limitation source: `%s`", analysis.DatasetInterpretation.g4_limitation_source)
    sprintf("- G4 full-rate audit: `%s`", analysis.DatasetInterpretation.g4_full_rate_audit)
    sprintf("- G5 gate decision: `%s`", analysis.DatasetInterpretation.g5_gate_decision)
    sprintf("- G5 decision label: `%s`", analysis.DatasetInterpretation.g5_decision_label)
    sprintf("- G5 default-gate reveal count: `%.0f`", analysis.DatasetInterpretation.g5_default_gate_reveal_count)
    sprintf("- G5 permissive-probe reveal count: `%.0f`", analysis.DatasetInterpretation.g5_permissive_probe_reveal_count)
    sprintf("- G5 best causal label: `%s`", analysis.DatasetInterpretation.g5_best_causal_label)
    ""
    "## Blocking Evidence"
    sprintf("- Upstream block rows: `%d`", height(analysis.UpstreamBlockTable))
    sprintf("- Source gate rows: `%d`", height(analysis.SourceGateSummaryTable))
    ""
    "## Output Files"
    "- `source_gate_summary.csv`"
    "- `upstream_block_table.csv`"
    "- `freeze_decision_table.csv`"
    "- `frozen_product_definition.csv`"
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
stepName = "blocked_deferred_freeze_scaffold";
elapsedColumn_s = double(elapsed_s);
executionMode = "diagnostic_negative_control";
inputSampleCount = NaN;
inputRepetitionCount = NaN;
outputArtifactCount = localCountOutputFiles(bundleRoot);
outputFigureCount = 0.0;
outputBytes = localCountOutputBytes(bundleRoot);
notes = string(analysis.FreezeStatus);
timingSummaryTable = table(stageId, stepName, elapsedColumn_s, executionMode, inputSampleCount, inputRepetitionCount, outputArtifactCount, outputFigureCount, outputBytes, notes, VariableNames = {'StageId', 'StepName', 'Elapsed_s', 'ExecutionMode', 'InputSampleCount', 'InputRepetitionCount', 'OutputArtifactCount', 'OutputFigureCount', 'OutputBytes', 'Notes'});

end

function performanceSummary = localBuildPerformanceSummary(analysis, elapsed_s, bundleRoot)

performanceSummary = struct();
performanceSummary.stage_id = string(analysis.StageId);
performanceSummary.elapsed_s = double(elapsed_s);
performanceSummary.execution_mode = "diagnostic_negative_control";
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
results.FreezeStatus = string(analysis.FreezeStatus);
results.DetectorProductFreezeEnabled = logical(analysis.DetectorProductFreezeEnabled);
results.TimingSummaryTable = timingSummaryTable;
results.PerformanceSummary = performanceSummary;

end

function localPrintRunSummary(results, analysis)

fprintf("G6 bundle root:\t%s\n", results.BundleRoot);
fprintf("Gate decision:\t%s\n", results.GateDecision);
fprintf("Review status:\t%s\n", results.ReviewStatus);
fprintf("Freeze status:\t%s\n", results.FreezeStatus);
fprintf("Freeze enabled:\t%d\n", results.DetectorProductFreezeEnabled);
fprintf("Upstream block rows:\t%d\n", height(analysis.UpstreamBlockTable));

end

function localEnsureFolder(folderPath)

if isfolder(folderPath)
    return
end

try
    mkdir(folderPath);
catch mkdirException
    error("runG6CpiIntegrationFreeze:CreateFolderFailed", "Failed to create folder %s: %s", folderPath, mkdirException.message);
end

end

function localWriteJsonFile(filePath, inputStruct)

try
    jsonText = jsonencode(inputStruct, PrettyPrint = true);
catch encodeException
    error("runG6CpiIntegrationFreeze:JsonEncodeFailed", "Failed to encode JSON for %s: %s", filePath, encodeException.message);
end

localWriteTextFile(filePath, jsonText);

end

function localWriteTextFile(filePath, lines)

try
    writelines(string(lines), filePath);
catch writeException
    error("runG6CpiIntegrationFreeze:WriteTextFailed", "Failed to write %s: %s", filePath, writeException.message);
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
    localWriteTextFile(fullfile(bundleRoot, "next_branch.txt"), "fix_g6_scaffold_execution_failure");
catch
end

end
