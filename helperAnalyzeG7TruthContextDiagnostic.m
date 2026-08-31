function analysis = helperAnalyzeG7TruthContextDiagnostic(datasetId, repoRoot, options)
%HELPERANALYZEG7TRUTHCONTEXTDIAGNOSTIC Build capture-level truth context.

arguments
    datasetId (1,1) string = "20260622T102123"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

datasetId = string(datasetId);
repoRoot = helperResolveRepoRoot(repoRoot);
resolvedOptions = localResolveOptions(options);
sourceG6 = localResolveG6Source(datasetId, repoRoot, resolvedOptions);
manifestPath = localResolveManifestPath(datasetId, repoRoot, resolvedOptions);
radarMetadataPath = localResolveRadarMetadataPath(datasetId, repoRoot, resolvedOptions);
truthPath = localResolveTruthPath(datasetId, repoRoot, manifestPath, resolvedOptions);
manifest = localReadJsonFile(manifestPath);
radarMetadataTable = localReadRadarMetadataTable(radarMetadataPath);
truthTable = localReadTruthTable(truthPath);
radarTimingAuditTable = localBuildRadarTimingAuditTable(manifest, radarMetadataTable);
truthImportSummaryTable = localBuildTruthImportSummaryTable(truthPath, truthTable);
captureTruthOverlapTable = localBuildCaptureTruthOverlapTable(radarTimingAuditTable, truthTable);
timingResidualSummaryTable = localBuildTimingResidualSummaryTable(manifest, radarTimingAuditTable);
[claimGateTable, gateDecision, reviewStatus, truthClaimsEnabled, claimBlockReason, nextBranch] = localBuildClaimGateTable(sourceG6, truthImportSummaryTable, captureTruthOverlapTable);
validationWindowTable = localBuildValidationWindowTable(captureTruthOverlapTable, truthClaimsEnabled, claimBlockReason);
requirementsCoverageTable = localBuildRequirementsCoverageTable(truthClaimsEnabled, claimBlockReason);
publicContractChangeTable = localBuildPublicContractChangeTable();

analysis = struct();
analysis.DatasetId = datasetId;
analysis.StageId = "G7_Truth_Context_Diagnostic";
analysis.GateId = "G7_Truth_Alignment";
analysis.Mode = "truth_context_diagnostic";
analysis.GateDecision = gateDecision;
analysis.ReviewStatus = reviewStatus;
analysis.TruthClaimsEnabled = truthClaimsEnabled;
analysis.ClaimBlockReason = claimBlockReason;
analysis.NextBranch = nextBranch;
analysis.ManifestPath = string(manifestPath);
analysis.RadarMetadataPath = string(radarMetadataPath);
analysis.TruthPath = string(truthPath);
analysis.SourceG6 = sourceG6;
analysis.TruthImportSummaryTable = truthImportSummaryTable;
analysis.RadarTimingAuditTable = radarTimingAuditTable;
analysis.CaptureTruthOverlapTable = captureTruthOverlapTable;
analysis.TimingResidualSummaryTable = timingResidualSummaryTable;
analysis.ClaimGateTable = claimGateTable;
analysis.ValidationWindowTable = validationWindowTable;
analysis.RequirementsCoverageTable = requirementsCoverageTable;
analysis.PublicContractChangeTable = publicContractChangeTable;

end

function resolvedOptions = localResolveOptions(options)

resolvedOptions = struct();
resolvedOptions.ManifestPath = localStringOption(options, "ManifestPath", "");
resolvedOptions.RadarMetadataPath = localStringOption(options, "RadarMetadataPath", "");
resolvedOptions.TruthPath = localStringOption(options, "TruthPath", "");
resolvedOptions.TruthWorkingRoot = localStringOption(options, "TruthWorkingRoot", "");
resolvedOptions.SourceG6BundleRoot = localStringOption(options, "SourceG6BundleRoot", "");
resolvedOptions.SourceG6Metrics = localStructOption(options, "SourceG6Metrics");

end

function value = localStringOption(options, fieldName, defaultValue)

value = string(defaultValue);

if isfield(options, fieldName)
    value = string(options.(fieldName));
end

end

function value = localStructOption(options, fieldName)

value = struct();

if isfield(options, fieldName)
    candidate = options.(fieldName);

    if isstruct(candidate)
        value = candidate;
    end
end

end

