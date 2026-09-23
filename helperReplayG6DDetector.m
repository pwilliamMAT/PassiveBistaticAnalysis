function replayResult = helperReplayG6DDetector( ...
    detectorReplaySession, detectorConfiguration)
%HELPERREPLAYG6DDETECTOR Replay CFAR, NMS, and post-hoc association only.
%
%   REPLAYRESULT = HELPERREPLAYG6DDETECTOR(SESSION, CONFIGURATION) reuses
%   in-memory map products from a completed field-background full run. It
%   does not regenerate trajectory, IQ, CPI, maps, or LMS products.

arguments
    detectorReplaySession (1,1) struct
    detectorConfiguration (1,1) struct = ...
        helperBuildG6DDetectorConfiguration()
end

requiredFields = [ ...
    "SchemaVersion", "MapProducts", "TruthTable", "Context", ...
    "ContainsRawIq"];

for fieldIndex = 1:numel(requiredFields)
    if ~isfield(detectorReplaySession, requiredFields(fieldIndex))
        error("helperReplayG6DDetector:Session", ...
            "Replay session is missing %s.", requiredFields(fieldIndex));
    end
end

if detectorReplaySession.ContainsRawIq
    error("helperReplayG6DDetector:RawIq", ...
        "Detector replay sessions must not contain raw IQ.");
end

context = detectorReplaySession.Context;
context.DetectorConfiguration = detectorConfiguration;
context.Finalize = true;

replayResult = helperAnalyzeG6ProductDiscrimination( ...
    detectorReplaySession.MapProducts, ...
    detectorReplaySession.TruthTable, context);

end
