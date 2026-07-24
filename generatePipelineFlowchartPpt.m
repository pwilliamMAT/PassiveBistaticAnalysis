function outputPath = generatePipelineFlowchartPpt(projectRoot, outputPath)
%GENERATEPIPELINEFLOWCHARTPPT Build an editable PowerPoint deck from the flowchart markdown.

if nargin < 1 || strlength(string(projectRoot)) == 0
    projectRoot = fileparts(mfilename("fullpath"));
end

projectRoot = char(string(projectRoot));

if nargin < 2 || strlength(string(outputPath)) == 0
    outputDir = fullfile(projectRoot, "artifacts", "ppt");
    if ~isfolder(outputDir)
        mkdir(outputDir);
    end

    outputPath = fullfile(outputDir, "PipelineFlowchart.pptx");
else
    outputPath = char(string(outputPath));
    outputDir = fileparts(outputPath);

    if ~isempty(outputDir) && ~isfolder(outputDir)
        mkdir(outputDir);
    end
end

markdownPath = fullfile(projectRoot, "docs", "flowcharts", "PipelineFlowchart.md");

try
    spec = helperParsePipelineFlowchartMarkdown(markdownPath);
    layout = helperBuildPipelinePptLayout(spec, projectRoot, outputPath);
    helperCreatePipelineFlowchartPpt(layout, outputPath);
catch ME
    error( ...
        "generatePipelineFlowchartPpt:GenerationFailed", ...
        "Failed to generate PowerPoint from %s.\n%s", ...
        markdownPath, ...
        getReport(ME, "extended", "hyperlinks", "off") ...
    );
end

fprintf("Generated PowerPoint artifact:\n\t%s\n", outputPath);
end
