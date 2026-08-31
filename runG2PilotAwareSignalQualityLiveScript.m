%[text] # G2 Pilot-Aware Signal Quality Development Review
%[text] Figure-first ATSC RF-health review for the accepted G2 reference and surveillance roles. This script uses pilot-aware spectrum evidence only; it does not demodulate ATSC and does not compute MER or EVM.

%%
%[text] ## Setup And Inputs
%[text] Choose the baseline session and the ATSC pilot assumptions used by the review.
if ~exist("datasetId", "var")
    datasetId = "20260622T102123";
end

if ~exist("repoRoot", "var")
    repoRoot = helperResolveRepoRoot();
end

if ~exist("ExportArtifacts", "var")
    ExportArtifacts = false;
end

if ~exist("ShowFigures", "var")
    ShowFigures = usejava("desktop");
end

analysisOptions = struct();
analysisOptions.ExpectedPilotOffsetHz = -2.690559441e6;
analysisOptions.PilotSearchHalfWidthHz = 150.0e3;
analysisOptions.PilotExclusionHalfWidthHz = 50.0e3;
analysisOptions.WelchLength = 8192;
analysisOptions.WelchOverlap = 4096;
analysisOptions.WelchNfft = 8192;
artifactPaths = localPrepareArtifactPaths(repoRoot, datasetId, ...
    ExportArtifacts);
fprintf("Dataset:\t%s\n", datasetId);
fprintf("Repository root:\t%s\n", repoRoot);
fprintf("Expected ATSC pilot offset [Hz]:\t%.3f\n", ...
    analysisOptions.ExpectedPilotOffsetHz);
fprintf("Pilot exclusion half-width [Hz]:\t%.3f\n", ...
    analysisOptions.PilotExclusionHalfWidthHz);
fprintf("Export artifacts:\t%d\n", ExportArtifacts);

%%
%[text] ## Preprocessing And Role Mapping
%[text] Confirm sample rate, center frequency, repetition count, and the accepted `RF1:RX2` reference / `RF0:RX2` surveillance mapping.
try
    loadOptions = struct();
    loadOptions.IncludeSamples = false;
    sessionData = loadIQData(datasetId, repoRoot, loadOptions);
    collectionMetadataPath = fullfile(sessionData.DatasetRoot, ...
        "collection_metadata.json");
    collectionMetadataInfo = helperReadCollectionMetadata( ...
        collectionMetadataPath, datasetId);
    pilotAnalysis = helperAnalyzeG2PilotAwareSignalQuality( ...
        sessionData, collectionMetadataInfo, analysisOptions);
catch analysisException
    error("runG2PilotAwareSignalQualityLiveScript:AnalysisFailed", ...
        "Pilot-aware G2 analysis failed: %s", analysisException.message);
end

fprintf("Sample rate [Hz]:\t%.3f\n", pilotAnalysis.Options.SampleRateHz);
fprintf("Center frequency [Hz]:\t%.3f\n", ...
    pilotAnalysis.Options.CenterFrequencyHz);
fprintf("Repetition count [count]:\t%d\n", ...
    height(pilotAnalysis.ComparisonMetricTable));
fprintf("Reference role:\t%s\n", pilotAnalysis.RoleInfo.ReferenceLabel);
fprintf("Surveillance role:\t%s\n", ...
    pilotAnalysis.RoleInfo.SurveillanceLabel);
fprintf("Role source:\t%s\n", pilotAnalysis.RoleInfo.RoleSource);
localPlotRoleMappedAveragePsd(pilotAnalysis, artifactPaths, ...
    ShowFigures, ExportArtifacts);

%%
%[text] ## Pilot Frequency Estimate
%[text] Where is the dominant pilot-like line in each role, and is it stable?
localPlotPilotFrequencyEstimate(pilotAnalysis, artifactPaths, ...
    ShowFigures, ExportArtifacts);

