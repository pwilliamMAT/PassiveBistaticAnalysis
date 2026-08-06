function verification = verifyG5MitigationSlice(options)
%VERIFYG5MITIGATIONSLICE Run bounded helper-level verification for G5.
%
%   VERIFICATION = VERIFYG5MITIGATIONSLICE() builds a synthetic
%   direct-path-dominated passive scene and verifies that the first G5
%   helper slice emits the required candidate and decision tables.

arguments
    options (1,1) struct = struct()
end

resolvedOptions = localResolveVerificationOptions(options);

fprintf("Running G5 helper smoke verification\n");

[sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, ...
    g5Options] = localBuildSyntheticFixture(resolvedOptions);
analysis = helperAnalyzeG5Mitigation(sessionData, collectionMetadataInfo, ...
    g3SyncResults, g4Analysis, g5Options);
localRunSmokeAssertions(analysis);

verification = struct();
verification.DatasetId = string(sessionData.DatasetId);
verification.StageId = "G5_Mitigation";
verification.Status = "passed";
verification.Passed = true;
verification.GateDecision = string(analysis.GateDecision);
verification.ReviewStatus = string(analysis.ReviewStatus);
verification.DecisionLabel = string(analysis.DecisionLabel);
verification.FormalGateDecisionEmitted = ...
    logical(analysis.FormalGateDecisionEmitted);
verification.CandidateCount = height(analysis.MitigationCandidateTable);
verification.SelectedG4MapRows = height(analysis.SelectedG4MapRows);
verification.Note = "Synthetic G5 helper smoke checks passed.";

fprintf("G5 smoke status:\t%s\n", verification.Status);
fprintf("Gate decision:\t%s\n", verification.GateDecision);
fprintf("Review status:\t%s\n", verification.ReviewStatus);
fprintf("Decision label:\t%s\n", verification.DecisionLabel);

end

function resolvedOptions = localResolveVerificationOptions(options)

resolvedOptions = struct();
resolvedOptions.SampleRateHz = 10000.0;
resolvedOptions.SamplesPerRepetition = 10000.0;
resolvedOptions.RepetitionCount = 3.0;
resolvedOptions.MapDecimationFactor = 10.0;
resolvedOptions.CpiDuration_s = 0.050;
resolvedOptions.ReviewMapRows = 64.0;
resolvedOptions.ReviewMapCols = 64.0;
resolvedOptions.RandomSeed = 42.0;

optionFields = fieldnames(options);

for idx = 1:numel(optionFields)
    fieldName = optionFields{idx};
    resolvedOptions.(fieldName) = options.(fieldName);
end

end

function [sessionData, collectionMetadataInfo, g3SyncResults, ...
    g4Analysis, g5Options] = localBuildSyntheticFixture(options)

rng(options.RandomSeed, "twister");
datasetId = "synthetic_g5";
sampleRateHz = double(options.SampleRateHz);
samplesPerRepetition = double(options.SamplesPerRepetition);
repetitionCount = double(options.RepetitionCount);
mapDecimationFactor = double(options.MapDecimationFactor);
cpiDuration_s = double(options.CpiDuration_s);
cpiSamples = round(cpiDuration_s .* sampleRateHz ./ mapDecimationFactor);
radarScans = repmat(struct( ...
    "Samples", [], ...
    "RelativePath", "", ...
    "Repetition", NaN ...
    ), repetitionCount, 1);
repetition = (1:repetitionCount).';
relativePath = strings(repetitionCount, 1);
sampleRateColumn = repmat(sampleRateHz, repetitionCount, 1);
numSamplesColumn = repmat(samplesPerRepetition, repetitionCount, 1);
antenna1 = repmat("RF0:RX2", repetitionCount, 1);
antenna2 = repmat("RF1:RX2", repetitionCount, 1);

