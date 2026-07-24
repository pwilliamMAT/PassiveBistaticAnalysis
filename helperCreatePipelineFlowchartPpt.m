function helperCreatePipelineFlowchartPpt(layout, outputPath)
%HELPERCREATEPIPELINEFLOWCHARTPPT Create the PowerPoint deck using COM automation.

arguments
    layout (1, 1) struct
    outputPath (1, :) char
end

pptApplication = [];
presentation = [];

if isfile(outputPath)
    delete(outputPath);
end

try
    pptApplication = actxserver("PowerPoint.Application");
    pptApplication.Visible = 1;

    presentation = invoke(pptApplication.Presentations, "Add");

    for slideIndex = 1:numel(layout.Slides)
        slideSpec = layout.Slides(slideIndex);
        slide = invoke(presentation.Slides, "Add", slideIndex, 12);

        for textIndex = 1:numel(slideSpec.Texts)
            helperAddPptText(slide, slideSpec.Texts(textIndex));
        end

        for boxIndex = 1:numel(slideSpec.Boxes)
            helperAddPptBox(slide, slideSpec.Boxes(boxIndex));
        end

        for lineIndex = 1:numel(slideSpec.Lines)
            helperAddPptLine(slide, slideSpec.Lines(lineIndex));
        end
    end

    invoke(presentation, "SaveAs", outputPath);
    invoke(presentation, "Close");
    invoke(pptApplication, "Quit");
    delete(pptApplication);
catch ME
    if ~isempty(presentation)
        try
            invoke(presentation, "Close");
        catch
        end
    end

    if ~isempty(pptApplication)
        try
            invoke(pptApplication, "Quit");
        catch
        end

        try
            delete(pptApplication);
        catch
        end
    end

    error( ...
        "helperCreatePipelineFlowchartPpt:ComFailure", ...
        "PowerPoint COM generation failed for %s.\n%s", ...
        outputPath, ...
        getReport(ME, "extended", "hyperlinks", "off") ...
    );
end
end
