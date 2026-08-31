function results = runG5MitigationDiagnosticStudy(datasetId, repoRoot, options)
%RUNG5MITIGATIONDIAGNOSTICSTUDY Run optional G5 diagnostic sidecar.

arguments
    datasetId (1,1) string = "20260622T102123"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

stageArtifactId = "G5_Mitigation_Diagnostic";
repoRoot = helperResolveRepoRoot(repoRoot);
datasetId = string(datasetId);
runnerOptions = localResolveRunnerOptions(options);
runTimestampZ = string(datetime("now", "TimeZone", "UTC", "Format", "yyyyMMdd'T'HHmmss'Z'"));
bundleRoot = fullfile(repoRoot, "artifacts", datasetId, stageArtifactId, runTimestampZ);
figureRoot = fullfile(bundleRoot, "figures");

fprintf("Running G5 Mitigation diagnostic study for dataset %s\n", datasetId);
fprintf("Repository root:\t%s\n", repoRoot);

try
    localEnsureFolder(bundleRoot);
    localEnsureFolder(figureRoot);
    sessionData = loadIQData(datasetId, repoRoot, struct("IncludeSamples", true));
    collectionMetadataInfo = helperReadCollectionMetadata(fullfile(sessionData.DatasetRoot, "collection_metadata.json"), datasetId);
    [g3SyncResults, g4Analysis, baseG5Analysis] = localResolveInputs(sessionData, collectionMetadataInfo, runnerOptions);

    diagnosticOptions = runnerOptions.DiagnosticOptions;

    if ~isempty(fieldnames(baseG5Analysis))
        diagnosticOptions.SourceG5Analysis = baseG5Analysis;
    end

    diagnosticAnalysis = helperAnalyzeG5MitigationDiagnosticStudy(sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, diagnosticOptions);
    reviewSummary = localBuildReviewSummary(diagnosticAnalysis);
    figurePaths = localRenderDiagnosticFigures(diagnosticAnalysis, figureRoot, runnerOptions.ShowFigures);
    localWriteArtifacts(bundleRoot, diagnosticAnalysis, reviewSummary, g3SyncResults, g4Analysis, baseG5Analysis, figurePaths);
    results = localBuildResults(datasetId, stageArtifactId, runTimestampZ, bundleRoot, diagnosticAnalysis, reviewSummary, figurePaths);

    try
        localPrintRunSummary(results, diagnosticAnalysis, figureRoot);
    catch printException
        localWriteTextFile(fullfile(bundleRoot, "console_output_warning.txt"), [ ...
            "G5 diagnostic completed, but command-window summary printing failed."; ...
            string(printException.message) ...
            ]);
    end
catch mainException
    localWriteFailureBundle(bundleRoot, mainException);
    rethrow(mainException);
end

end

function runnerOptions = localResolveRunnerOptions(options)

runnerOptions = struct();
runnerOptions.SourceG5BundleRoot = "";
runnerOptions.G3SyncResults = struct();
runnerOptions.G4Analysis = struct();
runnerOptions.G5Analysis = struct();
runnerOptions.G3Options = struct();
runnerOptions.G4Options = struct();
runnerOptions.DiagnosticOptions = struct();
runnerOptions.ShowFigures = usejava("desktop");

if isfield(options, "SourceG5BundleRoot")
    runnerOptions.SourceG5BundleRoot = string(options.SourceG5BundleRoot);
end

if isfield(options, "G3SyncResults")
    runnerOptions.G3SyncResults = options.G3SyncResults;
end

if isfield(options, "G4Analysis")
    runnerOptions.G4Analysis = options.G4Analysis;
end

if isfield(options, "G5Analysis")
    runnerOptions.G5Analysis = options.G5Analysis;
end

if isfield(options, "G3Options")
    runnerOptions.G3Options = options.G3Options;
end

if isfield(options, "G4Options")
    runnerOptions.G4Options = options.G4Options;
end

if isfield(options, "DiagnosticOptions")
    runnerOptions.DiagnosticOptions = options.DiagnosticOptions;
end

if isfield(options, "ShowFigures")
    runnerOptions.ShowFigures = logical(options.ShowFigures);
end

end

function [g3SyncResults, g4Analysis, baseG5Analysis] = localResolveInputs(sessionData, collectionMetadataInfo, runnerOptions)

g3SyncResults = runnerOptions.G3SyncResults;
g4Analysis = runnerOptions.G4Analysis;
baseG5Analysis = runnerOptions.G5Analysis;

