function verification = verifyPipelineStoryReport(datasetId, repoRoot, options)
%VERIFYPIPELINESTORYREPORT Verify artifact-only pipeline story report.

arguments
    datasetId (1,1) string = "20260622T102123"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

repoRoot = helperResolveRepoRoot(repoRoot);
datasetId = string(datasetId);
resolvedOptions = localResolveOptions(options);

fprintf("Running pipeline story report verification\n");
fprintf("Dataset:\t%s\n", datasetId);
fprintf("Repository root:\t%s\n", repoRoot);

reportOptions = struct();
reportOptions.ExportArtifacts = true;
reportOptions.G45SuiteId = resolvedOptions.G45SuiteId;
reportOptions.G45RunTimestampZ = resolvedOptions.G45RunTimestampZ;

if strlength(resolvedOptions.ExportRoot) > 0
    reportOptions.ExportRoot = resolvedOptions.ExportRoot;
end

reportData = helperBuildPipelineStoryReport(datasetId, repoRoot, ...
    reportOptions);

localAssert(reportData.SourceMode == "artifact_only_no_raw_bb_read", ...
    "Story report source mode must remain artifact-only.");
localAssert(height(reportData.StoryInterpretationTable) >= 9, ...
    "Story interpretation table must cover the gate-review story rows.");
localAssert(all(reportData.ArtifactPathTable.Exists), ...
    "Every listed required story artifact must exist.");
localAssert(~any(contains(reportData.ArtifactPathTable.ArtifactPath, ".bb")), ...
    "Story artifact path table must not include raw .bb captures.");
localVerifySelectedEvidenceIds(reportData);
localVerifyG45AssumptionsSummary(reportData);
localVerifyG45AssumedAircraftPlausibility(reportData);
localVerifyG45ControlMapContract(reportData);
localVerifyG4LatestCompleteSelection(reportData, repoRoot);

plotOptions = struct();
plotOptions.ShowFigures = false;
plotOptions.ExportFigures = true;
plotOptions.ExportRoot = reportData.ExportRoot;
plotOutput = helperPlotPipelineStoryEvidence(reportData, "all", plotOptions);
localAssert(all(plotOutput.FigureTable.Exported), ...
    "Every selected story figure must be exported.");
localVerifyExportedFigureIds(plotOutput);
localVerifyExportedFiguresNonblank(plotOutput);

verification = struct();
verification.Status = "passed";
verification.DatasetId = datasetId;
verification.StoryRunTimestampZ = reportData.StoryRunTimestampZ;
verification.ExportRoot = reportData.ExportRoot;
verification.G4SelectedRunTimestampZ = reportData.G4.Bundle.RunTimestampZ;
verification.G45RunTimestampZ = reportData.G45.RunTimestampZ;
verification.RequiredArtifactCount = height(reportData.ArtifactPathTable);
verification.ExportedFigureCount = height(plotOutput.FigureTable);
verification.StoryInterpretationTable = reportData.StoryInterpretationTable;
verification.FigureTable = plotOutput.FigureTable;

fprintf("Pipeline story verification status:\t%s\n", verification.Status);
fprintf("Story export root:\t%s\n", verification.ExportRoot);
fprintf("G4 selected bundle:\t%s\n", verification.G4SelectedRunTimestampZ);
fprintf("G4.5 selected bundle:\t%s\n", verification.G45RunTimestampZ);
fprintf("Required artifacts checked:\t%d [count]\n", ...
    verification.RequiredArtifactCount);
fprintf("Exported figures checked:\t%d [count]\n", ...
    verification.ExportedFigureCount);

end

function resolvedOptions = localResolveOptions(options)

resolvedOptions = struct();
resolvedOptions.G45SuiteId = "g4_5_real_background_20260807T162306840";
resolvedOptions.G45RunTimestampZ = "latest";
resolvedOptions.ExportRoot = "";

if isfield(options, "G45SuiteId")
    resolvedOptions.G45SuiteId = string(options.G45SuiteId);
end

if isfield(options, "G45RunTimestampZ")
    resolvedOptions.G45RunTimestampZ = string(options.G45RunTimestampZ);
end

if isfield(options, "ExportRoot")
    resolvedOptions.ExportRoot = string(options.ExportRoot);
end

end

function localVerifySelectedEvidenceIds(reportData)

