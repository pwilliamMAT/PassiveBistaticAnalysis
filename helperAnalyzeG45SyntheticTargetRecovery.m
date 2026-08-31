function analysis = helperAnalyzeG45SyntheticTargetRecovery(suiteId, ...
    caseDatasetId, repoRoot, options)
%HELPERANALYZEG45SYNTHETICTARGETRECOVERY Analyze one G4.5 synthetic case.
%
%   ANALYSIS = HELPERANALYZEG45SYNTHETICTARGETRECOVERY() analyzes one
%   canonical synthetic-target-recovery case using baseline G4-style
%   ambgfun map formation. The helper treats the synthetic suite as an
%   external data handoff and performs only local manifest normalization.

arguments
    suiteId (1,1) string = "g4_5_real_background_20260807T162306840"
    caseDatasetId (1,1) string = "easy_single_target"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

stageTimer = tic;
stageId = "G4_5_SyntheticTargetRecovery";
repoRoot = helperResolveRepoRoot(repoRoot);
suiteId = string(suiteId);
caseDatasetId = string(caseDatasetId);
resolvedOptions = localResolveOptions(options);
timingRows = localEmptyTimingSummaryTable();

try
    stepTimer = tic;
    [suiteRoot, suiteManifest, suiteReadStatus] = localReadSuiteManifest( ...
        repoRoot, suiteId, resolvedOptions);
    timingRows = localAppendTimingRow(timingRows, stageId, ...
        "read_suite_manifest", toc(stepTimer), 0, 0, ...
        suiteReadStatus.Message);

    if suiteReadStatus.IsBlocked
        analysis = localBuildBlockedAnalysis(suiteId, caseDatasetId, ...
            suiteRoot, stageId, resolvedOptions, timingRows, ...
            suiteReadStatus.ValidationTable, suiteReadStatus.Message);
        return
    end

    stepTimer = tic;
    [caseInfo, caseStatus] = localResolveCaseInfo(suiteManifest, ...
        caseDatasetId);
    timingRows = localAppendTimingRow(timingRows, stageId, ...
        "resolve_case_manifest_entry", toc(stepTimer), 0, 0, ...
        caseStatus.Message);

    if caseStatus.IsBlocked
        manifestValidationTable = [suiteReadStatus.ValidationTable; ...
            caseStatus.ValidationTable];
        analysis = localBuildBlockedAnalysis(suiteId, caseDatasetId, ...
            suiteRoot, stageId, resolvedOptions, timingRows, ...
            manifestValidationTable, caseStatus.Message);
        return
    end

    stepTimer = tic;
    [casePaths, normalizedManifest, manifestStatus] = ...
        localNormalizeCaseManifest(suiteRoot, caseInfo, resolvedOptions);
    manifestValidationTable = [suiteReadStatus.ValidationTable; ...
        caseStatus.ValidationTable; manifestStatus.ValidationTable];
    timingRows = localAppendTimingRow(timingRows, stageId, ...
        "normalize_case_manifest", toc(stepTimer), 0, 0, ...
        manifestStatus.Message);

    if manifestStatus.IsBlocked
        analysis = localBuildBlockedAnalysis(suiteId, caseDatasetId, ...
            suiteRoot, stageId, resolvedOptions, timingRows, ...
            manifestValidationTable, manifestStatus.Message);
        return
    end

    stepTimer = tic;
    [truth, truthStatus] = localReadTruth(casePaths.TruthPath);
    manifestValidationTable = [manifestValidationTable; ...
        truthStatus.ValidationTable];
    timingRows = localAppendTimingRow(timingRows, stageId, ...
        "read_truth_json", toc(stepTimer), 0, 0, truthStatus.Message);

    if truthStatus.IsBlocked
        analysis = localBuildBlockedAnalysis(suiteId, caseDatasetId, ...
            suiteRoot, stageId, resolvedOptions, timingRows, ...
            manifestValidationTable, truthStatus.Message);
        return
    end

    stepTimer = tic;
    [targetTruthTable, truthConventionAuditTable, truthBuildStatus] = ...
        localBuildTargetTruthTable(suiteId, caseDatasetId, truth, ...
        caseInfo, resolvedOptions);
    timingRows = localAppendTimingRow(timingRows, stageId, ...
        "build_truth_association_table", toc(stepTimer), 0, 0, ...
        truthBuildStatus.Message);

    if truthBuildStatus.IsBlocked
        analysis = localBuildBlockedAnalysis(suiteId, caseDatasetId, ...
            suiteRoot, stageId, resolvedOptions, timingRows, ...
            manifestValidationTable, truthBuildStatus.Message);
        analysis.TruthConventionAuditTable = truthConventionAuditTable;
        return
    end

    stepTimer = tic;
    [caseScan, scanStatus] = localReadBasebandForG45(casePaths.RadarPath, ...
        normalizedManifest, true);
    manifestValidationTable = [manifestValidationTable; ...
        scanStatus.ValidationTable];
    timingRows = localAppendTimingRow(timingRows, stageId, ...
        "load_case_baseband", toc(stepTimer), caseScan.NumSamples, 1, ...
        scanStatus.Message);

    if scanStatus.IsBlocked
        analysis = localBuildBlockedAnalysis(suiteId, caseDatasetId, ...
            suiteRoot, stageId, resolvedOptions, timingRows, ...
            manifestValidationTable, scanStatus.Message);
        analysis.TruthConventionAuditTable = truthConventionAuditTable;
        return
    end

    stepTimer = tic;
    [targetMeasurementTable, representativeMaps] = ...
        localEvaluateProbeRowsOnScan(caseScan, targetTruthTable, ...
        resolvedOptions);
    timingRows = localAppendTimingRow(timingRows, stageId, ...
        "form_case_maps_and_measure_truth", toc(stepTimer), ...
        caseScan.NumSamples, 1, "Baseline no-mitigation ambgfun maps.");

    stepTimer = tic;
    [controlProbeTable, controlProbeStatus] = localBuildControlProbeTable( ...
        suiteRoot, suiteManifest, caseDatasetId, targetTruthTable, ...
        resolvedOptions);
    timingRows = localAppendTimingRow(timingRows, stageId, ...
        "build_control_probe_truth", toc(stepTimer), 0, 0, ...
        controlProbeStatus.Message);

    if controlProbeStatus.IsBlocked
        analysis = localBuildBlockedAnalysis(suiteId, caseDatasetId, ...
            suiteRoot, stageId, resolvedOptions, timingRows, ...
            manifestValidationTable, controlProbeStatus.Message);
        analysis.TruthConventionAuditTable = truthConventionAuditTable;
        return
    end

    stepTimer = tic;
    [controlMeasurementTable, controlRepresentativeMaps, falseAlarmStatus] = ...
        localEvaluateControlFalseAlarms(suiteRoot, suiteManifest, ...
        caseDatasetId, caseScan, controlProbeTable, resolvedOptions);
    manifestValidationTable = [manifestValidationTable; ...
        falseAlarmStatus.ValidationTable];
    timingRows = localAppendTimingRow(timingRows, stageId, ...
        "measure_negative_control_false_alarms", toc(stepTimer), ...
        falseAlarmStatus.InputSampleCount, ...
        falseAlarmStatus.InputRepetitionCount, falseAlarmStatus.Message);

    if falseAlarmStatus.IsBlocked
        analysis = localBuildBlockedAnalysis(suiteId, caseDatasetId, ...
            suiteRoot, stageId, resolvedOptions, timingRows, ...
            manifestValidationTable, falseAlarmStatus.Message);
        analysis.TruthConventionAuditTable = truthConventionAuditTable;
        return
    end

    stepTimer = tic;
    falseAlarmSummaryTable = localBuildFalseAlarmSummaryTable( ...
        suiteId, caseDatasetId, controlMeasurementTable, resolvedOptions);
    targetRecoveryTable = localBuildTargetRecoveryTable(suiteId, ...
        caseDatasetId, targetMeasurementTable, falseAlarmSummaryTable, ...
        resolvedOptions);
    [gateDecision, failureCause, nextBranch, targetSummary] = ...
        localDecideCase(caseDatasetId, caseInfo, targetRecoveryTable, ...
        falseAlarmSummaryTable, truthBuildStatus, resolvedOptions);
    diagnosticInterpretationTable = localBuildDiagnosticInterpretationTable( ...
        gateDecision, caseDatasetId, caseInfo, targetSummary, ...
        falseAlarmSummaryTable, truthBuildStatus);
    requirementsCoverageTable = localBuildRequirementsCoverageTable( ...
        gateDecision, caseDatasetId, manifestValidationTable, ...
        targetRecoveryTable, falseAlarmSummaryTable, truthBuildStatus);
    timingRows = localAppendTimingRow(timingRows, stageId, ...
        "decide_g45_case", toc(stepTimer), caseScan.NumSamples, 1, ...
        "Numeric truth association, control check, and interpretation.");

    elapsed_s = toc(stageTimer);
    analysis = struct();
    analysis.StageId = stageId;
    analysis.SuiteId = suiteId;
    analysis.CaseDatasetId = caseDatasetId;
    analysis.SuiteRoot = string(suiteRoot);
    analysis.CaseRoot = string(casePaths.CaseRoot);
    analysis.RadarPath = string(casePaths.RadarPath);
    analysis.TruthPath = string(casePaths.TruthPath);
    analysis.NormalizedManifest = normalizedManifest;
    analysis.Options = resolvedOptions;
    analysis.GateDecision = string(gateDecision);
    analysis.FailureCause = string(failureCause);
    analysis.NextBranch = string(nextBranch);
    analysis.TargetSummary = targetSummary;
    analysis.InputSampleCount = double(caseScan.NumSamples);
    analysis.InputRepetitionCount = 1.0;
    analysis.SampleRateHz = double(caseScan.SampleRate);
    analysis.MapSampleRateHz = double(caseScan.SampleRate) ./ ...
        double(resolvedOptions.MapDecimationFactor);
    analysis.CenterFrequencyHz = double(caseScan.CenterFrequency);
    analysis.DecodePath = string(caseScan.DecodePath);
    analysis.Elapsed_s = double(elapsed_s);
    analysis.ManifestValidationTable = manifestValidationTable;
    analysis.TruthConventionAuditTable = truthConventionAuditTable;
    analysis.TargetRecoveryTable = targetRecoveryTable;
    analysis.FalseAlarmSummaryTable = falseAlarmSummaryTable;
    analysis.DiagnosticInterpretationTable = diagnosticInterpretationTable;
    analysis.RequirementsCoverageTable = requirementsCoverageTable;
    analysis.TimingSummaryTable = timingRows;
    analysis.RepresentativeMaps = representativeMaps;
    analysis.ControlRepresentativeMaps = controlRepresentativeMaps;
