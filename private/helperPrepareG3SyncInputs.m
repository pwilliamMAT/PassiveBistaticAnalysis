function syncPrep = helperPrepareG3SyncInputs(sessionData, ...
    collectionMetadataInfo, options, g3SyncResults)
%HELPERPREPAREG3SYNCINPUTS Build the shared sync-preparation contract.
%
%   SYNCPREP = HELPERPREPAREG3SYNCINPUTS(SESSIONDATA, ...
%   COLLECTIONMETADATAINFO, OPTIONS) resolves the frozen Stage 3 contracts,
%   builds the per-window lag and residual-frequency observations, and
%   derives the global-session correction used by later downstream work.
%
%   SYNCPREP = HELPERPREPAREG3SYNCINPUTS(..., G3SYNCRESULTS) also carries
%   per-CPI admissibility labels forward when an upstream G3 result is
%   available.

arguments
    sessionData (1,1) struct
    collectionMetadataInfo (1,1) struct
    options (1,1) struct = struct()
    g3SyncResults (1,1) struct = struct()
end

resolvedOptions = localResolveOptions(sessionData, options);
roleInfo = localResolveRoleInfo(sessionData, collectionMetadataInfo, ...
    resolvedOptions);
localValidateContracts(sessionData, roleInfo, resolvedOptions);

windowObservations = localBuildWindowObservations(sessionData, roleInfo, ...
    resolvedOptions);
globalCorrection = localBuildGlobalCorrection(windowObservations, ...
    resolvedOptions);
cpiAdmissibilityTable = localBuildCpiAdmissibilityTable(g3SyncResults, ...
    resolvedOptions);

syncPrep = struct();
syncPrep.DatasetId = string(sessionData.DatasetId);
syncPrep.RoleInfo = roleInfo;
syncPrep.ResolvedOptions = resolvedOptions;
syncPrep.CpiDefinitions = resolvedOptions.CpiDefinitions;
syncPrep.WindowObservations = windowObservations;
syncPrep.GlobalCorrection = globalCorrection;
syncPrep.CpiAdmissibilityTable = cpiAdmissibilityTable;

end

function resolvedOptions = localResolveOptions(sessionData, options)

sampleRateVector = unique(sessionData.RadarTable.SampleRate_Hz);
sampleCountVector = unique(sessionData.RadarTable.NumSamples);

if numel(sampleRateVector) ~= 1
    error("helperPrepareG3SyncInputs:SampleRateMismatch", ...
        "Stage 3 requires one frozen sample rate across the session.");
end

if numel(sampleCountVector) ~= 1
    error("helperPrepareG3SyncInputs:SampleCountMismatch", ...
        "Stage 3 requires one frozen sample count across the session.");
end