if strlength(runnerOptions.SourceG5BundleRoot) > 0
    loadedBundle = localLoadSourceG5Bundle(runnerOptions.SourceG5BundleRoot);

    if isempty(fieldnames(g3SyncResults)) && isfield(loadedBundle, "g3SyncResults")
        g3SyncResults = loadedBundle.g3SyncResults;
    end

    if isempty(fieldnames(g4Analysis)) && isfield(loadedBundle, "g4Analysis")
        g4Analysis = loadedBundle.g4Analysis;
    end

    if isempty(fieldnames(baseG5Analysis)) && isfield(loadedBundle, "analysis")
        baseG5Analysis = loadedBundle.analysis;
    end
end

if isempty(fieldnames(g3SyncResults))
    g3SyncResults = helperAnalyzeG3SyncCore(sessionData, collectionMetadataInfo, runnerOptions.G3Options);
end

if isempty(fieldnames(g4Analysis))
    g4Analysis = helperAnalyzeG4PassiveBaselineMap(sessionData, collectionMetadataInfo, g3SyncResults, runnerOptions.G4Options);
end

end

function loadedBundle = localLoadSourceG5Bundle(sourceBundleRoot)

metricsPath = fullfile(sourceBundleRoot, "metrics.mat");

if ~isfile(metricsPath)
    error("runG5MitigationDiagnosticStudy:MissingSourceMetrics", "Could not find %s.", metricsPath);
end

try
    loadedBundle = load(metricsPath);
catch loadException
    error("runG5MitigationDiagnosticStudy:LoadSourceMetricsFailed", "Failed to load %s: %s", metricsPath, loadException.message);
end

end

function reviewSummary = localBuildReviewSummary(analysis)

conclusion = analysis.DiagnosticConclusionTable(1, :);
reviewSummary = table(string(analysis.StageId), string(analysis.AnalysisStageId), string(conclusion.PrimaryConclusionLabel), string(conclusion.SecondaryCaveatLabel), string(analysis.SourceG5DecisionLabel), string(analysis.SourceG4OverallLabel), height(analysis.ProfileSweepSummaryTable), height(analysis.ThresholdSensitivityTable), height(analysis.SignalDiagnosticTable), string(conclusion.RecommendedNextAction), VariableNames = {'StageId', 'AnalysisStageId', 'PrimaryConclusionLabel', 'SecondaryCaveatLabel', 'SourceG5DecisionLabel', 'SourceG4OverallLabel', 'ProfileSweepRows', 'ThresholdSensitivityRows', 'SignalDiagnosticRows', 'RecommendedNextAction'});

end

function localWriteArtifacts(bundleRoot, analysis, reviewSummary, g3SyncResults, g4Analysis, baseG5Analysis, figurePaths)

try
    writetable(reviewSummary, fullfile(bundleRoot, "review_summary.csv"));
    writetable(analysis.SourceGateSummaryTable, fullfile(bundleRoot, "source_gate_summary.csv"));
    writetable(analysis.DiagnosticConclusionTable, fullfile(bundleRoot, "diagnostic_conclusion_table.csv"));
    writetable(analysis.ProfileSweepSummaryTable, fullfile(bundleRoot, "profile_sweep_summary_table.csv"));
    writetable(analysis.ThresholdSensitivityTable, fullfile(bundleRoot, "threshold_sensitivity_table.csv"));
    writetable(analysis.SignalDiagnosticTable, fullfile(bundleRoot, "signal_diagnostic_table.csv"));
    writetable(analysis.AcquisitionImplicationTable, fullfile(bundleRoot, "acquisition_implication_table.csv"));
    writetable(analysis.UpstreamCaveatsCarriedForward, fullfile(bundleRoot, "upstream_caveats_carried_forward.csv"));
catch writeException
    error("runG5MitigationDiagnosticStudy:WriteTableFailed", "Failed to write a G5 diagnostic table: %s", writeException.message);
end

localWriteJsonFile(fullfile(bundleRoot, "metrics.json"), localBuildMetricsJson(analysis, bundleRoot, figurePaths));
localWriteTextFile(fullfile(bundleRoot, "summary.md"), localBuildSummaryLines(analysis, bundleRoot, figurePaths));
localWriteTextFile(fullfile(bundleRoot, "diagnostic_conclusion.txt"), analysis.DiagnosticConclusionTable.PrimaryConclusionLabel(1));
localWriteTextFile(fullfile(bundleRoot, "next_branch.txt"), "hold_at_g5_diagnostic_review");

