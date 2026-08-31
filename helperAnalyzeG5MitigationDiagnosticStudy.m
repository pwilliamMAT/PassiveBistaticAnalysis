function analysis = helperAnalyzeG5MitigationDiagnosticStudy(sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, options)
%HELPERANALYZEG5MITIGATIONDIAGNOSTICSTUDY Optional G5 mitigation sidecar.

arguments
    sessionData (1,1) struct
    collectionMetadataInfo (1,1) struct
    g3SyncResults (1,1) struct
    g4Analysis (1,1) struct
    options (1,1) struct = struct()
end

opts = localResolveOptions(options);
baseG5 = localResolveBaseG5(sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, opts);
sourceSummary = localBuildSourceSummary(baseG5);
profileSummary = localBuildProfileSummary(sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, baseG5, opts);
thresholdSensitivity = localBuildThresholdSensitivity(profileSummary, opts);
signalDiagnostics = localBuildSignalDiagnostics(sessionData, collectionMetadataInfo, g4Analysis, baseG5, opts);
conclusion = localBuildConclusion(sourceSummary, profileSummary, thresholdSensitivity, signalDiagnostics);

analysis = struct();
analysis.DatasetId = string(sessionData.DatasetId);
analysis.StageId = "G5_Mitigation_Diagnostic";
analysis.AnalysisStageId = "G5_Mitigation_Diagnostic_Study";
analysis.AnalysisScope = "diagnostic_sidecar_no_formal_gate";
analysis.SourceG5DecisionLabel = string(baseG5.DecisionLabel);
analysis.SourceG5ReviewStatus = string(baseG5.ReviewStatus);
analysis.SourceG5FormalGateDecisionEmitted = logical(baseG5.FormalGateDecisionEmitted);
analysis.SourceG4OverallLabel = string(baseG5.G4OverallLabel);
analysis.SourceG4SceneObservabilityLabel = string(baseG5.G4SceneObservabilityLabel);
analysis.SourceG4FullRateAuditAgreementLabel = string(baseG5.G4FullRateAuditAgreementLabel);
analysis.Options = opts.PublicOptions;
analysis.SourceGateSummaryTable = sourceSummary;
analysis.DiagnosticConclusionTable = conclusion;
analysis.ProfileSweepSummaryTable = profileSummary;
analysis.ThresholdSensitivityTable = thresholdSensitivity;
analysis.SignalDiagnosticTable = signalDiagnostics;
analysis.AcquisitionImplicationTable = baseG5.AcquisitionImplicationTable;
analysis.UpstreamCaveatsCarriedForward = baseG5.UpstreamCaveatsCarriedForward;
analysis.BaseG5Analysis = baseG5;

end

function opts = localResolveOptions(options)

opts = struct();
opts.MaxReviewRows = localNumericOption(options, "MaxReviewRows", 3.0);
opts.ReviewMapRows = localNumericOption(options, "ReviewMapRows", 128.0);
opts.ReviewMapCols = localNumericOption(options, "ReviewMapCols", 128.0);
opts.MaxSignalRows = localNumericOption(options, "MaxSignalRows", 3.0);
opts.SourceG5Analysis = struct();

if isfield(options, "SourceG5Analysis")
    opts.SourceG5Analysis = options.SourceG5Analysis;
end

opts.ProfileSweepTable = localProfileSweepTable(options);
opts.ThresholdCaseTable = localThresholdCaseTable(options);
opts.PublicOptions = rmfield(opts, "SourceG5Analysis");

end

function value = localNumericOption(options, fieldName, defaultValue)

value = defaultValue;

if isfield(options, fieldName)
    candidate = options.(fieldName);

    if isnumeric(candidate) && isscalar(candidate) && isfinite(candidate)
        value = double(candidate);
    end
end

end

function profileTable = localProfileSweepTable(options)

if isfield(options, "ProfileSweepTable")
    profileTable = options.ProfileSweepTable;
    return
end

