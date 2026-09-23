function scan = helperScanBasebandCaptureFile(filePath, includeSamples)
%HELPERSCANBASEBANDCAPTUREFILE Scan a native baseband capture file.

arguments
    filePath (1,1) string
    includeSamples (1,1) logical = false
end

try
    fileInfo = dir(filePath);
catch fileInfoException
    error("helperScanBasebandCaptureFile:FileInfoFailed", ...
        "Failed to inspect %s: %s", filePath, fileInfoException.message);
end

if isempty(fileInfo)
    error("helperScanBasebandCaptureFile:MissingFile", ...
        "Baseband file not found: %s", filePath);
end

try
    scan = localScanWithNativeReader(filePath, includeSamples, fileInfo);
    return;
catch nativeException
    if ~localCanAttemptRawFallback(nativeException)
        error("helperScanBasebandCaptureFile:ScanFailed", ...
            "Failed to scan %s with comm.BasebandFileReader: %s", ...
            filePath, nativeException.message);
    end
end

try
    scan = localScanWithRawFallback(filePath, includeSamples, fileInfo, ...
        nativeException);
catch fallbackException
    error("helperScanBasebandCaptureFile:FallbackScanFailed", ...
        "Failed to scan %s. Native reader failed with: %s " + ...
        "Raw fread fallback failed with: %s", ...
        filePath, nativeException.message, fallbackException.message);
end

end

function scan = localScanWithNativeReader(filePath, includeSamples, fileInfo)

infoReader = [];
dataReader = [];

try
    infoReader = comm.BasebandFileReader(char(filePath));
    readerInfo = info(infoReader);
    metadata = infoReader.Metadata;
    sampleRateHz = double(infoReader.SampleRate);
    centerFrequencyHz = double(infoReader.CenterFrequency);
    numChannels = double(infoReader.NumChannels);
    release(infoReader);
    infoReader = [];

    dataReader = comm.BasebandFileReader(char(filePath), ...
        readerInfo.NumSamplesInData);
    rawData = dataReader();
    release(dataReader);
    dataReader = [];

    decodeProvenance = struct();
    decodeProvenance.DecodePath = "comm.BasebandFileReader";
    decodeProvenance.PreferredReader = "comm.BasebandFileReader";
    decodeProvenance.RawFreadFallbackUsed = false;
    decodeProvenance.RawFreadFallbackReason = "";
    decodeProvenance.NativeReaderFailureCategory = "";
    decodeProvenance.NativeReaderFailureIdentifier = "";
    decodeProvenance.NativeReaderFailureMessage = "";
    decodeProvenance.HeaderVersion = "";
    decodeProvenance.HeaderDataTypeCode = NaN;
    decodeProvenance.HeaderComplexFlag = NaN;
    decodeProvenance.HeaderMetadataEncodingCode = NaN;
    decodeProvenance.MetadataTextLengthBytes = NaN;
    decodeProvenance.PayloadOffsetBytes = ...
        double(fileInfo.bytes) - localComputePayloadBytes( ...
        double(readerInfo.NumSamplesInData), numChannels, ...
        string(readerInfo.DataType), ~isreal(rawData));
    decodeProvenance.PayloadPacking = "";
    decodeProvenance.MetadataSource = ...
        "comm.BasebandFileReader metadata interface";

    scan = localBuildScanStruct(filePath, fileInfo, rawData, sampleRateHz, ...
        centerFrequencyHz, numChannels, double(readerInfo.NumSamplesInData), ...
        string(readerInfo.DataType), ~isreal(rawData), metadata, ...
        decodeProvenance, includeSamples);
catch nativeException
    if ~isempty(infoReader)
        release(infoReader);
    end

    if ~isempty(dataReader)
        release(dataReader);
    end

    rethrow(nativeException);
end

end

function scan = localScanWithRawFallback(filePath, includeSamples, fileInfo, ...
    nativeException)

[fileIdentifier, cleanupObject] = localOpenFileForRead(filePath); %#ok<ASGLU>

