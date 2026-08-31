function reportData = helperBuildPipelineStoryReport(datasetId, repoRoot, options)
%HELPERBUILDPIPELINESTORYREPORT Load saved artifacts for story review.
%
%   REPORTDATA = HELPERBUILDPIPELINESTORYREPORT(DATASETID, REPOROOT,
%   OPTIONS) builds an artifact-only passive-bistatic pipeline story report.
%   It does not read raw baseband captures.

arguments
    datasetId (1,1) string = "20260622T102123"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

repoRoot = helperResolveRepoRoot(repoRoot);
datasetId = string(datasetId);
reportOptions = localResolveOptions(options, datasetId, repoRoot);
gateSpecs = localBuildGateSpecs();
gateRecords = repmat(localEmptyGateRecord(), numel(gateSpecs), 1);

for gateIndex = 1:numel(gateSpecs)
    gateSpecs(gateIndex).Bundle = helperResolveLatestCompleteGateBundle( ...
        datasetId, gateSpecs(gateIndex).ArtifactId, repoRoot, ...
        gateSpecs(gateIndex).RequiredFiles);
    gateRecords(gateIndex) = localLoadGateRecord(gateSpecs(gateIndex));
end

g45Options = struct();
g45Options.RunTimestampZ = reportOptions.G45RunTimestampZ;
g45Options.CaseIds = reportOptions.G45CaseIds;
g45ReportData = helperBuildG45SyntheticTargetRecoveryReport( ...
    reportOptions.G45SuiteId, repoRoot, g45Options);

reportData = struct();
reportData.DatasetId = datasetId;
reportData.RepoRoot = string(repoRoot);
reportData.SourceMode = "artifact_only_no_raw_bb_read";
reportData.StoryRunTimestampZ = reportOptions.StoryRunTimestampZ;
reportData.ExportRoot = reportOptions.ExportRoot;
reportData.G45SuiteId = reportOptions.G45SuiteId;
reportData.G45RunTimestampZ = g45ReportData.RunTimestampZ;
reportData.GateRecords = gateRecords;
reportData.G45 = g45ReportData;
reportData.PhaseQuestionTable = localBuildPhaseQuestionTable(gateSpecs);
reportData.BundleSummaryTable = localBuildBundleSummaryTable( ...
    gateRecords, g45ReportData);
reportData.ArtifactPathTable = localBuildArtifactPathTable( ...
    gateRecords, g45ReportData);
reportData.SelectedEvidenceTable = localBuildSelectedEvidenceTable();

for gateIndex = 1:numel(gateRecords)
    fieldName = gateRecords(gateIndex).FieldName;
    reportData.(fieldName) = gateRecords(gateIndex).Data;
end

reportData.StoryInterpretationTable = localBuildStoryInterpretationTable( ...
    reportData);

if reportOptions.ExportArtifacts
    localWriteStoryTables(reportData);
end

end

function reportOptions = localResolveOptions(options, datasetId, repoRoot)

reportOptions = struct();
reportOptions.G45SuiteId = "g4_5_real_background_20260807T162306840";
reportOptions.G45RunTimestampZ = "latest";
reportOptions.G45CaseIds = localDefaultG45CaseIds();
reportOptions.ExportArtifacts = false;
reportOptions.StoryRunTimestampZ = string(datetime( ...
    "now", "TimeZone", "UTC", "Format", "yyyyMMdd'T'HHmmss'Z'"));
reportOptions.ExportRoot = fullfile(repoRoot, "artifacts", ...
    "communication", "PipelineStory", datasetId, ...
    reportOptions.StoryRunTimestampZ);

if isfield(options, "G45SuiteId")
    reportOptions.G45SuiteId = string(options.G45SuiteId);
end

if isfield(options, "G45RunTimestampZ")
    reportOptions.G45RunTimestampZ = string(options.G45RunTimestampZ);
end

if isfield(options, "G45CaseIds")
    reportOptions.G45CaseIds = string(options.G45CaseIds(:));
end

if isfield(options, "ExportArtifacts")
    reportOptions.ExportArtifacts = logical(options.ExportArtifacts);
end

if isfield(options, "StoryRunTimestampZ")
    reportOptions.StoryRunTimestampZ = string(options.StoryRunTimestampZ);
end

if isfield(options, "ExportRoot")
    reportOptions.ExportRoot = string(options.ExportRoot);
end

end

function caseIds = localDefaultG45CaseIds()

caseIds = [
    "real_only_control"
    "easy_single_target"
    "medium_single_target"
    "hard_single_target"
    "marginal_single_target"
    "multi_target"
    ];

end

function gateSpecs = localBuildGateSpecs()

gateSpecs = repmat(localEmptyGateSpec(), 10, 1);

