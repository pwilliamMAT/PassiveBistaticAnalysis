function colorValue = helperHexToPptColor(hexColor)
%HELPERHEXTOPPTCOLOR Convert a hex RGB color string into a PowerPoint RGB integer.

arguments
    hexColor (1, :) char
end

normalizedColor = erase(hexColor, "#");

if strlength(string(normalizedColor)) ~= 6
    error( ...
        "helperHexToPptColor:InvalidColor", ...
        "Expected a 6-digit hex color, but received %s", ...
        hexColor ...
    );
end

redValue = hex2dec(normalizedColor(1:2));
greenValue = hex2dec(normalizedColor(3:4));
blueValue = hex2dec(normalizedColor(5:6));

colorValue = redValue + bitshift(greenValue, 8) + bitshift(blueValue, 16);
end