function sourceG6 = localResolveG6Source(datasetId, repoRoot, resolvedOptions)

sourceG6 = struct();
sourceG6.GateId = "G6_CPI_Integration_Freeze";
sourceG6.BundleRoot = "";
sourceG6.MetricsPath = "";
sourceG6.Metrics = struct();
sourceG6.Available = false;
sourceG6.LoadMessage = "";

if ~isempty(fieldnames(resolvedOptions.SourceG6Metrics))
    sourceG6.Metrics = resolvedOptions.SourceG6Metrics;
    sourceG6.Available = true;
    sourceG6.LoadMessage = "Using injected G6 metrics.";
    sourceG6.BundleRoot = localStringField(sourceG6.Metrics, ["bundle_root", "BundleRoot"], "");
    return
end

if strlength(resolvedOptions.SourceG6BundleRoot) > 0
    bundleRoot = resolvedOptions.SourceG6BundleRoot;
else
    bundleRoot = localFindLatestBundleRoot(repoRoot, datasetId, "G6_CPI_Integration_Freeze");
end

if strlength(bundleRoot) == 0
    sourceG6.LoadMessage = "No complete G6 bundle with metrics.json was found.";
    return
end

metricsPath = fullfile(bundleRoot, "metrics.json");

try
    metricsText = fileread(metricsPath);
    sourceG6.Metrics = jsondecode(metricsText);
catch readException
    error("helperAnalyzeG7TruthContextDiagnostic:ReadG6MetricsFailed", "Failed to read %s: %s", metricsPath, readException.message);
end

sourceG6.Available = true;
sourceG6.BundleRoot = string(bundleRoot);
sourceG6.MetricsPath = string(metricsPath);
sourceG6.LoadMessage = "Loaded G6 metrics.json.";

end

function bundleRoot = localFindLatestBundleRoot(repoRoot, datasetId, gateId)

stageRoot = fullfile(repoRoot, "artifacts", datasetId, gateId);
bundleRoot = "";

if ~isfolder(stageRoot)
    return
end

listing = dir(stageRoot);
names = string({listing.name}).';
isDirectory = [listing.isdir].';
isCandidate = isDirectory & names ~= "." & names ~= "..";
candidateNames = names(isCandidate);

if isempty(candidateNames)
    return
end

candidateRoots = fullfile(stageRoot, candidateNames);
candidateMetricsPaths = fullfile(candidateRoots, "metrics.json");
hasMetrics = isfile(candidateMetricsPaths);
validNames = candidateNames(hasMetrics);
validRoots = candidateRoots(hasMetrics);

if isempty(validRoots)
    return
end

[~, order] = sort(validNames, "descend");
bundleRoot = string(validRoots(order(1)));

end

function manifestPath = localResolveManifestPath(datasetId, repoRoot, resolvedOptions)

if strlength(resolvedOptions.ManifestPath) > 0
    manifestPath = resolvedOptions.ManifestPath;
else
    manifestPath = fullfile(repoRoot, datasetId, "session_manifest.json");
end

if ~isfile(manifestPath)
    error("helperAnalyzeG7TruthContextDiagnostic:MissingManifest", "Could not find manifest %s.", manifestPath);
end

end

function radarMetadataPath = localResolveRadarMetadataPath(datasetId, repoRoot, resolvedOptions)

if strlength(resolvedOptions.RadarMetadataPath) > 0
    radarMetadataPath = resolvedOptions.RadarMetadataPath;
else
    g1BundleRoot = localFindLatestBundleRoot(repoRoot, datasetId, "G1_Ingest");
    radarMetadataPath = fullfile(g1BundleRoot, "radar_metadata_scan.csv");
end

if ~isfile(radarMetadataPath)
    error("helperAnalyzeG7TruthContextDiagnostic:MissingRadarMetadata", "Could not find radar metadata %s.", radarMetadataPath);
end

end

function truthPath = localResolveTruthPath(datasetId, repoRoot, manifestPath, resolvedOptions)

if strlength(resolvedOptions.TruthPath) > 0
    truthPath = resolvedOptions.TruthPath;
else
    manifest = localReadJsonFile(manifestPath);
    truthPath = "";

    if isfield(manifest, "adsb_files") && ~isempty(manifest.adsb_files)
        truthRelativePath = string(manifest.adsb_files(1));
        truthPath = fullfile(repoRoot, datasetId, truthRelativePath);
    end