gateSpecs(1) = localMakeGateSpec( ...
    "G1 Ingest", ...
    "G1", ...
    "G1_Ingest", ...
    "G1 Ingest", ...
    "Did we decode the dual-channel capture, timing, metadata, and CPI contract correctly?", ...
    "Prevents later failures from being blamed on radar logic when the base capture contract is wrong.", ...
    [
    "summary.md"
    "metrics.json"
    "metrics.mat"
    "manifest_vs_observed.csv"
    "decode_contract_summary.md"
    "seam_continuity_summary.csv"
    "timing_summary.csv"
    ]);

gateSpecs(2) = localMakeGateSpec( ...
    "G2 Stage 1", ...
    "G2Stage1", ...
    "G2_RF_Health_Stage1_AcquisitionEvidence", ...
    "G2 Stage 1 Acquisition Evidence", ...
    "Do we know which channel is reference and which is surveillance, and is that mapping traceable?", ...
    "Prevents black-box role assignment and accidental reference/surveillance inversion.", ...
    [
    "summary.md"
    "metrics.json"
    "metrics.mat"
    "channel_role_evidence.csv"
    "receiver_state_table.csv"
    "metadata_presence_audit.csv"
    ]);

gateSpecs(3) = localMakeGateSpec( ...
    "G2 Stage 2", ...
    "G2Stage2", ...
    "G2_RF_Health_Stage2_ReceiverIntegrity", ...
    "G2 Stage 2 Receiver Integrity", ...
    "Is the receiver data usable even though the reference path is weak?", ...
    "Separates acquisition limitation from digitizer corruption or broken analysis.", ...
    [
    "summary.md"
    "metrics.json"
    "metrics.mat"
    "receiver_integrity_table.csv"
    "channel_summary_table.csv"
    "decision_traceability_table.csv"
    ]);

gateSpecs(4) = localMakeGateSpec( ...
    "G3 Sync", ...
    "G3", ...
    "G3_Sync_Core", ...
    "G3 Sync Core", ...
    "Can reference and surveillance be aligned well enough for bistatic processing?", ...
    "Addresses time offset, residual carrier/frequency drift, and CPI coherence risk.", ...
    [
    "summary.md"
    "metrics.json"
    "metrics.mat"
    "lag_table.csv"
    "residual_frequency_table.csv"
    "cpi_coherence_table.csv"
    "question_summaries.csv"
    ]);

gateSpecs(5) = localMakeGateSpec( ...
    "G4 Baseline Map", ...
    "G4", ...
    "G4_Passive_Baseline_Map", ...
    "G4 Passive Baseline Map", ...
    "Does ambgfun produce a plausible passive ambiguity map under the frozen upstream contracts?", ...
    "Validates coordinate convention, direct-path plausibility, and map reproducibility.", ...
    [
    "summary.md"
    "metrics.json"
    "metrics.mat"
    "map_summary_table.csv"
    "repeatability_table.csv"
    "scene_metric_medians.csv"
    "representative_map_index.csv"
    "review_summary.csv"
    "question_summaries.csv"
    "interpretation_summary.csv"
    ]);

gateSpecs(6) = localMakeGateSpec( ...
    "G5 Mitigation", ...
    "G5", ...
    "G5_Mitigation", ...
    "G5 Mitigation", ...
    "Does LMS mitigation reveal useful off-origin structure without erasing protected target content?", ...
    "Distinguishes failed formal promotion from useful diagnostic evidence and threshold sensitivity.", ...
    [
    "summary.md"
    "metrics.json"
    "metrics.mat"
    "mitigation_metric_table.csv"
    "suppression_summary_table.csv"
    "protected_region_retention_table.csv"
    "decision_comparison_table.csv"
    "review_summary.csv"
    ]);

gateSpecs(7) = localMakeGateSpec( ...
    "G5 Diagnostic", ...
    "G5Diagnostic", ...
    "G5_Mitigation_Diagnostic", ...
    "G5 Diagnostic Sensitivity", ...
    "How sensitive is the mitigation conclusion to LMS profile and threshold choices?", ...
    "Shows diagnostic lift without changing gate decisions, thresholds, or tracker readiness.", ...
    [
    "summary.md"
    "metrics.json"
    "metrics.mat"
    "threshold_sensitivity_table.csv"
    "profile_sweep_summary_table.csv"
    "diagnostic_conclusion_table.csv"
    ]);

gateSpecs(8) = localMakeGateSpec( ...
    "G6 Freeze", ...
    "G6", ...
    "G6_CPI_Integration_Freeze", ...
    "G6 CPI Integration Freeze", ...
    "Is a detector-input CPI product frozen and ready for downstream use?", ...
    "Shows why detector products should not be promoted yet.", ...
    [
    "summary.md"
    "metrics.json"
    "metrics.mat"
    "freeze_decision_table.csv"
    "upstream_block_table.csv"
    ]);