try
    save(fullfile(bundleRoot, "metrics.mat"), "analysis", "g3SyncResults", "g4Analysis", "baseG5Analysis", "figurePaths");
catch saveException
    error("runG5MitigationDiagnosticStudy:SaveMetricsFailed", "Failed to write G5 diagnostic metrics.mat: %s", saveException.message);
end

end
function metricsJson = localBuildMetricsJson(analysis, bundleRoot, figurePaths)

conclusion = analysis.DiagnosticConclusionTable(1, :);
thresholdCounts = localThresholdPassCounts(analysis.ThresholdSensitivityTable);
metricsJson = struct();
metricsJson.stage_id = string(analysis.StageId);
metricsJson.bundle_root = string(bundleRoot);
metricsJson.primary_conclusion_label = string(conclusion.PrimaryConclusionLabel);
metricsJson.secondary_caveat_label = string(conclusion.SecondaryCaveatLabel);
metricsJson.best_profile_id = string(conclusion.BestProfileId);
metricsJson.best_candidate_name = string(conclusion.BestCandidateName);
metricsJson.best_direct_path_suppression_db = double(conclusion.BestDirectPathSuppression_dB);
metricsJson.best_scene_score_delta = double(conclusion.BestSceneScoreDelta);
metricsJson.best_off_origin_energy_fraction_delta = double(conclusion.BestOffOriginEnergyFractionDelta);
metricsJson.best_protected_retention_ratio = double(conclusion.BestProtectedRetentionRatio);
metricsJson.best_causal_label = string(conclusion.BestCausalLabel);
metricsJson.median_reference_surveillance_coherence = double(conclusion.MedianReferenceSurveillanceCoherence);
metricsJson.source_g5_decision_label = string(analysis.SourceG5DecisionLabel);
metricsJson.source_g4_overall_label = string(analysis.SourceG4OverallLabel);
metricsJson.formal_gate_decision_changed = logical(conclusion.FormalGateDecisionChanged);
metricsJson.profile_sweep_rows = height(analysis.ProfileSweepSummaryTable);
metricsJson.threshold_sensitivity_rows = height(analysis.ThresholdSensitivityTable);
metricsJson.signal_diagnostic_rows = height(analysis.SignalDiagnosticTable);
metricsJson.default_gate_reveal_count = thresholdCounts.DefaultGateRevealCount;
metricsJson.permissive_probe_reveal_count = thresholdCounts.PermissiveProbeRevealCount;
metricsJson.figure_paths = string(figurePaths);

end
function summaryLines = localBuildSummaryLines(analysis, bundleRoot, figurePaths)