catch analysisException
    message = "G4.5 analysis failed before a complete decision: " + ...
        string(analysisException.message);
    analysis = localBuildBlockedAnalysis(suiteId, caseDatasetId, "", ...
        stageId, resolvedOptions, timingRows, localEmptyManifestTable(), ...
        message);
end

end

function resolvedOptions = localResolveOptions(options)

resolvedOptions = struct();
resolvedOptions.SuiteFolder = "g4_5_real_background_20260807T162306840";
resolvedOptions.RequiredCaseIds = [
    "real_only_control"
    "easy_single_target"
    "medium_single_target"
    "hard_single_target"
    "marginal_single_target"
    "multi_target"
    ];
resolvedOptions.ControlCaseId = "real_only_control";
resolvedOptions.ControlProbeCaseIds = [
    "easy_single_target"
    "multi_target"
    ];
resolvedOptions.CpiDuration_s = 0.100;
resolvedOptions.AnalysisWindowStart_s = [
    0.10
    0.30
    0.50
    ];
resolvedOptions.AnalysisWindowLabels = [
    "early"
    "center"
    "late"
    ];
resolvedOptions.MapDecimationFactor = 200;
resolvedOptions.TargetPatchHalfWidth_bins = 2;
resolvedOptions.BackgroundHalfWidth_bins = 10;
resolvedOptions.PassProminence_dB = 7.5;
resolvedOptions.PassRobustZ = 5.0;
resolvedOptions.WarnProminence_dB = 5.0;
resolvedOptions.WarnRobustZ = 2.5;
resolvedOptions.MinControlLiftForPass_dB = 3.0;
resolvedOptions.ControlFailPassWindowCount = 2;
resolvedOptions.DelayToleranceMapBins = 2.5;
resolvedOptions.DopplerTolerance_Hz = 15.0;
resolvedOptions.DelaySignForG4Raw = -1.0;
resolvedOptions.DopplerSignForG4Raw = -1.0;
resolvedOptions.ReviewMapRows = 512;
resolvedOptions.ReviewMapCols = 512;
resolvedOptions.FigureFloor_dB = -60.0;
resolvedOptions.RenderFigures = false;
resolvedOptions.ShowFigures = false;

optionFields = fieldnames(options);

for idx = 1:numel(optionFields)
    fieldName = optionFields{idx};
    resolvedOptions.(fieldName) = options.(fieldName);
end

if isfield(options, "ShowFigures")
    resolvedOptions.RenderFigures = logical(options.ShowFigures);
end

resolvedOptions.RequiredCaseIds = string(resolvedOptions.RequiredCaseIds(:));
resolvedOptions.ControlProbeCaseIds = string( ...
    resolvedOptions.ControlProbeCaseIds(:));
resolvedOptions.AnalysisWindowStart_s = double( ...
    resolvedOptions.AnalysisWindowStart_s(:));
resolvedOptions.AnalysisWindowLabels = string( ...
    resolvedOptions.AnalysisWindowLabels(:));

if numel(resolvedOptions.AnalysisWindowLabels) ~= ...
        numel(resolvedOptions.AnalysisWindowStart_s)
    error("helperAnalyzeG45SyntheticTargetRecovery:InvalidWindows", ...
        "AnalysisWindowLabels must match AnalysisWindowStart_s.");
end

end

function [suiteRoot, suiteManifest, status] = localReadSuiteManifest( ...
    repoRoot, suiteId, resolvedOptions)

suiteRoot = fullfile(repoRoot, suiteId);

if ~isfolder(suiteRoot)
    suiteRoot = fullfile(repoRoot, resolvedOptions.SuiteFolder);
end

manifestPath = fullfile(suiteRoot, "synthetic_suite_manifest.json");
validationRows = localManifestRow("suite_manifest_exists", ...
    manifestPath, true, isfile(manifestPath), "suite manifest path");

if ~isfile(manifestPath)
    suiteManifest = struct();
    status = localStatus(true, "Missing synthetic_suite_manifest.json.", ...
        validationRows);
    return
end

try
    suiteManifest = jsondecode(fileread(manifestPath));
catch readException
    validationRows.Status(1) = "BLOCKED";
    validationRows.Detail(1) = string(readException.message);
    suiteManifest = struct();
    status = localStatus(true, "Failed to parse synthetic suite manifest.", ...
        validationRows);
    return
end