gateSpecs(9) = localMakeGateSpec( ...
    "G7 Truth", ...
    "G7", ...
    "G7_Truth_Context_Diagnostic", ...
    "G7 Truth Context Diagnostic", ...
    "Are truth-alignment claims enabled for the current frozen detector product?", ...
    "Shows why truth-correlated claims should remain disabled until G6 freezes a product.", ...
    [
    "summary.md"
    "metrics.json"
    "metrics.mat"
    "claim_gate_table.csv"
    "timing_residual_summary_table.csv"
    "validation_window_table.csv"
    ]);

gateSpecs(10) = localMakeGateSpec( ...
    "G8 Readiness", ...
    "G8", ...
    "G8_Detection_Prerequisite_Gate", ...
    "G8 Detection Prerequisite Gate", ...
    "Are CFAR, detection, and tracking prerequisites satisfied?", ...
    "Keeps downstream detection execution blocked until G6/G7 prerequisites exist.", ...
    [
    "summary.md"
    "metrics.json"
    "metrics.mat"
    "execution_decision_table.csv"
    "prerequisite_block_table.csv"
    ]);

end

function gateSpec = localMakeGateSpec(phaseId, fieldName, artifactId, ...
    displayName, question, concern, requiredFiles)

gateSpec = localEmptyGateSpec();
gateSpec.PhaseId = string(phaseId);
gateSpec.FieldName = string(fieldName);
gateSpec.ArtifactId = string(artifactId);
gateSpec.DisplayName = string(displayName);
gateSpec.Question = string(question);
gateSpec.Concern = string(concern);
gateSpec.RequiredFiles = string(requiredFiles(:));

end

function gateSpec = localEmptyGateSpec()

gateSpec = struct();
gateSpec.PhaseId = "";
gateSpec.FieldName = "";
gateSpec.ArtifactId = "";
gateSpec.DisplayName = "";
gateSpec.Question = "";
gateSpec.Concern = "";
gateSpec.RequiredFiles = strings(0, 1);
gateSpec.Bundle = struct();

end

function gateRecord = localLoadGateRecord(gateSpec)

bundle = gateSpec.Bundle;
data = struct();
data.PhaseId = gateSpec.PhaseId;
data.FieldName = gateSpec.FieldName;
data.ArtifactId = gateSpec.ArtifactId;
data.DisplayName = gateSpec.DisplayName;
data.PassiveBistaticQuestion = gateSpec.Question;
data.ConcernAddressed = gateSpec.Concern;
data.Bundle = bundle;
data.Tables = struct();
data.Texts = struct();
data.Json = struct();
data.Mat = struct();

for fileIndex = 1:numel(bundle.RequiredFiles)
    relativeFile = bundle.RequiredFiles(fileIndex);
    artifactPath = fullfile(bundle.BundleRoot, relativeFile);
    [~, fileStem, fileExtension] = fileparts(relativeFile);
    dataKey = matlab.lang.makeValidName(string(fileStem));
    fileExtension = lower(string(fileExtension));

    switch fileExtension
        case ".csv"
            data.Tables.(dataKey) = localReadCsvTable(artifactPath);
        case ".md"
            data.Texts.(dataKey) = localReadTextFile(artifactPath);
        case ".json"
            data.Json.(dataKey) = localReadJsonFile(artifactPath);
        case ".mat"
            data.Mat.(dataKey) = localLoadMatFile(artifactPath);
    end
end

gateRecord = localEmptyGateRecord();
gateRecord.PhaseId = gateSpec.PhaseId;
gateRecord.FieldName = gateSpec.FieldName;
gateRecord.ArtifactId = gateSpec.ArtifactId;
gateRecord.DisplayName = gateSpec.DisplayName;
gateRecord.Question = gateSpec.Question;
gateRecord.Concern = gateSpec.Concern;
gateRecord.Bundle = bundle;
gateRecord.Data = data;

end

function gateRecord = localEmptyGateRecord()

gateRecord = struct();
gateRecord.PhaseId = "";
gateRecord.FieldName = "";
gateRecord.ArtifactId = "";
gateRecord.DisplayName = "";
gateRecord.Question = "";
gateRecord.Concern = "";
gateRecord.Bundle = struct();
gateRecord.Data = struct();

end

function phaseQuestionTable = localBuildPhaseQuestionTable(gateSpecs)

phaseId = string({gateSpecs.PhaseId}).';
artifactId = string({gateSpecs.ArtifactId}).';
question = string({gateSpecs.Question}).';
concern = string({gateSpecs.Concern}).';

phaseQuestionTable = table( ...
    phaseId, artifactId, question, concern, ...
    VariableNames = {'PhaseId', 'ArtifactId', ...
    'PassiveBistaticQuestion', 'ConcernAddressed'});

g45Row = table( ...
    "G4.5 Synthetic Recovery", ...
    "G4_5_SyntheticTargetRecovery", ...
    "Can the current map path recover known injected targets in real RF background?", ...
    "Provides a positive control showing the software path can localize targets when target evidence exists.", ...
    VariableNames = phaseQuestionTable.Properties.VariableNames);
phaseQuestionTable = [phaseQuestionTable; g45Row];

end

