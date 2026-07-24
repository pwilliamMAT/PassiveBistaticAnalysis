function logInfo = helperParseG2CaptureLog(logPath)
%HELPERPARSEG2CAPTURELOG Parse Stage 1 acquisition evidence from a capture log.

arguments
    logPath (1,1) string
end

try
    logText = string(fileread(logPath));
catch readException
    error("helperParseG2CaptureLog:ReadFailed", ...
        "Failed to read capture log %s: %s", logPath, ...
        readException.message);
end

lines = splitlines(logText);
lines = strtrim(lines);
lines = lines(strlength(lines) > 0);

deviceArgs = localParseDeviceArgs(lines);
roundInfo = localParseRoundInfo(lines);
plannedInfo = localParsePlannedLine(lines);
warningLines = lines(startsWith(lines, "[WARNING]"));
captureFilePaths = localCollectCaptureFilePaths(lines);
lowerLines = lower(lines);

logInfo = struct();
logInfo.LogPath = logPath;
logInfo.LogPresent = true;
logInfo.SessionId = localExtractAfterPrefix(lines, ...
    "Session ID (use in analyzeBistaticData):");
logInfo.CaptureSessionId = localExtractAfterPrefix(lines, ...
    "CAPTURE_SESSION_ID=");
logInfo.SessionIdsAgree = ...
    strlength(logInfo.SessionId) > 0 && ...
    strlength(logInfo.CaptureSessionId) > 0 && ...
    logInfo.SessionId == logInfo.CaptureSessionId;
logInfo.Dtg = localExtractAfterPrefix(lines, ...
    "date time group (DTG) for this capture:");
logInfo.SelectedAntennas = localExtractAfterPrefix(lines, ...
    "Selected Antennas:");
logInfo.PlannedDuration_s = plannedInfo.Duration_s;
logInfo.PlannedSampleRate_Msps = plannedInfo.SampleRate_Msps;
logInfo.PlannedChannelCount = plannedInfo.ChannelCount;
logInfo.RadioProduct = localGetDeviceArg(deviceArgs, "product");
logInfo.RadioSerial = localGetDeviceArg(deviceArgs, "serial");
logInfo.RadioName = localGetDeviceArg(deviceArgs, "name");
logInfo.RadioType = localGetDeviceArg(deviceArgs, "type");
logInfo.RadioMgmtAddress = localGetDeviceArg(deviceArgs, "mgmt_addr");
logInfo.RadioAddress = localGetDeviceArg(deviceArgs, "addr");
logInfo.ClockSource = localGetDeviceArg(deviceArgs, "clock_source");
logInfo.TimeSource = localGetDeviceArg(deviceArgs, "time_source");
logInfo.MasterClockRate_Hz = str2double(localGetDeviceArg(deviceArgs, ...
    "master_clock_rate"));
logInfo.CaptureRecordingUTC = str2double(localExtractAfterPrefix(lines, ...
    "CAPTURE_RECORDING_UTC="));
logInfo.UhdInfoLine = localFindLineContaining(lines, "[INFO] [UHD]");
logInfo.WarningLines = warningLines;
logInfo.WarningCount = numel(warningLines);
logInfo.RoundNumbers = roundInfo.RoundNumbers;
logInfo.RoundTotal = roundInfo.RoundTotal;
logInfo.RoundCount = roundInfo.RoundCount;
logInfo.CollectionStartedCount = nnz(lines == "Collection Started...");
logInfo.CaptureFileCount = numel(captureFilePaths);
logInfo.CaptureFilePaths = captureFilePaths;
logInfo.ContainsOverrunText = localHasAnyPattern(lowerLines, ...
    ["overrun", "overflow", "dropped sample", "dropped-sample"]);
logInfo.ContainsLockStatusText = localHasAnyPattern(lowerLines, ...
    ["lock status", "ref lock", "gps lock", "locked"]);
logInfo.ContainsAgcText = localHasAnyPattern(lowerLines, ...
    ["agc", "manual gain", "gain mode"]);
