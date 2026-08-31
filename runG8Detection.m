function results = runG8Detection(datasetId, repoRoot, options)
%RUNG8DETECTION Refuse formal G8 detection until prerequisites exist.

arguments
    datasetId (1,1) string = "20260622T102123"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

stageArtifactId = "G8_Detection_Prerequisite_Gate";
stageTimer = tic;
datasetId = string(datasetId);
repoRoot = helperResolveRepoRoot(repoRoot);
runTimestampZ = string(datetime("now", "TimeZone", "UTC", "Format", "yyyyMMdd'T'HHmmss'Z'"));
bundleRoot = fullfile(repoRoot, "artifacts", datasetId, stageArtifactId, runTimestampZ);
figureRoot = fullfile(bundleRoot, "figures");

fprintf("Running G8 detection prerequisite gate for dataset %s\n", datasetId);
fprintf("Repository root:\t%s\n", repoRoot);

try
    localEnsureFolder(bundleRoot);
    localEnsureFolder(figureRoot);
    analysis = helperAnalyzeG8DetectionPrerequisiteGate(datasetId, repoRoot, options);
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
    writetable(analysis.SourceSummaryTable, fullfile(bundleRoot, "source_summary_table.csv"));
    writetable(analysis.PrerequisiteBlockTable, fullfile(bundleRoot, "prerequisite_block_table.csv"));
    writetable(analysis.ExecutionDecisionTable, fullfile(bundleRoot, "execution_decision_table.csv"));
    writetable(analysis.DetectionSchemaScaffoldTable, fullfile(bundleRoot, "detection_schema_scaffold_table.csv"));
    writetable(analysis.RequirementsCoverageTable, fullfile(bundleRoot, "requirements_coverage.csv"));
    writetable(analysis.PublicContractChangeTable, fullfile(bundleRoot, "public_contract_change_table.csv"));
catch writeException
    error("runG8Detection:WriteTableFailed", "Failed to write G8 tables: %s", writeException.message);
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
metricsJson.execution_refused = logical(analysis.ExecutionRefused);
metricsJson.cfar_execution_enabled = logical(analysis.CfarExecutionEnabled);
metricsJson.detector_tuning_enabled = logical(analysis.DetectorTuningEnabled);
metricsJson.detection_table_emitted = logical(analysis.DetectionTableEmitted);
metricsJson.refusal_reason = string(analysis.RefusalReason);
metricsJson.next_branch = string(analysis.NextBranch);
metricsJson.prerequisite_block_rows = height(analysis.PrerequisiteBlockTable);
metricsJson.source_g6_bundle_root = string(analysis.SourceG6.BundleRoot);
metricsJson.source_g7_bundle_root = string(analysis.SourceG7.BundleRoot);

end

function configSnapshot = localBuildConfigSnapshot(analysis, options)

configSnapshot = struct();
configSnapshot.stage_id = string(analysis.StageId);
configSnapshot.dataset_id = string(analysis.DatasetId);
configSnapshot.execution_mode = "formal_detection_prerequisite_refusal";
configSnapshot.cfar_execution_enabled = logical(analysis.CfarExecutionEnabled);
configSnapshot.detector_tuning_enabled = logical(analysis.DetectorTuningEnabled);
configSnapshot.truth_claims_required = true;
configSnapshot.options = options;

end

function summaryLines = localBuildSummaryLines(analysis, bundleRoot, figureRoot)

summaryLines = [
    "# G8 Detection Prerequisite Gate"
    ""
    sprintf("- Dataset: `%s`", analysis.DatasetId)
    sprintf("- Bundle root: `%s`", bundleRoot)
    sprintf("- Gate decision: `%s`", analysis.GateDecision)
    sprintf("- Review status: `%s`", analysis.ReviewStatus)
    sprintf("- Execution refused: `%s`", string(analysis.ExecutionRefused))
    sprintf("- CFAR execution enabled: `%s`", string(analysis.CfarExecutionEnabled))
    sprintf("- Detector tuning enabled: `%s`", string(analysis.DetectorTuningEnabled))
    sprintf("- Detection table emitted: `%s`", string(analysis.DetectionTableEmitted))
    sprintf("- Refusal reason: `%s`", analysis.RefusalReason)
    sprintf("- Next branch: `%s`", analysis.NextBranch)
    ""
    "## Prerequisites"
    sprintf("- Source rows: `%d`", height(analysis.SourceSummaryTable))
    sprintf("- Prerequisite block rows: `%d`", height(analysis.PrerequisiteBlockTable))
    ""
    "## Output Files"
    "- `source_summary_table.csv`"
    "- `prerequisite_block_table.csv`"
    "- `execution_decision_table.csv`"
    "- `detection_schema_scaffold_table.csv`"
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
stepName = "formal_detection_prerequisite_refusal";
elapsedColumn_s = double(elapsed_s);
executionMode = "formal_detection_blocked";
inputSampleCount = NaN;
inputRepetitionCount = NaN;
outputArtifactCount = localCountOutputFiles(bundleRoot);
outputFigureCount = 0.0;
outputBytes = localCountOutputBytes(bundleRoot);
notes = string(analysis.RefusalReason);
timingSummaryTable = table(stageId, stepName, elapsedColumn_s, executionMode, inputSampleCount, inputRepetitionCount, outputArtifactCount, outputFigureCount, outputBytes, notes, VariableNames = {'StageId', 'StepName', 'Elapsed_s', 'ExecutionMode', 'InputSampleCount', 'InputRepetitionCount', 'OutputArtifactCount', 'OutputFigureCount', 'OutputBytes', 'Notes'});

end

function performanceSummary = localBuildPerformanceSummary(analysis, elapsed_s, bundleRoot)

performanceSummary = struct();
performanceSummary.stage_id = string(analysis.StageId);
performanceSummary.elapsed_s = double(elapsed_s);
performanceSummary.execution_mode = "formal_detection_blocked";
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
results.ExecutionRefused = logical(analysis.ExecutionRefused);
results.RefusalReason = string(analysis.RefusalReason);
results.TimingSummaryTable = timingSummaryTable;
results.PerformanceSummary = performanceSummary;

end

function localPrintRunSummary(results, analysis)

fprintf("G8 bundle root:\t%s\n", results.BundleRoot);
fprintf("Gate decision:\t%s\n", results.GateDecision);
fprintf("Review status:\t%s\n", results.ReviewStatus);
fprintf("Execution refused:\t%d\n", results.ExecutionRefused);
fprintf("Refusal reason:\t%s\n", results.RefusalReason);
fprintf("Prerequisite block rows:\t%d\n", height(analysis.PrerequisiteBlockTable));

end

function localEnsureFolder(folderPath)

if isfolder(folderPath)
    return
end

try
    mkdir(folderPath);
catch mkdirException
    error("runG8Detection:CreateFolderFailed", "Failed to create folder %s: %s", folderPath, mkdirException.message);
end

end

function localWriteJsonFile(filePath, inputStruct)

try
    jsonText = jsonencode(inputStruct, PrettyPrint = true);
catch encodeException
    error("runG8Detection:JsonEncodeFailed", "Failed to encode JSON for %s: %s", filePath, encodeException.message);
end

localWriteTextFile(filePath, jsonText);

end

function localWriteTextFile(filePath, lines)

try
    writelines(string(lines), filePath);
catch writeException
    error("runG8Detection:WriteTextFailed", "Failed to write %s: %s", filePath, writeException.message);
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
    localWriteTextFile(fullfile(bundleRoot, "next_branch.txt"), "fix_g8_prerequisite_gate_execution_failure");
catch
end

end