function bundleSummaryTable = localBuildBundleSummaryTable(gateRecords, ...
    g45ReportData)

phaseId = strings(numel(gateRecords), 1);
artifactId = strings(numel(gateRecords), 1);
runTimestampZ = strings(numel(gateRecords), 1);
bundleRoot = strings(numel(gateRecords), 1);

for gateIndex = 1:numel(gateRecords)
    phaseId(gateIndex) = gateRecords(gateIndex).PhaseId;
    artifactId(gateIndex) = gateRecords(gateIndex).ArtifactId;
    runTimestampZ(gateIndex) = gateRecords(gateIndex).Bundle.RunTimestampZ;
    bundleRoot(gateIndex) = gateRecords(gateIndex).Bundle.BundleRoot;
end

bundleSummaryTable = table( ...
    phaseId, artifactId, runTimestampZ, bundleRoot, ...
    VariableNames = {'PhaseId', 'ArtifactId', ...
    'RunTimestampZ', 'BundleRoot'});
g45Row = table( ...
    "G4.5 Synthetic Recovery", ...
    string(g45ReportData.StageArtifactId), ...
    string(g45ReportData.RunTimestampZ), ...
    string(g45ReportData.SuiteId), ...
    VariableNames = bundleSummaryTable.Properties.VariableNames);
bundleSummaryTable = [bundleSummaryTable; g45Row];

end

function artifactPathTable = localBuildArtifactPathTable(gateRecords, ...
    g45ReportData)

artifactPathTable = table( ...
    strings(0, 1), strings(0, 1), strings(0, 1), strings(0, 1), ...
    strings(0, 1), false(0, 1), ...
    VariableNames = {'PhaseId', 'ArtifactId', 'RunTimestampZ', ...
    'RelativePath', 'ArtifactPath', 'Exists'});

for gateIndex = 1:numel(gateRecords)
    bundle = gateRecords(gateIndex).Bundle;
    relativePaths = string(bundle.RequiredFiles(:));
    rowCount = numel(relativePaths);
    phaseId = repmat(gateRecords(gateIndex).PhaseId, rowCount, 1);
    artifactId = repmat(gateRecords(gateIndex).ArtifactId, rowCount, 1);
    runTimestampZ = repmat(bundle.RunTimestampZ, rowCount, 1);
    artifactPaths = fullfile(bundle.BundleRoot, relativePaths);
    existsMask = isfile(artifactPaths);
    artifactPathTable = [artifactPathTable; table( ...
        phaseId, artifactId, runTimestampZ, relativePaths, ...
        artifactPaths, existsMask, ...
        VariableNames = artifactPathTable.Properties.VariableNames)]; %#ok<AGROW>
end

g45ArtifactPathTable = localBuildG45ArtifactPathTable(g45ReportData);
artifactPathTable = [artifactPathTable; g45ArtifactPathTable];

end

function g45ArtifactPathTable = localBuildG45ArtifactPathTable(g45ReportData)

sourceTable = g45ReportData.ArtifactPathTable;
pathVariableNames = string(sourceTable.Properties.VariableNames);
pathVariableNames = pathVariableNames(endsWith(pathVariableNames, "Path"));
g45ArtifactPathTable = table( ...
    strings(0, 1), strings(0, 1), strings(0, 1), strings(0, 1), ...
    strings(0, 1), false(0, 1), ...
    VariableNames = {'PhaseId', 'ArtifactId', 'RunTimestampZ', ...
    'RelativePath', 'ArtifactPath', 'Exists'});

for rowIndex = 1:height(sourceTable)
    for pathIndex = 1:numel(pathVariableNames)
        pathValue = string(sourceTable.(pathVariableNames(pathIndex))(rowIndex));
        relativePath = string(sourceTable.CaseDatasetId(rowIndex)) + "/" + ...
            pathVariableNames(pathIndex);
        g45ArtifactPathTable = [g45ArtifactPathTable; table( ...
            "G4.5 Synthetic Recovery", ...
            string(g45ReportData.StageArtifactId), ...
            string(g45ReportData.RunTimestampZ), ...
            relativePath, pathValue, isfile(pathValue), ...
            VariableNames = g45ArtifactPathTable.Properties.VariableNames)]; %#ok<AGROW>
    end
end

end

function selectedEvidenceTable = localBuildSelectedEvidenceTable()

evidenceId = [
    "g2_raw_spectrum"
    "g2_reference_surveillance_delta"
    "g2_full_band_power_delta"
    "g2_psd_prominence"
    "g3_sync_overview"
    "g4_baseline_maps"
    "g4_scene_observability"
    "g45_recovery_prominence_summary"
    "g45_score_lift_summary"
    "g45_association_error_summary"
    "g45_pre_injection_map"
    "g45_injected_overlay_map"
    "g45_association_map"
    "g6_g8_readiness"
    ];