requiredCaseIds = resolvedOptions.RequiredCaseIds;
availableCaseIds = string({suiteManifest.datasets.dataset_id}.');
missingCaseIds = setdiff(requiredCaseIds, availableCaseIds);
hasRequiredCases = isempty(missingCaseIds);
validationRows = [validationRows; localManifestRow( ...
    "required_case_entries_present", manifestPath, true, ...
    hasRequiredCases, strjoin(missingCaseIds, ", "))];

status = localStatus(~hasRequiredCases, ...
    "Suite manifest parsed and required case entries checked.", ...
    validationRows);

if ~hasRequiredCases
    status.Message = "Suite manifest is missing required cases: " + ...
        strjoin(missingCaseIds, ", ");
end

end

function [caseInfo, status] = localResolveCaseInfo(suiteManifest, ...
    caseDatasetId)

caseInfo = struct();
datasetIds = string({suiteManifest.datasets.dataset_id}.');
matchIndex = find(datasetIds == caseDatasetId, 1, "first");
hasCase = ~isempty(matchIndex);
validationRows = localManifestRow("case_dataset_id_in_suite", ...
    caseDatasetId, true, hasCase, "case lookup");

if ~hasCase
    status = localStatus(true, "Requested case is not present in suite.", ...
        validationRows);
    return
end

caseInfo = suiteManifest.datasets(matchIndex);
status = localStatus(false, "Case manifest entry found.", validationRows);

end

function [casePaths, normalizedManifest, status] = ...
    localNormalizeCaseManifest(suiteRoot, caseInfo, ~)

caseDatasetId = string(caseInfo.dataset_id);
caseRoot = fullfile(suiteRoot, caseDatasetId);
sessionManifestPath = fullfile(caseRoot, "session_manifest.json");
validationRows = localManifestRow("case_session_manifest_exists", ...
    sessionManifestPath, true, isfile(sessionManifestPath), ...
    "per-case session manifest");

casePaths = struct();
casePaths.CaseRoot = string(caseRoot);
casePaths.SessionManifestPath = string(sessionManifestPath);
casePaths.RadarPath = "";
casePaths.TruthPath = "";

if ~isfile(sessionManifestPath)
    normalizedManifest = struct();
    status = localStatus(true, "Missing per-case session_manifest.json.", ...
        validationRows);
    return
end

try
    manifest = jsondecode(fileread(sessionManifestPath));
catch readException
    validationRows.Status(1) = "BLOCKED";
    validationRows.Detail(1) = string(readException.message);
    normalizedManifest = struct();
    status = localStatus(true, "Failed to parse per-case manifest.", ...
        validationRows);
    return
end

normalizedManifest = manifest;

if ~isfield(normalizedManifest, "adsb_files")
    normalizedManifest.adsb_files = string(manifest.truth_files(:));
end

if ~isfield(normalizedManifest, "log_files")
    normalizedManifest.log_files = strings(0, 1);
end

normalizedManifest.g45_normalization_applied = true;
normalizedManifest.g45_normalization_note = ...
    "truth_files mapped to adsb_files for local compatibility only.";

hasRadarFiles = isfield(manifest, "radar_files") && ...
    ~isempty(manifest.radar_files);
hasTruthFiles = isfield(manifest, "truth_files") && ...
    ~isempty(manifest.truth_files);
validationRows = [validationRows; localManifestRow("radar_files_present", ...
    sessionManifestPath, true, hasRadarFiles, "radar_files")];
validationRows = [validationRows; localManifestRow("truth_files_present", ...
    sessionManifestPath, true, hasTruthFiles, "truth_files")];
validationRows = [validationRows; localManifestRow( ...
    "g45_manifest_normalization", sessionManifestPath, true, true, ...
    "added adsb_files/log_files locally; source handoff unchanged")];

if ~hasRadarFiles || ~hasTruthFiles
    status = localStatus(true, ...
        "Case manifest lacks required radar_files or truth_files.", ...
        validationRows);
    return
end

radarRelativePath = string(manifest.radar_files(1));
truthRelativePath = string(manifest.truth_files(1));
radarPath = fullfile(caseRoot, strrep(radarRelativePath, "/", filesep));
truthPath = fullfile(caseRoot, strrep(truthRelativePath, "/", filesep));
casePaths.RadarPath = string(radarPath);
casePaths.TruthPath = string(truthPath);
validationRows = [validationRows; localManifestRow("bb_file_exists", ...
    radarPath, true, isfile(radarPath), "baseband .bb input")];
validationRows = [validationRows; localManifestRow("truth_file_exists", ...
    truthPath, true, isfile(truthPath), "per-case truth JSON")];

isBlocked = ~isfile(radarPath) || ~isfile(truthPath);
status = localStatus(isBlocked, "Case manifest normalized.", ...
    validationRows);

if isBlocked
    status.Message = "Required .bb or truth JSON file is missing.";
end

if ~isfield(normalizedManifest, "capture_repetitions")
    normalizedManifest.capture_repetitions = 1;
end

if ~isfield(normalizedManifest, "radar_epoch_utc")
    normalizedManifest.radar_epoch_utc = NaN;
end

if ~isfield(normalizedManifest, "sdr_defaults")
    normalizedManifest.sdr_defaults = struct();
end

if ~isfield(normalizedManifest.sdr_defaults, "sample_rate_hz")
    normalizedManifest.sdr_defaults.sample_rate_hz = NaN;
end

if ~isfield(normalizedManifest.sdr_defaults, "center_frequency_hz")
    normalizedManifest.sdr_defaults.center_frequency_hz = NaN;
end

end

function [truth, status] = localReadTruth(truthPath)

validationRows = localManifestRow("truth_json_readable", truthPath, ...
    true, isfile(truthPath), "truth file");

if ~isfile(truthPath)
    truth = struct();
    status = localStatus(true, "Truth JSON file is missing.", ...
        validationRows);
    return
end

try
    truth = jsondecode(fileread(truthPath));
catch readException
    validationRows.Status(1) = "BLOCKED";
    validationRows.Detail(1) = string(readException.message);
    truth = struct();
    status = localStatus(true, "Failed to parse truth JSON.", ...
        validationRows);
    return
end

status = localStatus(false, "Truth JSON parsed.", validationRows);

end

function [targetTruthTable, truthConventionAuditTable, status] = ...
    localBuildTargetTruthTable(suiteId, caseDatasetId, truth, caseInfo, ...
    resolvedOptions)

targetTruthTable = localEmptyTargetTruthTable();
truthConventionAuditTable = localEmptyTruthConventionAuditTable();
targetStruct = localResolveTargetStructArray(truth);
injectionEnabled = localLogicalField(truth, "injection_enabled", ...
    localLogicalField(caseInfo, "injection_enabled", false));
expectedTargetCount = localDoubleField(truth, "number_of_targets", ...
    localDoubleField(caseInfo, "number_of_targets", 0));

if ~injectionEnabled || expectedTargetCount == 0
    truthConventionAuditTable = localAppendTruthAuditNoTarget( ...
        truthConventionAuditTable, suiteId, caseDatasetId);
    status = localStatus(false, "No injected targets expected.", ...
        localEmptyManifestTable());
    status.OptionalCaveatCodes = strings(0, 1);
    return
end

if isempty(targetStruct)
    status = localStatus(true, ...
        "Injected case lacks required target truth records.", ...
        localEmptyManifestTable());
    status.OptionalCaveatCodes = strings(0, 1);
    return
end

rowIndex = 0;
optionalCaveatCodes = strings(0, 1);

for targetIndex = 1:numel(targetStruct)
    target = targetStruct(targetIndex);
    targetId = localStringField(target, "target_id", ...
        "target_" + string(targetIndex));
    truthTimes = localNestedNumericVector(target, ...
        ["cpi_or_time_windows_used", "truth_time_s"]);
    expectedDelay_s = localNumericVectorField(target, "expected_delay_s");
    expectedDoppler_Hz = localNumericVectorField(target, ...
        "expected_bistatic_doppler_hz");
    expectedRangeBin = localOptionalNumericVectorField(target, ...
        "expected_range_bin");
    expectedDopplerBin = localOptionalNumericVectorField(target, ...
        "expected_doppler_bin");
    optionalStatus = localResolveOptionalTruthStatus(target, truth, ...
        expectedRangeBin, expectedDopplerBin);

    if optionalStatus.HasCaveat
        optionalCaveatCodes = [optionalCaveatCodes; ...
            optionalStatus.CaveatCodes(:)]; %#ok<AGROW>
    end

    if isempty(truthTimes) || isempty(expectedDelay_s) || ...
            isempty(expectedDoppler_Hz)
        status = localStatus(true, ...
            "Target truth lacks expected delay or Doppler vectors.", ...
            localEmptyManifestTable());
        status.OptionalCaveatCodes = unique(optionalCaveatCodes);
        return
    end

    for windowIndex = 1:numel(resolvedOptions.AnalysisWindowStart_s)
        cpiStart_s = resolvedOptions.AnalysisWindowStart_s(windowIndex);
        cpiStop_s = cpiStart_s + resolvedOptions.CpiDuration_s;
        windowLabel = resolvedOptions.AnalysisWindowLabels(windowIndex);
        [truthTime_s, delay_s, doppler_Hz, rangeBin, dopplerBin, ...
            truthNote] = localResolveTruthAtWindow(truthTimes, ...
            expectedDelay_s, expectedDoppler_Hz, expectedRangeBin, ...
            expectedDopplerBin, cpiStart_s, cpiStop_s);
        associationDelay_s = resolvedOptions.DelaySignForG4Raw .* delay_s;
        associationDoppler_Hz = ...
            resolvedOptions.DopplerSignForG4Raw .* doppler_Hz;
        rowIndex = rowIndex + 1;
        targetTruthTable(rowIndex, :) = table( ...
            suiteId, ...
            caseDatasetId, ...
            string(targetId), ...
            string(windowLabel), ...
            double(cpiStart_s), ...
            double(resolvedOptions.CpiDuration_s), ...
            double(truthTime_s), ...
            double(delay_s), ...
            double(doppler_Hz), ...
            double(associationDelay_s), ...
            double(associationDoppler_Hz), ...
            double(rangeBin), ...
            double(dopplerBin), ...
            string(truthNote), ...
            VariableNames = targetTruthTable.Properties.VariableNames);
        truthConventionAuditTable = localAppendTruthAuditRow( ...
            truthConventionAuditTable, suiteId, caseDatasetId, ...
            targetId, windowLabel, truthTime_s, delay_s, doppler_Hz, ...
            associationDelay_s, associationDoppler_Hz, rangeBin, ...
            dopplerBin, optionalStatus, truthNote, resolvedOptions);
    end
end

status = localStatus(false, "Target truth association rows built.", ...
    localEmptyManifestTable());
status.OptionalCaveatCodes = unique(optionalCaveatCodes);

end

function [scan, status] = localReadBasebandForG45(radarPath, ...
    normalizedManifest, includeSamples)

scan = localEmptyScan();
validationRows = localEmptyManifestTable();

try
    scan = helperScanBasebandCaptureFile(radarPath, includeSamples);
    validationRows = [validationRows; localManifestRow( ...
        "baseband_read_path", radarPath, true, true, ...
        "helperScanBasebandCaptureFile")];
    status = localStatus(false, ...
        "Read .bb through helperScanBasebandCaptureFile.", ...
        validationRows);
    return
catch helperException
    helperMessage = string(helperException.message);
end

try
    scan = localReadBasebandWithMetadataAdapter(radarPath, ...
        normalizedManifest, includeSamples, helperMessage);
catch adapterException
    validationRows = [validationRows; localManifestRow( ...
        "baseband_read_path", radarPath, true, false, ...
        string(adapterException.message))];
    status = localStatus(true, "Failed to read baseband .bb file.", ...
        validationRows);
    return
end

validationRows = [validationRows; localManifestRow("baseband_read_path", ...
    radarPath, true, true, ...
    "comm.BasebandFileReader with G4.5 metadata adapter after " + ...
    "helper scanner metadata mismatch: " + helperMessage)];
status = localStatus(false, ...
    "Read .bb through comm.BasebandFileReader with local metadata adapter.", ...
    validationRows);

end

function scan = localReadBasebandWithMetadataAdapter(radarPath, ...
    normalizedManifest, includeSamples, helperMessage)

fileInfo = dir(radarPath);

if isempty(fileInfo)
    error("helperAnalyzeG45SyntheticTargetRecovery:MissingBasebandFile", ...
        "Baseband file not found: %s", radarPath);
end

infoReader = [];
dataReader = [];

try
    infoReader = comm.BasebandFileReader(char(radarPath));
    readerInfo = info(infoReader);
    metadata = infoReader.Metadata;
    sampleRateHz = double(infoReader.SampleRate);
    centerFrequencyHz = double(infoReader.CenterFrequency);
    numChannels = double(infoReader.NumChannels);
    release(infoReader);
    infoReader = [];
    dataReader = comm.BasebandFileReader(char(radarPath), ...
        readerInfo.NumSamplesInData);
    rawData = dataReader();
    release(dataReader);
catch readException
    if ~isempty(infoReader)
        release(infoReader);
    end

    if ~isempty(dataReader)
        release(dataReader);
    end

    error("helperAnalyzeG45SyntheticTargetRecovery:BasebandReadFailed", ...
        "comm.BasebandFileReader failed for %s: %s", radarPath, ...
        readException.message);
end

if numChannels < 2
    error("helperAnalyzeG45SyntheticTargetRecovery:InsufficientChannels", ...
        "Expected at least two baseband channels, found %d.", ...
        numChannels);
end

if ~includeSamples
    rawData = complex(single.empty(0, numChannels));
end

scan = struct();
scan.FilePath = string(radarPath);
scan.RelativePath = "";
scan.ManifestIndex = 1.0;
scan.FileSuffixRepetition = 1.0;
scan.Repetition = 1.0;
scan.DecodePath = "comm.BasebandFileReader_g45_metadata_adapter";
scan.PreferredReader = "comm.BasebandFileReader";
scan.RawFreadFallbackUsed = false;
scan.RawFreadFallbackReason = "";
scan.NativeReaderFailureCategory = "metadata_contract_adapter";
scan.NativeReaderFailureIdentifier = "";
scan.NativeReaderFailureMessage = helperMessage;
scan.SampleRate = sampleRateHz;
scan.CenterFrequency = centerFrequencyHz;
scan.NumSamples = double(readerInfo.NumSamplesInData);
scan.NumChannels = numChannels;
scan.DataType = string(readerInfo.DataType);
scan.IsComplex = true;
scan.SampleSpan_s = scan.NumSamples ./ scan.SampleRate;
scan.Duration_s = localDoubleField(metadata, "Duration_s", ...
    localDoubleField(normalizedManifest, "radar_recorded_iq_seconds_s", ...
    scan.SampleSpan_s));
scan.RecordingUTC = localDoubleField(metadata, "RecordingUTC", ...
    localDoubleField(normalizedManifest, "radar_epoch_utc", NaN));
scan.DateTime = localStringField(metadata, "DateTime", "");
scan.DateTimeVsRecording_ms = NaN;
scan.FileBytes = double(fileInfo.bytes);
scan.PayloadBytes = NaN;
scan.WrapperOverheadBytes = NaN;
scan.PayloadOffsetBytes = NaN;
scan.HeaderVersion = "comm.BasebandFileReader";
scan.MetadataSource = "G4.5 local synthetic metadata adapter";
scan.PayloadPacking = "baseband_file_reader_matrix";
scan.Antenna1 = "surveillance";
scan.Antenna2 = "reference";
scan.ChannelMapping = localStringField(metadata, "ChannelMapping", ...
    "CH1=surveillance, CH2=reference");

if includeSamples
    scan.Samples = rawData;
    scan.MeanPowerCh1 = mean(abs(double(rawData(:, 1))).^2, "omitnan");
    scan.MeanPowerCh2 = mean(abs(double(rawData(:, 2))).^2, "omitnan");
    scan.ChannelCorrelationMagnitude = abs(corr(rawData(:, 1), ...
        rawData(:, 2)));
    scan.FirstNonzeroIndexCh1 = localFirstNonzeroIndex(rawData(:, 1));
    scan.FirstNonzeroIndexCh2 = localFirstNonzeroIndex(rawData(:, 2));
    edgeSampleCount = min(16, size(rawData, 1));
    scan.StartSamples = rawData(1:edgeSampleCount, :);
    scan.EndSamples = rawData(end - edgeSampleCount + 1:end, :);
else
    scan.Samples = complex(single.empty(0, numChannels));
    scan.MeanPowerCh1 = NaN;
    scan.MeanPowerCh2 = NaN;
    scan.ChannelCorrelationMagnitude = NaN;
    scan.FirstNonzeroIndexCh1 = NaN;
    scan.FirstNonzeroIndexCh2 = NaN;
    scan.StartSamples = complex(single.empty(0, numChannels));
    scan.EndSamples = complex(single.empty(0, numChannels));
end

end

function [measurementTable, representativeMaps] = localEvaluateProbeRowsOnScan( ...
    scan, probeTable, resolvedOptions)

measurementTable = localEmptyMeasurementTable();
representativeMaps = repmat(localEmptyRepresentativeMap(), 0, 1);

if isempty(probeTable)
    return
end

if isempty(scan.Samples)
    error("helperAnalyzeG45SyntheticTargetRecovery:MissingSamples", ...
        "G4.5 target recovery requires loaded baseband samples.");
end

sampleRateHz = double(scan.SampleRate);
mapDecimationFactor = double(resolvedOptions.MapDecimationFactor);
mapSampleRateHz = sampleRateHz ./ mapDecimationFactor;
surveillanceMapSamples = resample(single(scan.Samples(:, 1)), 1, ...
    mapDecimationFactor);
referenceMapSamples = resample(single(scan.Samples(:, 2)), 1, ...
    mapDecimationFactor);
windowKeys = unique(probeTable(:, ["WindowLabel", "CpiStart_s", ...
    "CpiDuration_s"]), "rows", "stable");
measurementRows = repmat(localMeasurementRowTemplate(), ...
    height(probeTable), 1);
measurementIndex = 0;
representativeMaps = repmat(localEmptyRepresentativeMap(), ...
    height(windowKeys), 1);

for windowIndex = 1:height(windowKeys)
    cpiStart_s = double(windowKeys.CpiStart_s(windowIndex));
    cpiDuration_s = double(windowKeys.CpiDuration_s(windowIndex));
    windowLabel = string(windowKeys.WindowLabel(windowIndex));
    cpiMapSamples = round(cpiDuration_s .* mapSampleRateHz);
    mapStartIndex = max(1, round(cpiStart_s .* mapSampleRateHz) + 1);
    mapStopIndex = min(numel(referenceMapSamples), ...
        mapStartIndex + cpiMapSamples - 1);

    if mapStopIndex - mapStartIndex + 1 < cpiMapSamples
        mapStartIndex = max(1, mapStopIndex - cpiMapSamples + 1);
    end

    referenceWindow = referenceMapSamples(mapStartIndex:mapStopIndex);
    surveillanceWindow = surveillanceMapSamples(mapStartIndex:mapStopIndex);
    prfVector_Hz = [
        1.0 ./ cpiDuration_s
        1.0 ./ cpiDuration_s
        ];

    try
        [mapMagnitude, delayAxis_s, dopplerAxis_Hz] = ambgfun( ...
            referenceWindow, surveillanceWindow, mapSampleRateHz, ...
            prfVector_Hz);
    catch mapException
        error("helperAnalyzeG45SyntheticTargetRecovery:AmbgfunFailed", ...
            "ambgfun failed for window %s: %s", windowLabel, ...
            mapException.message);
    end

    mapLinear = max(single(mapMagnitude), eps("single")) .^ 2;
    delayAxis_s = double(delayAxis_s(:).');
    dopplerAxis_Hz = double(dopplerAxis_Hz(:));
    rowMask = probeTable.WindowLabel == windowLabel & ...
        abs(probeTable.CpiStart_s - cpiStart_s) <= eps(cpiStart_s) & ...
        abs(probeTable.CpiDuration_s - cpiDuration_s) <= ...
        eps(cpiDuration_s);
    probeRows = probeTable(rowMask, :);

    for probeIndex = 1:height(probeRows)
        measurementIndex = measurementIndex + 1;
        measurementRows(measurementIndex) = localMeasureProbe( ...
            probeRows(probeIndex, :), mapLinear, delayAxis_s, ...
            dopplerAxis_Hz, sampleRateHz, mapSampleRateHz, ...
            resolvedOptions);
    end

    representativeMaps(windowIndex) = localBuildRepresentativeMap( ...
        windowLabel, cpiStart_s, cpiDuration_s, mapLinear, ...
        delayAxis_s, dopplerAxis_Hz, resolvedOptions);
end

if measurementIndex > 0
    measurementTable = struct2table(measurementRows(1:measurementIndex));
else
    measurementTable = localEmptyMeasurementTable();
end

end

function measurementRow = localMeasureProbe(probeRow, mapLinear, ...
    delayAxis_s, dopplerAxis_Hz, nativeSampleRateHz, mapSampleRateHz, ...
    resolvedOptions)

associationDelay_s = double(probeRow.AssociationDelay_s);
associationDoppler_Hz = double(probeRow.AssociationDoppler_Hz);
[~, delayIndex] = min(abs(delayAxis_s - associationDelay_s));
[~, dopplerIndex] = min(abs(dopplerAxis_Hz - associationDoppler_Hz));
patchHalfWidth = double(resolvedOptions.TargetPatchHalfWidth_bins);
backgroundHalfWidth = double(resolvedOptions.BackgroundHalfWidth_bins);
targetRows = max(1, dopplerIndex - patchHalfWidth): ...
    min(size(mapLinear, 1), dopplerIndex + patchHalfWidth);
targetCols = max(1, delayIndex - patchHalfWidth): ...
    min(size(mapLinear, 2), delayIndex + patchHalfWidth);
backgroundRows = max(1, dopplerIndex - backgroundHalfWidth): ...
    min(size(mapLinear, 1), dopplerIndex + backgroundHalfWidth);
backgroundCols = max(1, delayIndex - backgroundHalfWidth): ...
    min(size(mapLinear, 2), delayIndex + backgroundHalfWidth);
targetPatch = mapLinear(targetRows, targetCols);
[targetPeakPower, localPeakIndex] = max(targetPatch, [], "all");
[localPeakRow, localPeakCol] = ind2sub(size(targetPatch), localPeakIndex);
associatedRow = targetRows(localPeakRow);
associatedCol = targetCols(localPeakCol);
backgroundPatch = mapLinear(backgroundRows, backgroundCols);
backgroundMask = true(size(backgroundPatch));
excludedRows = targetRows - backgroundRows(1) + 1;
excludedCols = targetCols - backgroundCols(1) + 1;
backgroundMask(excludedRows, excludedCols) = false;
backgroundValues = double(backgroundPatch(backgroundMask));

if isempty(backgroundValues)
    backgroundValues = double(mapLinear(:));
end

localMedianPower = max(median(backgroundValues, "omitnan"), eps);
robustSigma = 1.4826 .* mad(backgroundValues, 1);
robustSigma = max(robustSigma, eps);
localProminence_dB = pow2db(double(targetPeakPower) ./ localMedianPower);
robustZ = (double(targetPeakPower) - localMedianPower) ./ robustSigma;
localPercentile = 100.0 .* mean(backgroundValues <= ...
    double(targetPeakPower));
associatedDelay_s = delayAxis_s(associatedCol);
associatedDoppler_Hz = dopplerAxis_Hz(associatedRow);
delayError_s = abs(associatedDelay_s - associationDelay_s);
dopplerError_Hz = abs(associatedDoppler_Hz - associationDoppler_Hz);

measurementRow = localMeasurementRowTemplate();
measurementRow.SuiteId = string(probeRow.SuiteId);
measurementRow.CaseDatasetId = string(probeRow.CaseDatasetId);
measurementRow.ProbeSourceCaseId = string(probeRow.CaseDatasetId);
measurementRow.TargetId = string(probeRow.TargetId);
measurementRow.WindowLabel = string(probeRow.WindowLabel);
measurementRow.CpiStart_s = double(probeRow.CpiStart_s);
measurementRow.CpiDuration_s = double(probeRow.CpiDuration_s);
measurementRow.TruthTime_s = double(probeRow.TruthTime_s);
measurementRow.ExpectedDelay_s = double(probeRow.ExpectedDelay_s);
measurementRow.ExpectedBistaticDoppler_Hz = ...
    double(probeRow.ExpectedBistaticDoppler_Hz);
measurementRow.AssociationDelay_s = associationDelay_s;
measurementRow.AssociationDoppler_Hz = associationDoppler_Hz;
measurementRow.AssociatedDelay_s = associatedDelay_s;
measurementRow.AssociatedDoppler_Hz = associatedDoppler_Hz;
measurementRow.DelayError_s = delayError_s;
measurementRow.DelayError_nativeSamples = delayError_s .* ...
    nativeSampleRateHz;
measurementRow.DopplerError_Hz = dopplerError_Hz;
measurementRow.TargetPeak_dB = pow2db(double(targetPeakPower));
measurementRow.LocalMedian_dB = pow2db(localMedianPower);
measurementRow.LocalProminence_dB = double(localProminence_dB);
measurementRow.RobustZ = double(robustZ);
measurementRow.LocalPercentile = double(localPercentile);
measurementRow.NearestDelayBin = double(delayIndex);
measurementRow.NearestDopplerBin = double(dopplerIndex);
measurementRow.AssociatedDelayBin = double(associatedCol);
measurementRow.AssociatedDopplerBin = double(associatedRow);
measurementRow.MapSampleRateHz = double(mapSampleRateHz);
measurementRow.MapDelayBinWidth_s = 1.0 ./ double(mapSampleRateHz);
measurementRow.MapDopplerBinWidth_Hz = localMedianDiff(dopplerAxis_Hz);
measurementRow.TruthNote = string(probeRow.TruthNote);

end

function representativeMap = localBuildRepresentativeMap(windowLabel, ...
    cpiStart_s, cpiDuration_s, mapLinear, delayAxis_s, dopplerAxis_Hz, ...
    resolvedOptions)

reviewLinearMap = single(imresize(mapLinear, [
    resolvedOptions.ReviewMapRows
    resolvedOptions.ReviewMapCols
    ], "bilinear"));
reviewMagnitude = sqrt(max(reviewLinearMap, eps("single")));
reviewMap_dB = max(mag2db(reviewMagnitude), ...
    resolvedOptions.FigureFloor_dB);
representativeMap = localEmptyRepresentativeMap();
representativeMap.WindowLabel = string(windowLabel);
representativeMap.CpiStart_s = double(cpiStart_s);
representativeMap.CpiDuration_s = double(cpiDuration_s);
representativeMap.DelayAxis_s = linspace(delayAxis_s(1), ...
    delayAxis_s(end), resolvedOptions.ReviewMapCols);
representativeMap.DopplerAxis_Hz = linspace(dopplerAxis_Hz(1), ...
    dopplerAxis_Hz(end), resolvedOptions.ReviewMapRows).';
representativeMap.ReviewMap_dB = reviewMap_dB;

end

function [controlProbeTable, status] = localBuildControlProbeTable( ...
    suiteRoot, suiteManifest, caseDatasetId, targetTruthTable, ...
    resolvedOptions)

if caseDatasetId ~= resolvedOptions.ControlCaseId
    controlProbeTable = targetTruthTable;
    status = localStatus(false, "Using case truth as control probes.", ...
        localEmptyManifestTable());
    return
end

controlProbeTable = localEmptyTargetTruthTable();
caseIds = resolvedOptions.ControlProbeCaseIds;

for caseIndex = 1:numel(caseIds)
    [probeCaseInfo, probeCaseStatus] = localResolveCaseInfo(suiteManifest, ...
        caseIds(caseIndex));

    if probeCaseStatus.IsBlocked
        status = localStatus(true, ...
            "Control probe source case is missing from suite.", ...
            probeCaseStatus.ValidationTable);
        return
    end

    [probePaths, ~, manifestStatus] = localNormalizeCaseManifest( ...
        suiteRoot, probeCaseInfo, resolvedOptions);

    if manifestStatus.IsBlocked
        status = localStatus(true, ...
            "Control probe source manifest is incomplete.", ...
            manifestStatus.ValidationTable);
        return
    end

    [probeTruth, truthStatus] = localReadTruth(probePaths.TruthPath);

    if truthStatus.IsBlocked
        status = localStatus(true, ...
            "Control probe source truth is unreadable.", ...
            truthStatus.ValidationTable);
        return
    end

    [probeTruthTable, ~, buildStatus] = localBuildTargetTruthTable( ...
        string(suiteManifest.suite_id), caseIds(caseIndex), probeTruth, ...
        probeCaseInfo, resolvedOptions);

    if buildStatus.IsBlocked
        status = localStatus(true, ...
            "Control probe source truth lacks required fields.", ...
            localEmptyManifestTable());
        return
    end

    controlProbeTable = [controlProbeTable; probeTruthTable]; %#ok<AGROW>
end

status = localStatus(false, "Control probe truth rows built.", ...
    localEmptyManifestTable());

end

function [controlMeasurementTable, controlRepresentativeMaps, status] = ...
    localEvaluateControlFalseAlarms( ...
    suiteRoot, suiteManifest, caseDatasetId, caseScan, controlProbeTable, ...
    resolvedOptions)

controlMeasurementTable = localEmptyMeasurementTable();
controlRepresentativeMaps = repmat(localEmptyRepresentativeMap(), 0, 1);
status = localStatus(false, "No control probes required.", ...
    localEmptyManifestTable());
status.InputSampleCount = 0.0;
status.InputRepetitionCount = 0.0;

if isempty(controlProbeTable)
    return
end

if caseDatasetId == resolvedOptions.ControlCaseId
    controlScan = caseScan;
    validationRows = localManifestRow("negative_control_scan_source", ...
        resolvedOptions.ControlCaseId, true, true, ...
        "current case is the required control");
else
    [controlCaseInfo, controlCaseStatus] = localResolveCaseInfo( ...
        suiteManifest, resolvedOptions.ControlCaseId);

    if controlCaseStatus.IsBlocked
        status = localStatus(true, "Required real_only_control is missing.", ...
            controlCaseStatus.ValidationTable);
        status.InputSampleCount = 0.0;
        status.InputRepetitionCount = 0.0;
        return
    end

    [controlPaths, controlManifest, manifestStatus] = ...
        localNormalizeCaseManifest(suiteRoot, controlCaseInfo, ...
        resolvedOptions);

    if manifestStatus.IsBlocked
        status = localStatus(true, ...
            "Required real_only_control manifest is incomplete.", ...
            manifestStatus.ValidationTable);
        status.InputSampleCount = 0.0;
        status.InputRepetitionCount = 0.0;
        return
    end

    [controlScan, readStatus] = localReadBasebandForG45( ...
        controlPaths.RadarPath, controlManifest, true);
    validationRows = [manifestStatus.ValidationTable; ...
        readStatus.ValidationTable];

    if readStatus.IsBlocked
        status = localStatus(true, ...
            "Required real_only_control baseband could not be read.", ...
            validationRows);
        status.InputSampleCount = 0.0;
        status.InputRepetitionCount = 0.0;
        return
    end
end

[controlMeasurementTable, controlRepresentativeMaps] = localEvaluateProbeRowsOnScan( ...
    controlScan, controlProbeTable, resolvedOptions);
status = localStatus(false, "Negative control false-alarm probes measured.", ...
    validationRows);
status.InputSampleCount = double(controlScan.NumSamples);
status.InputRepetitionCount = 1.0;

end

function falseAlarmSummaryTable = localBuildFalseAlarmSummaryTable( ...
    suiteId, caseDatasetId, controlMeasurementTable, resolvedOptions)

falseAlarmSummaryTable = localEmptyFalseAlarmSummaryTable();

if isempty(controlMeasurementTable)
    return
end

rowCount = height(controlMeasurementTable);
rows = repmat(localFalseAlarmSummaryRowTemplate(), rowCount, 1);

for idx = 1:rowCount
    measurement = controlMeasurementTable(idx, :);
    falseAlarmStatus = "CONTROL_CLEAN";
    notes = "Control probe remained below warn threshold.";

    if measurement.LocalProminence_dB >= ...
            resolvedOptions.PassProminence_dB && ...
            measurement.RobustZ >= resolvedOptions.PassRobustZ
        falseAlarmStatus = "CONTROL_FALSE_ALARM_PASS_LEVEL";
        notes = "Control probe reached pass-level recovery thresholds.";
    elseif measurement.LocalProminence_dB >= ...
            resolvedOptions.WarnProminence_dB && ...
            measurement.RobustZ >= resolvedOptions.WarnRobustZ
        falseAlarmStatus = "CONTROL_FALSE_ALARM_WARN_LEVEL";
        notes = "Control probe reached warn-level recovery thresholds.";
    end

    rows(idx).SuiteId = suiteId;
    rows(idx).CaseDatasetId = caseDatasetId;
    rows(idx).ControlCaseId = resolvedOptions.ControlCaseId;
    rows(idx).ProbeSourceCaseId = string(measurement.CaseDatasetId);
    rows(idx).TargetId = string(measurement.TargetId);
    rows(idx).WindowLabel = string(measurement.WindowLabel);
    rows(idx).ExpectedDelay_s = double(measurement.ExpectedDelay_s);
    rows(idx).ExpectedBistaticDoppler_Hz = ...
        double(measurement.ExpectedBistaticDoppler_Hz);
    rows(idx).AssociationDelay_s = double(measurement.AssociationDelay_s);
    rows(idx).AssociationDoppler_Hz = ...
        double(measurement.AssociationDoppler_Hz);
    rows(idx).ControlPeak_dB = double(measurement.TargetPeak_dB);
    rows(idx).ControlProminence_dB = ...
        double(measurement.LocalProminence_dB);
    rows(idx).ControlRobustZ = double(measurement.RobustZ);
    rows(idx).ControlLocalPercentile = ...
        double(measurement.LocalPercentile);
    rows(idx).FalseAlarmStatus = falseAlarmStatus;
    rows(idx).Notes = notes;
end

falseAlarmSummaryTable = struct2table(rows);

end

function targetRecoveryTable = localBuildTargetRecoveryTable(suiteId, ...
    caseDatasetId, targetMeasurementTable, falseAlarmSummaryTable, ...
    resolvedOptions)

targetRecoveryTable = localEmptyTargetRecoveryTable();

if isempty(targetMeasurementTable)
    return
end

rowCount = height(targetMeasurementTable);
rows = repmat(localTargetRecoveryRowTemplate(), rowCount, 1);

for idx = 1:rowCount
    measurement = targetMeasurementTable(idx, :);
    controlMatch = localFindControlMatch(measurement, ...
        falseAlarmSummaryTable);
    controlProminence_dB = NaN;
    controlRobustZ = NaN;
    controlLift_dB = NaN;
    controlStatus = "CONTROL_NOT_AVAILABLE";

    if ~isempty(controlMatch)
        controlProminence_dB = double(controlMatch.ControlProminence_dB(1));
        controlRobustZ = double(controlMatch.ControlRobustZ(1));
        controlLift_dB = double(measurement.LocalProminence_dB) - ...
            controlProminence_dB;
        controlStatus = string(controlMatch.FalseAlarmStatus(1));
    end

    mapSampleRateHz = double(measurement.MapSampleRateHz(1));
    delayError_s = double(measurement.DelayError_s(1));
    dopplerError_Hz = double(measurement.DopplerError_Hz(1));
    localProminence_dB = double(measurement.LocalProminence_dB(1));
    robustZ = double(measurement.RobustZ(1));
    delayTolerance_s = resolvedOptions.DelayToleranceMapBins ./ ...
        mapSampleRateHz;
    associationWithinTolerance = all([
        delayError_s <= delayTolerance_s
        dopplerError_Hz <= resolvedOptions.DopplerTolerance_Hz
        ]);
    passNumeric = associationWithinTolerance && ...
        localProminence_dB >= resolvedOptions.PassProminence_dB && ...
        robustZ >= resolvedOptions.PassRobustZ;
    warnNumeric = associationWithinTolerance && ...
        localProminence_dB >= resolvedOptions.WarnProminence_dB && ...
        robustZ >= resolvedOptions.WarnRobustZ;
    controlPassLevel = strcmp(controlStatus, "CONTROL_FALSE_ALARM_PASS_LEVEL");
    controlLiftScalar_dB = double(controlLift_dB(1));
    controlLiftPass = isfinite(controlLiftScalar_dB) && ...
        controlLiftScalar_dB >= resolvedOptions.MinControlLiftForPass_dB;

    if passNumeric && ~controlPassLevel && controlLiftPass
        recoveryStatus = "RECOVERED";
        thresholdDecision = "pass_threshold_met";
        caveat = "";
    elseif warnNumeric && ~controlPassLevel
        recoveryStatus = "WEAK_RECOVERY";
        thresholdDecision = "warn_threshold_met";
        caveat = "Target is numerically localized but below pass margin " + ...
            "or not clearly separated from control.";
    else
        recoveryStatus = "NOT_RECOVERED";
        thresholdDecision = "threshold_not_met";
        caveat = "Target association did not meet numeric recovery " + ...
            "thresholds.";
    end

    rows(idx).SuiteId = suiteId;
    rows(idx).CaseDatasetId = caseDatasetId;
    rows(idx).TargetId = string(measurement.TargetId);
    rows(idx).WindowLabel = string(measurement.WindowLabel);
    rows(idx).CpiStart_s = double(measurement.CpiStart_s);
    rows(idx).CpiDuration_s = double(measurement.CpiDuration_s);
    rows(idx).TruthTime_s = double(measurement.TruthTime_s);
    rows(idx).ExpectedDelay_s = double(measurement.ExpectedDelay_s);
    rows(idx).ExpectedBistaticDoppler_Hz = ...
        double(measurement.ExpectedBistaticDoppler_Hz);
    rows(idx).AssociationDelay_s = double(measurement.AssociationDelay_s);
    rows(idx).AssociationDoppler_Hz = ...
        double(measurement.AssociationDoppler_Hz);
    rows(idx).AssociatedDelay_s = double(measurement.AssociatedDelay_s);
    rows(idx).AssociatedDoppler_Hz = ...
        double(measurement.AssociatedDoppler_Hz);
    rows(idx).DelayError_s = double(measurement.DelayError_s);
    rows(idx).DelayError_nativeSamples = ...
        double(measurement.DelayError_nativeSamples);
    rows(idx).DopplerError_Hz = double(measurement.DopplerError_Hz);
    rows(idx).TargetPeak_dB = double(measurement.TargetPeak_dB);
    rows(idx).LocalMedian_dB = double(measurement.LocalMedian_dB);
    rows(idx).LocalProminence_dB = ...
        double(measurement.LocalProminence_dB);
    rows(idx).RobustZ = double(measurement.RobustZ);
    rows(idx).LocalPercentile = double(measurement.LocalPercentile);
    rows(idx).ControlProminence_dB = controlProminence_dB;
    rows(idx).ControlRobustZ = controlRobustZ;
    rows(idx).ControlLift_dB = controlLift_dB;
    rows(idx).ControlFalseAlarmStatus = controlStatus;
    rows(idx).AssociationWithinTolerance = associationWithinTolerance;
    rows(idx).RecoveryStatus = recoveryStatus;
    rows(idx).ThresholdDecision = thresholdDecision;
    rows(idx).Caveat = caveat;
end

targetRecoveryTable = struct2table(rows);

end

function [gateDecision, failureCause, nextBranch, targetSummary] = ...
    localDecideCase(~, caseInfo, targetRecoveryTable, ...
    falseAlarmSummaryTable, truthBuildStatus, resolvedOptions)

injectionEnabled = localLogicalField(caseInfo, "injection_enabled", false);
difficultyLabel = localStringField(caseInfo, "difficulty_label", "");
optionalCaveats = string(truthBuildStatus.OptionalCaveatCodes(:));
hasOptionalCaveat = any(strlength(optionalCaveats) > 0);
hasPassLevelControlFalseAlarm = any( ...
    falseAlarmSummaryTable.FalseAlarmStatus == ...
    "CONTROL_FALSE_ALARM_PASS_LEVEL");
hasWarnLevelControlFalseAlarm = any( ...
    falseAlarmSummaryTable.FalseAlarmStatus == ...
    "CONTROL_FALSE_ALARM_WARN_LEVEL");

targetSummary = struct();
targetSummary.ExpectedTargetCount = localDoubleField(caseInfo, ...
    "number_of_targets", 0);
targetSummary.RecoveredTargetCount = 0.0;
targetSummary.WeakTargetCount = 0.0;
targetSummary.NotRecoveredTargetCount = 0.0;
targetSummary.BestProminence_dB = NaN;
targetSummary.BestRobustZ = NaN;
targetSummary.HasWarnLevelControlFalseAlarm = hasWarnLevelControlFalseAlarm;
targetSummary.HasPassLevelControlFalseAlarm = hasPassLevelControlFalseAlarm;
targetSummary.OptionalCaveatCodes = optionalCaveats;

if ~injectionEnabled
    passLevelControlRows = falseAlarmSummaryTable( ...
        falseAlarmSummaryTable.FalseAlarmStatus == ...
        "CONTROL_FALSE_ALARM_PASS_LEVEL", :);
    uniquePassLevelControlRows = unique(passLevelControlRows(:, ...
        ["TargetId", "WindowLabel", "AssociationDelay_s", ...
        "AssociationDoppler_Hz"]), "rows");
    passLevelControlCount = height(uniquePassLevelControlRows);

    if passLevelControlCount >= resolvedOptions.ControlFailPassWindowCount
        gateDecision = "CONTROL_FAIL";
        failureCause = "real_only_control produced pass-level target-like " + ...
            "responses at synthetic truth probes.";
        nextBranch = "tighten_threshold_policy_before_trusting_g45";
    else
        gateDecision = "CONTROL_PASS";
        failureCause = "";
        nextBranch = "use_control_as_false_confidence_guard_for_g45";
    end

    return
end

if isempty(targetRecoveryTable)
    gateDecision = "BLOCKED";
    failureCause = "No target recovery rows were produced for injected case.";
    nextBranch = "repair_g45_truth_or_map_generation_inputs";
    return
end

targetIds = unique(targetRecoveryTable.TargetId, "stable");
targetBestStatus = strings(numel(targetIds), 1);
bestProminence = NaN(numel(targetIds), 1);
bestRobustZ = NaN(numel(targetIds), 1);

for targetIndex = 1:numel(targetIds)
    subset = targetRecoveryTable(targetRecoveryTable.TargetId == ...
        targetIds(targetIndex), :);
    recovered = any(subset.RecoveryStatus == "RECOVERED");
    weak = any(subset.RecoveryStatus == "WEAK_RECOVERY");
    [bestProminence(targetIndex), bestIndex] = max( ...
        subset.LocalProminence_dB);
    bestRobustZ(targetIndex) = subset.RobustZ(bestIndex);

    if recovered
        targetBestStatus(targetIndex) = "RECOVERED";
    elseif weak
        targetBestStatus(targetIndex) = "WEAK_RECOVERY";
    else
        targetBestStatus(targetIndex) = "NOT_RECOVERED";
    end
end

recoveredCount = nnz(targetBestStatus == "RECOVERED");
weakCount = nnz(targetBestStatus == "WEAK_RECOVERY");
notRecoveredCount = nnz(targetBestStatus == "NOT_RECOVERED");
targetSummary.RecoveredTargetCount = double(recoveredCount);
targetSummary.WeakTargetCount = double(weakCount);
targetSummary.NotRecoveredTargetCount = double(notRecoveredCount);
targetSummary.BestProminence_dB = max(bestProminence, [], "omitnan");
targetSummary.BestRobustZ = max(bestRobustZ, [], "omitnan");


if recoveredCount == numel(targetIds)
    gateDecision = "PASS";
    failureCause = "";
    nextBranch = "record_g45_as_diagnostic_only_do_not_promote_g5";
elseif recoveredCount + weakCount == numel(targetIds)
    gateDecision = "WARN";
    failureCause = "All injected targets were numerically localized, " + ...
        "but at least one target only met warn-level margins.";
    nextBranch = "review_threshold_sensitivity_before_downstream_use";
else
    gateDecision = "FAIL";
    failureCause = "One or more injected targets were not numerically " + ...
        "recovered under baseline no-mitigation settings.";
    nextBranch = "debug_baseline_map_or_signal_chain_before_mitigation";
end

if difficultyLabel == "hard" && gateDecision == "PASS"
    gateDecision = "WARN";
    failureCause = "Hard case recovered numerically but is retained as " + ...
        "WARN by gate policy.";
    nextBranch = "review_sensitivity_margin_on_hard_case";
end

if difficultyLabel == "marginal" && gateDecision == "PASS"
    gateDecision = "WARN";
    failureCause = "Marginal case cannot pass on visual confidence; " + ...
        "numeric threshold sensitivity remains the intended outcome.";
    nextBranch = "review_threshold_sensitivity_on_marginal_case";
end

if hasOptionalCaveat && gateDecision == "PASS"
    gateDecision = "WARN";
    failureCause = "Optional truth bins, strength, or geometry metadata " + ...
        "were missing, so the case is caveated.";
    nextBranch = "fill_optional_truth_metadata_or_accept_warn_caveat";
end


end

function diagnosticInterpretationTable = localBuildDiagnosticInterpretationTable( ...
    gateDecision, caseDatasetId, caseInfo, targetSummary, ...
    falseAlarmSummaryTable, truthBuildStatus)

issueSources = [
    "pipeline_suspect"
    "acquisition_or_scene_likely"
    "threshold_policy_suspect"
    "sensitivity_limited"
    ];
active = false(4, 1);
severity = strings(4, 1);
evidence = strings(4, 1);
recommendedBranch = strings(4, 1);
gateDecision = string(gateDecision);
difficultyLabel = localStringField(caseInfo, "difficulty_label", "");

active(1) = ismember(gateDecision, ["FAIL", "BLOCKED"]) && ...
    string(caseDatasetId) ~= "real_only_control";
severity(1) = localSeverity(active(1), "high");
evidence(1) = sprintf("Decision %s with %.0f recovered, %.0f weak, %.0f not recovered targets.", ...
    gateDecision, targetSummary.RecoveredTargetCount, ...
    targetSummary.WeakTargetCount, targetSummary.NotRecoveredTargetCount);
recommendedBranch(1) = "debug_baseline_map_or_reader_chain";

active(2) = ismember(gateDecision, ["PASS", "CONTROL_PASS"]);
severity(2) = localSeverity(active(2), "info");
evidence(2) = "Synthetic recovery passed or control stayed clean, so " + ...
    "real-field G4 limits are more likely acquisition/scene observability.";
recommendedBranch(2) = "keep_g45_diagnostic_do_not_promote_downstream";

active(3) = any(falseAlarmSummaryTable.FalseAlarmStatus == ...
    "CONTROL_FALSE_ALARM_PASS_LEVEL") || any( ...
    falseAlarmSummaryTable.FalseAlarmStatus == ...
    "CONTROL_FALSE_ALARM_WARN_LEVEL");
severity(3) = localSeverity(active(3), "medium");
evidence(3) = "Negative control false-alarm status: " + strjoin( ...
    unique(falseAlarmSummaryTable.FalseAlarmStatus), ", ");
recommendedBranch(3) = "review_threshold_policy_against_control";

active(4) = gateDecision == "WARN" || difficultyLabel == "hard" || ...
    difficultyLabel == "marginal" || ...
    any(strlength(string(truthBuildStatus.OptionalCaveatCodes)) > 0);
severity(4) = localSeverity(active(4), "medium");
evidence(4) = "Case is sensitivity or metadata caveated; best prominence " + ...
    sprintf("%.2f dB, best robust Z %.2f.", ...
    targetSummary.BestProminence_dB, targetSummary.BestRobustZ);
recommendedBranch(4) = "review_threshold_sensitivity_and_optional_truth";

diagnosticInterpretationTable = table(issueSources, active, severity, ...
    evidence, recommendedBranch, VariableNames = {'IssueSource', ...
    'Active', 'Severity', 'Evidence', 'RecommendedBranch'});

end

function requirementsCoverageTable = localBuildRequirementsCoverageTable( ...
    gateDecision, caseDatasetId, manifestValidationTable, ...
    targetRecoveryTable, falseAlarmSummaryTable, truthBuildStatus)

requirementId = [
    "G45_REQ_001"
    "G45_REQ_002"
    "G45_REQ_003"
    "G45_REQ_004"
    "G45_REQ_005"
    "G45_REQ_006"
    "G45_REQ_007"
    "G45_REQ_008"
    ];
requirement = [
    "Parse synthetic suite and per-case truth manifests."
    "Do not modify handoff source files."
    "Read .bb through helper/baseband reader path."
    "Use baseline no-mitigation ambgfun map formation."
    "Associate targets by expected delay and bistatic Doppler."
    "Use real_only_control to prevent false confidence."
    "Return BLOCKED instead of crashing on missing required data."
    "Emit numeric recovery metrics and diagnostic interpretation."
    ];
status = repmat("PASS", numel(requirementId), 1);
evidenceArtifact = [
    "manifest_validation_table.csv"
    "manifest_validation_table.csv"
    "manifest_validation_table.csv"
    "target_recovery_table.csv"
    "truth_convention_audit_table.csv"
    "false_alarm_summary_table.csv"
    "decision.txt"
    "metrics.json"
    ];
notes = strings(numel(requirementId), 1);

if any(manifestValidationTable.Status == "BLOCKED")
    status(1) = "BLOCKED";
    status(3) = "BLOCKED";
end

if string(gateDecision) == "BLOCKED"
    status(7) = "PASS";
    notes(7) = "Blocked decision emitted without uncaught crash.";
end

if isempty(targetRecoveryTable) && string(caseDatasetId) ~= ...
        "real_only_control"
    status(4) = "BLOCKED";
    status(5) = "BLOCKED";
    status(8) = "BLOCKED";
end

if any(falseAlarmSummaryTable.FalseAlarmStatus == ...
        "CONTROL_FALSE_ALARM_PASS_LEVEL")
    status(6) = "WARN";
    notes(6) = "Pass-level control probes were recorded and applied " + ...
        "as row-level false-confidence guards.";
else
    status(6) = "PASS";
end

if any(strlength(string(truthBuildStatus.OptionalCaveatCodes)) > 0)
    status(5) = "WARN";
    notes(5) = "Optional bins, strength, or geometry metadata caveat.";
end

requirementsCoverageTable = table(requirementId, requirement, status, ...
    evidenceArtifact, notes, VariableNames = {'RequirementId', ...
    'Requirement', 'Status', 'EvidenceArtifact', 'Notes'});

end

function analysis = localBuildBlockedAnalysis(suiteId, caseDatasetId, ...
    suiteRoot, stageId, resolvedOptions, timingRows, ...
    manifestValidationTable, failureCause)

targetRecoveryTable = localEmptyTargetRecoveryTable();
falseAlarmSummaryTable = localEmptyFalseAlarmSummaryTable();
truthConventionAuditTable = localEmptyTruthConventionAuditTable();
diagnosticInterpretationTable = localBuildDiagnosticInterpretationTable( ...
    "BLOCKED", caseDatasetId, struct("difficulty_label", ""), ...
    localEmptyTargetSummary(), falseAlarmSummaryTable, ...
    localStatus(false, "", localEmptyManifestTable()));
requirementsCoverageTable = localBuildRequirementsCoverageTable( ...
    "BLOCKED", caseDatasetId, manifestValidationTable, ...
    targetRecoveryTable, falseAlarmSummaryTable, ...
    localStatus(false, "", localEmptyManifestTable()));

analysis = struct();
analysis.StageId = string(stageId);
analysis.SuiteId = string(suiteId);
analysis.CaseDatasetId = string(caseDatasetId);
analysis.SuiteRoot = string(suiteRoot);
analysis.CaseRoot = "";
analysis.RadarPath = "";
analysis.TruthPath = "";
analysis.NormalizedManifest = struct();
analysis.Options = resolvedOptions;
analysis.GateDecision = "BLOCKED";
analysis.FailureCause = string(failureCause);
analysis.NextBranch = "repair_g45_required_handoff_data";
analysis.TargetSummary = localEmptyTargetSummary();
analysis.InputSampleCount = 0.0;
analysis.InputRepetitionCount = 0.0;
analysis.SampleRateHz = NaN;
analysis.MapSampleRateHz = NaN;
analysis.CenterFrequencyHz = NaN;
analysis.DecodePath = "";
analysis.Elapsed_s = NaN;
analysis.ManifestValidationTable = manifestValidationTable;
analysis.TruthConventionAuditTable = truthConventionAuditTable;
analysis.TargetRecoveryTable = targetRecoveryTable;
analysis.FalseAlarmSummaryTable = falseAlarmSummaryTable;
analysis.DiagnosticInterpretationTable = diagnosticInterpretationTable;
analysis.RequirementsCoverageTable = requirementsCoverageTable;
analysis.TimingSummaryTable = timingRows;
analysis.RepresentativeMaps = repmat(localEmptyRepresentativeMap(), 0, 1);
analysis.ControlRepresentativeMaps = repmat(localEmptyRepresentativeMap(), 0, 1);

end

function row = localManifestRow(item, pathText, required, passed, detail)

status = "PASS";

if ~passed && required
    status = "BLOCKED";
elseif ~passed
    status = "WARN";
end

row = table(string(item), string(pathText), logical(required), ...
    string(status), string(detail), VariableNames = {'ValidationItem', ...
    'SourcePath', 'Required', 'Status', 'Detail'});

end

function status = localStatus(isBlocked, message, validationTable)

status = struct();
status.IsBlocked = logical(isBlocked);
status.Message = string(message);
status.ValidationTable = validationTable;
status.OptionalCaveatCodes = strings(0, 1);
status.InputSampleCount = 0.0;
status.InputRepetitionCount = 0.0;

end

function tableOut = localAppendTimingRow(tableIn, stageId, stepName, ...
    elapsed_s, inputSampleCount, inputRepetitionCount, notes)

newRow = table(string(stageId), string(stepName), double(elapsed_s), ...
    "review", double(inputSampleCount), double(inputRepetitionCount), ...
    NaN, NaN, NaN, string(notes), VariableNames = {'StageId', ...
    'StepName', 'Elapsed_s', 'ExecutionMode', 'InputSampleCount', ...
    'InputRepetitionCount', 'OutputArtifactCount', 'OutputFigureCount', ...
    'OutputBytes', 'Notes'});
tableOut = [tableIn; newRow];

end

function targetStruct = localResolveTargetStructArray(truth)

targetStruct = struct.empty(0, 1);

if ~isfield(truth, "targets")
    return
end

if isempty(truth.targets)
    return
end

if isstruct(truth.targets)
    targetStruct = truth.targets(:);
end

end

function [truthTime_s, delay_s, doppler_Hz, rangeBin, dopplerBin, ...
    note] = localResolveTruthAtWindow(truthTimes, expectedDelay_s, ...
    expectedDoppler_Hz, expectedRangeBin, expectedDopplerBin, ...
    cpiStart_s, cpiStop_s)

truthTimes = double(truthTimes(:));
expectedDelay_s = double(expectedDelay_s(:));
expectedDoppler_Hz = double(expectedDoppler_Hz(:));
validCount = min([numel(truthTimes), numel(expectedDelay_s), ...
    numel(expectedDoppler_Hz)]);
truthTimes = truthTimes(1:validCount);
expectedDelay_s = expectedDelay_s(1:validCount);
expectedDoppler_Hz = expectedDoppler_Hz(1:validCount);
inWindow = truthTimes >= cpiStart_s & truthTimes <= cpiStop_s;

if any(inWindow)
    selectedMask = inWindow;
    note = "truth_median_inside_cpi";
else
    [~, nearestIndex] = min(abs(truthTimes - mean([cpiStart_s, ...
        cpiStop_s])));
    selectedMask = false(size(truthTimes));
    selectedMask(nearestIndex) = true;
    note = "truth_nearest_to_cpi_center";
end

truthTime_s = median(truthTimes(selectedMask), "omitnan");
delay_s = median(expectedDelay_s(selectedMask), "omitnan");
doppler_Hz = median(expectedDoppler_Hz(selectedMask), "omitnan");
rangeBin = localResolveOptionalWindowMedian(expectedRangeBin, ...
    selectedMask, validCount);
dopplerBin = localResolveOptionalWindowMedian(expectedDopplerBin, ...
    selectedMask, validCount);

end

function value = localResolveOptionalWindowMedian(values, selectedMask, ...
    validCount)

value = NaN;

if isempty(values)
    return
end

values = double(values(:));
count = min(numel(values), validCount);
values = values(1:count);
mask = selectedMask(1:count);

if any(mask)
    value = median(values(mask), "omitnan");
end

end

function optionalStatus = localResolveOptionalTruthStatus(target, truth, ...
    expectedRangeBin, expectedDopplerBin)

caveatCodes = strings(0, 1);

if isempty(expectedRangeBin) || isempty(expectedDopplerBin)
    caveatCodes = [caveatCodes; "missing_optional_expected_bins"];
end

hasStrength = isfield(target, "echo_strength_parameters") || ...
    isfield(target, "target_echo_scale_applied") || ...
    isfield(target, "target_power_relative_to_background_db");

if ~hasStrength
    caveatCodes = [caveatCodes; "missing_optional_strength_metadata"];
end

hasGeometry = isfield(truth, "tx_lla_deg_m") && ...
    isfield(truth, "rx_lla_deg_m");

if ~hasGeometry
    caveatCodes = [caveatCodes; "missing_optional_geometry_metadata"];
end

optionalStatus = struct();
optionalStatus.HasCaveat = ~isempty(caveatCodes);
optionalStatus.CaveatCodes = unique(caveatCodes);

end

function truthConventionAuditTable = localAppendTruthAuditRow( ...
    truthConventionAuditTable, suiteId, caseDatasetId, targetId, ...
    windowLabel, truthTime_s, delay_s, doppler_Hz, associationDelay_s, ...
    associationDoppler_Hz, rangeBin, dopplerBin, optionalStatus, ...
    truthNote, resolvedOptions)

binFieldsPresent = isfinite(rangeBin) && isfinite(dopplerBin);
optionalConventionStatus = "PASS";
notes = "G4 raw-axis association applies documented ambgfun sign " + ...
    "conversion to expected delay and bistatic Doppler.";

if optionalStatus.HasCaveat
    optionalConventionStatus = "WARN";
    notes = notes + " Optional caveats: " + strjoin( ...
        optionalStatus.CaveatCodes, ", ");
end

newRow = table(string(suiteId), string(caseDatasetId), string(targetId), ...
    string(windowLabel), double(truthTime_s), double(delay_s), ...
    double(doppler_Hz), double(associationDelay_s), ...
    double(associationDoppler_Hz), ...
    double(resolvedOptions.DelaySignForG4Raw), ...
    double(resolvedOptions.DopplerSignForG4Raw), double(rangeBin), ...
    double(dopplerBin), logical(binFieldsPresent), ...
    string(optionalConventionStatus), string(truthNote), string(notes), ...
    VariableNames = truthConventionAuditTable.Properties.VariableNames);
truthConventionAuditTable = [truthConventionAuditTable; newRow];

end

function truthConventionAuditTable = localAppendTruthAuditNoTarget( ...
    truthConventionAuditTable, suiteId, caseDatasetId)

newRow = table(string(suiteId), string(caseDatasetId), "", "", NaN, ...
    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, false, ...
    "PASS", "control_case_no_target_truth", ...
    "No injected targets; truth association is intentionally empty.", ...
    VariableNames = truthConventionAuditTable.Properties.VariableNames);
truthConventionAuditTable = [truthConventionAuditTable; newRow];

end

function controlMatch = localFindControlMatch(measurement, ...
    falseAlarmSummaryTable)

controlMatch = table();

if isempty(falseAlarmSummaryTable)
    return
end

matchMask = falseAlarmSummaryTable.ProbeSourceCaseId == ...
    string(measurement.CaseDatasetId) & ...
    falseAlarmSummaryTable.TargetId == string(measurement.TargetId) & ...
    falseAlarmSummaryTable.WindowLabel == string(measurement.WindowLabel);

if any(matchMask)
    controlMatch = falseAlarmSummaryTable(matchMask, :);
end

end

function severity = localSeverity(isActive, activeSeverity)

if isActive
    severity = string(activeSeverity);
else
    severity = "none";
end

end

function value = localStringField(inputStruct, fieldName, defaultValue)

value = string(defaultValue);

if isstruct(inputStruct) && isfield(inputStruct, fieldName)
    value = string(inputStruct.(fieldName));
end

end

function value = localDoubleField(inputStruct, fieldName, defaultValue)

value = double(defaultValue);

if isstruct(inputStruct) && isfield(inputStruct, fieldName)
    candidate = inputStruct.(fieldName);

    if ~isempty(candidate)
        value = double(candidate);
    end
end

end

function value = localLogicalField(inputStruct, fieldName, defaultValue)

value = logical(defaultValue);

if isstruct(inputStruct) && isfield(inputStruct, fieldName)
    value = logical(inputStruct.(fieldName));
end

end

function values = localNumericVectorField(inputStruct, fieldName)

values = [];

if isstruct(inputStruct) && isfield(inputStruct, fieldName)
    values = double(inputStruct.(fieldName)(:));
end

end

function values = localOptionalNumericVectorField(inputStruct, fieldName)

values = [];

if isstruct(inputStruct) && isfield(inputStruct, fieldName)
    candidate = inputStruct.(fieldName);

    if ~isempty(candidate)
        values = double(candidate(:));
    end
end

end

function values = localNestedNumericVector(inputStruct, fieldPath)

values = [];
candidate = inputStruct;

for idx = 1:numel(fieldPath)
    fieldName = fieldPath(idx);

    if ~isstruct(candidate) || ~isfield(candidate, fieldName)
        return
    end

    candidate = candidate.(fieldName);
end

if ~isempty(candidate)
    values = double(candidate(:));
end

end

function index = localFirstNonzeroIndex(channelData)

index = find(channelData ~= 0, 1, "first");

if isempty(index)
    index = NaN;
end

end

function value = localMedianDiff(values)

values = double(values(:));

if numel(values) < 2
    value = NaN;
else
    value = median(abs(diff(values)), "omitnan");
end

end

function scan = localEmptyScan()

scan = struct();
scan.NumSamples = 0.0;
scan.SampleRate = NaN;
scan.CenterFrequency = NaN;
scan.DecodePath = "";
scan.Samples = complex(single.empty(0, 2));

end

function targetSummary = localEmptyTargetSummary()

targetSummary = struct();
targetSummary.ExpectedTargetCount = 0.0;
targetSummary.RecoveredTargetCount = 0.0;
targetSummary.WeakTargetCount = 0.0;
targetSummary.NotRecoveredTargetCount = 0.0;
targetSummary.BestProminence_dB = NaN;
targetSummary.BestRobustZ = NaN;
targetSummary.HasWarnLevelControlFalseAlarm = false;
targetSummary.HasPassLevelControlFalseAlarm = false;
targetSummary.OptionalCaveatCodes = strings(0, 1);

end

function row = localMeasurementRowTemplate()

row = struct();
row.SuiteId = "";
row.CaseDatasetId = "";
row.ProbeSourceCaseId = "";
row.TargetId = "";
row.WindowLabel = "";
row.CpiStart_s = NaN;
row.CpiDuration_s = NaN;
row.TruthTime_s = NaN;
row.ExpectedDelay_s = NaN;
row.ExpectedBistaticDoppler_Hz = NaN;
row.AssociationDelay_s = NaN;
row.AssociationDoppler_Hz = NaN;
row.AssociatedDelay_s = NaN;
row.AssociatedDoppler_Hz = NaN;
row.DelayError_s = NaN;
row.DelayError_nativeSamples = NaN;
row.DopplerError_Hz = NaN;
row.TargetPeak_dB = NaN;
row.LocalMedian_dB = NaN;
row.LocalProminence_dB = NaN;
row.RobustZ = NaN;
row.LocalPercentile = NaN;
row.NearestDelayBin = NaN;
row.NearestDopplerBin = NaN;
row.AssociatedDelayBin = NaN;
row.AssociatedDopplerBin = NaN;
row.MapSampleRateHz = NaN;
row.MapDelayBinWidth_s = NaN;
row.MapDopplerBinWidth_Hz = NaN;
row.TruthNote = "";

end

function row = localTargetRecoveryRowTemplate()

row = struct();
row.SuiteId = "";
row.CaseDatasetId = "";
row.TargetId = "";
row.WindowLabel = "";
row.CpiStart_s = NaN;
row.CpiDuration_s = NaN;
row.TruthTime_s = NaN;
row.ExpectedDelay_s = NaN;
row.ExpectedBistaticDoppler_Hz = NaN;
row.AssociationDelay_s = NaN;
row.AssociationDoppler_Hz = NaN;
row.AssociatedDelay_s = NaN;
row.AssociatedDoppler_Hz = NaN;
row.DelayError_s = NaN;
row.DelayError_nativeSamples = NaN;
row.DopplerError_Hz = NaN;
row.TargetPeak_dB = NaN;
row.LocalMedian_dB = NaN;
row.LocalProminence_dB = NaN;
row.RobustZ = NaN;
row.LocalPercentile = NaN;
row.ControlProminence_dB = NaN;
row.ControlRobustZ = NaN;
row.ControlLift_dB = NaN;
row.ControlFalseAlarmStatus = "";
row.AssociationWithinTolerance = false;
row.RecoveryStatus = "";
row.ThresholdDecision = "";
row.Caveat = "";

end

function row = localFalseAlarmSummaryRowTemplate()

row = struct();
row.SuiteId = "";
row.CaseDatasetId = "";
row.ControlCaseId = "";
row.ProbeSourceCaseId = "";
row.TargetId = "";
row.WindowLabel = "";
row.ExpectedDelay_s = NaN;
row.ExpectedBistaticDoppler_Hz = NaN;
row.AssociationDelay_s = NaN;
row.AssociationDoppler_Hz = NaN;
row.ControlPeak_dB = NaN;
row.ControlProminence_dB = NaN;
row.ControlRobustZ = NaN;
row.ControlLocalPercentile = NaN;
row.FalseAlarmStatus = "";
row.Notes = "";

end

function representativeMap = localEmptyRepresentativeMap()

representativeMap = struct();
representativeMap.WindowLabel = "";
representativeMap.CpiStart_s = NaN;
representativeMap.CpiDuration_s = NaN;
representativeMap.DelayAxis_s = [];
representativeMap.DopplerAxis_Hz = [];
representativeMap.ReviewMap_dB = [];

end

function tableOut = localEmptyManifestTable()

tableOut = table(Size = [0 5], VariableTypes = ...
    ["string", "string", "logical", "string", "string"], ...
    VariableNames = {'ValidationItem', 'SourcePath', 'Required', ...
    'Status', 'Detail'});

end

function tableOut = localEmptyTimingSummaryTable()

tableOut = table(Size = [0 10], VariableTypes = ...
    ["string", "string", "double", "string", "double", "double", ...
    "double", "double", "double", "string"], VariableNames = ...
    {'StageId', 'StepName', 'Elapsed_s', 'ExecutionMode', ...
    'InputSampleCount', 'InputRepetitionCount', 'OutputArtifactCount', ...
    'OutputFigureCount', 'OutputBytes', 'Notes'});

end

function tableOut = localEmptyTargetTruthTable()

tableOut = table(Size = [0 14], VariableTypes = ...
    ["string", "string", "string", "string", "double", "double", ...
    "double", "double", "double", "double", "double", "double", ...
    "double", "string"], VariableNames = {'SuiteId', ...
    'CaseDatasetId', 'TargetId', 'WindowLabel', 'CpiStart_s', ...
    'CpiDuration_s', 'TruthTime_s', 'ExpectedDelay_s', ...
    'ExpectedBistaticDoppler_Hz', 'AssociationDelay_s', ...
    'AssociationDoppler_Hz', 'ExpectedRangeBin', ...
    'ExpectedDopplerBin', 'TruthNote'});

end

function tableOut = localEmptyTruthConventionAuditTable()

tableOut = table(Size = [0 17], VariableTypes = ...
    ["string", "string", "string", "string", "double", "double", ...
    "double", "double", "double", "double", "double", "double", ...
    "double", "logical", "string", "string", "string"], ...
    VariableNames = {'SuiteId', 'CaseDatasetId', 'TargetId', ...
    'WindowLabel', 'TruthTime_s', 'ExpectedDelay_s', ...
    'ExpectedBistaticDoppler_Hz', 'G4AssociationDelay_s', ...
    'G4AssociationDoppler_Hz', 'DelaySignApplied', ...
    'DopplerSignApplied', 'ExpectedRangeBin', 'ExpectedDopplerBin', ...
    'BinFieldsPresent', 'OptionalConventionStatus', 'TruthNote', ...
    'Notes'});

end

function tableOut = localEmptyMeasurementTable()

tableOut = struct2table(repmat(localMeasurementRowTemplate(), 0, 1));

end

function tableOut = localEmptyTargetRecoveryTable()

tableOut = struct2table(repmat(localTargetRecoveryRowTemplate(), 0, 1));

end

function tableOut = localEmptyFalseAlarmSummaryTable()

tableOut = struct2table(repmat(localFalseAlarmSummaryRowTemplate(), 0, 1));

end
