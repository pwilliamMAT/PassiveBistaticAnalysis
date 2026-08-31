function plotOutput = helperPlotPipelineStoryEvidence(reportData, ...
    evidenceId, options)
%HELPERPLOTPIPELINESTORYEVIDENCE Render selected story evidence plots.
%
%   PLOTOUTPUT = HELPERPLOTPIPELINESTORYEVIDENCE(REPORTDATA, EVIDENCEID,
%   OPTIONS) renders a curated plot from the artifact-only pipeline story
%   report. Use EVIDENCEID = "all" to render the default plot budget.

arguments
    reportData (1,1) struct
    evidenceId (1,1) string = "all"
    options (1,1) struct = struct()
end

plotOptions = localResolveOptions(options, reportData);
evidenceId = lower(string(evidenceId));

if evidenceId == "all"
    plotOutput = localPlotAllEvidence(reportData, plotOptions);
    return
end

switch evidenceId
    case "g2_raw_spectrum"
        fig = localPlotG2RawSpectrum(reportData, plotOptions);
    case "g2_reference_surveillance_delta"
        fig = localPlotG2ReferenceSurveillanceDelta(reportData, plotOptions);
    case "g2_full_band_power_delta"
        fig = localPlotG2FullBandPowerDelta(reportData, plotOptions);
    case "g2_psd_prominence"
        fig = localPlotG2PsdProminence(reportData, plotOptions);
    case "g2_receiver_metrics"
        fig = localPlotG2ReceiverMetrics(reportData, plotOptions);
    case "g3_sync_overview"
        fig = localPlotG3SyncOverview(reportData, plotOptions);
    case "g4_baseline_maps"
        fig = localPlotG4BaselineMaps(reportData, plotOptions);
    case "g4_scene_observability"
        fig = localPlotG4SceneObservability(reportData, plotOptions);
    case "g45_recovery_prominence_summary"
        fig = localPlotG45RecoveryProminenceSummary(reportData, plotOptions);
    case "g45_score_lift_summary"
        fig = localPlotG45ScoreLiftSummary(reportData, plotOptions);
    case "g45_association_error_summary"
        fig = localPlotG45AssociationErrorSummary(reportData, plotOptions);
    case "g45_study_summary"
        fig = localPlotG45SuiteSummary(reportData, plotOptions);
    case "g45_suite_summary"
        fig = localPlotG45SuiteSummary(reportData, plotOptions);
    case "g45_pre_injection_map"
        fig = localPlotG45PreInjectionMap(reportData, plotOptions);
    case "g45_injected_overlay_map"
        fig = localPlotG45InjectedOverlayMap(reportData, plotOptions);
    case "g45_association_map"
        fig = localPlotG45AssociationMap(reportData, plotOptions);
    case "g45_recovery_maps"
        fig = localPlotG45RecoveryMaps(reportData, plotOptions);
    case "g5_mitigation_overview"
        fig = localPlotG5MitigationOverview(reportData, plotOptions);
    case "g5_diagnostic_sensitivity"
        fig = localPlotG5DiagnosticSensitivity(reportData, plotOptions);
    case "g6_g8_readiness"
        fig = localPlotG6G8Readiness(reportData, plotOptions);
    otherwise
        error("helperPlotPipelineStoryEvidence:UnknownEvidenceId", ...
            "Unknown pipeline story evidence id: %s", evidenceId);
end

figurePath = localMaybeExportFigure(fig, evidenceId, plotOptions);
plotOutput = localBuildPlotOutput(evidenceId, figurePath);

end

function plotOptions = localResolveOptions(options, reportData)

plotOptions = struct();
plotOptions.ShowFigures = usejava("desktop");
plotOptions.ExportFigures = false;
plotOptions.ImageFormat = "png";
plotOptions.G45MapCaseId = "easy_single_target";
plotOptions.G45MapWindowLabel = "center";
plotOptions.PsdPilotExclusionHalfWidth_Hz = 50.0e3;

if isfield(reportData, "ExportRoot")
    plotOptions.ExportRoot = string(reportData.ExportRoot);
