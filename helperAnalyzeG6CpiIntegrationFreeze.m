function analysis = helperAnalyzeG6CpiIntegrationFreeze(datasetId, repoRoot, options)
%HELPERANALYZEG6CPIINTEGRATIONFREEZE Build conservative G6 freeze evidence.

arguments
    datasetId (1,1) string = "20260622T102123"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

datasetId = string(datasetId);
repoRoot = helperResolveRepoRoot(repoRoot);
resolvedOptions = localResolveOptions(options);
sourceEvidence = localResolveSourceEvidence(datasetId, repoRoot, resolvedOptions);
sourceGateSummaryTable = localBuildSourceGateSummaryTable(sourceEvidence);
upstreamBlockTable = localBuildUpstreamBlockTable(sourceEvidence);
hasBlockingEvidence = height(upstreamBlockTable) > 0;

if hasBlockingEvidence
    gateDecision = "reject";
    reviewStatus = "blocked_by_upstream";
    freezeStatus = "freeze_deferred";
    detectorProductFreezeEnabled = false;
    normalFreezeRefused = true;
    refusalReason = strjoin(upstreamBlockTable.BlockCode, "; ");
    nextBranch = "hold_at_g6_until_g4_g5_pass_formal_freeze_inputs";
else
    gateDecision = "retune";
    reviewStatus = "manual_review_required";
    freezeStatus = "not_frozen_pending_manual_review";
    detectorProductFreezeEnabled = false;
    normalFreezeRefused = true;
    refusalReason = "no_upstream_block_detected_but_scaffold_does_not_freeze_products";
    nextBranch = "manual_g6_freeze_review_required";
end

freezeDecisionTable = table( ...
    string(gateDecision), ...
    string(reviewStatus), ...
    string(freezeStatus), ...
    logical(detectorProductFreezeEnabled), ...
    logical(normalFreezeRefused), ...
    string(refusalReason), ...
    string(nextBranch), ...
    VariableNames = {'GateDecision', 'ReviewStatus', 'FreezeStatus', 'DetectorProductFreezeEnabled', 'NormalFreezeRefused', 'RefusalReason', 'NextBranch'});

frozenProductDefinition = localBuildFrozenProductDefinition(datasetId, sourceEvidence, freezeStatus);
requirementsCoverageTable = localBuildRequirementsCoverageTable(freezeStatus, refusalReason);
publicContractChangeTable = localBuildPublicContractChangeTable();
datasetInterpretation = localBuildDatasetInterpretation(sourceEvidence);

analysis = struct();
analysis.DatasetId = datasetId;
analysis.StageId = "G6_CPI_Integration_Freeze";
analysis.GateId = "G6_CPI_Integration";
analysis.GateDecision = gateDecision;
analysis.ReviewStatus = reviewStatus;
analysis.FreezeStatus = freezeStatus;
analysis.DetectorProductFreezeEnabled = detectorProductFreezeEnabled;
analysis.NormalFreezeRefused = normalFreezeRefused;
analysis.RefusalReason = refusalReason;
analysis.NextBranch = nextBranch;
analysis.SourceEvidence = sourceEvidence;
analysis.SourceGateSummaryTable = sourceGateSummaryTable;
analysis.UpstreamBlockTable = upstreamBlockTable;
analysis.FreezeDecisionTable = freezeDecisionTable;
analysis.FrozenProductDefinition = frozenProductDefinition;
analysis.RequirementsCoverageTable = requirementsCoverageTable;
analysis.PublicContractChangeTable = publicContractChangeTable;
analysis.DatasetInterpretation = datasetInterpretation;

end

function resolvedOptions = localResolveOptions(options)

resolvedOptions = struct();
resolvedOptions.SourceG4BundleRoot = localStringOption(options, "SourceG4BundleRoot", "");
resolvedOptions.SourceG5BundleRoot = localStringOption(options, "SourceG5BundleRoot", "");
resolvedOptions.SourceG5DiagnosticBundleRoot = localStringOption(options, "SourceG5DiagnosticBundleRoot", "");
resolvedOptions.SourceG4Metrics = localStructOption(options, "SourceG4Metrics");
resolvedOptions.SourceG5Metrics = localStructOption(options, "SourceG5Metrics");
resolvedOptions.SourceG5DiagnosticMetrics = localStructOption(options, "SourceG5DiagnosticMetrics");

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