profileId = ["short_low_step"; "guarded_longer_filter"];
conservativeLength = [8.0; 32.0];
conservativeStepSize = [0.01; 0.02];
conservativeLeakageFactor = [1.0; 0.9995];
aggressiveLength = [16.0; 96.0];
aggressiveStepSize = [0.05; 0.03];
aggressiveLeakageFactor = [0.999; 0.999];
rationale = ["Short lower-risk probe."; "Longer guarded low-step probe."];
profileTable = table(profileId, conservativeLength, conservativeStepSize, conservativeLeakageFactor, aggressiveLength, aggressiveStepSize, aggressiveLeakageFactor, rationale, VariableNames = {'ProfileId', 'ConservativeLength', 'ConservativeStepSize', 'ConservativeLeakageFactor', 'AggressiveLength', 'AggressiveStepSize', 'AggressiveLeakageFactor', 'Rationale'});

end

function thresholdTable = localThresholdCaseTable(options)

if isfield(options, "ThresholdCaseTable")
    thresholdTable = options.ThresholdCaseTable;
    return
end

thresholdCase = ["default_gate"; "permissive_probe"; "retention_probe"; "strict_scene"];
directPathSuppressionThreshold_dB = [3.0; 1.0; 3.0; 6.0];
sceneScoreDeltaThreshold = [0.50; 0.05; 0.50; 1.0];
offOriginEnergyDeltaThreshold = [0.005; 0.0001; 0.005; 0.01];
offOriginOccupiedDeltaThreshold = [0.0005; 0.000001; 0.0005; 0.001];
protectedRetentionFloor = [0.50; 0.50; 0.25; 0.75];
casePurpose = ["Current G5 thresholds."; "Weak scene-reveal probe."; "Retention sensitivity probe."; "Strict robustness probe."];
thresholdTable = table(thresholdCase, directPathSuppressionThreshold_dB, sceneScoreDeltaThreshold, offOriginEnergyDeltaThreshold, offOriginOccupiedDeltaThreshold, protectedRetentionFloor, casePurpose, VariableNames = {'ThresholdCase', 'DirectPathSuppressionThreshold_dB', 'SceneScoreDeltaThreshold', 'OffOriginEnergyDeltaThreshold', 'OffOriginOccupiedDeltaThreshold', 'ProtectedRetentionFloor', 'CasePurpose'});

end

function baseG5 = localResolveBaseG5(sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, opts)

if ~isempty(fieldnames(opts.SourceG5Analysis))
    baseG5 = opts.SourceG5Analysis;
    return
end

g5Options = struct();
g5Options.MaxReviewRows = opts.MaxReviewRows;
g5Options.ReviewMapRows = opts.ReviewMapRows;
g5Options.ReviewMapCols = opts.ReviewMapCols;

if isfield(g4Analysis, "RecommendedBaselineCpiLabel")
    g5Options.ReviewCpiLabels = string(g4Analysis.RecommendedBaselineCpiLabel);
end

baseG5 = helperAnalyzeG5Mitigation(sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, g5Options);

end

function sourceSummary = localBuildSourceSummary(baseG5)

sourceSummary = table(string(baseG5.DecisionLabel), string(baseG5.ReviewStatus), logical(baseG5.FormalGateDecisionEmitted), string(baseG5.G4OverallLabel), string(baseG5.G4SceneObservabilityLabel), string(baseG5.G4FullRateAuditAgreementLabel), string(baseG5.DecisionRationale), VariableNames = {'SourceG5DecisionLabel', 'SourceG5ReviewStatus', 'SourceG5FormalGateDecisionEmitted', 'SourceG4OverallLabel', 'SourceG4SceneObservabilityLabel', 'SourceG4FullRateAuditAgreementLabel', 'SourceG5DecisionRationale'});

end

function profileSummary = localBuildProfileSummary(sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, baseG5, opts)

profileSummary = localExtractProfileRows("official_current", "base_g5_analysis", baseG5);
sweepTable = opts.ProfileSweepTable;

for idx = 1:height(sweepTable)
    g5Options = localSweepOptions(g4Analysis, baseG5, sweepTable(idx, :), opts);
    sweepG5 = helperAnalyzeG5Mitigation(sessionData, collectionMetadataInfo, g3SyncResults, g4Analysis, g5Options);
    profileSummary = [profileSummary; localExtractProfileRows(sweepTable.ProfileId(idx), "diagnostic_sweep", sweepG5)]; %#ok<AGROW>
end

