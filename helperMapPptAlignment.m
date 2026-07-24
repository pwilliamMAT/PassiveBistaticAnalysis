function alignmentValue = helperMapPptAlignment(alignmentName)
%HELPERMAPPPTALIGNMENT Map string alignment names to PowerPoint paragraph constants.

arguments
    alignmentName (1, :) char
end

switch lower(strtrim(alignmentName))
    case "center"
        alignmentValue = 2;
    case "right"
        alignmentValue = 3;
    otherwise
        alignmentValue = 1;
end
end