phaseId = [
    "G2 Stage 1"
    "G2 Stage 2"
    "G2 Stage 2"
    "G2 Stage 2"
    "G3 Sync"
    "G4 Baseline Map"
    "G4 Scene Observability"
    "G4.5 Synthetic Recovery"
    "G4.5 Synthetic Recovery"
    "G4.5 Synthetic Recovery"
    "G4.5 Synthetic Recovery"
    "G4.5 Synthetic Recovery"
    "G4.5 Synthetic Recovery"
    "G6-G8 Readiness"
    ];
plotPurpose = [
    "Raw channel pwelch PSD and magnitude-squared coherence before passive ambiguity map logic."
    "Accepted role-mapped mean PSD and pointwise PSD delta evidence."
    "Accepted role full-band mean-power delta by repetition."
    "Accepted role pilot-aware PSD prominence with pilot line separated from pilot-excluded data-band structure."
    "Lag stability, residual frequency, phase excursion, and coherence evidence."
    "Representative ambiguity map with direct-path trend evidence."
    "Scene observability metrics showing off-origin content limits."
    "Center-window recovery status and local prominence across easy, medium, hard, marginal, and multi-target cases."
    "Center-window robust Z score and control lift over pre-injection real background."
    "Center-window delay-bin and Doppler association errors against tolerance."
    "Real background before synthetic echo at the target coordinates."
    "ADS-B-derived synthetic echo over real HDTV IQ background."
    "Expected marker, associated marker, and tolerance region for recovery review."
    "Downstream freeze, truth, and detection prerequisite refusal evidence."
    ];

selectedEvidenceTable = table( ...
    evidenceId, phaseId, plotPurpose, ...
    VariableNames = {'EvidenceId', 'PhaseId', 'PlotPurpose'});

end

function storyTable = localBuildStoryInterpretationTable(reportData)

phaseId = strings(0, 1);
question = strings(0, 1);
concern = strings(0, 1);
selectedEvidence = strings(0, 1);
interpretation = strings(0, 1);
remainingChallenge = strings(0, 1);
bundleRoot = strings(0, 1);

[phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot] = localAppendStoryRow( ...
    phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot, reportData.G1, ...
    "manifest_vs_observed.csv; decode_contract_summary.md; seam_continuity_summary.csv", ...
    localG1Interpretation(reportData), ...
    "Keep later gate faults tied to saved capture-contract evidence before changing radar logic.");

[phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot] = localAppendStoryRow( ...
    phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot, reportData.G2Stage1, ...
    "channel_role_evidence.csv; receiver_state_table.csv; metadata_presence_audit.csv", ...
    localG2Stage1Interpretation(reportData), ...
    "Maintain explicit role mapping in future acquisitions so reference/surveillance assignment is reviewable.");

[phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot] = localAppendStoryRow( ...
    phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot, reportData.G2Stage2, ...
    "receiver_integrity_table.csv; channel_summary_table.csv; decision_traceability_table.csv", ...
    localG2Stage2Interpretation(reportData), ...
    "Improve the reference path without mistaking weak-reference acquisition limits for digitizer corruption.");

[phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot] = localAppendStoryRow( ...
    phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot, reportData.G3, ...
    "lag_table.csv; residual_frequency_table.csv; cpi_coherence_table.csv", ...
    localG3Interpretation(reportData), ...
    "Carry synchronization as ready evidence while keeping downstream observability separate.");

[phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot] = localAppendStoryRow( ...
    phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot, reportData.G4, ...
    "map_summary_table.csv; repeatability_table.csv; representative maps in metrics.mat", ...
    localG4BaselineInterpretation(reportData), ...
    "Do not freeze detector products until scene observability and raw/reduced-rate agreement are resolved.");

phaseId(end + 1, 1) = "G4.5 Synthetic Recovery";
question(end + 1, 1) = "Can the current map path recover known injected targets in real RF background?";
concern(end + 1, 1) = "Provides a positive control showing the software path can localize targets when target evidence exists.";
selectedEvidence(end + 1, 1) = "suite summary; assumptions summary; assumed-aircraft plausibility table; target_recovery_table.csv; RepresentativeMaps in metrics.mat";
interpretation(end + 1, 1) = localG45Interpretation(reportData);
remainingChallenge(end + 1, 1) = "Keep G4.5 diagnostic-only; it supports the software path but does not promote the real dataset.";
bundleRoot(end + 1, 1) = string(reportData.G45.SuiteId);

[phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot] = localAppendStoryRow( ...
    phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot, reportData.G5, ...
    "suppression_summary_table.csv; protected_region_retention_table.csv; decision_comparison_table.csv", ...
    localG5Interpretation(reportData), ...
    "Treat LMS changes as diagnostic until they reveal useful off-origin structure under formal upstream readiness.");

[phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot] = localAppendStoryRow( ...
    phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot, reportData.G5Diagnostic, ...
    "profile_sweep_summary_table.csv; threshold_sensitivity_table.csv; diagnostic_conclusion_table.csv", ...
    localG5DiagnosticInterpretation(reportData), ...
    "Use the sensitivity evidence to guide review, not to silently relax gate thresholds.");