profileSummary = sortrows(profileSummary, ["DiagnosticScore", "DirectPathSuppression_dB"], "descend");

end

function g5Options = localSweepOptions(g4Analysis, baseG5, profileRow, opts)

g5Options = struct();
g5Options.MaxReviewRows = opts.MaxReviewRows;
g5Options.ReviewMapRows = opts.ReviewMapRows;
g5Options.ReviewMapCols = opts.ReviewMapCols;
g5Options.ConservativeLmsLength = double(profileRow.ConservativeLength(1));
g5Options.ConservativeLmsStepSize = double(profileRow.ConservativeStepSize(1));
g5Options.ConservativeLmsLeakageFactor = double(profileRow.ConservativeLeakageFactor(1));
g5Options.AggressiveLmsLength = double(profileRow.AggressiveLength(1));
g5Options.AggressiveLmsStepSize = double(profileRow.AggressiveStepSize(1));
g5Options.AggressiveLmsLeakageFactor = double(profileRow.AggressiveLeakageFactor(1));

if isfield(g4Analysis, "RecommendedBaselineCpiLabel")
    g5Options.ReviewCpiLabels = string(g4Analysis.RecommendedBaselineCpiLabel);
end

if isfield(baseG5, "SelectedG4MapRows") && ~isempty(baseG5.SelectedG4MapRows)
    selectedRows = baseG5.SelectedG4MapRows;
    g5Options.ReviewCpiLabels = unique(string(selectedRows.CpiLabel), "stable");
    g5Options.ReviewWindowLabels = unique(string(selectedRows.WindowLabel), "stable");
    g5Options.ReviewRepetitions = unique(double(selectedRows.Repetition), "stable");
    g5Options.MaxReviewRows = height(selectedRows);
end

end

function rows = localExtractProfileRows(profileId, sweepSource, sourceAnalysis)

candidateTable = sourceAnalysis.MitigationCandidateTable;
candidateNames = string(candidateTable.CandidateName(:));
rowStruct = repmat(localProfileRowTemplate(), numel(candidateNames), 1);

for idx = 1:numel(candidateNames)
    candidateName = candidateNames(idx);
    candidateRow = candidateTable(candidateTable.CandidateName == candidateName, :);
    suppressionRow = sourceAnalysis.SuppressionSummaryTable(sourceAnalysis.SuppressionSummaryTable.CandidateName == candidateName, :);
    protectedRow = sourceAnalysis.ProtectedRegionRetentionTable(sourceAnalysis.ProtectedRegionRetentionTable.CandidateName == candidateName, :);
    proxyRow = sourceAnalysis.DetectabilityProxyTable(sourceAnalysis.DetectabilityProxyTable.CandidateName == candidateName, :);
    causalRow = sourceAnalysis.MitigationCausalAssessmentTable(sourceAnalysis.MitigationCausalAssessmentTable.CandidateName == candidateName, :);
    decisionRow = sourceAnalysis.DecisionComparisonTable(sourceAnalysis.DecisionComparisonTable.CandidateName == candidateName, :);
    residualRows = sourceAnalysis.ResidualErrorPowerTable(sourceAnalysis.ResidualErrorPowerTable.CandidateName == candidateName, :);
    residualToInput_dB = median(double(residualRows.ResidualToInputPower_dB), "omitnan");
    lmsFinite = all(logical(residualRows.LmsConvergedFinite));
    score = localDiagnosticScore(candidateName, suppressionRow, protectedRow, proxyRow);
    rowStruct(idx) = struct("ProfileId", string(profileId), "SweepSource", string(sweepSource), "CandidateName", candidateName, "FilterLength", double(candidateRow.FilterLength(1)), "StepSize", double(candidateRow.StepSize(1)), "LeakageFactor", double(candidateRow.LeakageFactor(1)), "DirectPathSuppression_dB", double(suppressionRow.MedianDirectPathSuppression_dB(1)), "SceneScoreDelta", double(proxyRow.MedianSceneScoreDelta(1)), "OffOriginEnergyFractionDelta", double(proxyRow.MedianOffOriginEnergyFractionDelta(1)), "OffOriginOccupiedFractionDelta", double(proxyRow.MedianOffOriginOccupiedFractionDelta(1)), "ProtectedRetentionRatio", double(protectedRow.MedianProtectedRetentionRatio(1)), "ResidualToInputPower_dB", residualToInput_dB, "LmsConvergedAll", lmsFinite, "CausalLabel", string(causalRow.CausalLabel(1)), "DetectabilityProxyLabel", string(proxyRow.DetectabilityProxyLabel(1)), "DecisionRole", string(decisionRow.DecisionRole(1)), "DiagnosticScore", score);
