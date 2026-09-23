function sessionData = loadIQData(datasetId, repoRoot, options)
%LOADIQDATA Load and decode session IQ data for downstream gate work.
%
%   SESSIONDATA = LOADIQDATA() loads the reference dataset
%   20260622T102123 and returns a manifest-driven session struct.
%
%   SESSIONDATA = LOADIQDATA(DATASETID, REPOROOT, OPTIONS) overrides the
%   dataset ID, repository root, and loader options.
%
%   OPTIONS.IncludeSamples defaults to true. Set it to false to return the
%   decoded metadata and contracts without retaining the full IQ matrices in
%   the returned session struct. OPTIONS.PartSelection supports part 1 or
%   "all" and defaults to "all". OPTIONS.SessionRoot can identify a packaged
%   session outside the PBR repository without adding external source code
%   to the MATLAB path.

arguments
    datasetId (1,1) string = "20260622T102123"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

repoRoot = helperResolveRepoRoot(repoRoot);
datasetId = string(datasetId);
datasetRoot = localResolveDatasetRoot(repoRoot, datasetId, options);
manifestPath = fullfile(datasetRoot, "session_manifest.json");
includeSamples = localResolveIncludeSamples(options);

manifest = localReadManifest(manifestPath);
manifestNormalization = localBuildManifestNormalization(manifest);
observedFiles = localCollectObservedFiles(datasetRoot);
manifestTable = localBuildManifestTable(manifest, observedFiles);

radarRelativePaths = localManifestPaths(manifest, "radar_files");
partSelection = "all";

if isfield(options, "PartSelection")
    partSelection = options.PartSelection;
end

selectionContract = helperResolvePartSelection(partSelection, ...
    radarRelativePaths);
selectedManifestIndices = selectionContract.SelectedManifestIndices;
selectedRadarRelativePaths = ...
    selectionContract.SelectedRadarRelativePaths;
scanCount = numel(selectedRadarRelativePaths);
radarScanCells = cell(scanCount, 1);

for idx = 1:scanCount
    manifestIndex = selectedManifestIndices(idx);
    absoluteFilePath = fullfile(datasetRoot, ...
        strrep(selectedRadarRelativePaths(idx), "/", filesep));
    radarScanCells{idx} = helperScanBasebandCaptureFile(absoluteFilePath, ...
        includeSamples);
    radarScanCells{idx}.ManifestIndex = manifestIndex;
    radarScanCells{idx}.RelativePath = selectedRadarRelativePaths(idx);
    radarScanCells{idx}.FileSuffixRepetition = ...
        localExtractFileSuffixRepetition(selectedRadarRelativePaths(idx), ...
        manifestIndex);
end

radarScans = vertcat(radarScanCells{:});
radarTable = localBuildRadarTable(radarScans);
seamTable = localBuildSeamTable(radarScans);

sessionData = struct();
sessionData.DatasetId = datasetId;
sessionData.RepoRoot = repoRoot;
sessionData.DatasetRoot = string(datasetRoot);
sessionData.ManifestPath = string(manifestPath);
sessionData.Manifest = manifest;
sessionData.ManifestNormalization = manifestNormalization;
sessionData.ObservedInventoryTable = observedFiles;
sessionData.ManifestInventoryTable = manifestTable;
sessionData.PackageRadarRelativePaths = radarRelativePaths;
sessionData.SelectedRadarRelativePaths = selectedRadarRelativePaths;
selectionContract.SelectedRepetitions = [radarScans.Repetition].';
sessionData.PartSelection = selectionContract;
sessionData.RadarScans = radarScans;
sessionData.RadarTable = radarTable;
sessionData.SeamTable = seamTable;
sessionData.NativeReaderContract = localBuildNativeReaderContract( ...
    radarScans, includeSamples);
sessionData.ChannelContract = localBuildChannelContract(radarScans);
sessionData.TimingModel = localBuildTimingModel(manifest, radarScans);
sessionData.CpiContract = localBuildCpiContract(radarScans);

end

function datasetRoot = localResolveDatasetRoot(repoRoot, datasetId, options)

if isfield(options, "SessionRoot")
    datasetRoot = string(options.SessionRoot);
else
    datasetRoot = fullfile(repoRoot, datasetId);
