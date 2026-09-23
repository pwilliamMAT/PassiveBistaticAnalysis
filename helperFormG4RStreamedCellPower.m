function [cellPower, diagnostics] = helperFormG4RStreamedCellPower( ...
    signalPair, commonDelayAxis_s, commonDopplerAxis_Hz, options)
%HELPERFORMG4RSTREAMEDCELLPOWER Form common-cell power from AMBGFUN cuts.
%
%   CELLPOWER = HELPERFORMG4RSTREAMEDCELLPOWER(SIGNALPAIR,
%   COMMONDELAYAXIS_S, COMMONDOPPLERAXIS_HZ) evaluates AMBGFUN Doppler
%   cuts and aggregates squared magnitude into the requested physical
%   cells. SIGNALPAIR contains ReferenceSignal, SurveillanceSignal,
%   SampleRateHz, and PrfVector_Hz.
%
%   The AMBGFUN cut convention is corrected by requesting the negative of
%   each physical Doppler coordinate and reversing each returned delay
%   row. OPTIONS.DopplerSamplesPerCell selects midpoint quadrature within
%   each common Doppler cell. OPTIONS.DopplerSampleAxis_Hz instead supplies
%   an explicit physical axis, which is useful for full-map oracle checks.

arguments
    signalPair (1,1) struct
    commonDelayAxis_s {mustBeNumeric, mustBeVector}
    commonDopplerAxis_Hz {mustBeNumeric, mustBeVector}
    options.DopplerSamplesPerCell (1,1) double = 1.0
    options.DopplerSampleAxis_Hz {mustBeNumeric, mustBeVector} = ...
        zeros(0, 1)
    options.CutBatchSize (1,1) double = 16.0
    options.PowerSemantics (1,1) string = "legacy_double"
end

[referenceSignal, surveillanceSignal, sampleRateHz, prfVector_Hz] = ...
    localValidateSignalPair(signalPair);
