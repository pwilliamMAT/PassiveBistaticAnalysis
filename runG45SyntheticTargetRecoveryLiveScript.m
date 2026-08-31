%[text] # G4.5 Synthetic Target Recovery Report
%[text] This plot-first report reads the saved canonical G4.5 artifact bundles, keeps the reviewed run timestamp, and teaches why each case passes or warns before showing the full audit tables.
%%
%[text] ## Setup
%[text] Pick the saved experiment we are reviewing. The default is the latest common complete G4.5 artifact timestamp across the six canonical cases, and this report does not reread or reanalyze any `.bb` files.
suiteId = "g4_5_real_background_20260807T162306840";
runTimestampZ = "latest";
caseIds = [
    "real_only_control"
    "easy_single_target"
    "medium_single_target"
    "hard_single_target"
    "marginal_single_target"
    "multi_target"
    ];
try
    repoRoot = helperResolveRepoRoot();
    reportOptions = struct();
    reportOptions.RunTimestampZ = runTimestampZ;
    reportOptions.CaseIds = caseIds;
    reportData = helperBuildG45SyntheticTargetRecoveryReport(suiteId, ...
        repoRoot, reportOptions);
catch reportException
    error("runG45SyntheticTargetRecoveryLiveScript:ArtifactLoadFailed", ...
        "Failed to load saved G4.5 artifacts: %s", reportException.message);
end
localPrintReportSetup(reportData);
%%
%[text] ## Plain-Language Interpretation
%[text] We hid pretend aircraft echoes in real radio noise and asked whether the baseline passive map could find them. A clean pass means the synthetic target lands near the expected raw delay/Doppler point and stays stronger than the matched real-only control probe; a warn means the target-like evidence exists but is too sensitive to the control, thresholds, or scene conditions to call clean.
localPrintTeachingFrame();
%%
%[text] ## Suite Decision Matrix
%[text] This is the scoreboard for all cases. Each cell is one review window: early, center, or late. The real-only control has no injected target, so its row is intentionally gray.
localPlotSuiteDecisionHeatmap(reportData);
%%
%[text] ## Metric Threshold Ladder
%[text] These are the rules for calling a dot found, weakly found, or not found. Local prominence and robust Z say whether the expected point is locally distinctive; control lift says whether it rises above the matching real-only background probe.
localPlotMetricLadder(reportData);
%%
%[text] ## G4 Raw Coordinate Convention
%[text] The map uses the G4 raw `ambgfun` coordinate convention. Expected truth delay and bistatic Doppler are sign-converted before association, so the visual target point appears mirrored from the physical truth values.
localPlotTruthConvention(reportData);
%%
%[text] ## Real-Only Control Comparison
%[text] The control comparison is the heart of the WARN logic. We check whether the empty background also makes a fake dot at the same truth probe point before trusting a synthetic recovery.
localPlotGlobalControlComparison(reportData);
%%
%[text] ## Real-Only Control Probe Evidence
%[text] The real-only control has no injected target and stores no representative Range-Doppler maps. Its role is to show whether the real RF background alone produces target-like probe responses.
localPrintCaseSummary(reportData, "real_only_control");
localPlotControlProbeSummary(reportData);
%%
%[text] ## Easy Single-Target Raw Range-Doppler Evidence
%[text] First inspect the no-overlay map. This shows the saved review map before the decision markers are added.
localPlotCaseRawRangeDoppler(reportData, "easy_single_target");
%%
%[text] ## Easy Single-Target Annotated Evidence
%[text] The overlay marks the expected G4 raw point, the nearest associated map point, and the tolerance box used by the decision.
localPlotCaseAnnotatedRangeDoppler(reportData, "easy_single_target");
%%
%[text] ## Easy Single-Target Metric Decision
%[text] The easy case passes because center and late windows meet pass-level recovery, while the early-row caveat is explained by the control comparison.
localPlotCaseMetricThresholds(reportData, "easy_single_target");
%%
%[text] ## Easy Single-Target Control Comparison
%[text] The control plot shows whether the synthetic response is separated from the matched real-only probe at each review window.
localPlotCaseControlComparison(reportData, "easy_single_target");
%%
%[text] ## Medium Single-Target Raw Range-Doppler Evidence
%[text] The medium map keeps the same review windows but reduces the injected target margin.
localPlotCaseRawRangeDoppler(reportData, "medium_single_target");
%%
%[text] ## Medium Single-Target Annotated Evidence
%[text] The marker and tolerance overlay show that the center point still localizes in the expected G4 raw coordinate neighborhood.
localPlotCaseAnnotatedRangeDoppler(reportData, "medium_single_target");
%%
%[text] ## Medium Single-Target Metric Decision
%[text] The medium case passes because the center row is recovered with enough lift over the control; late-window evidence weakens but remains a caveat.
localPlotCaseMetricThresholds(reportData, "medium_single_target");
%%
%[text] ## Medium Single-Target Control Comparison
%[text] The control-lift panel separates the recovered center point from the weaker late-window caveat.
localPlotCaseControlComparison(reportData, "medium_single_target");
%%
%[text] ## Hard Single-Target Raw Range-Doppler Evidence
%[text] The hard case is intentionally close to the sensitivity edge, so start with the clean map before reading the decision markers.
localPlotCaseRawRangeDoppler(reportData, "hard_single_target");
%%
%[text] ## Hard Single-Target Annotated Evidence
%[text] The expected point is visible enough to localize in the center window, but the map evidence is not clean enough for a pass call.
localPlotCaseAnnotatedRangeDoppler(reportData, "hard_single_target");
%%
%[text] ## Hard Single-Target Metric Decision
%[text] The hard case warns because the expected center point is only weak recovery and the control lift is below the pass requirement.
localPlotCaseMetricThresholds(reportData, "hard_single_target");
%%
%[text] ## Hard Single-Target Control Comparison
%[text] The matched real-only probe explains why target-like structure near the expected point is treated cautiously.
localPlotCaseControlComparison(reportData, "hard_single_target");
%%
%[text] ## Marginal Single-Target Raw Range-Doppler Evidence
%[text] The marginal map is the weakest single-target case and should be read as a sensitivity diagnostic, not a promotion gate.
localPlotCaseRawRangeDoppler(reportData, "marginal_single_target");
%%
%[text] ## Marginal Single-Target Annotated Evidence
%[text] The annotation shows localization near the expected point, but the decision depends on whether the metrics clear the pass ladder.
localPlotCaseAnnotatedRangeDoppler(reportData, "marginal_single_target");
%%
%[text] ## Marginal Single-Target Metric Decision
%[text] The marginal case warns because it has weak center recovery with low control lift and active sensitivity-limited interpretation.
localPlotCaseMetricThresholds(reportData, "marginal_single_target");
%%
%[text] ## Marginal Single-Target Control Comparison
%[text] The low synthetic-over-control separation is the main reason the marginal case remains WARN.
localPlotCaseControlComparison(reportData, "marginal_single_target");
%%
%[text] ## Multi-Target Raw Range-Doppler Evidence
%[text] The multi-target case uses the same windows but has two expected target IDs in the scene.
localPlotCaseRawRangeDoppler(reportData, "multi_target");
%%
%[text] ## Multi-Target Annotated Evidence
%[text] Target labels show which expected point belongs to each injected target. A pass requires each target ID to recover at the decision-driving center window.
localPlotCaseAnnotatedRangeDoppler(reportData, "multi_target");
%%
%[text] ## Multi-Target Metric Decision
%[text] The multi-target case passes because both target IDs have recovered center rows, even though early or late rows remain caveated.
localPlotCaseMetricThresholds(reportData, "multi_target");
%%
%[text] ## Multi-Target Control Comparison
%[text] The control comparison keeps the two target IDs separate so reviewers can see which rows have clean or caveated separation.
localPlotCaseControlComparison(reportData, "multi_target");
%%
%[text] ## Appendix: Analysis Questions
%[text] Receipts for reviewers who need every row begin here.
disp(reportData.CaseQuestionTable);
%%
%[text] ## Appendix: Suite Summary Table
%[text] Full suite summary table loaded from the saved artifact bundle.
disp(reportData.SuiteSummaryTable);
%%
%[text] ## Appendix: Decision Interpretation Table
%[text] Full decision rationale table.
disp(reportData.DecisionInterpretationTable);
%%
%[text] ## Appendix: Threshold Definition Table
%[text] Full threshold definition table with units and source fields.
disp(reportData.ThresholdDefinitionTable);
%%
%[text] ## Appendix: Target Recovery Rows
%[text] Full target recovery rows with expected coordinates, associated coordinates, metrics, and caveats.
disp(reportData.TargetRecoveryTable);
%%
%[text] ## Appendix: False-Alarm Control Rows
%[text] Full matched real-only control probe rows.
disp(reportData.FalseAlarmSummaryTable);
%%
%[text] ## Appendix: Truth Convention Audit
%[text] Full sign-convention audit rows for expected truth and G4 raw association coordinates.
disp(reportData.TruthConventionAuditTable);
%%
%[text] ## Appendix: Active Issue Sources
%[text] Active diagnostic labels explain whether a case is limited by scene conditions, threshold policy, or sensitivity.
disp(reportData.ActiveIssueSourceTable);
%%
%[text] ## Appendix: Artifact Links
%[text] These paths point back to the MAT, JSON, and CSV files used by this report. The report is artifact-only: the source baseband files are not reread here.
disp(reportData.ArtifactPathTable);
function localPrintReportSetup(reportData)
fprintf("G4.5 suite:\t%s\n", reportData.SuiteId);
fprintf("Artifact run timestamp [UTC]:\t%s\n", reportData.RunTimestampZ);
fprintf("Case count [count]:\t%d\n", numel(reportData.CaseIds));
decisionList = reportData.SuiteSummaryTable.CaseDatasetId + "=" + ...
    reportData.SuiteSummaryTable.GateDecision;