end

rows = struct2table(rowStruct);

end

function row = localProfileRowTemplate()

row = struct("ProfileId", "", "SweepSource", "", "CandidateName", "", "FilterLength", NaN, "StepSize", NaN, "LeakageFactor", NaN, "DirectPathSuppression_dB", NaN, "SceneScoreDelta", NaN, "OffOriginEnergyFractionDelta", NaN, "OffOriginOccupiedFractionDelta", NaN, "ProtectedRetentionRatio", NaN, "ResidualToInputPower_dB", NaN, "LmsConvergedAll", false, "CausalLabel", "", "DetectabilityProxyLabel", "", "DecisionRole", "", "DiagnosticScore", NaN);

end

function score = localDiagnosticScore(candidateName, suppressionRow, protectedRow, proxyRow)

if candidateName == "none"
    score = 0.0;
    return
end

score = double(suppressionRow.MedianDirectPathSuppression_dB(1)) + 20.0 .* double(proxyRow.MedianSceneScoreDelta(1)) + 250.0 .* double(proxyRow.MedianOffOriginEnergyFractionDelta(1)) + min(double(protectedRow.MedianProtectedRetentionRatio(1)), 2.0);

end

function sensitivityTable = localBuildThresholdSensitivity(profileSummary, opts)

candidateRows = profileSummary(profileSummary.CandidateName ~= "none", :);
thresholdCases = opts.ThresholdCaseTable;
rows = repmat(localThresholdRowTemplate(), height(candidateRows) .* height(thresholdCases), 1);
rowIndex = 0;

for candidateIdx = 1:height(candidateRows)
    candidateRow = candidateRows(candidateIdx, :);

    for caseIdx = 1:height(thresholdCases)
        thresholdRow = thresholdCases(caseIdx, :);
        rowIndex = rowIndex + 1;
        suppressionPass = candidateRow.DirectPathSuppression_dB >= thresholdRow.DirectPathSuppressionThreshold_dB;
        sceneProxyPass = candidateRow.SceneScoreDelta >= thresholdRow.SceneScoreDeltaThreshold || candidateRow.OffOriginEnergyFractionDelta >= thresholdRow.OffOriginEnergyDeltaThreshold || candidateRow.OffOriginOccupiedFractionDelta >= thresholdRow.OffOriginOccupiedDeltaThreshold;
        retentionPass = candidateRow.ProtectedRetentionRatio >= thresholdRow.ProtectedRetentionFloor;
        wouldRevealScene = suppressionPass && sceneProxyPass && retentionPass;
        rows(rowIndex) = struct("ProfileId", string(candidateRow.ProfileId), "CandidateName", string(candidateRow.CandidateName), "ThresholdCase", string(thresholdRow.ThresholdCase), "DirectPathSuppressionThreshold_dB", double(thresholdRow.DirectPathSuppressionThreshold_dB), "SceneScoreDeltaThreshold", double(thresholdRow.SceneScoreDeltaThreshold), "OffOriginEnergyDeltaThreshold", double(thresholdRow.OffOriginEnergyDeltaThreshold), "OffOriginOccupiedDeltaThreshold", double(thresholdRow.OffOriginOccupiedDeltaThreshold), "ProtectedRetentionFloor", double(thresholdRow.ProtectedRetentionFloor), "SuppressionPass", logical(suppressionPass), "SceneProxyPass", logical(sceneProxyPass), "RetentionPass", logical(retentionPass), "WouldRevealScene", logical(wouldRevealScene), "FailureMode", localFailureMode(suppressionPass, sceneProxyPass, retentionPass));
    end
end

sensitivityTable = struct2table(rows);

end

function row = localThresholdRowTemplate()

