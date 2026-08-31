function results = runDirectPathQuickView( ...
    baselineDatasetId, candidateDatasetId, options)
%RUNDIRECTPATHQUICKVIEW Print an evidence-first direct-path comparison.
%
%   RUNDIRECTPATHQUICKVIEW(BASELINEID, CANDIDATEID) analyzes centered
%   125 ms windows from the first, middle, and last repetitions.
%
%   RUNDIRECTPATHQUICKVIEW(..., struct("Mode", "confirm")) analyzes every
%   manifest-listed repetition. Set PrintRepetitions true to print every
%   selected repetition in addition to aggregate statistics.

arguments
    baselineDatasetId (1,1) string
    candidateDatasetId (1,1) string
    options (1,1) struct = struct()
end

repoRoot = string(fileparts(mfilename("fullpath")));
printRepetitions = localGetLogicalOption(options, ...
    "PrintRepetitions", false);
printOutput = localGetLogicalOption(options, "PrintOutput", true);
analysisOptions = options;

if isfield(analysisOptions, "PrintRepetitions")
    analysisOptions = rmfield(analysisOptions, "PrintRepetitions");
end

if isfield(analysisOptions, "PrintOutput")
    analysisOptions = rmfield(analysisOptions, "PrintOutput");
end

results = helperAnalyzeDirectPathQuickView(baselineDatasetId, ...
    candidateDatasetId, repoRoot, analysisOptions);

if printOutput
    localPrintResults(results, printRepetitions);
end

end

function value = localGetLogicalOption(options, fieldName, defaultValue)

value = defaultValue;

if isfield(options, fieldName)
    value = options.(fieldName);
end

if ~(islogical(value) && isscalar(value))
    error("runDirectPathQuickView:InvalidPrintOption", ...
        "%s must be a scalar logical.", fieldName);
end

end

function localPrintResults(results, printRepetitions)

fprintf("\nDIRECT-PATH QUICK VIEW\n");
fprintf("Baseline: %s\n", results.BaselineDatasetId);
fprintf("Candidate: %s\n", results.CandidateDatasetId);
fprintf("Mode: %s | %s: %.3f s\n", ...
    upper(results.Mode), results.WindowDescription, ...
    results.WindowDuration_s);
fprintf("Selected repetitions: BASE=[%s] CAND=[%s]\n", ...
    localJoinNumbers(results.Baseline.SelectedRepetitions), ...
    localJoinNumbers(results.Candidate.SelectedRepetitions));
fprintf("Mapping: REF=%s  SURV=%s\n", ...
    results.Mapping.Reference, results.Mapping.Surveillance);
fprintf("Gain: baseline=%s  candidate=%s  [manifest]\n\n", ...
    results.Baseline.ManifestGainSpec, ...
    results.Candidate.ManifestGainSpec);

localPrintComparisonTable(results.ComparisonTable);
localPrintDispersion(results.BaselineDatasetId, ...
    results.Baseline.ChannelSummaryTable);
localPrintDispersion(results.CandidateDatasetId, ...
    results.Candidate.ChannelSummaryTable);
localPrintPairwiseTable(results.PairwiseComparisonTable);
localPrintPairwiseDispersion(results.BaselineDatasetId, ...
    results.Baseline.PairwiseSummaryTable);
localPrintPairwiseDispersion(results.CandidateDatasetId, ...
    results.Candidate.PairwiseSummaryTable);

if printRepetitions
    localPrintRepetitions(results.Baseline, results.MetricDefinitions);
    localPrintRepetitions(results.Candidate, results.MetricDefinitions);
end

localPrintEvidence(results.EvidenceTable);
localPrintConclusion(results);

end

function localPrintComparisonTable(comparisonTable)

fprintf("%-37s %10s %10s %10s %10s %10s %10s %9s %9s %9s\n", ...
    "METRIC [unit]", "BASE REF", "BASE SURV", "BASE R-S", ...
    "CAND REF", "CAND SURV", "CAND R-S", ...
    "DeltaREF", "DeltaSURV", "Delta(R-S)");

for rowIndex = 1:height(comparisonTable)
    row = comparisonTable(rowIndex, :);
    metricLabel = row.DisplayName + " [" + row.Unit + "]";
    baselineDifference = localFormatDifference(row, ...
        row.BaselineReferenceMinusSurveillance);
    candidateDifference = localFormatDifference(row, ...
        row.CandidateReferenceMinusSurveillance);
    differenceOfDifferences = localFormatDifference(row, ...
        row.DeltaReferenceMinusSurveillance);
    fprintf("%-37s %10s %10s %10s %10s %10s %10s %9s %9s %9s\n", ...
        metricLabel, ...
        localFormatValue(row.BaselineReference, row.DisplayFormat), ...
        localFormatValue(row.BaselineSurveillance, row.DisplayFormat), ...
        baselineDifference, ...
        localFormatValue(row.CandidateReference, row.DisplayFormat), ...
        localFormatValue(row.CandidateSurveillance, row.DisplayFormat), ...
        candidateDifference, ...
        localFormatSignedValue(row.DeltaReference, row.DisplayFormat), ...
        localFormatSignedValue(row.DeltaSurveillance, row.DisplayFormat), ...
        differenceOfDifferences);
end

fprintf("\nR-S is computed per repetition and then summarized by the median.\n");
fprintf("For occupied bandwidth, PAR, headroom, clipping, DC, and IQ " + ...
    "quality, R-S and Delta(R-S) are N/A: evaluate channels separately.\n");

end

function text = localFormatDifference(row, value)

if row.DifferenceApplicable
    text = localFormatSignedValue(value, row.DisplayFormat);
else
    text = "N/A";
end

end

function localPrintDispersion(datasetId, summaryTable)