for idx = 1:repetitionCount
    time_s = (0:samplesPerRepetition - 1).' ./ sampleRateHz;
    reference = complex(randn(samplesPerRepetition, 1), ...
        randn(samplesPerRepetition, 1));
    delayedReference = [ ...
        zeros(35, 1); ...
        reference(1:end - 35) ...
        ];
    dopplerTarget = delayedReference .* exp(1j .* 2.0 .* pi .* ...
        140.0 .* time_s);
    leakage = 0.85 .* reference;
    receiverNoise = 0.05 .* complex(randn(samplesPerRepetition, 1), ...
        randn(samplesPerRepetition, 1));
    surveillance = leakage + 0.20 .* dopplerTarget + receiverNoise;
    radarScans(idx).Samples = [surveillance reference];
    radarScans(idx).RelativePath = "synthetic/rep_" + idx + ".bb";
    radarScans(idx).Repetition = idx;
    relativePath(idx) = radarScans(idx).RelativePath;
end

radarTable = table(repetition, relativePath, sampleRateColumn, ...
    numSamplesColumn, antenna1, antenna2, VariableNames = ...
    {'Repetition', 'RelativePath', 'SampleRate_Hz', 'NumSamples', ...
    'Antenna1', 'Antenna2'});
sessionData = struct();
sessionData.DatasetId = datasetId;
sessionData.DatasetRoot = string(pwd);
sessionData.RadarTable = radarTable;
sessionData.RadarScans = radarScans;
sessionData.CpiContract = struct("CrossFileAllowed", false);
collectionMetadataInfo = struct();
collectionMetadataInfo.MetadataPresent = true;
collectionMetadataInfo.SessionIdMatches = true;
collectionMetadataInfo.ReferenceChannel = ...
    struct("ChannelLabel", "RF1:RX2");
collectionMetadataInfo.SurveillanceChannel = ...
    struct("ChannelLabel", "RF0:RX2");
g3SyncResults = struct();
g3SyncResults.OverallLabel = "ready";
g3SyncResults.RecommendedStrategyCandidate = ...
    "global_session_correction";
g4Analysis = localBuildSyntheticG4Analysis(sessionData, ...
    mapDecimationFactor, cpiDuration_s, cpiSamples);
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

function g4Analysis = localBuildSyntheticG4Analysis(sessionData, ...
    mapDecimationFactor, cpiDuration_s, cpiSamples)

mapSummaryTable = localBuildSyntheticMapSummaryTable(sessionData, ...
    cpiDuration_s, cpiSamples);
baselineProductDefinition = struct();
baselineProductDefinition.Method = "ambgfun";
baselineProductDefinition.MapRateMode = "reduced_rate_main_product";
baselineProductDefinition.MapSampleRateHz = ...
    sessionData.RadarTable.SampleRate_Hz(1) ./ mapDecimationFactor;
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
interpretation.OverallRationale = "Synthetic fixture intentionally " + ...
    "marks G4 blocked so G5 smoke verifies diagnostic/manual-review behavior.";
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
g4Analysis.Options = struct( ...
    "MapDecimationFactor", mapDecimationFactor, ...
    "MapSampleRateHz", baselineProductDefinition.MapSampleRateHz, ...
    "ReviewMapRows", 64.0, ...
    "ReviewMapCols", 64.0, ...
    "FigureFloor_dB", -60.0, ...
    "FullRateAuditRepetitions", sessionData.RadarTable.Repetition);
g4Analysis.BaselineProductDefinition = baselineProductDefinition;
g4Analysis.MapSummaryTable = mapSummaryTable;
g4Analysis.QuestionSummaries = table();
g4Analysis.Interpretation = interpretation;
g4Analysis.RecommendedBaselineCpiLabel = "short";

end

function mapSummaryTable = localBuildSyntheticMapSummaryTable(sessionData, ...
    cpiDuration_s, cpiSamples)

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
mapDecimationFactor = repmat(10.0, rowCount, 1);
mapSampleRateHz = repmat(1000.0, rowCount, 1);
directPathPeak_dB = zeros(rowCount, 1);
offOriginFraction = repmat(0.02, rowCount, 1);
zeroDopplerFraction = repmat(0.90, rowCount, 1);
occupiedFraction = repmat(0.0002, rowCount, 1);
sceneScore = repmat(-20.0, rowCount, 1);
interpretationLabel = repmat("scene_limited_direct_path_dominated", ...
    rowCount, 1);