%%
%[text] ## Pilot PSD Prominence
%[text] Does each channel see a strong stable transmitter-specific pilot?
localPlotPilotProminence(pilotAnalysis, artifactPaths, ShowFigures, ...
    ExportArtifacts);

%%
%[text] ## Pilot-Excluded Data-Band Structure
%[text] After removing the pilot neighborhood, is the ATSC data band smooth or dominated by other structure?
localPlotDataBandStructure(pilotAnalysis, artifactPaths, ShowFigures, ...
    ExportArtifacts);

%%
%[text] ## Reference Vs Surveillance Pilot Delta
%[text] Is the accepted reference stronger for transmitter-specific pilot energy?
localPlotPilotDelta(pilotAnalysis, artifactPaths, ShowFigures, ...
    ExportArtifacts);

%%
%[text] ## Reference Vs Surveillance Data-Band Delta
%[text] Is surveillance stronger because of ATSC illuminator energy or broader non-pilot energy?
localPlotDataBandDelta(pilotAnalysis, artifactPaths, ShowFigures, ...
    ExportArtifacts);

%%
%[text] ## Manual Review Dashboard
%[text] What should we conclude before moving toward G2 Stage 3 illuminator-quality work?
localPlotManualReviewDashboard(pilotAnalysis, artifactPaths, ...
    ShowFigures, ExportArtifacts);
fprintf("Overall pilot-aware label:\t%s\n", ...
    pilotAnalysis.Metrics.overall_review_label);
fprintf("Overall rationale:\t%s\n", ...
    pilotAnalysis.Metrics.overall_review_rationale);

if ExportArtifacts
    localWritePilotAwareArtifacts(pilotAnalysis, artifactPaths);
    fprintf("Artifact bundle:\t%s\n", artifactPaths.BundleRoot);
end

%%
%[text] ## Appendix: Role Summary Table
%[text] Compact per-role summary values for audit and export.
disp(pilotAnalysis.RoleSummaryTable);

%%
%[text] ## Appendix: Per-Repetition Audit Table
%[text] Exact per-repetition role metrics for CSV/MAT export and later artifact-only reporting.
disp(pilotAnalysis.RoleMetricTable);

%%
%[text] ## Appendix: Role Delta Table
%[text] Exact per-repetition reference-minus-surveillance pilot and data-band deltas.
disp(pilotAnalysis.ComparisonMetricTable);

%%
%[text] ## Appendix: Dashboard Decision Table
%[text] Review labels and rationale used by the dashboard figure.
disp(pilotAnalysis.DashboardTable);

function artifactPaths = localPrepareArtifactPaths(repoRoot, datasetId, ...
    exportArtifacts)

artifactPaths = struct();
artifactPaths.BundleRoot = "";
artifactPaths.FigureRoot = "";
artifactPaths.RoleMetricCsvPath = "";
artifactPaths.RoleSummaryCsvPath = "";
artifactPaths.ComparisonMetricCsvPath = "";
artifactPaths.DashboardCsvPath = "";
artifactPaths.MetricsMatPath = "";
artifactPaths.MetricsJsonPath = "";
artifactPaths.FigurePaths = struct();

if ~exportArtifacts
    return
end

