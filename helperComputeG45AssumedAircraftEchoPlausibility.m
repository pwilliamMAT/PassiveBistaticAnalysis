function plausibilityTable = helperComputeG45AssumedAircraftEchoPlausibility( ...
    txLla_deg_m, rxLla_deg_m, centerFrequency_Hz, ...
    expectedBistaticExcessRange_m, options)
%HELPERCOMPUTEG45ASSUMEDAIRCRAFTECHOPLAUSIBILITY Forward-model echo plausibility.
%
%   PLAUSIBILITYTABLE = HELPERCOMPUTEG45ASSUMEDAIRCRAFTECHOPLAUSIBILITY(
%   TXLLA_DEG_M, RXLLA_DEG_M, CENTERFREQUENCY_HZ,
%   EXPECTEDBISTATICEXCESSRANGE_M, OPTIONS) estimates assumed-aircraft
%   echo-to-direct ratios for selected bistatic-RCS assumptions. This is a
%   forward-model sensitivity check, not calibrated or inferred RCS.

arguments
    txLla_deg_m double = zeros(0, 3)
    rxLla_deg_m double = zeros(0, 3)
    centerFrequency_Hz double = zeros(0, 1)
    expectedBistaticExcessRange_m double = zeros(0, 1)
    options (1,1) struct = struct()
end

resolvedOptions = localResolveOptions(options);

if isempty(expectedBistaticExcessRange_m)
    plausibilityTable = localEmptyPlausibilityTable();
    return
end

rowCount = localResolveRowCount(txLla_deg_m, rxLla_deg_m, ...
    centerFrequency_Hz, expectedBistaticExcessRange_m);
txLla_deg_m = localNormalizeLla(txLla_deg_m, rowCount, ...
    "txLla_deg_m");
rxLla_deg_m = localNormalizeLla(rxLla_deg_m, rowCount, ...
    "rxLla_deg_m");
centerFrequency_Hz = localExpandNumericColumn(centerFrequency_Hz, ...
    rowCount, "centerFrequency_Hz");
expectedBistaticExcessRange_m = localExpandNumericColumn( ...
    expectedBistaticExcessRange_m, rowCount, ...
    "expectedBistaticExcessRange_m");
caseDatasetId = localExpandStringColumn(resolvedOptions.CaseDatasetId, ...
    rowCount, "");
targetId = localExpandStringColumn(resolvedOptions.TargetId, rowCount, "");
adsbSourceId = localExpandStringColumn(resolvedOptions.AdsbSourceId, ...
    rowCount, "");
callsign = localExpandStringColumn(resolvedOptions.Callsign, rowCount, "");
syntheticTargetPowerRelativeToBackground_dB = localExpandNumericColumn( ...
    resolvedOptions.SyntheticTargetPowerRelativeToBackground_dB, ...
    rowCount, "SyntheticTargetPowerRelativeToBackground_dB");

c_mps = physconst("LightSpeed");
wavelength_m = c_mps ./ centerFrequency_Hz;
earthModel = wgs84Ellipsoid("meter");
[txX_m, txY_m, txZ_m] = geodetic2ecef(earthModel, ...
    txLla_deg_m(:, 1), txLla_deg_m(:, 2), txLla_deg_m(:, 3));
[rxX_m, rxY_m, rxZ_m] = geodetic2ecef(earthModel, ...
    rxLla_deg_m(:, 1), rxLla_deg_m(:, 2), rxLla_deg_m(:, 3));
txEcef_m = [txX_m, txY_m, txZ_m];
rxEcef_m = [rxX_m, rxY_m, rxZ_m];
txRxRange_m = vecnorm(rxEcef_m - txEcef_m, 2, 2);
assumedTxTargetRange_m = (txRxRange_m + ...
    expectedBistaticExcessRange_m) ./ 2.0;
assumedTargetRxRange_m = assumedTxTargetRange_m;
cosBistaticAngle = (assumedTxTargetRange_m.^2 + ...
    assumedTargetRxRange_m.^2 - txRxRange_m.^2) ./ ...
    (2.0 .* assumedTxTargetRange_m .* assumedTargetRxRange_m);
cosBistaticAngle = max(min(cosBistaticAngle, 1.0), -1.0);
notionalBistaticAngle_deg = acosd(cosBistaticAngle);

