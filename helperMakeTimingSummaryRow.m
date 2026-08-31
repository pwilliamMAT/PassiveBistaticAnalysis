function timingRow = helperMakeTimingSummaryRow(stageId, stepName, ...
    elapsed_s, executionMode, inputSampleCount, inputRepetitionCount, ...
    outputArtifactCount, outputFigureCount, outputBytes, notes)
%HELPERMAKETIMINGSUMMARYROW Create one common timing-summary row.

arguments
    stageId (1,1) string
    stepName (1,1) string
    elapsed_s (1,1) double
    executionMode (1,1) string
    inputSampleCount (1,1) double = NaN
    inputRepetitionCount (1,1) double = NaN
    outputArtifactCount (1,1) double = NaN
    outputFigureCount (1,1) double = NaN
    outputBytes (1,1) double = NaN
    notes (1,1) string = ""
end

timingRow = struct();
timingRow.StageId = stageId;
timingRow.StepName = stepName;
timingRow.Elapsed_s = elapsed_s;
timingRow.ExecutionMode = executionMode;
timingRow.InputSampleCount = inputSampleCount;
timingRow.InputRepetitionCount = inputRepetitionCount;
timingRow.OutputArtifactCount = outputArtifactCount;
timingRow.OutputFigureCount = outputFigureCount;
timingRow.OutputBytes = outputBytes;
timingRow.Notes = notes;

end