resolvedOptions = struct();
resolvedOptions.ExpectedDatasetId = "20260622T102123";
resolvedOptions.ExpectedReferenceLabel = "RF1:RX2";
resolvedOptions.ExpectedSurveillanceLabel = "RF0:RX2";
resolvedOptions.ExpectedRepetitionCount = 15;
resolvedOptions.DataProfile = "field_capture";
resolvedOptions.SampleRateHz = double(sampleRateVector(1));
resolvedOptions.SamplesPerRepetition = double(sampleCountVector(1));
resolvedOptions.CpiLabels = ["short"; "medium"; "long"];
resolvedOptions.CpiDurations_s = [0.025; 0.050; 0.100];
resolvedOptions.WindowHopFractions = [1.0; 1.0; 1.0];
resolvedOptions.CorrelationSampleCount = 131072;
resolvedOptions.CorrelationMaxLagSamples = 4096;
resolvedOptions.XcorrMainlobeExclusionSamples = 8;
resolvedOptions.CoherenceWindowLength = 4096;
resolvedOptions.CoherenceOverlap = 2048;
resolvedOptions.CoherenceNfft = 4096;
resolvedOptions.CoherenceBandEdgeFraction = 0.45;
resolvedOptions.CoherencePassThreshold = 0.80;
resolvedOptions.CoherenceCaveatedThreshold = 0.65;
resolvedOptions.CoherenceReadyPassFractionThreshold = 0.80;
resolvedOptions.CoherenceBlockedPassFractionThreshold = 0.50;
resolvedOptions.SpectrogramWindowLength = 4096;
resolvedOptions.SpectrogramOverlap = 3072;
resolvedOptions.SpectrogramNfft = 4096;
resolvedOptions.SpectrogramBandThreshold_dB = 20.0;
resolvedOptions.SpectrogramMinimumBandBins = 32;
resolvedOptions.LagReadySpreadThresholdSamples = 0.5;
resolvedOptions.LagBlockedSpreadThresholdSamples = 2.0;
resolvedOptions.LagReadySharpnessThreshold_dB = 6.0;
resolvedOptions.LagBlockedSharpnessThreshold_dB = 3.0;
resolvedOptions.DelayAgreementReadyThreshold = 0.90;
resolvedOptions.DelayAgreementBlockedThreshold = 0.50;
resolvedOptions.PhaseExcursionReadyThreshold_deg = 15.0;
resolvedOptions.PhaseExcursionBlockedThreshold_deg = 45.0;
resolvedOptions.PhaseFitRmseReadyThreshold_deg = 5.0;
resolvedOptions.PhaseFitRmseBlockedThreshold_deg = 15.0;
resolvedOptions.StrategyComparisonCpiLabel = "short";
resolvedOptions.StrategyLagPassThresholdSamples = 1.0;
resolvedOptions.StrategyPhasePassThreshold_deg = 15.0;
resolvedOptions.StrategyPassFractionMargin = 0.05;
resolvedOptions.StrategyLagEquivalenceMarginSamples = 0.5;
resolvedOptions.StrategyPhaseEquivalenceMargin_deg = 5.0;

optionFields = fieldnames(options);

for idx = 1:numel(optionFields)
    fieldName = optionFields{idx};
    resolvedOptions.(fieldName) = options.(fieldName);
end

resolvedOptions.CpiLabels = string(resolvedOptions.CpiLabels(:));
resolvedOptions.CpiDurations_s = double(resolvedOptions.CpiDurations_s(:));
resolvedOptions.WindowHopFractions = ...
    double(resolvedOptions.WindowHopFractions(:));

if numel(resolvedOptions.CpiLabels) ~= numel(resolvedOptions.CpiDurations_s)
    error("helperPrepareG3SyncInputs:InvalidCpiDefinition", ...
        "CPI labels and CPI durations must have the same length.");
end

if numel(resolvedOptions.WindowHopFractions) ~= ...
        numel(resolvedOptions.CpiDurations_s)
    error("helperPrepareG3SyncInputs:InvalidWindowHopDefinition", ...
        "Each CPI length requires one hop fraction.");
end

resolvedOptions.CpiSampleCounts = round( ...
    resolvedOptions.CpiDurations_s .* resolvedOptions.SampleRateHz);
resolvedOptions.WindowHopSamples = max(1, round( ...
    resolvedOptions.WindowHopFractions .* ...
    resolvedOptions.CpiSampleCounts));
resolvedOptions.CpiDefinitions = localBuildCpiDefinitions( ...
    resolvedOptions.CpiLabels, resolvedOptions.CpiDurations_s, ...
    resolvedOptions.CpiSampleCounts, resolvedOptions.WindowHopSamples);

end

function cpiDefinitions = localBuildCpiDefinitions(cpiLabels, ...
    cpiDurationsSeconds, cpiSampleCounts, windowHopSamples)

definitionCount = numel(cpiLabels);
cpiDefinitions = repmat(struct( ...
    "Label", "", ...
    "Duration_s", NaN, ...
    "Samples", NaN, ...
    "WindowHopSamples", NaN ...
    ), definitionCount, 1);

