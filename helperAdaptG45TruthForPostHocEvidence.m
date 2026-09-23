function canonicalTruth = helperAdaptG45TruthForPostHocEvidence( ...
    truthSource, sourceCaseId)
%HELPERADAPTG45TRUTHFORPOSTHOCEVIDENCE Convert G4.5 JSON truth.
%
%   CANONICALTRUTH = HELPERADAPTG45TRUTHFORPOSTHOCEVIDENCE(TRUTHSOURCE)
%   converts a decoded G4.5 truth struct or a truth JSON path into the
%   canonical post-hoc truth structure consumed by
%   helperAnalyzeSyntheticTargetEvidence. The adapter does not form maps.

arguments
    truthSource
    sourceCaseId (1,1) string = ""
end

[truth, truthPath] = localReadTruthSource(truthSource);

if strlength(sourceCaseId) == 0
    sourceCaseId = localStringField(truth, "dataset_id", "");
end

if strlength(sourceCaseId) == 0
    error("helperAdaptG45TruthForPostHocEvidence:MissingCaseId", ...
        "The truth source must identify its dataset or source case.");
end

injectionEnabled = localLogicalField(truth, ...
    "injection_enabled", false);
declaredTargetCount = localDoubleField(truth, ...
    "number_of_targets", 0.0);
radarEpochUtc = localDoubleField(truth, "radar_epoch_utc", NaN);
targetInput = localResolveTargetArray(truth);

if injectionEnabled && isempty(targetInput)
    error("helperAdaptG45TruthForPostHocEvidence:MissingTargets", ...
        "Injection-enabled case %s has no target truth.", sourceCaseId);
end

if ~isempty(targetInput) && ~isfinite(radarEpochUtc)
    error("helperAdaptG45TruthForPostHocEvidence:MissingRadarEpoch", ...
        "Target-bearing case %s has no finite radar_epoch_utc.", ...
        sourceCaseId);
end

tracks = repmat(localTrackTemplate(), numel(targetInput), 1);
metadataRows = repmat(localMetadataTemplate(), numel(targetInput), 1);

for targetIndex = 1:numel(targetInput)
    target = targetInput(targetIndex);
    truthTimes_s = localNestedNumericVector(target, ...
        ["cpi_or_time_windows_used", "truth_time_s"]);
    expectedDelay_s = localNumericVector(target, "expected_delay_s");
    expectedDoppler_Hz = localNumericVector(target, ...
        "expected_bistatic_doppler_hz");
    validCount = min([numel(truthTimes_s), numel(expectedDelay_s), ...
        numel(expectedDoppler_Hz)]);

    if validCount < 1
        error("helperAdaptG45TruthForPostHocEvidence:IncompleteTrack", ...
            "Target %d in %s has incomplete time/delay/Doppler truth.", ...
            targetIndex, sourceCaseId);
    end

    targetId = localStringField(target, "target_id", ...
        "target_" + string(targetIndex));
    callsign = localStringField(target, "callsign", "");
    injectionGain_dB = localNestedDouble(target, ...
        ["echo_strength_parameters", "echo_gain_db"], NaN);
    targetPowerRelativeToBackground_dB = localDoubleField(target, ...
        "target_power_relative_to_background_db", NaN);
    tracks(targetIndex) = struct( ...
        "hex", targetId, ...
        "callsign", callsign, ...
        "t_utc", radarEpochUtc + truthTimes_s(1:validCount), ...
        "R_excess_m", expectedDelay_s(1:validCount) .* ...
        physconst("LightSpeed"), ...
        "f_D_hz", expectedDoppler_Hz(1:validCount), ...
        "source_case_id", sourceCaseId, ...
        "injection_gain_db", injectionGain_dB, ...
        "target_power_relative_to_background_db", ...
        targetPowerRelativeToBackground_dB);
    metadataRows(targetIndex) = struct( ...
        "SourceCaseId", sourceCaseId, ...
        "TargetId", targetId, ...
        "Callsign", callsign, ...
        "InjectionGain_dB", injectionGain_dB, ...
        "TargetPowerRelativeToBackground_dB", ...
        targetPowerRelativeToBackground_dB, ...
        "TruthPointCount", double(validCount));
end

if declaredTargetCount ~= numel(targetInput)
    error("helperAdaptG45TruthForPostHocEvidence:TargetCountMismatch", ...
        "Case %s declares %d targets but supplies %d.", sourceCaseId, ...
        declaredTargetCount, numel(targetInput));
