function cancellation = helperApplyG4RNativeFirstCancellation( ...
        referenceCalibration, surveillanceCalibration, ...
        referenceScore, surveillanceScore, method, options)
%HELPERAPPLYG4RNATIVEFIRSTCANCELLATION Apply a native-rate cancellation path.
%
%   CANCELLATION = HELPERAPPLYG4RNATIVEFIRSTCANCELLATION(CALREF, CALSURV,
%   SCOREREF, SCORESURV, METHOD, OPTIONS) applies either a fixed
%   regularized-Wiener FIR or a 16-tap NLMS filter trained on CALREF/CALSURV
%   and explicitly frozen for SCOREREF/SCORESURV. It retains only compact
%   coefficients and scalar diagnostics.

arguments
    referenceCalibration {mustBeNumeric, mustBeVector}
    surveillanceCalibration {mustBeNumeric, mustBeVector}
    referenceScore {mustBeNumeric, mustBeVector}
    surveillanceScore {mustBeNumeric, mustBeVector}
    method (1,1) string
    options (1,1) struct = struct()
end

referenceCalibration = double(referenceCalibration(:));
surveillanceCalibration = double(surveillanceCalibration(:));
referenceScore = double(referenceScore(:));
surveillanceScore = double(surveillanceScore(:));
method = lower(string(method));
localValidateSignals(referenceCalibration, surveillanceCalibration, ...
    referenceScore, surveillanceScore);
resolvedOptions = localResolveOptions(options);

switch method
    case "wiener_fir"
        cancellation = localApplyWienerFir( ...
            referenceScore, surveillanceScore, resolvedOptions);
    case "frozen_nlms"
        cancellation = localApplyFrozenNlms( ...
            referenceCalibration, surveillanceCalibration, ...
            referenceScore, surveillanceScore, resolvedOptions);
    otherwise
        error("helperApplyG4RNativeFirstCancellation:Method", ...
            "Method must be wiener_fir or frozen_nlms.");
end

cancellation.Method = method;
cancellation.CalibrationSampleCount = double(numel(referenceCalibration));
cancellation.ScoreSampleCount = double(numel(referenceScore));
cancellation.AdaptationScope = ...
    "calibration_only_then_explicitly_frozen_for_score";

end

function localValidateSignals(referenceCalibration, surveillanceCalibration, ...
        referenceScore, surveillanceScore)

if numel(referenceCalibration) ~= numel(surveillanceCalibration) || ...
        numel(referenceScore) ~= numel(surveillanceScore) || ...
        isempty(referenceCalibration) || isempty(referenceScore)
    error("helperApplyG4RNativeFirstCancellation:SignalLength", ...
        "Calibration and score signals must be nonempty equal-length pairs.");
end

signals = [referenceCalibration; surveillanceCalibration; ...
    referenceScore; surveillanceScore];

if any(~isfinite(signals), "all")
    error("helperApplyG4RNativeFirstCancellation:NonfiniteSignal", ...
        "Cancellation inputs must contain only finite values.");
end

end

function resolvedOptions = localResolveOptions(options)

resolvedOptions = struct();
resolvedOptions.WienerCoefficients = zeros(0, 1);
resolvedOptions.NlmsLength = 16.0;
resolvedOptions.NlmsStepSize = 0.02;
resolvedOptions.NlmsLeakageFactor = 1.0;

optionNames = fieldnames(options);

for optionIndex = 1:numel(optionNames)
    optionName = optionNames{optionIndex};
    resolvedOptions.(optionName) = options.(optionName);
end

resolvedOptions.WienerCoefficients = double( ...
    resolvedOptions.WienerCoefficients(:));
resolvedOptions.NlmsLength = round(double(resolvedOptions.NlmsLength));
resolvedOptions.NlmsStepSize = double(resolvedOptions.NlmsStepSize);
resolvedOptions.NlmsLeakageFactor = ...
    double(resolvedOptions.NlmsLeakageFactor);

if resolvedOptions.NlmsLength < 1 || ...
        resolvedOptions.NlmsStepSize <= 0.0 || ...
        resolvedOptions.NlmsLeakageFactor <= 0.0 || ...
        resolvedOptions.NlmsLeakageFactor > 1.0
    error("helperApplyG4RNativeFirstCancellation:InvalidNlmsOptions", ...
        "NLMS length, step size, and leakage factor are invalid.");
end

end

function cancellation = localApplyWienerFir( ...
        referenceScore, surveillanceScore, resolvedOptions)

coefficients = resolvedOptions.WienerCoefficients;

if isempty(coefficients)
    error("helperApplyG4RNativeFirstCancellation:MissingWienerCoefficients", ...
        "WienerCoefficients are required for the wiener_fir method.");
end

firFilter = dsp.FIRFilter("Numerator", coefficients(:).');
modeledSignal = firFilter(referenceScore);
residualSignal = surveillanceScore - modeledSignal;
localRequireFinite(residualSignal, ...
    "helperApplyG4RNativeFirstCancellation:WienerResidual");

cancellation = struct();
cancellation.ModeledSignal = double(modeledSignal(:));
cancellation.ResidualSignal = double(residualSignal(:));
cancellation.Coefficients = coefficients(:);
cancellation.FilterLength = double(numel(coefficients));
cancellation.StepSize = NaN;
cancellation.MaxStepSize = NaN;
cancellation.FinalWeightsNorm = norm(coefficients);
cancellation.ToolboxFunction = "dsp.FIRFilter";
cancellation.ScoreAdaptationEnabled = false;

end

function cancellation = localApplyFrozenNlms( ...
        referenceCalibration, surveillanceCalibration, ...
        referenceScore, surveillanceScore, resolvedOptions)

lmsFilter = dsp.LMSFilter( ...
    "Method", "Normalized LMS", ...
    "Length", resolvedOptions.NlmsLength, ...
    "StepSize", resolvedOptions.NlmsStepSize, ...
    "LeakageFactor", resolvedOptions.NlmsLeakageFactor, ...
    "AdaptInputPort", true, ...
    "WeightsOutputPort", true);
[~, calibrationResidual, calibrationWeights] = lmsFilter( ...
    referenceCalibration, surveillanceCalibration, true);
[modeledSignal, residualSignal, frozenWeights] = lmsFilter( ...
    referenceScore, surveillanceScore, false);
localRequireFinite(calibrationResidual, ...
    "helperApplyG4RNativeFirstCancellation:CalibrationResidual");
localRequireFinite(residualSignal, ...
    "helperApplyG4RNativeFirstCancellation:FrozenResidual");

cancellation = struct();
cancellation.ModeledSignal = double(modeledSignal(:));
cancellation.ResidualSignal = double(residualSignal(:));
cancellation.Coefficients = double(frozenWeights(:));
cancellation.FilterLength = resolvedOptions.NlmsLength;
cancellation.StepSize = resolvedOptions.NlmsStepSize;
cancellation.MaxStepSize = double(maxstep(lmsFilter, referenceCalibration));
cancellation.FinalWeightsNorm = norm(double(frozenWeights(:)));
cancellation.CalibrationWeightsNorm = norm(double(calibrationWeights(:)));
cancellation.ToolboxFunction = "dsp.LMSFilter";
cancellation.ScoreAdaptationEnabled = false;

end

function localRequireFinite(signal, identifier)

if any(~isfinite(signal), "all")
    error(identifier, "Cancellation residual contains a non-finite value.");
end

end