expectedEvidenceIds = [
    "g2_raw_spectrum"
    "g2_reference_surveillance_delta"
    "g2_full_band_power_delta"
    "g2_psd_prominence"
    "g3_sync_overview"
    "g4_baseline_maps"
    "g4_scene_observability"
    "g45_recovery_prominence_summary"
    "g45_score_lift_summary"
    "g45_association_error_summary"
    "g45_pre_injection_map"
    "g45_injected_overlay_map"
    "g45_association_map"
    "g6_g8_readiness"
    ];
actualEvidenceIds = string(reportData.SelectedEvidenceTable.EvidenceId);
localAssert(height(reportData.SelectedEvidenceTable) == 14, ...
    "Selected evidence table must contain 14 story plot IDs.");
missingEvidenceIds = setdiff(expectedEvidenceIds, actualEvidenceIds);
localAssert(isempty(missingEvidenceIds), ...
    "Selected evidence table is missing required story plot IDs: " + ...
    strjoin(missingEvidenceIds, ", "));
localAssert(~any(contains(lower(actualEvidenceIds), "snr")), ...
    "Selected evidence IDs must not use SNR plot names.");
localAssert(~any(contains(lower( ...
    string(reportData.SelectedEvidenceTable.PlotPurpose)), "snr")), ...
    "Selected evidence purposes must not label G2 outputs as SNR.");

end

function localVerifyExportedFigureIds(plotOutput)

expectedFigureIds = [
    "g2_raw_spectrum"
    "g2_reference_surveillance_delta"
    "g2_full_band_power_delta"
    "g2_psd_prominence"
    "g3_sync_overview"
    "g4_baseline_maps"
    "g4_scene_observability"
    "g45_recovery_prominence_summary"
    "g45_score_lift_summary"
    "g45_association_error_summary"
    "g45_pre_injection_map"
    "g45_injected_overlay_map"
    "g45_association_map"
    "g6_g8_readiness"
    ];
actualFigureIds = string(plotOutput.FigureTable.EvidenceId);
localAssert(height(plotOutput.FigureTable) == 14, ...
    "Selected story figure export table must contain 14 figures.");
missingFigureIds = setdiff(expectedFigureIds, actualFigureIds);
localAssert(isempty(missingFigureIds), ...
    "Exported figure table is missing required story plot IDs: " + ...
    strjoin(missingFigureIds, ", "));
localAssert(~any(contains(lower(actualFigureIds), "snr")), ...
    "Exported selected story figure IDs must not use SNR plot names.");

end

function localVerifyG45AssumptionsSummary(reportData)

assumptionTable = reportData.G45.AssumptionsSummaryTable;
requiredVariables = [
    "TxLla_deg_m"
    "RxLla_deg_m"
    "AdsbSourceId"
    "Callsign"
    "ExpectedDelay_s"
    "ExpectedBistaticDoppler_Hz"
    "ExpectedBistaticRange_m"
    "ExpectedBistaticRangeRate_mps"
    "EchoGain_dB"
    "TargetPowerRelativeToBackground_dB"
    "UnavailableAssumptions"
    ];
actualVariables = string(assumptionTable.Properties.VariableNames);
missingVariables = setdiff(requiredVariables, actualVariables);
localAssert(isempty(missingVariables), ...
    "G4.5 assumptions summary is missing variables: " + ...
    strjoin(missingVariables, ", "));
localAssert(height(assumptionTable) >= 5, ...
    "G4.5 assumptions summary must include canonical injected targets.");
localAssert(all(strlength(assumptionTable.TxLla_deg_m) > 0), ...
    "G4.5 assumptions summary must include TX LLA values.");
localAssert(all(strlength(assumptionTable.RxLla_deg_m) > 0), ...
    "G4.5 assumptions summary must include RX LLA values.");
localAssert(all(isfinite(assumptionTable.ExpectedDelay_s)), ...
    "G4.5 assumptions summary must include finite expected delay.");
localAssert(all(isfinite(assumptionTable.ExpectedBistaticDoppler_Hz)), ...
    "G4.5 assumptions summary must include finite expected Doppler.");
localAssert(all(isfinite(assumptionTable.ExpectedBistaticRange_m)), ...
    "G4.5 assumptions summary must include finite expected bistatic range.");
localAssert(all(isfinite(assumptionTable.ExpectedBistaticRangeRate_mps)), ...
    "G4.5 assumptions summary must include finite expected bistatic range-rate.");
