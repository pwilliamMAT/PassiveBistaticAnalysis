function [pptPath, pngPath] = generateG2RFHealthCustomerFlowPpt(projectRoot, pptPath, pngPath)
%GENERATEG2RFHEALTHCUSTOMERFLOWPPT Build the customer-facing G2 PPT and PNG artifacts.

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

    pptPath = fullfile(communicationDir, "G2_RF_Health_CustomerFlow.pptx");
else
    pptPath = char(string(pptPath));
    pptDir = fileparts(pptPath);

    if ~isempty(pptDir) && ~isfolder(pptDir)
        mkdir(pptDir);
    end
end

if nargin < 3 || strlength(string(pngPath)) == 0
    pngPath = fullfile(fileparts(char(string(pptPath))), ...
        "G2_RF_Health_CustomerFlow.png");
else
    pngPath = char(string(pngPath));
    pngDir = fileparts(pngPath);

    if ~isempty(pngDir) && ~isfolder(pngDir)
        mkdir(pngDir);
    end
end

markdownPath = fullfile(projectRoot, "docs", "flowcharts", ...
    "G2_RF_Health_CustomerFlow.md");

try
    spec = helperParseG2CustomerFlowMarkdown(markdownPath);
    layout = helperBuildG2CustomerFlowPptLayout(spec, projectRoot, ...
        char(string(pptPath)));
    helperCreateG2CustomerFlowPpt(layout, char(string(pptPath)), ...
        char(string(pngPath)));
catch generationException
    error("generateG2RFHealthCustomerFlowPpt:GenerationFailed", ...
        "Failed to generate the G2 customer-flow assets from %s.\n%s", ...
        markdownPath, ...
        getReport(generationException, "extended", "hyperlinks", "off"));
end

fprintf("Generated G2 customer-flow artifacts:\n\t%s\n\t%s\n", ...
    char(string(pptPath)), char(string(pngPath)));
end