function sourceEvidence = localResolveSourceEvidence(datasetId, repoRoot, resolvedOptions)

sourceEvidence = struct();
sourceEvidence.G4 = localResolveMetricsSource(datasetId, repoRoot, "G4_Passive_Baseline_Map", resolvedOptions.SourceG4BundleRoot, resolvedOptions.SourceG4Metrics);
sourceEvidence.G5 = localResolveMetricsSource(datasetId, repoRoot, "G5_Mitigation", resolvedOptions.SourceG5BundleRoot, resolvedOptions.SourceG5Metrics);
sourceEvidence.G5Diagnostic = localResolveMetricsSource(datasetId, repoRoot, "G5_Mitigation_Diagnostic", resolvedOptions.SourceG5DiagnosticBundleRoot, resolvedOptions.SourceG5DiagnosticMetrics);

end

function metricsSource = localResolveMetricsSource(datasetId, repoRoot, gateId, explicitBundleRoot, explicitMetrics)

metricsSource = struct();
metricsSource.GateId = string(gateId);
metricsSource.BundleRoot = "";
metricsSource.MetricsPath = "";
metricsSource.Metrics = struct();
metricsSource.Available = false;
metricsSource.SourceMode = "missing";
metricsSource.LoadMessage = "";

if ~isempty(fieldnames(explicitMetrics))
    metricsSource.Metrics = explicitMetrics;
    metricsSource.Available = true;
    metricsSource.SourceMode = "injected_metrics";
    metricsSource.BundleRoot = localStringField(explicitMetrics, ["bundle_root", "BundleRoot"], "");
    metricsSource.MetricsPath = "";
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
metricsSource.BundleRoot = string(bundleRoot);
metricsSource.MetricsPath = string(metricsPath);

try
    metricsText = fileread(metricsPath);
    metricsSource.Metrics = jsondecode(metricsText);
catch readException
    error("helperAnalyzeG6CpiIntegrationFreeze:ReadMetricsFailed", "Failed to read %s: %s", metricsPath, readException.message);
end

metricsSource.Available = true;
metricsSource.SourceMode = "metrics_json";
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

function sourceGateSummaryTable = localBuildSourceGateSummaryTable(sourceEvidence)

g4Metrics = sourceEvidence.G4.Metrics;
g5Metrics = sourceEvidence.G5.Metrics;
g5DiagnosticMetrics = sourceEvidence.G5Diagnostic.Metrics;
gateId = [
    "G4_Passive_Baseline_Map"
    "G5_Mitigation"
    "G5_Mitigation_Diagnostic"
    ];
bundleRoot = [
    string(sourceEvidence.G4.BundleRoot)
    string(sourceEvidence.G5.BundleRoot)
    string(sourceEvidence.G5Diagnostic.BundleRoot)
    ];
metricsPath = [
    string(sourceEvidence.G4.MetricsPath)
    string(sourceEvidence.G5.MetricsPath)
    string(sourceEvidence.G5Diagnostic.MetricsPath)
    ];
statusLabel = [
    localStringField(g4Metrics, ["overall_label", "OverallLabel"], "missing")
    localStringField(g5Metrics, ["review_status", "ReviewStatus"], "missing")
    localStringField(g5DiagnosticMetrics, ["primary_conclusion_label", "PrimaryConclusionLabel"], "missing")
    ];
decisionLabel = [
    localStringField(g4Metrics, ["limitation_source_label", "LimitationSourceLabel"], "missing")
    localStringField(g5Metrics, ["decision_label", "DecisionLabel"], "missing")
    localStringField(g5DiagnosticMetrics, ["best_causal_label", "BestCausalLabel"], "missing")
    ];
formalGateDecisionEmitted = [
    false
    localLogicalField(g5Metrics, ["formal_gate_decision_emitted", "FormalGateDecisionEmitted"], false)
    localLogicalField(g5DiagnosticMetrics, ["formal_gate_decision_changed", "FormalGateDecisionChanged"], false)
    ];
blockingLabel = [
    localG4BlockingLabel(g4Metrics)
    localG5BlockingLabel(g5Metrics)
    localG5DiagnosticBlockingLabel(g5DiagnosticMetrics)
    ];
