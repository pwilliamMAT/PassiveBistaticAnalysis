function configuration = helperBuildG6DDetectorConfiguration(options)
%HELPERBUILDG6DDETECTORCONFIGURATION Build the G6-D detector contract.
%
%   CONFIGURATION = HELPERBUILDG6DDETECTORCONFIGURATION() returns the
%   immutable G6-D baseline used by the completed diagnostic campaign.
%
%   CONFIGURATION = HELPERBUILDG6DDETECTORCONFIGURATION(Mode="exploratory_support_override", ...)
%   creates an explicitly labeled diagnostic support override. Only the
%   delay and Doppler support rectangle can differ from the baseline; CFAR,
%   NMS, Pfa, and candidate settings remain unchanged. The actual CUT count
%   is derived from the supplied map grid by the detector.

arguments
    options.Mode (1,1) string {mustBeMember(options.Mode, ...
        ["baseline", "exploratory_support_override"])} = "baseline"
    options.CutDelayLimits_s (1,:) double {mustBeFinite} = zeros(1, 0)
    options.CutDopplerLimits_Hz (1,:) double {mustBeFinite} = zeros(1, 0)
end

baseline = localBaselineConfiguration();
mode = options.Mode;

if mode == "baseline"
    if ~isempty(options.CutDelayLimits_s) || ...
            ~isempty(options.CutDopplerLimits_Hz)
        error("helperBuildG6DDetectorConfiguration:BaselineOverride", ...
            "Baseline mode does not accept support overrides.");
    end

    configuration = baseline;
    configuration.ConfigurationMode = "baseline";
    configuration.IsBaseline = true;
    configuration.SupportStatus = "immutable_baseline";
    configuration.ActualCutCount = NaN;
    configuration.BaselineConfiguration = baseline;
    return
end

if isempty(options.CutDelayLimits_s) && ...
        isempty(options.CutDopplerLimits_Hz)
    error("helperBuildG6DDetectorConfiguration:MissingOverride", ...
        "Exploratory mode requires an explicit support rectangle override.");
end

configuration = baseline;

if ~isempty(options.CutDelayLimits_s)
    localValidateLimits(options.CutDelayLimits_s, "CutDelayLimits_s");
    configuration.CutDelayLimits_s = ...
        double(options.CutDelayLimits_s(:).');
end

if ~isempty(options.CutDopplerLimits_Hz)
    localValidateLimits(options.CutDopplerLimits_Hz, ...
        "CutDopplerLimits_Hz");
    configuration.CutDopplerLimits_Hz = ...
        double(options.CutDopplerLimits_Hz(:).');
end

configuration.ExpectedCutCount = NaN;
configuration.ConfigurationMode = "exploratory_support_override";
configuration.IsBaseline = false;
configuration.SupportStatus = ...
    "exploratory_support_override_actual_cut_count_required";
configuration.ActualCutCount = NaN;
configuration.BaselineConfiguration = baseline;

end

function configuration = localBaselineConfiguration()

configuration = struct();
configuration.SchemaVersion = ...
    "g6_product_discrimination_configuration_v1";
configuration.CandidateNames = [ ...
    "none"; "conservative_lms"; "aggressive_lms"];
configuration.CutDelayLimits_s = [-1.20e-3, -0.15e-3];
configuration.CutDopplerLimits_Hz = [-750.0, 750.0];
configuration.ExpectedCutCount = 12832.0;
configuration.GuardBandSize = [3.0, 1.0];
configuration.TrainingBandSize = [12.0, 4.0];
configuration.TrainingCellCount = 320.0;
configuration.Pfa = [ ...
    1.0e-2; 3.0e-3; 1.0e-3; 3.0e-4; 1.0e-4; ...
    3.0e-5; 1.0e-5; 3.0e-6; 1.0e-6];
configuration.Alpha = configuration.TrainingCellCount .* ...
    (configuration.Pfa .^ ...
    (-1.0 ./ configuration.TrainingCellCount) - 1.0);
configuration.NmsNeighborhood = [7.0, 3.0];
configuration.AxisOrientation = ...
    "rows_doppler_columns_delay";
configuration.CfarMethod = "CA";
configuration.AssociationMethod = ...
    "matchpairs_normalized_delay_doppler";
configuration.DetectionGenerationTruthBlind = true;
configuration.TruthUse = "post_hoc_association_only";

end

function localValidateLimits(limits, name)

if numel(limits) ~= 2 || limits(1) >= limits(2)
    error("helperBuildG6DDetectorConfiguration:InvalidSupport", ...
        "%s must contain two finite, strictly increasing limits.", name);
end

end