row = struct("ProfileId", "", "CandidateName", "", "ThresholdCase", "", "DirectPathSuppressionThreshold_dB", NaN, "SceneScoreDeltaThreshold", NaN, "OffOriginEnergyDeltaThreshold", NaN, "OffOriginOccupiedDeltaThreshold", NaN, "ProtectedRetentionFloor", NaN, "SuppressionPass", false, "SceneProxyPass", false, "RetentionPass", false, "WouldRevealScene", false, "FailureMode", "");

end

function failureMode = localFailureMode(suppressionPass, sceneProxyPass, retentionPass)

if suppressionPass && sceneProxyPass && retentionPass
    failureMode = "passes_case";
elseif ~suppressionPass
    failureMode = "insufficient_direct_path_suppression";
elseif ~sceneProxyPass
    failureMode = "insufficient_scene_proxy_gain";
else
    failureMode = "protected_retention_failed";
end

end

function signalTable = localBuildSignalDiagnostics(sessionData, collectionMetadataInfo, g4Analysis, baseG5, opts)

selectedRows = baseG5.SelectedG4MapRows;
selectedRows = selectedRows(1:min(height(selectedRows), round(opts.MaxSignalRows)), :);
roleInfo = localRoleInfo(sessionData, collectionMetadataInfo, g4Analysis);
correction = localAppliedCorrection(g4Analysis);
rows = repmat(localSignalRowTemplate(), height(selectedRows), 1);

for idx = 1:height(selectedRows)
    selectedRow = selectedRows(idx, :);
    [referenceWindow, surveillanceWindow, note] = localExtractWindow(sessionData, selectedRow, roleInfo, correction);
    sampleRateHz = double(sessionData.RadarTable.SampleRate_Hz(1));
    [coherenceMedian, coherenceMax, coherenceAboveHalf] = localCoherenceMetrics(referenceWindow, surveillanceWindow, sampleRateHz);
    [referencePeakToMedian_dB, surveillancePeakToMedian_dB] = localPsdMetrics(referenceWindow, surveillanceWindow, sampleRateHz);
    spectrogramDynamicRange_dB = localSpectrogramDynamicRange(surveillanceWindow, sampleRateHz);
    rows(idx) = struct("MapRowId", idx, "Repetition", double(selectedRow.Repetition(1)), "CpiLabel", string(selectedRow.CpiLabel(1)), "WindowLabel", string(selectedRow.WindowLabel(1)), "WindowStartSample", double(selectedRow.WindowStartSample(1)), "WindowSamples", numel(referenceWindow), "ReferencePower_dB", localPowerToDb(mean(abs(referenceWindow) .^ 2)), "SurveillancePower_dB", localPowerToDb(mean(abs(surveillanceWindow) .^ 2)), "ReferenceSurveillanceCoherenceMedian", coherenceMedian, "ReferenceSurveillanceCoherenceMax", coherenceMax, "CoherenceFractionAboveHalf", coherenceAboveHalf, "ReferencePsdPeakToMedian_dB", referencePeakToMedian_dB, "SurveillancePsdPeakToMedian_dB", surveillancePeakToMedian_dB, "SurveillanceSpectrogramDynamicRange_dB", spectrogramDynamicRange_dB, "DiagnosticNote", note);
end

signalTable = struct2table(rows);

end

function row = localSignalRowTemplate()

row = struct("MapRowId", NaN, "Repetition", NaN, "CpiLabel", "", "WindowLabel", "", "WindowStartSample", NaN, "WindowSamples", NaN, "ReferencePower_dB", NaN, "SurveillancePower_dB", NaN, "ReferenceSurveillanceCoherenceMedian", NaN, "ReferenceSurveillanceCoherenceMax", NaN, "CoherenceFractionAboveHalf", NaN, "ReferencePsdPeakToMedian_dB", NaN, "SurveillancePsdPeakToMedian_dB", NaN, "SurveillanceSpectrogramDynamicRange_dB", NaN, "DiagnosticNote", "");

end

function roleInfo = localRoleInfo(sessionData, collectionMetadataInfo, g4Analysis)

