function reportData = helperBuildG45SyntheticTargetRecoveryReport( ...
    suiteId, repoRoot, options)
%HELPERBUILDG45SYNTHETICTARGETRECOVERYREPORT Load saved G4.5 report data.
%
%   REPORTDATA = HELPERBUILDG45SYNTHETICTARGETRECOVERYREPORT(SUITEID,
%   REPOROOT, OPTIONS) reads existing G4.5 Synthetic Target Recovery
%   artifacts and returns report-ready tables plus loaded analysis structs.

arguments
    suiteId (1,1) string = "g4_5_real_background_20260807T162306840"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

if ~isfield(options, "RunTimestampZ")
    options.RunTimestampZ = "latest";
end

if ~isfield(options, "CaseIds")
    options.CaseIds = localDefaultCaseIds();
end

repoRoot = helperResolveRepoRoot(repoRoot);
suiteId = string(suiteId);
caseIds = string(options.CaseIds(:));
stageArtifactId = "G4_5_SyntheticTargetRecovery";
runTimestampZ = localResolveRunTimestampZ(suiteId, repoRoot, ...
    stageArtifactId, caseIds, string(options.RunTimestampZ));
caseRecords = repmat(localEmptyCaseRecord(), numel(caseIds), 1);

for caseIndex = 1:numel(caseIds)
    caseRecords(caseIndex) = localBuildCaseRecord(suiteId, repoRoot, ...
        stageArtifactId, caseIds(caseIndex), runTimestampZ);
end

targetRecoveryTable = localVertcatCaseTables(caseRecords, ...
    "TargetRecoveryTable");
falseAlarmSummaryTable = localVertcatCaseTables(caseRecords, ...
    "FalseAlarmSummaryTable");
truthConventionAuditTable = localVertcatCaseTables(caseRecords, ...
    "TruthConventionAuditTable");
diagnosticInterpretationTable = localVertcatCaseTables(caseRecords, ...
    "DiagnosticInterpretationTable");

reportData = struct();
reportData.SuiteId = suiteId;
reportData.RepoRoot = string(repoRoot);
reportData.StageArtifactId = stageArtifactId;
reportData.RunTimestampZ = runTimestampZ;
reportData.CaseIds = caseIds;
reportData.CaseRecords = caseRecords;
reportData.SuiteSummaryTable = localBuildSuiteSummaryTable(caseRecords);
reportData.CaseQuestionTable = localBuildCaseQuestionTable(caseIds);
reportData.DecisionInterpretationTable = ...
    localBuildDecisionInterpretationTable(caseRecords);
reportData.TargetRecoveryTable = targetRecoveryTable;
reportData.FalseAlarmSummaryTable = falseAlarmSummaryTable;
reportData.TruthConventionAuditTable = truthConventionAuditTable;
reportData.DiagnosticInterpretationTable = diagnosticInterpretationTable;
reportData.ActiveIssueSourceTable = localBuildActiveIssueSourceTable( ...
    diagnosticInterpretationTable);
reportData.ThresholdDefinitionTable = localBuildThresholdDefinitionTable( ...
    caseRecords);
reportData.AssumptionsSummaryTable = localBuildAssumptionsSummaryTable( ...
    caseRecords);
reportData.AssumedAircraftPlausibilityTable = ...
    localBuildAssumedAircraftPlausibilityTable(caseRecords);
reportData.ArtifactPathTable = localBuildArtifactPathTable(caseRecords);

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

function caseRecord = localBuildCaseRecord(suiteId, repoRoot, ...
    stageArtifactId, caseDatasetId, runTimestampZ)

paths = localBuildCaseArtifactPaths(suiteId, repoRoot, stageArtifactId, ...
    caseDatasetId, runTimestampZ);
localAssertRequiredFiles(paths);
metricsMat = localLoadMetricsMat(paths.MetricsMatPath);
metricsJson = localReadJsonFile(paths.MetricsJsonPath);
truthJson = localReadJsonFile(paths.TruthJsonPath);
analysis = metricsMat.analysis;

if string(analysis.SuiteId) ~= suiteId
    error("helperBuildG45SyntheticTargetRecoveryReport:SuiteMismatch", ...
        "Loaded suite %s from %s, but expected suite %s.", ...
        string(analysis.SuiteId), paths.MetricsMatPath, suiteId);
end

if string(analysis.CaseDatasetId) ~= caseDatasetId
    error("helperBuildG45SyntheticTargetRecoveryReport:CaseMismatch", ...
        "Loaded case %s from %s, but expected case %s.", ...
        string(analysis.CaseDatasetId), paths.MetricsMatPath, caseDatasetId);
end

localValidateControlMapContract(analysis, paths.MetricsMatPath);

targetRecoveryTable = localReadCsvTable(paths.TargetRecoveryCsvPath);
falseAlarmSummaryTable = localReadCsvTable(paths.FalseAlarmCsvPath);
truthConventionAuditTable = localReadCsvTable(paths.TruthConventionCsvPath);
diagnosticInterpretationTable = localReadCsvTable( ...
    paths.DiagnosticInterpretationCsvPath);
targetRecoveryTable = localApplyAnalysisSchemaIfEmpty(targetRecoveryTable, ...
    analysis.TargetRecoveryTable);
falseAlarmSummaryTable = localApplyAnalysisSchemaIfEmpty( ...
    falseAlarmSummaryTable, analysis.FalseAlarmSummaryTable);
truthConventionAuditTable = localApplyAnalysisSchemaIfEmpty( ...
    truthConventionAuditTable, analysis.TruthConventionAuditTable);
