function selection = helperResolvePartSelection(partSelection, ...
    radarRelativePaths)
%HELPERRESOLVEPARTSELECTION Resolve the bounded synthetic part selection.

arguments
    partSelection
    radarRelativePaths (:,1) string
end

if isempty(radarRelativePaths)
    error("helperResolvePartSelection:EmptyPackage", ...
        "At least one radar path is required.");
end

packagePartCount = numel(radarRelativePaths);

if (isstring(partSelection) || ischar(partSelection)) && ...
        isscalar(string(partSelection))
    normalizedText = lower(strtrim(string(partSelection)));

    if normalizedText ~= "all"
        error("helperResolvePartSelection:InvalidPartSelection", ...
            "PartSelection text must be ""all"".");
    end

    selectedManifestIndices = (1:packagePartCount).';
    requested = "all";
elseif isnumeric(partSelection) && isscalar(partSelection) && ...
        isfinite(partSelection) && partSelection == 1
    selectedManifestIndices = 1;
    requested = "1";
else
    error("helperResolvePartSelection:InvalidPartSelection", ...
        "PartSelection must be part 1 or ""all"".");
end

selection = struct();
selection.Requested = requested;
selection.PackagePartCount = packagePartCount;
selection.SelectedPartCount = numel(selectedManifestIndices);
selection.SelectedManifestIndices = selectedManifestIndices;
selection.SelectedRadarRelativePaths = ...
    radarRelativePaths(selectedManifestIndices);
selection.ExpectedRepetitions = selectedManifestIndices;
selection.AllPartsSelected = ...
    numel(selectedManifestIndices) == packagePartCount;

end
