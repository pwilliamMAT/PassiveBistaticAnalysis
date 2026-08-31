function verification = verifyG45SyntheticTargetRecovery(suiteId, ...
    repoRoot, options)
%VERIFYG45SYNTHETICTARGETRECOVERY Verify the canonical G4.5 suite.

arguments
    suiteId (1,1) string = "g4_5_real_background_20260807T162306840"
    repoRoot (1,1) string = string(fileparts(mfilename("fullpath")))
    options (1,1) struct = struct()
end

repoRoot = helperResolveRepoRoot(repoRoot);
suiteId = string(suiteId);

if ~isfield(options, "ShowFigures")
    options.ShowFigures = false;
end

fprintf("Running G4.5 synthetic target recovery verification\n");
fprintf("Suite:\t%s\n", suiteId);
fprintf("Repository root:\t%s\n", repoRoot);

results = runG45SyntheticTargetRecovery(suiteId, "all", repoRoot, options);
decisionTable = results.DecisionTable;
localAssert(height(decisionTable) == 6, ...
    "G4.5 verification must run all six canonical cases.");
localAssert(localDecisionFor(decisionTable, "real_only_control") == ...
    "CONTROL_PASS", "real_only_control must pass as the negative control.");
localAssert(localDecisionFor(decisionTable, "easy_single_target") == ...
    "PASS", "easy_single_target must recover the injected target.");
localAssert(ismember(localDecisionFor(decisionTable, ...
    "medium_single_target"), ["PASS", "WARN"]), ...
    "medium_single_target must be PASS or WARN.");
localAssert(ismember(localDecisionFor(decisionTable, ...
    "hard_single_target"), ["WARN", "FAIL"]), ...
    "hard_single_target must be WARN or FAIL without crashing.");
localAssert(ismember(localDecisionFor(decisionTable, ...
    "marginal_single_target"), ["WARN", "FAIL"]), ...
    "marginal_single_target must stay threshold-sensitive, not PASS.");
localAssert(ismember(localDecisionFor(decisionTable, ...
    "multi_target"), ["PASS", "WARN"]), ...
    "multi_target must validate association or emit WARN.");

for caseIndex = 1:numel(results.CaseResults)
    bundleRoot = string(results.CaseResults(caseIndex).BundleRoot);
    localAssert(isfolder(bundleRoot), ...
        "Expected G4.5 bundle root was not created.");
    localAssertRequiredArtifacts(bundleRoot, ...
        string(results.CaseResults(caseIndex).GateDecision));
end

easyBundle = localBundleFor(decisionTable, "easy_single_target");
targetTable = readtable(fullfile(easyBundle, ...
    "target_recovery_table.csv"), TextType = "string");
localAssert(any(targetTable.RecoveryStatus == "RECOVERED"), ...
    "easy_single_target must include numeric RECOVERED target rows.");
localAssert(all(isfinite(targetTable.LocalProminence_dB)), ...
    "target_recovery_table.csv must include numeric prominence metrics.");

verification = struct();
verification.Status = "passed";
verification.SuiteId = suiteId;
verification.RunTimestampZ = results.RunTimestampZ;
verification.DecisionTable = decisionTable;
verification.CaseResults = results.CaseResults;
verification.Passed = true;

fprintf("G4.5 verification status:\t%s\n", verification.Status);
disp(decisionTable);

end

function decision = localDecisionFor(decisionTable, caseDatasetId)

match = decisionTable.CaseDatasetId == string(caseDatasetId);
localAssert(any(match), "Missing expected case in decision table.");
decision = string(decisionTable.GateDecision(find(match, 1, "first")));

end

function bundleRoot = localBundleFor(decisionTable, caseDatasetId)

match = decisionTable.CaseDatasetId == string(caseDatasetId);
localAssert(any(match), "Missing expected bundle in decision table.");
bundleRoot = string(decisionTable.BundleRoot(find(match, 1, "first")));

end

function localAssertRequiredArtifacts(bundleRoot, gateDecision)

requiredFiles = [
    "summary.md"
    "summary.json"
    "metrics.json"
    "metrics.mat"
    "target_recovery_table.csv"
    "manifest_validation_table.csv"
    "truth_convention_audit_table.csv"
    "false_alarm_summary_table.csv"
    "diagnostic_interpretation_table.csv"
    "requirements_coverage.csv"
    "decision.txt"
    "next_branch.txt"
    "timing_summary.csv"
    "performance_summary.json"
    ];

if ~ismember(gateDecision, ["PASS", "CONTROL_PASS"])
    requiredFiles = [
        requiredFiles
        "failure_cause.txt"
        ];
end

for fileIndex = 1:numel(requiredFiles)
    filePath = fullfile(bundleRoot, requiredFiles(fileIndex));
    localAssert(isfile(filePath), "Missing required G4.5 artifact: " + ...
        string(filePath));
end

end

function localAssert(condition, message)

if ~condition
    error("verifyG45SyntheticTargetRecovery:AssertionFailed", ...
        "%s", message);
end

end
