%[text] # Passive Bistatic Pipeline Story
%[text] Thesis: the passive-bistatic code path is largely healthy through ingest, role evidence, synchronization, ambiguity-map construction, synthetic target recovery, and mitigation diagnostics. The current blocker is not a need to retune detector or tracker logic; it is the real dataset/acquisition/scene evidence, especially weak reference power, scene observability, and downstream freeze prerequisites.
%[text] This Live Script is artifact-only. It reads saved CSV, JSON, MAT, and Markdown evidence bundles and does not reread raw `.bb` captures.
%[text:tableOfContents]{"heading":"Table of Contents"}
%%
%[text] ## Setup 
%[text] Load the curated story report for the baseline dataset and write compact communication artifacts under `artifacts/communication/PipelineStory`. The reader-facing sections below use prose, plots, and short scalar summaries rather than large tables.
datasetId = "20260622T102123";
repoRoot = helperResolveRepoRoot();
reportOptions = struct();
reportOptions.ExportArtifacts = true;
reportData = helperBuildPipelineStoryReport(datasetId, repoRoot, reportOptions);
pilotExclusionHalfWidth_Hz = 50.0e3;
plotOptions = struct();
plotOptions.ExportFigures = true;
plotOptions.ShowFigures = usejava("desktop");
plotOptions.ExportRoot = reportData.ExportRoot;
plotOptions.G45MapCaseId = "easy_single_target";
plotOptions.G45MapWindowLabel = "center";
plotOptions.PsdPilotExclusionHalfWidth_Hz = pilotExclusionHalfWidth_Hz;
g2Stage1Role = reportData.G2Stage1.Mat.metrics.analysis.RoleEvidence;
g2Stage2Role = reportData.G2Stage2.Mat.metrics.analysis.RoleEvidence;
g2ReceiverTable = reportData.G2Stage2.Tables.receiver_integrity_table;
g3LagTable = reportData.G3.Tables.lag_table;
g3FrequencyTable = reportData.G3.Tables.residual_frequency_table;
g3CoherenceTable = reportData.G3.Tables.cpi_coherence_table;
g4ReviewSummary = reportData.G4.Tables.review_summary;
g4SceneTable = reportData.G4.Tables.scene_metric_medians;
g45AssumptionTable = reportData.G45.AssumptionsSummaryTable;
g45PlausibilityTable = reportData.G45.AssumedAircraftPlausibilityTable;
g45CaseIds = string({reportData.G45.CaseRecords.CaseDatasetId});
g45CaseIndex = find(g45CaseIds == plotOptions.G45MapCaseId, 1, "first");
g45CaseRecord = reportData.G45.CaseRecords(g45CaseIndex);
g45CenterFrequency_Hz = NaN;

if isfield(g45CaseRecord.TruthJson, "center_frequency_hz")
    g45CenterFrequency_Hz = double(g45CaseRecord.TruthJson.center_frequency_hz);
end

g45LightSpeed_mps = physconst("LightSpeed");
g45Wavelength_m = NaN;

if isfinite(g45CenterFrequency_Hz) && g45CenterFrequency_Hz > 0
    g45Wavelength_m = g45LightSpeed_mps ./ g45CenterFrequency_Hz;
end

g45TargetRows = g45CaseRecord.TargetRecoveryTable;
g45CenterRows = g45TargetRows(g45TargetRows.WindowLabel == ...
    plotOptions.G45MapWindowLabel, :);

if isempty(g45CenterRows)
    g45CenterRows = g45TargetRows(1, :);
end

g45TargetRow = g45CenterRows(1, :);
g45DelayErrorMapBins = double(g45TargetRow.DelayError_s) .* ...
    double(g45CaseRecord.Analysis.MapSampleRateHz);
g45SelectedAssumptionRows = g45AssumptionTable( ...
    g45AssumptionTable.CaseDatasetId == plotOptions.G45MapCaseId & ...
    g45AssumptionTable.TargetId == g45TargetRow.TargetId, :);