for idx = 1:definitionCount
    cpiDefinitions(idx).Label = string(cpiLabels(idx));
    cpiDefinitions(idx).Duration_s = double(cpiDurationsSeconds(idx));
    cpiDefinitions(idx).Samples = double(cpiSampleCounts(idx));
    cpiDefinitions(idx).WindowHopSamples = double(windowHopSamples(idx));
end

end

function roleInfo = localResolveRoleInfo(sessionData, collectionMetadataInfo, ...
    resolvedOptions)

roleInfo = helperResolveChannelRoles(sessionData, collectionMetadataInfo, ...
    resolvedOptions);

if roleInfo.ReferenceLabel ~= resolvedOptions.ExpectedReferenceLabel || ...
        roleInfo.SurveillanceLabel ~= ...
        resolvedOptions.ExpectedSurveillanceLabel
    error("helperPrepareG3SyncInputs:UnexpectedRoleMapping", ...
        [ ...
        "Stage 3 is scoped only to reference %s and surveillance %s ", ...
        "for the baseline session." ...
        ], resolvedOptions.ExpectedReferenceLabel, ...
        resolvedOptions.ExpectedSurveillanceLabel);
end

end

function localValidateContracts(sessionData, roleInfo, resolvedOptions)

datasetId = string(sessionData.DatasetId);
repetitionCount = height(sessionData.RadarTable);

if datasetId ~= resolvedOptions.ExpectedDatasetId
    error("helperPrepareG3SyncInputs:UnexpectedDataset", ...
        "Stage 3 is scoped only to dataset %s.", ...
        resolvedOptions.ExpectedDatasetId);
end

if repetitionCount ~= resolvedOptions.ExpectedRepetitionCount
    error("helperPrepareG3SyncInputs:UnexpectedRepetitionCount", ...
        "Expected %d repetitions for Stage 3 but found %d.", ...
        resolvedOptions.ExpectedRepetitionCount, repetitionCount);
end

if ~isfield(sessionData, "CpiContract") || ...
        ~isfield(sessionData.CpiContract, "CrossFileAllowed") || ...
        logical(sessionData.CpiContract.CrossFileAllowed)
    error("helperPrepareG3SyncInputs:UnexpectedCpiContract", ...
        "Stage 3 requires the frozen G1 intra-file-only CPI contract.");
end

if any(resolvedOptions.CpiSampleCounts > ...
        resolvedOptions.SamplesPerRepetition)
    error("helperPrepareG3SyncInputs:OversizedCpi", ...
        "Each Stage 3 CPI length must fit within one repetition.");
end

if isnan(roleInfo.ReferenceColumnIndex) || ...
        isnan(roleInfo.SurveillanceColumnIndex)
    error("helperPrepareG3SyncInputs:InvalidRoleColumns", ...
        "Stage 3 could not resolve the fixed reference/surveillance columns.");
end

end

function windowObservations = localBuildWindowObservations(sessionData, ...
    roleInfo, resolvedOptions)

radarTable = sessionData.RadarTable;
repetitionCount = height(radarTable);
windowCountPerRepetition = zeros(numel(resolvedOptions.CpiDefinitions), 1);

for idx = 1:numel(resolvedOptions.CpiDefinitions)
    cpiSamples = resolvedOptions.CpiDefinitions(idx).Samples;
    hopSamples = resolvedOptions.CpiDefinitions(idx).WindowHopSamples;
    maxStart = resolvedOptions.SamplesPerRepetition - cpiSamples + 1;
    windowStarts = 1:hopSamples:maxStart;
    windowCountPerRepetition(idx) = numel(windowStarts);
end

totalObservationCount = repetitionCount * sum(windowCountPerRepetition);
rowTemplate = localBuildWindowObservationTemplate();
rows = repmat(rowTemplate, totalObservationCount, 1);
rowIndex = 0;