else
    plotOptions.ExportRoot = fullfile(reportData.RepoRoot, "artifacts", ...
        "communication", "PipelineStory", reportData.DatasetId, ...
        string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyyMMdd'T'HHmmss'Z'")));
end

if isfield(options, "ShowFigures")
    plotOptions.ShowFigures = logical(options.ShowFigures);
end

if isfield(options, "ExportFigures")
    plotOptions.ExportFigures = logical(options.ExportFigures);
end

if isfield(options, "ExportRoot")
    plotOptions.ExportRoot = string(options.ExportRoot);
end

if isfield(options, "ImageFormat")
    plotOptions.ImageFormat = lower(string(options.ImageFormat));
end

if isfield(options, "G45MapCaseId")
    plotOptions.G45MapCaseId = string(options.G45MapCaseId);
end

if isfield(options, "G45MapWindowLabel")
    plotOptions.G45MapWindowLabel = string(options.G45MapWindowLabel);
end

if isfield(options, "PsdPilotExclusionHalfWidth_Hz")
    plotOptions.PsdPilotExclusionHalfWidth_Hz = ...
        double(options.PsdPilotExclusionHalfWidth_Hz);
end

end

function plotOutput = localPlotAllEvidence(reportData, plotOptions)

evidenceIds = string(reportData.SelectedEvidenceTable.EvidenceId);
figureTable = table( ...
    strings(0, 1), strings(0, 1), false(0, 1), ...
    VariableNames = {'EvidenceId', 'FigurePath', 'Exported'});

for evidenceIndex = 1:numel(evidenceIds)
    singleOutput = helperPlotPipelineStoryEvidence( ...
        reportData, evidenceIds(evidenceIndex), plotOptions);
    figureTable = [figureTable; singleOutput.FigureTable]; %#ok<AGROW>
end

plotOutput = struct();
plotOutput.EvidenceId = "all";
plotOutput.FigureTable = figureTable;

end

function fig = localPlotG2RawSpectrum(reportData, plotOptions)

roleEvidence = reportData.G2Stage1.Mat.metrics.analysis.RoleEvidence;
frequency_MHz = double(roleEvidence.PsdFrequencyHz(:)) ./ 1.0e6;
channel1Psd_dB = localPowerToDb(roleEvidence.MeanChannel1Psd(:));
channel2Psd_dB = localPowerToDb(roleEvidence.MeanChannel2Psd(:));
fig = localNewFigure("G2 Raw Spectrum", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, ...
    "G2 Stage 1 pwelch PSD and mscohere Coherence Averaged Across Repetitions");

nexttile(layout);
plot(frequency_MHz, channel1Psd_dB, LineWidth = 1.1);
hold on;
plot(frequency_MHz, channel2Psd_dB, LineWidth = 1.1);
hold off;
grid on;
xlabel("Frequency [MHz]");
ylabel("Mean PSD from pwelch [dB/Hz]");
title("Raw Channel Mean PSD");
legend(["Channel 1", "Channel 2"], Location = "best");

nexttile(layout);
plot(double(roleEvidence.CoherenceFrequencyHz(:)) ./ 1.0e6, ...
    double(roleEvidence.MeanCoherenceSpectrum(:)), LineWidth = 1.1);
grid on;
xlabel("Frequency [MHz]");
ylabel("Magnitude-squared coherence [ratio]");
title("Mean mscohere Cross-Channel Coherence");
ylim([0, 1]);

end

function fig = localPlotG2ReferenceSurveillanceDelta(reportData, plotOptions)

roleEvidence = reportData.G2Stage2.Mat.metrics.analysis.RoleEvidence;
frequency_MHz = double(roleEvidence.PsdFrequencyHz(:)) ./ 1.0e6;
referencePsd_dB = localPowerToDb(roleEvidence.ReferenceMeanPsd(:));
surveillancePsd_dB = localPowerToDb(roleEvidence.SurveillanceMeanPsd(:));
psdDelta_dB = pow2db( ...
    max(double(roleEvidence.ReferenceMeanPsd(:)), eps) ./ ...
    max(double(roleEvidence.SurveillanceMeanPsd(:)), eps));
medianPsdDelta_dB = median(psdDelta_dB, "omitnan");
fig = localNewFigure("G2 Reference Surveillance Delta", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G2 Role-Mapped Spectral Comparison");

nexttile(layout);
plot(frequency_MHz, referencePsd_dB, LineWidth = 1.1);
hold on;
plot(frequency_MHz, surveillancePsd_dB, LineWidth = 1.1);
hold off;
grid on;
xlabel("Frequency [MHz]");
ylabel("Mean PSD from pwelch [dB/Hz]");
title("Reference and Surveillance Mean PSD");
legend(["Reference", "Surveillance"], Location = "best");

nexttile(layout);
plot(frequency_MHz, psdDelta_dB, LineWidth = 1.1);
hold on;
yline(0, "--", "Equal PSD");
yline(medianPsdDelta_dB, "-", "Median over frequency");
hold off;
grid on;
xlabel("Frequency [MHz]");
ylabel("Reference / surveillance PSD [dB]");
title("Pointwise PSD Delta");

end

function fig = localPlotG2FullBandPowerDelta(reportData, plotOptions)

integrityTable = localTable(reportData.G2Stage2, "receiver_integrity_table");
medianPowerDelta_dB = median( ...
    integrityTable.ReferenceMinusSurveillancePower_dB, "omitnan");
fig = localNewFigure("G2 Full-Band Mean-Power Delta", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G2 Full-Band Mean-Power Delta by Repetition");

nexttile(layout);
plot(integrityTable.Repetition, ...
    integrityTable.ReferenceMeanPower_dBFS, "-o", LineWidth = 1.2);
hold on;
plot(integrityTable.Repetition, ...
    integrityTable.SurveillanceMeanPower_dBFS, "-s", LineWidth = 1.2);
hold off;
grid on;
xlabel("Repetition");
ylabel("Full-band mean power [dBFS]");
title("Role Mean Power");
legend(["Reference", "Surveillance"], Location = "best");

nexttile(layout);
plot(integrityTable.Repetition, ...
    integrityTable.ReferenceMinusSurveillancePower_dB, "-o", ...
    LineWidth = 1.2);
hold on;
yline(0, "--", "Equal full-band power");
yline(medianPowerDelta_dB, "-", "Median over repetitions");
hold off;
grid on;
xlabel("Repetition");
ylabel("Reference - surveillance [dB]");
title("Full-Band Mean-Power Delta");

end

function fig = localPlotG2PsdProminence(reportData, plotOptions)

stage2RoleEvidence = reportData.G2Stage2.Mat.metrics.analysis.RoleEvidence;
frequency_Hz = double(stage2RoleEvidence.PsdFrequencyHz(:));
fig = localNewFigure("G2 Pilot-Aware PSD Prominence", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G2 Pilot-Aware PSD Prominence");

nexttile(layout);
localPlotPsdProminenceTile(frequency_Hz, ...
    stage2RoleEvidence.ReferenceMeanPsd, "Reference", ...
    plotOptions.PsdPilotExclusionHalfWidth_Hz);

nexttile(layout);
localPlotPsdProminenceTile(frequency_Hz, ...
    stage2RoleEvidence.SurveillanceMeanPsd, "Surveillance", ...
    plotOptions.PsdPilotExclusionHalfWidth_Hz);

end

function localPlotPsdProminenceTile(frequency_Hz, psdValues, roleLabel, ...
    pilotExclusionHalfWidth_Hz)

metrics = localComputePilotAwarePsdMetrics(frequency_Hz, psdValues, ...
    pilotExclusionHalfWidth_Hz);
frequency_MHz = double(frequency_Hz(:)) ./ 1.0e6;
psd_dB = pow2db(max(double(psdValues(:)), eps));
psdHandle = plot(frequency_MHz, psd_dB, LineWidth = 1.1);
hold on;
dataMedianHandle = yline(metrics.DataBandMedianPsd_dB, "--", ...
    "Data-band median");
pilotHandle = plot(metrics.PilotFrequency_Hz ./ 1.0e6, ...
    metrics.PilotPsd_dB, "^", MarkerSize = 7.0, LineWidth = 1.2);
dataPeakHandle = plot(metrics.DataBandPeakFrequency_Hz ./ 1.0e6, ...
    metrics.DataBandPeakPsd_dB, "v", MarkerSize = 7.0, ...
    LineWidth = 1.2);
xline((metrics.PilotFrequency_Hz - metrics.PilotExclusionHalfWidth_Hz) ./ ...
    1.0e6, ":", HandleVisibility = "off");
xline((metrics.PilotFrequency_Hz + metrics.PilotExclusionHalfWidth_Hz) ./ ...
    1.0e6, ":", HandleVisibility = "off");
hold off;
grid on;
xlabel("Frequency [MHz]");
ylabel("Mean PSD from pwelch [dB/Hz]");
title(roleLabel + " Pilot-Excluded Data-Band Prominence");
legend([psdHandle, dataMedianHandle, pilotHandle, dataPeakHandle], ...
    ["Mean PSD", "Data-band median", "Pilot-like line", ...
    "Data-band peak"], Location = "best");

xLimits = xlim;
yLimits = ylim;
annotationText = sprintf( ...
    "Pilot: %.3f [MHz], %.2f [dB]\n" + ...
    "Data-band peak-to-median: %.2f [dB]\n" + ...
    "Pilot exclusion: +/- %.0f [kHz]", ...
    metrics.PilotFrequency_Hz ./ 1.0e6, metrics.PilotProminence_dB, ...
    metrics.DataBandProminence_dB, ...
    metrics.PilotExclusionHalfWidth_Hz ./ 1.0e3);
text(xLimits(1) + 0.03 .* range(xLimits), ...
    yLimits(2) - 0.10 .* range(yLimits), annotationText, ...
    VerticalAlignment = "top", BackgroundColor = "white", Margin = 2.0);

end

function metrics = localComputePilotAwarePsdMetrics(frequency_Hz, psdValues, ...
    pilotExclusionHalfWidth_Hz)

frequency_Hz = double(frequency_Hz(:));
psdValues = max(double(psdValues(:)), eps);
validMask = isfinite(frequency_Hz) & isfinite(psdValues);

if ~any(validMask)
    error("helperPlotPipelineStoryEvidence:InvalidPsd", ...
        "PSD prominence requires finite frequency and PSD values.");
end

validFrequency_Hz = frequency_Hz(validMask);
validPsd = psdValues(validMask);
[pilotPsd, pilotIndex] = max(validPsd, [], "omitnan");
pilotFrequency_Hz = validFrequency_Hz(pilotIndex);
overallMedianPsd = max(median(validPsd, "omitnan"), eps);
pilotExclusionHalfWidth_Hz = max(0.0, ...
    double(pilotExclusionHalfWidth_Hz));
dataBandMask = validMask & abs(frequency_Hz - pilotFrequency_Hz) > ...
    pilotExclusionHalfWidth_Hz;

if ~any(dataBandMask)
    dataBandMask = validMask;
end

dataBandFrequency_Hz = frequency_Hz(dataBandMask);
dataBandPsd = psdValues(dataBandMask);
dataBandMedianPsd = max(median(dataBandPsd, "omitnan"), eps);
[dataBandPeakPsd, dataBandPeakIndex] = max(dataBandPsd, [], "omitnan");
metrics = struct();
metrics.PilotFrequency_Hz = pilotFrequency_Hz;
metrics.PilotPsd_dB = pow2db(max(pilotPsd, eps));
metrics.PilotProminence_dB = pow2db(max(pilotPsd, eps) ./ ...
    overallMedianPsd);
metrics.PilotExclusionHalfWidth_Hz = pilotExclusionHalfWidth_Hz;
metrics.DataBandMedianPsd_dB = pow2db(dataBandMedianPsd);
metrics.DataBandPeakFrequency_Hz = dataBandFrequency_Hz(dataBandPeakIndex);
metrics.DataBandPeakPsd_dB = pow2db(max(dataBandPeakPsd, eps));
metrics.DataBandProminence_dB = pow2db(max(dataBandPeakPsd, eps) ./ ...
    dataBandMedianPsd);

end

function fig = localPlotG2ReceiverMetrics(reportData, plotOptions)

integrityTable = localTable(reportData.G2Stage2, "receiver_integrity_table");
fig = localNewFigure("G2 Receiver Metrics", plotOptions);
layout = tiledlayout(fig, 2, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G2 Receiver Metrics and Weak Reference Evidence");

nexttile(layout);
plot(integrityTable.Repetition, ...
    integrityTable.ReferenceMinusSurveillancePower_dB, "-o", ...
    LineWidth = 1.2);
hold on;
yline(0, "--", "Reference = surveillance");
hold off;
grid on;
xlabel("Repetition");
ylabel("Reference - surveillance [dB]");
title("Reference Power Relationship");

nexttile(layout);
plot(integrityTable.Repetition, ...
    integrityTable.ReferencePeakHeadroom_dB, "-o", LineWidth = 1.2);
hold on;
plot(integrityTable.Repetition, ...
    integrityTable.SurveillancePeakHeadroom_dB, "-s", LineWidth = 1.2);
hold off;
grid on;
xlabel("Repetition");
ylabel("Peak headroom [dB]");
title("Headroom");
legend(["Reference", "Surveillance"], Location = "best");

nexttile(layout);
plot(integrityTable.Repetition, ...
    integrityTable.ReferenceDcSpike_dB, "-o", LineWidth = 1.2);
hold on;
plot(integrityTable.Repetition, ...
    integrityTable.SurveillanceDcSpike_dB, "-s", LineWidth = 1.2);
yline(3.0, "--", "Retune");
hold off;
grid on;
xlabel("Repetition");
ylabel("DC spike [dB]");
title("DC and LO Contamination Proxy");
legend(["Reference", "Surveillance", "Retune"], Location = "best");

nexttile(layout);
plot(integrityTable.Repetition, ...
    integrityTable.ReferenceIqImpropriety, "-o", LineWidth = 1.2);
hold on;
plot(integrityTable.Repetition, ...
    integrityTable.SurveillanceIqImpropriety, "-s", LineWidth = 1.2);
yline(0.05, "--", "Retune");
hold off;
grid on;
xlabel("Repetition");
ylabel("IQ impropriety [ratio]");
title("IQ/Image Proxy");
legend(["Reference", "Surveillance", "Retune"], Location = "best");

end

function fig = localPlotG3SyncOverview(reportData, plotOptions)

lagTable = localTable(reportData.G3, "lag_table");
frequencyTable = localTable(reportData.G3, "residual_frequency_table");
coherenceTable = localTable(reportData.G3, "cpi_coherence_table");
fig = localNewFigure("G3 Sync Overview", plotOptions);
layout = tiledlayout(fig, 2, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G3 Synchronization Evidence");

nexttile(layout);
localPlotByCpi(lagTable, "Repetition", "LagWindowSpread_samples");
grid on;
xlabel("Repetition");
ylabel("Lag spread [samples]");
title("Lag Stability");

nexttile(layout);
localPlotByCpi(lagTable, "Repetition", "PeakToSidelobeMin_dB");
grid on;
xlabel("Repetition");
ylabel("Peak-to-sidelobe minimum [dB]");
title("Correlation Sharpness");

nexttile(layout);
localPlotByCpi(frequencyTable, "Repetition", ...
    "ResidualFrequencyAbsMax_Hz");
grid on;
xlabel("Repetition");
ylabel("Residual frequency max [Hz]");
title("Residual Frequency");

nexttile(layout);
localPlotByCpi(coherenceTable, "Repetition", "CoherencePassFraction");
grid on;
xlabel("Repetition");
ylabel("Coherence pass fraction [ratio]");
title("CPI Coherence");

end

function fig = localPlotG4BaselineMaps(reportData, plotOptions)

mapRecord = localSelectG4Map(reportData);
mapSummaryTable = localTable(reportData.G4, "map_summary_table");
summaryRows = mapSummaryTable( ...
    string(mapSummaryTable.CpiLabel) == string(mapRecord.CpiLabel) & ...
    string(mapSummaryTable.WindowLabel) == string(mapRecord.WindowLabel), :);
fig = localNewFigure("G4 Baseline Maps", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G4 Passive Ambiguity Map Evidence");

nexttile(layout);
imagesc(mapRecord.DisplayDelayAxis_samples, ...
    mapRecord.DisplayDopplerAxis_Hz, mapRecord.Map_dB);
axis xy;
colorbar;
hold on;
plot(mapRecord.DirectPathDelay_samples, ...
    mapRecord.DirectPathDoppler_Hz, "wx", MarkerSize = 9.0, ...
    LineWidth = 1.5);
hold off;
xlabel("Display delay [samples]");
ylabel("Display Doppler [Hz]");
title("Representative Map");

nexttile(layout);
plot(summaryRows.Repetition, summaryRows.DirectPathToOffRidgeEnergy_dB, ...
    "-o", LineWidth = 1.2);
grid on;
xlabel("Repetition");
ylabel("Direct path to off-ridge [dB]");
title("Direct-Path Trend");

end

function fig = localPlotG4SceneObservability(reportData, plotOptions)

sceneTable = localTable(reportData.G4, "scene_metric_medians");
centerRows = sceneTable(string(sceneTable.WindowLabel) == "center", :);

if isempty(centerRows)
    centerRows = sceneTable;
end

categories = categorical(string(centerRows.CpiLabel));
categories = reordercats(categories, string(centerRows.CpiLabel));
fig = localNewFigure("G4 Scene Observability", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G4 Scene Observability Limits");

nexttile(layout);
bar(categories, centerRows.DirectPathToOffRidgeEnergy_dB);
grid on;
xlabel("CPI label");
ylabel("Direct path to off-ridge [dB]");
title("Direct Path Dominance");
localUseLiteralTickLabels();

nexttile(layout);
semilogy(categories, ...
    centerRows.OffOriginOccupiedFraction_abovePeakMinus20dB, "o-", ...
    LineWidth = 1.2);
grid on;
xlabel("CPI label");
ylabel("Off-origin occupied fraction [ratio]");
title("Off-Origin Occupancy");
localUseLiteralTickLabels();

end

function fig = localPlotG45SuiteSummary(reportData, plotOptions)

[targetRows, categories, recoveryScore, delayErrorMapBins, options] = ...
    localPrepareG45StudySummary(reportData);
fig = localNewFigure("G4.5 Study Summary", plotOptions);
layout = tiledlayout(fig, 2, 3, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G4.5 Center-Window Synthetic Recovery Study");

nexttile(layout);
bar(categories, recoveryScore);
ylim([0, 2]);
yticks([0, 1, 2]);
yticklabels(["Not", "Weak", "Recovered"]);
grid on;
xlabel("Case/target");
ylabel("Recovery status [ordinal]");
title("Center-Window Recovery");
xtickangle(35);
localUseLiteralTickLabels();

nexttile(layout);
bar(categories, targetRows.LocalProminence_dB);
hold on;
yline(options.PassProminence_dB, "--", "Pass");
hold off;
grid on;
xlabel("Case/target");
ylabel("Local prominence [dB]");
title("Target Prominence");
xtickangle(35);
localUseLiteralTickLabels();

nexttile(layout);
bar(categories, targetRows.RobustZ);
hold on;
yline(options.PassRobustZ, "--", "Pass");
hold off;
grid on;
xlabel("Case/target");
ylabel("Robust Z [score]");
title("Robust Local Score");
xtickangle(35);
localUseLiteralTickLabels();

nexttile(layout);
bar(categories, targetRows.ControlLift_dB);
hold on;
yline(options.MinControlLiftForPass_dB, "--", "Pass");
hold off;
grid on;
xlabel("Case/target");
ylabel("Lift over pre-injection background [dB]");
title("Control Lift");
xtickangle(35);
localUseLiteralTickLabels();

nexttile(layout);
bar(categories, delayErrorMapBins);
hold on;
yline(options.DelayToleranceMapBins, "--", "Tolerance");
hold off;
grid on;
xlabel("Case/target");
ylabel("Delay error [map bins]");
title("Delay Error");
xtickangle(35);
localUseLiteralTickLabels();

nexttile(layout);
bar(categories, targetRows.DopplerError_Hz);
hold on;
yline(options.DopplerTolerance_Hz, "--", "Tolerance");
hold off;
grid on;
xlabel("Case/target");
ylabel("Doppler error [Hz]");
title("Doppler Error");
xtickangle(35);
localUseLiteralTickLabels();

end

function fig = localPlotG45RecoveryProminenceSummary(reportData, plotOptions)

[targetRows, categories, recoveryScore, ~, options] = ...
    localPrepareG45StudySummary(reportData);
fig = localNewFigure("G4.5 Recovery and Prominence Summary", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G4.5 Center-Window Recovery and Local Prominence");

nexttile(layout);
bar(categories, recoveryScore);
ylim([0, 2]);
yticks([0, 1, 2]);
yticklabels(["Not", "Weak", "Recovered"]);
grid on;
xlabel("Case/target");
ylabel("Recovery status [ordinal]");
title("Recovery Status");
xtickangle(35);
localUseLiteralTickLabels();

nexttile(layout);
bar(categories, targetRows.LocalProminence_dB);
hold on;
yline(options.PassProminence_dB, "--", "Pass");
hold off;
grid on;
xlabel("Case/target");
ylabel("Local prominence [dB]");
title("Local Prominence");
xtickangle(35);
localUseLiteralTickLabels();

end

function fig = localPlotG45ScoreLiftSummary(reportData, plotOptions)

[targetRows, categories, ~, ~, options] = ...
    localPrepareG45StudySummary(reportData);
fig = localNewFigure("G4.5 Score and Lift Summary", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G4.5 Center-Window Robust Score and Control Lift");

nexttile(layout);
bar(categories, targetRows.RobustZ);
hold on;
yline(options.PassRobustZ, "--", "Pass");
hold off;
grid on;
xlabel("Case/target");
ylabel("Robust Z [score]");
title("Robust Local Score");
xtickangle(35);
localUseLiteralTickLabels();

nexttile(layout);
bar(categories, targetRows.ControlLift_dB);
hold on;
yline(options.MinControlLiftForPass_dB, "--", "Pass");
hold off;
grid on;
xlabel("Case/target");
ylabel("Lift over pre-injection background [dB]");
title("Control Lift");
xtickangle(35);
localUseLiteralTickLabels();

end

function fig = localPlotG45AssociationErrorSummary(reportData, plotOptions)

[targetRows, categories, ~, delayErrorMapBins, options] = ...
    localPrepareG45StudySummary(reportData);
fig = localNewFigure("G4.5 Association Error Summary", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G4.5 Center-Window Association Error");

nexttile(layout);
bar(categories, delayErrorMapBins);
hold on;
yline(options.DelayToleranceMapBins, "--", "Tolerance");
hold off;
grid on;
xlabel("Case/target");
ylabel("Delay error [map bins]");
title("Delay Error");
xtickangle(35);
localUseLiteralTickLabels();

nexttile(layout);
bar(categories, targetRows.DopplerError_Hz);
hold on;
yline(options.DopplerTolerance_Hz, "--", "Tolerance");
hold off;
grid on;
xlabel("Case/target");
ylabel("Doppler error [Hz]");
title("Doppler Error");
xtickangle(35);
localUseLiteralTickLabels();

end

function fig = localPlotG45PreInjectionMap(reportData, plotOptions)

caseRecord = localSelectG45CaseRecord(reportData, plotOptions.G45MapCaseId);
mapRecord = localSelectG45ControlMap(caseRecord, ...
    plotOptions.G45MapWindowLabel);
targetRows = localSelectG45TargetRows(caseRecord, mapRecord.WindowLabel);
axisContext = localBuildG45PhysicalAxisContext(mapRecord, caseRecord);
fig = localNewFigure("G4.5 Real Background Before Synthetic Echo", ...
    plotOptions);
layout = tiledlayout(fig, 1, 1, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G4.5 Real Background Before ADS-B-Derived Synthetic Echo");
nexttile(layout);
localPlotG45MapImage(mapRecord, axisContext);
hold on;
[legendHandles, legendLabels] = localDrawG45TargetMarkers(targetRows, ...
    caseRecord.Analysis.Options, caseRecord.Analysis.MapSampleRateHz, ...
    false, false, axisContext);
localMaybeLegend(legendHandles, legendLabels);
hold off;
title("Pre-Injection Real Background at Target Coordinates");

end
function fig = localPlotG45InjectedOverlayMap(reportData, plotOptions)

caseRecord = localSelectG45CaseRecord(reportData, plotOptions.G45MapCaseId);
mapRecord = localSelectG45Map(caseRecord, plotOptions.G45MapWindowLabel);
targetRows = localSelectG45TargetRows(caseRecord, mapRecord.WindowLabel);
axisContext = localBuildG45PhysicalAxisContext(mapRecord, caseRecord);
fig = localNewFigure("G4.5 Synthetic Echo over Real Background", ...
    plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G4.5 ADS-B-Derived Synthetic Echo over Real HDTV IQ Background");

nexttile(layout);
localPlotG45MapImage(mapRecord, axisContext);
hold on;
[legendHandles, legendLabels] = localDrawG45TargetMarkers(targetRows, ...
    caseRecord.Analysis.Options, caseRecord.Analysis.MapSampleRateHz, ...
    true, true, axisContext);
localMaybeLegend(legendHandles, legendLabels);
hold off;
title("Injected Echo Map");

nexttile(layout);
localPlotG45MapImage(mapRecord, axisContext);
hold on;
[legendHandles, legendLabels] = localDrawG45TargetMarkers(targetRows, ...
    caseRecord.Analysis.Options, caseRecord.Analysis.MapSampleRateHz, ...
    true, true, axisContext);
localMaybeLegend(legendHandles, legendLabels);
localApplyG45TargetZoom(targetRows, caseRecord.Analysis.Options, ...
    caseRecord.Analysis.MapSampleRateHz, axisContext);
hold off;
title("Zoomed Target View");

end
function fig = localPlotG45AssociationMap(reportData, plotOptions)

caseRecord = localSelectG45CaseRecord(reportData, plotOptions.G45MapCaseId);
mapRecord = localSelectG45Map(caseRecord, plotOptions.G45MapWindowLabel);
targetRows = localSelectG45TargetRows(caseRecord, mapRecord.WindowLabel);
axisContext = localBuildG45PhysicalAxisContext(mapRecord, caseRecord);
fig = localNewFigure("G4.5 Association Map", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G4.5 Algorithm Association Against Expected Synthetic Target");

nexttile(layout);
localPlotG45MapImage(mapRecord, axisContext);
hold on;
[legendHandles, legendLabels] = localDrawG45TargetMarkers(targetRows, ...
    caseRecord.Analysis.Options, caseRecord.Analysis.MapSampleRateHz, ...
    true, true, axisContext);
localMaybeLegend(legendHandles, legendLabels);
hold off;
title("Full Association Map");

nexttile(layout);
localPlotG45MapImage(mapRecord, axisContext);
hold on;
[legendHandles, legendLabels] = localDrawG45TargetMarkers(targetRows, ...
    caseRecord.Analysis.Options, caseRecord.Analysis.MapSampleRateHz, ...
    true, true, axisContext);
localMaybeLegend(legendHandles, legendLabels);
localApplyG45TargetZoom(targetRows, caseRecord.Analysis.Options, ...
    caseRecord.Analysis.MapSampleRateHz, axisContext);
hold off;
title("Zoomed Association and Tolerance");

end
function fig = localPlotG45RecoveryMaps(reportData, plotOptions)

caseRecord = localSelectG45CaseRecord(reportData, plotOptions.G45MapCaseId);
mapRecord = localSelectG45Map(caseRecord, plotOptions.G45MapWindowLabel);
targetRows = localSelectG45TargetRows(caseRecord, mapRecord.WindowLabel);
axisContext = localBuildG45PhysicalAxisContext(mapRecord, caseRecord);
fig = localNewFigure("G4.5 Recovery Maps", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G4.5 Physical-Scale Range-Doppler Evidence");

nexttile(layout);
localPlotG45MapImage(mapRecord, axisContext);
title("Physical-Scale Synthetic Recovery Map");

nexttile(layout);
localPlotG45MapImage(mapRecord, axisContext);
hold on;

if ~isempty(targetRows)
    plot(localG45DelayToExcessRange(targetRows.AssociationDelay_s, ...
        axisContext), localG45DopplerToRangeRate( ...
        targetRows.AssociationDoppler_Hz, axisContext), ...
        "wo", MarkerSize = 7.0, ...
        LineWidth = 1.2);
    plot(localG45DelayToExcessRange(targetRows.AssociatedDelay_s, ...
        axisContext), localG45DopplerToRangeRate( ...
        targetRows.AssociatedDoppler_Hz, axisContext), ...
        "rx", MarkerSize = 8.0, ...
        LineWidth = 1.4);
    legend(["Expected", "Associated"], Location = "best");
end

hold off;
title("Annotated Target Association");

end

function fig = localPlotG5MitigationOverview(reportData, plotOptions)

suppressionTable = localTable(reportData.G5, "suppression_summary_table");
retentionTable = localTable(reportData.G5, ...
    "protected_region_retention_table");
categories = categorical(string(suppressionTable.CandidateName));
categories = reordercats(categories, string(suppressionTable.CandidateName));
fig = localNewFigure("G5 Mitigation Overview", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G5 Mitigation Diagnostic Evidence");

nexttile(layout);
bar(categories, suppressionTable.MedianDirectPathSuppression_dB);
grid on;
xlabel("Candidate");
ylabel("Suppression [dB]");
title("Direct-Path Suppression");
localUseLiteralTickLabels();

nexttile(layout);
retentionCategories = categorical(string(retentionTable.CandidateName));
retentionCategories = reordercats(retentionCategories, ...
    string(retentionTable.CandidateName));
bar(retentionCategories, retentionTable.MedianProtectedRetentionRatio);
hold on;
yline(0.5, "--", "Minimum");
hold off;
grid on;
xlabel("Candidate");
ylabel("Retention ratio [ratio]");
title("Protected-Region Retention");
localUseLiteralTickLabels();

end

function fig = localPlotG5DiagnosticSensitivity(reportData, plotOptions)

profileTable = localTable(reportData.G5Diagnostic, ...
    "profile_sweep_summary_table");
thresholdTable = localTable(reportData.G5Diagnostic, ...
    "threshold_sensitivity_table");
profileLabels = categorical(profileTable.ProfileId + "/" + ...
    profileTable.CandidateName);
profileLabels = reordercats(profileLabels, profileTable.ProfileId + "/" + ...
    profileTable.CandidateName);
thresholdRowLabels = thresholdTable.ProfileId + "/" + ...
    thresholdTable.CandidateName + "/" + thresholdTable.ThresholdCase;
thresholdLabels = categorical(thresholdRowLabels);
thresholdLabels = reordercats(thresholdLabels, thresholdRowLabels);
fig = localNewFigure("G5 Diagnostic Sensitivity", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G5 Diagnostic Threshold and Profile Sensitivity");

nexttile(layout);
bar(profileLabels, profileTable.DiagnosticScore);
grid on;
xlabel("Profile/candidate");
ylabel("Diagnostic score [score]");
title("Profile Ranking");
localUseLiteralTickLabels();

nexttile(layout);
bar(thresholdLabels, double(thresholdTable.WouldRevealScene));
grid on;
xlabel("Threshold case");
ylabel("Would reveal scene [0/1]");
title("Threshold Outcome");
localUseLiteralTickLabels();

end

function fig = localPlotG6G8Readiness(reportData, plotOptions)

g6FreezeTable = localTable(reportData.G6, "freeze_decision_table");
g7ClaimTable = localTable(reportData.G7, "claim_gate_table");
g8ExecutionTable = localTable(reportData.G8, "execution_decision_table");
g8BlockTable = localTable(reportData.G8, "prerequisite_block_table");
readinessLabels = categorical([
    "G6 freeze"
    "G7 truth claims"
    "G8 CFAR"
    "G8 tuning"
    "G8 detection table"
    ]);
readinessValues = [
    double(g6FreezeTable.DetectorProductFreezeEnabled(1))
    double(g7ClaimTable.TruthClaimsEnabled(1))
    double(g8ExecutionTable.CfarExecutionEnabled(1))
    double(g8ExecutionTable.DetectorTuningEnabled(1))
    double(g8ExecutionTable.DetectionTableEmitted(1))
    ];
fig = localNewFigure("G6-G8 Readiness", plotOptions);
layout = tiledlayout(fig, 1, 2, TileSpacing = "compact", ...
    Padding = "compact");
title(layout, "G6-G8 Downstream Readiness Refusal");

nexttile(layout);
bar(readinessLabels, readinessValues);
ylim([0, 1]);
grid on;
xlabel("Prerequisite");
ylabel("Enabled [0/1]");
title("Execution Enablement");
localUseLiteralTickLabels();

nexttile(layout);
blockLabels = categorical(string(g8BlockTable.BlockCode));
blockLabels = reordercats(blockLabels, string(g8BlockTable.BlockCode));
bar(blockLabels, ones(height(g8BlockTable), 1));
grid on;
xlabel("Block code");
ylabel("Blocking evidence [count]");
title("G8 Prerequisite Blocks");
localUseLiteralTickLabels();

end

function [targetRows, categories, recoveryScore, delayErrorMapBins, ...
    options] = localPrepareG45StudySummary(reportData)

targetRows = localSelectG45StudyRows(reportData.G45.TargetRecoveryTable);
rowLabels = localBuildG45StudyLabels(targetRows);
categories = categorical(rowLabels);
categories = reordercats(categories, rowLabels);
recoveryScore = localRecoveryStatusScore(targetRows.RecoveryStatus);
delayErrorMapBins = localG45DelayErrorMapBins(targetRows, reportData);
options = reportData.G45.CaseRecords(1).Analysis.Options;

end

function studyRows = localSelectG45StudyRows(targetTable)

caseOrder = [
    "easy_single_target"
    "medium_single_target"
    "hard_single_target"
    "marginal_single_target"
    "multi_target"
    ];
caseIds = string(targetTable.CaseDatasetId);
caseMask = ismember(caseIds, caseOrder);
centerMask = string(targetTable.WindowLabel) == "center";
studyRows = targetTable(caseMask & centerMask, :);

if isempty(studyRows)
    studyRows = targetTable(caseMask, :);
end

[~, caseOrderIndex] = ismember(string(studyRows.CaseDatasetId), caseOrder);
caseOrderIndex(caseOrderIndex == 0) = numel(caseOrder) + 1;
[~, sortIndex] = sort(caseOrderIndex);
studyRows = studyRows(sortIndex, :);

end

function rowLabels = localBuildG45StudyLabels(targetRows)

rowLabels = string(targetRows.CaseDatasetId) + "/" + ...
    string(targetRows.TargetId);

end

function delayErrorMapBins = localG45DelayErrorMapBins(targetRows, reportData)

caseIds = string(targetRows.CaseDatasetId);
caseRecordIds = string({reportData.G45.CaseRecords.CaseDatasetId});
delayErrorMapBins = NaN(height(targetRows), 1);

for rowIndex = 1:height(targetRows)
    caseRecordIndex = find(caseRecordIds == caseIds(rowIndex), 1, "first");

    if isempty(caseRecordIndex)
        continue
    end

    mapSampleRateHz = ...
        double(reportData.G45.CaseRecords(caseRecordIndex).Analysis.MapSampleRateHz);
    delayErrorMapBins(rowIndex) = ...
        double(targetRows.DelayError_s(rowIndex)) .* mapSampleRateHz;
end

end
function recoveryScore = localRecoveryStatusScore(recoveryStatus)


statusText = upper(string(recoveryStatus));
recoveryScore = zeros(numel(statusText), 1);
recoveryScore(statusText == "WEAK_RECOVERY") = 1.0;
recoveryScore(statusText == "RECOVERED") = 2.0;

end

function axisContext = localBuildG45PhysicalAxisContext(mapRecord, caseRecord)

lightSpeed_mps = physconst("LightSpeed");
centerFrequency_Hz = localG45CenterFrequencyHz(caseRecord);
wavelength_m = lightSpeed_mps ./ centerFrequency_Hz;
delayAxis_s = double(mapRecord.DelayAxis_s(:)).';
dopplerAxis_Hz = double(mapRecord.DopplerAxis_Hz(:));
rangeAxis_m = -delayAxis_s .* lightSpeed_mps;
rangeRateAxis_mps = dopplerAxis_Hz .* wavelength_m;
[rangeAxis_m, rangeOrder] = sort(rangeAxis_m);
[rangeRateAxis_mps, rangeRateOrder] = sort(rangeRateAxis_mps);
reviewMap_dB = double(mapRecord.ReviewMap_dB);

axisContext = struct();
axisContext.LightSpeed_mps = lightSpeed_mps;
axisContext.CenterFrequency_Hz = centerFrequency_Hz;
axisContext.Wavelength_m = wavelength_m;
axisContext.RangeAxis_m = rangeAxis_m;
axisContext.RangeRateAxis_mps = rangeRateAxis_mps;
axisContext.ReviewMap_dB = reviewMap_dB(rangeRateOrder, rangeOrder);

end

function centerFrequency_Hz = localG45CenterFrequencyHz(caseRecord)

centerFrequency_Hz = NaN;

if isfield(caseRecord, "TruthJson") && ...
        isfield(caseRecord.TruthJson, "center_frequency_hz")
    centerFrequency_Hz = double(caseRecord.TruthJson.center_frequency_hz);
end

if ~(isfinite(centerFrequency_Hz) && centerFrequency_Hz > 0)
    error("helperPlotPipelineStoryEvidence:MissingG45CenterFrequency", ...
        "G4.5 case %s does not provide a valid center_frequency_hz field.", ...
        string(caseRecord.CaseDatasetId));
end

end

function excessRange_m = localG45DelayToExcessRange(delay_s, axisContext)

excessRange_m = -double(delay_s) .* axisContext.LightSpeed_mps;

end

function rangeRate_mps = localG45DopplerToRangeRate(doppler_Hz, axisContext)

rangeRate_mps = double(doppler_Hz) .* axisContext.Wavelength_m;

end

function localPlotG45MapImage(~, axisContext)

imagesc(axisContext.RangeAxis_m, axisContext.RangeRateAxis_mps, ...
    axisContext.ReviewMap_dB);
axis xy;
colorbar;
grid on;
xlabel("Bistatic excess range [m]");
ylabel("Bistatic range-rate [m/s]");

end

function [legendHandles, legendLabels] = localDrawG45TargetMarkers( ...
    targetRows, options, mapSampleRateHz, includeAssociated, ...
    includeTolerance, axisContext)

legendHandles = gobjects(0, 1);
legendLabels = strings(0, 1);

if isempty(targetRows)
    return
end

expectedHandle = plot(localG45DelayToExcessRange( ...
    targetRows.AssociationDelay_s, axisContext), ...
    localG45DopplerToRangeRate(targetRows.AssociationDoppler_Hz, ...
    axisContext), "wo", MarkerSize = 8.0, LineWidth = 1.4);
legendHandles(end + 1, 1) = expectedHandle;
legendLabels(end + 1, 1) = "Expected";

hasAssociatedColumns = all(ismember(["AssociatedDelay_s", ...
    "AssociatedDoppler_Hz"], string(targetRows.Properties.VariableNames)));

if includeAssociated && hasAssociatedColumns
    associatedHandle = plot(localG45DelayToExcessRange( ...
        targetRows.AssociatedDelay_s, axisContext), ...
        localG45DopplerToRangeRate(targetRows.AssociatedDoppler_Hz, ...
        axisContext), "rx", MarkerSize = 9.0, LineWidth = 1.6);
    legendHandles(end + 1, 1) = associatedHandle;
    legendLabels(end + 1, 1) = "Associated";
end

if includeTolerance
    toleranceHandle = plot(NaN, NaN, "w--", LineWidth = 1.1);
    localDrawAssociationTolerance(targetRows, options, mapSampleRateHz, ...
        axisContext);
    legendHandles(end + 1, 1) = toleranceHandle;
    legendLabels(end + 1, 1) = "Tolerance";
end

end

function localMaybeLegend(legendHandles, legendLabels)

if isempty(legendHandles)
    return
end

legendHandle = legend(legendHandles, legendLabels, Location = "best");
legendHandle.Interpreter = "none";

end

function localApplyG45TargetZoom(targetRows, options, mapSampleRateHz, ...
    axisContext)

if isempty(targetRows)
    return
end

rangeValues_m = localG45DelayToExcessRange( ...
    targetRows.AssociationDelay_s, axisContext);
rangeRateValues_mps = localG45DopplerToRangeRate( ...
    targetRows.AssociationDoppler_Hz, axisContext);
hasAssociatedColumns = all(ismember(["AssociatedDelay_s", ...
    "AssociatedDoppler_Hz"], string(targetRows.Properties.VariableNames)));

if hasAssociatedColumns
    rangeValues_m = [rangeValues_m; ...
        localG45DelayToExcessRange(targetRows.AssociatedDelay_s, ...
        axisContext)];
    rangeRateValues_mps = [rangeRateValues_mps; ...
        localG45DopplerToRangeRate(targetRows.AssociatedDoppler_Hz, ...
        axisContext)];
end

validMask = isfinite(rangeValues_m) & isfinite(rangeRateValues_mps);

if ~any(validMask)
    return
end

rangeValues_m = rangeValues_m(validMask);
rangeRateValues_mps = rangeRateValues_mps(validMask);
rangeTolerance_m = double(options.DelayToleranceMapBins) ./ ...
    double(mapSampleRateHz) .* axisContext.LightSpeed_mps;
rangeRateTolerance_mps = double(options.DopplerTolerance_Hz) .* ...
    axisContext.Wavelength_m;
rangePadding_m = max([3.0 .* rangeTolerance_m, ...
    5.0 .* localMedianAxisSpacing(axisContext.RangeAxis_m), eps]);
rangeRatePadding_mps = max([3.0 .* rangeRateTolerance_mps, ...
    5.0 .* localMedianAxisSpacing(axisContext.RangeRateAxis_mps), eps]);
xLimits = [min(rangeValues_m) - rangePadding_m, ...
    max(rangeValues_m) + rangePadding_m];
yLimits = [min(rangeRateValues_mps) - rangeRatePadding_mps, ...
    max(rangeRateValues_mps) + rangeRatePadding_mps];
xlim(localClampAxisLimits(xLimits, axisContext.RangeAxis_m));
ylim(localClampAxisLimits(yLimits, axisContext.RangeRateAxis_mps));

end

function spacing = localMedianAxisSpacing(axisValues)

axisValues = sort(unique(double(axisValues(:))));
axisValues = axisValues(isfinite(axisValues));

if numel(axisValues) < 2
    spacing = 0.0;
else
    spacing = median(abs(diff(axisValues)), "omitnan");
end

end

function clampedLimits = localClampAxisLimits(requestedLimits, axisValues)

axisValues = double(axisValues(:));
axisValues = axisValues(isfinite(axisValues));
clampedLimits = double(requestedLimits);

if isempty(axisValues)
    return
end

axisLimits = [min(axisValues), max(axisValues)];
clampedLimits = [max(axisLimits(1), clampedLimits(1)), ...
    min(axisLimits(2), clampedLimits(2))];

if clampedLimits(1) >= clampedLimits(2)
    clampedLimits = double(requestedLimits);
end

end
function localDrawAssociationTolerance(targetRows, options, mapSampleRateHz, ...
    axisContext)

for rowIndex = 1:height(targetRows)
    rangeTolerance_m = double(options.DelayToleranceMapBins) ./ ...
        double(mapSampleRateHz) .* axisContext.LightSpeed_mps;
    rangeRateTolerance_mps = double(options.DopplerTolerance_Hz) .* ...
        axisContext.Wavelength_m;
    centerRange_m = localG45DelayToExcessRange( ...
        targetRows.AssociationDelay_s(rowIndex), axisContext);
    centerRangeRate_mps = localG45DopplerToRangeRate( ...
        targetRows.AssociationDoppler_Hz(rowIndex), axisContext);
    tolerancePosition = [
        centerRange_m - rangeTolerance_m, ...
        centerRangeRate_mps - rangeRateTolerance_mps, ...
        2.0 .* rangeTolerance_m, ...
        2.0 .* rangeRateTolerance_mps
        ];
    rectangle(Position = tolerancePosition, EdgeColor = "w", ...
        LineStyle = "--", LineWidth = 1.0, HandleVisibility = "off");
end

end

function localPlotByCpi(inputTable, xVariableName, yVariableName)

cpiLabels = unique(string(inputTable.CpiLabel), "stable");
hold on;

for cpiIndex = 1:numel(cpiLabels)
    cpiMask = string(inputTable.CpiLabel) == cpiLabels(cpiIndex);
    plot(inputTable.(xVariableName)(cpiMask), ...
        inputTable.(yVariableName)(cpiMask), "-o", LineWidth = 1.0);
end

hold off;
legendHandle = legend(cpiLabels, Location = "best");
legendHandle.Interpreter = "none";

end

function localUseLiteralTickLabels()

currentAxes = gca;
currentAxes.TickLabelInterpreter = "none";

end

function outputTable = localTable(gateData, tableKey)

tableKey = matlab.lang.makeValidName(string(tableKey));

if ~isfield(gateData.Tables, tableKey)
    error("helperPlotPipelineStoryEvidence:MissingLoadedTable", ...
        "Loaded gate %s does not contain table key %s.", ...
        gateData.PhaseId, tableKey);
end

outputTable = gateData.Tables.(tableKey);

end

function mapRecord = localSelectG4Map(reportData)

metricsData = reportData.G4.Mat.metrics;

if ~isfield(metricsData, "analysis") || ...
        ~isfield(metricsData.analysis, "RepresentativeMaps")
    error("helperPlotPipelineStoryEvidence:MissingG4Maps", ...
        "G4 metrics.mat does not contain analysis.RepresentativeMaps.");
end

maps = metricsData.analysis.RepresentativeMaps;
cpiLabels = string({maps.CpiLabel});
windowLabels = string({maps.WindowLabel});
match = cpiLabels == "long" & windowLabels == "center";

if ~any(match)
    match = true(numel(maps), 1);
end

mapRecord = maps(find(match, 1, "first"));

end

function caseRecord = localSelectG45CaseRecord(reportData, caseDatasetId)

caseIds = string({reportData.G45.CaseRecords.CaseDatasetId});
match = caseIds == string(caseDatasetId);

if ~any(match)
    error("helperPlotPipelineStoryEvidence:MissingG45Case", ...
        "G4.5 case %s was not found in the loaded story report.", ...
        string(caseDatasetId));
end

caseRecord = reportData.G45.CaseRecords(find(match, 1, "first"));

end

function mapRecord = localSelectG45Map(caseRecord, windowLabel)

maps = caseRecord.Analysis.RepresentativeMaps;
windowLabels = string({maps.WindowLabel});
match = windowLabels == string(windowLabel);

if ~any(match)
    match = true(numel(maps), 1);
end

mapRecord = maps(find(match, 1, "first"));

end

function mapRecord = localSelectG45ControlMap(caseRecord, windowLabel)

analysis = caseRecord.Analysis;

if ~isfield(analysis, "ControlRepresentativeMaps") || ...
        isempty(analysis.ControlRepresentativeMaps)
    error("helperPlotPipelineStoryEvidence:MissingG45ControlMaps", ...
        "G4.5 metrics.mat for case %s does not contain matched ControlRepresentativeMaps. Regenerate the canonical G4.5 suite before rendering before-injection story plots.", ...
        string(caseRecord.CaseDatasetId));
end

maps = analysis.ControlRepresentativeMaps;
windowLabels = string({maps.WindowLabel});
match = windowLabels == string(windowLabel);

if ~any(match)
    error("helperPlotPipelineStoryEvidence:MissingG45ControlWindow", ...
        "G4.5 case %s has ControlRepresentativeMaps, but none for window %s.", ...
        string(caseRecord.CaseDatasetId), string(windowLabel));
end

mapRecord = maps(find(match, 1, "first"));

end

function targetRows = localSelectG45TargetRows(caseRecord, windowLabel)

targetTable = caseRecord.TargetRecoveryTable;

if isempty(targetTable)
    targetRows = targetTable;
    return
end

windowMask = string(targetTable.WindowLabel) == string(windowLabel);
targetRows = targetTable(windowMask, :);

if isempty(targetRows)
    targetRows = targetTable;
end

end

function fig = localNewFigure(figureName, plotOptions)

if plotOptions.ShowFigures
    visibleState = "on";
else
    visibleState = "off";
end

fig = figure(Name = figureName, Visible = visibleState);

end

function figurePath = localMaybeExportFigure(fig, evidenceId, plotOptions)

figurePath = "";

if ~plotOptions.ExportFigures
    return
end

localEnsureFolder(plotOptions.ExportRoot);
figurePath = fullfile(plotOptions.ExportRoot, ...
    evidenceId + "." + plotOptions.ImageFormat);

try
    exportgraphics(fig, figurePath, Resolution = 150);
catch exportException
    error("helperPlotPipelineStoryEvidence:ExportFailed", ...
        "Failed to export pipeline story figure %s: %s", ...
        figurePath, exportException.message);
end

end

function output = localBuildPlotOutput(evidenceId, figurePath)

output = struct();
output.EvidenceId = evidenceId;
output.FigurePath = figurePath;
output.Exported = strlength(figurePath) > 0 && isfile(figurePath);
output.FigureTable = table( ...
    evidenceId, figurePath, output.Exported, ...
    VariableNames = {'EvidenceId', 'FigurePath', 'Exported'});

end

function values_dB = localPowerToDb(values)

values = max(double(values), eps);
values_dB = pow2db(values);

end


function localEnsureFolder(folderPath)

if isfolder(folderPath)
    return
end

try
    mkdir(folderPath);
catch folderException
    error("helperPlotPipelineStoryEvidence:CreateFolderFailed", ...
        "Failed to create folder %s: %s", folderPath, ...
        folderException.message);
end

end
