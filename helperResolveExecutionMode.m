function executionMode = helperResolveExecutionMode(options)
%HELPERRESOLVEEXECUTIONMODE Resolve supported runner execution modes.

arguments
    options (1,1) struct = struct()
end

executionMode = "review";

if isfield(options, "ExecutionMode")
    executionMode = lower(strtrim(string(options.ExecutionMode)));
end

validModes = ["review", "analysis_only", "profile"];

if ~ismember(executionMode, validModes)
    error("helperResolveExecutionMode:InvalidExecutionMode", ...
        "ExecutionMode must be review, analysis_only, or profile.");
end

end