try
    prefixBytes = localReadExactBytes(fileIdentifier, 48, filePath, ...
        "baseband header prefix");
    headerVersion = strtrim(string(char(prefixBytes(1:16).')));
    sampleRateHz = double(typecast(uint8(prefixBytes(21:28)), "double"));
    dataTypeCode = double(typecast(uint8(prefixBytes(29:32)), "uint32"));
    complexFlag = double(typecast(uint8(prefixBytes(33:36)), "uint32"));
    centerFrequencyHz = double(typecast(uint8(prefixBytes(37:44)), "double"));
    metadataEncodingWord = typecast(uint8(prefixBytes(45:48)), "uint32");
    metadataEncodingCode = double(bitand(metadataEncodingWord, uint32(255)));
    metadataTextLengthBytes = double(bitshift(metadataEncodingWord, -8));
    metadataBytes = localReadExactBytes(fileIdentifier, ...
        metadataTextLengthBytes, filePath, "embedded metadata text");
    metadataText = string(char(metadataBytes.'));
    metadata = localParseHeaderMetadataText(metadataText);
    numChannels = localCountMetadataChannels(metadataText);
    dataType = localMapRawHeaderDataTypeCode(dataTypeCode);
    isComplexMatrix = localMapRawComplexFlag(complexFlag);
    numSamples = localResolveNumSamples(sampleRateHz, metadata.Duration_s);
    payloadBytes = localComputePayloadBytes(numSamples, numChannels, ...
        dataType, isComplexMatrix);
    payloadOffsetBytes = double(fileInfo.bytes) - payloadBytes;

    if payloadOffsetBytes < 0
        error("helperScanBasebandCaptureFile:NegativePayloadOffset", ...
            "Computed negative payload offset for %s.", filePath);
    end

    if payloadOffsetBytes < 48 + metadataTextLengthBytes
        error("helperScanBasebandCaptureFile:PayloadOverlap", ...
            [ ...
            "Computed payload offset for %s overlaps the embedded header ", ...
            "region." ...
            ], filePath);
    end

    try
        status = fseek(fileIdentifier, payloadOffsetBytes, "bof");
    catch seekException
        error("helperScanBasebandCaptureFile:SeekFailed", ...
            "Failed to seek to payload in %s: %s", filePath, ...
            seekException.message);
    end

    if status ~= 0
        error("helperScanBasebandCaptureFile:SeekFailed", ...
            "Failed to seek to payload in %s.", filePath);
    end

    bytesPerNumericValue = localDataTypeByteCount(dataType);
    payloadValueCount = payloadBytes / bytesPerNumericValue;

    if rem(payloadValueCount, 2 * numChannels) ~= 0
        error("helperScanBasebandCaptureFile:InvalidPayloadShape", ...
            "Payload length for %s is not divisible by the channel layout.", ...
            filePath);
    end

    rawNumericData = localReadExactNumericValues(fileIdentifier, ...
        payloadValueCount, "*int16", filePath, "IQ payload");
    rawMatrix = reshape(rawNumericData, 2 * numChannels, []).';
    rawData = complex(rawMatrix(:, 1:numChannels), ...
        rawMatrix(:, numChannels + 1:end));

    decodeProvenance = struct();
    decodeProvenance.DecodePath = "raw_fread_fallback";
    decodeProvenance.PreferredReader = "comm.BasebandFileReader";
    decodeProvenance.RawFreadFallbackUsed = true;
    decodeProvenance.RawFreadFallbackReason = ...
        string(strtrim(nativeException.message));
    decodeProvenance.NativeReaderFailureCategory = ...
        localClassifyNativeReaderFailure(nativeException);
    decodeProvenance.NativeReaderFailureIdentifier = ...
        string(nativeException.identifier);
    decodeProvenance.NativeReaderFailureMessage = ...
        string(strtrim(nativeException.message));
    decodeProvenance.HeaderVersion = headerVersion;
    decodeProvenance.HeaderDataTypeCode = dataTypeCode;
    decodeProvenance.HeaderComplexFlag = complexFlag;
    decodeProvenance.HeaderMetadataEncodingCode = metadataEncodingCode;
    decodeProvenance.MetadataTextLengthBytes = metadataTextLengthBytes;
    decodeProvenance.PayloadOffsetBytes = payloadOffsetBytes;
    decodeProvenance.PayloadPacking = ...
        "[I1 I2 ... In Q1 Q2 ... Qn] int16 values per sample";
    decodeProvenance.MetadataSource = "embedded baseband header text";

    scan = localBuildScanStruct(filePath, fileInfo, rawData, sampleRateHz, ...
        centerFrequencyHz, numChannels, numSamples, dataType, ...
        isComplexMatrix, metadata, decodeProvenance, includeSamples);
catch fallbackException
    clear cleanupObject
    rethrow(fallbackException);
end

clear cleanupObject

end

function scan = localBuildScanStruct(filePath, fileInfo, rawData, ...
    sampleRateHz, centerFrequencyHz, numChannels, numSamples, dataType, ...
    isComplexMatrix, metadata, decodeProvenance, includeSamples)

if size(rawData, 2) < 2
    error("helperScanBasebandCaptureFile:InsufficientChannels", ...
        "Expected at least two decoded channels in %s.", filePath);
end

payloadBytes = localComputePayloadBytes(numSamples, numChannels, dataType, ...
    isComplexMatrix);
channel1 = double(rawData(:, 1));
channel2 = double(rawData(:, 2));
channelCorrelationMagnitude = abs(sum(channel1 .* conj(channel2))) / ...
    (norm(channel1) * norm(channel2));
[channelLabels, channelLabelSource] = localResolveChannelLabels( ...
    metadata, numChannels);
dateTimeZone = localResolveMetadataTimeZone(metadata);
dateTimeLocal = datetime(string(metadata.DateTime), ...
    "InputFormat", "yyyy-MM-dd_HH-mm-ss.SSS", ...
    "TimeZone", dateTimeZone);
dateTimeUtc = dateTimeLocal;
dateTimeUtc.TimeZone = "UTC";
recordingUtcDateTime = datetime(double(metadata.RecordingUTC), ...
    "ConvertFrom", "posixtime", "TimeZone", "UTC");
edgeSampleCount = min(8, size(rawData, 1));

scan = struct();
scan.FilePath = filePath;
scan.FileBytes = double(fileInfo.bytes);
scan.SampleRate = sampleRateHz;
scan.CenterFrequency = centerFrequencyHz;
scan.NumChannels = numChannels;
scan.NumSamples = numSamples;
scan.DataType = string(dataType);
scan.IsComplex = isComplexMatrix;
scan.PayloadBytes = payloadBytes;
scan.WrapperOverheadBytes = scan.FileBytes - scan.PayloadBytes;
scan.SampleSpan_s = scan.NumSamples / scan.SampleRate;
scan.Label = string(metadata.Label);
scan.Antenna1 = channelLabels(1);
scan.Antenna2 = channelLabels(2);
scan.ChannelLabels = channelLabels;
scan.ChannelLabelSource = channelLabelSource;
scan.SessionID = string(metadata.SessionID);
scan.DateTime = string(metadata.DateTime);
scan.DateTimeVsRecording_ms = milliseconds(dateTimeUtc - ...
    recordingUtcDateTime);
scan.RecordingUTC = double(metadata.RecordingUTC);
scan.Duration_s = double(metadata.Duration_s);
scan.Repetition = localOptionalNumericMetadataValue(metadata, ...
    "Repetition", 1.0);
scan.MeanPowerCh1 = mean(abs(channel1) .^ 2);
scan.MeanPowerCh2 = mean(abs(channel2) .^ 2);
scan.ChannelCorrelationMagnitude = double(channelCorrelationMagnitude);
scan.FirstNonzeroIndexCh1 = localFirstNonzeroIndex(rawData(:, 1));
scan.FirstNonzeroIndexCh2 = localFirstNonzeroIndex(rawData(:, 2));
scan.StartSamples = rawData(1:edgeSampleCount, :);
scan.EndSamples = rawData(end - edgeSampleCount + 1:end, :);
scan.DecodePath = string(decodeProvenance.DecodePath);
scan.PreferredReader = string(decodeProvenance.PreferredReader);
scan.RawFreadFallbackUsed = logical(decodeProvenance.RawFreadFallbackUsed);
scan.RawFreadFallbackReason = ...
    string(decodeProvenance.RawFreadFallbackReason);
scan.NativeReaderFailureCategory = ...
    string(decodeProvenance.NativeReaderFailureCategory);
scan.NativeReaderFailureIdentifier = ...
    string(decodeProvenance.NativeReaderFailureIdentifier);
scan.NativeReaderFailureMessage = ...
    string(decodeProvenance.NativeReaderFailureMessage);
scan.HeaderVersion = string(decodeProvenance.HeaderVersion);
scan.HeaderDataTypeCode = double(decodeProvenance.HeaderDataTypeCode);
scan.HeaderComplexFlag = double(decodeProvenance.HeaderComplexFlag);
scan.HeaderMetadataEncodingCode = ...
    double(decodeProvenance.HeaderMetadataEncodingCode);
scan.MetadataTextLengthBytes = ...
    double(decodeProvenance.MetadataTextLengthBytes);
scan.PayloadOffsetBytes = double(decodeProvenance.PayloadOffsetBytes);
scan.PayloadPacking = string(decodeProvenance.PayloadPacking);
scan.MetadataSource = string(decodeProvenance.MetadataSource);

if includeSamples
    scan.Samples = rawData;
else
    scan.Samples = complex(int16.empty(0, 0));
end

end

function [channelLabels, source] = localResolveChannelLabels(metadata, ...
    numChannels)

channelLabels = "CH" + string(1:numChannels);
source = "generated_index_labels";

if ~isfield(metadata, "Antenna1") || ~isfield(metadata, "Antenna2")
    if isfield(metadata, "ChannelMapping")
        mapping = lower(string(metadata.ChannelMapping));

        if contains(mapping, "ch1=surveillance") && ...
                contains(mapping, "ch2=") && ...
                contains(mapping, "reference")
            channelLabels(1:2) = ["surveillance", "reference"];
            source = "embedded_channel_mapping";
        end
    end

    return;
end

antennaLabels = [string(metadata.Antenna1), string(metadata.Antenna2)];

if all(strlength(strtrim(antennaLabels)) > 0)
    channelLabels(1:2) = antennaLabels;
    source = "embedded_antenna_metadata";
end

end

function timeZone = localResolveMetadataTimeZone(metadata)

timeZone = "America/New_York";

if isfield(metadata, "DataOrigin") && ...
        contains(string(metadata.DataOrigin), "synthetic", ...
        IgnoreCase=true)
    timeZone = "UTC";
end

end

function value = localOptionalNumericMetadataValue(metadata, fieldName, ...
    defaultValue)

value = double(defaultValue);

if isfield(metadata, fieldName) && ~isempty(metadata.(fieldName))
    value = double(metadata.(fieldName));
end

end

function [fileIdentifier, cleanupObject] = localOpenFileForRead(filePath)

try
    fileIdentifier = fopen(filePath, "r");
catch openException
    error("helperScanBasebandCaptureFile:OpenFileFailed", ...
        "Failed to open %s for reading: %s", filePath, ...
        openException.message);
end

if fileIdentifier == -1
    error("helperScanBasebandCaptureFile:OpenFileFailed", ...
        "Failed to open %s for reading.", filePath);
end

cleanupObject = onCleanup(@() fclose(fileIdentifier));

end

function bytes = localReadExactBytes(fileIdentifier, count, filePath, ...
    description)

try
    bytes = fread(fileIdentifier, count, "*uint8");
catch readException
    error("helperScanBasebandCaptureFile:ReadBytesFailed", ...
        "Failed to read %s from %s: %s", description, filePath, ...
        readException.message);
end

if numel(bytes) ~= count
    error("helperScanBasebandCaptureFile:ShortRead", ...
        "Expected %d bytes for %s from %s but read %d.", count, ...
        description, filePath, numel(bytes));
end

end

function values = localReadExactNumericValues(fileIdentifier, count, ...
    precision, filePath, description)

try
    values = fread(fileIdentifier, count, precision);
catch readException
    error("helperScanBasebandCaptureFile:ReadValuesFailed", ...
        "Failed to read %s from %s: %s", description, filePath, ...
        readException.message);
end

if numel(values) ~= count
    error("helperScanBasebandCaptureFile:ShortRead", ...
        "Expected %d numeric values for %s from %s but read %d.", ...
        count, description, filePath, numel(values));
end

end

function metadata = localParseHeaderMetadataText(metadataText)

metadata = struct();
metadata.Label = localExtractQuotedMetadataValue(metadataText, "Label", "'");
metadata.Antenna1 = localExtractOptionalQuotedMetadataValue(metadataText, ...
    "Antenna1", """");
metadata.Antenna2 = localExtractOptionalQuotedMetadataValue(metadataText, ...
    "Antenna2", """");
metadata.DateTime = localExtractQuotedMetadataValue(metadataText, ...
    "DateTime", """");
metadata.SessionID = localExtractQuotedMetadataValue(metadataText, ...
    "SessionID", """");
metadata.DataOrigin = localExtractOptionalQuotedMetadataValue(metadataText, ...
    "DataOrigin", """");
metadata.RecordingUTC = localExtractNumericMetadataValue(metadataText, ...
    "RecordingUTC");
metadata.Duration_s = localExtractNumericMetadataValue(metadataText, ...
    "Duration_s");
metadata.Repetition = localExtractNumericMetadataValue(metadataText, ...
    "Repetition");

end

function value = localExtractQuotedMetadataValue(metadataText, fieldName, ...
    quoteCharacter)

pattern = string(fieldName) + "=" + quoteCharacter + ...
    "([^" + quoteCharacter + "]*)" + quoteCharacter;
token = regexp(metadataText, pattern, "tokens", "once");

if isempty(token)
    error("helperScanBasebandCaptureFile:MissingMetadataField", ...
        "Missing metadata field %s in embedded header.", fieldName);
end

value = string(token{1});

end

function value = localExtractOptionalQuotedMetadataValue(metadataText, ...
    fieldName, quoteCharacter)

pattern = string(fieldName) + "=" + quoteCharacter + ...
    "([^" + quoteCharacter + "]*)" + quoteCharacter;
token = regexp(metadataText, pattern, "tokens", "once");

if isempty(token)
    value = "";
else
    value = string(token{1});
end

end

function value = localExtractNumericMetadataValue(metadataText, fieldName)

pattern = string(fieldName) + "=([^,\\)]+)";
token = regexp(metadataText, pattern, "tokens", "once");

if isempty(token)
    error("helperScanBasebandCaptureFile:MissingMetadataField", ...
        "Missing numeric metadata field %s in embedded header.", fieldName);
end

value = str2double(token{1});

if isnan(value)
    error("helperScanBasebandCaptureFile:InvalidMetadataField", ...
        "Invalid numeric metadata value for %s.", fieldName);
end

end

function numChannels = localCountMetadataChannels(metadataText)

channelTokens = regexp(metadataText, "Antenna\d+=", "match");
numChannels = double(numel(channelTokens));

if numChannels == 0 && contains(metadataText, "DataOrigin='synthetic'")
    numChannels = 2;
end

if numChannels < 2
    error("helperScanBasebandCaptureFile:InsufficientMetadataChannels", ...
        [ ...
        "Embedded metadata indicates %d channels. Expected at least two ", ...
        "channels for G1 ingest." ...
        ], numChannels);
end

end

function value = localResolveNumSamples(sampleRateHz, durationSeconds)

value = sampleRateHz * durationSeconds;

if abs(value - round(value)) > 1e-9
    error("helperScanBasebandCaptureFile:NonIntegerSampleCount", ...
        [ ...
        "Sample rate %.15g and duration %.15g do not produce an integer ", ...
        "sample count." ...
        ], sampleRateHz, durationSeconds);
end

value = double(round(value));

end

function payloadBytes = localComputePayloadBytes(numSamples, numChannels, ...
    dataType, isComplexMatrix)

payloadBytes = double(numSamples) * double(numChannels) * ...
    localDataTypeByteCount(dataType);

if isComplexMatrix
    payloadBytes = payloadBytes * 2;
end

end

function dataType = localMapRawHeaderDataTypeCode(dataTypeCode)

switch dataTypeCode
    case 1
        dataType = "int16";
    otherwise
        error("helperScanBasebandCaptureFile:UnsupportedRawDataTypeCode", ...
            [ ...
            "Unsupported baseband header data-type code %d. Only the ", ...
            "calibrated int16 code path is implemented." ...
            ], dataTypeCode);
end

end

function isComplexMatrix = localMapRawComplexFlag(complexFlag)

switch complexFlag
    case 1
        isComplexMatrix = true;
    case 0
        isComplexMatrix = false;
    otherwise
        error("helperScanBasebandCaptureFile:UnsupportedComplexFlag", ...
            "Unsupported baseband complex flag %d.", complexFlag);
end

end

function value = localCanAttemptRawFallback(nativeException)

messageText = lower(string(nativeException.message));
identifierText = lower(string(nativeException.identifier));

value = contains(messageText, "licensing error") || ...
    contains(messageText, "communications toolbox") || ...
    contains(messageText, "unable to access required licensing services") || ...
    contains(messageText, "could not check out") || ...
    contains(messageText, "undefined function") || ...
    contains(messageText, "unrecognized function or variable") || ...
    contains(messageText, "requires communications toolbox") || ...
    contains(identifierText, "license");

value = logical(value);

end

function category = localClassifyNativeReaderFailure(nativeException)

messageText = lower(string(nativeException.message));
identifierText = lower(string(nativeException.identifier));

if contains(messageText, "licensing error") || ...
        contains(messageText, "unable to access required licensing services") || ...
        contains(messageText, "could not check out") || ...
        contains(identifierText, "license")
    category = "licensing_or_service_unavailable";
elseif contains(messageText, "undefined function") || ...
        contains(messageText, "unrecognized function or variable") || ...
        contains(messageText, "requires communications toolbox")
    category = "toolbox_unavailable";
else
    category = "native_reader_unavailable";
end

end

function value = localDataTypeByteCount(dataType)

switch string(dataType)
    case {"int8", "uint8"}
        value = 1;
    case {"int16", "uint16"}
        value = 2;
    case {"int32", "uint32", "single"}
        value = 4;
    case {"int64", "uint64", "double"}
        value = 8;
    otherwise
        error("helperScanBasebandCaptureFile:UnsupportedDataType", ...
            "Unsupported baseband numeric type: %s", dataType);
end

end

function index = localFirstNonzeroIndex(channelData)

index = find(channelData ~= 0, 1, "first");

if isempty(index)
    index = NaN;
else
    index = double(index);
end

end
