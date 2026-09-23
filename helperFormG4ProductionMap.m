function mapProduct = helperFormG4ProductionMap( ...
    referenceSignal, surveillanceSignal, sampleRateHz, prfVector_Hz)
%HELPERFORMG4PRODUCTIONMAP Form a map using exact production-G4 semantics.

arguments
    referenceSignal {mustBeNumeric, mustBeVector}
    surveillanceSignal {mustBeNumeric, mustBeVector}
    sampleRateHz (1,1) double
    prfVector_Hz {mustBeNumeric, mustBeVector}
end

referenceSignal = referenceSignal(:);
surveillanceSignal = surveillanceSignal(:);
prfVector_Hz = double(prfVector_Hz(:).');

if isempty(referenceSignal) || ...
        numel(referenceSignal) ~= numel(surveillanceSignal)
    error("helperFormG4ProductionMap:InvalidSignalPair", ...
        "Signals must be nonempty equal-length vectors.");
end

if any(~isfinite(referenceSignal), "all") || ...
        any(~isfinite(surveillanceSignal), "all")
    error("helperFormG4ProductionMap:NonfiniteSignalPair", ...
        "Signals must contain only finite samples.");
end

if ~isfinite(sampleRateHz) || sampleRateHz <= 0.0
    error("helperFormG4ProductionMap:InvalidSampleRate", ...
        "sampleRateHz must be positive and finite.");
end

if isempty(prfVector_Hz) || any(~isfinite(prfVector_Hz)) || ...
        any(prfVector_Hz <= 0.0)
    error("helperFormG4ProductionMap:InvalidPrf", ...
        "prfVector_Hz must contain positive finite values.");
end

[mapMagnitude, delayAxis_s, dopplerAxis_Hz] = ambgfun( ...
    referenceSignal, surveillanceSignal, sampleRateHz, prfVector_Hz);
mapPower = max(single(mapMagnitude) .^ 2, eps("single"));
delayAxis_s = double(delayAxis_s(:).');
dopplerAxis_Hz = double(dopplerAxis_Hz(:));

if size(mapPower, 1) ~= numel(dopplerAxis_Hz) || ...
        size(mapPower, 2) ~= numel(delayAxis_s)
    error("helperFormG4ProductionMap:MapAxisMismatch", ...
        "Map rows must match Doppler and columns must match delay.");
end

if any(~isfinite(mapPower), "all") || ...
        any(diff(delayAxis_s) <= 0.0) || ...
        any(diff(dopplerAxis_Hz) <= 0.0)
    error("helperFormG4ProductionMap:InvalidMapIntegrity", ...
        "The ambiguity map and axes must be finite and increasing.");
end

mapProduct = struct();
mapProduct.Power = mapPower;
mapProduct.DelayAxis_s = delayAxis_s;
mapProduct.DopplerAxis_Hz = dopplerAxis_Hz;
mapProduct.AxisOrientation = "rows_doppler_columns_delay";
mapProduct.InputClass = string(class(referenceSignal));
mapProduct.PowerClass = string(class(mapPower));
mapProduct.PowerDefinition = ...
    "max(single(ambgfun_magnitude).^2,eps_single)";
mapProduct.Normalization = "ambgfun_native_normalization";

end