channelLabels = [string(sessionData.RadarTable.Antenna1(1)); string(sessionData.RadarTable.Antenna2(1))];
referenceLabel = localG4Label(g4Analysis, "ReferenceLabel");
surveillanceLabel = localG4Label(g4Analysis, "SurveillanceLabel");

if strlength(referenceLabel) == 0 && isfield(collectionMetadataInfo, "ReferenceChannel")
    referenceLabel = string(collectionMetadataInfo.ReferenceChannel.ChannelLabel);
end

if strlength(surveillanceLabel) == 0 && isfield(collectionMetadataInfo, "SurveillanceChannel")
    surveillanceLabel = string(collectionMetadataInfo.SurveillanceChannel.ChannelLabel);
end

referenceIndex = find(channelLabels == referenceLabel, 1, "first");
surveillanceIndex = find(channelLabels == surveillanceLabel, 1, "first");

if isempty(referenceIndex) || isempty(surveillanceIndex) || referenceIndex == surveillanceIndex
    error("helperAnalyzeG5MitigationDiagnosticStudy:InvalidRoleMapping", "Could not resolve distinct reference and surveillance channels.");
end

roleInfo = struct("ReferenceColumnIndex", double(referenceIndex), "SurveillanceColumnIndex", double(surveillanceIndex));

end

function correction = localAppliedCorrection(g4Analysis)

definition = g4Analysis.BaselineProductDefinition;
correction = struct("AppliedLag_samples", double(definition.AppliedLag_samples), "AppliedResidualFrequency_Hz", double(definition.AppliedResidualFrequency_Hz));

end

function label = localG4Label(g4Analysis, fieldName)

label = "";

if isfield(g4Analysis, "Interpretation") && isfield(g4Analysis.Interpretation, fieldName)
    label = string(g4Analysis.Interpretation.(fieldName));
end

end

function [referenceWindow, surveillanceWindow, note] = localExtractWindow(sessionData, selectedRow, roleInfo, correction)

repetitionIndex = double(selectedRow.Repetition(1));
scan = localScanWithSamples(sessionData, repetitionIndex);
referenceSamples = double(scan.Samples(:, roleInfo.ReferenceColumnIndex));
surveillanceSamples = double(scan.Samples(:, roleInfo.SurveillanceColumnIndex));
surveillanceSamples = localApplyIntegerDelay(surveillanceSamples, correction.AppliedLag_samples);
surveillanceSamples = localApplyResidualFrequencyCorrection(surveillanceSamples, correction.AppliedResidualFrequency_Hz, double(sessionData.RadarTable.SampleRate_Hz(1)));
startSample = max(1, round(double(selectedRow.WindowStartSample(1))));
rawWindowSamples = round(double(selectedRow.CpiSamples(1)) .* double(selectedRow.MapDecimationFactor(1)));
stopSample = min(numel(referenceSamples), startSample + rawWindowSamples - 1);
referenceWindow = referenceSamples(startSample:stopSample);
surveillanceWindow = surveillanceSamples(startSample:stopSample);
note = "corrected_reference_surveillance_window";

end

function scan = localScanWithSamples(sessionData, repetitionIndex)

scan = sessionData.RadarScans(repetitionIndex);

if ~isempty(scan.Samples)
    return
end

absoluteFilePath = fullfile(string(sessionData.DatasetRoot), strrep(sessionData.RadarTable.RelativePath(repetitionIndex), "/", filesep));

try
    scan = helperScanBasebandCaptureFile(absoluteFilePath, true);
catch readException
    error("helperAnalyzeG5MitigationDiagnosticStudy:ReadSamplesFailed", "Failed to load samples for %s: %s", absoluteFilePath, readException.message);
end

end

function delayedSignal = localApplyIntegerDelay(inputSignal, sampleDelay)

sampleDelay = round(double(sampleDelay));
signalLength = numel(inputSignal);

if sampleDelay == 0 || signalLength == 0
    delayedSignal = inputSignal;
    return
end

if sampleDelay > 0
    if sampleDelay >= signalLength
        delayedSignal = zeros(size(inputSignal), "like", inputSignal);
        return
    end

    delayedSignal = [zeros(sampleDelay, 1, "like", inputSignal); inputSignal(1:end - sampleDelay)];
    return
end

advanceCount = abs(sampleDelay);

