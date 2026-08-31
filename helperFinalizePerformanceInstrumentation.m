function [timingSummaryTable, performanceSummary] = ...
    helperFinalizePerformanceInstrumentation(stageId, datasetId, ...
    bundleRoot, runTimestampZ, executionMode, showFigures, timingRows, ...
    totalTimer, inputSampleCount, inputRepetitionCount, metricsMatPath)
%HELPERFINALIZEPERFORMANCEINSTRUMENTATION Write timing artifacts.

arguments
    stageId (1,1) string
    datasetId (1,1) string
    bundleRoot (1,1) string
    runTimestampZ (1,1) string
    executionMode (1,1) string
    showFigures (1,1) logical
    timingRows (1,:) struct
    totalTimer
    inputSampleCount (1,1) double = NaN
    inputRepetitionCount (1,1) double = NaN
    metricsMatPath (1,1) string = ""
end

performanceTimer = tic;
bundleSummary = localSummarizeBundleOutputs(bundleRoot);
totalRow = helperMakeTimingSummaryRow(stageId, "total", ...
    toc(totalTimer), executionMode, inputSampleCount, ...
    inputRepetitionCount, bundleSummary.ArtifactCount, ...
    bundleSummary.FigureCount, bundleSummary.OutputBytes, ...
    "Preliminary total before performance artifact write.");
timingSummaryTable = struct2table([totalRow, timingRows]);
performanceSummary = localBuildPerformanceSummary(stageId, datasetId, ...
    bundleRoot, runTimestampZ, executionMode, showFigures, ...
    timingSummaryTable, bundleSummary);

timingSummaryPath = fullfile(bundleRoot, "timing_summary.csv");
performanceSummaryPath = fullfile(bundleRoot, ...
    "performance_summary.json");
localWriteTimingArtifacts(timingSummaryPath, performanceSummaryPath, ...
    timingSummaryTable, performanceSummary);

if strlength(metricsMatPath) > 0 && isfile(metricsMatPath)
    localAppendTimingToMetricsMat(metricsMatPath, timingSummaryTable, ...
        performanceSummary);
end

performanceArtifactElapsed_s = toc(performanceTimer);
timingRows(end + 1) = helperMakeTimingSummaryRow(stageId, ...
    "write_performance_artifacts", performanceArtifactElapsed_s, ...
    executionMode, inputSampleCount, inputRepetitionCount, 2, 0, NaN, ...
    "timing_summary.csv; performance_summary.json");
bundleSummary = localSummarizeBundleOutputs(bundleRoot);
totalRow = helperMakeTimingSummaryRow(stageId, "total", ...
    toc(totalTimer), executionMode, inputSampleCount, ...
    inputRepetitionCount, bundleSummary.ArtifactCount, ...
    bundleSummary.FigureCount, bundleSummary.OutputBytes, "");
timingSummaryTable = struct2table([totalRow, timingRows]);
performanceSummary = localBuildPerformanceSummary(stageId, datasetId, ...
    bundleRoot, runTimestampZ, executionMode, showFigures, ...
    timingSummaryTable, bundleSummary);

localWriteTimingArtifacts(timingSummaryPath, performanceSummaryPath, ...
    timingSummaryTable, performanceSummary);

if strlength(metricsMatPath) > 0 && isfile(metricsMatPath)
    localAppendTimingToMetricsMat(metricsMatPath, timingSummaryTable, ...
        performanceSummary);
end

end

function performanceSummary = localBuildPerformanceSummary(stageId, ...
    datasetId, bundleRoot, runTimestampZ, executionMode, showFigures, ...
    timingSummaryTable, bundleSummary)

totalMask = timingSummaryTable.StepName == "total";
totalElapsed_s = NaN;

if any(totalMask)
    totalElapsed_s = timingSummaryTable.Elapsed_s(find(totalMask, 1, ...
        "first"));
end

performanceSummary = struct();
performanceSummary.dataset_id = datasetId;
performanceSummary.stage_id = stageId;
performanceSummary.run_timestamp_z = runTimestampZ;
performanceSummary.bundle_root = bundleRoot;
performanceSummary.execution_mode = executionMode;
performanceSummary.show_figures = showFigures;
performanceSummary.input_sample_count = ...
    timingSummaryTable.InputSampleCount(1);
