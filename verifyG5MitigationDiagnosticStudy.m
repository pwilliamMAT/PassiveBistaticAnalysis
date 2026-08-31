function verification = verifyG5MitigationDiagnosticStudy(options)
%VERIFYG5MITIGATIONDIAGNOSTICSTUDY Bounded synthetic G5 diagnostic smoke.

arguments
    options (1,1) struct = struct()
end

resolvedOptions = localResolveOptions(options);
[sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, g5Options] = localBuildSyntheticFixture(resolvedOptions);
baseG5Analysis = helperAnalyzeG5Mitigation(sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, g5Options);
diagnosticOptions = struct();
diagnosticOptions.SourceG5Analysis = baseG5Analysis;
diagnosticOptions.MaxReviewRows = 1.0;
diagnosticOptions.MaxSignalRows = 1.0;
diagnosticOptions.ReviewMapRows = resolvedOptions.ReviewMapRows;
diagnosticOptions.ReviewMapCols = resolvedOptions.ReviewMapCols;
diagnosticOptions.ProfileSweepTable = localBuildSmokeProfileSweepTable();
diagnosticAnalysis = helperAnalyzeG5MitigationDiagnosticStudy(sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, diagnosticOptions);
localRunSmokeAssertions(diagnosticAnalysis, baseG5Analysis);

verification = struct();
verification.Status = "passed";
verification.DatasetId = string(sessionData.DatasetId);
verification.PrimaryConclusionLabel = string(diagnosticAnalysis.DiagnosticConclusionTable.PrimaryConclusionLabel(1));
verification.SecondaryCaveatLabel = string(diagnosticAnalysis.DiagnosticConclusionTable.SecondaryCaveatLabel(1));
verification.ProfileSweepRows = height(diagnosticAnalysis.ProfileSweepSummaryTable);
verification.ThresholdSensitivityRows = height(diagnosticAnalysis.ThresholdSensitivityTable);
verification.SignalDiagnosticRows = height(diagnosticAnalysis.SignalDiagnosticTable);
verification.SourceDecisionLabel = string(baseG5Analysis.DecisionLabel);
verification.FormalGateDecisionChanged = logical(diagnosticAnalysis.DiagnosticConclusionTable.FormalGateDecisionChanged(1));

fprintf("Running G5 diagnostic smoke verification\n");
fprintf("G5 diagnostic smoke status:\t%s\n", verification.Status);
fprintf("Primary conclusion:\t%s\n", verification.PrimaryConclusionLabel);
fprintf("Secondary caveat:\t%s\n", verification.SecondaryCaveatLabel);
fprintf("Profile rows:\t%d\n", verification.ProfileSweepRows);
fprintf("Threshold rows:\t%d\n", verification.ThresholdSensitivityRows);
fprintf("Signal rows:\t%d\n", verification.SignalDiagnosticRows);

end

function resolvedOptions = localResolveOptions(options)

resolvedOptions = struct();
resolvedOptions.RandomSeed = localNumericOption(options, "RandomSeed", 42.0);
resolvedOptions.SampleRateHz = localNumericOption(options, "SampleRateHz", 8192.0);
resolvedOptions.SamplesPerRepetition = localNumericOption(options, "SamplesPerRepetition", 4096.0);
resolvedOptions.RepetitionCount = localNumericOption(options, "RepetitionCount", 1.0);
resolvedOptions.MapDecimationFactor = localNumericOption(options, "MapDecimationFactor", 4.0);
resolvedOptions.CpiDuration_s = localNumericOption(options, "CpiDuration_s", 0.25);
resolvedOptions.ReviewMapRows = localNumericOption(options, "ReviewMapRows", 64.0);
resolvedOptions.ReviewMapCols = localNumericOption(options, "ReviewMapCols", 64.0);

end

function value = localNumericOption(options, fieldName, defaultValue)

value = defaultValue;

if isfield(options, fieldName)
    candidateValue = options.(fieldName);

    if isnumeric(candidateValue) && isscalar(candidateValue) && isfinite(candidateValue)
        value = double(candidateValue);
    end
end

end

function profileTable = localBuildSmokeProfileSweepTable()

profileId = "smoke_probe";
conservativeLength = 8.0;
conservativeStepSize = 0.01;
conservativeLeakageFactor = 1.0;
aggressiveLength = 16.0;
aggressiveStepSize = 0.05;
aggressiveLeakageFactor = 0.999;
rationale = "Single bounded smoke diagnostic profile.";
profileTable = table(profileId, conservativeLength, conservativeStepSize, conservativeLeakageFactor, aggressiveLength, aggressiveStepSize, aggressiveLeakageFactor, rationale, VariableNames = {'ProfileId', 'ConservativeLength', 'ConservativeStepSize', 'ConservativeLeakageFactor', 'AggressiveLength', 'AggressiveStepSize', 'AggressiveLeakageFactor', 'Rationale'});

end

function [sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, g5Options] = localBuildSyntheticFixture(options)