end

if ~isscalar(datasetRoot) || strlength(strtrim(datasetRoot)) == 0
    error("loadIQData:InvalidSessionRoot", ...
        "OPTIONS.SessionRoot must be a nonempty scalar path.");
end

if ~isfolder(datasetRoot)
    error("loadIQData:MissingSessionRoot", ...
        "Session folder not found: %s", datasetRoot);
end

end

function manifest = localReadManifest(manifestPath)

try
    manifest = jsondecode(fileread(manifestPath));
catch manifestException
    error("loadIQData:ReadManifestFailed", ...
        "Failed to read manifest %s: %s", manifestPath, ...
        manifestException.message);
end

end

function normalization = localBuildManifestNormalization(manifest)

radarPaths = localManifestPaths(manifest, "radar_files");
adsbPaths = localManifestPaths(manifest, "adsb_files");
truthPaths = localManifestPaths(manifest, "truth_files");
logPaths = localManifestPaths(manifest, "log_files");

if isempty(radarPaths)
    error("loadIQData:MissingRadarFiles", ...
        "The session manifest must declare at least one radar file.");
end

if ~isempty(adsbPaths) && ~isempty(truthPaths)
    truthFieldUsed = "adsb_files_and_truth_files";
elseif ~isempty(truthPaths)
    truthFieldUsed = "truth_files";
elseif ~isempty(adsbPaths)
    truthFieldUsed = "adsb_files";
else
    truthFieldUsed = "none";
end

missingOptionalFields = strings(0, 1);

if ~isfield(manifest, "adsb_files")
    missingOptionalFields(end + 1, 1) = "adsb_files";
end

if ~isfield(manifest, "truth_files")
    missingOptionalFields(end + 1, 1) = "truth_files";
end

if ~isfield(manifest, "log_files")
    missingOptionalFields(end + 1, 1) = "log_files";
end

normalization = struct();
normalization.Schema = "session_manifest_v1_compatible";
normalization.SourceManifestUnchanged = true;
normalization.TruthFieldUsed = truthFieldUsed;
normalization.RadarFileCount = double(numel(radarPaths));
normalization.TruthFileCount = double(numel(unique( ...
    [adsbPaths; truthPaths], "stable")));
normalization.LogFileCount = double(numel(logPaths));
normalization.MissingOptionalFields = missingOptionalFields;
normalization.OmittedEmptyFieldsTolerated = ...
    ~isempty(missingOptionalFields);

end

function observedFiles = localCollectObservedFiles(datasetRoot)

try
    listing = dir(fullfile(datasetRoot, "**", "*"));
catch listingException
    error("loadIQData:CollectObservedFilesFailed", ...
        "Failed to enumerate dataset files under %s: %s", datasetRoot, ...
        listingException.message);
end

listing = listing(~[listing.isdir]);
fileCount = numel(listing);
relativePath = strings(fileCount, 1);
artifactType = strings(fileCount, 1);
bytes = zeros(fileCount, 1);

for idx = 1:fileCount
    absolutePath = fullfile(listing(idx).folder, listing(idx).name);
    relativePath(idx) = localNormalizeRelativePath(absolutePath, datasetRoot);
    pathTokens = split(relativePath(idx), "/");
    artifactType(idx) = pathTokens(1);
    bytes(idx) = double(listing(idx).bytes);
end

observedFiles = table(relativePath, artifactType, bytes, ...
    VariableNames = {'RelativePath', 'ArtifactType', 'Bytes'});
observedFiles = observedFiles(ismember(observedFiles.ArtifactType, ...
    ["radar", "truth", "logs"]), :);
observedFiles = sortrows(observedFiles, ["ArtifactType", "RelativePath"]);

end

function manifestTable = localBuildManifestTable(manifest, observedFiles)

traceabilityTruthPaths = strings(0, 1);

if isfield(manifest, "traceability_truth_file")
    traceabilityTruthPaths = string(manifest.traceability_truth_file);
    traceabilityTruthPaths = traceabilityTruthPaths( ...
        strlength(strtrim(traceabilityTruthPaths)) > 0);
end

