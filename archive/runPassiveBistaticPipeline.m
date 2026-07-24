%[text] # Passive Bistatic Pipeline
%[text] This plain-text MATLAB live script is the current development/test pipeline for exercising the checkpoint plan gate by gate.
%[text] Each implemented gate or stage follows the same review pattern:
%[text] 1. question: what technical claim are we trying to establish?
%[text] 2. approach: which native MATLAB functions or repo helpers quantify that claim?
%[text] 3. summary: what did the executed code actually find on this dataset?
%[text] - Edit |datasetId| in the setup section for a different session
%[text] - |repoRoot| auto-resolves to the real project root even when the Live Editor runs from a temp copy
%[text] - Run sections sequentially in the Live Editor
%[text] - Inspect |pipelineResults|, |g2Stage1Results|, and |g2Stage2Results| after the summary sections
%[text] - A later customer-facing live script should sit above stable helper APIs rather than gate-validation runners
%%
%[text] ## Setup
%[text] Edit the dataset or repo root here before running the gate sections.
%[text] Implemented manual-review content currently exists for |G1 Ingest|, |G2 Stage 1 Acquisition Evidence|, and |G2 Stage 2 Receiver Integrity|.
datasetId = "20260622T102123";
repoRoot = helperResolveRepoRoot();
gateIds = localGetGateIds();
pipelineResults = localInitializePipelineResults(datasetId, repoRoot, gateIds);
setupSummary = table(datasetId, repoRoot, numel(gateIds), gateIds(1), ...
    gateIds(end), VariableNames = {'DatasetId', 'RepoRoot', 'GateCount', ...
    'FirstGate', 'LastGate'});
setupSummary
%%
%[text] ## G1 Ingest
%[text] Question: did the manifest-driven ingest produce a trusted decode, channel contract, timing model, and CPI segmentation contract for this session?
%[text] Approach: run |runG1Ingest|, which uses |loadIQData| plus manifest reconciliation, radar-header scans, seam checks, and CPI-contract freezing.
%[text] Output below: a compact G1 summary table followed by the gate-status row recorded in |pipelineResults|.
if ~exist("pipelineResults", "var")
    datasetId = "20260622T102123";
    repoRoot = helperResolveRepoRoot();
    gateIds = localGetGateIds();
    pipelineResults = localInitializePipelineResults(datasetId, repoRoot, ...
        gateIds);
end

pipelineResults = localRunG1IngestGate(pipelineResults);
g1ReviewSummary = localBuildG1ReviewSummaryTable(pipelineResults.G1Result);
gateStatusTable = localBuildGateStatusTable(pipelineResults);
g1ReviewSummary
gateStatusTable(1, :)
%%
%[text] ## G2 RF Health
%[text] Question: is the dataset RF-clean and role-consistent enough to justify later sync and passive-map work?
%[text] Approach: the full G2 gate is still under staged implementation. The gate status below remains a controlled placeholder, while the next two sections run the implemented manual-review slices for |Stage 1 Acquisition Evidence| and |Stage 2 Receiver Integrity|.
%[text] Output below: the current whole-gate placeholder status. Continue into the next sections for the implemented G2 summaries.
if ~exist("pipelineResults", "var")
    datasetId = "20260622T102123";
    repoRoot = helperResolveRepoRoot();
    gateIds = localGetGateIds();
    pipelineResults = localInitializePipelineResults(datasetId, repoRoot, ...
        gateIds);
end

pipelineResults = localRunG2RFHealthGate(pipelineResults);
gateStatusTable = localBuildGateStatusTable(pipelineResults);
gateStatusTable(2, :)
%%
%[text] ## G2 Stage 1 Acquisition Evidence
%[text] Question: do the manifest, capture log, embedded headers, and manual collection metadata actually establish the receiver configuration and the intended channel roles?
%[text] Approach: run |runG2Stage1AcquisitionEvidence|, which audits metadata presence and uses |pwelch|, |mscohere|, and |xcorr| as role-evidence diagnostics.
%[text] Output below: the current Stage 1 summary and, when applicable, the list of still-missing required acquisition-evidence items.
if ~exist("datasetId", "var")
    datasetId = "20260622T102123";
    repoRoot = helperResolveRepoRoot();
end

if ~exist("pipelineResults", "var")
    gateIds = localGetGateIds();
    pipelineResults = localInitializePipelineResults(datasetId, repoRoot, ...
        gateIds);