conclusion = analysis.DiagnosticConclusionTable(1, :);
thresholdCounts = localThresholdPassCounts(analysis.ThresholdSensitivityTable);
summaryLines = [ ...
    "# G5 Mitigation Diagnostic Study"; ...
    ""; ...
    sprintf("- Dataset: `%s`", analysis.DatasetId); ...
    sprintf("- Bundle root: `%s`", bundleRoot); ...
    sprintf("- Primary conclusion: `%s`", conclusion.PrimaryConclusionLabel); ...
    sprintf("- Secondary caveat: `%s`", conclusion.SecondaryCaveatLabel); ...
    sprintf("- Source G5 decision label: `%s`", analysis.SourceG5DecisionLabel); ...
    sprintf("- Source G4 overall label: `%s`", analysis.SourceG4OverallLabel); ...
    sprintf("- Best profile/candidate: `%s` / `%s`", conclusion.BestProfileId, conclusion.BestCandidateName); ...
    sprintf("- Formal gate decision changed: `%s`", string(conclusion.FormalGateDecisionChanged)); ...
    sprintf("- Figure count: `%d`", numel(figurePaths)); ...
    ""; ...
    "## Interpretation"; ...
    sprintf("- Rationale: %s", conclusion.Rationale); ...
    sprintf("- Recommended next action: %s", conclusion.RecommendedNextAction); ...
    sprintf("- Default-gate reveal count: `%d`", thresholdCounts.DefaultGateRevealCount); ...
    sprintf("- Permissive-probe reveal count: `%d`", thresholdCounts.PermissiveProbeRevealCount); ...
    ""; ...
    "## Key Metrics"; ...
    sprintf("- Best direct-path suppression: `%.3f dB`", conclusion.BestDirectPathSuppression_dB); ...
    sprintf("- Best scene-score delta: `%.6f`", conclusion.BestSceneScoreDelta); ...
    sprintf("- Best off-origin energy-fraction delta: `%.9f`", conclusion.BestOffOriginEnergyFractionDelta); ...
    sprintf("- Best protected-region retention ratio: `%.3f`", conclusion.BestProtectedRetentionRatio); ...
    sprintf("- Best causal label: `%s`", conclusion.BestCausalLabel); ...
    sprintf("- Median reference/surveillance coherence: `%.3f`", conclusion.MedianReferenceSurveillanceCoherence); ...
    ""; ...
    "## Threshold Readout"; ...
    localBuildThresholdReadoutLines(analysis.ThresholdSensitivityTable); ...
    ""; ...
    "## Top Profile Rows"; ...
    localBuildTopProfileLines(analysis.ProfileSweepSummaryTable); ...
    ""; ...
    "## Signal Diagnostics"; ...
    localBuildSignalDiagnosticLines(analysis.SignalDiagnosticTable); ...
    ""; ...
    "## Figures"; ...
    localBuildFigureLines(figurePaths); ...
    ""; ...
    "## Output Files"; ...
    "- `review_summary.csv`"; ...
    "- `source_gate_summary.csv`"; ...
    "- `diagnostic_conclusion_table.csv`"; ...
    "- `profile_sweep_summary_table.csv`"; ...
    "- `threshold_sensitivity_table.csv`"; ...
    "- `signal_diagnostic_table.csv`"; ...
    "- `acquisition_implication_table.csv`"; ...
    "- `upstream_caveats_carried_forward.csv`"; ...
    "- `metrics.json`"; ...
    "- `metrics.mat`"; ...
    "- `figures/`"; ...
    "- `diagnostic_conclusion.txt`"; ...
    "- `next_branch.txt`" ...
    ];

end
function results = localBuildResults(datasetId, stageArtifactId, runTimestampZ, bundleRoot, analysis, reviewSummary, figurePaths)

conclusion = analysis.DiagnosticConclusionTable(1, :);
results = struct();
results.DatasetId = datasetId;
results.StageId = stageArtifactId;
results.AnalysisStageId = string(analysis.AnalysisStageId);
results.RunTimestampZ = runTimestampZ;
results.BundleRoot = string(bundleRoot);
results.PrimaryConclusionLabel = string(conclusion.PrimaryConclusionLabel);
results.SecondaryCaveatLabel = string(conclusion.SecondaryCaveatLabel);
results.BestProfileId = string(conclusion.BestProfileId);
results.BestCandidateName = string(conclusion.BestCandidateName);
results.BestDirectPathSuppression_dB = double(conclusion.BestDirectPathSuppression_dB);
results.BestSceneScoreDelta = double(conclusion.BestSceneScoreDelta);
results.BestOffOriginEnergyFractionDelta = double(conclusion.BestOffOriginEnergyFractionDelta);
results.BestProtectedRetentionRatio = double(conclusion.BestProtectedRetentionRatio);
results.BestCausalLabel = string(conclusion.BestCausalLabel);
results.MedianReferenceSurveillanceCoherence = double(conclusion.MedianReferenceSurveillanceCoherence);
results.ReviewSummaryTable = reviewSummary;
results.DiagnosticConclusionTable = analysis.DiagnosticConclusionTable;
results.ProfileSweepSummaryTable = analysis.ProfileSweepSummaryTable;
results.ThresholdSensitivityTable = analysis.ThresholdSensitivityTable;
results.SignalDiagnosticTable = analysis.SignalDiagnosticTable;
results.FigurePaths = figurePaths;
results.Analysis = analysis;

end
function localPrintRunSummary(results, analysis, figureRoot)

thresholdCounts = localThresholdPassCounts(analysis.ThresholdSensitivityTable);