radarPaths = localManifestPaths(manifest, "radar_files");
adsbPaths = localManifestPaths(manifest, "adsb_files");
truthPaths = localManifestPaths(manifest, "truth_files");
truthPaths = unique([adsbPaths; truthPaths; traceabilityTruthPaths(:)], ...
    "stable");
logPaths = localManifestPaths(manifest, "log_files");
requiredPaths = [ ...
    radarPaths; ...
    truthPaths; ...
    logPaths ...
    ];
requiredType = [ ...
    repmat("radar", numel(radarPaths), 1); ...
    repmat("truth", numel(truthPaths), 1); ...
    repmat("logs", numel(logPaths), 1) ...
    ];
manifestIndex = (1:numel(requiredPaths)).';

requiredRowCount = numel(requiredPaths);
requiredObserved = false(requiredRowCount, 1);
requiredStatus = strings(requiredRowCount, 1);
requiredBytes = NaN(requiredRowCount, 1);

for idx = 1:requiredRowCount
    matchIndex = observedFiles.RelativePath == requiredPaths(idx);
    requiredObserved(idx) = any(matchIndex);

    if requiredObserved(idx)
        requiredStatus(idx) = "required_present";
        requiredBytes(idx) = observedFiles.Bytes(find(matchIndex, 1, "first"));
    else
        requiredStatus(idx) = "missing_required";
    end
end

requiredTable = table(manifestIndex, requiredType, requiredPaths, ...
    true(requiredRowCount, 1), requiredObserved, requiredStatus, requiredBytes, ...
    VariableNames = {'ManifestIndex', 'ArtifactType', 'RelativePath', ...
    'RequiredByManifest', 'Observed', 'Status', 'ObservedBytes'});

extraMask = ~ismember(observedFiles.RelativePath, requiredPaths);
sourceArtifactMask = extraMask & localIsSourceArtifactRelativePath( ...
    observedFiles.RelativePath);
supportArtifactMask = extraMask & ~sourceArtifactMask;
sourceObserved = observedFiles(sourceArtifactMask, :);
supportObserved = observedFiles(supportArtifactMask, :);
sourceCount = height(sourceObserved);
supportCount = height(supportObserved);

sourceExtraTable = table( ...
    NaN(sourceCount, 1), ...
    sourceObserved.ArtifactType, ...
    sourceObserved.RelativePath, ...
    false(sourceCount, 1), ...
    true(sourceCount, 1), ...
    repmat("unexpected_extra_source_artifact", sourceCount, 1), ...
    sourceObserved.Bytes, ...
    VariableNames = requiredTable.Properties.VariableNames);

supportExtraTable = table( ...
    NaN(supportCount, 1), ...
    supportObserved.ArtifactType, ...
    supportObserved.RelativePath, ...
    false(supportCount, 1), ...
    true(supportCount, 1), ...
    repmat("local_support_nonblocking", supportCount, 1), ...
    supportObserved.Bytes, ...
    VariableNames = requiredTable.Properties.VariableNames);

manifestTable = [requiredTable; sourceExtraTable; supportExtraTable];

end

function paths = localManifestPaths(manifest, fieldName)

paths = strings(0, 1);

if ~isfield(manifest, fieldName)
    return
end

candidatePaths = string(manifest.(fieldName));
candidatePaths = candidatePaths(:);
paths = candidatePaths(strlength(strtrim(candidatePaths)) > 0);

end

function radarTable = localBuildRadarTable(radarScans)

