function results = runG45SyntheticTargetRecovery(suiteId, caseDatasetId, ...
    repoRoot, options)
%RUNG45SYNTHETICTARGETRECOVERY Run the standalone G4.5 diagnostic gate.
%
%   RESULTS = RUNG45SYNTHETICTARGETRECOVERY() runs all canonical G4.5
%   synthetic target recovery cases and writes one artifact bundle per case:
%   artifacts/<suite_id>/<case_dataset_id>/G4_5_SyntheticTargetRecovery/
%   <runTimestampZ>/

arguments
    suiteId (1,1) string = "g4_5_real_background_20260807T162306840"
    caseDatasetId (1,1) string = "all"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

repoRoot = helperResolveRepoRoot(repoRoot);
suiteId = string(suiteId);
caseDatasetId = string(caseDatasetId);
stageArtifactId = "G4_5_SyntheticTargetRecovery";
runTimestampZ = string(datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyyMMdd'T'HHmmss'Z'"));
caseIds = localResolveCaseIds(caseDatasetId, options);
caseResults = repmat(localEmptyCaseResult(), numel(caseIds), 1);

fprintf("Running G4.5 Synthetic Target Recovery for suite %s\n", suiteId);
fprintf("Repository root:\t%s\n", repoRoot);
fprintf("Case count:\t%d\n", numel(caseIds));

for caseIndex = 1:numel(caseIds)
    currentCaseId = caseIds(caseIndex);
    fprintf("G4.5 case:\t%s\n", currentCaseId);
    caseResults(caseIndex) = localRunOneCase(suiteId, currentCaseId, ...
        repoRoot, options, runTimestampZ, stageArtifactId);
end

results = struct();
results.SuiteId = suiteId;
results.CaseDatasetId = caseDatasetId;
results.StageArtifactId = stageArtifactId;
results.RunTimestampZ = runTimestampZ;
results.CaseResults = caseResults;
results.DecisionTable = localBuildSuiteDecisionTable(caseResults);
results.AllRequiredCasesRun = all(ismember(localDefaultCaseIds(), ...
    string({caseResults.CaseDatasetId}.')));

fprintf("G4.5 suite run timestamp:\t%s\n", runTimestampZ);
disp(results.DecisionTable);

end

function caseResult = localRunOneCase(suiteId, caseDatasetId, repoRoot, ...
    options, runTimestampZ, stageArtifactId)

caseTimer = tic;
bundleRoot = fullfile(repoRoot, "artifacts", suiteId, caseDatasetId, ...
    stageArtifactId, runTimestampZ);
figureRoot = fullfile(bundleRoot, "figures");

try
    localEnsureFolder(bundleRoot);
    localEnsureFolder(figureRoot);

    analysis = helperAnalyzeG45SyntheticTargetRecovery(suiteId, ...
        caseDatasetId, repoRoot, options);
    figurePaths = localRenderFiguresIfRequested(analysis, figureRoot);
    localWriteAnalysisArtifacts(bundleRoot, analysis, figurePaths);
    elapsed_s = toc(caseTimer);
    timingSummaryTable = localFinalizeTimingSummary(analysis, bundleRoot, ...
        elapsed_s, numel(figurePaths));
    performanceSummary = localBuildPerformanceSummary(analysis, ...
        bundleRoot, elapsed_s, numel(figurePaths));
    writetable(timingSummaryTable, fullfile(bundleRoot, ...
        "timing_summary.csv"));
    localWriteJsonFile(fullfile(bundleRoot, "performance_summary.json"), ...
        performanceSummary);
    save(fullfile(bundleRoot, "metrics.mat"), "analysis", ...
        "timingSummaryTable", "performanceSummary", "figurePaths");
    caseResult = localBuildCaseResult(suiteId, caseDatasetId, ...
        stageArtifactId, runTimestampZ, bundleRoot, analysis, ...
        timingSummaryTable, performanceSummary, figurePaths);
    localPrintCaseSummary(caseResult, analysis);
catch mainException
    localWriteFailureBundle(bundleRoot, mainException);
    rethrow(mainException);
end

end

function localWriteAnalysisArtifacts(bundleRoot, analysis, figurePaths)

try
    writetable(analysis.TargetRecoveryTable, fullfile(bundleRoot, ...
        "target_recovery_table.csv"));
    writetable(analysis.ManifestValidationTable, fullfile(bundleRoot, ...
        "manifest_validation_table.csv"));
    writetable(analysis.TruthConventionAuditTable, fullfile(bundleRoot, ...
        "truth_convention_audit_table.csv"));
    writetable(analysis.FalseAlarmSummaryTable, fullfile(bundleRoot, ...
        "false_alarm_summary_table.csv"));
    writetable(analysis.DiagnosticInterpretationTable, fullfile(bundleRoot, ...
        "diagnostic_interpretation_table.csv"));
    writetable(analysis.RequirementsCoverageTable, fullfile(bundleRoot, ...
        "requirements_coverage.csv"));
catch writeException
    error("runG45SyntheticTargetRecovery:WriteTableFailed", ...
        "Failed to write G4.5 CSV artifacts: %s", writeException.message);
end

localWriteTextFile(fullfile(bundleRoot, "summary.md"), ...
    localBuildSummaryLines(analysis, bundleRoot, figurePaths));
localWriteJsonFile(fullfile(bundleRoot, "summary.json"), ...
    localBuildSummaryJson(analysis, bundleRoot, figurePaths));
localWriteJsonFile(fullfile(bundleRoot, "metrics.json"), ...
    localBuildMetricsJson(analysis, bundleRoot));
localWriteTextFile(fullfile(bundleRoot, "decision.txt"), ...
    analysis.GateDecision);
localWriteTextFile(fullfile(bundleRoot, "next_branch.txt"), ...
    analysis.NextBranch);

if ~ismember(analysis.GateDecision, ["PASS", "CONTROL_PASS"])
    localWriteTextFile(fullfile(bundleRoot, "failure_cause.txt"), ...
        analysis.FailureCause);
end

end

function figurePaths = localRenderFiguresIfRequested(analysis, figureRoot)

figurePaths = strings(0, 1);

if ~isfield(analysis.Options, "RenderFigures") || ...
        ~logical(analysis.Options.RenderFigures)
    return
end

if isempty(analysis.RepresentativeMaps)
    return
end

visibleState = "off";

if isfield(analysis.Options, "ShowFigures") && ...
        logical(analysis.Options.ShowFigures)
    visibleState = "on";
end

truthOverlayPath = fullfile(figureRoot, "truth_overlay.png");
localRenderTruthOverlayFigure(analysis, truthOverlayPath, visibleState);
figurePaths(end + 1, 1) = string(truthOverlayPath);

if ~isempty(analysis.TargetRecoveryTable)
    localCutPath = fullfile(figureRoot, "local_target_cut.png");
    localRenderLocalTargetCutFigure(analysis, localCutPath, visibleState);
    figurePaths(end + 1, 1) = string(localCutPath);
end

if ~isempty(analysis.FalseAlarmSummaryTable)
    falseAlarmPath = fullfile(figureRoot, "false_alarm_overlay.png");
    localRenderFalseAlarmFigure(analysis, falseAlarmPath, visibleState);
    figurePaths(end + 1, 1) = string(falseAlarmPath);
end

end

function localRenderTruthOverlayFigure(analysis, outputPath, visibleState)

map = analysis.RepresentativeMaps(1);
figureHandle = figure("Visible", visibleState);
cleanupObject = onCleanup(@() close(figureHandle));
imagesc(map.DelayAxis_s .* 1.0e6, map.DopplerAxis_Hz, map.ReviewMap_dB);
axis xy
colorbar
xlabel("Delay [us]");
ylabel("Doppler [Hz]");
title("G4.5 Truth Overlay - " + analysis.CaseDatasetId);
hold on

if ~isempty(analysis.TargetRecoveryTable)
    subset = analysis.TargetRecoveryTable( ...
        analysis.TargetRecoveryTable.WindowLabel == map.WindowLabel, :);
    scatter(subset.AssociationDelay_s .* 1.0e6, ...
        subset.AssociationDoppler_Hz, 36, "r", "filled");
end

hold off
localSaveFigure(figureHandle, outputPath);

end

function localRenderLocalTargetCutFigure(analysis, outputPath, visibleState)

targetTable = analysis.TargetRecoveryTable;
[~, bestIndex] = max(targetTable.LocalProminence_dB);
bestRow = targetTable(bestIndex, :);
figureHandle = figure("Visible", visibleState);
cleanupObject = onCleanup(@() close(figureHandle));
bar(categorical(["target", "control"]), [
    bestRow.LocalProminence_dB
    bestRow.ControlProminence_dB
    ]);
ylabel("Local prominence [dB]");
xlabel("Measurement source");
title("G4.5 Local Target Cut - " + bestRow.TargetId);
hold on
yline(analysis.Options.PassProminence_dB, "r--", "Pass threshold");
yline(analysis.Options.WarnProminence_dB, "k--", "Warn threshold");
hold off
localSaveFigure(figureHandle, outputPath);

end

function localRenderFalseAlarmFigure(analysis, outputPath, visibleState)

falseAlarmTable = analysis.FalseAlarmSummaryTable;
figureHandle = figure("Visible", visibleState);
cleanupObject = onCleanup(@() close(figureHandle));
bar(categorical(falseAlarmTable.WindowLabel), ...
    falseAlarmTable.ControlProminence_dB);
ylabel("Control local prominence [dB]");
xlabel("Probe window");
title("G4.5 False Alarm Overlay - " + analysis.CaseDatasetId);
hold on
yline(analysis.Options.PassProminence_dB, "r--", "Pass threshold");
yline(analysis.Options.WarnProminence_dB, "k--", "Warn threshold");
hold off
localSaveFigure(figureHandle, outputPath);

end

function localSaveFigure(figureHandle, outputPath)

try
    exportgraphics(figureHandle, outputPath, Resolution = 150);
catch exportException
    error("runG45SyntheticTargetRecovery:FigureExportFailed", ...
        "Failed to export %s: %s", outputPath, exportException.message);
end

end

function summaryLines = localBuildSummaryLines(analysis, bundleRoot, ...
    figurePaths)

summaryLines = [
    "# G4.5 Synthetic Target Recovery"
    ""
    sprintf("- Suite: `%s`", analysis.SuiteId)
    sprintf("- Case: `%s`", analysis.CaseDatasetId)
    sprintf("- Bundle root: `%s`", bundleRoot)
    sprintf("- Decision: `%s`", analysis.GateDecision)
    sprintf("- Failure cause: `%s`", analysis.FailureCause)
    sprintf("- Next branch: `%s`", analysis.NextBranch)
    sprintf("- Decode path: `%s`", analysis.DecodePath)
    sprintf("- Sample rate: `%.0f [Hz]`", analysis.SampleRateHz)
    sprintf("- Map sample rate: `%.0f [Hz]`", analysis.MapSampleRateHz)
    sprintf("- Input samples: `%.0f`", analysis.InputSampleCount)
    ""
    "## Numeric Recovery"
    sprintf("- Expected targets: `%.0f`", ...
    analysis.TargetSummary.ExpectedTargetCount)
    sprintf("- Recovered targets: `%.0f`", ...
    analysis.TargetSummary.RecoveredTargetCount)
    sprintf("- Weak targets: `%.0f`", ...
    analysis.TargetSummary.WeakTargetCount)
    sprintf("- Not recovered targets: `%.0f`", ...
    analysis.TargetSummary.NotRecoveredTargetCount)
    sprintf("- Best local prominence: `%.2f [dB]`", ...
    analysis.TargetSummary.BestProminence_dB)
    sprintf("- Best robust Z: `%.2f`", analysis.TargetSummary.BestRobustZ)
    ""
    "## Output Files"
    "- `summary.md`"
    "- `summary.json`"
    "- `metrics.json`"
    "- `metrics.mat`"
    "- `target_recovery_table.csv`"
    "- `manifest_validation_table.csv`"
    "- `truth_convention_audit_table.csv`"
    "- `false_alarm_summary_table.csv`"
    "- `diagnostic_interpretation_table.csv`"
    "- `requirements_coverage.csv`"
    "- `decision.txt`"
    "- `next_branch.txt`"
    "- `timing_summary.csv`"
    "- `performance_summary.json`"
    sprintf("- Figure count: `%d`", numel(figurePaths))
    ];

if ~ismember(analysis.GateDecision, ["PASS", "CONTROL_PASS"])
    summaryLines = [
        summaryLines
        "- `failure_cause.txt`"
        ];
end

end

function summaryJson = localBuildSummaryJson(analysis, bundleRoot, ...
    figurePaths)

summaryJson = struct();
summaryJson.stage_id = string(analysis.StageId);
summaryJson.suite_id = string(analysis.SuiteId);
summaryJson.case_dataset_id = string(analysis.CaseDatasetId);
summaryJson.bundle_root = string(bundleRoot);
summaryJson.gate_decision = string(analysis.GateDecision);
summaryJson.failure_cause = string(analysis.FailureCause);
summaryJson.next_branch = string(analysis.NextBranch);
summaryJson.decode_path = string(analysis.DecodePath);
summaryJson.input_sample_count = double(analysis.InputSampleCount);
summaryJson.sample_rate_hz = double(analysis.SampleRateHz);
summaryJson.map_sample_rate_hz = double(analysis.MapSampleRateHz);
summaryJson.figure_paths = string(figurePaths(:));

end

function metricsJson = localBuildMetricsJson(analysis, bundleRoot)

metricsJson = struct();
metricsJson.stage_id = string(analysis.StageId);
metricsJson.suite_id = string(analysis.SuiteId);
metricsJson.case_dataset_id = string(analysis.CaseDatasetId);
metricsJson.bundle_root = string(bundleRoot);
metricsJson.gate_decision = string(analysis.GateDecision);
metricsJson.failure_cause = string(analysis.FailureCause);
metricsJson.next_branch = string(analysis.NextBranch);
metricsJson.expected_target_count = ...
    double(analysis.TargetSummary.ExpectedTargetCount);
metricsJson.recovered_target_count = ...
    double(analysis.TargetSummary.RecoveredTargetCount);
metricsJson.weak_target_count = ...
    double(analysis.TargetSummary.WeakTargetCount);
metricsJson.not_recovered_target_count = ...
    double(analysis.TargetSummary.NotRecoveredTargetCount);
metricsJson.best_prominence_db = ...
    double(analysis.TargetSummary.BestProminence_dB);
metricsJson.best_robust_z = double(analysis.TargetSummary.BestRobustZ);
metricsJson.has_warn_level_control_false_alarm = ...
    logical(analysis.TargetSummary.HasWarnLevelControlFalseAlarm);
metricsJson.has_pass_level_control_false_alarm = ...
    logical(analysis.TargetSummary.HasPassLevelControlFalseAlarm);
metricsJson.control_representative_map_count = ...
    double(numel(analysis.ControlRepresentativeMaps));
metricsJson.optional_caveat_codes = string( ...
    analysis.TargetSummary.OptionalCaveatCodes(:));
metricsJson.thresholds = struct();
metricsJson.thresholds.pass_prominence_db = ...
    double(analysis.Options.PassProminence_dB);
metricsJson.thresholds.pass_robust_z = ...
    double(analysis.Options.PassRobustZ);
metricsJson.thresholds.warn_prominence_db = ...
    double(analysis.Options.WarnProminence_dB);
metricsJson.thresholds.warn_robust_z = ...
    double(analysis.Options.WarnRobustZ);
metricsJson.thresholds.min_control_lift_for_pass_db = ...
    double(analysis.Options.MinControlLiftForPass_dB);

end

function timingSummaryTable = localFinalizeTimingSummary(analysis, ...
    bundleRoot, elapsed_s, figureCount)

timingSummaryTable = analysis.TimingSummaryTable;
newRow = table(string(analysis.StageId), "write_artifacts", ...
    double(elapsed_s), "review", double(analysis.InputSampleCount), ...
    double(analysis.InputRepetitionCount), ...
    double(localCountOutputFiles(bundleRoot)), double(figureCount), ...
    double(localCountOutputBytes(bundleRoot)), ...
    "Complete G4.5 runner artifact write.", VariableNames = ...
    {'StageId', 'StepName', 'Elapsed_s', 'ExecutionMode', ...
    'InputSampleCount', 'InputRepetitionCount', 'OutputArtifactCount', ...
    'OutputFigureCount', 'OutputBytes', 'Notes'});
timingSummaryTable = [timingSummaryTable; newRow];

end

function performanceSummary = localBuildPerformanceSummary(analysis, ...
    bundleRoot, elapsed_s, figureCount)

performanceSummary = struct();
performanceSummary.stage_id = string(analysis.StageId);
performanceSummary.suite_id = string(analysis.SuiteId);
performanceSummary.case_dataset_id = string(analysis.CaseDatasetId);
performanceSummary.elapsed_s = double(elapsed_s);
performanceSummary.execution_mode = "review";
performanceSummary.input_sample_count = double(analysis.InputSampleCount);
performanceSummary.input_repetition_count = ...
    double(analysis.InputRepetitionCount);
performanceSummary.output_artifact_count = ...
    double(localCountOutputFiles(bundleRoot));
performanceSummary.output_figure_count = double(figureCount);
performanceSummary.output_bytes = double(localCountOutputBytes(bundleRoot));

end

function result = localBuildCaseResult(suiteId, caseDatasetId, ...
    stageArtifactId, runTimestampZ, bundleRoot, analysis, ...
    timingSummaryTable, performanceSummary, figurePaths)

result = localEmptyCaseResult();
result.SuiteId = string(suiteId);
result.CaseDatasetId = string(caseDatasetId);
result.StageArtifactId = string(stageArtifactId);
result.RunTimestampZ = string(runTimestampZ);
result.BundleRoot = string(bundleRoot);
result.GateDecision = string(analysis.GateDecision);
result.FailureCause = string(analysis.FailureCause);
result.NextBranch = string(analysis.NextBranch);
result.RecoveredTargetCount = ...
    double(analysis.TargetSummary.RecoveredTargetCount);
result.WeakTargetCount = double(analysis.TargetSummary.WeakTargetCount);
result.NotRecoveredTargetCount = ...
    double(analysis.TargetSummary.NotRecoveredTargetCount);
result.TimingSummaryTable = timingSummaryTable;
result.PerformanceSummary = performanceSummary;
result.FigurePaths = string(figurePaths(:));

end

function localPrintCaseSummary(caseResult, analysis)

fprintf("G4.5 bundle root:\t%s\n", caseResult.BundleRoot);
fprintf("G4.5 decision:\t%s\n", caseResult.GateDecision);
fprintf("Recovered targets:\t%.0f\n", caseResult.RecoveredTargetCount);
fprintf("Weak targets:\t%.0f\n", caseResult.WeakTargetCount);
fprintf("Not recovered targets:\t%.0f\n", ...
    caseResult.NotRecoveredTargetCount);
fprintf("Failure cause:\t%s\n", analysis.FailureCause);

end

function decisionTable = localBuildSuiteDecisionTable(caseResults)

caseDatasetId = string({caseResults.CaseDatasetId}.');
gateDecision = string({caseResults.GateDecision}.');
bundleRoot = string({caseResults.BundleRoot}.');
recoveredTargetCount = double([caseResults.RecoveredTargetCount].');
weakTargetCount = double([caseResults.WeakTargetCount].');
notRecoveredTargetCount = double([caseResults.NotRecoveredTargetCount].');
decisionTable = table(caseDatasetId, gateDecision, ...
    recoveredTargetCount, weakTargetCount, notRecoveredTargetCount, ...
    bundleRoot, VariableNames = {'CaseDatasetId', 'GateDecision', ...
    'RecoveredTargetCount', 'WeakTargetCount', ...
    'NotRecoveredTargetCount', 'BundleRoot'});

end

function caseIds = localResolveCaseIds(caseDatasetId, options)

if caseDatasetId ~= "all"
    caseIds = string(caseDatasetId);
    return
end

if isfield(options, "CaseIds")
    caseIds = string(options.CaseIds(:));
else
    caseIds = localDefaultCaseIds();
end

end

function caseIds = localDefaultCaseIds()

caseIds = [
    "real_only_control"
    "easy_single_target"
    "medium_single_target"
    "hard_single_target"
    "marginal_single_target"
    "multi_target"
    ];

end

function localEnsureFolder(folderPath)

if isfolder(folderPath)
    return
end

try
    mkdir(folderPath);
catch mkdirException
    error("runG45SyntheticTargetRecovery:CreateFolderFailed", ...
        "Failed to create folder %s: %s", folderPath, ...
        mkdirException.message);
end

end

function localWriteJsonFile(filePath, inputStruct)

try
    jsonText = jsonencode(inputStruct, PrettyPrint = true);
catch encodeException
    error("runG45SyntheticTargetRecovery:JsonEncodeFailed", ...
        "Failed to encode JSON for %s: %s", filePath, ...
        encodeException.message);
end

localWriteTextFile(filePath, jsonText);

end

function localWriteTextFile(filePath, lines)

try
    writelines(string(lines), filePath);
catch writeException
    error("runG45SyntheticTargetRecovery:WriteTextFailed", ...
        "Failed to write %s: %s", filePath, writeException.message);
end

end

function fileCount = localCountOutputFiles(bundleRoot)

listing = dir(fullfile(bundleRoot, "**", "*"));

if isempty(listing)
    fileCount = 0.0;
    return
end

isFile = ~[listing.isdir];
fileCount = double(nnz(isFile));

end

function outputBytes = localCountOutputBytes(bundleRoot)

listing = dir(fullfile(bundleRoot, "**", "*"));

if isempty(listing)
    outputBytes = 0.0;
    return
end

isFile = ~[listing.isdir];
fileBytes = [listing(isFile).bytes];
outputBytes = double(sum(fileBytes));

end

function localWriteFailureBundle(bundleRoot, mainException)

try
    localEnsureFolder(bundleRoot);
    localWriteTextFile(fullfile(bundleRoot, "decision.txt"), "FAIL");
    localWriteTextFile(fullfile(bundleRoot, "failure_cause.txt"), ...
        string(mainException.message));
    localWriteTextFile(fullfile(bundleRoot, "next_branch.txt"), ...
        "fix_g45_runner_execution_failure");
catch
end

end

function result = localEmptyCaseResult()

result = struct();
result.SuiteId = "";
result.CaseDatasetId = "";
result.StageArtifactId = "";
result.RunTimestampZ = "";
result.BundleRoot = "";
result.GateDecision = "";
result.FailureCause = "";
result.NextBranch = "";
result.RecoveredTargetCount = NaN;
result.WeakTargetCount = NaN;
result.NotRecoveredTargetCount = NaN;
result.TimingSummaryTable = table();
result.PerformanceSummary = struct();
result.FigurePaths = strings(0, 1);

end
