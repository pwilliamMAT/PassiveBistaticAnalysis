function row = helperMakeComparisonMetricRow(metricId, metricLabel, value, ...
    units, notes)
%HELPERMAKECOMPARISONMETRICROW Build a normalized comparison-summary row.

arguments
    metricId (1,1) string
    metricLabel (1,1) string
    value
    units (1,1) string = ""
    notes (1,1) string = ""
end

[numericValue, textValue, valueType] = localNormalizeValue(value);

row = struct();
row.MetricId = string(metricId);
row.MetricLabel = string(metricLabel);
row.ValueType = string(valueType);
row.NumericValue = double(numericValue);
row.TextValue = string(textValue);
row.Units = string(units);
row.Notes = string(notes);

end

function [numericValue, textValue, valueType] = localNormalizeValue(value)

numericValue = NaN;
valueType = "text";

if islogical(value) && isscalar(value)
    valueType = "logical";
    numericValue = double(value);

    if value
        textValue = "true";
    else
        textValue = "false";
    end

    return
end

if isnumeric(value) && isscalar(value) && ~isempty(value)
    valueType = "numeric";
    numericValue = double(value);

    if isnan(numericValue)
        textValue = "NaN";
    else
        textValue = string(numericValue);
    end

    return
end

if isstring(value) || ischar(value)
    textTokens = string(value);
    textTokens = strtrim(textTokens(:));
    textTokens = textTokens(strlength(textTokens) > 0);

    if isempty(textTokens)
        textValue = "";
    else
        textValue = strjoin(textTokens, " | ");
    end

    return
end

if isnumeric(value) || islogical(value)
    textValue = string(mat2str(double(value)));
    return
end

textValue = string(value);

end