diagnosticInterpretationTable = localApplyAnalysisSchemaIfEmpty( ...
    diagnosticInterpretationTable, analysis.DiagnosticInterpretationTable);
targetRecoveryTable = localSetTableProvenance(targetRecoveryTable, ...
    suiteId, caseDatasetId);
falseAlarmSummaryTable = localSetTableProvenance(falseAlarmSummaryTable, ...
    suiteId, caseDatasetId);
truthConventionAuditTable = localSetTableProvenance( ...
    truthConventionAuditTable, suiteId, caseDatasetId);
diagnosticInterpretationTable = localSetTableProvenance( ...
    diagnosticInterpretationTable, suiteId, caseDatasetId);

caseRecord = localEmptyCaseRecord();
caseRecord.SuiteId = suiteId;
caseRecord.CaseDatasetId = caseDatasetId;
caseRecord.StageArtifactId = stageArtifactId;
caseRecord.RunTimestampZ = runTimestampZ;
caseRecord.BundleRoot = paths.BundleRoot;
caseRecord.Analysis = analysis;
caseRecord.MetricsJson = metricsJson;
caseRecord.TruthJson = truthJson;
caseRecord.TargetRecoveryTable = targetRecoveryTable;
caseRecord.FalseAlarmSummaryTable = falseAlarmSummaryTable;
caseRecord.TruthConventionAuditTable = truthConventionAuditTable;
caseRecord.DiagnosticInterpretationTable = diagnosticInterpretationTable;
caseRecord.ArtifactPaths = paths;

if isfield(metricsMat, "timingSummaryTable")
    caseRecord.TimingSummaryTable = metricsMat.timingSummaryTable;
end

if isfield(metricsMat, "performanceSummary")
    caseRecord.PerformanceSummary = metricsMat.performanceSummary;
end

if isfield(metricsMat, "figurePaths")
    caseRecord.FigurePaths = string(metricsMat.figurePaths(:));
end

end

function runTimestampZ = localResolveRunTimestampZ(suiteId, repoRoot, ...
    stageArtifactId, caseIds, requestedRunTimestampZ)

requestedRunTimestampZ = string(requestedRunTimestampZ);

if requestedRunTimestampZ ~= "latest"
    runTimestampZ = requestedRunTimestampZ;
    return
end

commonRunNames = strings(0, 1);

for caseIndex = 1:numel(caseIds)
    stageRoot = fullfile(repoRoot, "artifacts", suiteId, caseIds(caseIndex), ...
        stageArtifactId);

    if ~isfolder(stageRoot)
        error("helperBuildG45SyntheticTargetRecoveryReport:MissingStageRoot", ...
            "Missing G4.5 artifact root for case %s at %s.", ...
            caseIds(caseIndex), stageRoot);
    end

    dirInfo = dir(stageRoot);
    dirInfo = dirInfo([dirInfo.isdir]);
    folderNames = string({dirInfo.name});
    folderNames = folderNames(folderNames ~= "." & folderNames ~= "..");
    isCompleteRun = false(numel(folderNames), 1);

    for folderIndex = 1:numel(folderNames)
        paths = localBuildCaseArtifactPaths(suiteId, repoRoot, ...
            stageArtifactId, caseIds(caseIndex), folderNames(folderIndex));
        isCompleteRun(folderIndex) = localHasRequiredFiles(paths);
    end

    completeRunNames = folderNames(isCompleteRun);

    if isempty(completeRunNames)
        error("helperBuildG45SyntheticTargetRecoveryReport:NoCompleteRuns", ...
            "No complete G4.5 artifact bundle was found for case %s.", ...
            caseIds(caseIndex));
    end

    if caseIndex == 1
        commonRunNames = completeRunNames;
    else
        commonRunNames = intersect(commonRunNames, completeRunNames);
    end
end

if isempty(commonRunNames)
    error("helperBuildG45SyntheticTargetRecoveryReport:NoCommonRun", ...
        "No common complete G4.5 run timestamp exists across the selected cases.");
end

commonRunNames = sort(commonRunNames(:));
runTimestampZ = commonRunNames(end);

end

function paths = localBuildCaseArtifactPaths(suiteId, repoRoot, ...
    stageArtifactId, caseDatasetId, runTimestampZ)

bundleRoot = fullfile(repoRoot, "artifacts", suiteId, caseDatasetId, ...
    stageArtifactId, runTimestampZ);
paths = struct();
paths.BundleRoot = string(bundleRoot);
paths.MetricsMatPath = string(fullfile(bundleRoot, "metrics.mat"));
paths.MetricsJsonPath = string(fullfile(bundleRoot, "metrics.json"));
paths.TargetRecoveryCsvPath = string(fullfile(bundleRoot, ...
    "target_recovery_table.csv"));
paths.FalseAlarmCsvPath = string(fullfile(bundleRoot, ...
    "false_alarm_summary_table.csv"));
paths.TruthConventionCsvPath = string(fullfile(bundleRoot, ...
    "truth_convention_audit_table.csv"));
paths.DiagnosticInterpretationCsvPath = string(fullfile(bundleRoot, ...
    "diagnostic_interpretation_table.csv"));
paths.SummaryMarkdownPath = string(fullfile(bundleRoot, "summary.md"));
paths.SummaryJsonPath = string(fullfile(bundleRoot, "summary.json"));
paths.TruthJsonPath = string(fullfile(repoRoot, suiteId, caseDatasetId, ...
    "truth", caseDatasetId + "_truth.json"));
