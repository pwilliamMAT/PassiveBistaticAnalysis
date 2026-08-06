function results = runG5Mitigation(datasetId, repoRoot, options)
%RUNG5MITIGATION Execute the first G5 mitigation manual-review slice.
%
%   RESULTS = RUNG5MITIGATION() writes a G5 evidence bundle under:
%   artifacts/<datasetId>/G5_Mitigation/<runTimestampZ>/

arguments
    datasetId (1,1) string = "20260622T102123"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

stageArtifactId = "G5_Mitigation";
repoRoot = helperResolveRepoRoot(repoRoot);
datasetId = string(datasetId);
[g5Options, runnerOptions] = localResolveRunnerOptions(options);
runTimestampZ = string(datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyyMMdd'T'HHmmss'Z'"));
bundleRoot = fullfile(repoRoot, "artifacts", datasetId, stageArtifactId, ...
    runTimestampZ);
figureRoot = fullfile(bundleRoot, "figures");

fprintf("Running G5 Mitigation manual review for dataset %s\n", datasetId);
fprintf("Repository root:\t%s\n", repoRoot);

try
    localEnsureFolder(bundleRoot);
    localEnsureFolder(figureRoot);

    sessionData = loadIQData(datasetId, repoRoot, ...
        struct("IncludeSamples", true));
    collectionMetadataPath = fullfile(sessionData.DatasetRoot, ...
        "collection_metadata.json");
    collectionMetadataInfo = helperReadCollectionMetadata( ...
        collectionMetadataPath, datasetId);

    if isempty(fieldnames(runnerOptions.G3SyncResults))
        g3SyncResults = helperAnalyzeG3SyncCore(sessionData, ...
            collectionMetadataInfo, runnerOptions.G3Options);
    else
        g3SyncResults = runnerOptions.G3SyncResults;
    end

    if isempty(fieldnames(runnerOptions.G4Analysis))
        g4Analysis = helperAnalyzeG4PassiveBaselineMap(sessionData, ...
            collectionMetadataInfo, g3SyncResults, ...
            runnerOptions.G4Options);
    else
        g4Analysis = runnerOptions.G4Analysis;
    end

    analysis = helperAnalyzeG5Mitigation(sessionData, ...
        collectionMetadataInfo, g3SyncResults, g4Analysis, g5Options);
    reviewSummaryTable = localBuildReviewSummaryTable(analysis);
    configSnapshot = localBuildConfigSnapshot(datasetId, repoRoot, ...
        bundleRoot, runTimestampZ, analysis);
    metricsJson = localBuildMetricsJson(runTimestampZ, bundleRoot, ...
        analysis);

    localWriteRunnerArtifacts(bundleRoot, reviewSummaryTable, ...
        configSnapshot, metricsJson, analysis, g3SyncResults, g4Analysis);
    localWriteTextFile(fullfile(bundleRoot, "summary.md"), ...
        localBuildSummaryLines(bundleRoot, runTimestampZ, analysis, ...
        reviewSummaryTable));
    localWriteTextFile(fullfile(bundleRoot, "decision.txt"), ...
        analysis.GateDecision);
    localWriteTextFile(fullfile(bundleRoot, "next_branch.txt"), ...
        analysis.NextBranch);

    if analysis.GateDecision ~= "pass"
        localWriteTextFile(fullfile(bundleRoot, "failure_cause.txt"), ...
            localBuildFailureCauseLines(analysis));
    end

    figurePaths = localRenderFigures(analysis, figureRoot, ...
        runnerOptions.ShowFigures);
    results = localBuildResults(datasetId, stageArtifactId, ...
        runTimestampZ, bundleRoot, analysis, reviewSummaryTable, ...
        figurePaths);

    fprintf("Gate decision:\t%s\n", results.GateDecision);
    fprintf("Review status:\t%s\n", results.ReviewStatus);
    fprintf("Decision label:\t%s\n", results.DecisionLabel);
    fprintf("Formal gate emitted:\t%s\n", ...
        string(results.FormalGateDecisionEmitted));
    fprintf("Bundle root:\t%s\n", bundleRoot);
catch mainException
    localWriteFailureBundle(bundleRoot, mainException);
    rethrow(mainException);
end

end

function [g5Options, runnerOptions] = localResolveRunnerOptions(options)

g5Options = options;
runnerOptions = struct();
runnerOptions.ShowFigures = usejava("desktop");
runnerOptions.G3SyncResults = struct();
runnerOptions.G4Analysis = struct();
runnerOptions.G3Options = struct();
runnerOptions.G4Options = struct();

if isfield(g5Options, "ShowFigures")
    runnerOptions.ShowFigures = logical(g5Options.ShowFigures);
    g5Options = rmfield(g5Options, "ShowFigures");
end

if isfield(g5Options, "G3SyncResults")
    runnerOptions.G3SyncResults = g5Options.G3SyncResults;
    g5Options = rmfield(g5Options, "G3SyncResults");
end

if isfield(g5Options, "G4Analysis")
    runnerOptions.G4Analysis = g5Options.G4Analysis;
    g5Options = rmfield(g5Options, "G4Analysis");
end

if isfield(g5Options, "G3Options")
    runnerOptions.G3Options = g5Options.G3Options;
    g5Options = rmfield(g5Options, "G3Options");
end

if isfield(g5Options, "G4Options")
    runnerOptions.G4Options = g5Options.G4Options;
    g5Options = rmfield(g5Options, "G4Options");
end

if isfield(g5Options, "G5Options")
    explicitG5Options = g5Options.G5Options;
    g5Options = rmfield(g5Options, "G5Options");
    g5Options = localMergeStructs(g5Options, explicitG5Options);
end

end

function mergedStruct = localMergeStructs(baseStruct, overrideStruct)

mergedStruct = baseStruct;
overrideFields = fieldnames(overrideStruct);

for idx = 1:numel(overrideFields)
    mergedStruct.(overrideFields{idx}) = overrideStruct.(overrideFields{idx});
end

end

function results = localBuildResults(datasetId, stageArtifactId, ...
    runTimestampZ, bundleRoot, analysis, reviewSummaryTable, figurePaths)

results = struct();
results.DatasetId = datasetId;
results.StageId = stageArtifactId;
results.AnalysisStageId = string(analysis.AnalysisStageId);
results.RunTimestampZ = runTimestampZ;
results.BundleRoot = string(bundleRoot);
results.GateDecision = string(analysis.GateDecision);
results.ReviewStatus = string(analysis.ReviewStatus);
results.DecisionLabel = string(analysis.DecisionLabel);
results.DecisionRationale = string(analysis.DecisionRationale);
results.NextBranch = string(analysis.NextBranch);
results.FormalGateDecisionEmitted = ...
    logical(analysis.FormalGateDecisionEmitted);
results.G4OverallLabel = string(analysis.G4OverallLabel);
results.SelectedG4MapRows = height(analysis.SelectedG4MapRows);
results.ReviewSummaryTable = reviewSummaryTable;
results.MitigationCandidateTable = analysis.MitigationCandidateTable;
results.SuppressionSummaryTable = analysis.SuppressionSummaryTable;
results.ProtectedRegionRetentionTable = ...
    analysis.ProtectedRegionRetentionTable;
results.ResidualErrorPowerTable = analysis.ResidualErrorPowerTable;
results.DetectabilityProxyTable = analysis.DetectabilityProxyTable;
results.MitigationCausalAssessmentTable = ...
    analysis.MitigationCausalAssessmentTable;
results.AcquisitionImplicationTable = ...
    analysis.AcquisitionImplicationTable;
results.DecisionComparisonTable = analysis.DecisionComparisonTable;
results.UpstreamCaveatsCarriedForward = ...
    analysis.UpstreamCaveatsCarriedForward;
results.RequirementsCoverageTable = ...
    analysis.RequirementsCoverageTable;
results.Analysis = analysis;
results.FigurePaths = figurePaths;

end

function reviewSummary = localBuildReviewSummaryTable(analysis)

reviewSummary = table( ...
    string(analysis.StageId), ...
    string(analysis.AnalysisStageId), ...
    string(analysis.GateDecision), ...
    string(analysis.ReviewStatus), ...
    string(analysis.DecisionLabel), ...
    logical(analysis.FormalGateDecisionEmitted), ...
    string(analysis.G4OverallLabel), ...
    string(analysis.G4SceneObservabilityLabel), ...
    string(analysis.G4FullRateAuditAgreementLabel), ...
    height(analysis.SelectedG4MapRows), ...
    height(analysis.MitigationMetricTable), ...
    height(analysis.SuppressionSummaryTable), ...
    height(analysis.ProtectedRegionRetentionTable), ...
    height(analysis.ResidualErrorPowerTable), ...
    height(analysis.DetectabilityProxyTable), ...
    string(analysis.DecisionRationale), ...
    VariableNames = {'StageId', 'AnalysisStageId', 'GateDecision', ...
    'ReviewStatus', 'DecisionLabel', 'FormalGateDecisionEmitted', ...
    'G4OverallLabel', 'G4SceneObservabilityLabel', ...
    'G4FullRateAuditAgreementLabel', 'SelectedG4MapRows', ...
    'MitigationMetricRows', 'SuppressionSummaryRows', ...
    'ProtectedRegionRetentionRows', 'ResidualErrorPowerRows', ...
    'DetectabilityProxyRows', 'DecisionRationale'});

end

function configSnapshot = localBuildConfigSnapshot(datasetId, repoRoot, ...
    bundleRoot, runTimestampZ, analysis)

configSnapshot = struct();
configSnapshot.dataset_id = string(datasetId);
configSnapshot.stage_id = string(analysis.StageId);
configSnapshot.analysis_stage_id = string(analysis.AnalysisStageId);
configSnapshot.run_timestamp_z = string(runTimestampZ);
configSnapshot.repo_root = string(repoRoot);
configSnapshot.bundle_root = string(bundleRoot);
configSnapshot.analysis_scope = string(analysis.AnalysisScope);
configSnapshot.g4_overall_label = string(analysis.G4OverallLabel);
configSnapshot.gate_decision = string(analysis.GateDecision);
configSnapshot.review_status = string(analysis.ReviewStatus);
configSnapshot.decision_label = string(analysis.DecisionLabel);
configSnapshot.formal_gate_decision_emitted = ...
    logical(analysis.FormalGateDecisionEmitted);
configSnapshot.candidate_names = ...
    string(analysis.MitigationCandidateTable.CandidateName);
configSnapshot.review_cpi_labels = string(analysis.Options.ReviewCpiLabels);
configSnapshot.review_window_labels = ...
    string(analysis.Options.ReviewWindowLabels);
configSnapshot.review_repetitions = ...
    double(analysis.Options.ReviewRepetitions);
configSnapshot.map_decimation_factor = ...
    double(analysis.Options.MapDecimationFactor);
configSnapshot.map_sample_rate_hz = ...
    double(analysis.Options.MapSampleRateHz);
configSnapshot.matlab_version = string(version);
configSnapshot.matlab_release = string(version("-release"));
configSnapshot.computer = string(computer);

end

function metricsJson = localBuildMetricsJson(runTimestampZ, bundleRoot, ...
    analysis)

metricsJson = struct();
metricsJson.stage_id = string(analysis.StageId);
metricsJson.analysis_stage_id = string(analysis.AnalysisStageId);
metricsJson.run_timestamp_z = string(runTimestampZ);
metricsJson.bundle_root = string(bundleRoot);
metricsJson.gate_decision = string(analysis.GateDecision);
metricsJson.review_status = string(analysis.ReviewStatus);
metricsJson.decision_label = string(analysis.DecisionLabel);
metricsJson.formal_gate_decision_emitted = ...
    logical(analysis.FormalGateDecisionEmitted);
metricsJson.g4_overall_label = string(analysis.G4OverallLabel);
metricsJson.selected_g4_map_rows = height(analysis.SelectedG4MapRows);
metricsJson.mitigation_metric_rows = height(analysis.MitigationMetricTable);
metricsJson.required_candidate_count = ...
    height(analysis.MitigationCandidateTable);
metricsJson.causal_labels = table2struct( ...
    analysis.MitigationCausalAssessmentTable);
metricsJson.decision_comparison = table2struct( ...
    analysis.DecisionComparisonTable);

end

function localWriteRunnerArtifacts(bundleRoot, reviewSummaryTable, ...
    configSnapshot, metricsJson, analysis, g3SyncResults, g4Analysis)

try
    writetable(reviewSummaryTable, fullfile(bundleRoot, ...
        "review_summary.csv"));
    writetable(analysis.MitigationCandidateTable, fullfile(bundleRoot, ...
        "mitigation_candidate_table.csv"));
    writetable(analysis.MitigationMetricTable, fullfile(bundleRoot, ...
        "mitigation_metric_table.csv"));
    writetable(analysis.SuppressionSummaryTable, fullfile(bundleRoot, ...
        "suppression_summary_table.csv"));
    writetable(analysis.ProtectedRegionRetentionTable, fullfile( ...
        bundleRoot, "protected_region_retention_table.csv"));
    writetable(analysis.ProtectedRegionRetentionDetailTable, fullfile( ...
        bundleRoot, "protected_region_retention_detail_table.csv"));
    writetable(analysis.ResidualErrorPowerTable, fullfile(bundleRoot, ...
        "residual_error_power_table.csv"));
    writetable(analysis.DetectabilityProxyTable, fullfile(bundleRoot, ...
        "detectability_proxy_table.csv"));
    writetable(analysis.MitigationCausalAssessmentTable, fullfile( ...
        bundleRoot, "mitigation_causal_assessment_table.csv"));
    writetable(analysis.AcquisitionImplicationTable, fullfile( ...
        bundleRoot, "acquisition_implication_table.csv"));
    writetable(analysis.DecisionComparisonTable, fullfile(bundleRoot, ...
        "decision_comparison_table.csv"));
    writetable(analysis.UpstreamCaveatsCarriedForward, fullfile( ...
        bundleRoot, "upstream_caveats_carried_forward.csv"));
    writetable(analysis.RequirementsCoverageTable, fullfile(bundleRoot, ...
        "requirements_coverage.csv"));
catch writeException
    error("runG5Mitigation:WriteTableFailed", ...
        "Failed to write a G5 table artifact: %s", ...
        writeException.message);
end

localWriteJsonFile(fullfile(bundleRoot, "config_snapshot.json"), ...
    configSnapshot);
localWriteJsonFile(fullfile(bundleRoot, "metrics.json"), metricsJson);

try
    save(fullfile(bundleRoot, "metrics.mat"), "analysis", ...
        "g3SyncResults", "g4Analysis");
catch saveException
    error("runG5Mitigation:SaveMetricsFailed", ...
        "Failed to write G5 metrics.mat: %s", saveException.message);
end

end

function summaryLines = localBuildSummaryLines(bundleRoot, runTimestampZ, ...
    analysis, reviewSummaryTable)

summaryLines = [ ...
    "# G5 Mitigation Summary"; ...
    ""; ...
    sprintf("- Dataset: `%s`", analysis.DatasetId); ...
    "- Scope: `G5_Mitigation` first-slice manual-review runner"; ...
    "- Entry point: `runG5Mitigation`"; ...
    sprintf("- Run timestamp: `%s`", runTimestampZ); ...
    sprintf("- Bundle root: `%s`", bundleRoot); ...
    sprintf("- Gate decision: `%s`", analysis.GateDecision); ...
    sprintf("- Review status: `%s`", analysis.ReviewStatus); ...
    sprintf("- Decision label: `%s`", analysis.DecisionLabel); ...
    sprintf("- Formal gate decision emitted: `%s`", ...
    string(analysis.FormalGateDecisionEmitted)); ...
    sprintf("- G4 overall label: `%s`", analysis.G4OverallLabel); ...
    sprintf("- Selected G4 map rows: `%d`", ...
    height(analysis.SelectedG4MapRows)); ...
    sprintf("- Decision rationale: %s", ...
    analysis.DecisionRationale); ...
    ""; ...
    "## Review Summary"; ...
    sprintf("- Mitigation candidates: `%d`", ...
    height(analysis.MitigationCandidateTable)); ...
    sprintf("- Mitigation metric rows: `%d`", ...
    height(analysis.MitigationMetricTable)); ...
    sprintf("- Suppression summary rows: `%d`", ...
    height(analysis.SuppressionSummaryTable)); ...
    sprintf("- Protected-region rows: `%d`", ...
    height(analysis.ProtectedRegionRetentionTable)); ...
    sprintf("- Residual-error rows: `%d`", ...
    height(analysis.ResidualErrorPowerTable)); ...
    sprintf("- Detectability proxy rows: `%d`", ...
    height(analysis.DetectabilityProxyTable)); ...
    ""; ...
    "## Output Files"; ...
    "- `review_summary.csv`"; ...
    "- `mitigation_candidate_table.csv`"; ...
    "- `mitigation_metric_table.csv`"; ...
    "- `suppression_summary_table.csv`"; ...
    "- `protected_region_retention_table.csv`"; ...
    "- `protected_region_retention_detail_table.csv`"; ...
    "- `residual_error_power_table.csv`"; ...
    "- `detectability_proxy_table.csv`"; ...
    "- `mitigation_causal_assessment_table.csv`"; ...
    "- `acquisition_implication_table.csv`"; ...
    "- `decision_comparison_table.csv`"; ...
    "- `upstream_caveats_carried_forward.csv`"; ...
    "- `requirements_coverage.csv`"; ...
    "- `config_snapshot.json`"; ...
    "- `metrics.json`"; ...
    "- `metrics.mat`"; ...
    "- `decision.txt`"; ...
    "- `next_branch.txt`"; ...
    "- `figures/`"; ...
    ""; ...
    "## Review Table"; ...
    sprintf("- Rows: `%d`", height(reviewSummaryTable)) ...
    ];

end

function failureLines = localBuildFailureCauseLines(analysis)

failureLines = [ ...
    "Stage: G5_Mitigation"; ...
    sprintf("GateDecision: %s", analysis.GateDecision); ...
    sprintf("ReviewStatus: %s", analysis.ReviewStatus); ...
    sprintf("DecisionLabel: %s", analysis.DecisionLabel); ...
    sprintf("FormalGateDecisionEmitted: %s", ...
    string(analysis.FormalGateDecisionEmitted)); ...
    sprintf("Rationale: %s", analysis.DecisionRationale) ...
    ];

end

function figurePaths = localRenderFigures(analysis, figureRoot, showFigures)

figurePaths = strings(4, 1);
figurePaths(1) = fullfile(figureRoot, ...
    "figure_01_candidate_representative_maps.png");
figurePaths(2) = fullfile(figureRoot, ...
    "figure_02_direct_path_suppression.png");
figurePaths(3) = fullfile(figureRoot, ...
    "figure_03_protected_region_retention.png");
figurePaths(4) = fullfile(figureRoot, ...
    "figure_04_residual_error_power.png");

localRenderRepresentativeMapFigure(analysis.RepresentativeMaps, ...
    figurePaths(1), showFigures);
localRenderSuppressionFigure(analysis.SuppressionSummaryTable, ...
    figurePaths(2), showFigures);
localRenderProtectedRetentionFigure( ...
    analysis.ProtectedRegionRetentionTable, figurePaths(3), showFigures);
localRenderResidualErrorFigure(analysis.ResidualErrorPowerTable, ...
    figurePaths(4), showFigures);

end

function localRenderRepresentativeMapFigure(representativeMaps, ...
    figurePath, showFigures)

figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G5 Mitigation Candidate Representative Maps", ...
    "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
layoutHandle = tiledlayout(1, numel(representativeMaps), ...
    "TileSpacing", "compact", "Padding", "compact");

for idx = 1:numel(representativeMaps)
    nexttile(layoutHandle);
    mapInfo = representativeMaps(idx);
    imagesc(mapInfo.DisplayDelayAxis_samples, ...
        mapInfo.DisplayDopplerAxis_Hz, mapInfo.Map_dB);
    axis xy
    xlabel("Delay [samples]");
    ylabel("Doppler [Hz]");
    title(sprintf("G5 %s Map", string(mapInfo.CandidateName)));
    colorbar;
end

drawnow
localExportGraphics(layoutHandle, figurePath);
clear cleanupObject

end

function localRenderSuppressionFigure(summaryTable, figurePath, showFigures)

figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G5 Direct-Path Suppression", "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
bar(categorical(summaryTable.CandidateName), ...
    summaryTable.MedianDirectPathSuppression_dB);
grid on
xlabel("Candidate");
ylabel("Suppression [dB]");
title("G5 Median Direct-Path Suppression");
drawnow
localExportGraphics(gca, figurePath);
clear cleanupObject

end

function localRenderProtectedRetentionFigure(retentionTable, figurePath, ...
    showFigures)

figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G5 Protected-Region Retention", "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
bar(categorical(retentionTable.CandidateName), ...
    retentionTable.MedianProtectedRetentionRatio);
grid on
xlabel("Candidate");
ylabel("Retention ratio [linear]");
title("G5 Protected-Region Retention");
drawnow
localExportGraphics(gca, figurePath);
clear cleanupObject

end

function localRenderResidualErrorFigure(residualTable, figurePath, ...
    showFigures)

figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G5 Residual Error Power", "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
layoutHandle = tiledlayout(1, 1, "TileSpacing", "compact", ...
    "Padding", "compact");
nexttile(layoutHandle);
hold on
candidateNames = unique(residualTable.CandidateName, "stable");

for idx = 1:numel(candidateNames)
    subset = residualTable(residualTable.CandidateName == ...
        candidateNames(idx), :);
    plot(subset.MapRowId, subset.ResidualErrorPower_dB, "-o", ...
        "DisplayName", candidateNames(idx));
end

hold off
grid on
xlabel("Selected G4 map row");
ylabel("Residual error power [dB]");
title("G5 Residual Error Power Trend");
legend("Location", "best");
drawnow
localExportGraphics(layoutHandle, figurePath);
clear cleanupObject

end

function localExportGraphics(exportTarget, figurePath)

try
    exportgraphics(exportTarget, figurePath);
catch exportException
    error("runG5Mitigation:ExportFigureFailed", ...
        "Failed to export %s: %s", figurePath, ...
        exportException.message);
end

end

function visibility = localResolveFigureVisibility(showFigures)

if showFigures
    visibility = "on";
else
    visibility = "off";
end

end

function cleanupObject = localCreateFigureCleanup(figureHandle, showFigures)

if showFigures
    cleanupObject = [];
    return
end

cleanupObject = onCleanup(@() close(figureHandle));

end

function localEnsureFolder(folderPath)

if isfolder(folderPath)
    return
end

try
    mkdir(folderPath);
catch mkdirException
    error("runG5Mitigation:CreateFolderFailed", ...
        "Failed to create folder %s: %s", folderPath, ...
        mkdirException.message);
end

end

function localWriteTextFile(filePath, lines)

try
    fileIdentifier = fopen(filePath, "w");
catch openException
    error("runG5Mitigation:OpenTextFileFailed", ...
        "Failed to open %s for writing: %s", filePath, ...
        openException.message);
end

if fileIdentifier == -1
    error("runG5Mitigation:OpenTextFileFailed", ...
        "Failed to open %s for writing.", filePath);
end

cleanupObject = onCleanup(@() fclose(fileIdentifier));
lines = string(lines);

for idx = 1:numel(lines)
    fprintf(fileIdentifier, "%s\n", lines(idx));
end

clear cleanupObject

end

function localWriteJsonFile(filePath, inputStruct)

try
    jsonText = jsonencode(inputStruct, PrettyPrint = true);
catch encodeException
    error("runG5Mitigation:JsonEncodeFailed", ...
        "Failed to encode JSON for %s: %s", filePath, ...
        encodeException.message);
end

localWriteTextFile(filePath, jsonText);

end

function localWriteFailureBundle(bundleRoot, mainException)

if strlength(string(bundleRoot)) == 0
    return
end

if ~isfolder(bundleRoot)
    try
        mkdir(bundleRoot);
    catch
        return
    end
end

try
    localWriteTextFile(fullfile(bundleRoot, "summary.md"), [ ...
        "# G5 Mitigation Summary"; ...
        ""; ...
        "- Stage status: `failed`"; ...
        sprintf("- Failure message: `%s`", mainException.message); ...
        "- See `failure_cause.txt` for the captured exception details." ...
        ]);
catch
end

stackLines = strings(numel(mainException.stack), 1);

for idx = 1:numel(mainException.stack)
    stackFrame = mainException.stack(idx);
    stackLines(idx) = sprintf("%s (line %d)", ...
        string(stackFrame.name), double(stackFrame.line));
end

if isempty(stackLines)
    stackLines = "none";
end

try
    localWriteTextFile(fullfile(bundleRoot, "failure_cause.txt"), [ ...
        "Stage: G5_Mitigation"; ...
        sprintf("Identifier: %s", string(mainException.identifier)); ...
        sprintf("Message: %s", string(mainException.message)); ...
        "Stack:"; ...
        stackLines ...
        ]);
catch
end

end