fprintf("Diagnostic conclusion:\t%s\n", results.PrimaryConclusionLabel);
fprintf("Secondary caveat:\t%s\n", results.SecondaryCaveatLabel);
fprintf("Best profile/candidate:\t%s / %s\n", results.BestProfileId, results.BestCandidateName);
fprintf("Best direct-path suppression:\t%.3f [dB]\n", results.BestDirectPathSuppression_dB);
fprintf("Best scene-score delta:\t%.6f [unitless]\n", results.BestSceneScoreDelta);
fprintf("Best off-origin energy delta:\t%.9f [fraction]\n", results.BestOffOriginEnergyFractionDelta);
fprintf("Best protected retention:\t%.3f [ratio]\n", results.BestProtectedRetentionRatio);
fprintf("Best causal label:\t%s\n", results.BestCausalLabel);
fprintf("Median reference/surveillance coherence:\t%.3f [unitless]\n", results.MedianReferenceSurveillanceCoherence);
fprintf("Default-gate reveal count:\t%d [candidate-cases]\n", thresholdCounts.DefaultGateRevealCount);
fprintf("Permissive-probe reveal count:\t%d [candidate-cases]\n", thresholdCounts.PermissiveProbeRevealCount);
fprintf("Figure root:\t%s\n", figureRoot);
fprintf("Bundle root:\t%s\n", results.BundleRoot);

end

function figurePaths = localRenderDiagnosticFigures(analysis, figureRoot, showFigures)

figurePaths = strings(4, 1);
figurePaths(1) = fullfile(figureRoot, "figure_01_profile_sweep_metrics.png");
figurePaths(2) = fullfile(figureRoot, "figure_02_threshold_sensitivity.png");
figurePaths(3) = fullfile(figureRoot, "figure_03_signal_diagnostics.png");
figurePaths(4) = fullfile(figureRoot, "figure_04_diagnostic_score_ranking.png");

localRenderProfileSweepFigure(analysis, figurePaths(1), showFigures);
localRenderThresholdSensitivityFigure(analysis, figurePaths(2), showFigures);
localRenderSignalDiagnosticsFigure(analysis, figurePaths(3), showFigures);
localRenderDiagnosticScoreFigure(analysis, figurePaths(4), showFigures);

end

function localRenderProfileSweepFigure(analysis, figurePath, showFigures)

profileTable = localMitigationProfileRows(analysis.ProfileSweepSummaryTable);
labelText = localProfileCandidateLabels(profileTable);
figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G5 Diagnostic Profile Sweep Metrics", ...
    "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
layoutHandle = tiledlayout(2, 2, ...
    "TileSpacing", "compact", ...
    "Padding", "compact");

nexttile(layoutHandle);
bar(1:height(profileTable), profileTable.DirectPathSuppression_dB);
hold on
yline(localThresholdValue(analysis, "default_gate", "DirectPathSuppressionThreshold_dB", 3.0), "--", "default gate", "Interpreter", "none");
yline(localThresholdValue(analysis, "permissive_probe", "DirectPathSuppressionThreshold_dB", 1.0), ":", "permissive probe", "Interpreter", "none");
hold off
grid on
xlabel("Profile / candidate");
ylabel("Suppression [dB]");
title("Direct-path suppression", "Interpreter", "none");
localApplyCategoryTickLabels(labelText);

nexttile(layoutHandle);
bar(1:height(profileTable), profileTable.SceneScoreDelta);
hold on
yline(localThresholdValue(analysis, "default_gate", "SceneScoreDeltaThreshold", 0.50), "--", "default gate", "Interpreter", "none");
yline(localThresholdValue(analysis, "permissive_probe", "SceneScoreDeltaThreshold", 0.05), ":", "permissive probe", "Interpreter", "none");
hold off
grid on
xlabel("Profile / candidate");
ylabel("Scene-score delta [unitless]");
title("Scene-score proxy gain", "Interpreter", "none");
localApplyCategoryTickLabels(labelText);

nexttile(layoutHandle);
bar(1:height(profileTable), profileTable.OffOriginEnergyFractionDelta);
hold on
yline(localThresholdValue(analysis, "default_gate", "OffOriginEnergyDeltaThreshold", 0.005), "--", "default gate", "Interpreter", "none");
yline(localThresholdValue(analysis, "permissive_probe", "OffOriginEnergyDeltaThreshold", 0.0001), ":", "permissive probe", "Interpreter", "none");
hold off
grid on
xlabel("Profile / candidate");
ylabel("Energy fraction delta [fraction]");
title("Off-origin energy proxy gain", "Interpreter", "none");
localApplyCategoryTickLabels(labelText);