paths.SuiteManifestPath = string(fullfile(repoRoot, suiteId, ...
    "synthetic_suite_manifest.json"));

end

function localAssertRequiredFiles(paths)

requiredPaths = localRequiredPaths(paths);

for fileIndex = 1:numel(requiredPaths)
    if ~isfile(requiredPaths(fileIndex))
        error("helperBuildG45SyntheticTargetRecoveryReport:MissingFile", ...
            "Missing required G4.5 report artifact: %s", ...
            requiredPaths(fileIndex));
    end
end

end

function hasRequiredFiles = localHasRequiredFiles(paths)

requiredPaths = localRequiredPaths(paths);
existsMask = false(numel(requiredPaths), 1);

for fileIndex = 1:numel(requiredPaths)
    existsMask(fileIndex) = isfile(requiredPaths(fileIndex));
end

hasRequiredFiles = all(existsMask);

end

function requiredPaths = localRequiredPaths(paths)

requiredPaths = [
    paths.MetricsMatPath
    paths.MetricsJsonPath
    paths.TargetRecoveryCsvPath
    paths.FalseAlarmCsvPath
    paths.TruthConventionCsvPath
    paths.DiagnosticInterpretationCsvPath
    paths.TruthJsonPath
    paths.SuiteManifestPath
    ];

end

function localValidateControlMapContract(analysis, metricsMatPath)

controlCaseId = "real_only_control";

if isfield(analysis, "Options") && ...
        isfield(analysis.Options, "ControlCaseId")
    controlCaseId = string(analysis.Options.ControlCaseId);
end

caseDatasetId = string(analysis.CaseDatasetId);

if caseDatasetId == controlCaseId
    return
end

if ~isfield(analysis, "ControlRepresentativeMaps") || ...
        isempty(analysis.ControlRepresentativeMaps)
    error("helperBuildG45SyntheticTargetRecoveryReport:MissingControlRepresentativeMaps", ...
        "G4.5 metrics.mat at %s does not contain analysis.ControlRepresentativeMaps for non-control case %s. Regenerate the canonical G4.5 suite with runG45SyntheticTargetRecovery before using matched before/after story plots.", ...
        metricsMatPath, caseDatasetId);
end

end

function metricsMat = localLoadMetricsMat(metricsMatPath)

try
    metricsMat = load(metricsMatPath);
catch loadException
    error("helperBuildG45SyntheticTargetRecoveryReport:LoadMatFailed", ...
        "Failed to load %s: %s", metricsMatPath, loadException.message);
end

if ~isfield(metricsMat, "analysis")
    error("helperBuildG45SyntheticTargetRecoveryReport:MissingAnalysis", ...
        "metrics.mat at %s does not contain variable analysis.", ...
        metricsMatPath);
end

end

function decodedJson = localReadJsonFile(jsonPath)

try
    jsonText = fileread(jsonPath);
    decodedJson = jsondecode(jsonText);
catch jsonException
    error("helperBuildG45SyntheticTargetRecoveryReport:JsonReadFailed", ...
        "Failed to read JSON artifact %s: %s", jsonPath, ...
        jsonException.message);
end

end

function outputTable = localReadCsvTable(csvPath)

try
    importOptions = detectImportOptions(csvPath, FileType="text", ...
        Delimiter=",", TextType="string");
    outputTable = readtable(csvPath, importOptions);
catch csvException
    error("helperBuildG45SyntheticTargetRecoveryReport:CsvReadFailed", ...
        "Failed to read CSV artifact %s: %s", csvPath, ...
        csvException.message);
end

outputTable = localNormalizeTextVariables(outputTable);

end

function outputTable = localApplyAnalysisSchemaIfEmpty(inputTable, ...
    analysisTable)

outputTable = inputTable;

if height(inputTable) > 0
    return
end

if istable(analysisTable)
    outputTable = analysisTable;
end

end

function outputTable = localNormalizeTextVariables(inputTable)

outputTable = inputTable;
variableNames = string(outputTable.Properties.VariableNames);

for variableIndex = 1:numel(variableNames)
    variableValue = outputTable.(variableNames(variableIndex));

    if iscellstr(variableValue) || isstring(variableValue)
        outputTable.(variableNames(variableIndex)) = string(variableValue);
    elseif iscategorical(variableValue)
        outputTable.(variableNames(variableIndex)) = string(variableValue);
    elseif ischar(variableValue)
        outputTable.(variableNames(variableIndex)) = string(variableValue);
    end
end

end

function outputTable = localSetTableProvenance(inputTable, suiteId, ...
    caseDatasetId)

outputTable = inputTable;
rowCount = height(outputTable);

if ismember("SuiteId", string(outputTable.Properties.VariableNames))
    outputTable.SuiteId = string(outputTable.SuiteId);
else
    outputTable.SuiteId = repmat(suiteId, rowCount, 1);
end

if ismember("CaseDatasetId", string(outputTable.Properties.VariableNames))
    outputTable.CaseDatasetId = string(outputTable.CaseDatasetId);
else
    outputTable.CaseDatasetId = repmat(caseDatasetId, rowCount, 1);
end

variableNames = string(outputTable.Properties.VariableNames);
frontNames = ["SuiteId", "CaseDatasetId"];
frontNames = frontNames(ismember(frontNames, variableNames));
otherNames = variableNames(~ismember(variableNames, frontNames));
outputTable = outputTable(:, [frontNames, otherNames]);

end

function combinedTable = localVertcatCaseTables(caseRecords, tableFieldName)