fprintf("\nDISPERSION %s (IQR; min..max)\n", datasetId);

for rowIndex = 1:height(summaryTable)
    row = summaryTable(rowIndex, :);
    metricLabel = row.DisplayName + " [" + row.Unit + "]";
    referenceText = localFormatStats(row.ReferenceIQR, ...
        row.ReferenceMin, row.ReferenceMax, row.DisplayFormat);
    surveillanceText = localFormatStats(row.SurveillanceIQR, ...
        row.SurveillanceMin, row.SurveillanceMax, row.DisplayFormat);

    if row.DifferenceApplicable
        differenceText = localFormatStats( ...
            row.ReferenceMinusSurveillanceIQR, ...
            row.ReferenceMinusSurveillanceMin, ...
            row.ReferenceMinusSurveillanceMax, row.DisplayFormat);
    else
        differenceText = row.DifferenceNote;
    end

    fprintf("  %-37s REF %s | SURV %s | R-S %s\n", ...
        metricLabel, referenceText, surveillanceText, differenceText);
end

end

function localPrintPairwiseTable(tableIn)

fprintf("\n%-40s %11s %11s %11s\n", ...
    "PAIRWISE METRIC", "BASELINE", "CANDIDATE", "CHANGE");

for rowIndex = 1:height(tableIn)
    row = tableIn(rowIndex, :);
    metricLabel = row.DisplayName + " [" + row.Unit + "]";
    fprintf("%-40s %11s %11s %11s\n", metricLabel, ...
        localFormatValue(row.Baseline, row.DisplayFormat), ...
        localFormatValue(row.Candidate, row.DisplayFormat), ...
        localFormatSignedValue(row.Change, row.DisplayFormat));
end

fprintf("Pairwise measurements are informational and do not determine antenna improvement.\n");

end

function localPrintPairwiseDispersion(datasetId, tableIn)

fprintf("\nPAIRWISE DISPERSION %s (IQR; min..max)\n", datasetId);

for rowIndex = 1:height(tableIn)
    row = tableIn(rowIndex, :);
    metricLabel = row.DisplayName + " [" + row.Unit + "]";
    fprintf("  %-40s %s\n", metricLabel, ...
        localFormatStats(row.IQR, row.Min, row.Max, row.DisplayFormat));
end

end

function localPrintRepetitions(session, definitions)

fprintf("\nSELECTED REPETITIONS %s\n", session.DatasetId);
referenceRows = session.ChannelMetricTable( ...
    session.ChannelMetricTable.Role == "reference", :);
surveillanceRows = session.ChannelMetricTable( ...
    session.ChannelMetricTable.Role == "surveillance", :);

for repetitionIndex = 1:height(referenceRows)
    fprintf("  Repetition %.0f\n", referenceRows.Repetition(repetitionIndex));

    for metricIndex = 1:height(definitions)
        definition = definitions(metricIndex, :);
        fieldName = char(definition.FieldName);
        referenceValue = referenceRows.(fieldName)(repetitionIndex);
        surveillanceValue = ...
            surveillanceRows.(fieldName)(repetitionIndex);

        if definition.DifferenceApplicable
            differenceText = localFormatSignedValue( ...
                referenceValue - surveillanceValue, ...
                definition.DisplayFormat);
        else
            differenceText = definition.DifferenceNote;
        end

        fprintf("    %-37s REF %s | SURV %s | R-S %s\n", ...
            definition.DisplayName + " [" + definition.Unit + "]", ...
            localFormatValue(referenceValue, definition.DisplayFormat), ...
            localFormatValue(surveillanceValue, ...
            definition.DisplayFormat), differenceText);
    end
end

end

function localPrintEvidence(evidenceTable)

fprintf("\nAPPLIED CRITERIA\n");

for rowIndex = 1:height(evidenceTable) - 2
    row = evidenceTable(rowIndex, :);
    fprintf("%s\n", row.Check);
    fprintf("  Observed: %s [%s]\n", row.ObservedValues, row.Units);
    fprintf("  Direction: %s\n", row.ComparisonDirection);
    fprintf("  Criterion: %s [%s]\n", row.Criterion, row.Source);
    fprintf("  Result: %s -- %s\n", row.Result, row.Explanation);
end

end

function localPrintConclusion(results)

trend = results.Trend;
localization = results.LocalizationSuitability;
fprintf("\nObserved reference-path trend: %s\n", trend.Label);
fprintf("Observed: %s [%s]\n", trend.ObservedValues, trend.Units);
fprintf("Why: %s\n", trend.Explanation);
fprintf("Direction: %s\n", trend.ComparisonDirection);
fprintf("Criterion: %s [%s]\n", trend.Criterion, trend.Source);
fprintf("Localization suitability: %s -- %s.\n", ...
    localization.Label, localization.Criterion);
fprintf("Localization evidence: %s [%s]; %s\n\n", ...
    localization.ObservedValues, localization.Units, ...
    localization.Explanation);

end

function text = localFormatValue(value, formatText)

text = string(sprintf(char(formatText), value));

end

function text = localFormatSignedValue(value, formatText)

unsignedFormat = char(formatText);

if startsWith(unsignedFormat, "%")
    signedFormat = "%+" + extractAfter(string(unsignedFormat), 1);
else
    signedFormat = "%+.3g";
end

text = string(sprintf(char(signedFormat), value));

end

function text = localFormatStats(iqrValue, minValue, maxValue, formatText)

text = "IQR=" + localFormatValue(iqrValue, formatText) + ...
    "; " + localFormatValue(minValue, formatText) + ".." + ...
    localFormatValue(maxValue, formatText);

end

function text = localJoinNumbers(values)

text = strjoin(compose("%.0f", values), ",");

end