nexttile(layoutHandle);
bar(1:height(profileTable), profileTable.ProtectedRetentionRatio);
hold on
yline(localThresholdValue(analysis, "default_gate", "ProtectedRetentionFloor", 0.50), "--", "retention floor", "Interpreter", "none");
yline(1.0, ":", "baseline", "Interpreter", "none");
hold off
grid on
xlabel("Profile / candidate");
ylabel("Retention ratio [linear]");
title("Protected-region retention", "Interpreter", "none");
localApplyCategoryTickLabels(labelText);

sgtitle(layoutHandle, sprintf("G5 diagnostic profile sweep: %s", analysis.DiagnosticConclusionTable.PrimaryConclusionLabel(1)), "Interpreter", "none");
drawnow
localExportGraphics(layoutHandle, figurePath);
clear cleanupObject

end

function localRenderThresholdSensitivityFigure(analysis, figurePath, showFigures)

sensitivityTable = analysis.ThresholdSensitivityTable;
rowLabels = string(sensitivityTable.ProfileId) + " / " + string(sensitivityTable.CandidateName);
uniqueRowLabels = unique(rowLabels, "stable");
caseLabels = unique(string(sensitivityTable.ThresholdCase), "stable");
passMatrix = NaN(numel(uniqueRowLabels), numel(caseLabels));
textMatrix = strings(numel(uniqueRowLabels), numel(caseLabels));

for idx = 1:height(sensitivityTable)
    rowIndex = find(uniqueRowLabels == rowLabels(idx), 1, "first");
    columnIndex = find(caseLabels == string(sensitivityTable.ThresholdCase(idx)), 1, "first");
    passMatrix(rowIndex, columnIndex) = double(sensitivityTable.WouldRevealScene(idx));
    textMatrix(rowIndex, columnIndex) = localFailureModeShortLabel(sensitivityTable.FailureMode(idx));
end

figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G5 Diagnostic Threshold Sensitivity", ...
    "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
imagesc(passMatrix);
colormap([0.86 0.86 0.86; 0.22 0.63 0.33]);
colorbar("Ticks", [0.25 0.75], "TickLabels", ["does not reveal", "reveals"]);
clim([0 1]);
axis tight
xticks(1:numel(caseLabels));
xticklabels(caseLabels);
yticks(1:numel(uniqueRowLabels));
yticklabels(uniqueRowLabels);
xtickangle(30);
xlabel("Threshold case");
ylabel("Profile / candidate");
title("G5 threshold sensitivity: pass/fail by candidate case", "Interpreter", "none");

for rowIndex = 1:numel(uniqueRowLabels)
    for columnIndex = 1:numel(caseLabels)
        text(columnIndex, rowIndex, textMatrix(rowIndex, columnIndex), ...
            "HorizontalAlignment", "center", ...
            "Color", "black", ...
            "FontSize", 8, ...
            "Interpreter", "none");
    end
end

drawnow
localExportGraphics(gca, figurePath);
clear cleanupObject

end

function localRenderSignalDiagnosticsFigure(analysis, figurePath, showFigures)

signalTable = analysis.SignalDiagnosticTable;
mapLabels = string(signalTable.CpiLabel) + " / " + string(signalTable.WindowLabel) + " / rep " + string(signalTable.Repetition);
figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G5 Diagnostic Signal Diagnostics", ...
    "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
layoutHandle = tiledlayout(2, 2, ...
    "TileSpacing", "compact", ...
    "Padding", "compact");

nexttile(layoutHandle);
bar(1:height(signalTable), [signalTable.ReferencePower_dB signalTable.SurveillancePower_dB]);
grid on
xlabel("Selected map row");
ylabel("Power [dB]");
title("Reference and surveillance power", "Interpreter", "none");
legend(["reference", "surveillance"], "Location", "best", "Interpreter", "none");
localApplyCategoryTickLabels(mapLabels);

nexttile(layoutHandle);
bar(1:height(signalTable), [signalTable.ReferenceSurveillanceCoherenceMedian signalTable.ReferenceSurveillanceCoherenceMax signalTable.CoherenceFractionAboveHalf]);
hold on
yline(0.5, "--", "0.5 coherence", "Interpreter", "none");
hold off
grid on
xlabel("Selected map row");
ylabel("Coherence [unitless]");
title("Reference/surveillance coherence", "Interpreter", "none");
legend(["median", "max", "fraction >= 0.5"], "Location", "best", "Interpreter", "none");
localApplyCategoryTickLabels(mapLabels);

