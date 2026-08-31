function analysis = helperAnalyzeG8DetectionPrerequisiteGate(datasetId, repoRoot, options)
%HELPERANALYZEG8DETECTIONPREREQUISITEGATE Refuse formal G8 without prerequisites.

arguments
    datasetId (1,1) string = "20260622T102123"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

datasetId = string(datasetId);
repoRoot = helperResolveRepoRoot(repoRoot);
resolvedOptions = localResolveOptions(options);
sourceG6 = localResolveMetricsSource(datasetId, repoRoot, "G6_CPI_Integration_Freeze", resolvedOptions.SourceG6BundleRoot, resolvedOptions.SourceG6Metrics);
sourceG7 = localResolveMetricsSource(datasetId, repoRoot, "G7_Truth_Context_Diagnostic", resolvedOptions.SourceG7BundleRoot, resolvedOptions.SourceG7Metrics);
sourceSummaryTable = localBuildSourceSummaryTable(sourceG6, sourceG7);
prerequisiteBlockTable = localBuildPrerequisiteBlockTable(sourceG6, sourceG7);
hasBlocks = height(prerequisiteBlockTable) > 0;

if hasBlocks
    gateDecision = "reject";
    reviewStatus = "blocked_missing_prerequisites";
    executionRefused = true;
    refusalReason = strjoin(prerequisiteBlockTable.BlockCode, "; ");
    nextBranch = "hold_g8_until_g6_freeze_and_g7_truth_windows";
else
    gateDecision = "retune";
    reviewStatus = "manual_review_required";
    executionRefused = true;
    refusalReason = "g8_scaffold_does_not_tune_or_execute_detector_on_current_real_data";
    nextBranch = "manual_g8_detector_design_review_required";
end

executionDecisionTable = table( ...
    string(gateDecision), ...
    string(reviewStatus), ...
    logical(executionRefused), ...
    false, ...
    false, ...
    false, ...
    string(refusalReason), ...
    string(nextBranch), ...
    VariableNames = {'GateDecision', 'ReviewStatus', 'ExecutionRefused', 'CfarExecutionEnabled', 'DetectorTuningEnabled', 'DetectionTableEmitted', 'RefusalReason', 'NextBranch'});
requirementsCoverageTable = localBuildRequirementsCoverageTable(refusalReason);
publicContractChangeTable = localBuildPublicContractChangeTable();
detectionSchemaScaffoldTable = localBuildDetectionSchemaScaffoldTable();

analysis = struct();
analysis.DatasetId = datasetId;
analysis.StageId = "G8_Detection_Prerequisite_Gate";
analysis.GateId = "G8_Detection";
analysis.GateDecision = gateDecision;
analysis.ReviewStatus = reviewStatus;
analysis.ExecutionRefused = executionRefused;
analysis.CfarExecutionEnabled = false;
analysis.DetectorTuningEnabled = false;
analysis.DetectionTableEmitted = false;
analysis.RefusalReason = refusalReason;
analysis.NextBranch = nextBranch;
analysis.SourceG6 = sourceG6;
analysis.SourceG7 = sourceG7;
analysis.SourceSummaryTable = sourceSummaryTable;
analysis.PrerequisiteBlockTable = prerequisiteBlockTable;
analysis.ExecutionDecisionTable = executionDecisionTable;
analysis.RequirementsCoverageTable = requirementsCoverageTable;
analysis.PublicContractChangeTable = publicContractChangeTable;
analysis.DetectionSchemaScaffoldTable = detectionSchemaScaffoldTable;

end

function resolvedOptions = localResolveOptions(options)

resolvedOptions = struct();
resolvedOptions.SourceG6BundleRoot = localStringOption(options, "SourceG6BundleRoot", "");
resolvedOptions.SourceG7BundleRoot = localStringOption(options, "SourceG7BundleRoot", "");
resolvedOptions.SourceG6Metrics = localStructOption(options, "SourceG6Metrics");
resolvedOptions.SourceG7Metrics = localStructOption(options, "SourceG7Metrics");

end

function value = localStringOption(options, fieldName, defaultValue)

value = string(defaultValue);

if isfield(options, fieldName)
    value = string(options.(fieldName));
end

end

function value = localStructOption(options, fieldName)

value = struct();

if isfield(options, fieldName)
    candidate = options.(fieldName);

    if isstruct(candidate)
        value = candidate;
    end
end

end

function metricsSource = localResolveMetricsSource(datasetId, repoRoot, gateId, explicitBundleRoot, explicitMetrics)

metricsSource = struct();
metricsSource.GateId = string(gateId);
metricsSource.BundleRoot = "";
metricsSource.MetricsPath = "";
metricsSource.Metrics = struct();
metricsSource.Available = false;
metricsSource.LoadMessage = "";

if ~isempty(fieldnames(explicitMetrics))
    metricsSource.Metrics = explicitMetrics;
    metricsSource.Available = true;
    metricsSource.BundleRoot = localStringField(explicitMetrics, ["bundle_root", "BundleRoot"], "");
    metricsSource.LoadMessage = "Using injected metrics.";
    return