for repetitionIndex = 1:repetitionCount
    scan = localResolveScanWithSamples(sessionData, repetitionIndex);
    referenceSamples = double(scan.Samples(:, roleInfo.ReferenceColumnIndex));
    surveillanceSamples = double(scan.Samples(:, ...
        roleInfo.SurveillanceColumnIndex));

    for cpiIndex = 1:numel(resolvedOptions.CpiDefinitions)
        cpiDefinition = resolvedOptions.CpiDefinitions(cpiIndex);
        maxStart = numel(referenceSamples) - cpiDefinition.Samples + 1;
        windowStarts = 1:cpiDefinition.WindowHopSamples:maxStart;

        for windowIndex = 1:numel(windowStarts)
            startSample = windowStarts(windowIndex);
            stopSample = startSample + cpiDefinition.Samples - 1;
            referenceWindow = referenceSamples(startSample:stopSample);
            surveillanceWindow = surveillanceSamples(startSample:stopSample);
            lagMetrics = localEstimateLag(referenceWindow, ...
                surveillanceWindow, resolvedOptions);
            alignedSurveillance = localApplyIntegerDelay( ...
                surveillanceWindow, lagMetrics.CanonicalLagSamples);
            residualMetrics = localEstimateResidualFrequency( ...
                referenceWindow, alignedSurveillance, cpiDefinition, ...
                resolvedOptions);
            coherenceMetrics = localEstimateCoherence(referenceWindow, ...
                alignedSurveillance, resolvedOptions);

            rowIndex = rowIndex + 1;
            rows(rowIndex) = struct( ...
                "Repetition", double(radarTable.Repetition(repetitionIndex)), ...
                "RelativePath", string(radarTable.RelativePath(repetitionIndex)), ...
                "CpiLabel", cpiDefinition.Label, ...
                "CpiDuration_s", cpiDefinition.Duration_s, ...
                "CpiSamples", cpiDefinition.Samples, ...
                "WindowIndex", double(windowIndex), ...
                "WindowStartSample", double(startSample), ...
                "WindowStopSample", double(stopSample), ...
                "FindDelayLagSamples", lagMetrics.FindDelayLagSamples, ...
                "XcorrLagSamples", lagMetrics.XcorrLagSamples, ...
                "CanonicalLagSamples", lagMetrics.CanonicalLagSamples, ...
                "DelayEstimateAgreement", lagMetrics.DelayEstimateAgreement, ...
                "PeakCorrelationMagnitude", ...
                lagMetrics.PeakCorrelationMagnitude, ...
                "ZeroLagCorrelationMagnitude", ...
                lagMetrics.ZeroLagCorrelationMagnitude, ...
                "PeakToSidelobe_dB", lagMetrics.PeakToSidelobe_dB, ...
                "PeakToZero_dB", lagMetrics.PeakToZero_dB, ...
                "ResidualFrequencyHz", residualMetrics.ResidualFrequencyHz, ...
                "PhaseExcursion_deg", residualMetrics.PhaseExcursion_deg, ...
                "PhaseFitRmse_deg", residualMetrics.PhaseFitRmse_deg, ...
                "SpectrogramBandBinCount", ...
                residualMetrics.SpectrogramBandBinCount, ...
                "CoherenceMean", coherenceMetrics.CoherenceMean, ...
                "CoherenceP10", coherenceMetrics.CoherenceP10, ...
                "CoherenceMinimum", coherenceMetrics.CoherenceMinimum ...
                );
        end
    end
end

windowObservations = struct2table(rows(1:rowIndex));
windowObservations = sortrows(windowObservations, ...
    ["Repetition", "CpiLabel", "WindowIndex"]);

end

function rowTemplate = localBuildWindowObservationTemplate()

rowTemplate = struct( ...
    "Repetition", NaN, ...
    "RelativePath", "", ...
    "CpiLabel", "", ...
    "CpiDuration_s", NaN, ...
    "CpiSamples", NaN, ...
    "WindowIndex", NaN, ...
    "WindowStartSample", NaN, ...
    "WindowStopSample", NaN, ...
    "FindDelayLagSamples", NaN, ...
    "XcorrLagSamples", NaN, ...
    "CanonicalLagSamples", NaN, ...
    "DelayEstimateAgreement", false, ...
    "PeakCorrelationMagnitude", NaN, ...
    "ZeroLagCorrelationMagnitude", NaN, ...
    "PeakToSidelobe_dB", NaN, ...
    "PeakToZero_dB", NaN, ...
    "ResidualFrequencyHz", NaN, ...
    "PhaseExcursion_deg", NaN, ...
    "PhaseFitRmse_deg", NaN, ...
    "SpectrogramBandBinCount", NaN, ...
    "CoherenceMean", NaN, ...
    "CoherenceP10", NaN, ...
    "CoherenceMinimum", NaN ...
    );

