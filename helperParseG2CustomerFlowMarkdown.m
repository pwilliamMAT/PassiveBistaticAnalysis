function spec = helperParseG2CustomerFlowMarkdown(markdownPath)
%HELPERPARSEG2CUSTOMERFLOWMARKDOWN Parse the G2 customer-flow Markdown sections.

arguments
    markdownPath (1, :) char
end

try
    rawText = fileread(markdownPath);
catch readException
    error("helperParseG2CustomerFlowMarkdown:ReadFailed", ...
        "Unable to read %s.\n%s", ...
        markdownPath, ...
        getReport(readException, "basic", "hyperlinks", "off"));
end

titleTokens = regexp(rawText, "^#\s+(?<title>[^\r\n]+)", ...
    "names", "once", "lineanchors");

if isempty(titleTokens)
    error("helperParseG2CustomerFlowMarkdown:MissingTitle", ...
        "The Markdown file is missing a top-level title: %s", markdownPath);
end

sections = localReadSections(rawText);
overview = strings(0, 1);
outputs = strings(0, 1);
visualNotes = strings(0, 1);
stages = repmat(localStageTemplate(), 0, 1);

for sectionIndex = 1:numel(sections)
    sectionTitle = sections(sectionIndex).Title;

    switch sectionTitle
        case "Overview"
            overview = sections(sectionIndex).Bullets;
        case "Outputs"
            outputs = sections(sectionIndex).Bullets;
        case "Visual Notes"
            visualNotes = sections(sectionIndex).Bullets;
        otherwise
            if startsWith(sectionTitle, "Stage ")
                stages(end + 1, 1) = localParseStageSection( ...
                    sectionTitle, sections(sectionIndex).Bullets);
            end
    end
end

if isempty(overview)
    error("helperParseG2CustomerFlowMarkdown:MissingOverview", ...
        "The Overview section is missing or empty in %s", markdownPath);
end

if isempty(outputs)
    error("helperParseG2CustomerFlowMarkdown:MissingOutputs", ...
        "The Outputs section is missing or empty in %s", markdownPath);
end

if isempty(visualNotes)
    error("helperParseG2CustomerFlowMarkdown:MissingVisualNotes", ...
        "The Visual Notes section is missing or empty in %s", markdownPath);
end

if numel(stages) < 5
    error("helperParseG2CustomerFlowMarkdown:MissingStages", ...
        "Expected at least five stage sections in %s", markdownPath);
end

[~, sortOrder] = sort([stages.Order]);
stages = stages(sortOrder);

spec = struct();
spec.Title = string(titleTokens.title);
spec.MarkdownPath = string(markdownPath);
spec.Overview = overview;
spec.Stages = stages;
spec.Outputs = outputs;
spec.VisualNotes = visualNotes;
end

function sections = localReadSections(rawText)

lines = splitlines(string(rawText));
sections = repmat(struct("Title", string.empty(0, 1), ...
    "Bullets", strings(0, 1)), 0, 1);
currentTitle = "";
currentBullets = strings(0, 1);
inCodeFence = false;

for lineIndex = 1:numel(lines)
    trimmedLine = strtrim(lines(lineIndex));

    if startsWith(trimmedLine, "```")
        inCodeFence = ~inCodeFence;
        continue;
    end

    if inCodeFence
        continue;
    end

    if startsWith(trimmedLine, "## ")
        if strlength(currentTitle) > 0
            sections(end + 1, 1) = struct( ...
                "Title", currentTitle, ...
                "Bullets", currentBullets ...
                );
        end

        currentTitle = extractAfter(trimmedLine, 3);
        currentBullets = strings(0, 1);
        continue;
    end

    if startsWith(trimmedLine, "- ") && strlength(currentTitle) > 0
        bulletText = strtrim(extractAfter(trimmedLine, 2));
        bulletText = strrep(bulletText, "`", "");
        currentBullets(end + 1, 1) = bulletText;
    end
end

if strlength(currentTitle) > 0
    sections(end + 1, 1) = struct( ...
        "Title", currentTitle, ...
        "Bullets", currentBullets ...
        );
end
end

function stage = localParseStageSection(sectionTitle, bullets)

tokens = regexp(sectionTitle, "^Stage\s+(?<order>\d+)\s*-\s*(?<title>.+)$", ...
    "names", "once");

if isempty(tokens)
    error("helperParseG2CustomerFlowMarkdown:InvalidStageTitle", ...
        "Invalid stage section title: %s", sectionTitle);
end

stage = localStageTemplate();
stage.Order = str2double(tokens.order);
stage.Title = string(tokens.title);

for bulletIndex = 1:numel(bullets)
    bulletText = bullets(bulletIndex);

    if startsWith(bulletText, "Questions:", "IgnoreCase", true)
        stage.Questions = strtrim(extractAfter(bulletText, "Questions:"));
    elseif startsWith(bulletText, "MATLAB path:", "IgnoreCase", true)
        stage.MATLABPath = strtrim(extractAfter(bulletText, "MATLAB path:"));
    elseif startsWith(bulletText, "Expected criteria:", "IgnoreCase", true)
        stage.ExpectedCriteria = strtrim(extractAfter(bulletText, ...
            "Expected criteria:"));
    elseif startsWith(bulletText, "Why it matters:", "IgnoreCase", true)
        stage.WhyItMatters = strtrim(extractAfter(bulletText, ...
            "Why it matters:"));
    end
end

requiredFields = ["Questions"; "MATLABPath"; "ExpectedCriteria"; "WhyItMatters"];

for fieldIndex = 1:numel(requiredFields)
    fieldName = requiredFields(fieldIndex);

    if strlength(stage.(fieldName)) == 0
        error("helperParseG2CustomerFlowMarkdown:MissingStageField", ...
            "Missing %s in %s", fieldName, sectionTitle);
    end
end
end

function stage = localStageTemplate()

stage = struct( ...
    "Order", 0, ...
    "Title", "", ...
    "Questions", "", ...
    "MATLABPath", "", ...
    "ExpectedCriteria", "", ...
    "WhyItMatters", "" ...
    );
end