localAssert(all(isfinite(assumptionTable.EchoGain_dB)), ...
    "G4.5 assumptions summary must include finite echo gain.");
localAssert(all(isfinite( ...
    assumptionTable.TargetPowerRelativeToBackground_dB)), ...
    "G4.5 assumptions summary must include finite target power relative to background.");
unavailableText = lower(strjoin(assumptionTable.UnavailableAssumptions, "; "));
localAssert(contains(unavailableText, "calibrated bistatic rcs") && ...
    contains(unavailableText, "instantaneous target lla") && ...
    contains(unavailableText, "3d velocity"), ...
    "G4.5 assumptions summary must explicitly list unavailable target assumptions.");

end

function localVerifyG45AssumedAircraftPlausibility(reportData)

plausibilityTable = reportData.G45.AssumedAircraftPlausibilityTable;
requiredVariables = [
    "CaseDatasetId"
    "TargetId"
    "AssumptionLabel"
    "CenterFrequency_Hz"
    "Wavelength_m"
    "TxRxRange_m"
    "ExpectedBistaticExcessRange_m"
    "AssumedTxTargetRange_m"
    "AssumedTargetRxRange_m"
    "NotionalBistaticAngle_deg"
    "AssumedSigmaB_m2"
    "TxAntennaGainRatio_dB"
    "RxAntennaGainRatio_dB"
    "CombinedLossFactor_dB"
    "EchoToDirectRatio"
    "EchoToDirectRatio_dB"
    "SyntheticTargetPowerRelativeToBackground_dB"
    "EchoDirectVsSyntheticBackgroundOffset_dB"
    "ComparisonBasis"
    "ForwardQuestion"
    "Caveat"
    ];
actualVariables = string(plausibilityTable.Properties.VariableNames);
missingVariables = setdiff(requiredVariables, actualVariables);
localAssert(isempty(missingVariables), ...
    "G4.5 assumed-aircraft plausibility table is missing variables: " + ...
    strjoin(missingVariables, ", "));
localAssert(height(plausibilityTable) >= 15, ...
    "G4.5 assumed-aircraft plausibility table must include default RCS sweeps for canonical targets.");
localAssert(all(ismember(["low_conservative", ...
    "nominal_medium_transport", "favorable_aspect"], ...
    string(plausibilityTable.AssumptionLabel))), ...
    "G4.5 assumed-aircraft plausibility table must include default RCS assumption labels.");
localAssert(all(isfinite(plausibilityTable.CenterFrequency_Hz)), ...
    "G4.5 assumed-aircraft plausibility table must include finite center frequency.");
localAssert(all(isfinite(plausibilityTable.TxRxRange_m)), ...
    "G4.5 assumed-aircraft plausibility table must include finite TX/RX range.");
localAssert(all(isfinite(plausibilityTable.AssumedTxTargetRange_m)), ...
    "G4.5 assumed-aircraft plausibility table must include finite assumed TX-target range.");
localAssert(all(isfinite(plausibilityTable.AssumedTargetRxRange_m)), ...
    "G4.5 assumed-aircraft plausibility table must include finite assumed target-RX range.");
localAssert(all(isfinite(plausibilityTable.NotionalBistaticAngle_deg)), ...
    "G4.5 assumed-aircraft plausibility table must include finite notional bistatic angle.");
localAssert(all(isfinite(plausibilityTable.EchoToDirectRatio_dB)), ...
    "G4.5 assumed-aircraft plausibility table must include finite echo/direct ratios.");
localAssert(all(plausibilityTable.TxAntennaGainRatio_dB == 0.0), ...
    "G4.5 assumed-aircraft plausibility default TX antenna gain ratio must be 0 dB.");
localAssert(all(plausibilityTable.RxAntennaGainRatio_dB == 0.0), ...
    "G4.5 assumed-aircraft plausibility default RX antenna gain ratio must be 0 dB.");
localAssert(all(plausibilityTable.CombinedLossFactor_dB == -6.0), ...
    "G4.5 assumed-aircraft plausibility default combined loss factor must be -6 dB.");
comparisonText = lower(strjoin(plausibilityTable.ComparisonBasis, "; "));
forwardQuestionText = lower(strjoin(plausibilityTable.ForwardQuestion, "; "));
caveatText = lower(strjoin(plausibilityTable.Caveat, "; "));
localAssert(contains(comparisonText, "diagnostic only"), ...
    "G4.5 assumed-aircraft plausibility comparison must be diagnostic-only.");