end

function scan = localResolveScanWithSamples(sessionData, repetitionIndex)

scan = sessionData.RadarScans(repetitionIndex);

if ~isempty(scan.Samples)
    return
end

absoluteFilePath = fullfile(string(sessionData.DatasetRoot), ...
    strrep(sessionData.RadarTable.RelativePath(repetitionIndex), ...
    "/", filesep));

try
    scan = helperScanBasebandCaptureFile(absoluteFilePath, true);
catch readException
    error("helperPrepareG3SyncInputs:ReadSamplesFailed", ...
        "Failed to load samples for %s: %s", absoluteFilePath, ...
        readException.message);
end

end

function lagMetrics = localEstimateLag(referenceWindow, surveillanceWindow, ...
    resolvedOptions)

correlationSampleCount = min(numel(referenceWindow), ...
    resolvedOptions.CorrelationSampleCount);
referenceSegment = referenceWindow(1:correlationSampleCount);
surveillanceSegment = surveillanceWindow(1:correlationSampleCount);
findDelayLag = finddelay(referenceSegment, surveillanceSegment, ...
    resolvedOptions.CorrelationMaxLagSamples);
[correlationValues, correlationLags] = xcorr(referenceSegment, ...
    surveillanceSegment, resolvedOptions.CorrelationMaxLagSamples, ...
    "normalized");
[peakCorrelationMagnitude, peakIndex] = max(abs(correlationValues));
xcorrLag = correlationLags(peakIndex);
zeroLagIndex = find(correlationLags == 0, 1, "first");
zeroLagCorrelationMagnitude = abs(correlationValues(zeroLagIndex));
mainlobeMask = abs(correlationLags - xcorrLag) <= ...
    resolvedOptions.XcorrMainlobeExclusionSamples;
sidelobeValues = abs(correlationValues(~mainlobeMask));

lagMetrics = struct();
lagMetrics.FindDelayLagSamples = double(findDelayLag);
lagMetrics.XcorrLagSamples = double(xcorrLag);
lagMetrics.CanonicalLagSamples = double(xcorrLag);
lagMetrics.DelayEstimateAgreement = ...
    double(xcorrLag) == -double(findDelayLag);
lagMetrics.PeakCorrelationMagnitude = double(peakCorrelationMagnitude);
lagMetrics.ZeroLagCorrelationMagnitude = ...
    double(zeroLagCorrelationMagnitude);
lagMetrics.PeakToSidelobe_dB = 20.0 * log10( ...
    double(peakCorrelationMagnitude) / max(max(sidelobeValues), eps));
lagMetrics.PeakToZero_dB = 20.0 * log10( ...
    double(peakCorrelationMagnitude) / ...
    max(double(zeroLagCorrelationMagnitude), eps));

end

function delayedSignal = localApplyIntegerDelay(inputSignal, sampleDelay)

sampleDelay = double(sampleDelay);
signalLength = numel(inputSignal);

if signalLength == 0
    delayedSignal = inputSignal;
    return
end

if sampleDelay > 0
    if sampleDelay >= signalLength
        delayedSignal = zeros(size(inputSignal), "like", inputSignal);
        return
    end

    delayedSignal = [ ...
        zeros(sampleDelay, 1, "like", inputSignal); ...
        inputSignal(1:end - sampleDelay) ...
        ];
    return
end

if sampleDelay < 0
    advanceCount = abs(sampleDelay);

    if advanceCount >= signalLength
        delayedSignal = zeros(size(inputSignal), "like", inputSignal);
        return
    end

    delayedSignal = [ ...
        inputSignal(advanceCount + 1:end); ...
        zeros(advanceCount, 1, "like", inputSignal) ...
        ];
    return
