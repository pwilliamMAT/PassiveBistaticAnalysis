function [comparisonSnapshot, snapshotPath, bundleRoot] = ...
    helperLoadLatestComparisonSnapshot(datasetId, stageArtifactId, repoRoot)
%HELPERLOADLATESTCOMPARISONSNAPSHOT Load the latest saved stage snapshot.

arguments
    datasetId (1,1) string
    stageArtifactId (1,1) string
    repoRoot (1,1) string
end

stageRoot = fullfile(repoRoot, "artifacts", datasetId, stageArtifactId);

if ~isfolder(stageRoot)
    error("helperLoadLatestComparisonSnapshot:MissingStageRoot", ...
        "Missing comparison snapshot for dataset %s stage %s. " + ...
        "No artifact root exists at %s. Run the single-session stage " + ...
        "runner first.", datasetId, stageArtifactId, stageRoot);
end

dirInfo = dir(stageRoot);
dirInfo = dirInfo([dirInfo.isdir]);
folderNames = string({dirInfo.name});
folderNames = folderNames(folderNames ~= "." & folderNames ~= "..");
folderNames = sort(folderNames);
folderNames = flipud(folderNames(:));

snapshotPath = "";
bundleRoot = "";

for idx = 1:numel(folderNames)
    candidateBundleRoot = fullfile(stageRoot, folderNames(idx));
    candidateSnapshotPath = fullfile(candidateBundleRoot, ...
        "comparison_snapshot.mat");

    if isfile(candidateSnapshotPath)
        bundleRoot = string(candidateBundleRoot);
        snapshotPath = string(candidateSnapshotPath);
        break
    end
end

if strlength(snapshotPath) == 0
    error("helperLoadLatestComparisonSnapshot:MissingSnapshot", ...
        "Missing comparison snapshot for dataset %s stage %s. " + ...
        "Expected comparison_snapshot.mat inside %s. Run the " + ...
        "single-session stage runner first.", ...
        datasetId, stageArtifactId, stageRoot);
end

loadedData = load(snapshotPath, "comparisonSnapshot");

if ~isfield(loadedData, "comparisonSnapshot")
    error("helperLoadLatestComparisonSnapshot:InvalidSnapshot", ...
        "Invalid comparison snapshot at %s. Variable " + ...
        "comparisonSnapshot was not found.", snapshotPath);
end

comparisonSnapshot = loadedData.comparisonSnapshot;
comparisonSnapshot.DatasetId = string(comparisonSnapshot.DatasetId);
comparisonSnapshot.StageId = string(comparisonSnapshot.StageId);
comparisonSnapshot.RunTimestampZ = string(comparisonSnapshot.RunTimestampZ);
comparisonSnapshot.BundleRoot = string(comparisonSnapshot.BundleRoot);

if isfield(comparisonSnapshot, "SummaryTable")
    comparisonSnapshot.SummaryTable = localNormalizeSummaryTable( ...
        comparisonSnapshot.SummaryTable);
end

end

function summaryTable = localNormalizeSummaryTable(summaryTable)

if ~istable(summaryTable)
    error("helperLoadLatestComparisonSnapshot:InvalidSummaryTable", ...
        "Comparison snapshot SummaryTable must be a MATLAB table.");
end

if ~ismember("DisplayOrder", summaryTable.Properties.VariableNames)
    summaryTable.DisplayOrder = (1:height(summaryTable)).';
end

summaryTable.MetricId = string(summaryTable.MetricId);
summaryTable.MetricLabel = string(summaryTable.MetricLabel);
summaryTable.ValueType = string(summaryTable.ValueType);
summaryTable.TextValue = string(summaryTable.TextValue);
summaryTable.Units = string(summaryTable.Units);
summaryTable.Notes = string(summaryTable.Notes);
summaryTable.DisplayOrder = double(summaryTable.DisplayOrder);

end