fprintf("Loaded decisions:\t%s\n", strjoin(decisionList.', ", "));
end
function localPrintTeachingFrame()
fprintf("Interpretation:\t%s\n", "G4.5 is diagnostic only and does not promote G5, detector tuning, or tracking.");
fprintf("Coordinate convention:\t%s\n", "Expected truth is plotted after G4 raw ambgfun sign conversion.");
fprintf("Control policy:\t%s\n", "Control false alarms and low synthetic-over-control lift explain the WARN cases.");
end
function localPrintCaseSummary(reportData, caseId)
caseRecord = localFindCaseRecord(reportData, caseId);
analysis = caseRecord.Analysis;
fprintf("Case:\t%s\n", caseRecord.CaseDatasetId);
fprintf("Decision:\t%s\n", string(analysis.GateDecision));
fprintf("Range-Doppler map count [count]:\t%d\n", numel(analysis.RepresentativeMaps));
if isempty(analysis.RepresentativeMaps)
    fprintf("Range-Doppler note:\t%s\n", "No representative maps are stored for this case.");
end
end
function localPlotSuiteDecisionHeatmap(reportData)
windowLabels = localWindowLabels(reportData);
caseIds = reportData.CaseIds;
statusCodes = zeros(numel(caseIds), numel(windowLabels));
statusLabels = strings(numel(caseIds), numel(windowLabels));
for caseIndex = 1:numel(caseIds)
    caseRows = reportData.TargetRecoveryTable( ...
        reportData.TargetRecoveryTable.CaseDatasetId == caseIds(caseIndex), :);
    for windowIndex = 1:numel(windowLabels)
        windowRows = caseRows(caseRows.WindowLabel == windowLabels(windowIndex), :);
        [statusCodes(caseIndex, windowIndex), ...
            statusLabels(caseIndex, windowIndex)] = localWindowStatusCode(windowRows);
    end
end
figure("Name", "G4.5 Suite Decision Matrix", ...
    "Position", [100, 100, 1150, 520]);
imagesc(statusCodes);
colormap(gca, localStatusColormap());
clim([-0.5, 3.5]);
colorbarHandle = colorbar;
colorbarHandle.Ticks = 0:3;
colorbarHandle.TickLabels = ["no target", "not recovered", ...
    "weak", "recovered"];
axis tight;
caseTickLabels = strings(numel(caseIds), 1);
for caseIndex = 1:numel(caseIds)
    caseTickLabels(caseIndex) = localCaseDisplayName(caseIds(caseIndex)) + ...
        " (" + localGateDecisionFor(reportData, caseIds(caseIndex)) + ")";
end
set(gca, "XTick", 1:numel(windowLabels), "XTickLabel", windowLabels);
set(gca, "YTick", 1:numel(caseIds), "YTickLabel", caseTickLabels);
xlabel("Review window");
ylabel("G4.5 case and gate decision");
title("Saved target recovery status by case and review window");
hold on;
for caseIndex = 1:numel(caseIds)
    for windowIndex = 1:numel(windowLabels)
        labelText = localShortStatusLabel(statusLabels(caseIndex, windowIndex));
        textColor = localHeatmapTextColor(statusCodes(caseIndex, windowIndex));
        text(windowIndex, caseIndex, labelText, ...
            HorizontalAlignment="center", Color=textColor, ...
            FontWeight="bold", Interpreter="none");
    end
end
hold off;
end
function localPlotMetricLadder(reportData)
targetRows = reportData.TargetRecoveryTable;
if isempty(targetRows)
    fprintf("Metric ladder note:\t%s\n", "No target recovery rows were loaded.");
    return
end
thresholds = localRecoveryThresholds(reportData);
xValues = 1:height(targetRows);
rowLabels = localTargetRowLabels(targetRows, true);
figure("Name", "G4.5 Metric Threshold Ladder", ...
    "Position", [80, 80, 1500, 900]);
tiledlayout(3, 1, TileSpacing="compact", Padding="compact");
nexttile;
localPlotThresholdScatter(xValues, double(targetRows.LocalProminence_dB), ...
    string(targetRows.RecoveryStatus), rowLabels, "Target row", ...
    "Local prominence [dB]", "Local prominence versus warn/pass thresholds", ...
    [thresholds.WarnProminence_dB, thresholds.PassProminence_dB], ...
    ["warn prominence", "pass prominence"], "recovery");
nexttile;
localPlotThresholdScatter(xValues, double(targetRows.RobustZ), ...
    string(targetRows.RecoveryStatus), rowLabels, "Target row", ...
    "Robust Z [score]", "Robust Z versus warn/pass thresholds", ...
    [thresholds.WarnRobustZ, thresholds.PassRobustZ], ...
    ["warn robust Z", "pass robust Z"], "recovery");
nexttile;
localPlotThresholdScatter(xValues, double(targetRows.ControlLift_dB), ...
    string(targetRows.RecoveryStatus), rowLabels, "Target row", ...
    "Control lift [dB]", "Synthetic-over-control lift versus pass threshold", ...
    thresholds.MinControlLiftForPass_dB, "pass control lift", "recovery");
sgtitle("Decision ladder for saved G4.5 target recovery rows", ...
    Interpreter="none");
end
function localPlotTruthConvention(reportData)
truthRows = reportData.TruthConventionAuditTable;
if isempty(truthRows)
    fprintf("Truth convention note:\t%s\n", "No truth convention rows were loaded.");
    return
end
displayRows = truthRows(truthRows.WindowLabel == "center", :);
if isempty(displayRows)
    displayRows = truthRows;
end
figure("Name", "G4.5 Raw Coordinate Convention", ...
    "Position", [120, 120, 1250, 560]);
tiledlayout(1, 2, TileSpacing="loose", Padding="compact");
nexttile;
expectedDelay_us = double(displayRows.ExpectedDelay_s) .* 1.0e6;
expectedDoppler_Hz = double(displayRows.ExpectedBistaticDoppler_Hz);
g4Delay_us = double(displayRows.G4AssociationDelay_s) .* 1.0e6;
g4Doppler_Hz = double(displayRows.G4AssociationDoppler_Hz);
hold on;
plot(expectedDelay_us, expectedDoppler_Hz, "s", MarkerSize=8, ...
    MarkerFaceColor=[0.20, 0.45, 0.85], MarkerEdgeColor="k", ...
    DisplayName="truth coordinates");
plot(g4Delay_us, g4Doppler_Hz, "o", MarkerSize=8, ...
    MarkerFaceColor=[0.95, 0.55, 0.05], MarkerEdgeColor="k", ...
    DisplayName="G4 raw association");
for rowIndex = 1:height(displayRows)
    plot([expectedDelay_us(rowIndex), g4Delay_us(rowIndex)], ...
        [expectedDoppler_Hz(rowIndex), g4Doppler_Hz(rowIndex)], ...
        "-", Color=[0.45, 0.45, 0.45], HandleVisibility="off");
    labelText = localCaseShortName(displayRows.CaseDatasetId(rowIndex)) + ...
        "/" + displayRows.TargetId(rowIndex);
    text(g4Delay_us(rowIndex), g4Doppler_Hz(rowIndex), " " + labelText, ...
        Interpreter="none", FontSize=8, Clipping="on");
end
xline(0.0, ":", "zero delay", HandleVisibility="off");
yline(0.0, ":", "zero Doppler", HandleVisibility="off");
grid on;
xlabel("Delay [us]");
ylabel("Doppler [Hz]");
title("Truth values mirrored into G4 raw map coordinates");
legend(Location="best", Interpreter="none");
hold off;
nexttile;
delaySign = double(displayRows.DelaySignApplied(1));
dopplerSign = double(displayRows.DopplerSignApplied(1));
bar(categorical(["delay", "Doppler"]), [delaySign, dopplerSign], ...
    FaceColor=[0.25, 0.55, 0.65]);
hold on;
yline(0.0, "k-", HandleVisibility="off");
ylim([-1.2, 1.2]);
grid on;
xlabel("Coordinate component");
ylabel("Multiplier applied before association");
title("Saved G4 raw sign conversion");
hold off;
sgtitle("G4 raw coordinate convention used by target association", ...
    Interpreter="none");
end
function localPlotGlobalControlComparison(reportData)
targetRows = reportData.TargetRecoveryTable;
if isempty(targetRows)
    fprintf("Control comparison note:\t%s\n", "No synthetic target rows were loaded.");
    return
end
thresholds = localRecoveryThresholds(reportData);
xValues = 1:height(targetRows);
rowLabels = localTargetRowLabels(targetRows, true);
figure("Name", "G4.5 Global Control Comparison", ...
    "Position", [80, 80, 1500, 760]);
tiledlayout(2, 1, TileSpacing="compact", Padding="compact");
nexttile;
barData = [
    double(targetRows.LocalProminence_dB), ...
    double(targetRows.ControlProminence_dB)
    ];
bar(xValues, barData);
hold on;
yline(thresholds.WarnProminence_dB, "--", "warn prominence", ...
    HandleVisibility="off");
yline(thresholds.PassProminence_dB, "--", "pass prominence", ...
    HandleVisibility="off");
grid on;
set(gca, "XTick", xValues, "XTickLabel", rowLabels);
xtickangle(45);
xlabel("Target row");
ylabel("Local prominence [dB]");
title("Synthetic target response versus matched real-only control response");
legend(["synthetic target", "matched real-only control"], ...
    Location="northoutside", Orientation="horizontal", Interpreter="none");
hold off;
nexttile;
liftValues_dB = double(targetRows.ControlLift_dB);
barHandle = bar(xValues, liftValues_dB);
barHandle.FaceColor = "flat";
barHandle.CData = localColorsForStatus(string(targetRows.RecoveryStatus));
barHandle.HandleVisibility = "off";
hold on;
yline(thresholds.MinControlLiftForPass_dB, "--", ...
    "pass control lift", HandleVisibility="off");
yline(0.0, "k:", "same as control", HandleVisibility="off");
grid on;
localPadYLimits([liftValues_dB; thresholds.MinControlLiftForPass_dB; 0.0]);
set(gca, "XTick", xValues, "XTickLabel", rowLabels);
xtickangle(45);
xlabel("Target row");
ylabel("Synthetic-over-control lift [dB]");
title("Control lift used to separate target recovery from background probes");
localAddRecoveryStatusLegend();
hold off;
sgtitle("Global control comparison across saved G4.5 synthetic cases", ...
    Interpreter="none");
end
function localPlotControlProbeSummary(reportData)
controlRows = reportData.FalseAlarmSummaryTable;
if isempty(controlRows)
    fprintf("Control probe note:\t%s\n", "No false-alarm control rows were loaded.");
    return
end
thresholds = localRecoveryThresholds(reportData);
xValues = 1:height(controlRows);
rowLabels = localControlRowLabels(controlRows);
figure("Name", "G4.5 Real-Only Control Probe Summary", ...
    "Position", [90, 90, 1500, 760]);
tiledlayout(2, 1, TileSpacing="compact", Padding="compact");
nexttile;
localPlotControlThresholdScatter(xValues, ...
    double(controlRows.ControlProminence_dB), ...
    string(controlRows.FalseAlarmStatus), rowLabels, "Control probe row", ...
    "Control prominence [dB]", ...
    "Real-only control prominence at saved synthetic truth probes", ...
    [thresholds.WarnProminence_dB, thresholds.PassProminence_dB], ...
    ["warn prominence", "pass prominence"]);
nexttile;
localPlotControlThresholdScatter(xValues, double(controlRows.ControlRobustZ), ...
    string(controlRows.FalseAlarmStatus), rowLabels, "Control probe row", ...
    "Control robust Z [score]", ...
    "Real-only control robust Z at saved synthetic truth probes", ...
    [thresholds.WarnRobustZ, thresholds.PassRobustZ], ...
    ["warn robust Z", "pass robust Z"]);
sgtitle("Real-only background probe checks used by G4.5 WARN logic", ...
    Interpreter="none");
end
function localPlotCaseRawRangeDoppler(reportData, caseId)
caseRecord = localFindCaseRecord(reportData, caseId);
analysis = caseRecord.Analysis;
displayCaseId = localCaseDisplayName(caseId);
if isempty(analysis.RepresentativeMaps)
    fprintf("Raw Range-Doppler note:\t%s has no representative maps.\n", ...
        string(caseId));
    return
end
figure("Name", "G4.5 Raw Range-Doppler Evidence - " + string(caseId), ...
    "Position", [100, 100, 1500, 650]);
colorLimits_dB = localMapColorLimits(analysis.RepresentativeMaps);
tiledlayout(1, numel(analysis.RepresentativeMaps), ...
    TileSpacing="loose", Padding="compact");
for mapIndex = 1:numel(analysis.RepresentativeMaps)
    mapData = analysis.RepresentativeMaps(mapIndex);
    nexttile;
    localPlotRangeDopplerMapTile(caseRecord, displayCaseId, mapData, ...
        colorLimits_dB);
end
sgtitle("Raw no-overlay Range-Doppler maps in G4 raw coordinates", ...
    Interpreter="none");
end
function localPlotCaseAnnotatedRangeDoppler(reportData, caseId)
caseRecord = localFindCaseRecord(reportData, caseId);
analysis = caseRecord.Analysis;
displayCaseId = localCaseDisplayName(caseId);
if isempty(analysis.RepresentativeMaps)
    fprintf("Annotated Range-Doppler note:\t%s has no representative maps.\n", ...
        string(caseId));
    return
end
figure("Name", "G4.5 Annotated Range-Doppler Evidence - " + string(caseId), ...
    "Position", [100, 100, 1500, 650]);
colorLimits_dB = localMapColorLimits(analysis.RepresentativeMaps);
tiledlayout(1, numel(analysis.RepresentativeMaps), ...
    TileSpacing="loose", Padding="compact");
for mapIndex = 1:numel(analysis.RepresentativeMaps)
    mapData = analysis.RepresentativeMaps(mapIndex);
    nexttile;
    targetRows = localPlotRangeDopplerMapTile(caseRecord, displayCaseId, ...
        mapData, colorLimits_dB);
    localAddAnnotatedTargetOverlay(caseRecord, mapData, targetRows);
    if mapIndex == 1
        localAddAnnotatedLegend();
    end
end
sgtitle("Annotated target association, nearest map point, and tolerance box", ...
    Interpreter="none");
end
function localPlotCaseMetricThresholds(reportData, caseId)
caseRecord = localFindCaseRecord(reportData, caseId);
targetRows = caseRecord.TargetRecoveryTable;
if isempty(targetRows)
    fprintf("Case metric note:\t%s has no target rows.\n", string(caseId));
    return
end
thresholds = localRecoveryThresholdsFromCase(caseRecord);
xValues = 1:height(targetRows);
rowLabels = localTargetRowLabels(targetRows, false);
figure("Name", "G4.5 Case Metric Thresholds - " + string(caseId), ...
    "Position", [90, 90, 1300, 850]);
tiledlayout(3, 1, TileSpacing="compact", Padding="compact");
nexttile;
localPlotThresholdScatter(xValues, double(targetRows.LocalProminence_dB), ...
    string(targetRows.RecoveryStatus), rowLabels, "Target/window", ...
    "Local prominence [dB]", ...
    localCaseDisplayName(caseId) + ": local prominence threshold ladder", ...
    [thresholds.WarnProminence_dB, thresholds.PassProminence_dB], ...
    ["warn prominence", "pass prominence"], "recovery");
nexttile;
localPlotThresholdScatter(xValues, double(targetRows.RobustZ), ...
    string(targetRows.RecoveryStatus), rowLabels, "Target/window", ...
    "Robust Z [score]", ...
    localCaseDisplayName(caseId) + ": robust Z threshold ladder", ...
    [thresholds.WarnRobustZ, thresholds.PassRobustZ], ...
    ["warn robust Z", "pass robust Z"], "recovery");
nexttile;
localPlotThresholdScatter(xValues, double(targetRows.ControlLift_dB), ...
    string(targetRows.RecoveryStatus), rowLabels, "Target/window", ...
    "Control lift [dB]", ...
    localCaseDisplayName(caseId) + ": control lift pass gate", ...
    thresholds.MinControlLiftForPass_dB, "pass control lift", "recovery");
sgtitle(localCaseDisplayName(caseId) + " metric thresholds from saved artifacts", ...
    Interpreter="none");
end
function localPlotCaseControlComparison(reportData, caseId)
caseRecord = localFindCaseRecord(reportData, caseId);
targetRows = caseRecord.TargetRecoveryTable;
if isempty(targetRows)
    fprintf("Case control note:\t%s has no target rows.\n", string(caseId));
    return
end
thresholds = localRecoveryThresholdsFromCase(caseRecord);
xValues = 1:height(targetRows);
rowLabels = localTargetRowLabels(targetRows, false);
figure("Name", "G4.5 Case Control Comparison - " + string(caseId), ...
    "Position", [90, 90, 1300, 760]);
tiledlayout(2, 1, TileSpacing="compact", Padding="compact");
nexttile;
barData = [
    double(targetRows.LocalProminence_dB), ...
    double(targetRows.ControlProminence_dB)
    ];
bar(xValues, barData);
hold on;
yline(thresholds.WarnProminence_dB, "--", "warn prominence", ...
    HandleVisibility="off");
yline(thresholds.PassProminence_dB, "--", "pass prominence", ...
    HandleVisibility="off");
grid on;
set(gca, "XTick", xValues, "XTickLabel", rowLabels);
xtickangle(45);
xlabel("Target/window");
ylabel("Local prominence [dB]");
title(localCaseDisplayName(caseId) + ": synthetic response versus real-only control");
legend(["synthetic target", "matched real-only control"], ...
    Location="northoutside", Orientation="horizontal", Interpreter="none");
hold off;
nexttile;
liftValues_dB = double(targetRows.ControlLift_dB);
barHandle = bar(xValues, liftValues_dB);
barHandle.FaceColor = "flat";
barHandle.CData = localColorsForStatus(string(targetRows.RecoveryStatus));
barHandle.HandleVisibility = "off";
hold on;
yline(thresholds.MinControlLiftForPass_dB, "--", ...
    "pass control lift", HandleVisibility="off");
yline(0.0, "k:", "same as control", HandleVisibility="off");
grid on;
localPadYLimits([liftValues_dB; thresholds.MinControlLiftForPass_dB; 0.0]);
set(gca, "XTick", xValues, "XTickLabel", rowLabels);
xtickangle(45);
xlabel("Target/window");
ylabel("Synthetic-over-control lift [dB]");
title(localCaseDisplayName(caseId) + ": control lift used by recovery status");
localAddRecoveryStatusLegend();
hold off;
sgtitle(localCaseDisplayName(caseId) + " matched control comparison", ...
    Interpreter="none");
end
function targetRows = localPlotRangeDopplerMapTile(caseRecord, displayCaseId, ...
    mapData, colorLimits_dB)
imagesc(mapData.DelayAxis_s .* 1.0e6, mapData.DopplerAxis_Hz, ...
    mapData.ReviewMap_dB);
axis xy;
colormap(gca, "turbo");
clim(colorLimits_dB);
colorbarHandle = colorbar;
colorbarHandle.Label.String = "Review map [dB]";
xlabel("G4 raw delay [us]");
ylabel("G4 raw Doppler [Hz]");
title(displayCaseId + " " + string(mapData.WindowLabel), ...
    Interpreter="none");
targetRows = caseRecord.TargetRecoveryTable( ...
    caseRecord.TargetRecoveryTable.WindowLabel == mapData.WindowLabel, :);
localSetTargetView(targetRows, mapData);
end
function localAddAnnotatedTargetOverlay(caseRecord, mapData, targetRows)
if isempty(targetRows)
    return
end
options = caseRecord.Analysis.Options;
delayTolerance_us = localDelayTolerance_us(mapData, options);
dopplerTolerance_Hz = double(options.DopplerTolerance_Hz);
hold on;
for rowIndex = 1:height(targetRows)
    markerColor = localRecoveryStatusColor(targetRows.RecoveryStatus(rowIndex));
    associationDelay_us = double(targetRows.AssociationDelay_s(rowIndex)) .* ...
        1.0e6;
    associationDoppler_Hz = double(targetRows.AssociationDoppler_Hz(rowIndex));
    associatedDelay_us = double(targetRows.AssociatedDelay_s(rowIndex)) .* ...
        1.0e6;
    associatedDoppler_Hz = double(targetRows.AssociatedDoppler_Hz(rowIndex));
    rectangle(Position=[associationDelay_us - delayTolerance_us, ...
        associationDoppler_Hz - dopplerTolerance_Hz, ...
        2.0 .* delayTolerance_us, 2.0 .* dopplerTolerance_Hz], ...
        EdgeColor=markerColor, LineStyle="--", LineWidth=1.0, ...
        HandleVisibility="off");
    plot([associationDelay_us, associatedDelay_us], ...
        [associationDoppler_Hz, associatedDoppler_Hz], "-", ...
        Color=[0.15, 0.15, 0.15], LineWidth=0.75, ...
        HandleVisibility="off");
    plot(associationDelay_us, associationDoppler_Hz, "o", ...
        MarkerSize=8, MarkerFaceColor=markerColor, ...
        MarkerEdgeColor="k", LineWidth=1.0, HandleVisibility="off");
    plot(associatedDelay_us, associatedDoppler_Hz, "x", ...
        MarkerSize=9, Color="k", LineWidth=1.4, HandleVisibility="off");
    xLimits = double(xlim);
    yLimits = double(ylim);
    xCenter = mean(xLimits);
    yCenter = mean(yLimits);
    labelText = targetRows.TargetId(rowIndex) + newline + ...
        localShortStatusLabel(targetRows.RecoveryStatus(rowIndex));
    if associationDelay_us(1) > xCenter(1)
        labelDelay_us = associationDelay_us - 1.2 .* delayTolerance_us;
        horizontalAlignment = "right";
    else
        labelDelay_us = associationDelay_us + 1.2 .* delayTolerance_us;
        horizontalAlignment = "left";
    end
    if associationDoppler_Hz(1) > yCenter(1)
        labelDoppler_Hz = associationDoppler_Hz - 1.2 .* dopplerTolerance_Hz;
        verticalAlignment = "top";
    else
        labelDoppler_Hz = associationDoppler_Hz + 1.2 .* dopplerTolerance_Hz;
        verticalAlignment = "bottom";
    end
    text(labelDelay_us, labelDoppler_Hz, labelText, Color="k", ...
        BackgroundColor="w", Margin=1, FontSize=8, Interpreter="none", ...
        Clipping="on", HorizontalAlignment=horizontalAlignment, ...
        VerticalAlignment=verticalAlignment);
end
hold off;
end
function localPlotThresholdScatter(xValues, metricValues, statusValues, ...
    rowLabels, xLabelText, yLabelText, titleText, thresholdValues, ...
    thresholdLabels, legendMode)
hold on;
plot(xValues, metricValues, "-", Color=[0.55, 0.55, 0.55], ...
    HandleVisibility="off");
scatter(xValues, metricValues, 70, localColorsForStatus(statusValues), ...
    "filled", MarkerEdgeColor="k", HandleVisibility="off");
thresholdValues = double(thresholdValues);
for thresholdIndex = 1:numel(thresholdValues)
    yline(thresholdValues(thresholdIndex), "--", ...
        thresholdLabels(thresholdIndex), HandleVisibility="off");
end
grid on;
localPadYLimits([metricValues(:); thresholdValues(:)]);
set(gca, "XTick", xValues, "XTickLabel", rowLabels);
xtickangle(45);
xlabel(xLabelText);
ylabel(yLabelText);
title(titleText, Interpreter="none");
if legendMode == "recovery"
    localAddRecoveryStatusLegend();
end
hold off;
end
function localPlotControlThresholdScatter(xValues, metricValues, statusValues, ...
    rowLabels, xLabelText, yLabelText, titleText, thresholdValues, ...
    thresholdLabels)
hold on;
plot(xValues, metricValues, "-", Color=[0.55, 0.55, 0.55], ...
    HandleVisibility="off");
scatter(xValues, metricValues, 70, localColorsForControlStatus(statusValues), ...
    "filled", MarkerEdgeColor="k", HandleVisibility="off");
thresholdValues = double(thresholdValues);
for thresholdIndex = 1:numel(thresholdValues)
    yline(thresholdValues(thresholdIndex), "--", ...
        thresholdLabels(thresholdIndex), HandleVisibility="off");
end
grid on;
localPadYLimits([metricValues(:); thresholdValues(:)]);
set(gca, "XTick", xValues, "XTickLabel", rowLabels);
xtickangle(45);
xlabel(xLabelText);
ylabel(yLabelText);
title(titleText, Interpreter="none");
localAddControlStatusLegend();
hold off;
end
function caseRecord = localFindCaseRecord(reportData, caseId)
caseIndex = find(reportData.CaseIds == string(caseId), 1, "first");
if isempty(caseIndex)
    error("runG45SyntheticTargetRecoveryLiveScript:MissingCase", ...
        "Case %s was not loaded into reportData.", string(caseId));
end
caseRecord = reportData.CaseRecords(caseIndex);
end
function gateDecision = localGateDecisionFor(reportData, caseId)
summaryRows = reportData.SuiteSummaryTable( ...
    reportData.SuiteSummaryTable.CaseDatasetId == string(caseId), :);
if isempty(summaryRows)
    gateDecision = "";
    return
end
gateDecision = string(summaryRows.GateDecision(1));
end
function windowLabels = localWindowLabels(reportData)
options = localReferenceOptions(reportData);
windowLabels = string(options.AnalysisWindowLabels(:)).';
end
function thresholds = localRecoveryThresholds(reportData)
options = localReferenceOptions(reportData);
thresholds = localThresholdsFromOptions(options);
end
function thresholds = localRecoveryThresholdsFromCase(caseRecord)
thresholds = localThresholdsFromOptions(caseRecord.Analysis.Options);
end
function thresholds = localThresholdsFromOptions(options)
thresholds = struct();
thresholds.PassProminence_dB = double(options.PassProminence_dB);
thresholds.PassRobustZ = double(options.PassRobustZ);
thresholds.WarnProminence_dB = double(options.WarnProminence_dB);
thresholds.WarnRobustZ = double(options.WarnRobustZ);
thresholds.MinControlLiftForPass_dB = ...
    double(options.MinControlLiftForPass_dB);
end
function options = localReferenceOptions(reportData)
for caseIndex = 1:numel(reportData.CaseRecords)
    analysis = reportData.CaseRecords(caseIndex).Analysis;
    if isfield(analysis, "Options")
        options = analysis.Options;
        return
    end
end
error("runG45SyntheticTargetRecoveryLiveScript:MissingOptions", ...
    "No saved G4.5 analysis options were loaded.");
end
function [statusCode, statusLabel] = localWindowStatusCode(windowRows)
if isempty(windowRows)
    statusCode = 0.0;
    statusLabel = "NO_TARGET";
    return
end
statusValues = string(windowRows.RecoveryStatus);
if all(statusValues == "RECOVERED")
    statusCode = 3.0;
    statusLabel = "RECOVERED";
elseif any(statusValues == "NOT_RECOVERED")
    statusCode = 1.0;
    statusLabel = "NOT_RECOVERED";
elseif any(statusValues == "WEAK_RECOVERY")
    statusCode = 2.0;
    statusLabel = "WEAK_RECOVERY";
else
    statusCode = 0.0;
    statusLabel = "NO_TARGET";
end
end
function colorMap = localStatusColormap()
colorMap = [
    0.86, 0.86, 0.86
    0.85, 0.10, 0.10
    0.95, 0.55, 0.05
    0.00, 0.55, 0.20
    ];
end
function color = localHeatmapTextColor(statusCode)
if statusCode == 1.0 || statusCode == 3.0
    color = "w";
else
    color = "k";
end
end
function labelText = localShortStatusLabel(statusLabel)
switch string(statusLabel)
    case "RECOVERED"
        labelText = "recovered";
    case "WEAK_RECOVERY"
        labelText = "weak";
    case "NOT_RECOVERED"
        labelText = "not recovered";
    otherwise
        labelText = "no target";
end
end
function rowLabels = localTargetRowLabels(targetRows, includeCaseName)
if includeCaseName
    rowLabels = localCaseShortName(targetRows.CaseDatasetId) + "/" + ...
        targetRows.TargetId + "/" + targetRows.WindowLabel;
else
    rowLabels = targetRows.TargetId + "/" + targetRows.WindowLabel;
end
rowLabels = string(rowLabels);
end
function rowLabels = localControlRowLabels(controlRows)
rowLabels = localCaseShortName(controlRows.ProbeSourceCaseId) + "/" + ...
    controlRows.TargetId + "/" + controlRows.WindowLabel;
rowLabels = string(rowLabels);
end
function shortName = localCaseShortName(caseId)
shortName = string(caseId);
shortName = replace(shortName, "real_only_control", "control");
shortName = replace(shortName, "_single_target", "");
shortName = replace(shortName, "multi_target", "multi");
end
function displayCaseId = localCaseDisplayName(caseId)
displayCaseId = replace(string(caseId), "_", " ");
end
function colorLimits_dB = localMapColorLimits(representativeMaps)
mapValueCells = arrayfun(@(mapData) mapData.ReviewMap_dB(:), ...
    representativeMaps, UniformOutput=false);
finiteValues = vertcat(mapValueCells{:});
finiteValues = finiteValues(isfinite(finiteValues));
if isempty(finiteValues)
    colorLimits_dB = [0.0, 1.0];
    return
end
colorLimits_dB = [
    min(finiteValues)
    max(finiteValues)
    ].';
if colorLimits_dB(1) == colorLimits_dB(2)
    colorLimits_dB = colorLimits_dB + [-0.5, 0.5];
end
end
function localSetTargetView(targetRows, mapData)
if isempty(targetRows)
    return
end
targetDelay_us = [
    double(targetRows.AssociationDelay_s)
    double(targetRows.AssociatedDelay_s)
    ] .* 1.0e6;
targetDoppler_Hz = [
    double(targetRows.AssociationDoppler_Hz)
    double(targetRows.AssociatedDoppler_Hz)
    ];
delayMargin_us = max(1000.0, 0.75 .* range(targetDelay_us));
dopplerMargin_Hz = max(750.0, 0.75 .* range(targetDoppler_Hz));
delayAxis_us = double(mapData.DelayAxis_s) .* 1.0e6;
dopplerAxis_Hz = double(mapData.DopplerAxis_Hz);
xBounds = [
    max(min(delayAxis_us), min(targetDelay_us) - delayMargin_us)
    min(max(delayAxis_us), max(targetDelay_us) + delayMargin_us)
    ];
yBounds = [
    max(min(dopplerAxis_Hz), min(targetDoppler_Hz) - dopplerMargin_Hz)
    min(max(dopplerAxis_Hz), max(targetDoppler_Hz) + dopplerMargin_Hz)
    ];
if xBounds(1) < xBounds(2)
    xlim(xBounds);
end
if yBounds(1) < yBounds(2)
    ylim(yBounds);
end
end
function delayTolerance_us = localDelayTolerance_us(mapData, options)
delayAxis_us = double(mapData.DelayAxis_s) .* 1.0e6;
delaySteps_us = abs(diff(delayAxis_us));
delaySteps_us = delaySteps_us(isfinite(delaySteps_us));
if isempty(delaySteps_us)
    delayBinWidth_us = 1.0;
else
    delayBinWidth_us = median(delaySteps_us);
end
delayTolerance_us = double(options.DelayToleranceMapBins) .* delayBinWidth_us;
end
function markerColor = localRecoveryStatusColor(recoveryStatus)
switch string(recoveryStatus)
    case "RECOVERED"
        markerColor = [0.00, 0.55, 0.20];
    case "WEAK_RECOVERY"
        markerColor = [0.95, 0.55, 0.05];
    otherwise
        markerColor = [0.85, 0.10, 0.10];
end
end
function colors = localColorsForStatus(statusValues)
statusValues = string(statusValues);
colors = zeros(numel(statusValues), 3);
for statusIndex = 1:numel(statusValues)
    colors(statusIndex, :) = localRecoveryStatusColor(statusValues(statusIndex));
end
end
function colors = localColorsForControlStatus(statusValues)
statusValues = string(statusValues);
colors = zeros(numel(statusValues), 3);
for statusIndex = 1:numel(statusValues)
    switch statusValues(statusIndex)
        case "CONTROL_CLEAN"
            colors(statusIndex, :) = [0.00, 0.55, 0.20];
        case "CONTROL_FALSE_ALARM_WARN_LEVEL"
            colors(statusIndex, :) = [0.95, 0.55, 0.05];
        case "CONTROL_FALSE_ALARM_PASS_LEVEL"
            colors(statusIndex, :) = [0.85, 0.10, 0.10];
        otherwise
            colors(statusIndex, :) = [0.45, 0.45, 0.45];
    end
end
end
function localAddRecoveryStatusLegend()
scatter(NaN, NaN, 70, [0.00, 0.55, 0.20], "filled", ...
    MarkerEdgeColor="k", DisplayName="RECOVERED");
scatter(NaN, NaN, 70, [0.95, 0.55, 0.05], "filled", ...
    MarkerEdgeColor="k", DisplayName="WEAK_RECOVERY");
scatter(NaN, NaN, 70, [0.85, 0.10, 0.10], "filled", ...
    MarkerEdgeColor="k", DisplayName="NOT_RECOVERED");
legend(Location="best", Interpreter="none");
end
function localAddControlStatusLegend()
scatter(NaN, NaN, 70, [0.00, 0.55, 0.20], "filled", ...
    MarkerEdgeColor="k", DisplayName="CONTROL_CLEAN");
scatter(NaN, NaN, 70, [0.95, 0.55, 0.05], "filled", ...
    MarkerEdgeColor="k", DisplayName="CONTROL_FALSE_ALARM_WARN_LEVEL");
scatter(NaN, NaN, 70, [0.85, 0.10, 0.10], "filled", ...
    MarkerEdgeColor="k", DisplayName="CONTROL_FALSE_ALARM_PASS_LEVEL");
legend(Location="best", Interpreter="none");
end
function localAddAnnotatedLegend()
hold on;
plot(NaN, NaN, "o", MarkerSize=8, MarkerFaceColor=[0.00, 0.55, 0.20], ...
    MarkerEdgeColor="k", DisplayName="RECOVERED expected point");
plot(NaN, NaN, "o", MarkerSize=8, MarkerFaceColor=[0.95, 0.55, 0.05], ...
    MarkerEdgeColor="k", DisplayName="WEAK expected point");
plot(NaN, NaN, "o", MarkerSize=8, MarkerFaceColor=[0.85, 0.10, 0.10], ...
    MarkerEdgeColor="k", DisplayName="NOT recovered expected point");
plot(NaN, NaN, "x", MarkerSize=9, Color="k", LineWidth=1.4, ...
    DisplayName="associated map point");
plot(NaN, NaN, "--", Color=[0.15, 0.15, 0.15], ...
    DisplayName="association tolerance");
legend(Location="southoutside", Orientation="horizontal", ...
    Interpreter="none");
hold off;
end
function localPadYLimits(values)
finiteValues = values(isfinite(values));
if isempty(finiteValues)
    return
end
valueMin = min(finiteValues);
valueMax = max(finiteValues);
if valueMin == valueMax
    valueMin = valueMin - 1.0;
    valueMax = valueMax + 1.0;
end
padding = 0.10 .* (valueMax - valueMin);
ylim([valueMin - padding, valueMax + padding]);
end
%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