end

if strlength(truthPath) == 0
    error("helperAnalyzeG7TruthContextDiagnostic:MissingTruthPath", "No ADS-B truth artifact was declared.");
end

if endsWith(truthPath, ".gz", IgnoreCase = true)
    truthPath = localResolveCompressedTruthPath(truthPath, resolvedOptions.TruthWorkingRoot);
end

if ~isfile(truthPath)
    error("helperAnalyzeG7TruthContextDiagnostic:MissingTruthFile", "Could not find truth file %s.", truthPath);
end

end

function truthPath = localResolveCompressedTruthPath(gzipPath, truthWorkingRoot)

gzipPath = string(gzipPath);
expandedFolder = erase(gzipPath, ".gz");
expandedName = string(getFileNameWithoutGzip(gzipPath));
expandedPath = fullfile(expandedFolder, expandedName);

if isfile(expandedPath)
    truthPath = expandedPath;
    return
end

if strlength(truthWorkingRoot) == 0
    truthWorkingRoot = tempname;
end

try
    if ~isfolder(truthWorkingRoot)
        mkdir(truthWorkingRoot);
    end

    expandedFiles = gunzip(gzipPath, truthWorkingRoot);
catch unzipException
    error("helperAnalyzeG7TruthContextDiagnostic:GunzipFailed", "Failed to expand %s: %s", gzipPath, unzipException.message);
end

truthPath = string(expandedFiles(1));

end

function fileName = getFileNameWithoutGzip(gzipPath)

[~, baseName, extension] = fileparts(erase(string(gzipPath), ".gz"));
fileName = baseName + extension;

end

function manifest = localReadJsonFile(filePath)

try
    jsonText = fileread(filePath);
    manifest = jsondecode(jsonText);
catch readException
    error("helperAnalyzeG7TruthContextDiagnostic:ReadJsonFailed", "Failed to read %s: %s", filePath, readException.message);
end

end

function radarMetadataTable = localReadRadarMetadataTable(filePath)

try
    radarMetadataTable = readtable(filePath, TextType = "string", Delimiter = ",");
catch readException
    error("helperAnalyzeG7TruthContextDiagnostic:ReadRadarMetadataFailed", "Failed to read %s: %s", filePath, readException.message);
end

end

function truthTable = localReadTruthTable(filePath)

variableNames = {'MessageType', 'TransmissionType', 'SessionId', 'AircraftId', 'HexIdent', 'FlightId', 'DateGenerated', 'TimeGenerated', 'DateLogged', 'TimeLogged', 'Callsign', 'Altitude_ft', 'GroundSpeed_kt', 'Track_deg', 'Latitude_deg', 'Longitude_deg', 'VerticalRate_fpm', 'Squawk', 'Alert', 'Emergency', 'Spi', 'IsOnGround'};
variableTypes = repmat("string", 1, numel(variableNames));

try
    importOptions = delimitedTextImportOptions(NumVariables = numel(variableNames), Delimiter = ",");
    importOptions.VariableNames = variableNames;
    importOptions.VariableTypes = variableTypes;
    importOptions.ExtraColumnsRule = "ignore";
    importOptions.EmptyLineRule = "read";
    rawTruthTable = readtable(filePath, importOptions);
catch readException
    error("helperAnalyzeG7TruthContextDiagnostic:ReadTruthFailed", "Failed to read %s: %s", filePath, readException.message);
end

messageUtc = localParseTruthDatetime(rawTruthTable.DateGenerated, rawTruthTable.TimeGenerated);
loggedUtc = localParseTruthDatetime(rawTruthTable.DateLogged, rawTruthTable.TimeLogged);
truthTable = table();
truthTable.MessageType = string(rawTruthTable.MessageType);
truthTable.TransmissionType = str2double(string(rawTruthTable.TransmissionType));
truthTable.HexIdent = string(rawTruthTable.HexIdent);
truthTable.Callsign = strtrim(string(rawTruthTable.Callsign));
truthTable.MessageUtc = messageUtc;
truthTable.LoggedUtc = loggedUtc;
truthTable.Altitude_ft = str2double(string(rawTruthTable.Altitude_ft));
truthTable.GroundSpeed_kt = str2double(string(rawTruthTable.GroundSpeed_kt));
truthTable.Track_deg = str2double(string(rawTruthTable.Track_deg));
truthTable.Latitude_deg = str2double(string(rawTruthTable.Latitude_deg));
truthTable.Longitude_deg = str2double(string(rawTruthTable.Longitude_deg));
truthTable.VerticalRate_fpm = str2double(string(rawTruthTable.VerticalRate_fpm));

