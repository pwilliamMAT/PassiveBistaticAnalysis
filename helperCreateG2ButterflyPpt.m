function helperCreateG2ButterflyPpt(layout, pptPath, pngPath)
%HELPERCREATEG2BUTTERFLYPPT Create the G2 butterfly PPT and export slide 1 as PNG.

arguments
    layout (1, 1) struct
    pptPath (1, :) char
    pngPath (1, :) char
end

pptApplication = [];
presentation = [];

if isfile(pptPath)
    delete(pptPath);
end

if isfile(pngPath)
    delete(pngPath);
end

try
    pptApplication = actxserver("PowerPoint.Application");
    pptApplication.Visible = 1;

    presentation = invoke(pptApplication.Presentations, "Add");
    presentation.PageSetup.SlideWidth = layout.SlideWidth;
    presentation.PageSetup.SlideHeight = layout.SlideHeight;

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

    invoke(presentation, "SaveAs", pptPath);

    exportSlide = invoke(presentation.Slides, "Item", layout.ExportSlideIndex);
    invoke(exportSlide, "Export", pngPath, "PNG", 1920, 1080);

    invoke(presentation, "Close");
    invoke(pptApplication, "Quit");
    delete(pptApplication);
catch createException
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

    error("helperCreateG2ButterflyPpt:GenerationFailed", ...
        "PowerPoint generation failed for %s and %s.\n%s", ...
        pptPath, ...
        pngPath, ...
        getReport(createException, "extended", "hyperlinks", "off"));
end
end
