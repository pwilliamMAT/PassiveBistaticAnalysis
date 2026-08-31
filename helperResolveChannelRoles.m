function roleInfo = helperResolveChannelRoles(sessionData, ...
    collectionMetadataInfo, options)
%HELPERRESOLVECHANNELROLES Resolve explicit or field-metadata channel roles.

arguments
    sessionData (1,1) struct
    collectionMetadataInfo (1,1) struct
    options (1,1) struct = struct()
end

channelLabels = [ ...
    string(sessionData.RadarTable.Antenna1(1)); ...
    string(sessionData.RadarTable.Antenna2(1)) ...
    ];
numChannels = double(sessionData.RadarTable.NumChannels(1));
dataProfile = "field_capture";

if isfield(options, "DataProfile")
    dataProfile = lower(strtrim(string(options.DataProfile)));
end

if ~ismember(dataProfile, ["field_capture", "synthetic"])
    error("helperResolveChannelRoles:InvalidDataProfile", ...
        "DataProfile must be ""field_capture"" or ""synthetic"".");
end

hasReferenceIndex = isfield(options, "ReferenceChannelIndex");
hasSurveillanceIndex = isfield(options, "SurveillanceChannelIndex");

if xor(hasReferenceIndex, hasSurveillanceIndex)
    error("helperResolveChannelRoles:IncompleteExplicitMapping", ...
        "Specify both reference and surveillance channel indices.");
end

if dataProfile == "synthetic" && ~hasReferenceIndex
    error("helperResolveChannelRoles:MissingSyntheticRoleMapping", ...
        "Synthetic data requires explicit reference and surveillance indices.");
end

if hasReferenceIndex
    referenceIndex = localValidateChannelIndex( ...
        options.ReferenceChannelIndex, numChannels, "reference");
    surveillanceIndex = localValidateChannelIndex( ...
        options.SurveillanceChannelIndex, numChannels, "surveillance");

    if referenceIndex == surveillanceIndex
        error("helperResolveChannelRoles:DuplicateChannelAssignment", ...
            "Reference and surveillance channels must be distinct.");
    end

    roleInfo = localBuildRoleInfo(channelLabels, referenceIndex, ...
        surveillanceIndex);

    if dataProfile == "synthetic"
        roleInfo.RoleSource = "explicit_generator_contract";
        roleInfo.RoleNote = "Channel roles come from the packaged " + ...
            "SyntheticDataGeneration contract.";
    else
        roleInfo.RoleSource = "explicit_option_mapping";
        roleInfo.RoleNote = "Channel roles were supplied explicitly by " + ...
            "the caller.";
    end

    roleInfo.DataProfile = dataProfile;
    return;
end

referenceLabel = strtrim( ...
    string(collectionMetadataInfo.ReferenceChannel.ChannelLabel));
surveillanceLabel = strtrim( ...
    string(collectionMetadataInfo.SurveillanceChannel.ChannelLabel));
manualMappingValid = collectionMetadataInfo.MetadataPresent && ...
    collectionMetadataInfo.SessionIdMatches && ...
    strlength(referenceLabel) > 0 && ...
    strlength(surveillanceLabel) > 0 && ...
    any(referenceLabel == channelLabels) && ...
    any(surveillanceLabel == channelLabels) && ...
    referenceLabel ~= surveillanceLabel;

if manualMappingValid
    referenceIndex = find(channelLabels == referenceLabel, 1, "first");
    surveillanceIndex = find(channelLabels == surveillanceLabel, ...
        1, "first");
    roleInfo = localBuildRoleInfo(channelLabels, referenceIndex, ...
        surveillanceIndex);
    roleInfo.RoleSource = "collection_metadata_manual_mapping";
    roleInfo.RoleNote = "Channel roles come from session-matched " + ...
        "collection_metadata.json.";
else
    roleInfo = localBuildRoleInfo(channelLabels, 1, 2);
    roleInfo.RoleSource = "channel_order_fallback_unverified";
    roleInfo.RoleNote = "Manual or explicit role mapping was unavailable; " + ...
        "channel order is an unverified fallback.";
end

roleInfo.DataProfile = dataProfile;

end

function index = localValidateChannelIndex(value, numChannels, roleName)

if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || ...
        value ~= round(value) || value < 1 || value > numChannels
    error("helperResolveChannelRoles:InvalidChannelIndex", ...
        "%s channel index must be an integer from 1 through %d.", ...
        roleName, numChannels);
end

index = double(value);

end

function roleInfo = localBuildRoleInfo(channelLabels, referenceIndex, ...
    surveillanceIndex)

roleInfo = struct();
roleInfo.Channel1Label = channelLabels(1);
roleInfo.Channel2Label = channelLabels(2);
roleInfo.ReferenceLabel = channelLabels(referenceIndex);
roleInfo.SurveillanceLabel = channelLabels(surveillanceIndex);
roleInfo.ReferenceColumnIndex = referenceIndex;
roleInfo.SurveillanceColumnIndex = surveillanceIndex;
roleInfo.RoleSource = "";
roleInfo.RoleNote = "";

end
