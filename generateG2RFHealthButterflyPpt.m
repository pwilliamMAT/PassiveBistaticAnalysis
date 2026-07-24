function [pptPath, pngPath] = generateG2RFHealthButterflyPpt(projectRoot, pptPath, pngPath)
%GENERATEG2RFHEALTHBUTTERFLYPPT Build the G2 butterfly PPT and PNG artifacts.

if nargin < 1 || strlength(string(projectRoot)) == 0
    projectRoot = fileparts(mfilename("fullpath"));
end

projectRoot = helperResolveRepoRoot(string(projectRoot));

if nargin < 2 || strlength(string(pptPath)) == 0
    communicationDir = fullfile(projectRoot, "artifacts", "communication", ...
        "G2_RF_Health");

    if ~isfolder(communicationDir)
        mkdir(communicationDir);
    end

    pptPath = fullfile(communicationDir, "G2_RF_Health_Butterfly.pptx");
else
    pptPath = char(string(pptPath));
    pptDir = fileparts(pptPath);

    if ~isempty(pptDir) && ~isfolder(pptDir)
        mkdir(pptDir);
    end
end

if nargin < 3 || strlength(string(pngPath)) == 0
    pngPath = fullfile(fileparts(char(string(pptPath))), ...
        "G2_RF_Health_Butterfly.png");
else
    pngPath = char(string(pngPath));
    pngDir = fileparts(pngPath);

    if ~isempty(pngDir) && ~isfolder(pngDir)
        mkdir(pngDir);
    end
end

markdownPath = fullfile(projectRoot, "docs", "flowcharts", ...
    "G2_RF_Health_Butterfly.md");

try
    spec = helperParseG2ButterflyMarkdown(markdownPath);
    layout = helperBuildG2ButterflyPptLayout(spec, projectRoot, ...
        char(string(pptPath)));
    helperCreateG2ButterflyPpt(layout, char(string(pptPath)), ...
        char(string(pngPath)));
catch generationException
    error("generateG2RFHealthButterflyPpt:GenerationFailed", ...
        "Failed to generate the G2 butterfly assets from %s.\n%s", ...
        markdownPath, ...
        getReport(generationException, "extended", "hyperlinks", "off"));
end

fprintf("Generated G2 butterfly artifacts:\n\t%s\n\t%s\n", ...
    char(string(pptPath)), char(string(pngPath)));
end