end

delayedSignal = inputSignal;

end

function residualMetrics = localEstimateResidualFrequency(referenceWindow, ...
    alignedSurveillance, cpiDefinition, resolvedOptions)

stftWindow = hamming(resolvedOptions.SpectrogramWindowLength, ...
    "periodic");
[referenceSpectrogram, frequencyHz, timeSeconds] = spectrogram( ...
    referenceWindow, stftWindow, resolvedOptions.SpectrogramOverlap, ...
    resolvedOptions.SpectrogramNfft, resolvedOptions.SampleRateHz, ...
    "centered");
[surveillanceSpectrogram, ~, ~] = spectrogram(alignedSurveillance, ...
    stftWindow, resolvedOptions.SpectrogramOverlap, ...
    resolvedOptions.SpectrogramNfft, resolvedOptions.SampleRateHz, ...
    "centered");
referencePowerByBin = mean(abs(referenceSpectrogram) .^ 2, 2);
analysisBandMask = abs(frequencyHz) <= ...
    resolvedOptions.CoherenceBandEdgeFraction * ...
    resolvedOptions.SampleRateHz;
bandMask = referencePowerByBin >= max(referencePowerByBin) * ...
    10.0 ^ (-resolvedOptions.SpectrogramBandThreshold_dB / 10.0) & ...
    analysisBandMask;

if nnz(bandMask) < resolvedOptions.SpectrogramMinimumBandBins
    candidateIndices = find(analysisBandMask);
    [~, sortOrder] = sort(referencePowerByBin(candidateIndices), ...
        "descend");
    bandMask = false(size(referencePowerByBin));
    keepCount = min(resolvedOptions.SpectrogramMinimumBandBins, ...
        numel(sortOrder));
    bandMask(candidateIndices(sortOrder(1:keepCount))) = true;
end

crossSpectrum = surveillanceSpectrogram(bandMask, :) .* conj( ...
    referenceSpectrogram(bandMask, :));
bandCrossSeries = sum(crossSpectrum, 1).';
phaseVector = unwrap(angle(bandCrossSeries));
fitCoefficients = polyfit(timeSeconds(:), phaseVector, 1);
fitPhaseVector = polyval(fitCoefficients, timeSeconds(:));
residualFrequencyHz = fitCoefficients(1) / (2.0 * pi);

residualMetrics = struct();
residualMetrics.ResidualFrequencyHz = double(residualFrequencyHz);
residualMetrics.PhaseExcursion_deg = abs(residualFrequencyHz) * ...
    cpiDefinition.Duration_s * 360.0;
residualMetrics.PhaseFitRmse_deg = rad2deg(sqrt(mean((phaseVector - ...
    fitPhaseVector) .^ 2)));
residualMetrics.SpectrogramBandBinCount = double(nnz(bandMask));

end

function coherenceMetrics = localEstimateCoherence(referenceWindow, ...
    alignedSurveillance, resolvedOptions)

coherenceWindow = hamming(resolvedOptions.CoherenceWindowLength, ...
    "periodic");
[coherenceVector, coherenceFrequencyHz] = mscohere(referenceWindow, ...
    alignedSurveillance, coherenceWindow, resolvedOptions.CoherenceOverlap, ...
    resolvedOptions.CoherenceNfft, resolvedOptions.SampleRateHz);
[coherenceFrequencyHz, coherenceVector] = localCenterSingleSpectrum( ...
    coherenceFrequencyHz, coherenceVector, ...
    resolvedOptions.SampleRateHz);
analysisBandMask = abs(coherenceFrequencyHz) <= ...
    resolvedOptions.CoherenceBandEdgeFraction * ...
    resolvedOptions.SampleRateHz;
bandCoherence = coherenceVector(analysisBandMask);

