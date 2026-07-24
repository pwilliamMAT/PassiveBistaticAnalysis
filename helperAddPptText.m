function textBox = helperAddPptText(slide, textSpec)
%HELPERADDPPTTEXT Add a PowerPoint text box with optional border and fill.

arguments
    slide
    textSpec (1, 1) struct
end

textBox = invoke( ...
    slide.Shapes, ...
    "AddTextbox", ...
    1, ...
    textSpec.X, ...
    textSpec.Y, ...
    textSpec.Width, ...
    textSpec.Height ...
);

textBox.TextFrame.TextRange.Text = char(string(textSpec.Text));
textBox.TextFrame.TextRange.Font.Name = "Aptos";
textBox.TextFrame.TextRange.Font.Size = textSpec.FontSize;
textBox.TextFrame.TextRange.Font.Bold = double(textSpec.Bold);
textBox.TextFrame.TextRange.Font.Italic = double(textSpec.Italic);
textBox.TextFrame.TextRange.Font.Color.RGB = helperHexToPptColor(textSpec.FontColor);
textBox.TextFrame.TextRange.ParagraphFormat.Alignment = helperMapPptAlignment(textSpec.Align);
textBox.TextFrame.WordWrap = 1;
textBox.TextFrame.AutoSize = 0;
textBox.TextFrame.MarginLeft = 4;
textBox.TextFrame.MarginRight = 4;
textBox.TextFrame.MarginTop = 2;
textBox.TextFrame.MarginBottom = 2;

if strlength(string(textSpec.FillColor)) == 0
    textBox.Fill.Visible = 0;
else
    textBox.Fill.Visible = 1;
    textBox.Fill.ForeColor.RGB = helperHexToPptColor(textSpec.FillColor);
end

if strlength(string(textSpec.LineColor)) == 0
    textBox.Line.Visible = 0;
else
    textBox.Line.Visible = 1;
    textBox.Line.ForeColor.RGB = helperHexToPptColor(textSpec.LineColor);
    textBox.Line.Weight = 1;
end
end