end

if isfield(pipelineResults, "G1Result") && ...
        pipelineResults.G1Result.Decision == "pass"
    g2Stage1Results = runG2Stage1AcquisitionEvidence(datasetId, repoRoot, ...
        struct("ShowFigures", true));
    g2Stage1Summary = localBuildG2Stage1ReviewSummaryTable( ...
        g2Stage1Results);
else
    g2Stage1Results = struct();
    g2Stage1Summary = localBuildBlockedSummaryTable( ...
        "G2 Stage 1 Acquisition Evidence", ...
        "Run and pass G1 in this live-script session before reviewing G2.");
end

g2Stage1Summary

if isfield(g2Stage1Results, "MissingRequiredItems") && ...
        ~isempty(g2Stage1Results.MissingRequiredItems)
    g2Stage1MissingRequired = localBuildStringListTable( ...
        "MissingRequiredItem", g2Stage1Results.MissingRequiredItems);
    g2Stage1MissingRequired
end
%%
%[text] ## G2 Stage 2 Receiver Integrity
%[text] Question: are the accepted reference and surveillance channels healthy in total in-band power, headroom, DC behavior, and IQ balance?
%[text] Approach: run |runG2Stage2ReceiverIntegrity|, which computes whole-channel power via |mean(abs(x).^2)|, uses |pwelch| for PSD review, |bandpower| for low-frequency/DC concentration, and IQ image-risk proxies derived from amplitude, phase, and impropriety metrics.
%[text] Important: the current power delta is whole-band baseband power across the captured channel, not isolated direct-path-only energy.
%[text] Output below: the current Stage 2 summary and per-role channel summary table.
if ~exist("datasetId", "var")
    datasetId = "20260622T102123";
    repoRoot = helperResolveRepoRoot();
end

if ~exist("pipelineResults", "var")
    gateIds = localGetGateIds();
    pipelineResults = localInitializePipelineResults(datasetId, repoRoot, ...
        gateIds);
end

if isfield(pipelineResults, "G1Result") && ...
        pipelineResults.G1Result.Decision == "pass"
    g2Stage2Results = runG2Stage2ReceiverIntegrity(datasetId, repoRoot, ...
        struct("ShowFigures", true));
    g2Stage2Summary = localBuildG2Stage2ReviewSummaryTable( ...
        g2Stage2Results);
else
    g2Stage2Results = struct();
    g2Stage2Summary = localBuildBlockedSummaryTable( ...
        "G2 Stage 2 Receiver Integrity", ...
        "Run and pass G1 in this live-script session before reviewing G2.");
end

g2Stage2Summary

if isfield(g2Stage2Results, "ChannelSummaryTable")
    g2Stage2Results.ChannelSummaryTable
end
%%
%[text] ## G3 Sync
%[text] Question: can lag and residual frequency alignment be established repeatably across repetitions and candidate CPI windows?
%[text] Planned approach: synchronization will use cross-channel lag and coherence observables such as |finddelay|, |xcorr|, and |mscohere| once G3 is opened.
%[text] Output below: placeholder gate status only. No G3 logic is implemented in this session.
if ~exist("pipelineResults", "var")
    datasetId = "20260622T102123";
    repoRoot = helperResolveRepoRoot();
    gateIds = localGetGateIds();
    pipelineResults = localInitializePipelineResults(datasetId, repoRoot, ...
        gateIds);
end

pipelineResults = localRunG3SyncGate(pipelineResults);
gateStatusTable = localBuildGateStatusTable(pipelineResults);
gateStatusTable(3, :)
%%
%[text] ## G4 Passive Baseline Map
%[text] Question: does the baseline passive map show plausible and repeatable delay-Doppler structure after synchronization is established?
%[text] Planned approach: G4 will use |ambgfun| as the baseline oracle before any later equivalence or optimization path is considered.
%[text] Output below: placeholder gate status only. No G4 logic is implemented in this session.
if ~exist("pipelineResults", "var")
    datasetId = "20260622T102123";
    repoRoot = helperResolveRepoRoot();
    gateIds = localGetGateIds();
    pipelineResults = localInitializePipelineResults(datasetId, repoRoot, ...
        gateIds);
end