rationale = repmat("synthetic G4 baseline row", rowCount, 1);

mapSummaryTable = table(questionId, repetition, relativePath, cpiLabel, ...
    windowLabel, windowStartSample, windowIndex, cpiDurationColumn_s, ...
    cpiSamplesColumn, mapRateMode, mapDecimationFactor, ...
    mapSampleRateHz, directPathPeak_dB, offOriginFraction, ...
    zeroDopplerFraction, occupiedFraction, sceneScore, ...
    interpretationLabel, rationale, VariableNames = {'QuestionId', ...
    'Repetition', 'RelativePath', 'CpiLabel', 'WindowLabel', ...
    'WindowStartSample', 'WindowIndex', 'CpiDuration_s', ...
    'CpiSamples', 'MapRateMode', 'MapDecimationFactor', ...
    'MapSampleRateHz', 'DirectPathPeak_dB', ...
    'OffOriginNonzeroDopplerEnergyFraction', ...
    'ZeroDopplerRidgeEnergyFraction', ...
    'OffOriginOccupiedFraction_abovePeakMinus20dB', ...
    'SceneObservabilityScore', 'InterpretationLabel', 'Rationale'});

end

function localRunSmokeAssertions(analysis)

localAssert(analysis.ReviewStatus == "manual_review_required", ...
    "Blocked G4 must keep G5 in manual-review status.");
localAssert(analysis.DecisionLabel == "blocked_by_g4", ...
    "Blocked G4 must produce the blocked_by_g4 G5 decision label.");
localAssert(~analysis.FormalGateDecisionEmitted, ...
    "Blocked G4 must not emit a formal G5 gate decision.");
localAssert(isequal(sort(analysis.MitigationCandidateTable.CandidateName), ...
    sort(["none"; "conservative_lms"; "aggressive_lms"])), ...
    "G5 candidate set is incomplete.");
localAssert(height(analysis.SuppressionSummaryTable) == 3, ...
    "SuppressionSummaryTable must include all candidates.");
localAssert(height(analysis.ProtectedRegionRetentionTable) == 3, ...
    "ProtectedRegionRetentionTable must include all candidates.");
localAssert(height(analysis.ResidualErrorPowerTable) == 9, ...
    "ResidualErrorPowerTable must include one row per candidate/map row.");
localAssert(height(analysis.DetectabilityProxyTable) == 3, ...
    "DetectabilityProxyTable must include all candidates.");
localAssert(height(analysis.MitigationCausalAssessmentTable) == 3, ...
    "MitigationCausalAssessmentTable must include all candidates.");
localAssert(height(analysis.AcquisitionImplicationTable) >= 7, ...
    "AcquisitionImplicationTable must carry RF/acquisition implications.");
localAssert(height(analysis.DecisionComparisonTable) == 3, ...
    "DecisionComparisonTable must include all candidates.");
localAssert(height(analysis.UpstreamCaveatsCarriedForward) >= 2, ...
    "Upstream caveats must be carried forward.");
localAssert(all(ismember(["MIT-001"; "MIT-002"; "MIT-003"], ...
    analysis.RequirementsCoverageTable.RequirementId)), ...
    "Requirements coverage is missing a G5 MIT requirement.");
localAssert(all(isfinite( ...
    analysis.ResidualErrorPowerTable.ResidualErrorPower_dB)), ...
    "Residual error power must be finite.");
localAssert(all(analysis.ResidualErrorPowerTable.LmsConvergedFinite), ...
    "LMS candidates must produce finite residuals in the smoke fixture.");

end

function localAssert(condition, message)

if ~condition
    error("verifyG5MitigationSlice:AssertionFailed", "%s", message);
end

end