if isempty(g45SelectedAssumptionRows)
    g45AssumptionRow = g45AssumptionTable(1, :);
else
    g45AssumptionRow = g45SelectedAssumptionRows(1, :);
end

g45SelectedPlausibilityRows = g45PlausibilityTable( ...
    g45PlausibilityTable.CaseDatasetId == plotOptions.G45MapCaseId & ...
    g45PlausibilityTable.TargetId == g45TargetRow.TargetId, :);

if isempty(g45SelectedPlausibilityRows)
    g45SelectedPlausibilityRows = g45PlausibilityTable( ...
        1:min(3, height(g45PlausibilityTable)), :);
end

g45CoordinateSanityTable = helperBuildG45CoordinateSanityTable( ...
    reportData.G45, ...
    [plotOptions.G45MapCaseId; "multi_target"], ...
    [string(g45TargetRow.TargetId); "A862F2"], ...
    plotOptions.G45MapWindowLabel);

g2PsdFrequency_Hz = double(g2Stage2Role.PsdFrequencyHz(:));
referenceMeanPsd = max(double(g2Stage2Role.ReferenceMeanPsd(:)), eps);
surveillanceMeanPsd = max(double(g2Stage2Role.SurveillanceMeanPsd(:)), eps);
referencePsdMetrics = helperComputePilotAwarePsdMetrics( ...
    g2PsdFrequency_Hz, referenceMeanPsd, pilotExclusionHalfWidth_Hz);
surveillancePsdMetrics = helperComputePilotAwarePsdMetrics( ...
    g2PsdFrequency_Hz, surveillanceMeanPsd, pilotExclusionHalfWidth_Hz);
psdPointwiseDelta_dB = pow2db(referenceMeanPsd ./ surveillanceMeanPsd);
medianPsdPointwiseDelta_dB = median(psdPointwiseDelta_dB, "omitnan");
medianFullBandPowerDelta_dB = median( ...
    g2ReceiverTable.ReferenceMinusSurveillancePower_dB, "omitnan");
fprintf("Dataset:\t%s\n", reportData.DatasetId);
fprintf("Story export root:\t%s\n", reportData.ExportRoot);
fprintf("G4 selected bundle:\t%s\n", reportData.G4.Bundle.RunTimestampZ);
fprintf("G4.5 selected bundle:\t%s\n", reportData.G45.RunTimestampZ);
%%
%[text] ## 1. Raw Spectrum and Coherence 
%[text] Why not SNR? The saved G2 artifacts do not include a calibrated noise-only capture or a signal-only separation, so this story does not calculate true SNR. 
%[text] The current artifacts support channel power, PSD peak-to-median prominence, magnitude-squared coherence, and later map contrast. MATLAB functions `pwelch` and `mscohere` were used with G2 Stage 1 channel data to estimate average raw-channel PSD and magnitude-squared coherence; this story reads those saved `RoleEvidence` arrays. 
%[text] This plot is shown before any radar-map logic so a reviewer can see whether both receiver channels contain structured RF content and whether the channels are coherent. 
%[text] The coherence curve checks whether the two receiver channels share frequency-dependent RF content expected from a common illuminator/direct path; it supports role and sync plausibility, but it is not an SNR or target-detectability measurement. The evidence says the channels are not blank and carry coherent content with a persistent full-band mean-power imbalance.
helperPlotPipelineStoryEvidence(reportData, ...
    "g2_raw_spectrum", plotOptions);
fprintf("Raw channel full-band mean-power delta median:\t%.2f [dB]\n", ...
    g2Stage1Role.ChannelPowerDelta_dB_Median);
fprintf("Median magnitude-squared coherence:\t%.3f [ratio]\n", ...
    g2Stage1Role.MeanCoherence_Median);