pipelineResults = localRunG4PassiveBaselineMapGate(pipelineResults);
gateStatusTable = localBuildGateStatusTable(pipelineResults);
gateStatusTable(4, :)
%%
%[text] ## G5 Mitigation
%[text] Question: do conservative mitigation settings improve the passive map without erasing the nonzero-Doppler content we care about?
%[text] Planned approach: G5 will compare no mitigation against candidate cancellation baselines such as |dsp.LMSFilter| once a credible G4 map exists.
%[text] Output below: placeholder gate status only. No G5 logic is implemented in this session.
if ~exist("pipelineResults", "var")
    datasetId = "20260622T102123";
    repoRoot = helperResolveRepoRoot();
    gateIds = localGetGateIds();
    pipelineResults = localInitializePipelineResults(datasetId, repoRoot, ...
        gateIds);
end

pipelineResults = localRunG5MitigationGate(pipelineResults);
gateStatusTable = localBuildGateStatusTable(pipelineResults);
gateStatusTable(5, :)
%%
%[text] ## G6 CPI Integration
%[text] Question: which CPI length, overlap, and integration rules should be frozen so detector tuning is applied to a stable map product?
%[text] Planned approach: G6 will compare CPI and integration choices against map stability and downstream usability metrics.
%[text] Output below: placeholder gate status only. No G6 logic is implemented in this session.
if ~exist("pipelineResults", "var")
    datasetId = "20260622T102123";
    repoRoot = helperResolveRepoRoot();
    gateIds = localGetGateIds();
    pipelineResults = localInitializePipelineResults(datasetId, repoRoot, ...
        gateIds);
end

pipelineResults = localRunG6CPIIntegrationGate(pipelineResults);
gateStatusTable = localBuildGateStatusTable(pipelineResults);
gateStatusTable(6, :)
%%
%[text] ## G7 Truth Alignment
%[text] Question: can radar-relative time be aligned to the external truth timeline with an explicit uncertainty budget?
%[text] Planned approach: G7 will use |datetime|, |timetable|, and |synchronize| once truth-alignment work is opened.
%[text] Output below: placeholder gate status only. No G7 logic is implemented in this session.
if ~exist("pipelineResults", "var")
    datasetId = "20260622T102123";
    repoRoot = helperResolveRepoRoot();
    gateIds = localGetGateIds();
    pipelineResults = localInitializePipelineResults(datasetId, repoRoot, ...
        gateIds);
end

pipelineResults = localRunG7TruthAlignmentGate(pipelineResults);
gateStatusTable = localBuildGateStatusTable(pipelineResults);
gateStatusTable(7, :)
%%
%[text] ## G8 Detection
%[text] Question: do the frozen map products support stable detections with acceptable false-alarm behavior?
%[text] Planned approach: G8 will evaluate detector outputs on the fixed G6 product rather than tuning against a moving upstream target.
%[text] Output below: placeholder gate status only. No G8 logic is implemented in this session.
if ~exist("pipelineResults", "var")
    datasetId = "20260622T102123";
    repoRoot = helperResolveRepoRoot();
    gateIds = localGetGateIds();
    pipelineResults = localInitializePipelineResults(datasetId, repoRoot, ...
        gateIds);
end

pipelineResults = localRunG8DetectionGate(pipelineResults);
gateStatusTable = localBuildGateStatusTable(pipelineResults);
gateStatusTable(8, :)
%%
%[text] ## G9 Tracker Readiness
%[text] Question: are the detections temporally and structurally consistent enough to hand to a tracker?
%[text] Planned approach: G9 will screen measurement continuity, density, and schema stability before tracking is allowed to open.
%[text] Output below: placeholder gate status only. No G9 logic is implemented in this session.
if ~exist("pipelineResults", "var")
    datasetId = "20260622T102123";
    repoRoot = helperResolveRepoRoot();
    gateIds = localGetGateIds();
    pipelineResults = localInitializePipelineResults(datasetId, repoRoot, ...
        gateIds);
end

pipelineResults = localRunG9TrackerReadinessGate(pipelineResults);
gateStatusTable = localBuildGateStatusTable(pipelineResults);
gateStatusTable(9, :)
%%
%[text] ## G10 Tracking Truth Validation
%[text] Question: do batch tracks hold up against truth once the upstream contracts and detector inputs are frozen?
%[text] Planned approach: G10 will evaluate track-level and truth-correlated outcomes only after the earlier gates are stable.
%[text] Output below: placeholder gate status only. No G10 logic is implemented in this session.
if ~exist("pipelineResults", "var")
    datasetId = "20260622T102123";
    repoRoot = helperResolveRepoRoot();
    gateIds = localGetGateIds();
    pipelineResults = localInitializePipelineResults(datasetId, repoRoot, ...
        gateIds);