logInfo.ContainsMappingVerificationText = localHasAnyPattern(lowerLines, ...
    ["mapping verification", "injected tone", "channel swap", ...
    "reference antenna", "surveillance antenna"]);

end

function deviceArgs = localParseDeviceArgs(lines)

deviceArgs = struct();
deviceArgLine = localFindLineContaining(lines, ...
    "Initializing 1 device(s) in parallel with args:");

if strlength(deviceArgLine) == 0
    return
end

argText = extractAfter(deviceArgLine, "args:");
tokens = split(argText, ",");

for idx = 1:numel(tokens)
    token = strtrim(tokens(idx));
    tokenText = char(token);
    parts = regexp(tokenText, "^(?<Key>[^=]+)=(?<Value>.*)$", ...
        "names", "once");

    if isempty(parts)
        continue
    end

    fieldName = matlab.lang.makeValidName(strtrim(parts.Key));
    deviceArgs.(fieldName) = string(strtrim(parts.Value));
end

end

function roundInfo = localParseRoundInfo(lines)

roundNumbers = zeros(numel(lines), 1);
roundTotals = zeros(numel(lines), 1);
roundCount = 0;

for idx = 1:numel(lines)
    token = regexp(char(lines(idx)), ...
        "^--- Capture Round (\d+) of (\d+) ---$", "tokens", "once");

    if isempty(token)
        continue
    end

    roundCount = roundCount + 1;
    roundNumbers(roundCount) = str2double(token{1});
    roundTotals(roundCount) = str2double(token{2});
end

roundNumbers = roundNumbers(1:roundCount);
roundTotals = roundTotals(1:roundCount);

roundInfo = struct();
roundInfo.RoundNumbers = roundNumbers;
roundInfo.RoundCount = roundCount;

if isempty(roundTotals)
    roundInfo.RoundTotal = NaN;
else
    roundInfo.RoundTotal = roundTotals(end);
end

end

function plannedInfo = localParsePlannedLine(lines)

plannedInfo = struct();
plannedInfo.Duration_s = NaN;
plannedInfo.SampleRate_Msps = NaN;
plannedInfo.ChannelCount = NaN;

plannedLine = localExtractAfterPrefix(lines, "Planned:");

if strlength(plannedLine) == 0
    return
end

token = regexp(char(plannedLine), ...
    "^\s*([0-9.]+)\s*s\s*@\s*([0-9.]+)\s*MSps\s*\((\d+)\s*Ch\)", ...
    "tokens", "once");

if isempty(token)
    return
end

plannedInfo.Duration_s = str2double(token{1});
plannedInfo.SampleRate_Msps = str2double(token{2});
plannedInfo.ChannelCount = str2double(token{3});

end

function captureFilePaths = localCollectCaptureFilePaths(lines)

captureFilePaths = strings(0, 1);

for idx = 1:numel(lines)
    if ~startsWith(lines(idx), "CAPTURE_FILE_")
        continue
    end

    token = regexp(char(lines(idx)), "^CAPTURE_FILE_\d+=(.*)$", ...
        "tokens", "once");

    if isempty(token)
        continue
    end

    captureFilePaths(end + 1, 1) = string(strtrim(token{1})); %#ok<AGROW>
end

end

function value = localExtractAfterPrefix(lines, prefix)

value = "";
matchIndex = find(startsWith(lines, prefix), 1, "first");

if isempty(matchIndex)
    return
end

value = strtrim(extractAfter(lines(matchIndex), prefix));

end

function line = localFindLineContaining(lines, pattern)

line = "";
matchIndex = find(contains(lines, pattern), 1, "first");

if isempty(matchIndex)
    return
end

line = lines(matchIndex);

end

function value = localGetDeviceArg(deviceArgs, fieldName)

value = "";

if isfield(deviceArgs, fieldName)
    value = string(deviceArgs.(fieldName));
end

end

function value = localHasAnyPattern(lines, patterns)

value = false;

for idx = 1:numel(patterns)
    if any(contains(lines, patterns(idx)))
        value = true;
        return
    end
end

end