%%
%[text] ## 2. Role-Mapped Spectral Comparison 
%[text] MATLAB function `pwelch` was used with G2 Stage 2 accepted role-mapped channel data to estimate reference and surveillance mean PSD; the second panel computes the PSD pointwise delta with `pow2db(ReferenceMeanPsd ./ SurveillanceMeanPsd)`. This plot explains the accepted role mapping after Stage 2 has assigned reference and surveillance channels. Look for frequency regions where the reference PSD is weaker or stronger than surveillance and use the median-over-frequency line as a compact spectral-delta summary. This is spectral subtraction over the saved mean PSD arrays, not a repetition-by-repetition full-band power metric.
helperPlotPipelineStoryEvidence(reportData, ...
    "g2_reference_surveillance_delta", plotOptions);
fprintf("Median PSD pointwise delta:\t%.2f [dB]\n", ...
    medianPsdPointwiseDelta_dB);
%%
%[text] ## 3. Full-Band Mean-Power Delta 
%[text] MATLAB vectorized mean power `mean(abs(x).^2)` was used with each G2 Stage 2 role-mapped repetition to estimate full-band mean power in dBFS. This plot shows the accepted reference and surveillance full-band mean power by repetition, then the reference-minus-surveillance full-band mean-power delta. The median-over-repetitions line summarizes the persistent weak-reference relationship without claiming a spectral or detection metric.
helperPlotPipelineStoryEvidence(reportData, ...
    "g2_full_band_power_delta", plotOptions);
fprintf("Full-band mean-power delta median:\t%.2f [dB]\n", ...
    medianFullBandPowerDelta_dB);
%%
%[text] ## 4. Pilot-Aware PSD Prominence 
%[text] MATLAB function `pwelch` was used with G2 Stage 2 accepted role-mapped channel data to estimate mean PSD arrays. The story first reports the dominant pilot-like line, then excludes a `50 kHz` half-width around that line before computing data-band PSD peak-to-median prominence. This plot separates pilot-line prominence from the pilot-excluded data-band prominence. The data-band prominence answers a caution question: after the dominant HDTV pilot-like line is excluded, is the accepted data band flat enough to behave like clean usable illumination? A high pilot-excluded value is a warning for non-flat or scalloped data-band structure, possible sidelobe/direct-path geometry, front-end response, fading, or operation near the noise floor. It is not an SNR value and it is not a "stronger is better" metric.
helperPlotPipelineStoryEvidence(reportData, ...
    "g2_psd_prominence", plotOptions);
fprintf("PSD pilot exclusion half-width:\t%.0f [Hz]\n", ...
    pilotExclusionHalfWidth_Hz);
fprintf("Reference pilot frequency:\t%.0f [Hz]\n", ...
    referencePsdMetrics.PilotFrequency_Hz);
fprintf("Reference pilot prominence:\t%.2f [dB]\n", ...
    referencePsdMetrics.PilotProminence_dB);
fprintf("Reference pilot-excluded data-band PSD prominence:\t%.2f [dB]\n", ...
    referencePsdMetrics.DataBandProminence_dB);
fprintf("Surveillance pilot frequency:\t%.0f [Hz]\n", ...
    surveillancePsdMetrics.PilotFrequency_Hz);
fprintf("Surveillance pilot prominence:\t%.2f [dB]\n", ...
    surveillancePsdMetrics.PilotProminence_dB);
fprintf("Surveillance pilot-excluded data-band PSD prominence:\t%.2f [dB]\n", ...
    surveillancePsdMetrics.DataBandProminence_dB);
%%
%[text] ## 5. Synchronization Overview 
%[text] G3 uses the saved synchronization-core artifacts to summarize lag stability, residual frequency, and CPI coherence after G2 role mapping. 
%[text] The metric questions are: 
%[text] - does `finddelay`/`xcorr` produce a repeatable lag
%[text] - does `spectrogram` plus `polyfit` show small residual carrier or phase drift
%[text] - and does `mscohere` say the candidate CPI windows remain coherently usable?  \
%[text] This section reintroduces synchronization evidence before any map-domain claim.
helperPlotPipelineStoryEvidence(reportData, ...
    "g3_sync_overview", plotOptions);
