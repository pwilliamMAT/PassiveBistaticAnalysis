function shape = helperAddPptBox(slide, boxSpec)
%HELPERADDPPTBOX Add a PowerPoint shape with centered text.

arguments
    slide
    boxSpec (1, 1) struct
end

shape = invoke( ...
    slide.Shapes, ...
    "AddShape", ...
    boxSpec.ShapeType, ...
    boxSpec.X, ...
    boxSpec.Y, ...
    boxSpec.Width, ...
    boxSpec.Height ...
);

shape.Fill.ForeColor.RGB = helperHexToPptColor(boxSpec.FillColor);
shape.Line.ForeColor.RGB = helperHexToPptColor(boxSpec.LineColor);
shape.Line.Weight = 1.25;
shape.TextFrame.TextRange.Text = char(string(boxSpec.Text));
shape.TextFrame.TextRange.Font.Name = "Aptos";
shape.TextFrame.TextRange.Font.Size = boxSpec.FontSize;
shape.TextFrame.TextRange.Font.Bold = double(boxSpec.Bold);
shape.TextFrame.TextRange.Font.Color.RGB = helperHexToPptColor(boxSpec.FontColor);
shape.TextFrame.TextRange.ParagraphFormat.Alignment = helperMapPptAlignment(boxSpec.Align);
shape.TextFrame.WordWrap = 1;
shape.TextFrame.AutoSize = 0;
shape.TextFrame.MarginLeft = 4;
shape.TextFrame.MarginRight = 4;
shape.TextFrame.MarginTop = 3;
shape.TextFrame.MarginBottom = 3;

if isfield(boxSpec, "VerticalAnchor") && ~isempty(boxSpec.VerticalAnchor)
    shape.TextFrame.VerticalAnchor = boxSpec.VerticalAnchor;
else
    shape.TextFrame.VerticalAnchor = 3;
end
end
