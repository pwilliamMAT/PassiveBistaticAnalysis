function spec = helperParsePipelineFlowchartMarkdown(markdownPath)
%HELPERPARSEPIPELINEFLOWCHARTMARKDOWN Parse nodes and edges from the Mermaid block.

arguments
    markdownPath (1, :) char
end

try
    rawText = fileread(markdownPath);
catch ME
    error( ...
        "helperParsePipelineFlowchartMarkdown:ReadFailed", ...
        "Unable to read %s.\n%s", ...
        markdownPath, ...
        getReport(ME, "basic", "hyperlinks", "off") ...
    );
end

titleTokens = regexp(rawText, "^#\s+(?<title>[^\r\n]+)", "names", "once", "lineanchors");
mermaidTokens = regexp(rawText, "```mermaid\s*(?<body>[\s\S]*?)```", "names", "once");

if isempty(titleTokens) || isempty(mermaidTokens)
    error( ...
        "helperParsePipelineFlowchartMarkdown:InvalidSource", ...
        "The flowchart markdown file is missing a title or Mermaid block: %s", ...
        markdownPath ...
    );
end

lines = splitlines(string(mermaidTokens.body));

nodeLines = startsWith(strtrim(lines), ["G", "I", "C", "R", "D", "M"]);
edgeLines = contains(lines, "-->") | contains(lines, ".->");

nodes = repmat(struct("Id", "", "Label", ""), 1, nnz(nodeLines));
edges = repmat(struct("Source", "", "Target", "", "Label", "", "Style", ""), 1, nnz(edgeLines));

nodeCount = 0;
edgeCount = 0;

for lineIndex = 1:numel(lines)
    lineText = strtrim(lines(lineIndex));

    if strlength(lineText) == 0
        continue;
    end

    nodeTokens = regexp(char(lineText), "^(?<id>[A-Z0-9]+)\[""(?<label>.+)""\]$", "names", "once");
    if ~isempty(nodeTokens)
        nodeCount = nodeCount + 1;
        nodes(nodeCount) = struct( ...
            "Id", nodeTokens.id, ...
            "Label", nodeTokens.label ...
        );
        continue;
    end

    edgeTokens = regexp( ...
        char(lineText), ...
        "^(?<src>[A-Z0-9]+)\s+(?<style>-->|-\.\->)\|(?<label>[^|]+)\|\s+(?<dst>[A-Z0-9]+)$", ...
        "names", ...
        "once" ...
    );

    if isempty(edgeTokens)
        edgeTokens = regexp( ...
            char(lineText), ...
            "^(?<src>[A-Z0-9]+)\s+-\.\s*(?<label>[^.]+?)\s*\.\->\s+(?<dst>[A-Z0-9]+)$", ...
            "names", ...
            "once" ...
        );

        if ~isempty(edgeTokens)
            edgeTokens.style = "-.->";
        end
    end

    if ~isempty(edgeTokens)
        edgeCount = edgeCount + 1;
        edges(edgeCount) = struct( ...
            "Source", edgeTokens.src, ...
            "Target", edgeTokens.dst, ...
            "Label", strtrim(edgeTokens.label), ...
            "Style", edgeTokens.style ...
        );
    end
end

nodes = nodes(1:nodeCount);
edges = edges(1:edgeCount);

if isempty(nodes)
    error( ...
        "helperParsePipelineFlowchartMarkdown:NoNodesFound", ...
        "No Mermaid nodes were parsed from %s", ...
        markdownPath ...
    );
end

labelMap = containers.Map("KeyType", "char", "ValueType", "char");

for nodeIndex = 1:numel(nodes)
    labelMap(nodes(nodeIndex).Id) = nodes(nodeIndex).Label;
end

spec = struct;
spec.Title = titleTokens.title;
spec.MarkdownPath = markdownPath;
spec.Nodes = nodes;
spec.Edges = edges;
spec.LabelMap = labelMap;
end