end

function timeValues = localParseTruthDatetime(dateValues, timeValuesText)

timestampText = strtrim(string(dateValues)) + " " + strtrim(string(timeValuesText));

try
    timeValues = datetime(timestampText, InputFormat = "yyyy/MM/dd HH:mm:ss.SSS", TimeZone = "UTC");
catch
    timeValues = datetime(timestampText, InputFormat = "yyyy/MM/dd HH:mm:ss", TimeZone = "UTC");
end

end

function radarTimingAuditTable = localBuildRadarTimingAuditTable(manifest, radarMetadataTable)

repetition = double(radarMetadataTable.Repetition);
relativePath = string(radarMetadataTable.RelativePath);
recordingUtc_s = double(radarMetadataTable.RecordingUTC);
recordingStartUtc = datetime(recordingUtc_s, ConvertFrom = "posixtime", TimeZone = "UTC");
embeddedDateTimeUtc = localParseEmbeddedDateTime(radarMetadataTable.DateTime);
duration_s = localNumericColumnOrDefault(radarMetadataTable, "Duration_s", manifest.capture_duration_s);
sampleSpan_s = localNumericColumnOrDefault(radarMetadataTable, "SampleSpan_s", manifest.capture_duration_s);
manifestSpacing_s = double(manifest.capture_repetition_spacing_s);
manifestCaptureDuration_s = double(manifest.capture_duration_s);
radarEpoch_s = double(manifest.radar_epoch_utc);
manifestSpacingOnlyStartUtc = datetime(radarEpoch_s + (repetition - 1.0) .* manifestSpacing_s, ConvertFrom = "posixtime", TimeZone = "UTC");
manifestSampleAndSpacingStartUtc = datetime(radarEpoch_s + (repetition - 1.0) .* (manifestCaptureDuration_s + manifestSpacing_s), ConvertFrom = "posixtime", TimeZone = "UTC");
recordingDelta_s = [NaN; seconds(diff(recordingStartUtc))];
recordingDeltaMinusSampleSpan_s = recordingDelta_s - sampleSpan_s;
recordingDeltaMinusSampleSpanAndManifestSpacing_s = recordingDelta_s - sampleSpan_s - manifestSpacing_s;
spacingOnlyResidual_s = seconds(recordingStartUtc - manifestSpacingOnlyStartUtc);
sampleAndSpacingResidual_s = seconds(recordingStartUtc - manifestSampleAndSpacingStartUtc);
dateTimeVsRecording_ms = milliseconds(embeddedDateTimeUtc - recordingStartUtc);

if ismember("DateTimeVsRecording_ms", string(radarMetadataTable.Properties.VariableNames))
    dateTimeVsRecording_ms = double(radarMetadataTable.DateTimeVsRecording_ms);
end

timingLabel = repmat("embedded_recording_utc_authoritative", numel(repetition), 1);
radarTimingAuditTable = table(repetition, relativePath, recordingUtc_s, recordingStartUtc, embeddedDateTimeUtc, dateTimeVsRecording_ms, duration_s, sampleSpan_s, manifestSpacingOnlyStartUtc, manifestSampleAndSpacingStartUtc, spacingOnlyResidual_s, sampleAndSpacingResidual_s, recordingDelta_s, recordingDeltaMinusSampleSpan_s, recordingDeltaMinusSampleSpanAndManifestSpacing_s, timingLabel, VariableNames = {'Repetition', 'RelativePath', 'RecordingUTC_s', 'RecordingStartUtc', 'EmbeddedDateTimeUtc', 'DateTimeVsRecording_ms', 'Duration_s', 'SampleSpan_s', 'ManifestSpacingOnlyStartUtc', 'ManifestSampleAndSpacingStartUtc', 'SpacingOnlyResidual_s', 'SampleAndSpacingResidual_s', 'RecordingDelta_s', 'RecordingDeltaMinusSampleSpan_s', 'RecordingDeltaMinusSampleSpanAndManifestSpacing_s', 'TimingLabel'});

end