scanCount = numel(radarScans);
manifestIndex = zeros(scanCount, 1);
relativePath = strings(scanCount, 1);
repetition = zeros(scanCount, 1);
fileSuffixRepetition = zeros(scanCount, 1);
decodePath = strings(scanCount, 1);
rawFreadFallbackUsed = false(scanCount, 1);
payloadOffsetBytes = zeros(scanCount, 1);
headerVersion = strings(scanCount, 1);
metadataSource = strings(scanCount, 1);
nativeReaderFailureCategory = strings(scanCount, 1);
sampleRateHz = zeros(scanCount, 1);
centerFrequencyHz = zeros(scanCount, 1);
numSamples = zeros(scanCount, 1);
numChannels = zeros(scanCount, 1);
dataType = strings(scanCount, 1);
isComplex = false(scanCount, 1);
sampleSpanS = zeros(scanCount, 1);
durationS = zeros(scanCount, 1);
recordingUtc = zeros(scanCount, 1);
dateTimeText = strings(scanCount, 1);
dateTimeVsRecordingMs = zeros(scanCount, 1);
fileBytes = zeros(scanCount, 1);
payloadBytes = zeros(scanCount, 1);
wrapperOverheadBytes = zeros(scanCount, 1);
antenna1 = strings(scanCount, 1);
antenna2 = strings(scanCount, 1);
channelLabelSource = strings(scanCount, 1);
meanPowerCh1 = zeros(scanCount, 1);
meanPowerCh2 = zeros(scanCount, 1);
channelPowerDeltaDb = zeros(scanCount, 1);
channelCorrelationMagnitude = zeros(scanCount, 1);
firstNonzeroIndexCh1 = zeros(scanCount, 1);
firstNonzeroIndexCh2 = zeros(scanCount, 1);
manifestOrderMatchesRepetition = false(scanCount, 1);
filenameSuffixMatchesRepetition = false(scanCount, 1);

for idx = 1:scanCount
    manifestIndex(idx) = radarScans(idx).ManifestIndex;
    relativePath(idx) = radarScans(idx).RelativePath;
    repetition(idx) = radarScans(idx).Repetition;
    fileSuffixRepetition(idx) = radarScans(idx).FileSuffixRepetition;
    decodePath(idx) = radarScans(idx).DecodePath;
    rawFreadFallbackUsed(idx) = radarScans(idx).RawFreadFallbackUsed;
    payloadOffsetBytes(idx) = radarScans(idx).PayloadOffsetBytes;
    headerVersion(idx) = radarScans(idx).HeaderVersion;
    metadataSource(idx) = radarScans(idx).MetadataSource;
    nativeReaderFailureCategory(idx) = ...
        radarScans(idx).NativeReaderFailureCategory;
    sampleRateHz(idx) = radarScans(idx).SampleRate;
    centerFrequencyHz(idx) = radarScans(idx).CenterFrequency;
    numSamples(idx) = radarScans(idx).NumSamples;
    numChannels(idx) = radarScans(idx).NumChannels;
    dataType(idx) = radarScans(idx).DataType;
    isComplex(idx) = radarScans(idx).IsComplex;
    sampleSpanS(idx) = radarScans(idx).SampleSpan_s;
    durationS(idx) = radarScans(idx).Duration_s;
    recordingUtc(idx) = radarScans(idx).RecordingUTC;
    dateTimeText(idx) = radarScans(idx).DateTime;
    dateTimeVsRecordingMs(idx) = radarScans(idx).DateTimeVsRecording_ms;
    fileBytes(idx) = radarScans(idx).FileBytes;
    payloadBytes(idx) = radarScans(idx).PayloadBytes;
    wrapperOverheadBytes(idx) = radarScans(idx).WrapperOverheadBytes;
    antenna1(idx) = radarScans(idx).Antenna1;
    antenna2(idx) = radarScans(idx).Antenna2;
    channelLabelSource(idx) = radarScans(idx).ChannelLabelSource;
    meanPowerCh1(idx) = radarScans(idx).MeanPowerCh1;
    meanPowerCh2(idx) = radarScans(idx).MeanPowerCh2;
    channelPowerDeltaDb(idx) = 10 * log10(meanPowerCh1(idx) / meanPowerCh2(idx));
    channelCorrelationMagnitude(idx) = ...
        radarScans(idx).ChannelCorrelationMagnitude;
    firstNonzeroIndexCh1(idx) = radarScans(idx).FirstNonzeroIndexCh1;
    firstNonzeroIndexCh2(idx) = radarScans(idx).FirstNonzeroIndexCh2;
    manifestOrderMatchesRepetition(idx) = ...
        radarScans(idx).ManifestIndex == radarScans(idx).Repetition;
    filenameSuffixMatchesRepetition(idx) = ...
        radarScans(idx).FileSuffixRepetition == radarScans(idx).Repetition;
end