notes = [
    "G4 must be ready with no raw/reduced-rate disagreement before G6 can freeze."
    "G5 must emit a selectable formal mitigation posture before G6 can freeze."
    "G5 diagnostic evidence is context only and cannot promote a freeze."
    ];
sourceGateSummaryTable = table(gateId, bundleRoot, metricsPath, statusLabel, decisionLabel, formalGateDecisionEmitted, blockingLabel, notes, VariableNames = {'GateId', 'BundleRoot', 'MetricsPath', 'StatusLabel', 'DecisionLabel', 'FormalGateDecisionEmitted', 'BlockingLabel', 'Notes'});

end

function upstreamBlockTable = localBuildUpstreamBlockTable(sourceEvidence)

g4Metrics = sourceEvidence.G4.Metrics;
g5Metrics = sourceEvidence.G5.Metrics;
g5DiagnosticMetrics = sourceEvidence.G5Diagnostic.Metrics;
blockSource = strings(0, 1);
blockCode = strings(0, 1);
severity = strings(0, 1);
evidenceValue = strings(0, 1);
requiredAction = strings(0, 1);

if ~sourceEvidence.G4.Available
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G4", "missing_g4_metrics", "blocking", sourceEvidence.G4.LoadMessage, "Run or restore a complete G4 evidence bundle.");
end

g4OverallLabel = localStringField(g4Metrics, ["overall_label", "OverallLabel"], "missing");

if g4OverallLabel ~= "ready"
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G4", "g4_not_ready", "blocking", g4OverallLabel, "Do not freeze G6 until G4 is ready.");
end

g4Limitation = localStringField(g4Metrics, ["limitation_source_label", "LimitationSourceLabel"], "missing");

if contains(g4Limitation, "scene_limited", IgnoreCase = true)
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G4", "scene_limited_direct_path_dominated", "blocking", g4Limitation, "Treat current maps as diagnostic negative-control evidence.");
end

g4AuditAgreement = localStringField(g4Metrics, ["full_rate_audit_agreement_label", "FullRateAuditAgreementLabel"], "missing");

if g4AuditAgreement ~= "agreement"
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G4", "raw_reduced_rate_disagreement", "blocking", g4AuditAgreement, "Reconcile raw/reduced-rate map disagreement before freezing detector products.");
end

sceneLimitedFraction = localNumericField(g4Metrics, ["scene_limited_map_fraction", "SceneLimitedMapFraction"], NaN);

if isfinite(sceneLimitedFraction) && sceneLimitedFraction >= 1.0
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G4", "all_maps_scene_limited", "blocking", sprintf("%.3f", sceneLimitedFraction), "Acquire or select evidence with observable off-origin scene content.");
end

if ~sourceEvidence.G5.Available
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G5", "missing_g5_metrics", "blocking", sourceEvidence.G5.LoadMessage, "Run or restore a complete G5 evidence bundle.");
end

g5GateDecision = localStringField(g5Metrics, ["gate_decision", "GateDecision"], "missing");
g5DecisionLabel = localStringField(g5Metrics, ["decision_label", "DecisionLabel"], "missing");
g5FormalEmitted = localLogicalField(g5Metrics, ["formal_gate_decision_emitted", "FormalGateDecisionEmitted"], false);

if g5GateDecision ~= "pass"
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G5", "g5_not_passed", "blocking", g5GateDecision, "Do not select a detector product until mitigation posture is formally selectable.");
end

if g5DecisionLabel == "blocked_by_g4"
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G5", "g5_blocked_by_g4", "blocking", g5DecisionLabel, "Resolve G4 before treating G5 mitigation as product evidence.");
end

if ~g5FormalEmitted
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G5", "g5_diagnostic_only_formal_decision_missing", "blocking", string(g5FormalEmitted), "Keep mitigation evidence diagnostic-only.");
end

defaultGateRevealCount = localNumericField(g5DiagnosticMetrics, ["default_gate_reveal_count", "DefaultGateRevealCount"], NaN);
bestCausalLabel = localStringField(g5DiagnosticMetrics, ["best_causal_label", "BestCausalLabel"], "missing");

if isfinite(defaultGateRevealCount) && defaultGateRevealCount == 0
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G5_Diagnostic", "no_default_scene_reveal", "diagnostic", sprintf("%.0f", defaultGateRevealCount), "Use the current G5 diagnostic as negative-control context only.");
end