localAssert(contains(forwardQuestionText, ...
    "conservative assumed medium-aircraft echo"), ...
    "G4.5 assumed-aircraft plausibility table must include the forward aircraft-echo question.");
localAssert(contains(caveatText, "forward-model sensitivity") && ...
    contains(caveatText, "not calibrated rcs") && ...
    contains(caveatText, "not inferred bistatic rcs"), ...
    "G4.5 assumed-aircraft plausibility caveat must reject calibrated or inferred RCS claims.");

end

function localVerifyExportedFiguresNonblank(plotOutput)

figurePaths = string(plotOutput.FigureTable.FigurePath);

for figureIndex = 1:numel(figurePaths)
    try
        imageData = imread(figurePaths(figureIndex));
    catch imageException
        error("verifyPipelineStoryReport:ImageReadFailed", ...
            "Failed to read exported figure %s: %s", ...
            figurePaths(figureIndex), imageException.message);
    end

    pixelVariance = var(double(imageData(:)), "omitnan");
    localAssert(pixelVariance > 0.0, ...
        "Exported figure appears blank: " + figurePaths(figureIndex));
end

end

function localVerifyG45ControlMapContract(reportData)

caseRecords = reportData.G45.CaseRecords;

for caseIndex = 1:numel(caseRecords)
    analysis = caseRecords(caseIndex).Analysis;
    caseDatasetId = string(caseRecords(caseIndex).CaseDatasetId);
    controlCaseId = "real_only_control";

    if isfield(analysis, "Options") && ...
            isfield(analysis.Options, "ControlCaseId")
        controlCaseId = string(analysis.Options.ControlCaseId);
    end

    if caseDatasetId == controlCaseId
        continue
    end

    localAssert(isfield(analysis, "ControlRepresentativeMaps"), ...
        "Non-control G4.5 metrics.mat must include ControlRepresentativeMaps.");
    localAssert(~isempty(analysis.ControlRepresentativeMaps), ...
        "Non-control G4.5 ControlRepresentativeMaps must not be empty.");
    representativeWindows = string({analysis.RepresentativeMaps.WindowLabel});
    controlWindows = string({analysis.ControlRepresentativeMaps.WindowLabel});
    localAssert(all(ismember(representativeWindows, controlWindows)), ...
        "G4.5 ControlRepresentativeMaps must include each representative map window.");
end

end

function localVerifyG4LatestCompleteSelection(reportData, repoRoot)

g4Bundle = reportData.G4.Bundle;
artifactRoot = fullfile(repoRoot, "artifacts", reportData.DatasetId, ...
    g4Bundle.ArtifactId);
latestFolder = localLatestFolderName(artifactRoot);
selectedFolder = string(g4Bundle.RunTimestampZ);
requiredFiles = string(g4Bundle.RequiredFiles(:));
selectedRoot = string(g4Bundle.BundleRoot);
localAssert(localHasRequiredFiles(selectedRoot, requiredFiles), ...
    "Selected G4 bundle must contain all required files.");

if latestFolder ~= selectedFolder
    latestRoot = fullfile(artifactRoot, latestFolder);
    localAssert(~localHasRequiredFiles(latestRoot, requiredFiles), ...
        "G4 resolver selected an older bundle even though the newest bundle appears complete.");
    fprintf("G4 latest-complete resolver skipped incomplete newest bundle:\t%s\n", ...
        latestFolder);
end

end

function latestFolder = localLatestFolderName(artifactRoot)

dirInfo = dir(artifactRoot);
dirInfo = dirInfo([dirInfo.isdir]);
folderNames = string({dirInfo.name});
folderNames = folderNames(folderNames ~= "." & folderNames ~= "..");
folderNames = sort(folderNames(:), "descend");
localAssert(~isempty(folderNames), ...
    "Expected at least one G4 artifact bundle folder.");
latestFolder = folderNames(1);

end

function hasRequiredFiles = localHasRequiredFiles(bundleRoot, requiredFiles)

requiredPaths = fullfile(bundleRoot, requiredFiles);
hasRequiredFiles = all(isfile(requiredPaths));

end

function localAssert(condition, message)

if ~condition
    error("verifyPipelineStoryReport:AssertionFailed", "%s", message);
end

end
