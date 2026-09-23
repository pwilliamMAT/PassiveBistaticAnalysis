function estimate = helperEstimateG4RWienerFir( ...
        referenceSignal, desiredSignal, tapCount, options)
%HELPERESTIMATEG4RWIENERFIR Estimate a regularized causal Wiener FIR.
%
%   ESTIMATE = HELPERESTIMATEG4RWIENERFIR(REFERENCE, DESIRED, TAPCOUNT)
%   estimates the causal FIR that models DESIRED from REFERENCE using
%   biased correlations, a Hermitian Toeplitz correlation matrix, and
%   diagonal regularization. The compact result retains coefficients and
%   fitting diagnostics, never input samples.

arguments
    referenceSignal {mustBeNumeric, mustBeVector}
    desiredSignal {mustBeNumeric, mustBeVector}
    tapCount (1,1) double {mustBeInteger, mustBePositive}
    options (1,1) struct = struct()
end

resolvedOptions = localResolveOptions(options);
referenceSignal = double(referenceSignal(:));
desiredSignal = double(desiredSignal(:));

if numel(referenceSignal) ~= numel(desiredSignal) || ...
        numel(referenceSignal) < tapCount
    error("helperEstimateG4RWienerFir:InvalidSignalLength", ...
        "Signals must be equal length and contain at least tapCount samples.");
end

if any(~isfinite(referenceSignal), "all") || ...
        any(~isfinite(desiredSignal), "all")
    error("helperEstimateG4RWienerFir:NonfiniteSignal", ...
        "Reference and desired signals must contain only finite values.");
end

maximumLag = tapCount - 1;
[referenceCorrelation, lags] = xcorr( ...
    referenceSignal, maximumLag, "biased");
[crossCorrelation, crossLags] = xcorr( ...
    desiredSignal, referenceSignal, maximumLag, "biased");
nonnegativeMask = lags >= 0;
crossNonnegativeMask = crossLags >= 0;
autocorrelation = referenceCorrelation(nonnegativeMask);
crossCorrelation = crossCorrelation(crossNonnegativeMask);

if numel(autocorrelation) ~= tapCount || ...
        numel(crossCorrelation) ~= tapCount
    error("helperEstimateG4RWienerFir:CorrelationLength", ...
        "Wiener-Hopf correlation vectors do not match tapCount.");
end

autocorrelationMatrix = toeplitz( ...
    autocorrelation, conj(autocorrelation));
regularization = resolvedOptions.RegularizationFraction .* ...
    max(real(autocorrelation(1)), eps);
regularizedMatrix = autocorrelationMatrix + ...
    regularization .* eye(tapCount);
coefficients = regularizedMatrix \ crossCorrelation;
conditionNumber = cond(regularizedMatrix);

if any(~isfinite(coefficients), "all")
    error("helperEstimateG4RWienerFir:NonfiniteCoefficients", ...
        "The regularized Wiener estimate contains non-finite coefficients.");
end

estimate = struct();
estimate.Method = "regularized_wiener_hopf";
estimate.TapCount = double(tapCount);
estimate.RegularizationFraction = ...
    resolvedOptions.RegularizationFraction;
estimate.Regularization = double(regularization);
estimate.Coefficients = coefficients(:);
estimate.CoefficientNorm = norm(coefficients);
estimate.RegularizedMatrixConditionNumber = double(conditionNumber);
estimate.AutocorrelationZeroLagPower = double(real(autocorrelation(1)));
estimate.CorrelationEstimator = "xcorr_biased";
estimate.SolveMethod = "toeplitz_regularized_backslash";

end

function resolvedOptions = localResolveOptions(options)

resolvedOptions = struct();
resolvedOptions.RegularizationFraction = 1.0e-3;

optionNames = fieldnames(options);

for optionIndex = 1:numel(optionNames)
    optionName = optionNames{optionIndex};
    resolvedOptions.(optionName) = options.(optionName);
end

resolvedOptions.RegularizationFraction = double( ...
    resolvedOptions.RegularizationFraction);

if ~isscalar(resolvedOptions.RegularizationFraction) || ...
        ~isfinite(resolvedOptions.RegularizationFraction) || ...
        resolvedOptions.RegularizationFraction <= 0.0
    error("helperEstimateG4RWienerFir:Regularization", ...
        "RegularizationFraction must be a positive finite scalar.");
end

end