nexttile(layoutHandle);
bar(1:height(signalTable), [signalTable.ReferencePsdPeakToMedian_dB signalTable.SurveillancePsdPeakToMedian_dB]);
grid on
xlabel("Selected map row");
ylabel("Peak-to-median [dB]");
title("PSD concentration", "Interpreter", "none");
legend(["reference", "surveillance"], "Location", "best", "Interpreter", "none");
localApplyCategoryTickLabels(mapLabels);

nexttile(layoutHandle);
bar(1:height(signalTable), signalTable.SurveillanceSpectrogramDynamicRange_dB);
grid on
xlabel("Selected map row");
ylabel("Dynamic range [dB]");
title("Surveillance spectrogram dynamic range", "Interpreter", "none");
localApplyCategoryTickLabels(mapLabels);

sgtitle(layoutHandle, "G5 diagnostic signal checks for selected G4 rows", "Interpreter", "none");
drawnow
localExportGraphics(layoutHandle, figurePath);
clear cleanupObject

end

function localRenderDiagnosticScoreFigure(analysis, figurePath, showFigures)

profileTable = localMitigationProfileRows(analysis.ProfileSweepSummaryTable);
labelText = localProfileCandidateLabels(profileTable);
figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G5 Diagnostic Score Ranking", ...
    "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
layoutHandle = tiledlayout(1, 1, ...
    "TileSpacing", "compact", ...
    "Padding", "compact");
nexttile(layoutHandle);
bar(1:height(profileTable), profileTable.DiagnosticScore);
grid on
xlabel("Profile / candidate");
ylabel("Diagnostic score [unitless]");
title("G5 diagnostic candidate ranking", "Interpreter", "none");
localApplyCategoryTickLabels(labelText);
drawnow
localExportGraphics(layoutHandle, figurePath);
clear cleanupObject

end

function profileRows = localMitigationProfileRows(profileSummaryTable)

profileRows = profileSummaryTable(profileSummaryTable.CandidateName ~= "none", :);

end

function labelText = localProfileCandidateLabels(profileTable)

labelText = string(profileTable.ProfileId) + " / " + string(profileTable.CandidateName);

end

function localApplyCategoryTickLabels(labelText)

xticks(1:numel(labelText));
xticklabels(labelText);
xtickangle(35);

end

function value = localThresholdValue(analysis, thresholdCase, variableName, defaultValue)

value = defaultValue;

if ~isfield(analysis, "Options")
    return
end

if ~isfield(analysis.Options, "ThresholdCaseTable")
    return
end

thresholdTable = analysis.Options.ThresholdCaseTable;
matchingRows = thresholdTable(thresholdTable.ThresholdCase == string(thresholdCase), :);

if isempty(matchingRows)
    return
end

if ~ismember(variableName, string(matchingRows.Properties.VariableNames))
    return
end

candidateValue = matchingRows.(variableName)(1);

if isnumeric(candidateValue) && isscalar(candidateValue) && isfinite(candidateValue)
    value = double(candidateValue);
end

end

function shortLabel = localFailureModeShortLabel(failureMode)

failureMode = string(failureMode);

if failureMode == "passes_case"
    shortLabel = "pass";
elseif failureMode == "insufficient_direct_path_suppression"
    shortLabel = "supp";
elseif failureMode == "insufficient_scene_proxy_gain"
    shortLabel = "scene";
elseif failureMode == "protected_retention_failed"
    shortLabel = "retain";
else
    shortLabel = "n/a";
end

end

function thresholdCounts = localThresholdPassCounts(thresholdSensitivityTable)

defaultRows = thresholdSensitivityTable(thresholdSensitivityTable.ThresholdCase == "default_gate", :);
permissiveRows = thresholdSensitivityTable(thresholdSensitivityTable.ThresholdCase == "permissive_probe", :);
thresholdCounts = struct();
thresholdCounts.DefaultGateRevealCount = sum(logical(defaultRows.WouldRevealScene));
thresholdCounts.PermissiveProbeRevealCount = sum(logical(permissiveRows.WouldRevealScene));

end

function lines = localBuildThresholdReadoutLines(thresholdSensitivityTable)

caseLabels = unique(string(thresholdSensitivityTable.ThresholdCase), "stable");
lines = strings(numel(caseLabels), 1);

