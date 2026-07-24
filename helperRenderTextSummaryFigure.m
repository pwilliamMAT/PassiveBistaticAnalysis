function helperRenderTextSummaryFigure(lines, titleText, outputPath)
%HELPERRENDERTEXTSUMMARYFIGURE Render a text summary into a PNG figure.

arguments
    lines string
    titleText (1,1) string
    outputPath (1,1) string
end

figureHandle = [];

try
    lines = lines(:);
    lines = lines(strlength(lines) > 0);

    if isempty(lines)
        lines = "No content available.";
    end

    lineCount = numel(lines);
    figureHeight = max(600, 24 * lineCount + 180);
    figureHandle = figure( ...
        "Visible", "off", ...
        "Color", "w", ...
        "Position", [100 100 1800 figureHeight]);
    axesHandle = axes(figureHandle);
    xlim(axesHandle, [0 1]);
    ylim(axesHandle, [0 lineCount + 1]);
    axesHandle.XTick = [];
    axesHandle.YTick = [];
    box(axesHandle, "on");
    xlabel(axesHandle, "Normalized Horizontal Position");
    ylabel(axesHandle, "Summary Row Index");
    title(axesHandle, titleText, "Interpreter", "none");

    for idx = 1:lineCount
        yPosition = lineCount - idx + 1;
        text(axesHandle, 0.01, yPosition, lines(idx), ...
            "Interpreter", "none", ...
            "FontName", "Courier New", ...
            "FontSize", 10, ...
            "VerticalAlignment", "middle");
    end

    exportgraphics(figureHandle, outputPath, "Resolution", 150);
    close(figureHandle);
catch renderException
    if ~isempty(figureHandle) && isvalid(figureHandle)
        close(figureHandle);
    end

    error("helperRenderTextSummaryFigure:RenderFailed", ...
        "Failed to render %s: %s", outputPath, renderException.message);
end

end