phaseId(end + 1, 1) = "G6-G8 Readiness";
question(end + 1, 1) = "Are downstream freeze, truth alignment, and detection prerequisites satisfied?";
concern(end + 1, 1) = "Shows why CFAR, detection, tracking, and truth claims should not be promoted yet.";
selectedEvidence(end + 1, 1) = "G6 freeze_decision_table.csv; G7 claim_gate_table.csv; G8 prerequisite_block_table.csv";
interpretation(end + 1, 1) = localDownstreamInterpretation(reportData);
remainingChallenge(end + 1, 1) = "Keep CFAR, detection, tracking, and truth claims disabled until freeze and truth prerequisites exist.";
bundleRoot(end + 1, 1) = strjoin([
    string(reportData.G6.Bundle.BundleRoot)
    string(reportData.G7.Bundle.BundleRoot)
    string(reportData.G8.Bundle.BundleRoot)
    ], " | ");

storyTable = table( ...
    phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot, ...
    VariableNames = {'PhaseId', 'PassiveBistaticQuestion', ...
    'ConcernAddressed', 'SelectedEvidence', 'Interpretation', ...
    'RemainingChallenge', 'BundleRoot'});

end

function [phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot] = localAppendStoryRow( ...
    phaseId, question, concern, selectedEvidence, interpretation, ...
    remainingChallenge, bundleRoot, gateData, rowEvidence, rowInterpretation, ...
    rowChallenge)

phaseId(end + 1, 1) = gateData.PhaseId;
question(end + 1, 1) = gateData.PassiveBistaticQuestion;
concern(end + 1, 1) = gateData.ConcernAddressed;
selectedEvidence(end + 1, 1) = string(rowEvidence);
interpretation(end + 1, 1) = string(rowInterpretation);
remainingChallenge(end + 1, 1) = string(rowChallenge);
bundleRoot(end + 1, 1) = string(gateData.Bundle.BundleRoot);

end

function interpretation = localG1Interpretation(reportData)

manifestTable = localTable(reportData.G1, "manifest_vs_observed");
seamTable = localTable(reportData.G1, "seam_continuity_summary");
observedMask = localLogicalColumn(manifestTable, "Observed");
requiredMask = localLogicalColumn(manifestTable, "RequiredByManifest");
missingRequiredCount = sum(requiredMask & ~observedMask);
stableSeamCount = sum(string(seamTable.Status) == "ok_gap_expected");
interpretation = sprintf( ...
    "Required manifest misses = %.0f; seam/timing rows with expected gaps = %.0f of %.0f.", ...
    missingRequiredCount, stableSeamCount, height(seamTable));

end

function interpretation = localG2Stage1Interpretation(reportData)

roleTable = localTable(reportData.G2Stage1, "channel_role_evidence");
receiverStateTable = localTable(reportData.G2Stage1, "receiver_state_table");
roleLabels = unique(string(roleTable.RoleInference), "stable");
medianPowerDelta_dB = median(roleTable.ChannelPowerDelta_dB, "omitnan");
interpretation = sprintf( ...
    "Role inference is traceable through %s; median channel power delta = %.2f [dB] across %.0f captures and %.0f receiver-state rows.", ...
    strjoin(roleLabels, ", "), medianPowerDelta_dB, ...
    height(roleTable), height(receiverStateTable));

end

function interpretation = localG2Stage2Interpretation(reportData)

integrityTable = localTable(reportData.G2Stage2, "receiver_integrity_table");
decisionTable = localTable(reportData.G2Stage2, "decision_traceability_table");
medianReferenceDelta_dB = median( ...
    integrityTable.ReferenceMinusSurveillancePower_dB, "omitnan");
worstNearRail = max([ ...
    integrityTable.ReferenceNearRailFraction; ...
    integrityTable.SurveillanceNearRailFraction], [], "omitnan");
maxDcSpike_dB = max([ ...
    integrityTable.ReferenceDcSpike_dB; ...
    integrityTable.SurveillanceDcSpike_dB], [], "omitnan");
maxImpropriety = max([ ...
    integrityTable.ReferenceIqImpropriety; ...
    integrityTable.SurveillanceIqImpropriety], [], "omitnan");
interpretation = sprintf( ...
    "Full-band mean-power delta median = %.2f [dB]; worst near-rail fraction = %.3g; max DC spike = %.2f [dB]; max IQ impropriety = %.4f across %.0f decision rows.", ...
    medianReferenceDelta_dB, worstNearRail, maxDcSpike_dB, ...
    maxImpropriety, height(decisionTable));

end

function interpretation = localG3Interpretation(reportData)