for idx = 1:numel(caseLabels)
    caseRows = thresholdSensitivityTable(thresholdSensitivityTable.ThresholdCase == caseLabels(idx), :);
    revealCount = sum(logical(caseRows.WouldRevealScene));
    totalCount = height(caseRows);
    dominantFailureMode = localDominantFailureMode(caseRows);
    lines(idx) = sprintf("- `%s`: `%d` of `%d` candidate cases reveal scene; dominant non-pass reason `%s`", caseLabels(idx), revealCount, totalCount, dominantFailureMode);
end

end

function dominantFailureMode = localDominantFailureMode(caseRows)

failureRows = caseRows(~logical(caseRows.WouldRevealScene), :);

if isempty(failureRows)
    dominantFailureMode = "none";
    return
end

failureCategories = categorical(string(failureRows.FailureMode));
failureLabels = categories(failureCategories);
labelCounts = countcats(failureCategories);
[~, maxIndex] = max(labelCounts);
dominantFailureMode = string(failureLabels(maxIndex));

end

function lines = localBuildTopProfileLines(profileSummaryTable)

profileRows = localMitigationProfileRows(profileSummaryTable);
rowCount = min(5, height(profileRows));
lines = strings(rowCount, 1);

for idx = 1:rowCount
    row = profileRows(idx, :);
    lines(idx) = sprintf("- `%s` / `%s`: suppression `%.3f dB`, scene delta `%.6f`, off-origin delta `%.9f`, retention `%.3f`, causal `%s`", row.ProfileId, row.CandidateName, row.DirectPathSuppression_dB, row.SceneScoreDelta, row.OffOriginEnergyFractionDelta, row.ProtectedRetentionRatio, row.CausalLabel);
end

end

function lines = localBuildSignalDiagnosticLines(signalDiagnosticTable)

rowCount = min(5, height(signalDiagnosticTable));
lines = strings(rowCount, 1);

for idx = 1:rowCount
    row = signalDiagnosticTable(idx, :);
    lines(idx) = sprintf("- Row `%d` `%s` / `%s` rep `%.0f`: median coherence `%.3f`, coherence fraction >= 0.5 `%.3f`, surveillance PSD peak/median `%.3f dB`", row.MapRowId, row.CpiLabel, row.WindowLabel, row.Repetition, row.ReferenceSurveillanceCoherenceMedian, row.CoherenceFractionAboveHalf, row.SurveillancePsdPeakToMedian_dB);
end

end

function lines = localBuildFigureLines(figurePaths)

lines = strings(numel(figurePaths), 1);

for idx = 1:numel(figurePaths)
    [~, figureName, figureExtension] = fileparts(figurePaths(idx));
    lines(idx) = sprintf("- `figures/%s%s`", figureName, figureExtension);
end

end

function localExportGraphics(exportTarget, figurePath)

try
    exportgraphics(exportTarget, figurePath);
catch exportException
    error("runG5MitigationDiagnosticStudy:ExportFigureFailed", "Failed to export %s: %s", figurePath, exportException.message);
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

if ~isfolder(folderPath)
    try
        mkdir(folderPath);
    catch mkdirException
        error("runG5MitigationDiagnosticStudy:CreateFolderFailed", "Failed to create folder %s: %s", folderPath, mkdirException.message);
    end
end

end

function localWriteJsonFile(filePath, inputStruct)

try
    jsonText = jsonencode(inputStruct, PrettyPrint = true);
catch encodeException
    error("runG5MitigationDiagnosticStudy:JsonEncodeFailed", "Failed to encode JSON for %s: %s", filePath, encodeException.message);
end

localWriteTextFile(filePath, jsonText);

end

function localWriteTextFile(filePath, lines)

try
    fileIdentifier = fopen(filePath, "w");
catch openException
    error("runG5MitigationDiagnosticStudy:OpenTextFileFailed", "Failed to open %s for writing: %s", filePath, openException.message);
end

if fileIdentifier == -1
    error("runG5MitigationDiagnosticStudy:OpenTextFileFailed", "Failed to open %s for writing.", filePath);
end

cleanupObject = onCleanup(@() fclose(fileIdentifier));
lines = string(lines);

for idx = 1:numel(lines)
    fprintf(fileIdentifier, "%s\n", lines(idx));
end

clear cleanupObject

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
    localWriteTextFile(fullfile(bundleRoot, "summary.md"), ["# G5 Diagnostic Failure"; ""; string(mainException.message)]);
    localWriteTextFile(fullfile(bundleRoot, "failure_cause.txt"), getReport(mainException, "extended", "hyperlinks", "off"));
catch
end

end