rng(options.RandomSeed, "twister");
datasetId = "synthetic_g5_diagnostic";
sampleRateHz = double(options.SampleRateHz);
samplesPerRepetition = double(options.SamplesPerRepetition);
repetitionCount = double(options.RepetitionCount);
mapDecimationFactor = double(options.MapDecimationFactor);
cpiDuration_s = double(options.CpiDuration_s);
cpiSamples = round(cpiDuration_s .* sampleRateHz ./ mapDecimationFactor);
radarScans = repmat(struct("Samples", [], "RelativePath", "", "Repetition", NaN), repetitionCount, 1);
repetition = (1:repetitionCount).';
relativePath = strings(repetitionCount, 1);
sampleRateColumn = repmat(sampleRateHz, repetitionCount, 1);
numSamplesColumn = repmat(samplesPerRepetition, repetitionCount, 1);
antenna1 = repmat("RF0:RX2", repetitionCount, 1);
antenna2 = repmat("RF1:RX2", repetitionCount, 1);

for idx = 1:repetitionCount
    time_s = (0:samplesPerRepetition - 1).' ./ sampleRateHz;
    reference = complex(randn(samplesPerRepetition, 1), randn(samplesPerRepetition, 1));
    delayedReference = [zeros(12, 1); reference(1:end - 12)];
    dopplerTarget = delayedReference .* exp(1j .* 2.0 .* pi .* 80.0 .* time_s);
    leakage = 0.80 .* reference;
    receiverNoise = 0.05 .* complex(randn(samplesPerRepetition, 1), randn(samplesPerRepetition, 1));
    surveillance = leakage + 0.15 .* dopplerTarget + receiverNoise;
    radarScans(idx).Samples = [surveillance reference];
    radarScans(idx).RelativePath = "synthetic/rep_" + idx + ".bb";
    radarScans(idx).Repetition = idx;
    relativePath(idx) = radarScans(idx).RelativePath;
end

radarTable = table(repetition, relativePath, sampleRateColumn, numSamplesColumn, antenna1, antenna2, VariableNames = {'Repetition', 'RelativePath', 'SampleRate_Hz', 'NumSamples', 'Antenna1', 'Antenna2'});
sessionData = struct();
sessionData.DatasetId = datasetId;
sessionData.DatasetRoot = string(pwd);
sessionData.RadarTable = radarTable;
sessionData.RadarScans = radarScans;
sessionData.CpiContract = struct("CrossFileAllowed", false);
collectionMetadataInfo = struct();
collectionMetadataInfo.MetadataPresent = true;
collectionMetadataInfo.SessionIdMatches = true;
collectionMetadataInfo.ReferenceChannel = struct("ChannelLabel", "RF1:RX2");
collectionMetadataInfo.SurveillanceChannel = struct("ChannelLabel", "RF0:RX2");
g3SyncResults = struct("OverallLabel", "ready", "RecommendedStrategyCandidate", "global_session_correction");
g4Analysis = localBuildSyntheticG4Analysis(sessionData, mapDecimationFactor, cpiDuration_s, cpiSamples);
g5Options = struct();
g5Options.ReviewCpiLabels = "short";
g5Options.ReviewWindowLabels = "center";
g5Options.ReviewRepetitions = repetition;
g5Options.MapDecimationFactor = mapDecimationFactor;
g5Options.MapSampleRateHz = sampleRateHz ./ mapDecimationFactor;
g5Options.ReviewMapRows = options.ReviewMapRows;
g5Options.ReviewMapCols = options.ReviewMapCols;
g5Options.ConservativeLmsLength = 8.0;
g5Options.ConservativeLmsStepSize = 0.01;
g5Options.AggressiveLmsLength = 16.0;
g5Options.AggressiveLmsStepSize = 0.05;

end

function g4Analysis = localBuildSyntheticG4Analysis(sessionData, mapDecimationFactor, cpiDuration_s, cpiSamples)

mapSummaryTable = localBuildSyntheticMapSummaryTable(sessionData, cpiDuration_s, cpiSamples, mapDecimationFactor);
baselineProductDefinition = struct();
baselineProductDefinition.Method = "ambgfun";
baselineProductDefinition.MapRateMode = "reduced_rate_main_product";
baselineProductDefinition.MapSampleRateHz = sessionData.RadarTable.SampleRate_Hz(1) ./ mapDecimationFactor;
baselineProductDefinition.MapDecimationFactor = mapDecimationFactor;
baselineProductDefinition.OriginSearchDelayRadius_samples = 3.0;
baselineProductDefinition.OriginSearchDopplerRadius_Hz = 25.0;
baselineProductDefinition.ExclusionDelayRadius_samples = 5.0;
baselineProductDefinition.ExclusionDopplerRadius_Hz = 35.0;
baselineProductDefinition.ZeroDopplerRidgeExclusion_Hz = 25.0;
baselineProductDefinition.AppliedLag_samples = 0.0;
baselineProductDefinition.AppliedResidualFrequency_Hz = 0.0;
baselineProductDefinition.AppliedCorrectionSource = "synthetic_fixture";
interpretation = struct();
interpretation.OverallLabel = "blocked";
interpretation.OverallRationale = "Synthetic fixture intentionally marks G4 blocked for diagnostic verification.";
interpretation.UpstreamValidityLabel = "ready";
interpretation.SceneObservabilityLabel = "blocked";
interpretation.ImplementationConfidenceLabel = "ready";
interpretation.FullRateAuditAgreementLabel = "agreement";
interpretation.CaveatCodes = strings(0, 1);
interpretation.ReferenceLabel = "RF1:RX2";
interpretation.SurveillanceLabel = "RF0:RX2";
g4Analysis = struct();
g4Analysis.DatasetId = string(sessionData.DatasetId);
g4Analysis.StageId = "G4_Passive_Baseline_Analysis_Core";
g4Analysis.Options = struct("MapDecimationFactor", mapDecimationFactor, "MapSampleRateHz", baselineProductDefinition.MapSampleRateHz, "ReviewMapRows", 64.0, "ReviewMapCols", 64.0, "FigureFloor_dB", -60.0, "FullRateAuditRepetitions", sessionData.RadarTable.Repetition);
g4Analysis.BaselineProductDefinition = baselineProductDefinition;
g4Analysis.MapSummaryTable = mapSummaryTable;
g4Analysis.QuestionSummaries = table();
g4Analysis.Interpretation = interpretation;
g4Analysis.RecommendedBaselineCpiLabel = "short";

