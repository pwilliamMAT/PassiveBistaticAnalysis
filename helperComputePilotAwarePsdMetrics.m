function metrics = helperComputePilotAwarePsdMetrics(frequency_Hz, psdValues, ...
    pilotExclusionHalfWidth_Hz)
%HELPERCOMPUTEPILOTAWAREPSDMETRICS Compute pilot-aware PSD metrics.
%
%   METRICS = HELPERCOMPUTEPILOTAWAREPSDMETRICS(FREQUENCY_HZ, PSDVALUES,
%   PILOTEXCLUSIONHALFWIDTH_HZ) identifies the dominant pilot-like PSD line,
%   excludes a frequency window around it, and reports pilot and data-band
%   peak-to-median prominence values. This is not an SNR estimate.

arguments
    frequency_Hz (:,1) double
    psdValues (:,1) double
    pilotExclusionHalfWidth_Hz (1,1) double = 50.0e3
end

frequency_Hz = double(frequency_Hz(:));
psdValues = max(double(psdValues(:)), eps);

if numel(frequency_Hz) ~= numel(psdValues)
    error("helperComputePilotAwarePsdMetrics:SizeMismatch", ...
        "Frequency and PSD vectors must have the same number of elements.");
end

validMask = isfinite(frequency_Hz) & isfinite(psdValues);

if ~any(validMask)
    error("helperComputePilotAwarePsdMetrics:InvalidInput", ...
        "PSD metric calculation requires finite frequency and PSD values.");
end

validFrequency_Hz = frequency_Hz(validMask);
validPsd = psdValues(validMask);
[pilotPsd, pilotIndex] = max(validPsd, [], "omitnan");
pilotFrequency_Hz = validFrequency_Hz(pilotIndex);
overallMedianPsd = max(median(validPsd, "omitnan"), eps);
pilotExclusionHalfWidth_Hz = max(0.0, pilotExclusionHalfWidth_Hz);
dataBandMask = validMask & abs(frequency_Hz - pilotFrequency_Hz) > ...
    pilotExclusionHalfWidth_Hz;

if ~any(dataBandMask)
    dataBandMask = validMask;
end

dataBandFrequency_Hz = frequency_Hz(dataBandMask);
dataBandPsd = psdValues(dataBandMask);
dataBandMedianPsd = max(median(dataBandPsd, "omitnan"), eps);
[dataBandPeakPsd, dataBandPeakIndex] = max(dataBandPsd, [], "omitnan");
metrics = struct();
metrics.PilotFrequency_Hz = pilotFrequency_Hz;
metrics.PilotPsd_dB = pow2db(max(pilotPsd, eps));
metrics.PilotProminence_dB = pow2db(max(pilotPsd, eps) ./ ...
    overallMedianPsd);
metrics.PilotExclusionHalfWidth_Hz = pilotExclusionHalfWidth_Hz;
metrics.DataBandMedianPsd_dB = pow2db(dataBandMedianPsd);
metrics.DataBandPeakFrequency_Hz = dataBandFrequency_Hz(dataBandPeakIndex);
metrics.DataBandPeakPsd_dB = pow2db(max(dataBandPeakPsd, eps));
metrics.DataBandProminence_dB = pow2db(max(dataBandPeakPsd, eps) ./ ...
    dataBandMedianPsd);
metrics.DataBandBinCount = sum(dataBandMask);

end