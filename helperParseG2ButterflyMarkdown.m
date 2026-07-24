function spec = helperParseG2ButterflyMarkdown(markdownPath)
%HELPERPARSEG2BUTTERFLYMARKDOWN Parse the G2 butterfly Markdown sections.

arguments
    markdownPath (1, :) char
end

try
    rawText = fileread(markdownPath);
catch readException
    error("helperParseG2ButterflyMarkdown:ReadFailed", ...
        "Unable to read %s.\n%s", ...
        markdownPath, ...
        getReport(readException, "basic", "hyperlinks", "off"));
end

titleTokens = regexp(rawText, "^#\s+(?<title>[^\r\n]+)", ...
    "names", "once", "lineanchors");

if isempty(titleTokens)
    error("helperParseG2ButterflyMarkdown:MissingTitle", ...
        "The Markdown file is missing a top-level title: %s", markdownPath);
end

lines = splitlines(string(rawText));
sectionStruct = struct();
currentField = "";

for lineIndex = 1:numel(lines)
    trimmedLine = strtrim(lines(lineIndex));

    if startsWith(trimmedLine, "## ")
        sectionName = extractAfter(trimmedLine, 3);
        currentField = localNormalizeSectionName(sectionName);
        sectionStruct.(currentField) = strings(0, 1);
        continue;
    end

    if strlength(currentField) == 0
        continue;
    end

    if startsWith(trimmedLine, "- ")
        bulletText = strtrim(extractAfter(trimmedLine, 2));
        bulletText = strrep(bulletText, "`", "");
        currentValues = sectionStruct.(currentField);
        currentValues(end + 1, 1) = bulletText;
        sectionStruct.(currentField) = currentValues;
    end
end

requiredFields = [ ...
    "Overview"; ...
    "LeftWing"; ...
    "Center"; ...
    "RightWing"; ...
    "FlowSteps"; ...
    "EvidenceOutputs"; ...
    "VisualNotes" ...
    ];

for fieldIndex = 1:numel(requiredFields)
    currentField = requiredFields(fieldIndex);

    if ~isfield(sectionStruct, currentField) || ...
            isempty(sectionStruct.(currentField))
        error("helperParseG2ButterflyMarkdown:MissingSection", ...
            "Required section %s is missing or empty in %s", ...
            currentField, markdownPath);
    end
end

spec = struct();
spec.Title = string(titleTokens.title);
spec.MarkdownPath = string(markdownPath);
spec.Overview = sectionStruct.Overview;
spec.LeftWing = sectionStruct.LeftWing;
spec.Center = sectionStruct.Center;
spec.RightWing = sectionStruct.RightWing;
spec.FlowSteps = sectionStruct.FlowSteps;
spec.EvidenceOutputs = sectionStruct.EvidenceOutputs;
spec.VisualNotes = sectionStruct.VisualNotes;
end

function fieldName = localNormalizeSectionName(sectionName)

fieldName = matlab.lang.makeValidName(char(strrep(string(sectionName), " ", "")));
fieldName = string(fieldName);
end
