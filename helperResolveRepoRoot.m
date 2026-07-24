function repoRoot = helperResolveRepoRoot(candidateRoot)
%HELPERRESOLVEREPOROOT Resolve the real project root from likely anchors.

arguments
    candidateRoot (1,1) string = ""
end

candidateRoots = [ ...
    string(candidateRoot); ...
    string(pwd); ...
    localPathFromWhich("loadIQData"); ...
    localPathFromWhich("runG1Ingest"); ...
    localPathFromWhich("runPassiveBistaticPipeline"); ...
    string(fileparts(mfilename("fullpath"))) ...
    ];
candidateRoots = unique(candidateRoots(strlength(candidateRoots) > 0), "stable");

for idx = 1:numel(candidateRoots)
    repoRoot = localFindRepoRoot(candidateRoots(idx));
    if strlength(repoRoot) > 0
        return;
    end
end

error("helperResolveRepoRoot:RepoRootNotFound", ...
    "Unable to resolve the PassiveBistaticRestart repo root.");

end

function repoRoot = localFindRepoRoot(candidateRoot)

repoRoot = "";
currentPath = string(candidateRoot);

if strlength(currentPath) == 0
    return;
end

if isfile(currentPath)
    currentPath = string(fileparts(currentPath));
end

while strlength(currentPath) > 0 && isfolder(currentPath)
    if localIsRepoRoot(currentPath)
        repoRoot = currentPath;
        return;
    end

    parentPath = string(fileparts(currentPath));
    if parentPath == currentPath
        return;
    end

    currentPath = parentPath;
end

end

function tf = localIsRepoRoot(candidateRoot)

tf = isfile(fullfile(candidateRoot, "ProjectPlan.md")) && ...
    isfile(fullfile(candidateRoot, "README.md")) && ...
    isfile(fullfile(candidateRoot, "docs", "checkpoints", "G1_Ingest.md")) && ...
    isfile(fullfile(candidateRoot, "20260622T102123", "session_manifest.json"));

end

function resolvedPath = localPathFromWhich(name)

whichResult = which(name);

if isempty(whichResult)
    resolvedPath = "";
    return;
end

resolvedPath = string(fileparts(whichResult));

end