fprintf("G3 max lag-window spread:\t%.2f [samples]\n", ...
    max(g3LagTable.LagWindowSpread_samples, [], "omitnan"));
fprintf("G3 max residual frequency:\t%.3f [Hz]\n", ...
    max(g3FrequencyTable.ResidualFrequencyAbsMax_Hz, [], "omitnan"));
fprintf("G3 minimum coherence pass fraction:\t%.2f [ratio]\n", ...
    min(g3CoherenceTable.CoherencePassFraction, [], "omitnan"));
%%
%[text] ## 6. Baseline Passive Ambiguity Map 
%[text] G4 forms baseline `ambgfun` passive ambiguity maps from the frozen upstream contracts. The map validates coordinate convention and direct-path plausibility, but it does not by itself prove real-target observability. The five G4 CPI labels are 
%[text] - `short = 0.025 s`
%[text] - `short\_mid = 0.0375 s`
%[text] - `medium = 0.050 s`
%[text] - `medium\_long = 0.075 s`
%[text] - and `long = 0.100 s`.  \
%[text] The direct-path dominance metric is the direct-path power relative to the median off-origin, nonzero-Doppler power, reported in dB. Large positive values mean the map is dominated by the direct path/ridge rather than isolated off-origin target-like content.
%[text] Definition: `median off-origin` is the median linear map power over cells outside the direct-path exclusion region and outside the zero-Doppler ridge. It is calculated before the final dB ratio, so it is not a median of displayed dB values.
%[text] How calculated: `direct-path-to-off-ridge` is `pow2db(directPathPower / median(offOriginNonzeroDopplerPower))`. The numerator is the direct-path map power, and the denominator is the off-origin, nonzero-Doppler background summary.
%[text] Why it matters: a large positive value says the map is dominated by direct-path/ridge energy instead of isolated off-origin target-like content. What it does not prove: the representative map validates coordinate convention and direct-path dominance, not target detectability or the target power required for detection. \
helperPlotPipelineStoryEvidence(reportData, ...
    "g4_baseline_maps", plotOptions);
fprintf("G4 overall label:\t%s\n", g4ReviewSummary.OverallLabel(1));
fprintf("G4 raw/reduced-rate audit label:\t%s\n", ...
    g4ReviewSummary.FullRateAuditAgreementLabel(1));
%%
%[text] ## 7. Scene Observability Limits 
%[text] The G4 observability plot is the explicit reviewer warning: current real-scene map content is direct-path dominated and does not justify downstream detector or tracker promotion. The off-origin occupancy metric counts the fraction of off-origin, nonzero-Doppler cells above the map peak minus 20 dB. In this saved bundle, that occupied fraction is extremely small, so the high direct-path-to-off-ridge values are a limitation signal rather than evidence of usable target structure.
%[text] Definition: `off-origin occupancy` is the fraction of map cells outside the direct-path exclusion region and outside the zero-Doppler ridge that exceed the direct-path peak minus `20 dB`.
%[text] How calculated: each G4 ambiguity map is formed within a CPI using `ambgfun`; repetitions and CPI labels are summarized statistically, not coherently integrated across CPIs. The occupancy ratio counts only off-origin, nonzero-Doppler cells that clear the peak-minus-20 dB threshold.
%[text] Why it matters: when direct-path-to-off-ridge is high and off-origin occupancy is very small, the map evidence is dominated by the direct path and does not support a claim that usable real-target structure is present. \
helperPlotPipelineStoryEvidence(reportData, ...
    "g4_scene_observability", plotOptions);
fprintf("G4 scene observability label:\t%s\n", ...
    g4ReviewSummary.SceneObservabilityLabel(1));
fprintf("Median center-window off-origin occupied fraction:\t%.3g [ratio]\n", ...
    median(g4SceneTable.OffOriginOccupiedFraction_abovePeakMinus20dB, ...
    "omitnan"));