radarTable = table(manifestIndex, relativePath, repetition, ...
    fileSuffixRepetition, decodePath, rawFreadFallbackUsed, ...
    payloadOffsetBytes, headerVersion, metadataSource, ...
    nativeReaderFailureCategory, sampleRateHz, centerFrequencyHz, ...
    numSamples, numChannels, dataType, isComplex, sampleSpanS, durationS, ...
    recordingUtc, dateTimeText, dateTimeVsRecordingMs, fileBytes, ...
    payloadBytes, wrapperOverheadBytes, antenna1, antenna2, ...
    channelLabelSource, meanPowerCh1, meanPowerCh2, channelPowerDeltaDb, ...
    channelCorrelationMagnitude, ...
    firstNonzeroIndexCh1, firstNonzeroIndexCh2, ...
    manifestOrderMatchesRepetition, filenameSuffixMatchesRepetition, ...
    VariableNames = {'ManifestIndex', 'RelativePath', 'Repetition', ...
    'FileSuffixRepetition', 'DecodePath', 'RawFreadFallbackUsed', ...
    'PayloadOffsetBytes', 'HeaderVersion', 'MetadataSource', ...
    'NativeReaderFailureCategory', 'SampleRate_Hz', 'CenterFrequency_Hz', ...
    'NumSamples', 'NumChannels', 'DataType', 'IsComplex', 'SampleSpan_s', ...
    'Duration_s', 'RecordingUTC', 'DateTime', 'DateTimeVsRecording_ms', ...
    'FileBytes', 'PayloadBytes', 'WrapperOverheadBytes', 'Antenna1', ...
    'Antenna2', 'ChannelLabelSource', 'MeanPowerCh1', 'MeanPowerCh2', ...
    'ChannelPowerDelta_dB', 'ChannelCorrelationMagnitude', ...
    'FirstNonzeroIndexCh1', ...
    'FirstNonzeroIndexCh2', 'ManifestOrderMatchesRepetition', ...
    'FilenameSuffixMatchesRepetition'});

end

function seamTable = localBuildSeamTable(radarScans)

scanCount = numel(radarScans);
boundaryCount = max(scanCount - 1, 0);
previousRepetition = zeros(boundaryCount, 1);
currentRepetition = zeros(boundaryCount, 1);
deltaRecordingUtcS = zeros(boundaryCount, 1);
deltaSampleSpanS = zeros(boundaryCount, 1);
repetitionIncrement = zeros(boundaryCount, 1);
sampleCountStable = false(boundaryCount, 1);
metadataStable = false(boundaryCount, 1);
decodeContractStable = false(boundaryCount, 1);
edgeExactDuplicateCount = zeros(boundaryCount, 1);
status = strings(boundaryCount, 1);

for idx = 2:scanCount
    rowIdx = idx - 1;
    previousScan = radarScans(idx - 1);
    currentScan = radarScans(idx);

    previousRepetition(rowIdx) = previousScan.Repetition;
    currentRepetition(rowIdx) = currentScan.Repetition;
    deltaRecordingUtcS(rowIdx) = ...
        currentScan.RecordingUTC - previousScan.RecordingUTC;
    deltaSampleSpanS(rowIdx) = ...
        deltaRecordingUtcS(rowIdx) - previousScan.SampleSpan_s;
    repetitionIncrement(rowIdx) = ...
        currentScan.Repetition - previousScan.Repetition;
    sampleCountStable(rowIdx) = ...
        currentScan.NumSamples == previousScan.NumSamples;
    metadataStable(rowIdx) = ...
        currentScan.SampleRate == previousScan.SampleRate && ...
        currentScan.CenterFrequency == previousScan.CenterFrequency && ...
        currentScan.NumChannels == previousScan.NumChannels && ...
        currentScan.Antenna1 == previousScan.Antenna1 && ...
        currentScan.Antenna2 == previousScan.Antenna2 && ...
        currentScan.SessionID == previousScan.SessionID;
    decodeContractStable(rowIdx) = ...
        currentScan.DataType == previousScan.DataType && ...
        currentScan.IsComplex == previousScan.IsComplex;
    edgeExactDuplicateCount(rowIdx) = nnz( ...
        previousScan.EndSamples == currentScan.StartSamples);

    if repetitionIncrement(rowIdx) ~= 1
        status(rowIdx) = "defect_repetition_index_jump";
    elseif ~sampleCountStable(rowIdx)
        status(rowIdx) = "defect_sample_count_shift";
    elseif ~metadataStable(rowIdx) || ~decodeContractStable(rowIdx)
        status(rowIdx) = "defect_contract_change";
    elseif edgeExactDuplicateCount(rowIdx) == numel(currentScan.StartSamples)
        status(rowIdx) = "warning_exact_edge_duplicate";
    else
        status(rowIdx) = "ok_gap_expected";
    end