end

truthBundle = struct();
truthBundle.radar_epoch_utc = radarEpochUtc;
truthBundle.bistatic_tracks = tracks;

canonicalTruth = struct();
canonicalTruth.SchemaVersion = "g45_post_hoc_truth_v1";
canonicalTruth.SourceCaseId = sourceCaseId;
canonicalTruth.SourceTruthPath = truthPath;
canonicalTruth.InjectionEnabled = injectionEnabled;
canonicalTruth.DeclaredTargetCount = declaredTargetCount;
canonicalTruth.part_start_offsets_s = 0.0;
canonicalTruth.truth_bundle = truthBundle;
canonicalTruth.TargetMetadataTable = struct2table(metadataRows);

end

function [truth, truthPath] = localReadTruthSource(truthSource)

truthPath = "";

if isstruct(truthSource) && isscalar(truthSource)
    truth = truthSource;
    return
end

if (isstring(truthSource) || ischar(truthSource)) && ...
        isscalar(string(truthSource))
    truthPath = string(truthSource);

    if ~isfile(truthPath)
        error("helperAdaptG45TruthForPostHocEvidence:MissingTruthFile", ...
            "Truth JSON file not found: %s", truthPath);
    end

    try
        truth = jsondecode(fileread(truthPath));
    catch readException
        error("helperAdaptG45TruthForPostHocEvidence:ReadTruthFailed", ...
            "Failed to read %s: %s", truthPath, readException.message);
    end

    return
end

error("helperAdaptG45TruthForPostHocEvidence:InvalidTruthSource", ...
    "Truth source must be a scalar struct or JSON path.");

end

function targets = localResolveTargetArray(truth)

targets = repmat(localTargetInputTemplate(), 0, 1);

if ~isfield(truth, "targets") || isempty(truth.targets)
    return
end

if ~isstruct(truth.targets)
    error("helperAdaptG45TruthForPostHocEvidence:InvalidTargets", ...
        "The targets field must contain a struct or struct array.");
end

targets = truth.targets(:);

end

function track = localTrackTemplate()

track = struct( ...
    "hex", "", ...
    "callsign", "", ...
    "t_utc", zeros(0, 1), ...
    "R_excess_m", zeros(0, 1), ...
    "f_D_hz", zeros(0, 1), ...
    "source_case_id", "", ...
    "injection_gain_db", NaN, ...
    "target_power_relative_to_background_db", NaN);

end

function target = localTargetInputTemplate()

target = struct();

end

function row = localMetadataTemplate()

row = struct( ...
    "SourceCaseId", "", ...
    "TargetId", "", ...
    "Callsign", "", ...
    "InjectionGain_dB", NaN, ...
    "TargetPowerRelativeToBackground_dB", NaN, ...
    "TruthPointCount", NaN);

end

function value = localStringField(inputStruct, fieldName, defaultValue)

value = string(defaultValue);

if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = string(inputStruct.(fieldName));
end

end

function value = localDoubleField(inputStruct, fieldName, defaultValue)

value = double(defaultValue);

if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = double(inputStruct.(fieldName));
end

end

function value = localLogicalField(inputStruct, fieldName, defaultValue)

value = logical(defaultValue);

if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = logical(inputStruct.(fieldName));
end

end

function values = localNumericVector(inputStruct, fieldName)

values = zeros(0, 1);

if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    values = double(inputStruct.(fieldName)(:));
end

end

function values = localNestedNumericVector(inputStruct, fieldPath)

values = zeros(0, 1);
candidate = inputStruct;

for fieldIndex = 1:numel(fieldPath)
    fieldName = fieldPath(fieldIndex);

    if ~isstruct(candidate) || ~isfield(candidate, fieldName)
        return
    end

    candidate = candidate.(fieldName);
end

if ~isempty(candidate)
    values = double(candidate(:));
end

end

function value = localNestedDouble(inputStruct, fieldPath, defaultValue)

value = double(defaultValue);
candidate = inputStruct;

for fieldIndex = 1:numel(fieldPath)
    fieldName = fieldPath(fieldIndex);

    if ~isstruct(candidate) || ~isfield(candidate, fieldName)
        return
    end

    candidate = candidate.(fieldName);
end

if ~isempty(candidate)
    value = double(candidate);
end

end