function embeddedDateTimeUtc = localParseEmbeddedDateTime(dateTimeText)

dateTimeText = string(dateTimeText);

try
    embeddedDateTimeUtc = datetime(dateTimeText, InputFormat = "yyyy-MM-dd_HH-mm-ss.SSS", TimeZone = "UTC");
catch
    embeddedDateTimeUtc = datetime(dateTimeText, InputFormat = "yyyy-MM-dd_HH-mm-ss", TimeZone = "UTC");
end

end

function values = localNumericColumnOrDefault(inputTable, variableName, defaultValue)

variableNames = string(inputTable.Properties.VariableNames);

if ismember(variableName, variableNames)
    values = double(inputTable.(variableName));
else
    values = repmat(double(defaultValue), height(inputTable), 1);
end

end

function truthImportSummaryTable = localBuildTruthImportSummaryTable(truthPath, truthTable)

validTimeRows = ~isnat(truthTable.MessageUtc);
validAircraftRows = strlength(truthTable.HexIdent) > 0;
rowCount = height(truthTable);
validTimeRowCount = nnz(validTimeRows);
uniqueAircraftCount = numel(unique(truthTable.HexIdent(validAircraftRows)));
firstTruthUtc = NaT(1, 1, TimeZone = "UTC");
lastTruthUtc = NaT(1, 1, TimeZone = "UTC");

if any(validTimeRows)
    firstTruthUtc = min(truthTable.MessageUtc(validTimeRows));
    lastTruthUtc = max(truthTable.MessageUtc(validTimeRows));
end

truthFilePath = string(truthPath);
parseStatus = "parsed";
caveat = "capture_level_context_only";
truthImportSummaryTable = table(truthFilePath, rowCount, validTimeRowCount, uniqueAircraftCount, firstTruthUtc, lastTruthUtc, parseStatus, caveat, VariableNames = {'TruthFilePath', 'RowCount', 'ValidTimeRowCount', 'UniqueAircraftCount', 'FirstTruthUtc', 'LastTruthUtc', 'ParseStatus', 'Caveat'});

end

function captureTruthOverlapTable = localBuildCaptureTruthOverlapTable(radarTimingAuditTable, truthTable)