%%
%[text] ## 8. G4.5 Split Study Summary and Assumptions 
%[text] G4.5 overlays ADS-B-derived synthetic echoes onto real collected HDTV IQ background, then compares the injected result against the real background before synthetic echo at the same target coordinates. This is a positive-control story for the software path, not a promotion of the real G4 scene. The summary evidence is split into recovery/prominence, robust-score/control-lift, and association-error figures so the center-window target labels remain readable. 
%[text] - The echo model is `real\_background\_toolbox\_wideband\_free\_space\_v1`.
%[text] - Synthetic echoes are ADS-B-derived, generated in measurement-space excess-path coordinates, and overlaid on real HDTV IQ surveillance background while the reference channel remains the real capture.
%[text] - Echo gain is an applied synthetic amplitude gain after propagated echo normalization.
%[text] - Target power relative to background is a diagnostic-suite level, not calibrated received target power.
%[text] - Callsign and ICAO/ADS-B source ID identify a track; callsign alone is not aircraft type and must not be treated as an RCS source.
%[text] - The saved artifacts provide TX/RX LLA, center frequency, ADS-B target ID and callsign, expected delay, expected bistatic Doppler, expected bistatic range and range-rate, echo gain, and target power relative to background.
%[text] - They do not provide calibrated bistatic RCS, instantaneous target LLA/3D velocity, or aircraft type, and this story does not invent them. \
%[text] The coordinate sanity table keeps the signed G4 raw-axis convention visible. Positive expected delay appears as negative raw association delay, and raw association Doppler is converted to bistatic path range-rate using the center-frequency wavelength. The `multi_target/A862F2` row is included so reviewers can see a farther-from-origin case in the same suite.
fprintf("G4.5 target-coordinate sanity table:\n");
disp(g45CoordinateSanityTable);
helperPlotPipelineStoryEvidence(reportData, ...
    "g45_recovery_prominence_summary", plotOptions);
helperPlotPipelineStoryEvidence(reportData, ...
    "g45_score_lift_summary", plotOptions);
helperPlotPipelineStoryEvidence(reportData, ...
    "g45_association_error_summary", plotOptions);
fprintf("G4.5 assumption rows:\t%d [count]\n", ...
    height(g45AssumptionTable));
fprintf("Selected ADS-B target:\t%s / %s\n", ...
    g45AssumptionRow.AdsbSourceId, g45AssumptionRow.Callsign);
fprintf("Selected TX LLA:\t%s [deg,deg,m]\n", ...
    g45AssumptionRow.TxLla_deg_m);
fprintf("Selected RX LLA:\t%s [deg,deg,m]\n", ...
    g45AssumptionRow.RxLla_deg_m);
fprintf("Selected center frequency:\t%.0f [Hz]\n", ...
    g45CenterFrequency_Hz);
fprintf("Selected expected delay:\t%.9f [s]\n", ...
    g45AssumptionRow.ExpectedDelay_s);
fprintf("Selected expected bistatic Doppler:\t%.2f [Hz]\n", ...
    g45AssumptionRow.ExpectedBistaticDoppler_Hz);
fprintf("Selected expected bistatic range:\t%.2f [m]\n", ...
    g45AssumptionRow.ExpectedBistaticRange_m);
fprintf("Selected expected bistatic range-rate:\t%.2f [m/s]\n", ...
    g45AssumptionRow.ExpectedBistaticRangeRate_mps);
fprintf("Selected echo gain:\t%.2f [dB]\n", ...
    g45AssumptionRow.EchoGain_dB);
fprintf("Selected target power relative to background:\t%.2f [dB]\n", ...
    g45AssumptionRow.TargetPowerRelativeToBackground_dB);
fprintf("Unavailable synthetic-target assumptions:\t%s\n", ...
    g45AssumptionRow.UnavailableAssumptions);