if advanceCount >= signalLength
    delayedSignal = zeros(size(inputSignal), "like", inputSignal);
    return
end

delayedSignal = [inputSignal(advanceCount + 1:end); zeros(advanceCount, 1, "like", inputSignal)];

end

function correctedSignal = localApplyResidualFrequencyCorrection(inputSignal, residualFrequencyHz, sampleRateHz)

sampleCount = numel(inputSignal);
sampleIndex = (0:sampleCount - 1).';
correctionPhase = exp(-1j .* 2.0 .* pi .* residualFrequencyHz .* sampleIndex ./ sampleRateHz);
correctedSignal = inputSignal(:) .* correctionPhase;

end

function [coherenceMedian, coherenceMax, coherenceAboveHalf] = localCoherenceMetrics(referenceWindow, surveillanceWindow, sampleRateHz)

if exist("mscohere", "file") ~= 2
    coherenceMedian = NaN;
    coherenceMax = NaN;
    coherenceAboveHalf = NaN;
    return
end

segmentLength = localSegmentLength(numel(referenceWindow));
analysisWindow = hamming(segmentLength, "periodic");
overlapLength = floor(segmentLength ./ 2.0);
coherenceValues = mscohere(referenceWindow, surveillanceWindow, analysisWindow, overlapLength, segmentLength, sampleRateHz);
coherenceMedian = median(coherenceValues, "omitnan");
coherenceMax = max(coherenceValues, [], "omitnan");
coherenceAboveHalf = mean(coherenceValues >= 0.5, "omitnan");

end

function [referencePeakToMedian_dB, surveillancePeakToMedian_dB] = localPsdMetrics(referenceWindow, surveillanceWindow, sampleRateHz)

if exist("pwelch", "file") ~= 2
    referencePeakToMedian_dB = NaN;
    surveillancePeakToMedian_dB = NaN;
    return
end

segmentLength = localSegmentLength(numel(referenceWindow));
analysisWindow = hamming(segmentLength, "periodic");
overlapLength = floor(segmentLength ./ 2.0);
referencePsd = pwelch(referenceWindow, analysisWindow, overlapLength, segmentLength, sampleRateHz, "centered");
surveillancePsd = pwelch(surveillanceWindow, analysisWindow, overlapLength, segmentLength, sampleRateHz, "centered");
referencePeakToMedian_dB = localPowerToDb(max(referencePsd, [], "omitnan") ./ max(median(referencePsd, "omitnan"), eps));
surveillancePeakToMedian_dB = localPowerToDb(max(surveillancePsd, [], "omitnan") ./ max(median(surveillancePsd, "omitnan"), eps));

end

function dynamicRange_dB = localSpectrogramDynamicRange(surveillanceWindow, sampleRateHz)

if exist("spectrogram", "file") ~= 2
    dynamicRange_dB = NaN;
    return
end

segmentLength = localSegmentLength(numel(surveillanceWindow));
analysisWindow = hamming(segmentLength, "periodic");
overlapLength = floor(segmentLength ./ 2.0);
spectrogramMatrix = spectrogram(surveillanceWindow, analysisWindow, overlapLength, segmentLength, sampleRateHz, "centered");
spectrogramPower = abs(spectrogramMatrix) .^ 2;
dynamicRange_dB = localPowerToDb(max(spectrogramPower, [], "all") ./ max(median(spectrogramPower, "all", "omitnan"), eps));

end

function segmentLength = localSegmentLength(sampleCount)

segmentLength = min(4096, max(128, floor(double(sampleCount) ./ 8.0)));
segmentLength = 2 .^ floor(log2(segmentLength));
segmentLength = max(64, segmentLength);

end

function conclusionTable = localBuildConclusion(sourceSummary, profileSummary, thresholdSensitivity, signalDiagnostics)

candidateRows = profileSummary(profileSummary.CandidateName ~= "none", :);
defaultRows = thresholdSensitivity(thresholdSensitivity.ThresholdCase == "default_gate", :);
permissiveRows = thresholdSensitivity(thresholdSensitivity.ThresholdCase == "permissive_probe", :);
defaultPassRows = defaultRows(defaultRows.WouldRevealScene, :);
permissivePassRows = permissiveRows(permissiveRows.WouldRevealScene, :);
leakageOnlyRows = candidateRows(candidateRows.DirectPathSuppression_dB >= 3.0 & candidateRows.ProtectedRetentionRatio >= 0.50, :);