runTimestampZ = string(datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyyMMdd'T'HHmmss'Z'"));
artifactPaths.BundleRoot = fullfile(repoRoot, "artifacts", datasetId, ...
    "G2_PilotAwareSignalQuality_Development", runTimestampZ);
artifactPaths.FigureRoot = fullfile(artifactPaths.BundleRoot, "figures");
localEnsureFolder(artifactPaths.BundleRoot);
localEnsureFolder(artifactPaths.FigureRoot);
artifactPaths.RoleMetricCsvPath = fullfile(artifactPaths.BundleRoot, ...
    "role_metric_table.csv");
artifactPaths.RoleSummaryCsvPath = fullfile(artifactPaths.BundleRoot, ...
    "role_summary_table.csv");
artifactPaths.ComparisonMetricCsvPath = fullfile( ...
    artifactPaths.BundleRoot, "comparison_metric_table.csv");
artifactPaths.DashboardCsvPath = fullfile(artifactPaths.BundleRoot, ...
    "dashboard_table.csv");
artifactPaths.MetricsMatPath = fullfile(artifactPaths.BundleRoot, ...
    "metrics.mat");
artifactPaths.MetricsJsonPath = fullfile(artifactPaths.BundleRoot, ...
    "metrics.json");
artifactPaths.FigurePaths.AveragePsd = fullfile( ...
    artifactPaths.FigureRoot, "figure_01_role_mapped_average_psd.png");
artifactPaths.FigurePaths.PilotFrequency = fullfile( ...
    artifactPaths.FigureRoot, "figure_02_pilot_frequency_estimate.png");
artifactPaths.FigurePaths.PilotProminence = fullfile( ...
    artifactPaths.FigureRoot, "figure_03_pilot_psd_prominence.png");
artifactPaths.FigurePaths.DataBandStructure = fullfile( ...
    artifactPaths.FigureRoot, "figure_04_pilot_excluded_data_band.png");
artifactPaths.FigurePaths.PilotDelta = fullfile( ...
    artifactPaths.FigureRoot, "figure_05_reference_surveillance_pilot_delta.png");
artifactPaths.FigurePaths.DataBandDelta = fullfile( ...
    artifactPaths.FigureRoot, "figure_06_reference_surveillance_data_band_delta.png");
artifactPaths.FigurePaths.Dashboard = fullfile( ...
    artifactPaths.FigureRoot, "figure_07_manual_review_dashboard.png");

end

function localPlotRoleMappedAveragePsd(pilotAnalysis, artifactPaths, ...
    showFigures, exportArtifacts)

figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G2 Pilot-Aware Average PSD by Accepted Role", ...
    "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
layoutHandle = tiledlayout(1, 1);
nexttile(layoutHandle);
plot(pilotAnalysis.RoleEvidence.PsdFrequencyOffset_Hz / 1.0e6, ...
    pow2db(pilotAnalysis.RoleEvidence.ReferenceMeanPsd + eps), ...
    "LineWidth", 1.4);
hold on
plot(pilotAnalysis.RoleEvidence.PsdFrequencyOffset_Hz / 1.0e6, ...
    pow2db(pilotAnalysis.RoleEvidence.SurveillanceMeanPsd + eps), ...
    "LineWidth", 1.4);
xline(pilotAnalysis.Options.ExpectedPilotOffsetHz / 1.0e6, "--", ...
    "Expected pilot", "LineWidth", 1.0);
hold off
grid on
xlabel("Frequency Offset [MHz]");
ylabel("PSD [dB/Hz]");
title("Role-Mapped Average PSD With Expected ATSC Pilot");
legend("Reference", "Surveillance", "Expected Pilot", ...
    Location = "best");
drawnow
localExportFigure(layoutHandle, artifactPaths.FigurePaths.AveragePsd, ...
    exportArtifacts);
clear cleanupObject

end

function localPlotPilotFrequencyEstimate(pilotAnalysis, artifactPaths, ...
    showFigures, exportArtifacts)

roleMetricTable = pilotAnalysis.RoleMetricTable;
figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G2 Pilot Frequency Estimate", "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
layoutHandle = tiledlayout(2, 1);

nexttile(layoutHandle);
localPlotRoleSeries(roleMetricTable, "PilotFrequencyOffset_Hz", ...
    1.0e6, "-o");
hold on
yline(pilotAnalysis.Options.ExpectedPilotOffsetHz / 1.0e6, "--", ...
    "Expected pilot", "LineWidth", 1.0);
hold off
grid on
xlabel("Repetition");
ylabel("Pilot Offset [MHz]");
title("Dominant Pilot-Like Frequency by Accepted Role");
legend("Reference", "Surveillance", "Expected Pilot", ...
    Location = "best");

nexttile(layoutHandle);
localPlotRoleSeries(roleMetricTable, "PilotOffsetError_Hz", ...
    1.0e3, "-o");
hold on
yline(0.0, "--", "LineWidth", 1.0);
hold off
grid on
xlabel("Repetition");
ylabel("Pilot Offset Error [kHz]");
title("Pilot Frequency Error Relative to Expected ATSC Offset");
legend("Reference", "Surveillance", "Zero Error", Location = "best");
drawnow
localExportFigure(layoutHandle, artifactPaths.FigurePaths.PilotFrequency, ...
    exportArtifacts);
clear cleanupObject

end

function localPlotPilotProminence(pilotAnalysis, artifactPaths, ...
    showFigures, exportArtifacts)

roleMetricTable = pilotAnalysis.RoleMetricTable;
figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G2 Pilot PSD Prominence", "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
layoutHandle = tiledlayout(2, 1);

nexttile(layoutHandle);
localPlotRoleSeries(roleMetricTable, "PilotProminence_dB", 1.0, "-o");
hold on
yline(pilotAnalysis.Options.PilotProminenceReadyThreshold_dB, "--", ...
    "Ready", "LineWidth", 1.0);
yline(pilotAnalysis.Options.PilotProminenceCautionThreshold_dB, "--", ...
    "Caution", "LineWidth", 1.0);
hold off
grid on
xlabel("Repetition");
ylabel("Pilot Prominence [dB]");
title("Pilot Prominence Relative to Pilot-Excluded Data-Band Median");
legend("Reference", "Surveillance", "Ready", "Caution", ...
    Location = "best");

nexttile(layoutHandle);
bar(categorical(pilotAnalysis.RoleSummaryTable.Role), ...
    [pilotAnalysis.RoleSummaryTable.MedianPilotProminence_dB, ...
    pilotAnalysis.RoleSummaryTable.WorstPilotProminence_dB]);
grid on
xlabel("Accepted Role");
ylabel("Pilot Prominence [dB]");
title("Median and Worst Pilot Prominence by Role");
legend("Median", "Worst", Location = "best");
drawnow
localExportFigure(layoutHandle, artifactPaths.FigurePaths.PilotProminence, ...
    exportArtifacts);
clear cleanupObject

end

function localPlotDataBandStructure(pilotAnalysis, artifactPaths, ...
    showFigures, exportArtifacts)

frequencyMHz = pilotAnalysis.RoleEvidence.PsdFrequencyOffset_Hz / 1.0e6;
expectedPilotMHz = pilotAnalysis.Options.ExpectedPilotOffsetHz / 1.0e6;
exclusionHalfWidthMHz = ...
    pilotAnalysis.Options.PilotExclusionHalfWidthHz / 1.0e6;
figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G2 Pilot-Excluded Data-Band Structure", ...
    "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
layoutHandle = tiledlayout(2, 1);

nexttile(layoutHandle);
plot(frequencyMHz, pow2db(pilotAnalysis.RoleEvidence.ReferenceMeanPsd + eps), ...
    "LineWidth", 1.4);
hold on
plot(frequencyMHz, ...
    pow2db(pilotAnalysis.RoleEvidence.SurveillanceMeanPsd + eps), ...
    "LineWidth", 1.4);
yLimits = ylim;
patch([expectedPilotMHz - exclusionHalfWidthMHz, ...
    expectedPilotMHz + exclusionHalfWidthMHz, ...
    expectedPilotMHz + exclusionHalfWidthMHz, ...
    expectedPilotMHz - exclusionHalfWidthMHz], ...
    [yLimits(1), yLimits(1), yLimits(2), yLimits(2)], ...
    [0.75, 0.75, 0.75], "FaceAlpha", 0.25, ...
    "EdgeColor", "none");
hold off
grid on
xlabel("Frequency Offset [MHz]");
ylabel("PSD [dB/Hz]");
title("Average PSD With Pilot Exclusion Band Shaded");
legend("Reference", "Surveillance", "Pilot Exclusion", ...
    Location = "best");

nexttile(layoutHandle);
localPlotRoleSeries(pilotAnalysis.RoleMetricTable, ...
    "DataBandProminence_dB", 1.0, "-o");
hold on
yline(pilotAnalysis.Options.DataBandProminenceReadyThreshold_dB, "--", ...
    "Ready", "LineWidth", 1.0);
yline(pilotAnalysis.Options.DataBandProminenceCautionThreshold_dB, "--", ...
    "Caution", "LineWidth", 1.0);
hold off
grid on
xlabel("Repetition");
ylabel("Data-Band Peak Prominence [dB]");
title("Pilot-Excluded Data-Band Structure by Repetition");
legend("Reference", "Surveillance", "Ready", "Caution", ...
    Location = "best");
drawnow
localExportFigure(layoutHandle, ...
    artifactPaths.FigurePaths.DataBandStructure, exportArtifacts);
clear cleanupObject

end

function localPlotPilotDelta(pilotAnalysis, artifactPaths, showFigures, ...
    exportArtifacts)

comparisonMetricTable = pilotAnalysis.ComparisonMetricTable;
figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G2 Reference Minus Surveillance Pilot Delta", ...
    "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
layoutHandle = tiledlayout(1, 1);
nexttile(layoutHandle);
plot(comparisonMetricTable.Repetition, ...
    comparisonMetricTable.ReferenceMinusSurveillancePilotPsd_dB, ...
    "-o", "LineWidth", 1.2);
hold on
yline(0.0, "--", "Zero delta", "LineWidth", 1.0);
hold off
grid on
xlabel("Repetition");
ylabel("Reference - Surveillance Pilot PSD [dB]");
title("Pilot PSD Delta by Repetition; Stage 2 Full-Band Power Caveat Applies");
legend("Pilot PSD Delta", "Zero Delta", Location = "best");
drawnow
localExportFigure(layoutHandle, artifactPaths.FigurePaths.PilotDelta, ...
    exportArtifacts);
clear cleanupObject

end

function localPlotDataBandDelta(pilotAnalysis, artifactPaths, ...
    showFigures, exportArtifacts)

comparisonMetricTable = pilotAnalysis.ComparisonMetricTable;
figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G2 Reference Minus Surveillance Data-Band Delta", ...
    "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
layoutHandle = tiledlayout(2, 1);

nexttile(layoutHandle);
plot(pilotAnalysis.RoleEvidence.PsdFrequencyOffset_Hz / 1.0e6, ...
    pilotAnalysis.RoleEvidence.ReferenceMinusSurveillanceMeanPsd_dB, ...
    "LineWidth", 1.2);
hold on
xline(pilotAnalysis.Options.ExpectedPilotOffsetHz / 1.0e6, "--", ...
    "Expected pilot", "LineWidth", 1.0);
yline(0.0, "--", "LineWidth", 1.0);
hold off
grid on
xlabel("Frequency Offset [MHz]");
ylabel("Reference - Surveillance PSD [dB]");
title("Pointwise Average PSD Delta Across the ATSC Band");
legend("PSD Delta", "Expected Pilot", "Zero Delta", Location = "best");

nexttile(layoutHandle);
plot(comparisonMetricTable.Repetition, ...
    comparisonMetricTable.ReferenceMinusSurveillanceDataBandMedianPsd_dB, ...
    "-o", "LineWidth", 1.2);
hold on
plot(comparisonMetricTable.Repetition, ...
    comparisonMetricTable.ReferenceMinusSurveillanceDataBandPower_dB, ...
    "-o", "LineWidth", 1.2);
yline(0.0, "--", "LineWidth", 1.0);
hold off
grid on
xlabel("Repetition");
ylabel("Reference - Surveillance [dB]");
title("Pilot-Excluded Data-Band Median and Power Delta");
legend("Median PSD Delta", "Band Power Delta", "Zero Delta", ...
    Location = "best");
drawnow
localExportFigure(layoutHandle, artifactPaths.FigurePaths.DataBandDelta, ...
    exportArtifacts);
clear cleanupObject

end

function localPlotManualReviewDashboard(pilotAnalysis, artifactPaths, ...
    showFigures, exportArtifacts)

figureHandle = figure("Visible", localResolveFigureVisibility(showFigures), ...
    "Name", "G2 Pilot-Aware Manual Review Dashboard", ...
    "NumberTitle", "off");
cleanupObject = localCreateFigureCleanup(figureHandle, showFigures); %#ok<NASGU>
layoutHandle = tiledlayout(2, 2);

nexttile(layoutHandle);
bar(categorical(pilotAnalysis.RoleSummaryTable.Role), ...
    pilotAnalysis.RoleSummaryTable.PilotFrequencyStd_Hz / 1.0e3);
hold on
yline(pilotAnalysis.Options.PilotFrequencyStableThreshold_Hz / 1.0e3, ...
    "--", "Ready", "LineWidth", 1.0);
yline(pilotAnalysis.Options.PilotFrequencyCautionStableThreshold_Hz / ...
    1.0e3, "--", "Caution", "LineWidth", 1.0);
hold off
grid on
xlabel("Accepted Role");
ylabel("Pilot Frequency Std [kHz]");
title("Pilot Stability Label Inputs");
legend("Observed", "Ready", "Caution", Location = "best");

nexttile(layoutHandle);
bar(categorical(pilotAnalysis.RoleSummaryTable.Role), ...
    pilotAnalysis.RoleSummaryTable.MedianPilotProminence_dB);
hold on
yline(pilotAnalysis.Options.PilotProminenceReadyThreshold_dB, "--", ...
    "Ready", "LineWidth", 1.0);
yline(pilotAnalysis.Options.PilotProminenceCautionThreshold_dB, "--", ...
    "Caution", "LineWidth", 1.0);
hold off
grid on
xlabel("Accepted Role");
ylabel("Median Pilot Prominence [dB]");
title("Pilot Prominence Label Inputs");
legend("Observed", "Ready", "Caution", Location = "best");

nexttile(layoutHandle);
bar(categorical(pilotAnalysis.RoleSummaryTable.Role), ...
    pilotAnalysis.RoleSummaryTable.MedianDataBandProminence_dB);
hold on
yline(pilotAnalysis.Options.DataBandProminenceReadyThreshold_dB, "--", ...
    "Ready", "LineWidth", 1.0);
yline(pilotAnalysis.Options.DataBandProminenceCautionThreshold_dB, "--", ...
    "Caution", "LineWidth", 1.0);
hold off
grid on
xlabel("Accepted Role");
ylabel("Median Data-Band Prominence [dB]");
title("Data-Band Structure Label Inputs");
legend("Observed", "Ready", "Caution", Location = "best");

nexttile(layoutHandle);
statusCodes = localStatusCodes(pilotAnalysis.DashboardTable.ReviewLabel);
imagesc(statusCodes);
colormap(gca, localStatusColormap());
clim([0.5, 3.5]);
for rowIndex = 1:height(pilotAnalysis.DashboardTable)
    text(1, rowIndex, pilotAnalysis.DashboardTable.ReviewLabel(rowIndex), ...
        "HorizontalAlignment", "center", "FontWeight", "bold");
end
yticks(1:height(pilotAnalysis.DashboardTable));
yticklabels("Q" + string(1:height(pilotAnalysis.DashboardTable)));
xticks(1);
xticklabels("Status");
xlabel("Manual Review Label");
ylabel("Review Question");
title("Ready / Caution / No-Confidence Labels");
drawnow
localExportFigure(layoutHandle, artifactPaths.FigurePaths.Dashboard, ...
    exportArtifacts);
clear cleanupObject

end

function localPlotRoleSeries(roleMetricTable, variableName, scaleFactor, ...
    lineStyle)

referenceRows = roleMetricTable(roleMetricTable.Role == "reference", :);
surveillanceRows = roleMetricTable(roleMetricTable.Role == ...
    "surveillance", :);
plot(referenceRows.Repetition, referenceRows.(variableName) ./ ...
    scaleFactor, lineStyle, "LineWidth", 1.2);
hold on
plot(surveillanceRows.Repetition, surveillanceRows.(variableName) ./ ...
    scaleFactor, lineStyle, "LineWidth", 1.2);

end

function statusCodes = localStatusCodes(statusLabels)

statusCodes = zeros(numel(statusLabels), 1);

for statusIndex = 1:numel(statusLabels)
    switch string(statusLabels(statusIndex))
        case "ready"
            statusCodes(statusIndex) = 3;
        case "caution"
            statusCodes(statusIndex) = 2;
        otherwise
            statusCodes(statusIndex) = 1;
    end
end

end

function colorMap = localStatusColormap()

colorMap = [
    0.72, 0.24, 0.20
    0.86, 0.62, 0.22
    0.20, 0.55, 0.36
    ];

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
    cleanupObject = onCleanup(@() []);
else
    cleanupObject = onCleanup(@() close(figureHandle));
end

end

function localExportFigure(exportTarget, figurePath, exportArtifacts)

if ~exportArtifacts
    return
end

try
    exportgraphics(exportTarget, figurePath);
catch exportException
    error("runG2PilotAwareSignalQualityLiveScript:ExportFigureFailed", ...
        "Failed to export %s: %s", figurePath, exportException.message);
end

end

function localWritePilotAwareArtifacts(pilotAnalysis, artifactPaths)

try
    writetable(pilotAnalysis.RoleMetricTable, ...
        artifactPaths.RoleMetricCsvPath);
    writetable(pilotAnalysis.RoleSummaryTable, ...
        artifactPaths.RoleSummaryCsvPath);
    writetable(pilotAnalysis.ComparisonMetricTable, ...
        artifactPaths.ComparisonMetricCsvPath);
    writetable(pilotAnalysis.DashboardTable, artifactPaths.DashboardCsvPath);
catch tableException
    error("runG2PilotAwareSignalQualityLiveScript:WriteTableFailed", ...
        "Failed to write pilot-aware CSV artifacts: %s", ...
        tableException.message);
end

try
    save(artifactPaths.MetricsMatPath, "pilotAnalysis");
catch saveException
    error("runG2PilotAwareSignalQualityLiveScript:SaveMetricsFailed", ...
        "Failed to write pilot-aware metrics MAT file: %s", ...
        saveException.message);
end

localWriteJsonFile(artifactPaths.MetricsJsonPath, pilotAnalysis.Metrics);

end

function localWriteJsonFile(filePath, inputStruct)

try
    jsonText = jsonencode(inputStruct, PrettyPrint = true);
    fileIdentifier = fopen(filePath, "w");
catch openException
    error("runG2PilotAwareSignalQualityLiveScript:OpenJsonFailed", ...
        "Failed to open %s for JSON writing: %s", filePath, ...
        openException.message);
end

if fileIdentifier == -1
    error("runG2PilotAwareSignalQualityLiveScript:OpenJsonFailed", ...
        "Failed to open %s for JSON writing.", filePath);
end

cleanupObject = onCleanup(@() fclose(fileIdentifier));

try
    fprintf(fileIdentifier, "%s", jsonText);
catch writeException
    error("runG2PilotAwareSignalQualityLiveScript:WriteJsonFailed", ...
        "Failed to write %s: %s", filePath, writeException.message);
end

clear cleanupObject

end

function localEnsureFolder(folderPath)

if isfolder(folderPath)
    return
end

try
    mkdir(folderPath);
catch mkdirException
    error("runG2PilotAwareSignalQualityLiveScript:CreateFolderFailed", ...
        "Failed to create folder %s: %s", folderPath, ...
        mkdirException.message);
end

end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