tableList = cell(numel(caseRecords), 1);

for caseIndex = 1:numel(caseRecords)
    tableList{caseIndex} = caseRecords(caseIndex).(tableFieldName);
end

combinedTable = vertcat(tableList{:});

end

function summaryTable = localBuildSuiteSummaryTable(caseRecords)

caseCount = numel(caseRecords);
caseDatasetId = strings(caseCount, 1);
gateDecision = strings(caseCount, 1);
expectedTargetCount = zeros(caseCount, 1);
recoveredTargetCount = zeros(caseCount, 1);
weakTargetCount = zeros(caseCount, 1);
notRecoveredTargetCount = zeros(caseCount, 1);
bestProminence_dB = NaN(caseCount, 1);
bestRobustZ = NaN(caseCount, 1);
centerRecoveryStatus = strings(caseCount, 1);
centerControlLift_dB = NaN(caseCount, 1);
centerControlFalseAlarmStatus = strings(caseCount, 1);
activeIssueSources = strings(caseCount, 1);
rangeDopplerMapCount = zeros(caseCount, 1);
bundleRoot = strings(caseCount, 1);

for caseIndex = 1:caseCount
    analysis = caseRecords(caseIndex).Analysis;
    targetSummary = analysis.TargetSummary;
    caseDatasetId(caseIndex) = caseRecords(caseIndex).CaseDatasetId;
    gateDecision(caseIndex) = string(analysis.GateDecision);
    expectedTargetCount(caseIndex) = ...
        double(targetSummary.ExpectedTargetCount);
    recoveredTargetCount(caseIndex) = ...
        double(targetSummary.RecoveredTargetCount);
    weakTargetCount(caseIndex) = double(targetSummary.WeakTargetCount);
    notRecoveredTargetCount(caseIndex) = ...
        double(targetSummary.NotRecoveredTargetCount);
    bestProminence_dB(caseIndex) = ...
        double(targetSummary.BestProminence_dB);
    bestRobustZ(caseIndex) = double(targetSummary.BestRobustZ);
    [centerRecoveryStatus(caseIndex), centerControlLift_dB(caseIndex), ...
        centerControlFalseAlarmStatus(caseIndex)] = localCenterSummary( ...
        caseRecords(caseIndex).TargetRecoveryTable);
    activeIssueSources(caseIndex) = localJoinActiveIssueSources( ...
        caseRecords(caseIndex).DiagnosticInterpretationTable);
    rangeDopplerMapCount(caseIndex) = ...
        double(numel(analysis.RepresentativeMaps));
    bundleRoot(caseIndex) = caseRecords(caseIndex).BundleRoot;
end

summaryTable = table(caseDatasetId, gateDecision, expectedTargetCount, ...
    recoveredTargetCount, weakTargetCount, notRecoveredTargetCount, ...
    bestProminence_dB, bestRobustZ, centerRecoveryStatus, ...
    centerControlLift_dB, centerControlFalseAlarmStatus, ...
    activeIssueSources, rangeDopplerMapCount, bundleRoot, ...
    VariableNames={'CaseDatasetId', 'GateDecision', ...
    'ExpectedTargetCount', 'RecoveredTargetCount', 'WeakTargetCount', ...
    'NotRecoveredTargetCount', 'BestProminence_dB', 'BestRobustZ', ...
    'CenterRecoveryStatus', 'CenterControlLift_dB', ...
    'CenterControlFalseAlarmStatus', 'ActiveIssueSources', ...
    'RangeDopplerMapCount', 'BundleRoot'});

end

function questionTable = localBuildCaseQuestionTable(caseIds)

caseDatasetId = string(caseIds(:));
syntheticRecoveryQuestion = strings(numel(caseDatasetId), 1);
passWarnMeaning = strings(numel(caseDatasetId), 1);

for caseIndex = 1:numel(caseDatasetId)
    [syntheticRecoveryQuestion(caseIndex), passWarnMeaning(caseIndex)] = ...
        localCaseQuestion(caseDatasetId(caseIndex));
end

questionTable = table(caseDatasetId, syntheticRecoveryQuestion, ...
    passWarnMeaning, VariableNames={'CaseDatasetId', ...
    'SyntheticRecoveryQuestion', 'PassWarnMeaning'});

end

function interpretationTable = localBuildDecisionInterpretationTable( ...
    caseRecords)

caseCount = numel(caseRecords);
caseDatasetId = strings(caseCount, 1);
gateDecision = strings(caseCount, 1);
decisionRationale = strings(caseCount, 1);
activeIssueSources = strings(caseCount, 1);

for caseIndex = 1:caseCount
    caseDatasetId(caseIndex) = caseRecords(caseIndex).CaseDatasetId;
    gateDecision(caseIndex) = string(caseRecords(caseIndex).Analysis.GateDecision);
    decisionRationale(caseIndex) = localDecisionRationale( ...
        caseRecords(caseIndex));
    activeIssueSources(caseIndex) = localJoinActiveIssueSources( ...
        caseRecords(caseIndex).DiagnosticInterpretationTable);
end

interpretationTable = table(caseDatasetId, gateDecision, ...
    decisionRationale, activeIssueSources, ...
    VariableNames={'CaseDatasetId', 'GateDecision', ...
    'DecisionRationale', 'ActiveIssueSources'});

end

function activeIssueSourceTable = localBuildActiveIssueSourceTable( ...
    diagnosticInterpretationTable)

if isempty(diagnosticInterpretationTable)
    activeIssueSourceTable = diagnosticInterpretationTable;
    return