scenarioCount = numel(resolvedOptions.SigmaB_m2);
caseDatasetId = repelem(caseDatasetId, scenarioCount, 1);
targetId = repelem(targetId, scenarioCount, 1);
adsbSourceId = repelem(adsbSourceId, scenarioCount, 1);
callsign = repelem(callsign, scenarioCount, 1);
assumptionLabel = repmat(resolvedOptions.AssumptionLabels, rowCount, 1);
centerFrequency_Hz = repelem(centerFrequency_Hz, scenarioCount, 1);
wavelength_m = repelem(wavelength_m, scenarioCount, 1);
txRxRange_m = repelem(txRxRange_m, scenarioCount, 1);
expectedBistaticExcessRange_m = repelem( ...
    expectedBistaticExcessRange_m, scenarioCount, 1);
assumedTxTargetRange_m = repelem(assumedTxTargetRange_m, scenarioCount, 1);
assumedTargetRxRange_m = repelem(assumedTargetRxRange_m, scenarioCount, 1);
notionalBistaticAngle_deg = repelem(notionalBistaticAngle_deg, ...
    scenarioCount, 1);
assumedSigmaB_m2 = repmat(resolvedOptions.SigmaB_m2, rowCount, 1);
txAntennaGainRatio_dB = repmat(resolvedOptions.TxAntennaGainRatio_dB, ...
    rowCount .* scenarioCount, 1);
rxAntennaGainRatio_dB = repmat(resolvedOptions.RxAntennaGainRatio_dB, ...
    rowCount .* scenarioCount, 1);
combinedLossFactor_dB = repmat(resolvedOptions.CombinedLossFactor_dB, ...
    rowCount .* scenarioCount, 1);
syntheticTargetPowerRelativeToBackground_dB = repelem( ...
    syntheticTargetPowerRelativeToBackground_dB, scenarioCount, 1);

linearGainLossRatio = db2pow(txAntennaGainRatio_dB + ...
    rxAntennaGainRatio_dB + combinedLossFactor_dB);
echoToDirectRatio = linearGainLossRatio .* assumedSigmaB_m2 .* ...
    txRxRange_m.^2 ./ (4.0 .* pi .* assumedTxTargetRange_m.^2 .* ...
    assumedTargetRxRange_m.^2);
echoToDirectRatio_dB = pow2db(max(echoToDirectRatio, realmin));
echoDirectVsSyntheticBackgroundOffset_dB = echoToDirectRatio_dB - ...
    syntheticTargetPowerRelativeToBackground_dB;
perLegAssumption = repmat("symmetric_target_legs", ...
    rowCount .* scenarioCount, 1);
comparisonBasis = repmat( ...
    "diagnostic only: echo/direct ratio and synthetic target/background level use different denominators", ...
    rowCount .* scenarioCount, 1);
forwardQuestion = repmat( ...
    "Would a conservative assumed medium-aircraft echo be near the synthetic injected levels or likely buried under current map/background limits?", ...
    rowCount .* scenarioCount, 1);
caveat = repmat( ...
    "Forward-model sensitivity check only; not calibrated RCS, not inferred bistatic RCS, and not a measured aircraft-type estimate.", ...
    rowCount .* scenarioCount, 1);

plausibilityTable = table( ...
    caseDatasetId, targetId, adsbSourceId, callsign, assumptionLabel, ...
    centerFrequency_Hz, wavelength_m, txRxRange_m, ...
    expectedBistaticExcessRange_m, assumedTxTargetRange_m, ...
    assumedTargetRxRange_m, notionalBistaticAngle_deg, ...
    assumedSigmaB_m2, txAntennaGainRatio_dB, rxAntennaGainRatio_dB, ...
    combinedLossFactor_dB, echoToDirectRatio, echoToDirectRatio_dB, ...
    syntheticTargetPowerRelativeToBackground_dB, ...
    echoDirectVsSyntheticBackgroundOffset_dB, perLegAssumption, ...
    comparisonBasis, forwardQuestion, caveat, ...
    VariableNames = localPlausibilityVariableNames());

end

function resolvedOptions = localResolveOptions(options)

resolvedOptions = struct();
resolvedOptions.SigmaB_m2 = [1.0; 10.0; 100.0];
resolvedOptions.AssumptionLabels = [
    "low_conservative"
    "nominal_medium_transport"
    "favorable_aspect"
    ];
resolvedOptions.TxAntennaGainRatio_dB = 0.0;
resolvedOptions.RxAntennaGainRatio_dB = 0.0;
resolvedOptions.CombinedLossFactor_dB = -6.0;
resolvedOptions.CaseDatasetId = "";
resolvedOptions.TargetId = "";
resolvedOptions.AdsbSourceId = "";
resolvedOptions.Callsign = "";
resolvedOptions.SyntheticTargetPowerRelativeToBackground_dB = NaN;

if isfield(options, "SigmaB_m2")
    resolvedOptions.SigmaB_m2 = double(options.SigmaB_m2(:));