performanceSummary.input_repetition_count = ...
    timingSummaryTable.InputRepetitionCount(1);
performanceSummary.total_elapsed_s = totalElapsed_s;
performanceSummary.timed_step_count = height(timingSummaryTable) - 1;
performanceSummary.output_artifact_count = bundleSummary.ArtifactCount;
performanceSummary.output_figure_count = bundleSummary.FigureCount;
performanceSummary.output_bytes = bundleSummary.OutputBytes;
performanceSummary.timing_summary_path = fullfile(bundleRoot, ...
    "timing_summary.csv");
performanceSummary.performance_summary_path = fullfile(bundleRoot, ...
    "performance_summary.json");
performanceSummary.timing_schema = [ ...
    "StageId", ...
    "StepName", ...
    "Elapsed_s", ...
    "ExecutionMode", ...
    "InputSampleCount", ...
    "InputRepetitionCount", ...
    "OutputArtifactCount", ...
    "OutputFigureCount", ...
    "OutputBytes", ...
    "Notes"];
performanceSummary.matlab_version = string(version);
performanceSummary.matlab_release = string(version("-release"));
performanceSummary.computer = string(computer);
performanceSummary.generated_utc = string(datetime("now", ...
    "TimeZone", "UTC", "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'"));

end

function bundleSummary = localSummarizeBundleOutputs(bundleRoot)

fileListing = dir(fullfile(bundleRoot, "**", "*"));
fileListing = fileListing(~[fileListing.isdir]);
artifactCount = numel(fileListing);
outputBytes = 0;
figureCount = 0;

if artifactCount > 0
    outputBytes = sum(double([fileListing.bytes]));
    fileNames = string({fileListing.name}).';
    [~, ~, extensions] = fileparts(fileNames);
    figureExtensions = [".fig", ".jpg", ".jpeg", ".pdf", ".png"];
    figureCount = nnz(ismember(lower(extensions), figureExtensions));
end

bundleSummary = struct();
bundleSummary.ArtifactCount = double(artifactCount);
bundleSummary.FigureCount = double(figureCount);
bundleSummary.OutputBytes = double(outputBytes);

end

function localWriteTimingArtifacts(timingSummaryPath, ...
    performanceSummaryPath, timingSummaryTable, performanceSummary)

try
    writetable(timingSummaryTable, timingSummaryPath);
catch writeException
    error("helperFinalizePerformanceInstrumentation:WriteTimingFailed", ...
        "Failed to write %s: %s", timingSummaryPath, ...
        writeException.message);
end

try
    jsonText = jsonencode(performanceSummary, PrettyPrint = true);
catch encodeException
    error("helperFinalizePerformanceInstrumentation:JsonEncodeFailed", ...
        "Failed to encode %s: %s", performanceSummaryPath, ...
        encodeException.message);
end

localWriteTextFile(performanceSummaryPath, jsonText);

end

function localAppendTimingToMetricsMat(metricsMatPath, timingSummaryTable, ...
    performanceSummary)

try
    save(metricsMatPath, "timingSummaryTable", "performanceSummary", ...
        "-append");
catch saveException
    error("helperFinalizePerformanceInstrumentation:AppendMetricsFailed", ...
        "Failed to append timing outputs to %s: %s", metricsMatPath, ...
        saveException.message);
end

end

function localWriteTextFile(filePath, lines)

try
    fileIdentifier = fopen(filePath, "w");
catch openException
    error("helperFinalizePerformanceInstrumentation:OpenTextFileFailed", ...
        "Failed to open %s for writing: %s", filePath, ...
        openException.message);
end

if fileIdentifier == -1
    error("helperFinalizePerformanceInstrumentation:OpenTextFileFailed", ...
        "Failed to open %s for writing.", filePath);
end

cleanupObject = onCleanup(@() fclose(fileIdentifier));
lines = string(lines);

for idx = 1:numel(lines)
    fprintf(fileIdentifier, "%s\n", lines(idx));
end

clear cleanupObject

end