lagTable = localTable(reportData.G3, "lag_table");
frequencyTable = localTable(reportData.G3, "residual_frequency_table");
coherenceTable = localTable(reportData.G3, "cpi_coherence_table");
maxLagSpread = max(lagTable.LagWindowSpread_samples, [], "omitnan");
minPeakToSidelobe_dB = min(lagTable.PeakToSidelobeMin_dB, [], "omitnan");
maxResidualFrequency_Hz = max( ...
    frequencyTable.ResidualFrequencyAbsMax_Hz, [], "omitnan");
minCoherencePassFraction = min( ...
    coherenceTable.CoherencePassFraction, [], "omitnan");
interpretation = sprintf( ...
    "Lag spread max = %.2f [samples], minimum peak-to-sidelobe = %.2f [dB], residual frequency max = %.3f [Hz], minimum coherence pass fraction = %.2f.", ...
    maxLagSpread, minPeakToSidelobe_dB, maxResidualFrequency_Hz, ...
    minCoherencePassFraction);

end

function interpretation = localG4BaselineInterpretation(reportData)

reviewSummary = localTable(reportData.G4, "review_summary");
sceneMedians = localTable(reportData.G4, "scene_metric_medians");
overallLabel = string(reviewSummary.OverallLabel(1));
sceneLabel = string(reviewSummary.SceneObservabilityLabel(1));
auditLabel = string(reviewSummary.FullRateAuditAgreementLabel(1));
medianOccupiedFraction = median( ...
    sceneMedians.OffOriginOccupiedFraction_abovePeakMinus20dB, "omitnan");
medianDirectPathToOffRidge_dB = median( ...
    sceneMedians.DirectPathToOffRidgeEnergy_dB, "omitnan");
interpretation = sprintf( ...
    "G4 status = %s; scene label = %s; raw/reduced-rate audit = %s; median occupied off-origin fraction = %.3g; median direct-path-to-off-ridge = %.2f [dB].", ...
    overallLabel, sceneLabel, auditLabel, medianOccupiedFraction, ...
    medianDirectPathToOffRidge_dB);

end

function interpretation = localG45Interpretation(reportData)

suiteSummary = reportData.G45.SuiteSummaryTable;
passCount = sum(ismember(suiteSummary.GateDecision, ["PASS", "CONTROL_PASS"]));
warnCount = sum(suiteSummary.GateDecision == "WARN");
bestProminence_dB = max(suiteSummary.BestProminence_dB, [], "omitnan");
assumptionCount = height(reportData.G45.AssumptionsSummaryTable);
plausibilityCount = height(reportData.G45.AssumedAircraftPlausibilityTable);
interpretation = sprintf( ...
    "Synthetic suite selected run %s with %.0f pass/control-pass cases, %.0f warn cases, best target prominence %.2f [dB], %.0f ADS-B-derived target-assumption rows, and %.0f assumed-aircraft plausibility rows over real HDTV IQ background.", ...
    reportData.G45.RunTimestampZ, passCount, warnCount, ...
    bestProminence_dB, assumptionCount, plausibilityCount);

end

function interpretation = localG5Interpretation(reportData)

decisionTable = localTable(reportData.G5, "decision_comparison_table");
retentionTable = localTable(reportData.G5, "protected_region_retention_table");
topCandidate = string(decisionTable.CandidateName(1));
topRole = string(decisionTable.DecisionRole(1));
medianSuppression_dB = decisionTable.MedianDirectPathSuppression_dB(1);
minRetentionRatio = min(retentionTable.MinimumProtectedRetentionRatio, [], ...
    "omitnan");
interpretation = sprintf( ...
    "Top diagnostic candidate = %s with %.2f [dB] direct-path suppression, decision role = %s, and minimum protected-region retention ratio = %.2f.", ...
    topCandidate, medianSuppression_dB, topRole, minRetentionRatio);

end

function interpretation = localG5DiagnosticInterpretation(reportData)

profileTable = localTable(reportData.G5Diagnostic, ...
    "profile_sweep_summary_table");
thresholdTable = localTable(reportData.G5Diagnostic, ...
    "threshold_sensitivity_table");
[bestScore, bestIndex] = max(profileTable.DiagnosticScore, [], "omitnan");
revealCount = sum(localLogicalColumn(thresholdTable, "WouldRevealScene"));
interpretation = sprintf( ...
    "Best diagnostic profile = %s/%s with score %.2f; permissive threshold probes that would reveal scene = %.0f of %.0f.", ...
    string(profileTable.ProfileId(bestIndex)), ...
    string(profileTable.CandidateName(bestIndex)), bestScore, ...
    revealCount, height(thresholdTable));

end

function interpretation = localDownstreamInterpretation(reportData)

g6FreezeTable = localTable(reportData.G6, "freeze_decision_table");
g7ClaimTable = localTable(reportData.G7, "claim_gate_table");
g8ExecutionTable = localTable(reportData.G8, "execution_decision_table");
g8BlockTable = localTable(reportData.G8, "prerequisite_block_table");
interpretation = sprintf( ...
    "G6 freeze status = %s; detector freeze enabled = %.0f; G7 truth claims enabled = %.0f; G8 execution refused = %.0f; prerequisite block rows = %.0f.", ...
    string(g6FreezeTable.FreezeStatus(1)), ...
    double(g6FreezeTable.DetectorProductFreezeEnabled(1)), ...
    double(g7ClaimTable.TruthClaimsEnabled(1)), ...
    double(g8ExecutionTable.ExecutionRefused(1)), height(g8BlockTable));