end

activeMask = localActiveMask(diagnosticInterpretationTable.Active);
activeIssueSourceTable = diagnosticInterpretationTable(activeMask, :);
preferredNames = ["SuiteId", "CaseDatasetId", "IssueSource", "Severity", ...
    "Evidence", "RecommendedBranch"];
preferredNames = preferredNames(ismember(preferredNames, ...
    string(activeIssueSourceTable.Properties.VariableNames)));
activeIssueSourceTable = activeIssueSourceTable(:, preferredNames);

end

function thresholdTable = localBuildThresholdDefinitionTable(caseRecords)

options = caseRecords(1).Analysis.Options;
thresholdId = [
    "RECOVERED"
    "WEAK_RECOVERY"
    "NOT_RECOVERED"
    "LocalProminence_dB"
    "RobustZ"
    "ControlLift_dB"
    "AssociationTolerance"
    "ControlFalseAlarmStatus"
    ];
definition = [
    string(sprintf("Pass when local prominence >= %.1f [dB], robust Z >= %.1f, control lift >= %.1f [dB], and the association is within tolerance.", options.PassProminence_dB, options.PassRobustZ, options.MinControlLiftForPass_dB))
    string(sprintf("Warn when local prominence >= %.1f [dB] and robust Z >= %.1f but one or more pass margins, usually control lift, is insufficient.", options.WarnProminence_dB, options.WarnRobustZ))
    "Target association did not meet warn-level local prominence, robust Z, or tolerance requirements."
    "Target-bin peak minus robust local background median."
    "Robust local target score using median absolute deviation scaling."
    string(sprintf("Synthetic target local prominence minus pre-injection real-background prominence; pass policy requires >= %.1f [dB].", options.MinControlLiftForPass_dB))
    string(sprintf("Association must be within %.1f map bins in delay and %.1f [Hz] in Doppler.", options.DelayToleranceMapBins, options.DopplerTolerance_Hz))
    "Negative-control probe status; warn-level or pass-level control responses caveat threshold policy."
    ];
units = [
    "categorical"
    "categorical"
    "categorical"
    "dB"
    "robust z-score"
    "dB"
    "map bins and Hz"
    "categorical"
    ];
sourceFields = [
    "RecoveryStatus, ThresholdDecision"
    "RecoveryStatus, ThresholdDecision"
    "RecoveryStatus, ThresholdDecision"
    "LocalProminence_dB"
    "RobustZ"
    "ControlLift_dB"
    "DelayToleranceMapBins, DopplerTolerance_Hz"
    "ControlFalseAlarmStatus, FalseAlarmStatus"
    ];

thresholdTable = table(thresholdId, definition, units, sourceFields, ...
    VariableNames={'ThresholdId', 'Definition', 'Units', 'SourceFields'});

end

function assumptionsSummaryTable = localBuildAssumptionsSummaryTable( ...
    caseRecords)

assumptionsSummaryTable = table(Size = [0 17], VariableTypes = ...
    ["string", "string", "string", "string", "string", "string", ...
    "string", "string", "double", "double", "double", "double", ...
    "double", "double", "double", "string", "string"], ...
    VariableNames = {'SuiteId', 'CaseDatasetId', 'TargetId', ...
    'Callsign', 'AdsbSourceId', 'TruthSourceMode', 'TxLla_deg_m', ...
    'RxLla_deg_m', 'TruthTime_s', 'ExpectedDelay_s', ...
    'ExpectedBistaticDoppler_Hz', 'ExpectedBistaticRange_m', ...
    'ExpectedBistaticRangeRate_mps', 'EchoGain_dB', ...
    'TargetPowerRelativeToBackground_dB', 'UnavailableAssumptions', ...
    'SourceTruthJsonPath'});

unavailableAssumptions = "calibrated bistatic RCS; " + ...
    "instantaneous target LLA; instantaneous target 3D velocity";

for caseIndex = 1:numel(caseRecords)
    truthJson = caseRecords(caseIndex).TruthJson;
    targetStruct = localResolveTruthTargets(truthJson);

    if isempty(targetStruct)
        continue
    end

    for targetIndex = 1:numel(targetStruct)
        target = targetStruct(targetIndex);
        targetId = localStringField(target, "target_id", ...
            "target_" + string(targetIndex));
        [truthTime_s, truthIndex] = localRepresentativeTruthIndex( ...
            target, caseRecords(caseIndex).TargetRecoveryTable, targetId);
        expectedDelay_s = localNumericVectorValue(target, ...
            "expected_delay_s", truthIndex);
        expectedDoppler_Hz = localNumericVectorValue(target, ...
            "expected_bistatic_doppler_hz", truthIndex);
        expectedRange_m = localNumericVectorValue(target, ...
            "expected_bistatic_range_m", truthIndex);
        expectedRangeRate_mps = localNumericVectorValue(target, ...
            "expected_bistatic_range_rate_mps", truthIndex);
        echoGain_dB = localNestedDoubleField(target, ...
            ["echo_strength_parameters", "echo_gain_db"], NaN);
        targetPowerRelativeToBackground_dB = localDoubleField(target, ...
            "target_power_relative_to_background_db", NaN);
        newRow = table( ...
            string(caseRecords(caseIndex).SuiteId), ...
            string(caseRecords(caseIndex).CaseDatasetId), ...
            string(targetId), ...
            localStringField(target, "callsign", ""), ...
            localStringField(target, "adsb_source_id_or_track_id", ""), ...
            localStringField(truthJson, "truth_source_mode", ""), ...
            localVectorToText(localNumericVectorField(truthJson, ...
            "tx_lla_deg_m")), ...
            localVectorToText(localNumericVectorField(truthJson, ...
            "rx_lla_deg_m")), ...
            double(truthTime_s), ...
            double(expectedDelay_s), ...
            double(expectedDoppler_Hz), ...
            double(expectedRange_m), ...
            double(expectedRangeRate_mps), ...
            double(echoGain_dB), ...
            double(targetPowerRelativeToBackground_dB), ...
            unavailableAssumptions, ...
            string(caseRecords(caseIndex).ArtifactPaths.TruthJsonPath), ...
            VariableNames = assumptionsSummaryTable.Properties.VariableNames);
        assumptionsSummaryTable = [assumptionsSummaryTable; newRow]; %#ok<AGROW>
    end
