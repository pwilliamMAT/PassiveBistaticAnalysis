function metrics = helperComputeG4RCancellationMetrics( ...
        referenceSignal, inputSurveillanceSignal, residualSignal)
%HELPERCOMPUTEG4RCANCELLATIONMETRICS Calculate compact cancellation metrics.

arguments
    referenceSignal {mustBeNumeric, mustBeVector}
    inputSurveillanceSignal {mustBeNumeric, mustBeVector}
    residualSignal {mustBeNumeric, mustBeVector}
end

referenceSignal = double(referenceSignal(:));
inputSurveillanceSignal = double(inputSurveillanceSignal(:));
residualSignal = double(residualSignal(:));

if numel(referenceSignal) ~= numel(inputSurveillanceSignal) || ...
        numel(referenceSignal) ~= numel(residualSignal) || ...
        isempty(referenceSignal)
    error("helperComputeG4RCancellationMetrics:SignalLength", ...
        "All metrics inputs must be nonempty and equal length.");
end

if any(~isfinite(referenceSignal), "all") || ...
        any(~isfinite(inputSurveillanceSignal), "all") || ...
        any(~isfinite(residualSignal), "all")
    error("helperComputeG4RCancellationMetrics:NonfiniteSignal", ...
        "Metrics inputs must be finite.");
end

inputPower = mean(abs(inputSurveillanceSignal) .^ 2);
residualPower = mean(abs(residualSignal) .^ 2);
modeledPower = max(inputPower - residualPower, 0.0);
coherenceSquared = abs(sum(referenceSignal .* conj(residualSignal))) .^ 2 ./ ...
    max(sum(abs(referenceSignal) .^ 2) .* ...
    sum(abs(residualSignal) .^ 2), eps);

metrics = struct();
metrics.InputSurveillancePower = double(inputPower);
metrics.InputSurveillancePower_dB = pow2db(max(inputPower, eps));
metrics.ResidualPower = double(residualPower);
metrics.ResidualPower_dB = pow2db(max(residualPower, eps));
metrics.ModeledPower = double(modeledPower);
metrics.CancellationDepth_dB = pow2db( ...
    max(inputPower, eps) ./ max(residualPower, eps));
metrics.ResidualCoherenceSquared = double(coherenceSquared);
metrics.Finite = true;

end