fprintf("Unavailable aircraft/RCS note:\t%s\n", ...
    "aircraft type is not present; callsign and ICAO identify a track only");
%%
%[text] ## 9. G4.5 Assumed-Aircraft Echo Plausibility Appendix 
%[text] Direct bistatic-RCS inference from the current artifacts is still not valid. The saved fields are enough for a forward-model sensitivity question only: Would a conservative assumed medium-aircraft echo be near the synthetic injected levels or likely buried under current map/background limits? 
%[text] The helper uses TX/RX LLA, center frequency, expected bistatic excess range, assumed `sigma\_b` values of `1`, `10`, and `100 m^2`, symmetric target-leg ranges `R\_tx\_target = R\_target\_rx = (R\_tx\_rx + excessRange) / 2`, `0 dB` antenna gain ratios, and `-6 dB` combined polarization/propagation/loss factor. 
%[text] The comparison against synthetic target/background level is diagnostic only. It is not calibration, not measured target power, not aircraft type identification, and not inferred bistatic RCS.
fprintf("G4.5 calibrated or inferred bistatic RCS status:\t%s\n", ...
    "not valid from current artifacts");
fprintf("G4.5 forward-model question:\t%s\n", ...
    g45SelectedPlausibilityRows.ForwardQuestion(1));
fprintf("Assumed aircraft RCS cases:\t%s [m^2]\n", ...
    strjoin(string(g45SelectedPlausibilityRows.AssumedSigmaB_m2), ", "));
fprintf("Estimated echo/direct ratios:\t%s [dB]\n", ...
    strjoin(compose("%.2f", ...
    g45SelectedPlausibilityRows.EchoToDirectRatio_dB), ", "));
fprintf("Synthetic diagnostic target/background:\t%.2f [dB]\n", ...
    g45AssumptionRow.TargetPowerRelativeToBackground_dB);
fprintf("Assumed-aircraft caveat:\t%s\n", ...
    g45SelectedPlausibilityRows.Caveat(1));
%%
%[text] ## 10. Real Background Before Synthetic Echo 
%[text] This plot shows the real background before synthetic echo for the same G4.5 window used in the injected case. Reviewers should look for whether the background already contains a target-like response at the expected synthetic location. The evidence says the pre-injection background is available and measured. It does not prove the real scene contains a natural target.
%[text] Physical-scale read: G4.5 reviewer maps convert signed raw-axis delay to bistatic excess range as `range_m = -delay_s * physconst("LightSpeed")` and raw Doppler to bistatic range-rate as `rangeRate_mps = doppler_Hz * wavelength_m`, where `wavelength_m = c / centerFrequency_Hz`.
%[text] The range shown here is bistatic excess path, `(Tx to target) + (target to Rx) - direct path`, not the full two-leg path length. Current artifacts support bistatic path range-rate sanity checks, not true 3D target velocity, because the saved assumptions explicitly lack instantaneous target LLA and 3D velocity.
%[text] The selected `easy_single_target/A075DF` case is near `50 km` excess range and about `-239 m/s` bistatic range-rate. The sanity table also includes `multi_target/A862F2`, near `106 km` excess range, so the suite is not confined to near-origin examples. \
helperPlotPipelineStoryEvidence(reportData, ...
    "g45_pre_injection_map", plotOptions);
fprintf("Pre-injection real-background map count:\t%d [count]\n", ...
    numel(g45CaseRecord.Analysis.ControlRepresentativeMaps));
fprintf("Pre-injection target-coordinate prominence:\t%.2f [dB]\n", ...
    g45TargetRow.ControlProminence_dB);
fprintf("Selected raw association delay:\t%.9f [s]\n", ...
    g45TargetRow.AssociationDelay_s);
fprintf("Selected raw association Doppler:\t%.2f [Hz]\n", ...
    g45TargetRow.AssociationDoppler_Hz);