elseif isfield(options, "sigma_b_m2")
    resolvedOptions.SigmaB_m2 = double(options.sigma_b_m2(:));
end

if isfield(options, "AssumptionLabels")
    resolvedOptions.AssumptionLabels = string(options.AssumptionLabels(:));
elseif isfield(options, "Labels")
    resolvedOptions.AssumptionLabels = string(options.Labels(:));
end

if isfield(options, "AntennaGainRatio_dB")
    resolvedOptions.TxAntennaGainRatio_dB = ...
        double(options.AntennaGainRatio_dB);
    resolvedOptions.RxAntennaGainRatio_dB = ...
        double(options.AntennaGainRatio_dB);
end

if isfield(options, "TxAntennaGainRatio_dB")
    resolvedOptions.TxAntennaGainRatio_dB = ...
        double(options.TxAntennaGainRatio_dB);
end

if isfield(options, "RxAntennaGainRatio_dB")
    resolvedOptions.RxAntennaGainRatio_dB = ...
        double(options.RxAntennaGainRatio_dB);
end

if isfield(options, "CombinedLossFactor_dB")
    resolvedOptions.CombinedLossFactor_dB = ...
        double(options.CombinedLossFactor_dB);
elseif isfield(options, "CombinedPolarizationPropagationLoss_dB")
    resolvedOptions.CombinedLossFactor_dB = ...
        double(options.CombinedPolarizationPropagationLoss_dB);
end

if isfield(options, "CaseDatasetId")
    resolvedOptions.CaseDatasetId = string(options.CaseDatasetId(:));
end

if isfield(options, "TargetId")
    resolvedOptions.TargetId = string(options.TargetId(:));
end

if isfield(options, "AdsbSourceId")
    resolvedOptions.AdsbSourceId = string(options.AdsbSourceId(:));
end

if isfield(options, "Callsign")
    resolvedOptions.Callsign = string(options.Callsign(:));
end

if isfield(options, "SyntheticTargetPowerRelativeToBackground_dB")
    resolvedOptions.SyntheticTargetPowerRelativeToBackground_dB = ...
        double(options.SyntheticTargetPowerRelativeToBackground_dB(:));
end

localValidateOptions(resolvedOptions);

end

function localValidateOptions(resolvedOptions)

if isempty(resolvedOptions.SigmaB_m2) || ...
        any(~isfinite(resolvedOptions.SigmaB_m2)) || ...
        any(resolvedOptions.SigmaB_m2 <= 0.0)
    error("helperComputeG45AssumedAircraftEchoPlausibility:InvalidRcs", ...
        "Assumed SigmaB_m2 values must be finite positive values.");
end

if numel(resolvedOptions.AssumptionLabels) ~= ...
        numel(resolvedOptions.SigmaB_m2)
    error("helperComputeG45AssumedAircraftEchoPlausibility:LabelMismatch", ...
        "AssumptionLabels must have the same length as SigmaB_m2.");
end

if ~isscalar(resolvedOptions.TxAntennaGainRatio_dB) || ...
        ~isfinite(resolvedOptions.TxAntennaGainRatio_dB)
    error("helperComputeG45AssumedAircraftEchoPlausibility:InvalidGain", ...
        "TxAntennaGainRatio_dB must be a finite scalar.");
end

if ~isscalar(resolvedOptions.RxAntennaGainRatio_dB) || ...
        ~isfinite(resolvedOptions.RxAntennaGainRatio_dB)
    error("helperComputeG45AssumedAircraftEchoPlausibility:InvalidGain", ...
        "RxAntennaGainRatio_dB must be a finite scalar.");
end

if ~isscalar(resolvedOptions.CombinedLossFactor_dB) || ...
        ~isfinite(resolvedOptions.CombinedLossFactor_dB)
    error("helperComputeG45AssumedAircraftEchoPlausibility:InvalidLoss", ...
        "CombinedLossFactor_dB must be a finite scalar.");
end

end

function rowCount = localResolveRowCount(txLla_deg_m, rxLla_deg_m, ...
    centerFrequency_Hz, expectedBistaticExcessRange_m)

rowCounts = [
    localLlaRowCount(txLla_deg_m, "txLla_deg_m")
    localLlaRowCount(rxLla_deg_m, "rxLla_deg_m")
    numel(centerFrequency_Hz)
    numel(expectedBistaticExcessRange_m)
    ];
rowCounts = rowCounts(rowCounts > 0);

if isempty(rowCounts)
    rowCount = 0;
    return
end

rowCount = max(rowCounts);
validMask = rowCounts == 1 | rowCounts == rowCount;