end

if strlength(explicitBundleRoot) > 0
    bundleRoot = explicitBundleRoot;
else
    bundleRoot = localFindLatestBundleRoot(repoRoot, datasetId, gateId);
end

if strlength(bundleRoot) == 0
    metricsSource.LoadMessage = "No complete bundle with metrics.json was found.";
    return
end

metricsPath = fullfile(bundleRoot, "metrics.json");

try
    metricsText = fileread(metricsPath);
    metricsSource.Metrics = jsondecode(metricsText);
catch readException
    error("helperAnalyzeG8DetectionPrerequisiteGate:ReadMetricsFailed", "Failed to read %s: %s", metricsPath, readException.message);
end

metricsSource.Available = true;
metricsSource.BundleRoot = string(bundleRoot);
metricsSource.MetricsPath = string(metricsPath);
metricsSource.LoadMessage = "Loaded metrics.json.";

end

function bundleRoot = localFindLatestBundleRoot(repoRoot, datasetId, gateId)

stageRoot = fullfile(repoRoot, "artifacts", datasetId, gateId);
bundleRoot = "";

if ~isfolder(stageRoot)
    return
end

listing = dir(stageRoot);
names = string({listing.name}).';
isDirectory = [listing.isdir].';
isCandidate = isDirectory & names ~= "." & names ~= "..";
candidateNames = names(isCandidate);

if isempty(candidateNames)
    return
end

candidateRoots = fullfile(stageRoot, candidateNames);
candidateMetricsPaths = fullfile(candidateRoots, "metrics.json");
hasMetrics = isfile(candidateMetricsPaths);
validNames = candidateNames(hasMetrics);
validRoots = candidateRoots(hasMetrics);

if isempty(validRoots)
    return
end

[~, order] = sort(validNames, "descend");
bundleRoot = string(validRoots(order(1)));

end

function sourceSummaryTable = localBuildSourceSummaryTable(sourceG6, sourceG7)

gateId = [
    "G6_CPI_Integration_Freeze"
    "G7_Truth_Context_Diagnostic"
    ];
bundleRoot = [
    string(sourceG6.BundleRoot)
    string(sourceG7.BundleRoot)
    ];
metricsPath = [
    string(sourceG6.MetricsPath)
    string(sourceG7.MetricsPath)
    ];
available = [
    logical(sourceG6.Available)
    logical(sourceG7.Available)
    ];
statusLabel = [
    localStringField(sourceG6.Metrics, ["freeze_status", "FreezeStatus"], "missing")
    localStringField(sourceG7.Metrics, ["review_status", "ReviewStatus"], "missing")
    ];
prerequisiteEnabled = [
    localLogicalField(sourceG6.Metrics, ["detector_product_freeze_enabled", "DetectorProductFreezeEnabled"], false)
    localLogicalField(sourceG7.Metrics, ["truth_claims_enabled", "TruthClaimsEnabled"], false)
    ];
notes = [
    "G8 requires a frozen detector input product from G6."
    "G8 requires G7 truth windows before truth-correlated detection validation."
    ];
sourceSummaryTable = table(gateId, bundleRoot, metricsPath, available, statusLabel, prerequisiteEnabled, notes, VariableNames = {'GateId', 'BundleRoot', 'MetricsPath', 'Available', 'StatusLabel', 'PrerequisiteEnabled', 'Notes'});

end

function prerequisiteBlockTable = localBuildPrerequisiteBlockTable(sourceG6, sourceG7)

blockSource = strings(0, 1);
blockCode = strings(0, 1);
severity = strings(0, 1);
evidenceValue = strings(0, 1);
requiredAction = strings(0, 1);