end

end

function assumedAircraftPlausibilityTable = ...
    localBuildAssumedAircraftPlausibilityTable(caseRecords)

assumedAircraftPlausibilityTable = ...
    helperComputeG45AssumedAircraftEchoPlausibility();

for caseIndex = 1:numel(caseRecords)
    truthJson = caseRecords(caseIndex).TruthJson;
    targetStruct = localResolveTruthTargets(truthJson);

    if isempty(targetStruct)
        continue
    end

    txLla_deg_m = localNumericVectorField(truthJson, "tx_lla_deg_m");
    rxLla_deg_m = localNumericVectorField(truthJson, "rx_lla_deg_m");
    centerFrequency_Hz = localDoubleField(truthJson, ...
        "center_frequency_hz", NaN);

    for targetIndex = 1:numel(targetStruct)
        target = targetStruct(targetIndex);
        targetId = localStringField(target, "target_id", ...
            "target_" + string(targetIndex));
        [~, truthIndex] = localRepresentativeTruthIndex( ...
            target, caseRecords(caseIndex).TargetRecoveryTable, targetId);
        expectedRange_m = localNumericVectorValue(target, ...
            "expected_bistatic_range_m", truthIndex);
        targetPowerRelativeToBackground_dB = localDoubleField(target, ...
            "target_power_relative_to_background_db", NaN);
        plausibilityOptions = struct();
        plausibilityOptions.CaseDatasetId = ...
            string(caseRecords(caseIndex).CaseDatasetId);
        plausibilityOptions.TargetId = string(targetId);
        plausibilityOptions.AdsbSourceId = localStringField(target, ...
            "adsb_source_id_or_track_id", "");
        plausibilityOptions.Callsign = localStringField(target, ...
            "callsign", "");
        plausibilityOptions.SyntheticTargetPowerRelativeToBackground_dB = ...
            double(targetPowerRelativeToBackground_dB);
        targetPlausibilityTable = ...
            helperComputeG45AssumedAircraftEchoPlausibility( ...
            txLla_deg_m, rxLla_deg_m, centerFrequency_Hz, ...
            expectedRange_m, plausibilityOptions);
        assumedAircraftPlausibilityTable = [ ...
            assumedAircraftPlausibilityTable; ...
            targetPlausibilityTable]; %#ok<AGROW>
    end
end

end

function targetStruct = localResolveTruthTargets(truthJson)

targetStruct = repmat(struct(), 0, 1);

if ~isstruct(truthJson) || ~isfield(truthJson, "targets")
    return
end

targetValue = truthJson.targets;

if isstruct(targetValue)
    targetStruct = targetValue(:);
end

end

function [truthTime_s, truthIndex] = localRepresentativeTruthIndex( ...
    target, targetRecoveryTable, targetId)

truthTimes = localNestedNumericVector(target, ...
    ["cpi_or_time_windows_used", "truth_time_s"]);
truthTime_s = NaN;
truthIndex = 1;

if istable(targetRecoveryTable) && ~isempty(targetRecoveryTable) && ...
        ismember("TargetId", string(targetRecoveryTable.Properties.VariableNames))
    targetMask = string(targetRecoveryTable.TargetId) == string(targetId);
    rowMask = targetMask;

    if ismember("WindowLabel", string(targetRecoveryTable.Properties.VariableNames))
        centerMask = targetMask & string(targetRecoveryTable.WindowLabel) == ...
            "center";

        if any(centerMask)
            rowMask = centerMask;
        end
    end

    selectedRows = targetRecoveryTable(rowMask, :);

    if ~isempty(selectedRows) && ismember("TruthTime_s", ...
            string(selectedRows.Properties.VariableNames))
        truthTime_s = double(selectedRows.TruthTime_s(1));
    end
end

if isempty(truthTimes)
    return
end

if isfinite(truthTime_s)
    [~, truthIndex] = min(abs(truthTimes - truthTime_s));
else
    truthIndex = max(1, ceil(numel(truthTimes) ./ 2));
    truthTime_s = truthTimes(truthIndex);
end

end

function value = localNumericVectorValue(inputStruct, fieldName, index)

values = localNumericVectorField(inputStruct, fieldName);

if isempty(values)
    value = NaN;
    return
end

index = max(1, min(numel(values), double(index)));
value = values(index);

end

function values = localNestedNumericVector(inputStruct, fieldPath)

currentValue = inputStruct;

for fieldIndex = 1:numel(fieldPath)
    fieldName = char(fieldPath(fieldIndex));

    if ~isstruct(currentValue) || ~isfield(currentValue, fieldName)
        values = [];
        return
    end

    currentValue = currentValue.(fieldName);
end