if ~all(validMask)
    error("helperComputeG45AssumedAircraftEchoPlausibility:RowMismatch", ...
        "Inputs must be scalar rows or have the same number of rows.");
end

end

function rowCount = localLlaRowCount(lla_deg_m, variableName)

if isempty(lla_deg_m)
    rowCount = 0;
    return
end

lla_deg_m = double(lla_deg_m);

if isvector(lla_deg_m)
    if numel(lla_deg_m) ~= 3
        error("helperComputeG45AssumedAircraftEchoPlausibility:InvalidLla", ...
            "%s must contain latitude, longitude, and height.", ...
            variableName);
    end

    rowCount = 1;
    return
end

if size(lla_deg_m, 2) == 3
    rowCount = size(lla_deg_m, 1);
elseif size(lla_deg_m, 1) == 3
    rowCount = size(lla_deg_m, 2);
else
    error("helperComputeG45AssumedAircraftEchoPlausibility:InvalidLla", ...
        "%s must be an N-by-3 latitude, longitude, height array.", ...
        variableName);
end

end

function lla_deg_m = localNormalizeLla(lla_deg_m, rowCount, variableName)

if isempty(lla_deg_m)
    error("helperComputeG45AssumedAircraftEchoPlausibility:MissingLla", ...
        "%s is required when expected bistatic excess range is provided.", ...
        variableName);
end

lla_deg_m = double(lla_deg_m);

if isvector(lla_deg_m)
    lla_deg_m = reshape(lla_deg_m, 1, []);
elseif size(lla_deg_m, 1) == 3 && size(lla_deg_m, 2) ~= 3
    lla_deg_m = lla_deg_m.';
end

if size(lla_deg_m, 2) ~= 3
    error("helperComputeG45AssumedAircraftEchoPlausibility:InvalidLla", ...
        "%s must be an N-by-3 latitude, longitude, height array.", ...
        variableName);
end

if size(lla_deg_m, 1) == 1 && rowCount > 1
    lla_deg_m = repmat(lla_deg_m, rowCount, 1);
end

if size(lla_deg_m, 1) ~= rowCount
    error("helperComputeG45AssumedAircraftEchoPlausibility:RowMismatch", ...
        "%s has an incompatible row count.", variableName);
end

end

function values = localExpandNumericColumn(values, rowCount, variableName)

if isempty(values)
    error("helperComputeG45AssumedAircraftEchoPlausibility:MissingValue", ...
        "%s is required.", variableName);
end

values = double(values(:));

if isscalar(values) && rowCount > 1
    values = repmat(values, rowCount, 1);
end

if numel(values) ~= rowCount
    error("helperComputeG45AssumedAircraftEchoPlausibility:RowMismatch", ...
        "%s has an incompatible row count.", variableName);
end

end

function values = localExpandStringColumn(values, rowCount, defaultValue)

values = string(values(:));

if isempty(values)
    values = repmat(string(defaultValue), rowCount, 1);
elseif isscalar(values) && rowCount > 1
    values = repmat(values, rowCount, 1);
end

if numel(values) ~= rowCount
    error("helperComputeG45AssumedAircraftEchoPlausibility:RowMismatch", ...
        "String metadata has an incompatible row count.");
end

end

function plausibilityTable = localEmptyPlausibilityTable()

plausibilityTable = table(Size = [0, 24], VariableTypes = [
    "string", "string", "string", "string", "string", "double", ...
    "double", "double", "double", "double", "double", "double", ...
    "double", "double", "double", "double", "double", "double", ...
    "double", "double", "string", "string", "string", "string"], ...
    VariableNames = localPlausibilityVariableNames());

end

function variableNames = localPlausibilityVariableNames()

variableNames = {'CaseDatasetId', 'TargetId', 'AdsbSourceId', ...
    'Callsign', 'AssumptionLabel', 'CenterFrequency_Hz', ...
    'Wavelength_m', 'TxRxRange_m', 'ExpectedBistaticExcessRange_m', ...
    'AssumedTxTargetRange_m', 'AssumedTargetRxRange_m', ...
    'NotionalBistaticAngle_deg', 'AssumedSigmaB_m2', ...
    'TxAntennaGainRatio_dB', 'RxAntennaGainRatio_dB', ...
    'CombinedLossFactor_dB', 'EchoToDirectRatio', ...
    'EchoToDirectRatio_dB', ...
    'SyntheticTargetPowerRelativeToBackground_dB', ...
    'EchoDirectVsSyntheticBackgroundOffset_dB', 'PerLegAssumption', ...
    'ComparisonBasis', 'ForwardQuestion', 'Caveat'};

end