coherenceMetrics = struct();
coherenceMetrics.CoherenceMean = mean(bandCoherence, "omitnan");
coherenceMetrics.CoherenceP10 = prctile(bandCoherence, 10);
coherenceMetrics.CoherenceMinimum = min(bandCoherence);

end

function [frequencyHz, spectrum] = localCenterSingleSpectrum( ...
    frequencyHz, spectrum, sampleRateHz)

if max(frequencyHz) <= sampleRateHz / 2
    return
end

frequencyHz = frequencyHz - sampleRateHz / 2;
spectrum = fftshift(spectrum);

end

function globalCorrection = localBuildGlobalCorrection(windowObservations, ...
    resolvedOptions)

baseObservations = windowObservations( ...
    windowObservations.CpiLabel == ...
    resolvedOptions.StrategyComparisonCpiLabel, :);

if isempty(baseObservations)
    error("helperPrepareG3SyncInputs:MissingStrategyBaseObservations", ...
        "No %s CPI observations are available for the frozen global " + ...
        "correction derivation.", resolvedOptions.StrategyComparisonCpiLabel);
end

globalLagSamples = round(median(baseObservations.CanonicalLagSamples));
globalResidualFrequencyHz = median(baseObservations.ResidualFrequencyHz);

globalCorrection = struct();
globalCorrection.StrategyCandidate = "global_session_correction";
globalCorrection.SourceCpiLabel = ...
    string(resolvedOptions.StrategyComparisonCpiLabel);
globalCorrection.AppliedLag_samples = double(globalLagSamples);
globalCorrection.AppliedResidualFrequency_Hz = ...
    double(globalResidualFrequencyHz);
globalCorrection.LagResidualMax_samples = max(abs( ...
    baseObservations.CanonicalLagSamples - globalLagSamples));
globalCorrection.ResidualFrequencySpread_Hz = max(abs( ...
    baseObservations.ResidualFrequencyHz - globalResidualFrequencyHz));
globalCorrection.WindowCount = double(height(baseObservations));

end

function cpiAdmissibilityTable = localBuildCpiAdmissibilityTable( ...
    g3SyncResults, resolvedOptions)

cpiLabel = string(resolvedOptions.CpiLabels(:));
rowCount = numel(cpiLabel);
eligibilityAvailable = false(rowCount, 1);
eligible = true(rowCount, 1);
g3EligibilityLabel = repmat("not_available", rowCount, 1);
rationale = repmat("Upstream G3 CPI admissibility was not supplied.", ...
    rowCount, 1);

if isfield(g3SyncResults, "CpiCoherenceTable") && ...
        istable(g3SyncResults.CpiCoherenceTable)
    cpiCoherenceTable = g3SyncResults.CpiCoherenceTable;

    for idx = 1:rowCount
        subset = cpiCoherenceTable(cpiCoherenceTable.CpiLabel == ...
            cpiLabel(idx), :);

        if isempty(subset)
            continue
        end

        collapsedLabel = localCollapseInterpretationLabels( ...
            subset.InterpretationLabel);
        eligibilityAvailable(idx) = true;

        if collapsedLabel == "blocked"
            g3EligibilityLabel(idx) = "ineligible";
            eligible(idx) = false;
        else
            g3EligibilityLabel(idx) = collapsedLabel;
            eligible(idx) = true;
        end

        rationale(idx) = sprintf("G3 coherence admissibility for %s " + ...
            "collapsed to %s from %d repetition-level rows.", ...
            cpiLabel(idx), g3EligibilityLabel(idx), height(subset));
    end
end

cpiAdmissibilityTable = table(cpiLabel, eligibilityAvailable, eligible, ...
    g3EligibilityLabel, rationale, VariableNames = ...
    {'CpiLabel', 'EligibilityAvailable', 'Eligible', ...
    'G3EligibilityLabel', 'Rationale'});

end

function label = localCollapseInterpretationLabels(labelVector)

labelVector = string(labelVector(:));

if any(labelVector == "blocked")
    label = "blocked";
elseif any(labelVector == "caveated")
    label = "caveated";
else
    label = "ready";
end

end