end

function outputTable = localTable(gateData, tableKey)

tableKey = matlab.lang.makeValidName(string(tableKey));

if ~isfield(gateData.Tables, tableKey)
    error("helperBuildPipelineStoryReport:MissingLoadedTable", ...
        "Loaded gate %s does not contain table key %s.", ...
        gateData.PhaseId, tableKey);
end

outputTable = gateData.Tables.(tableKey);

end

function logicalValues = localLogicalColumn(inputTable, variableName)

values = inputTable.(string(variableName));

if islogical(values)
    logicalValues = values;
elseif isnumeric(values)
    logicalValues = values ~= 0;
else
    textValues = lower(string(values));
    logicalValues = textValues == "true" | textValues == "1" | ...
        textValues == "yes";
end

logicalValues = logicalValues(:);

end

function outputTable = localReadCsvTable(csvPath)

try
    importOptions = detectImportOptions(csvPath, FileType = "text", ...
        Delimiter = ",", TextType = "string");
    outputTable = readtable(csvPath, importOptions);
catch csvException
    error("helperBuildPipelineStoryReport:CsvReadFailed", ...
        "Failed to read CSV artifact %s: %s", csvPath, ...
        csvException.message);
end

outputTable = localNormalizeTextVariables(outputTable);

end

function textValue = localReadTextFile(textPath)

try
    textValue = string(fileread(textPath));
catch textException
    error("helperBuildPipelineStoryReport:TextReadFailed", ...
        "Failed to read text artifact %s: %s", textPath, ...
        textException.message);
end

end

function decodedJson = localReadJsonFile(jsonPath)

try
    jsonText = fileread(jsonPath);
    decodedJson = jsondecode(jsonText);
catch jsonException
    error("helperBuildPipelineStoryReport:JsonReadFailed", ...
        "Failed to read JSON artifact %s: %s", jsonPath, ...
        jsonException.message);
end

end

function matData = localLoadMatFile(matPath)

try
    matData = load(matPath);
catch matException
    error("helperBuildPipelineStoryReport:MatReadFailed", ...
        "Failed to load MAT artifact %s: %s", matPath, ...
        matException.message);
end

end

function outputTable = localNormalizeTextVariables(inputTable)

outputTable = inputTable;
variableNames = string(outputTable.Properties.VariableNames);

for variableIndex = 1:numel(variableNames)
    variableName = variableNames(variableIndex);

    if isstring(outputTable.(variableName)) || ...
            iscellstr(outputTable.(variableName)) || ...
            ischar(outputTable.(variableName))
        outputTable.(variableName) = string(outputTable.(variableName));
    end
end

end

function localWriteStoryTables(reportData)

localEnsureFolder(reportData.ExportRoot);
localWriteTable(reportData.PhaseQuestionTable, fullfile( ...
    reportData.ExportRoot, "phase_question_table.csv"));
localWriteTable(reportData.BundleSummaryTable, fullfile( ...
    reportData.ExportRoot, "bundle_summary_table.csv"));
localWriteTable(reportData.ArtifactPathTable, fullfile( ...
    reportData.ExportRoot, "artifact_path_table.csv"));
localWriteTable(reportData.SelectedEvidenceTable, fullfile( ...
    reportData.ExportRoot, "selected_evidence_table.csv"));
localWriteTable(reportData.StoryInterpretationTable, fullfile( ...
    reportData.ExportRoot, "story_interpretation_table.csv"));
localWriteTable(reportData.G45.SuiteSummaryTable, fullfile( ...
    reportData.ExportRoot, "g45_suite_summary_table.csv"));
localWriteTable(reportData.G45.AssumptionsSummaryTable, fullfile( ...
    reportData.ExportRoot, "g45_assumptions_summary_table.csv"));
localWriteTable(reportData.G45.AssumedAircraftPlausibilityTable, fullfile( ...
    reportData.ExportRoot, ...
    "g45_assumed_aircraft_echo_plausibility_table.csv"));

end

function localEnsureFolder(folderPath)

if isfolder(folderPath)
    return
end

try
    mkdir(folderPath);
catch folderException
    error("helperBuildPipelineStoryReport:CreateFolderFailed", ...
        "Failed to create folder %s: %s", folderPath, ...
        folderException.message);
end

end

function localWriteTable(tableValue, tablePath)

try
    writetable(tableValue, tablePath);
catch writeException
    error("helperBuildPipelineStoryReport:WriteTableFailed", ...
        "Failed to write story table %s: %s", tablePath, ...
        writeException.message);
end

end


