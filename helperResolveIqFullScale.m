function scaleInfo = helperResolveIqFullScale(samples, dataProfile)
%HELPERRESOLVEIQFULLSCALE Resolve the dBFS reference for an IQ array.
%
%   SCALEINFO = HELPERRESOLVEIQFULLSCALE(SAMPLES, DATAPROFILE) preserves
%   the established int16 field-capture convention and treats floating-
%   point synthetic IQ as normalized to unit component full scale.

arguments
    samples {mustBeNumeric}
    dataProfile (1,1) string = "field_capture"
end

dataProfile = lower(strtrim(dataProfile));

if ~ismember(dataProfile, ["field_capture", "synthetic"])
    error("helperResolveIqFullScale:InvalidDataProfile", ...
        "DataProfile must be ""field_capture"" or ""synthetic"".");
end

sourceClass = string(class(samples));

if dataProfile == "field_capture"
    fullScale = double(intmax("int16"));
    convention = "field_int16_component_full_scale";
elseif isfloat(samples)
    fullScale = 1.0;
    convention = "synthetic_normalized_floating_point";
elseif isinteger(samples)
    fullScale = double(intmax(char(sourceClass)));
    convention = "synthetic_integer_component_full_scale";
else
    error("helperResolveIqFullScale:UnsupportedSampleClass", ...
        "Unsupported IQ sample class: %s.", sourceClass);
end

scaleInfo = struct();
scaleInfo.DataProfile = dataProfile;
scaleInfo.SourceClass = sourceClass;
scaleInfo.FullScale = fullScale;
scaleInfo.Convention = convention;

end