if ~sourceG6.Available
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G6", "missing_g6_freeze_bundle", "blocking", sourceG6.LoadMessage, "Run G6 and produce a frozen detector input product before formal G8.");
else
    g6FreezeEnabled = localLogicalField(sourceG6.Metrics, ["detector_product_freeze_enabled", "DetectorProductFreezeEnabled"], false);
    g6FreezeStatus = localStringField(sourceG6.Metrics, ["freeze_status", "FreezeStatus"], "missing");

    if ~g6FreezeEnabled
        [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G6", "g6_detector_product_not_frozen", "blocking", g6FreezeStatus, "Keep G8 formal detection blocked until G6 freezes a product.");
    end
end

if ~sourceG7.Available
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G7", "missing_g7_truth_window_bundle", "blocking", sourceG7.LoadMessage, "Run G7 truth-window evidence after G6 freeze before formal G8.");
else
    truthClaimsEnabled = localLogicalField(sourceG7.Metrics, ["truth_claims_enabled", "TruthClaimsEnabled"], false);
    claimBlockReason = localStringField(sourceG7.Metrics, ["claim_block_reason", "ClaimBlockReason"], "missing");

    if ~truthClaimsEnabled
        [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G7", "g7_truth_claims_not_enabled", "blocking", claimBlockReason, "Keep G8 truth-correlated validation blocked until G7 enables truth windows.");
    end
end

prerequisiteBlockTable = table(blockSource, blockCode, severity, evidenceValue, requiredAction, VariableNames = {'BlockSource', 'BlockCode', 'Severity', 'EvidenceValue', 'RequiredAction'});

end

function [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, newSource, newCode, newSeverity, newValue, newAction)

blockSource(end + 1, 1) = string(newSource);
blockCode(end + 1, 1) = string(newCode);
severity(end + 1, 1) = string(newSeverity);
evidenceValue(end + 1, 1) = string(newValue);
requiredAction(end + 1, 1) = string(newAction);

end

function requirementsCoverageTable = localBuildRequirementsCoverageTable(refusalReason)

requirementId = [
    "DET-001"
    "DET-002"
    "DET-003"
    "DET-004"
    ];
gateId = repmat("G8_Detection", 4, 1);
status = repmat("blocked", 4, 1);
evidenceReference = [
    "source_summary_table.csv"
    "execution_decision_table.csv"
    "execution_decision_table.csv"
    "detection_schema_scaffold_table.csv"
    ];
notes = [
    "Frozen detector input product missing or disabled upstream."
    "CFAR threshold control not run on current real data."
    "Truth-window hit rate and persistence not computed."
    "Detection record schema is documented as scaffold only; no detection rows emitted."
    ] + " Refusal: " + string(refusalReason);
requirementsCoverageTable = table(requirementId, gateId, status, evidenceReference, notes, VariableNames = {'RequirementId', 'GateId', 'Status', 'EvidenceReference', 'Notes'});

end

function publicContractChangeTable = localBuildPublicContractChangeTable()

contractItem = [
    "G8 formal execution"
    "G8 detector tuning"
    "G8 detection records"
    ];
changeType = [
    "explicit_prerequisite_refusal"
    "disabled_on_current_real_data"
    "schema_scaffold_only"
    ];
downstreamEffect = [
    "Formal G8 refuses to run unless G6 freeze and G7 truth-window prerequisites are present."
    "No detector thresholds are tuned against the current diagnostic-only dataset."
    "G9 tracker readiness remains blocked because no validated detection table is emitted."
    ];
publicContractChangeTable = table(contractItem, changeType, downstreamEffect, VariableNames = {'ContractItem', 'ChangeType', 'DownstreamEffect'});

end

function detectionSchemaScaffoldTable = localBuildDetectionSchemaScaffoldTable()

fieldName = [
    "FrameId"
    "CaptureId"
    "DetectionTimeUtc"
    "Delay_s"
    "Doppler_Hz"
    "Snr_dB"
    "Threshold"
    "NoiseEstimate"
    "TruthWindowAssociation"
    "DetectionStatus"
    ];
unit = [
    "count"
    "count"
    "UTC"
    "s"
    "Hz"
    "dB"
    "linear_or_dB_declared_by_future_detector"
    "linear_or_dB_declared_by_future_detector"
    "label"
    "label"
    ];
status = repmat("schema_only_no_detection_rows", numel(fieldName), 1);
notes = repmat("Formal detector execution is blocked in this scaffold.", numel(fieldName), 1);
detectionSchemaScaffoldTable = table(fieldName, unit, status, notes, VariableNames = {'FieldName', 'Unit', 'Status', 'Notes'});

end

function value = localStringField(inputStruct, fieldNames, defaultValue)

value = string(defaultValue);

if ~isstruct(inputStruct)
    return
end

candidateNames = string(fieldNames);
structFields = string(fieldnames(inputStruct));
matchIndex = find(ismember(candidateNames, structFields), 1, "first");

if isempty(matchIndex)
    return
end

fieldValue = inputStruct.(candidateNames(matchIndex));

if isstring(fieldValue) || ischar(fieldValue)
    value = string(fieldValue);
elseif isnumeric(fieldValue) || islogical(fieldValue)
    value = string(fieldValue);
end

if numel(value) > 1
    value = value(1);
end

end

function value = localLogicalField(inputStruct, fieldNames, defaultValue)

value = logical(defaultValue);

if ~isstruct(inputStruct)
    return
end

candidateNames = string(fieldNames);
structFields = string(fieldnames(inputStruct));
matchIndex = find(ismember(candidateNames, structFields), 1, "first");

if isempty(matchIndex)
    return
end

fieldValue = inputStruct.(candidateNames(matchIndex));

if islogical(fieldValue) && isscalar(fieldValue)
    value = logical(fieldValue);
elseif isnumeric(fieldValue) && isscalar(fieldValue)
    value = fieldValue ~= 0;
elseif isstring(fieldValue) || ischar(fieldValue)
    value = any(strcmpi(string(fieldValue), ["true", "1", "yes"]));
end

end