validTruthRows = ~isnat(truthTable.MessageUtc);
truthTimes = truthTable.MessageUtc(validTruthRows);
truthHex = truthTable.HexIdent(validTruthRows);
captureStartUtc = radarTimingAuditTable.RecordingStartUtc;
captureStopUtc = captureStartUtc + seconds(radarTimingAuditTable.Duration_s);
truthPosix = posixtime(truthTimes);
captureStartPosix = posixtime(captureStartUtc).';
captureStopPosix = posixtime(captureStopUtc).';
overlapMask = truthPosix >= captureStartPosix & truthPosix <= captureStopPosix;
truthRowCount = sum(overlapMask, 1).';
truthPosixMatrix = repmat(truthPosix, 1, height(radarTimingAuditTable));
truthPosixMatrix(~overlapMask) = NaN;
firstTruthPosix = min(truthPosixMatrix, [], 1, "omitnan").';
lastTruthPosix = max(truthPosixMatrix, [], 1, "omitnan").';
firstTruthUtc = datetime(firstTruthPosix, ConvertFrom = "posixtime", TimeZone = "UTC");
lastTruthUtc = datetime(lastTruthPosix, ConvertFrom = "posixtime", TimeZone = "UTC");
uniqueAircraftCount = arrayfun(@(idx) numel(unique(truthHex(overlapMask(:, idx) & strlength(truthHex) > 0))), (1:height(radarTimingAuditTable)).');
claimStatus = repmat("capture_level_diagnostic_only_product_claim_blocked", height(radarTimingAuditTable), 1);
captureTruthOverlapTable = table(radarTimingAuditTable.Repetition, radarTimingAuditTable.RelativePath, captureStartUtc, captureStopUtc, truthRowCount, uniqueAircraftCount, firstTruthUtc, lastTruthUtc, claimStatus, VariableNames = {'Repetition', 'RelativePath', 'CaptureStartUtc', 'CaptureStopUtc', 'TruthRowCount', 'UniqueAircraftCount', 'FirstTruthUtc', 'LastTruthUtc', 'ClaimStatus'});

end

function timingResidualSummaryTable = localBuildTimingResidualSummaryTable(manifest, radarTimingAuditTable)

manifestCaptureDuration_s = double(manifest.capture_duration_s);
manifestRepetitionSpacing_s = double(manifest.capture_repetition_spacing_s);
recordingDeltaMin_s = min(radarTimingAuditTable.RecordingDelta_s, [], "omitnan");
recordingDeltaMedian_s = median(radarTimingAuditTable.RecordingDelta_s, "omitnan");
recordingDeltaMax_s = max(radarTimingAuditTable.RecordingDelta_s, [], "omitnan");
maxAbsDateTimeVsRecording_ms = max(abs(radarTimingAuditTable.DateTimeVsRecording_ms), [], "omitnan");
maxAbsSpacingOnlyResidual_s = max(abs(radarTimingAuditTable.SpacingOnlyResidual_s), [], "omitnan");
maxAbsSampleAndSpacingResidual_s = max(abs(radarTimingAuditTable.SampleAndSpacingResidual_s), [], "omitnan");
timingSourceDecision = "per_file_recording_utc_repetition_anchors";
claimUse = "diagnostic_capture_context_only";
timingResidualSummaryTable = table(manifestCaptureDuration_s, manifestRepetitionSpacing_s, recordingDeltaMin_s, recordingDeltaMedian_s, recordingDeltaMax_s, maxAbsDateTimeVsRecording_ms, maxAbsSpacingOnlyResidual_s, maxAbsSampleAndSpacingResidual_s, timingSourceDecision, claimUse, VariableNames = {'ManifestCaptureDuration_s', 'ManifestRepetitionSpacing_s', 'RecordingDeltaMin_s', 'RecordingDeltaMedian_s', 'RecordingDeltaMax_s', 'MaxAbsDateTimeVsRecording_ms', 'MaxAbsSpacingOnlyResidual_s', 'MaxAbsSampleAndSpacingResidual_s', 'TimingSourceDecision', 'ClaimUse'});

end

function [claimGateTable, gateDecision, reviewStatus, truthClaimsEnabled, claimBlockReason, nextBranch] = localBuildClaimGateTable(sourceG6, truthImportSummaryTable, captureTruthOverlapTable)

g6FreezeEnabled = localLogicalField(sourceG6.Metrics, ["detector_product_freeze_enabled", "DetectorProductFreezeEnabled"], false);
g6FreezeStatus = localStringField(sourceG6.Metrics, ["freeze_status", "FreezeStatus"], "missing_g6_freeze");
hasTruthRows = truthImportSummaryTable.ValidTimeRowCount(1) > 0;
hasCaptureOverlap = any(captureTruthOverlapTable.TruthRowCount > 0);

truthClaimsEnabled = false;
claimBlockReason = "missing_frozen_g6_product";

if sourceG6.Available && ~g6FreezeEnabled
    claimBlockReason = "g6_product_freeze_not_enabled_" + g6FreezeStatus;
elseif ~sourceG6.Available
    claimBlockReason = "missing_g6_evidence_bundle";
elseif ~hasTruthRows
    claimBlockReason = "truth_artifact_has_no_valid_timestamps";
elseif ~hasCaptureOverlap
    claimBlockReason = "truth_artifact_has_no_capture_overlap";
end

gateDecision = "reject";
reviewStatus = "truth_context_diagnostic_only";
nextBranch = "hold_truth_claims_until_g6_freeze_and_g7_product_windows";
claimScope = "cpi_product_level_truth_claims";
sourceG6BundleRoot = string(sourceG6.BundleRoot);
sourceG6FreezeStatus = string(g6FreezeStatus);
truthRowsAvailable = logical(hasTruthRows);
captureOverlapAvailable = logical(hasCaptureOverlap);
claimGateTable = table(claimScope, truthClaimsEnabled, string(claimBlockReason), sourceG6BundleRoot, sourceG6FreezeStatus, truthRowsAvailable, captureOverlapAvailable, VariableNames = {'ClaimScope', 'TruthClaimsEnabled', 'ClaimBlockReason', 'SourceG6BundleRoot', 'SourceG6FreezeStatus', 'TruthRowsAvailable', 'CaptureOverlapAvailable'});

end

function validationWindowTable = localBuildValidationWindowTable(captureTruthOverlapTable, truthClaimsEnabled, claimBlockReason)

windowScope = repmat("capture_level_diagnostic_context", height(captureTruthOverlapTable), 1);
repetition = captureTruthOverlapTable.Repetition;
windowStartUtc = captureTruthOverlapTable.CaptureStartUtc;
windowStopUtc = captureTruthOverlapTable.CaptureStopUtc;
truthRowCount = captureTruthOverlapTable.TruthRowCount;
uniqueAircraftCount = captureTruthOverlapTable.UniqueAircraftCount;
productClaimStatus = repmat("blocked", height(captureTruthOverlapTable), 1);
claimBlockReasonColumn = repmat(string(claimBlockReason), height(captureTruthOverlapTable), 1);
truthClaimsEnabledColumn = repmat(logical(truthClaimsEnabled), height(captureTruthOverlapTable), 1);
validationWindowTable = table(windowScope, repetition, windowStartUtc, windowStopUtc, truthRowCount, uniqueAircraftCount, truthClaimsEnabledColumn, productClaimStatus, claimBlockReasonColumn, VariableNames = {'WindowScope', 'Repetition', 'WindowStartUtc', 'WindowStopUtc', 'TruthRowCount', 'UniqueAircraftCount', 'TruthClaimsEnabled', 'ProductClaimStatus', 'ClaimBlockReason'});

end

function requirementsCoverageTable = localBuildRequirementsCoverageTable(truthClaimsEnabled, claimBlockReason)

requirementId = [
    "VAL-001"
    "VAL-002"
    ];
gateId = [
    "G7_Truth_Alignment"
    "G7_Truth_Alignment"
    ];
status = [
    "diagnostic_only"
    "blocked"
    ];
evidenceReference = [
    "capture_truth_overlap_table.csv"
    "validation_window_table.csv"
    ];
notes = [
    "Capture-level timing/truth overlap emitted without enabling product claims."
    "CPI/product association windows blocked: " + string(claimBlockReason)
    ];

if truthClaimsEnabled
    status = [
        "ready"
        "ready"
        ];
end

requirementsCoverageTable = table(requirementId, gateId, status, evidenceReference, notes, VariableNames = {'RequirementId', 'GateId', 'Status', 'EvidenceReference', 'Notes'});

end

function publicContractChangeTable = localBuildPublicContractChangeTable()

contractItem = [
    "G7 truth_context_diagnostic mode"
    "G7 claim gating"
    "G7 capture overlap table"
    ];
changeType = [
    "new_diagnostic_mode"
    "explicit_truth_claim_block"
    "new_capture_level_context_table"
    ];
downstreamEffect = [
    "G7 may import truth and audit timing before G6 freeze, but only as diagnostic context."
    "Formal truth-correlated detection claims remain disabled until G6 frozen product evidence exists."
    "Downstream review can inspect capture-level truth overlap without treating it as detector validation."
    ];
publicContractChangeTable = table(contractItem, changeType, downstreamEffect, VariableNames = {'ContractItem', 'ChangeType', 'DownstreamEffect'});

end

function value = localStringField(inputStruct, fieldNames, defaultValue)

value = string(defaultValue);

if ~isstruct(inputStruct)
    return
end

candidateNames = string(fieldNames);
structFields = string(fieldnames(inputStruct));
matchIndex = find(ismember(candidateNames, structFields), 1, "first");

if isempty(matchIndex)
    return
end

fieldValue = inputStruct.(candidateNames(matchIndex));

if isstring(fieldValue) || ischar(fieldValue)
    value = string(fieldValue);
elseif isnumeric(fieldValue) || islogical(fieldValue)
    value = string(fieldValue);
end

if numel(value) > 1
    value = value(1);
end

end

function value = localLogicalField(inputStruct, fieldNames, defaultValue)

value = logical(defaultValue);

if ~isstruct(inputStruct)
    return
end

candidateNames = string(fieldNames);
structFields = string(fieldnames(inputStruct));
matchIndex = find(ismember(candidateNames, structFields), 1, "first");

if isempty(matchIndex)
    return
end

fieldValue = inputStruct.(candidateNames(matchIndex));

if islogical(fieldValue) && isscalar(fieldValue)
    value = logical(fieldValue);
elseif isnumeric(fieldValue) && isscalar(fieldValue)
    value = fieldValue ~= 0;
elseif isstring(fieldValue) || ischar(fieldValue)
    value = any(strcmpi(string(fieldValue), ["true", "1", "yes"]));
end

end