if bestCausalLabel == "visual_only_improvement"
    [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, "G5_Diagnostic", "visual_only_improvement", "diagnostic", bestCausalLabel, "Do not promote visual improvement to detector-product validation.");
end

upstreamBlockTable = table(blockSource, blockCode, severity, evidenceValue, requiredAction, VariableNames = {'BlockSource', 'BlockCode', 'Severity', 'EvidenceValue', 'RequiredAction'});

end

function [blockSource, blockCode, severity, evidenceValue, requiredAction] = localAppendBlock(blockSource, blockCode, severity, evidenceValue, requiredAction, newSource, newCode, newSeverity, newValue, newAction)

blockSource(end + 1, 1) = string(newSource);
blockCode(end + 1, 1) = string(newCode);
severity(end + 1, 1) = string(newSeverity);
evidenceValue(end + 1, 1) = string(newValue);
requiredAction(end + 1, 1) = string(newAction);

end

function frozenProductDefinition = localBuildFrozenProductDefinition(datasetId, sourceEvidence, freezeStatus)

g4Metrics = sourceEvidence.G4.Metrics;
g5Metrics = sourceEvidence.G5.Metrics;
datasetIdColumn = string(datasetId);
productDefinitionStatus = "not_frozen";
freezeStatusColumn = string(freezeStatus);
recommendedCpiLabel = localStringField(g4Metrics, ["recommended_baseline_cpi_label", "RecommendedBaselineCpiLabel"], "not_selected");
mapRateMode = localStringField(g4Metrics, ["map_rate_mode", "MapRateMode"], "unresolved");
mapDecimationFactor = localNumericField(g4Metrics, ["map_decimation_factor", "MapDecimationFactor"], NaN);
mapSampleRateHz = localNumericField(g4Metrics, ["map_sample_rate_hz", "MapSampleRateHz"], NaN);
mitigationPosture = localStringField(g5Metrics, ["decision_label", "DecisionLabel"], "not_selectable");
timestampConvention = "blocked_until_g6_freeze";
registrationRule = "blocked_until_g4_g5_pass";
publicUseAllowed = false;
frozenProductDefinition = table(datasetIdColumn, productDefinitionStatus, freezeStatusColumn, recommendedCpiLabel, mapRateMode, mapDecimationFactor, mapSampleRateHz, mitigationPosture, timestampConvention, registrationRule, publicUseAllowed, VariableNames = {'DatasetId', 'ProductDefinitionStatus', 'FreezeStatus', 'RecommendedCpiLabelCarriedForContext', 'MapRateModeCarriedForContext', 'MapDecimationFactorCarriedForContext', 'MapSampleRateHzCarriedForContext', 'MitigationPostureCarriedForContext', 'TimestampConvention', 'RegistrationRule', 'PublicUseAllowed'});

end

function requirementsCoverageTable = localBuildRequirementsCoverageTable(freezeStatus, refusalReason)

requirementId = [
    "MAP-004"
    "DET-001"
    ];
gateId = [
    "G6_CPI_Integration"
    "G6_CPI_Integration"
    ];
status = [
    "blocked"
    "blocked"
    ];
evidenceReference = [
    "freeze_decision_table.csv"
    "frozen_product_definition.csv"
    ];
notes = [
    "CPI/integration registration freeze deferred: " + string(freezeStatus)
    "Detector input product definition not frozen: " + string(refusalReason)
    ];
requirementsCoverageTable = table(requirementId, gateId, status, evidenceReference, notes, VariableNames = {'RequirementId', 'GateId', 'Status', 'EvidenceReference', 'Notes'});

end

function publicContractChangeTable = localBuildPublicContractChangeTable()

contractItem = [
    "G6 evidence bundle"
    "G6 frozen product definition"
    "G8 downstream prerequisite"
    ];
changeType = [
    "new_blocked_state_contract"
    "explicit_not_frozen_record"
    "formal_detection_refusal_dependency"
    ];
downstreamEffect = [
    "Downstream gates can read FreezeStatus and DetectorProductFreezeEnabled."
    "No detector product may be consumed from this dataset while ProductDefinitionStatus is not_frozen."
    "Formal G8 must refuse execution until G6 emits a frozen product and G7 emits truth windows."
    ];
