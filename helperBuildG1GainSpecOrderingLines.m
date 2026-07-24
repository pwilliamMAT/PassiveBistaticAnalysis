function gainSpecOrderingLines = helperBuildG1GainSpecOrderingLines(metrics)
%HELPERBUILDG1GAINSPECORDERINGLINES Decode manifest gain order by channel.

arguments
    metrics (1,1) struct
end

gainSpecText = strtrim(string(metrics.manifest_inputs.gain_spec));
channel1Labels = localJoinStringVector(metrics.channel_contract.channel_1_label);
channel2Labels = localJoinStringVector(metrics.channel_contract.channel_2_label);
channelLabels = [channel1Labels; channel2Labels];
roleLabels = [ ...
    localInferChannelRoleLabel(channelLabels(1)); ...
    localInferChannelRoleLabel(channelLabels(2)) ...
    ];

if strlength(gainSpecText) == 0
    gainSpecOrderingLines = "manifest gain_spec is empty.";
    return
end

gainTokens = split(gainSpecText, ",");
gainTokens = strtrim(gainTokens);
gainTokens = gainTokens(strlength(gainTokens) > 0);

mappingCount = min(numel(gainTokens), numel(channelLabels));
gainSpecOrderingLines = strings(mappingCount, 1);

for idx = 1:mappingCount
    gainSpecOrderingLines(idx) = sprintf("%s (%s) = %s dB", ...
        char(channelLabels(idx)), ...
        char(roleLabels(idx)), ...
        char(gainTokens(idx)));
end

if mappingCount == 0
    gainSpecOrderingLines = "manifest gain_spec could not be parsed into " + ...
        "channel-aligned values.";
    return
end

gainSpecOrderingLines = [ ...
    "manifest gain_spec follows the decoded channel order:"; ...
    gainSpecOrderingLines ...
    ];

if numel(gainTokens) ~= numel(channelLabels)
    gainSpecOrderingLines(end + 1) = ...
        "Parsed value count does not match decoded channel count exactly.";
end

end

function joinedText = localJoinStringVector(values)

values = string(values(:));
values = strtrim(values);
values = values(strlength(values) > 0);

if isempty(values)
    joinedText = "";
    return
end

joinedText = strjoin(values, ", ");

end

function roleLabel = localInferChannelRoleLabel(channelLabel)

channelLabel = upper(strtrim(string(channelLabel)));

if contains(channelLabel, "RF0")
    roleLabel = "Surveillance";
elseif contains(channelLabel, "RF1")
    roleLabel = "Reference";
else
    roleLabel = "Unspecified";
end

end