fprintf("Selected raw-axis excess range:\t%.2f [m]\n", ...
    -double(g45TargetRow.AssociationDelay_s) .* g45LightSpeed_mps);
fprintf("Selected raw-axis range-rate:\t%.2f [m/s]\n", ...
    double(g45TargetRow.AssociationDoppler_Hz) .* g45Wavelength_m);
%%
%[text] 11\. Echo-Overlaid Map 
%[text] This plot overlays the known ADS-B-derived synthetic echo location on the injected G4.5 map and includes a zoomed target view. Reviewers should look for a localized response near the expected delay and Doppler. The evidence says the software path can form a map where the injected echo is visually reviewable and numerically measured. It does not promote the real G4 baseline scene or replace detector validation.
helperPlotPipelineStoryEvidence(reportData, ...
    "g45_injected_overlay_map", plotOptions);
fprintf("Target local prominence:\t%.2f [dB]\n", ...
    g45TargetRow.LocalProminence_dB);
fprintf("Target robust Z:\t%.2f\n", g45TargetRow.RobustZ);
fprintf("Target lift over pre-injection background:\t%.2f [dB]\n", ...
    g45TargetRow.ControlLift_dB);
%%
%[text] ## 12. Algorithm Association Map 
%[text] This plot shows the expected marker, the associated marker chosen by the algorithm, and the tolerance region, with a zoomed target view. Reviewers should look for a small delay/Doppler error and a recovery status that matches the scalar metrics. The evidence says the selected synthetic target is recovered within tolerance. It does not prove that CFAR, tracking, or truth validation is ready for uncontrolled real data.
helperPlotPipelineStoryEvidence(reportData, ...
    "g45_association_map", plotOptions);
fprintf("Association delay error:\t%.2f [map bins]\n", ...
    g45DelayErrorMapBins);
fprintf("Association Doppler error:\t%.2f [Hz]\n", ...
    g45TargetRow.DopplerError_Hz);
fprintf("Recovery status:\t%s\n", g45TargetRow.RecoveryStatus);
%%
%[text] ## 13. Downstream Meaning 
%[text] These plots build confidence in the software path through receiver evidence, synchronization, map formation, and synthetic positive controls. Reviewers should also see why downstream detector and tracker claims remain disabled. The evidence supports diagnostic software-path confidence. It does not promote detector freeze, CFAR execution, tracker readiness, or truth-correlated detection claims.
helperPlotPipelineStoryEvidence(reportData, ...
    "g6_g8_readiness", plotOptions);
g6FreezeTable = reportData.G6.Tables.freeze_decision_table;
g7ClaimTable = reportData.G7.Tables.claim_gate_table;
g8ExecutionTable = reportData.G8.Tables.execution_decision_table;
fprintf("G6 freeze status:\t%s\n", g6FreezeTable.FreezeStatus(1));
fprintf("G7 truth claims enabled:\t%d [0/1]\n", ...
    double(g7ClaimTable.TruthClaimsEnabled(1)));
fprintf("G8 execution refused:\t%d [0/1]\n", ...
    double(g8ExecutionTable.ExecutionRefused(1)));
%%
%[text] Artifact Links The full tables remain exported for audit, but they are not the reader-facing story surface.
fprintf("Story interpretation table:\t%s\n", ...
    fullfile(reportData.ExportRoot, "story_interpretation_table.csv"));
fprintf("Selected evidence table:\t%s\n", ...
    fullfile(reportData.ExportRoot, "selected_evidence_table.csv"));
fprintf("G4.5 assumptions summary table:\t%s\n", ...
    fullfile(reportData.ExportRoot, "g45_assumptions_summary_table.csv"));
fprintf("G4.5 assumed-aircraft plausibility table:\t%s\n", ...
    fullfile(reportData.ExportRoot, ...
    "g45_assumed_aircraft_echo_plausibility_table.csv"));
fprintf("Artifact path table:\t%s\n", ...
    fullfile(reportData.ExportRoot, "artifact_path_table.csv"));