publicContractChangeTable = table(contractItem, changeType, downstreamEffect, VariableNames = {'ContractItem', 'ChangeType', 'DownstreamEffect'});

end

function datasetInterpretation = localBuildDatasetInterpretation(sourceEvidence)

g4Metrics = sourceEvidence.G4.Metrics;
g5Metrics = sourceEvidence.G5.Metrics;
g5DiagnosticMetrics = sourceEvidence.G5Diagnostic.Metrics;
datasetInterpretation = struct();
datasetInterpretation.current_dataset_interpretation = "diagnostic_negative_control_only";
datasetInterpretation.g4_status = localStringField(g4Metrics, ["overall_label", "OverallLabel"], "missing");
datasetInterpretation.g4_limitation_source = localStringField(g4Metrics, ["limitation_source_label", "LimitationSourceLabel"], "missing");
datasetInterpretation.g4_full_rate_audit = localStringField(g4Metrics, ["full_rate_audit_agreement_label", "FullRateAuditAgreementLabel"], "missing");
datasetInterpretation.g5_decision_label = localStringField(g5Metrics, ["decision_label", "DecisionLabel"], "missing");
datasetInterpretation.g5_gate_decision = localStringField(g5Metrics, ["gate_decision", "GateDecision"], "missing");
datasetInterpretation.g5_default_gate_reveal_count = localNumericField(g5DiagnosticMetrics, ["default_gate_reveal_count", "DefaultGateRevealCount"], NaN);
datasetInterpretation.g5_permissive_probe_reveal_count = localNumericField(g5DiagnosticMetrics, ["permissive_probe_reveal_count", "PermissiveProbeRevealCount"], NaN);
datasetInterpretation.g5_best_causal_label = localStringField(g5DiagnosticMetrics, ["best_causal_label", "BestCausalLabel"], "missing");

end

function blockingLabel = localG4BlockingLabel(metrics)

overallLabel = localStringField(metrics, ["overall_label", "OverallLabel"], "missing");
auditLabel = localStringField(metrics, ["full_rate_audit_agreement_label", "FullRateAuditAgreementLabel"], "missing");
limitationLabel = localStringField(metrics, ["limitation_source_label", "LimitationSourceLabel"], "missing");

if overallLabel ~= "ready"
    blockingLabel = "blocks_g6_freeze";
elseif auditLabel ~= "agreement"
    blockingLabel = "blocks_g6_freeze";
elseif contains(limitationLabel, "scene_limited", IgnoreCase = true)
    blockingLabel = "blocks_g6_freeze";
else
    blockingLabel = "not_blocking";
end

end

function blockingLabel = localG5BlockingLabel(metrics)

gateDecision = localStringField(metrics, ["gate_decision", "GateDecision"], "missing");
formalGateDecisionEmitted = localLogicalField(metrics, ["formal_gate_decision_emitted", "FormalGateDecisionEmitted"], false);

if gateDecision ~= "pass"
    blockingLabel = "blocks_g6_freeze";
elseif ~formalGateDecisionEmitted
    blockingLabel = "blocks_g6_freeze";
else
    blockingLabel = "not_blocking";
end

end

function blockingLabel = localG5DiagnosticBlockingLabel(metrics)

defaultGateRevealCount = localNumericField(metrics, ["default_gate_reveal_count", "DefaultGateRevealCount"], NaN);
bestCausalLabel = localStringField(metrics, ["best_causal_label", "BestCausalLabel"], "missing");

if isfinite(defaultGateRevealCount) && defaultGateRevealCount == 0
    blockingLabel = "diagnostic_only";
elseif bestCausalLabel == "visual_only_improvement"
    blockingLabel = "diagnostic_only";
else
    blockingLabel = "context_only";
end

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

function value = localNumericField(inputStruct, fieldNames, defaultValue)

value = double(defaultValue);

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

if isnumeric(fieldValue) && isscalar(fieldValue)
    value = double(fieldValue);
elseif islogical(fieldValue) && isscalar(fieldValue)
    value = double(fieldValue);
elseif isstring(fieldValue) || ischar(fieldValue)
    parsedValue = str2double(string(fieldValue));

    if isfinite(parsedValue)
        value = parsedValue;
    end
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
