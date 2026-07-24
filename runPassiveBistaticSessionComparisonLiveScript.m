% Passive Bistatic G1/G2 Session Comparison
%
% This live script is for hardware-change evaluation only.
% It compares saved G1, G2 Stage 1, and G2 Stage 2 artifacts from two
% sessions and does not replace the single-session gate review.

%%
% Comparison Setup
% Edit the baseline or candidate dataset IDs here before running the
% comparison sections. The baseline remains the approved single-session
% reference, while the candidate should be the hardware-iteration session
% you want to compare against it.
baselineDatasetId = "20260622T102123";
candidateDatasetId = "20260713T150404";
repoRoot = helperResolveRepoRoot();
comparisonOptions = struct("ShowFigures", usejava("desktop"));
comparisonResults = [];
setupSummary = table( ...
    baselineDatasetId, candidateDatasetId, repoRoot, ...
    "artifact_only_hardware_change_evaluation", ...
    "Does not replace the single-session gate review", ...
    VariableNames = {'BaselineDatasetId', 'CandidateDatasetId', ...
    'RepoRoot', 'Mode', 'Reminder'});
setupSummary

%%
% G1 Comparison
% This section loads the latest saved G1 comparison snapshots for the
% baseline and candidate sessions and shows the normalized G1 delta table.
comparisonResults = localEnsureComparisonResults(comparisonResults, ...
    baselineDatasetId, candidateDatasetId, repoRoot, comparisonOptions);
comparisonResults.G1ComparisonTable

%%
% G2 Stage 1 Comparison
% This section shows the artifact-only comparison for acquisition-evidence
% verdicts, role-source summary, and the key Stage 1 scalar metrics.
comparisonResults = localEnsureComparisonResults(comparisonResults, ...
    baselineDatasetId, candidateDatasetId, repoRoot, comparisonOptions);
comparisonResults.G2Stage1ComparisonTable

%%
% G2 Stage 2 Comparison
% This section shows the artifact-only Stage 2 comparison table.
% The underlying runner also generates the visible Stage 2 comparison
% figures when ShowFigures is true in desktop MATLAB.
comparisonResults = localEnsureComparisonResults(comparisonResults, ...
    baselineDatasetId, candidateDatasetId, repoRoot, comparisonOptions);
comparisonResults.G2Stage2ComparisonTable

%%
% Hardware-Iteration Summary
% This section keeps the summary focused on hardware-change evaluation
% rather than later-gate approval.
comparisonResults = localEnsureComparisonResults(comparisonResults, ...
    baselineDatasetId, candidateDatasetId, repoRoot, comparisonOptions);
comparisonResults.OverallSummaryTable
hardwareIterationNote = localBuildInterpretationTable( ...
    comparisonResults.InterpretationNoteLines);
hardwareIterationNote

%%
% G3 Sync Comparison Placeholder
% Preserve the later-gate comparison placeholder. No artifact-only
% cross-session comparison is implemented yet for G3.
g3ComparisonPlaceholder = localBuildPlaceholderSummaryTable( ...
    "G3 Sync Comparison", "not_implemented", ...
    "Preserved placeholder only. Cross-session comparison is currently " + ...
    "limited to saved G1, G2 Stage 1, and G2 Stage 2 artifacts.");
g3ComparisonPlaceholder

%%
% G4 Passive Baseline Map Comparison Placeholder
% Preserve the later-gate comparison placeholder. No comparison workflow
% is implemented yet for passive baseline maps.
g4ComparisonPlaceholder = localBuildPlaceholderSummaryTable( ...
    "G4 Passive Baseline Map Comparison", "not_implemented", ...
    "Preserved placeholder only. No saved cross-session G4 map " + ...
    "comparison path is implemented yet.");
g4ComparisonPlaceholder

%%
% G5 Mitigation Comparison Placeholder
% Preserve the later-gate comparison placeholder. No mitigation comparison
% workflow is implemented yet.
g5ComparisonPlaceholder = localBuildPlaceholderSummaryTable( ...
    "G5 Mitigation Comparison", "not_implemented", ...
    "Preserved placeholder only. Cross-session mitigation comparison " + ...
    "has not been opened yet.");
g5ComparisonPlaceholder

%%
% G6 CPI Integration Comparison Placeholder
% Preserve the later-gate comparison placeholder. No CPI/integration
% comparison workflow is implemented yet.
g6ComparisonPlaceholder = localBuildPlaceholderSummaryTable( ...
    "G6 CPI Integration Comparison", "not_implemented", ...
    "Preserved placeholder only. Cross-session CPI or integration " + ...
    "comparison has not been implemented yet.");
g6ComparisonPlaceholder

%%
% G7 Truth Alignment Comparison Placeholder
% Preserve the later-gate comparison placeholder. No truth-alignment
% comparison workflow is implemented yet.
g7ComparisonPlaceholder = localBuildPlaceholderSummaryTable( ...
    "G7 Truth Alignment Comparison", "not_implemented", ...
    "Preserved placeholder only. Cross-session truth-alignment " + ...
    "comparison has not been implemented yet.");
g7ComparisonPlaceholder

%%
% G8 Detection Comparison Placeholder
% Preserve the later-gate comparison placeholder. No detector-comparison
% workflow is implemented yet.
g8ComparisonPlaceholder = localBuildPlaceholderSummaryTable( ...
    "G8 Detection Comparison", "not_implemented", ...
    "Preserved placeholder only. Cross-session detector comparison " + ...
    "has not been implemented yet.");
g8ComparisonPlaceholder

%%
% G9 Tracker Readiness Comparison Placeholder
% Preserve the later-gate comparison placeholder. No tracker-readiness
% comparison workflow is implemented yet.
g9ComparisonPlaceholder = localBuildPlaceholderSummaryTable( ...
    "G9 Tracker Readiness Comparison", "not_implemented", ...
    "Preserved placeholder only. Cross-session tracker-readiness " + ...
    "comparison has not been implemented yet.");
g9ComparisonPlaceholder

%%
% G10 Tracking Truth Validation Comparison Placeholder
% Preserve the later-gate comparison placeholder. No tracking or
% truth-validation comparison workflow is implemented yet.
g10ComparisonPlaceholder = localBuildPlaceholderSummaryTable( ...
    "G10 Tracking Truth Validation Comparison", "not_implemented", ...
    "Preserved placeholder only. Cross-session tracking or truth " + ...
    "validation comparison has not been implemented yet.");
g10ComparisonPlaceholder

function comparisonResults = localEnsureComparisonResults( ...
    comparisonResults, baselineDatasetId, candidateDatasetId, repoRoot, ...
    comparisonOptions)

if ~isempty(comparisonResults)
    return
end

comparisonResults = runG1G2SessionComparison(baselineDatasetId, ...
    candidateDatasetId, repoRoot, comparisonOptions);

end

function interpretationTable = localBuildInterpretationTable(noteLines)

interpretationTable = table(string(noteLines(:)), ...
    'VariableNames', {'InterpretationLine'});

end

function placeholderTable = localBuildPlaceholderSummaryTable(stageName, ...
    status, reason)

placeholderTable = table(string(stageName), string(status), string(reason), ...
    'VariableNames', {'Stage', 'Status', 'Reason'});

end