end

pipelineResults = localRunG10TrackingTruthValidationGate(pipelineResults);
gateStatusTable = localBuildGateStatusTable(pipelineResults);
gateStatusTable(10, :)
%%
%[text] ## Pipeline Summary
%[text] The summary table captures the current pipeline state after the executed sections.
%[text] Use the stage result structs above for the detailed manual-review outputs from the implemented G2 slices.
pipelineSummary = localBuildPipelineSummaryTable(pipelineResults);
pipelineSummary

function gateIds = localGetGateIds()

gateIds = [ ...
    "G1_Ingest"; ...
    "G2_RF_Health"; ...
    "G3_Sync"; ...
    "G4_Passive_Baseline_Map"; ...
    "G5_Mitigation"; ...
    "G6_CPI_Integration"; ...
    "G7_Truth_Alignment"; ...
    "G8_Detection"; ...
    "G9_Tracker_Readiness"; ...
    "G10_Tracking_Truth_Validation" ...
    ];

end

function pipelineResults = localInitializePipelineResults(datasetId, ...
    repoRoot, gateIds)

gateCount = numel(gateIds);
template = struct("GateId", "", "Implemented", false, ...
    "ExecutionStatus", "not_implemented", "Decision", "", ...
    "BundleRoot", "", "Message", ...
    "Placeholder only. Replace this local gate function when the gate " + ...
    "implementation is ready.");
gateResults = repmat(template, gateCount, 1);

for idx = 1:gateCount
    gateResults(idx).GateId = gateIds(idx);
end