end

seamTable = table(previousRepetition, currentRepetition, deltaRecordingUtcS, ...
    deltaSampleSpanS, repetitionIncrement, sampleCountStable, metadataStable, ...
    decodeContractStable, edgeExactDuplicateCount, status, ...
    VariableNames = {'PreviousRepetition', 'CurrentRepetition', ...
    'DeltaRecordingUTC_s', 'WallClockMinusSampleSpan_s', ...
    'RepetitionIncrement', 'SampleCountStable', 'MetadataStable', ...
    'DecodeContractStable', 'EdgeExactDuplicateCount', 'Status'});

end

function nativeReaderContract = localBuildNativeReaderContract(radarScans, ...
    includeSamples)

wrapperOverheadBytes = [radarScans.WrapperOverheadBytes].';
payloadOffsetBytes = [radarScans.PayloadOffsetBytes].';

nativeReaderContract = struct();
nativeReaderContract.Reader = localUniqueNonemptyStrings( ...
    string({radarScans.DecodePath}).');
nativeReaderContract.PreferredReader = "comm.BasebandFileReader";
nativeReaderContract.RawFreadFallbackUsed = ...
    any([radarScans.RawFreadFallbackUsed].');
nativeReaderContract.RawFreadFallbackReason = localUniqueNonemptyStrings( ...
    string({radarScans.RawFreadFallbackReason}).');
nativeReaderContract.NativeReaderFailureCategory = ...
    localUniqueNonemptyStrings( ...
    string({radarScans.NativeReaderFailureCategory}).');
nativeReaderContract.NativeReaderFailureIdentifier = ...
    localUniqueNonemptyStrings( ...
    string({radarScans.NativeReaderFailureIdentifier}).');
nativeReaderContract.NativeReaderFailureMessage = ...
    localUniqueNonemptyStrings( ...
    string({radarScans.NativeReaderFailureMessage}).');
    nativeReaderContract.LoadedSamplesIntoMemory = includeSamples;
    nativeReaderContract.FileCount = numel(radarScans);
    nativeReaderContract.NumSamplesPerFile = unique([radarScans.NumSamples].');
    nativeReaderContract.NumChannels = unique([radarScans.NumChannels].');
    nativeReaderContract.DataType = unique(string({radarScans.DataType}).');
    nativeReaderContract.IsComplex = all([radarScans.IsComplex].');
    nativeReaderContract.Channel1Label = unique(string({radarScans.Antenna1}).');
    nativeReaderContract.Channel2Label = unique(string({radarScans.Antenna2}).');
    nativeReaderContract.ChannelLabelSource = ...
        unique(string({radarScans.ChannelLabelSource}).');
    nativeReaderContract.SampleRateHz = unique([radarScans.SampleRate].');
    nativeReaderContract.CenterFrequencyHz = unique([radarScans.CenterFrequency].');
    nativeReaderContract.PayloadBytes = unique([radarScans.PayloadBytes].');
    nativeReaderContract.PayloadOffsetBytes = [ ...
        min(payloadOffsetBytes), ...
        max(payloadOffsetBytes) ...
        ];
    nativeReaderContract.WrapperOverheadBytes = [ ...
        min(wrapperOverheadBytes), ...
        max(wrapperOverheadBytes) ...
        ];
    nativeReaderContract.HeaderVersion = localUniqueNonemptyStrings( ...
        string({radarScans.HeaderVersion}).');
    nativeReaderContract.MetadataSource = unique(string({radarScans.MetadataSource}).');
    nativeReaderContract.PayloadPacking = localUniqueNonemptyStrings( ...
        string({radarScans.PayloadPacking}).');

end

function channelContract = localBuildChannelContract(radarScans)

channelPowerRatioDb = 10 * log10([radarScans.MeanPowerCh1].' ./ ...
    [radarScans.MeanPowerCh2].');
channelCorrelationMagnitude = [radarScans.ChannelCorrelationMagnitude].';

channelContract = struct();
channelContract.NumChannels = unique([radarScans.NumChannels].');
channelContract.CanonicalRepresentation = "[N x 2] complex int16 matrix";
channelContract.Channel1Label = unique(string({radarScans.Antenna1}).');
channelContract.Channel2Label = unique(string({radarScans.Antenna2}).');
channelContract.ChannelLabelSource = ...
    unique(string({radarScans.ChannelLabelSource}).');
channelContract.ChannelPowerDeltaDb = [ ...
    min(channelPowerRatioDb), ...
    max(channelPowerRatioDb) ...
    ];
channelContract.ChannelCorrelationMagnitude = [ ...
    min(channelCorrelationMagnitude), ...
    max(channelCorrelationMagnitude) ...
    ];

end

function timingModel = localBuildTimingModel(manifest, radarScans)

recordingUtcVector = [radarScans.RecordingUTC].';
recordingUtcDelta = diff(recordingUtcVector);
sampleSpanVector = [radarScans.SampleSpan_s].';
wallClockMinusSampleSpan = recordingUtcDelta - sampleSpanVector(1:end - 1);
wallClockMinusSampleSpanAndRequestedSpacing = wallClockMinusSampleSpan - ...
    manifest.capture_repetition_spacing_s;
dateTimeVsRecordingMs = [radarScans.DateTimeVsRecording_ms].';

timingModel = struct();
timingModel.SampleSpanSeconds = unique([radarScans.SampleSpan_s].');
timingModel.ManifestCaptureDurationSeconds = manifest.capture_duration_s;
timingModel.ManifestCaptureRepetitionSpacingSeconds = ...
    manifest.capture_repetition_spacing_s;
timingModel.RecordingUtcAnchorSeconds = recordingUtcVector;
timingModel.RecordingUtcDeltaSeconds = recordingUtcDelta;
timingModel.WallClockMinusSampleSpanSeconds = wallClockMinusSampleSpan;
timingModel.WallClockMinusSampleSpanAndRequestedSpacingSeconds = ...
    wallClockMinusSampleSpanAndRequestedSpacing;
timingModel.MaxDateTimeVsRecordingMilliseconds = ...
    max(abs(dateTimeVsRecordingMs));
timingModel.AuthoritativeRadarTimeBase = ...
    "per-file RecordingUTC repetition anchors";
timingModel.RadarEpochRole = "session first-repetition anchor";
timingModel.RadarEpochMinusFirstRecordingSeconds = ...
    manifest.radar_epoch_utc - radarScans(1).RecordingUTC;

end

function cpiContract = localBuildCpiContract(radarScans)

cpiContract = struct();
cpiContract.SegmentationScope = "intra-file only";
cpiContract.CrossFileAllowed = false;
cpiContract.CanonicalSamplesPerRepetition = unique([radarScans.NumSamples].');
cpiContract.Note = [ ...
    "Each file is one repetition boundary. Cross-file CPI formation ", ...
    "requires a later explicit G1 reopen decision." ...
    ];

end

function includeSamples = localResolveIncludeSamples(options)

includeSamples = true;

if ~isfield(options, "IncludeSamples")
    return;
end

includeSamples = logical(options.IncludeSamples);

end

function value = localExtractFileSuffixRepetition(relativePath, ...
    manifestIndex)

token = regexp(relativePath, "_part(\d+)(?:\.bb)?$", "tokens", "once");

if isempty(token)
    value = double(manifestIndex);
    return
end

value = str2double(token{1});

end

function relativePath = localNormalizeRelativePath(absolutePath, datasetRoot)

relativePath = string(strrep(absolutePath, datasetRoot + filesep, ""));
relativePath = replace(relativePath, "\", "/");

end

function values = localUniqueNonemptyStrings(values)

values = unique(string(values));
values = values(strlength(strtrim(values)) > 0);

end

function isSourceArtifact = localIsSourceArtifactRelativePath(relativePaths)

relativePaths = string(relativePaths);
pathDepth = count(relativePaths, "/") + 1;
artifactType = extractBefore(relativePaths + "/", "/");
isKnownRoot = ismember(artifactType, ["radar", "truth", "logs"]);
isSourceArtifact = isKnownRoot & pathDepth == 2;

end