values = localToNumericVector(currentValue);

end

function value = localNestedDoubleField(inputStruct, fieldPath, defaultValue)

currentValue = inputStruct;

for fieldIndex = 1:numel(fieldPath)
    fieldName = char(fieldPath(fieldIndex));

    if ~isstruct(currentValue) || ~isfield(currentValue, fieldName)
        value = defaultValue;
        return
    end

    currentValue = currentValue.(fieldName);
end

values = localToNumericVector(currentValue);

if isempty(values)
    value = defaultValue;
else
    value = values(1);
end

end

function values = localNumericVectorField(inputStruct, fieldName)

fieldName = char(fieldName);

if ~isstruct(inputStruct) || ~isfield(inputStruct, fieldName)
    values = [];
    return
end

values = localToNumericVector(inputStruct.(fieldName));

end

function value = localDoubleField(inputStruct, fieldName, defaultValue)

values = localNumericVectorField(inputStruct, fieldName);

if isempty(values)
    value = defaultValue;
else
    value = values(1);
end

end

function values = localToNumericVector(inputValue)

if isnumeric(inputValue)
    values = double(inputValue(:));
else
    values = [];
end

end

function textValue = localStringField(inputStruct, fieldName, defaultValue)

fieldName = char(fieldName);

if ~isstruct(inputStruct) || ~isfield(inputStruct, fieldName)
    textValue = string(defaultValue);
    return
end

fieldValue = inputStruct.(fieldName);

if isstring(fieldValue) || ischar(fieldValue)
    textValue = string(fieldValue);
elseif iscellstr(fieldValue)
    textValue = strjoin(string(fieldValue), ", ");
