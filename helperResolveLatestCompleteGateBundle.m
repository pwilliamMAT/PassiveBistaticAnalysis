function bundle = helperResolveLatestCompleteGateBundle( ...
    datasetId, artifactId, repoRoot, requiredFiles)
%HELPERRESOLVELATESTCOMPLETEGATEBUNDLE Find newest complete gate bundle.
%
%   BUNDLE = HELPERRESOLVELATESTCOMPLETEGATEBUNDLE(DATASETID,
%   ARTIFACTID, REPOROOT, REQUIREDFILES) searches
%   artifacts/DATASETID/ARTIFACTID and returns the newest timestamped
%   bundle containing every relative file listed in REQUIREDFILES.

arguments
    datasetId (1,1) string
    artifactId (1,1) string
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    requiredFiles (:,1) string = strings(0, 1)
end

repoRoot = helperResolveRepoRoot(repoRoot);
datasetId = string(datasetId);
artifactId = string(artifactId);
requiredFiles = string(requiredFiles(:));
artifactRoot = fullfile(repoRoot, "artifacts", datasetId, artifactId);

if ~isfolder(artifactRoot)
    error("helperResolveLatestCompleteGateBundle:MissingArtifactRoot", ...
        "Missing artifact root for dataset %s and artifact %s at %s. Run the corresponding gate runner first.", ...
        datasetId, artifactId, artifactRoot);
end

candidateNames = localListCandidateFolders(artifactRoot);

if isempty(candidateNames)
    error("helperResolveLatestCompleteGateBundle:NoCandidateBundles", ...
        "No timestamped artifact bundles were found at %s. Run the corresponding gate runner first.", ...
        artifactRoot);
end

incompleteBundleTable = table( ...
    strings(0, 1), strings(0, 1), strings(0, 1), ...
    VariableNames = {'RunTimestampZ', 'BundleRoot', 'MissingFiles'});

for candidateIndex = 1:numel(candidateNames)
    runTimestampZ = candidateNames(candidateIndex);
    bundleRoot = string(fullfile(artifactRoot, runTimestampZ));
    missingFiles = localMissingRequiredFiles(bundleRoot, requiredFiles);

    if isempty(missingFiles)
        bundle = struct();
        bundle.DatasetId = datasetId;
        bundle.ArtifactId = artifactId;
        bundle.ArtifactRoot = string(artifactRoot);
        bundle.RunTimestampZ = runTimestampZ;
        bundle.BundleRoot = bundleRoot;
        bundle.RequiredFiles = requiredFiles;
        bundle.IncompleteBundleTable = incompleteBundleTable;
        bundle.CheckedRunTimestampsZ = candidateNames(1:candidateIndex);
        return
    end

    missingSummary = strjoin(missingFiles, "; ");
    skippedRow = table( ...
        runTimestampZ, bundleRoot, missingSummary, ...
        VariableNames = {'RunTimestampZ', 'BundleRoot', 'MissingFiles'});
    incompleteBundleTable = [incompleteBundleTable; skippedRow]; %#ok<AGROW>
end

detailText = localBuildIncompleteDetail(incompleteBundleTable);
error("helperResolveLatestCompleteGateBundle:NoCompleteBundle", ...
    "No complete artifact bundle was found at %s. Missing files by skipped timestamp:%s%s", ...
    artifactRoot, newline, detailText);

end

function candidateNames = localListCandidateFolders(artifactRoot)

dirInfo = dir(artifactRoot);
dirInfo = dirInfo([dirInfo.isdir]);
candidateNames = string({dirInfo.name});
candidateNames = candidateNames(candidateNames ~= "." & candidateNames ~= "..");
candidateNames = sort(candidateNames(:), "descend");

end

function missingFiles = localMissingRequiredFiles(bundleRoot, requiredFiles)

if isempty(requiredFiles)
    missingFiles = strings(0, 1);
    return
end

requiredPaths = fullfile(bundleRoot, requiredFiles);
existsMask = isfile(requiredPaths);
missingFiles = requiredFiles(~existsMask);

end

function detailText = localBuildIncompleteDetail(incompleteBundleTable)

if isempty(incompleteBundleTable)
    detailText = "";
    return
end

detailLines = incompleteBundleTable.RunTimestampZ + ": " + ...
    incompleteBundleTable.MissingFiles;
detailText = strjoin(detailLines, newline);

end