pipelineResults = struct();
pipelineResults.DatasetId = string(datasetId);
pipelineResults.RepoRoot = string(repoRoot);
pipelineResults.RunTimestampZ = string(datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyyMMdd'T'HHmmss'Z'"));
pipelineResults.ExecutedGates = strings(0, 1);
pipelineResults.GateResults = gateResults;
pipelineResults.LastExecutedGate = "";
pipelineResults.LastPassingGate = "";
pipelineResults.NextGate = gateIds(1);
pipelineResults.PipelineStatus = "ready";
pipelineResults.Message = "Pipeline initialized.";
pipelineResults.StopPipeline = false;

end

function pipelineResults = localRunG1IngestGate(pipelineResults)

gateId = "G1_Ingest";
g1Results = runG1Ingest(pipelineResults.DatasetId, pipelineResults.RepoRoot);
gateIdx = localFindGateIndex(pipelineResults, gateId);
pipelineResults.ExecutedGates = localAppendExecutedGate( ...
    pipelineResults.ExecutedGates, gateId);
pipelineResults.LastExecutedGate = gateId;
pipelineResults.GateResults(gateIdx).Implemented = true;
pipelineResults.GateResults(gateIdx).ExecutionStatus = "executed";
pipelineResults.GateResults(gateIdx).Decision = g1Results.Decision;
pipelineResults.GateResults(gateIdx).BundleRoot = g1Results.BundleRoot;
pipelineResults.GateResults(gateIdx).Message = "Executed via runG1Ingest.";
pipelineResults.G1Result = g1Results;

if g1Results.Decision == "pass"
    pipelineResults.LastPassingGate = gateId;
    pipelineResults.NextGate = "G2_RF_Health";
    pipelineResults.PipelineStatus = "g1_passed";
    pipelineResults.Message = ...
        "G1 passed. Continue with the next gate when it is implemented.";
    pipelineResults.StopPipeline = false;
else
    pipelineResults.NextGate = gateId;
    pipelineResults.PipelineStatus = "stopped_on_g1_decision";
    pipelineResults.Message = ...
        "Pipeline stopped on the G1 decision. No later gates should run.";
    pipelineResults.StopPipeline = true;
end

end

function pipelineResults = localRunG2RFHealthGate(pipelineResults)

pipelineResults = localRunPlaceholderGate(pipelineResults, "G2_RF_Health");
gateIdx = localFindGateIndex(pipelineResults, "G2_RF_Health");
pipelineResults.Message = ...
    "Full G2 gate logic is not finalized. Use the Stage 1 and Stage 2 " + ...
    "sections below for the implemented manual-review slices.";
pipelineResults.GateResults(gateIdx).Message = ...
    "Full G2 gate remains non-final. Run the Stage 1 and Stage 2 " + ...
    "sections below for the current manual-review outputs.";

end

function pipelineResults = localRunG3SyncGate(pipelineResults)

pipelineResults = localRunPlaceholderGate(pipelineResults, "G3_Sync");

end

function pipelineResults = localRunG4PassiveBaselineMapGate(pipelineResults)

pipelineResults = localRunPlaceholderGate(pipelineResults, ...
    "G4_Passive_Baseline_Map");

end

function pipelineResults = localRunG5MitigationGate(pipelineResults)

pipelineResults = localRunPlaceholderGate(pipelineResults, "G5_Mitigation");

end

function pipelineResults = localRunG6CPIIntegrationGate(pipelineResults)

pipelineResults = localRunPlaceholderGate(pipelineResults, ...
    "G6_CPI_Integration");

end

function pipelineResults = localRunG7TruthAlignmentGate(pipelineResults)

pipelineResults = localRunPlaceholderGate(pipelineResults, ...
    "G7_Truth_Alignment");

end

function pipelineResults = localRunG8DetectionGate(pipelineResults)

pipelineResults = localRunPlaceholderGate(pipelineResults, "G8_Detection");

end

function pipelineResults = localRunG9TrackerReadinessGate(pipelineResults)

pipelineResults = localRunPlaceholderGate(pipelineResults, ...
    "G9_Tracker_Readiness");

end

function pipelineResults = localRunG10TrackingTruthValidationGate( ...
    pipelineResults)

pipelineResults = localRunPlaceholderGate(pipelineResults, ...
    "G10_Tracking_Truth_Validation");

end

function pipelineResults = localRunPlaceholderGate(pipelineResults, gateId)

if pipelineResults.StopPipeline
    return
end

gateIdx = localFindGateIndex(pipelineResults, gateId);

if gateIdx > 1
    previousGate = pipelineResults.GateResults(gateIdx - 1);

    if previousGate.ExecutionStatus ~= "executed" || ...
            previousGate.Decision ~= "pass"
        pipelineResults.PipelineStatus = "blocked_by_upstream_gate";
        pipelineResults.NextGate = previousGate.GateId;
        pipelineResults.StopPipeline = true;
        pipelineResults.Message = ...
            "Later gate execution is blocked until the upstream gate has " + ...
            "executed and passed.";
        pipelineResults.GateResults(gateIdx).Message = ...
            "Blocked by an upstream gate that has not passed yet.";
        return
    end
end

pipelineResults.PipelineStatus = "stopped_after_last_implemented_gate";
pipelineResults.NextGate = gateId;
pipelineResults.StopPipeline = true;
pipelineResults.Message = ...
    "Pipeline stopped after the last implemented gate. This gate is " + ...
    "still a placeholder.";
pipelineResults.GateResults(gateIdx).Message = ...
    "Placeholder only. Add the gate implementation here when it is ready.";

end

function reviewSummary = localBuildG1ReviewSummaryTable(g1Results)

passFlags = g1Results.PassFlags;
reviewSummary = table( ...
    string(g1Results.Decision), ...
    string(g1Results.NextBranch), ...
    logical(passFlags.InventoryReconciled), ...
    logical(passFlags.DecodeContractConfirmed), ...
    logical(passFlags.ChannelContractConfirmed), ...
    logical(passFlags.TimingModelFrozen), ...
    logical(passFlags.SeamChecksPassed), ...
    logical(passFlags.CpiSegmentationFrozen), ...
    string(g1Results.BundleRoot), ...
    'VariableNames', {'Decision', 'NextBranch', 'InventoryReconciled', ...
    'DecodeContractConfirmed', 'ChannelContractConfirmed', ...
    'TimingModelFrozen', 'SeamChecksPassed', ...
    'CpiSegmentationFrozen', 'BundleRoot'});

end

function reviewSummary = localBuildG2Stage1ReviewSummaryTable(stageResults)

metrics = stageResults.Metrics;
reviewSummary = table( ...
    string(stageResults.CollectionValidityVerdict), ...
    string(stageResults.AircraftReadinessImpact), ...
    string(metrics.role_evidence.iq_only_mapping_inference), ...
    double(metrics.metadata_presence.missing_required_item_count), ...
    double(metrics.role_evidence.reference_candidate_pass_fraction), ...
    double(metrics.role_evidence.peak_correlation_magnitude_median), ...
    string(stageResults.BundleRoot), ...
    'VariableNames', {'CollectionValidityVerdict', ...
    'AircraftReadinessImpact', 'IqOnlyMappingInference', ...
    'MissingRequiredItemCount', 'ReferenceCandidatePassFraction', ...
    'PeakCorrelationMagnitudeMedian', 'BundleRoot'});

end

function reviewSummary = localBuildG2Stage2ReviewSummaryTable(stageResults)

metrics = stageResults.Metrics;
reviewSummary = table( ...
    string(stageResults.ReceiverIntegrityVerdict), ...
    string(stageResults.LegalGateRecommendation), ...
    string(stageResults.DatasetClassificationRecommendation), ...
    string(stageResults.RoleSource), ...
    string(stageResults.ReferenceLabel), ...
    string(stageResults.SurveillanceLabel), ...
    double(metrics.reference_minus_surveillance_power_db_min), ...
    double(metrics.reference_minus_surveillance_power_db_median), ...
    double(metrics.reference_minus_surveillance_power_db_max), ...
    string(stageResults.BundleRoot), ...
    'VariableNames', {'ReceiverIntegrityVerdict', ...
    'LegalGateRecommendation', 'DatasetClassificationRecommendation', ...
    'RoleSource', 'ReferenceLabel', 'SurveillanceLabel', ...
    'ReferenceMinusSurveillanceMin_dB', ...
    'ReferenceMinusSurveillanceMedian_dB', ...
    'ReferenceMinusSurveillanceMax_dB', 'BundleRoot'});

end

function summaryTable = localBuildBlockedSummaryTable(stageName, reason)

summaryTable = table(string(stageName), "blocked", string(reason), ...
    'VariableNames', {'Stage', 'Status', 'Reason'});

end

function stringTable = localBuildStringListTable(columnName, values)

stringTable = table(string(values(:)), ...
    'VariableNames', {char(string(columnName))});

end

function gateStatusTable = localBuildGateStatusTable(pipelineResults)

gateResults = pipelineResults.GateResults;
gateCount = numel(gateResults);
gateId = strings(gateCount, 1);
implemented = false(gateCount, 1);
executionStatus = strings(gateCount, 1);
decision = strings(gateCount, 1);
bundleRoot = strings(gateCount, 1);
message = strings(gateCount, 1);

for idx = 1:gateCount
    gateId(idx) = gateResults(idx).GateId;
    implemented(idx) = gateResults(idx).Implemented;
    executionStatus(idx) = gateResults(idx).ExecutionStatus;
    decision(idx) = gateResults(idx).Decision;
    bundleRoot(idx) = gateResults(idx).BundleRoot;
    message(idx) = gateResults(idx).Message;
end

gateStatusTable = table(gateId, implemented, executionStatus, decision, ...
    bundleRoot, message, VariableNames = {'GateId', 'Implemented', ...
    'ExecutionStatus', 'Decision', 'BundleRoot', 'Message'});

end

function pipelineSummary = localBuildPipelineSummaryTable(pipelineResults)

pipelineSummary = table(pipelineResults.DatasetId, ...
    pipelineResults.RunTimestampZ, pipelineResults.PipelineStatus, ...
    pipelineResults.LastExecutedGate, pipelineResults.LastPassingGate, ...
    pipelineResults.NextGate, numel(pipelineResults.ExecutedGates), ...
    VariableNames = {'DatasetId', 'RunTimestampZ', 'PipelineStatus', ...
    'LastExecutedGate', 'LastPassingGate', 'NextGate', ...
    'ExecutedGateCount'});

end

function gateIdx = localFindGateIndex(pipelineResults, gateId)

gateIdx = find([pipelineResults.GateResults.GateId] == gateId, 1, "first");

if isempty(gateIdx)
    error("runPassiveBistaticPipeline:UnknownGate", ...
        "Unknown gate ID: %s", gateId);
end

end

function executedGates = localAppendExecutedGate(executedGates, gateId)

if any(executedGates == gateId)
    return
end

executedGates = [executedGates; gateId];

end