if ~isempty(defaultPassRows)
    primaryLabel = "tunable_g5_candidate";
    bestRow = localBestCandidate(candidateRows, defaultPassRows(1, :));
    action = "Review diagnostic candidate manually before changing formal G5 profiles.";
elseif ~isempty(permissivePassRows)
    primaryLabel = "mask_definition_sensitive";
    bestRow = localBestCandidate(candidateRows, permissivePassRows(1, :));
    action = "Inspect masks and scene-proxy thresholds before retuning G5.";
elseif ~isempty(leakageOnlyRows)
    primaryLabel = "leakage_only_cleanup";
    bestRow = leakageOnlyRows(1, :);
    action = "Treat mitigation as diagnostic cleanup and prioritize acquisition plus G4 rate/scene review.";
else
    primaryLabel = "acquisition_limited";
    bestRow = candidateRows(1, :);
    action = "Prioritize acquisition geometry, direct-path rejection, gain staging, and RF isolation.";
end

secondaryLabel = localSecondaryCaveat(sourceSummary);
coherenceMedian = median(signalDiagnostics.ReferenceSurveillanceCoherenceMedian, "omitnan");
rationale = localRationale(primaryLabel, secondaryLabel, coherenceMedian);
conclusionTable = table(primaryLabel, secondaryLabel, string(bestRow.ProfileId(1)), string(bestRow.CandidateName(1)), double(bestRow.DirectPathSuppression_dB(1)), double(bestRow.SceneScoreDelta(1)), double(bestRow.OffOriginEnergyFractionDelta(1)), double(bestRow.ProtectedRetentionRatio(1)), string(bestRow.CausalLabel(1)), coherenceMedian, rationale, action, false, VariableNames = {'PrimaryConclusionLabel', 'SecondaryCaveatLabel', 'BestProfileId', 'BestCandidateName', 'BestDirectPathSuppression_dB', 'BestSceneScoreDelta', 'BestOffOriginEnergyFractionDelta', 'BestProtectedRetentionRatio', 'BestCausalLabel', 'MedianReferenceSurveillanceCoherence', 'Rationale', 'RecommendedNextAction', 'FormalGateDecisionChanged'});

end

function bestRow = localBestCandidate(candidateRows, sensitivityRow)

matchingRows = candidateRows(candidateRows.ProfileId == sensitivityRow.ProfileId(1) & candidateRows.CandidateName == sensitivityRow.CandidateName(1), :);

if isempty(matchingRows)
    bestRow = candidateRows(1, :);
else
    bestRow = matchingRows(1, :);
end

end

function secondaryLabel = localSecondaryCaveat(sourceSummary)

secondaryLabel = "none";

if sourceSummary.SourceG4FullRateAuditAgreementLabel == "disagreement"
    secondaryLabel = "rate_limited_evidence";
elseif sourceSummary.SourceG4OverallLabel == "blocked"
    secondaryLabel = "upstream_g4_blocked";
end

end

function rationale = localRationale(primaryLabel, secondaryLabel, coherenceMedian)

if primaryLabel == "tunable_g5_candidate"
    rationale = "At least one diagnostic profile crossed default scene-reveal, suppression, and retention checks.";
elseif primaryLabel == "mask_definition_sensitive"
    rationale = "Evidence only crosses a permissive probe case, so the result is sensitive to masks or thresholds.";
elseif primaryLabel == "leakage_only_cleanup"
    rationale = "Mitigation suppresses reference-correlated leakage but does not produce enough scene-proxy gain.";
else
    rationale = "Diagnostic profiles did not produce useful scene-recovery evidence.";
end

if secondaryLabel ~= "none"
    rationale = rationale + " Secondary caveat: " + secondaryLabel + ".";
end

if isfinite(coherenceMedian)
    rationale = rationale + sprintf(" Median reference/surveillance coherence was %.3f.", coherenceMedian);
end

end

function value_dB = localPowerToDb(powerValue)

value_dB = 10.0 .* log10(max(double(powerValue), eps));

end