end

function mapSummaryTable = localBuildSyntheticMapSummaryTable(sessionData, cpiDuration_s, cpiSamples, mapDecimationFactor)

repetitionValues = double(sessionData.RadarTable.Repetition);
rowCount = numel(repetitionValues);
questionId = repmat("Q1_Q2_Q3", rowCount, 1);
repetition = repetitionValues(:);
relativePath = string(sessionData.RadarTable.RelativePath(:));
cpiLabel = repmat("short", rowCount, 1);
windowLabel = repmat("center", rowCount, 1);
windowStartSample = ones(rowCount, 1);
windowIndex = ones(rowCount, 1);
cpiDurationColumn_s = repmat(cpiDuration_s, rowCount, 1);
cpiSamplesColumn = repmat(double(cpiSamples), rowCount, 1);
mapRateMode = repmat("reduced_rate_main_product", rowCount, 1);
mapDecimationFactorColumn = repmat(double(mapDecimationFactor), rowCount, 1);
mapSampleRateHz = repmat(sessionData.RadarTable.SampleRate_Hz(1) ./ mapDecimationFactor, rowCount, 1);
directPathPeak_dB = zeros(rowCount, 1);
offOriginFraction = repmat(0.02, rowCount, 1);
zeroDopplerFraction = repmat(0.90, rowCount, 1);
occupiedFraction = repmat(0.0002, rowCount, 1);
sceneScore = repmat(-20.0, rowCount, 1);
interpretationLabel = repmat("scene_limited_direct_path_dominated", rowCount, 1);
rationale = repmat("synthetic G4 baseline row", rowCount, 1);
mapSummaryTable = table(questionId, repetition, relativePath, cpiLabel, windowLabel, windowStartSample, windowIndex, cpiDurationColumn_s, cpiSamplesColumn, mapRateMode, mapDecimationFactorColumn, mapSampleRateHz, directPathPeak_dB, offOriginFraction, zeroDopplerFraction, occupiedFraction, sceneScore, interpretationLabel, rationale, VariableNames = {'QuestionId', 'Repetition', 'RelativePath', 'CpiLabel', 'WindowLabel', 'WindowStartSample', 'WindowIndex', 'CpiDuration_s', 'CpiSamples', 'MapRateMode', 'MapDecimationFactor', 'MapSampleRateHz', 'DirectPathPeak_dB', 'OffOriginNonzeroDopplerEnergyFraction', 'ZeroDopplerRidgeEnergyFraction', 'OffOriginOccupiedFraction_abovePeakMinus20dB', 'SceneObservabilityScore', 'InterpretationLabel', 'Rationale'});

end

function localRunSmokeAssertions(diagnosticAnalysis, baseG5Analysis)

localAssert(baseG5Analysis.DecisionLabel == "blocked_by_g4", "Synthetic base G5 must stay blocked by G4.");
localAssert(~diagnosticAnalysis.DiagnosticConclusionTable.FormalGateDecisionChanged(1), "Diagnostic sidecar must not change formal G5 decision.");
localAssert(height(diagnosticAnalysis.ProfileSweepSummaryTable) >= 6, "Diagnostic profile table must include base and sweep candidates.");
localAssert(height(diagnosticAnalysis.ThresholdSensitivityTable) >= 8, "Threshold sensitivity table must include candidate probe rows.");
localAssert(height(diagnosticAnalysis.SignalDiagnosticTable) == 1, "Signal diagnostic table must include one bounded smoke row.");
localAssert(strlength(diagnosticAnalysis.DiagnosticConclusionTable.PrimaryConclusionLabel(1)) > 0, "Diagnostic conclusion label must be populated.");

end

function localAssert(conditionValue, messageText)

if ~conditionValue
    error("verifyG5MitigationDiagnosticStudy:AssertionFailed", "%s", messageText);
end

end