elseif isnumeric(fieldValue)
    textValue = strjoin(string(fieldValue(:).'), ", ");
else
    textValue = string(defaultValue);
end

end

function textValue = localVectorToText(values)

values = double(values(:));

if isempty(values)
    textValue = "";
else
    textValue = strjoin(compose("%.9g", values.'), ", ");
end
end

function artifactPathTable = localBuildArtifactPathTable(caseRecords)

caseCount = numel(caseRecords);
caseDatasetId = strings(caseCount, 1);
runTimestampZ = strings(caseCount, 1);
bundleRoot = strings(caseCount, 1);
metricsMatPath = strings(caseCount, 1);
metricsJsonPath = strings(caseCount, 1);
targetRecoveryCsvPath = strings(caseCount, 1);
falseAlarmCsvPath = strings(caseCount, 1);
truthConventionCsvPath = strings(caseCount, 1);
diagnosticInterpretationCsvPath = strings(caseCount, 1);
truthJsonPath = strings(caseCount, 1);
suiteManifestPath = strings(caseCount, 1);

for caseIndex = 1:caseCount
    paths = caseRecords(caseIndex).ArtifactPaths;
    caseDatasetId(caseIndex) = caseRecords(caseIndex).CaseDatasetId;
    runTimestampZ(caseIndex) = caseRecords(caseIndex).RunTimestampZ;
    bundleRoot(caseIndex) = paths.BundleRoot;
    metricsMatPath(caseIndex) = paths.MetricsMatPath;
    metricsJsonPath(caseIndex) = paths.MetricsJsonPath;
    targetRecoveryCsvPath(caseIndex) = paths.TargetRecoveryCsvPath;
    falseAlarmCsvPath(caseIndex) = paths.FalseAlarmCsvPath;
    truthConventionCsvPath(caseIndex) = paths.TruthConventionCsvPath;
    diagnosticInterpretationCsvPath(caseIndex) = ...
        paths.DiagnosticInterpretationCsvPath;
    truthJsonPath(caseIndex) = paths.TruthJsonPath;
    suiteManifestPath(caseIndex) = paths.SuiteManifestPath;
end

artifactPathTable = table(caseDatasetId, runTimestampZ, bundleRoot, ...
    metricsMatPath, metricsJsonPath, targetRecoveryCsvPath, ...
    falseAlarmCsvPath, truthConventionCsvPath, ...
    diagnosticInterpretationCsvPath, truthJsonPath, suiteManifestPath, ...
    VariableNames={'CaseDatasetId', 'RunTimestampZ', 'BundleRoot', ...
    'MetricsMatPath', 'MetricsJsonPath', 'TargetRecoveryCsvPath', ...
    'FalseAlarmCsvPath', 'TruthConventionCsvPath', ...
    'DiagnosticInterpretationCsvPath', 'TruthJsonPath', ...
    'SuiteManifestPath'});

end

function [centerRecoveryStatus, centerControlLift_dB, ...
    centerControlFalseAlarmStatus] = localCenterSummary(targetRecoveryTable)

centerRecoveryStatus = "";
centerControlLift_dB = NaN;
centerControlFalseAlarmStatus = "";

if isempty(targetRecoveryTable) || ~ismember("WindowLabel", ...
        string(targetRecoveryTable.Properties.VariableNames))
    return
end

centerRows = targetRecoveryTable(targetRecoveryTable.WindowLabel == ...
    "center", :);

if isempty(centerRows)
    return
end

statusLines = centerRows.TargetId + ":" + centerRows.RecoveryStatus;
centerRecoveryStatus = strjoin(statusLines, ", ");
centerControlLift_dB = min(centerRows.ControlLift_dB);
centerControlFalseAlarmStatus = strjoin(unique( ...
    centerRows.ControlFalseAlarmStatus, "stable"), ", ");

end

function joinedIssueSources = localJoinActiveIssueSources( ...
    diagnosticInterpretationTable)

joinedIssueSources = "";

if isempty(diagnosticInterpretationTable) || ~ismember("Active", ...
        string(diagnosticInterpretationTable.Properties.VariableNames))
    return
end

activeMask = localActiveMask(diagnosticInterpretationTable.Active);

if ~any(activeMask)
    return
end

joinedIssueSources = strjoin(string( ...
    diagnosticInterpretationTable.IssueSource(activeMask)), ", ");

end

function activeMask = localActiveMask(activeValues)

if islogical(activeValues)
    activeMask = activeValues;
elseif isnumeric(activeValues)
    activeMask = activeValues ~= 0;
else
    activeStrings = lower(string(activeValues));
    activeMask = activeStrings == "true" | activeStrings == "1";
end

activeMask = activeMask(:);

end

function [syntheticRecoveryQuestion, passWarnMeaning] = localCaseQuestion( ...
    caseDatasetId)

switch string(caseDatasetId)
    case "real_only_control"
        syntheticRecoveryQuestion = ...
            "Does the real RF background alone create target-like responses at synthetic truth probe points?";
        passWarnMeaning = ...
            "CONTROL_PASS means the control remains usable as the false-alarm reference.";
    case "easy_single_target"
        syntheticRecoveryQuestion = ...
            "Can the baseline G4 map recover a high-margin injected target in real background?";
        passWarnMeaning = ...
            "PASS requires at least one pass-level recovery with enough lift over the control.";
    case "medium_single_target"
        syntheticRecoveryQuestion = ...
            "Does recovery persist after reducing synthetic target strength to a moderate case?";
        passWarnMeaning = ...
            "PASS means a center recovery remains above pass thresholds, with weaker windows kept as caveats.";
    case "hard_single_target"
        syntheticRecoveryQuestion = ...
            "Where does recovery become threshold-sensitive for a weak single target?";
        passWarnMeaning = ...
            "WARN is expected when the target localizes but lacks control lift or full pass margin.";
    case "marginal_single_target"
        syntheticRecoveryQuestion = ...
            "Does the weakest single-target case show only sensitivity-limited evidence?";
        passWarnMeaning = ...
            "WARN means weak localization was seen without enough separation from the control.";
    case "multi_target"
        syntheticRecoveryQuestion = ...
            "Can the G4.5 association logic recover more than one injected target in the same scene?";
        passWarnMeaning = ...
            "PASS means each target ID has a pass-level recovered row even if some windows remain caveated.";
    otherwise
        syntheticRecoveryQuestion = ...
            "What recovery evidence is present for this selected G4.5 case?";
        passWarnMeaning = ...
            "Use the target recovery rows and diagnostic interpretation table for the case decision.";
end

end

function decisionRationale = localDecisionRationale(caseRecord)

caseDatasetId = caseRecord.CaseDatasetId;
analysis = caseRecord.Analysis;
targetSummary = analysis.TargetSummary;
[centerRecoveryStatus, centerControlLift_dB, ...
    centerControlFalseAlarmStatus] = localCenterSummary( ...
    caseRecord.TargetRecoveryTable);

switch string(caseDatasetId)
    case "real_only_control"
        decisionRationale = ...
            "CONTROL_PASS because the real-only case is the negative control and has no injected target recovery count.";
    case "easy_single_target"
        decisionRationale = string(sprintf("PASS because the target reaches pass-level recovery; best prominence is %.2f [dB] and best robust Z is %.2f.", targetSummary.BestProminence_dB, targetSummary.BestRobustZ));
    case "medium_single_target"
        decisionRationale = string(sprintf("PASS because the center row is recovered with %.2f [dB] minimum center control lift; late evidence drops to weak recovery but does not overturn target-level recovery.", centerControlLift_dB));
    case "hard_single_target"
        decisionRationale = string(sprintf("WARN because the center row is %s, control lift is %.2f [dB], and the control status is %s.", centerRecoveryStatus, centerControlLift_dB, centerControlFalseAlarmStatus));
    case "marginal_single_target"
        decisionRationale = string(sprintf("WARN because only weak center recovery is present, with %.2f [dB] center control lift and sensitivity-limited diagnostics active.", centerControlLift_dB));
    case "multi_target"
        decisionRationale = string(sprintf("PASS because recovered target count is %.0f; both target IDs recover at center even though early or late rows remain caveated.", targetSummary.RecoveredTargetCount));
    otherwise
        decisionRationale = string(sprintf("Decision %s with %.0f recovered, %.0f weak, and %.0f not-recovered target counts.", analysis.GateDecision, targetSummary.RecoveredTargetCount, targetSummary.WeakTargetCount, targetSummary.NotRecoveredTargetCount));
end

end

function caseRecord = localEmptyCaseRecord()

caseRecord = struct();
caseRecord.SuiteId = "";
caseRecord.CaseDatasetId = "";
caseRecord.StageArtifactId = "";
caseRecord.RunTimestampZ = "";
caseRecord.BundleRoot = "";
caseRecord.Analysis = struct();
caseRecord.MetricsJson = struct();
caseRecord.TruthJson = struct();
caseRecord.TargetRecoveryTable = table();
caseRecord.FalseAlarmSummaryTable = table();
caseRecord.TruthConventionAuditTable = table();
caseRecord.DiagnosticInterpretationTable = table();
caseRecord.TimingSummaryTable = table();
caseRecord.PerformanceSummary = struct();
caseRecord.FigurePaths = strings(0, 1);
caseRecord.ArtifactPaths = struct();

end