commonDelayAxis_s = double(commonDelayAxis_s(:).');
commonDopplerAxis_Hz = double(commonDopplerAxis_Hz(:));
localValidateAxis(commonDelayAxis_s, "commonDelayAxis_s");
localValidateAxis(commonDopplerAxis_Hz, "commonDopplerAxis_Hz");

samplesPerCell = round(options.DopplerSamplesPerCell);
batchSize = round(options.CutBatchSize);
powerSemantics = lower(options.PowerSemantics);

if samplesPerCell < 1 || samplesPerCell ~= options.DopplerSamplesPerCell
    error("helperFormG4RStreamedCellPower:InvalidSamplesPerCell", ...
        "DopplerSamplesPerCell must be a positive integer.");
end

if batchSize < 1 || batchSize ~= options.CutBatchSize
    error("helperFormG4RStreamedCellPower:InvalidBatchSize", ...
        "CutBatchSize must be a positive integer.");
end

if ~ismember(powerSemantics, ["legacy_double", "production_g4"])
    error("helperFormG4RStreamedCellPower:InvalidPowerSemantics", ...
        "PowerSemantics must be legacy_double or production_g4.");
end

dopplerEdges_Hz = localBuildEdges(commonDopplerAxis_Hz);
explicitDopplerAxis_Hz = double(options.DopplerSampleAxis_Hz(:));

if isempty(explicitDopplerAxis_Hz)
    dopplerSampleAxis_Hz = localBuildMidpointSamples( ...
        dopplerEdges_Hz, samplesPerCell);
    samplingMode = "midpoint_quadrature";
else
    localValidateAxis(explicitDopplerAxis_Hz, ...
        "options.DopplerSampleAxis_Hz");

    if explicitDopplerAxis_Hz(1) < dopplerEdges_Hz(1) || ...
            explicitDopplerAxis_Hz(end) > dopplerEdges_Hz(end)
        error("helperFormG4RStreamedCellPower:DopplerSamplesOutsideSupport", ...
            "DopplerSampleAxis_Hz must lie within the common-cell edges.");
    end

    dopplerSampleAxis_Hz = explicitDopplerAxis_Hz;
    samplingMode = "explicit_physical_axis";
end

outputSize = [numel(commonDopplerAxis_Hz), ...
    numel(commonDelayAxis_s)];
cellPowerSum = zeros(outputSize);
cellCounts = zeros(outputSize);
returnedDelayAxis_s = zeros(0, 1);

for batchStart = 1:batchSize:numel(dopplerSampleAxis_Hz)
    batchIndices = batchStart:min( ...
        batchStart + batchSize - 1, numel(dopplerSampleAxis_Hz));
    physicalDoppler_Hz = dopplerSampleAxis_Hz(batchIndices);
    [magnitudeCuts, returnedDelayAxis_s] = ambgfun( ...
        referenceSignal, surveillanceSignal, sampleRateHz, prfVector_Hz, ...
        Cut="Doppler", CutValue=-physicalDoppler_Hz);
    correctedMagnitude = flip(magnitudeCuts, 2);

    if powerSemantics == "production_g4"
        correctedPower = max( ...
            single(correctedMagnitude) .^ 2, eps("single"));
    else
        correctedPower = double(correctedMagnitude) .^ 2;
    end
    [~, batchCounts, batchPowerSum] = helperAggregateG4RMapPower( ...
        correctedPower, returnedDelayAxis_s, physicalDoppler_Hz, ...
        commonDelayAxis_s, commonDopplerAxis_Hz, ...
        RequirePopulatedCells=false);
    cellPowerSum = cellPowerSum + batchPowerSum;
    cellCounts = cellCounts + batchCounts;
end

if any(cellCounts == 0.0, "all")
    error("helperFormG4RStreamedCellPower:UnpopulatedCell", ...
        "Every common physical cell must receive a streamed map sample.");
end

cellPower = cellPowerSum ./ cellCounts;
dopplerGroups = discretize(dopplerSampleAxis_Hz, dopplerEdges_Hz);
dopplerCounts = accumarray(dopplerGroups, 1.0, ...
    [numel(commonDopplerAxis_Hz), 1], @sum, 0.0);
delayEdges_s = localBuildEdges(commonDelayAxis_s);
retainedDelayCount = nnz(returnedDelayAxis_s >= delayEdges_s(1) & ...
    returnedDelayAxis_s <= delayEdges_s(end));
diagnostics = localBuildDiagnostics(referenceSignal, ...
    dopplerSampleAxis_Hz, dopplerCounts, retainedDelayCount, ...
    batchSize, samplesPerCell, samplingMode, powerSemantics);

end

function [referenceSignal, surveillanceSignal, sampleRateHz, ...
    prfVector_Hz] = localValidateSignalPair(signalPair)

requiredFields = [ ...
    "ReferenceSignal"; ...
    "SurveillanceSignal"; ...
    "SampleRateHz"; ...
    "PrfVector_Hz" ...
    ];

for fieldIndex = 1:numel(requiredFields)
    if ~isfield(signalPair, requiredFields(fieldIndex))
        error("helperFormG4RStreamedCellPower:MissingSignalField", ...
            "signalPair is missing %s.", requiredFields(fieldIndex));
    end
end

referenceSignal = signalPair.ReferenceSignal(:);
surveillanceSignal = signalPair.SurveillanceSignal(:);
sampleRateHz = double(signalPair.SampleRateHz);
prfVector_Hz = double(signalPair.PrfVector_Hz(:).');

if isempty(referenceSignal) || ...
        numel(referenceSignal) ~= numel(surveillanceSignal)
    error("helperFormG4RStreamedCellPower:InvalidSignalPair", ...
        "ReferenceSignal and SurveillanceSignal must be nonempty and equal length.");
end

if any(~isfinite(referenceSignal), "all") || ...
        any(~isfinite(surveillanceSignal), "all")
    error("helperFormG4RStreamedCellPower:NonfiniteSignalPair", ...
        "ReferenceSignal and SurveillanceSignal must be finite.");
end

if ~isscalar(sampleRateHz) || ~isfinite(sampleRateHz) || ...
        sampleRateHz <= 0.0
    error("helperFormG4RStreamedCellPower:InvalidSampleRate", ...
        "SampleRateHz must be a positive finite scalar.");
end

if isempty(prfVector_Hz) || any(~isfinite(prfVector_Hz)) || ...
        any(prfVector_Hz <= 0.0)
    error("helperFormG4RStreamedCellPower:InvalidPrf", ...
        "PrfVector_Hz must contain positive finite values.");
end

end

function localValidateAxis(axisValues, axisName)

if numel(axisValues) < 2 || any(~isfinite(axisValues)) || ...
        any(diff(axisValues) <= 0.0)
    error("helperFormG4RStreamedCellPower:InvalidAxis", ...
        "%s must be finite and strictly increasing.", axisName);
end

end

function edges = localBuildEdges(axisValues)

axisValues = double(axisValues(:));
edges = [ ...
    axisValues(1) - (axisValues(2) - axisValues(1)) ./ 2.0; ...
    (axisValues(1:end - 1) + axisValues(2:end)) ./ 2.0; ...
    axisValues(end) + ...
    (axisValues(end) - axisValues(end - 1)) ./ 2.0 ...
    ];

end

function sampleAxis_Hz = localBuildMidpointSamples( ...
    dopplerEdges_Hz, samplesPerCell)

cellLowerEdges_Hz = dopplerEdges_Hz(1:end - 1);
cellWidths_Hz = diff(dopplerEdges_Hz);
fractions = ((1:samplesPerCell) - 0.5) ./ samplesPerCell;
sampleGrid_Hz = cellLowerEdges_Hz + cellWidths_Hz .* fractions;
sampleAxis_Hz = reshape(sampleGrid_Hz.', [], 1);

end

function diagnostics = localBuildDiagnostics(referenceSignal, ...
    dopplerSampleAxis_Hz, dopplerCounts, retainedDelayCount, ...
    batchSize, samplesPerCell, samplingMode, powerSemantics)

if isa(referenceSignal, "single")
    bytesPerReal = 4.0;
else
    bytesPerReal = 8.0;
end

diagnostics = struct();
diagnostics.InputSampleCount = double(numel(referenceSignal));
diagnostics.DopplerCutCount = double(numel(dopplerSampleAxis_Hz));
diagnostics.RetainedDelaySampleCount = double(retainedDelayCount);
diagnostics.CutBatchSize = double(batchSize);
diagnostics.EstimatedLargestCutBatchBytes = double(batchSize) .* ...
    double(2 .* numel(referenceSignal) - 1) .* bytesPerReal;
diagnostics.RequestedDopplerSamplesPerCell = double(samplesPerCell);
diagnostics.MinimumDopplerSamplesPerCell = min(dopplerCounts);
diagnostics.MaximumDopplerSamplesPerCell = max(dopplerCounts);
diagnostics.DopplerSamplingMode = samplingMode;
diagnostics.PowerSemantics = powerSemantics;
diagnostics.AggregationImplementation = ...
    "helperAggregateG4RMapPower";

end
