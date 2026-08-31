function sanityTable = helperBuildG45CoordinateSanityTable( ...
    g45ReportData, caseIds, targetIds, windowLabel)
%HELPERBUILDG45COORDINATESANITYTABLE Build G4.5 physical-coordinate checks.
%
%   SANITYTABLE = HELPERBUILDG45COORDINATESANITYTABLE(G45REPORTDATA,
%   CASEIDS, TARGETIDS, WINDOWLABEL) returns a compact reviewer table using
%   saved G4.5 target-recovery and assumption artifacts. It does not read raw
%   baseband captures.

arguments
    g45ReportData (1,1) struct
    caseIds (:,1) string = ["easy_single_target"; "multi_target"]
    targetIds (:,1) string = ["A075DF"; "A862F2"]
    windowLabel (1,1) string = "center"
end

caseIds = string(caseIds(:));
targetIds = string(targetIds(:));

if numel(caseIds) ~= numel(targetIds)
    error("helperBuildG45CoordinateSanityTable:InputSizeMismatch", ...
        "Case and target ID lists must have the same length.");
end

variableNames = {'CaseDatasetId', 'TargetId', 'WindowLabel', ...
    'ExpectedDelay_s', 'RawAssociationDelay_s', ...
    'ExpectedExcessRange_m', 'RawAssociationExcessRange_m', ...
    'ExpectedDoppler_Hz', 'RawAssociationDoppler_Hz', ...
    'ExpectedBistaticRangeRate_mps', 'RawAssociationRangeRate_mps', ...
    'RecoveryStatus'};
variableTypes = ["string", "string", "string", "double", "double", ...
    "double", "double", "double", "double", "double", "double", ...
    "string"];
sanityTable = table(Size = [0, numel(variableNames)], ...
    VariableTypes = variableTypes, VariableNames = variableNames);
lightSpeed_mps = physconst("LightSpeed");

for rowIndex = 1:numel(caseIds)
    caseRecord = localSelectCaseRecord(g45ReportData, caseIds(rowIndex));
    targetRow = localSelectTargetRow(caseRecord, targetIds(rowIndex), ...
        windowLabel);
    assumptionRow = localSelectAssumptionRow(g45ReportData, ...
        caseIds(rowIndex), targetIds(rowIndex));
    centerFrequency_Hz = localCenterFrequencyHz(caseRecord);
    wavelength_m = lightSpeed_mps ./ centerFrequency_Hz;
    rawAssociationDelay_s = double(targetRow.AssociationDelay_s(1));
    rawAssociationDoppler_Hz = double(targetRow.AssociationDoppler_Hz(1));
    rawAssociationExcessRange_m = -rawAssociationDelay_s .* lightSpeed_mps;
    rawAssociationRangeRate_mps = rawAssociationDoppler_Hz .* wavelength_m;
    newRow = table( ...
        string(caseIds(rowIndex)), ...
        string(targetIds(rowIndex)), ...
        string(targetRow.WindowLabel(1)), ...
        double(assumptionRow.ExpectedDelay_s(1)), ...
        rawAssociationDelay_s, ...
        double(assumptionRow.ExpectedBistaticRange_m(1)), ...
        rawAssociationExcessRange_m, ...
        double(assumptionRow.ExpectedBistaticDoppler_Hz(1)), ...
        rawAssociationDoppler_Hz, ...
        double(assumptionRow.ExpectedBistaticRangeRate_mps(1)), ...
        rawAssociationRangeRate_mps, ...
        string(targetRow.RecoveryStatus(1)), ...
        VariableNames = variableNames);
    sanityTable = [sanityTable; newRow]; %#ok<AGROW>
end

end

function caseRecord = localSelectCaseRecord(g45ReportData, caseId)

caseRecordIds = string({g45ReportData.CaseRecords.CaseDatasetId});
caseIndex = find(caseRecordIds == string(caseId), 1, "first");

if isempty(caseIndex)
    error("helperBuildG45CoordinateSanityTable:MissingCase", ...
        "G4.5 case %s was not found in the loaded report data.", ...
        string(caseId));
end

caseRecord = g45ReportData.CaseRecords(caseIndex);

end

function targetRow = localSelectTargetRow(caseRecord, targetId, windowLabel)

targetTable = caseRecord.TargetRecoveryTable;
targetMask = string(targetTable.TargetId) == string(targetId);
windowMask = string(targetTable.WindowLabel) == string(windowLabel);
rowIndex = find(targetMask & windowMask, 1, "first");

if isempty(rowIndex)
    rowIndex = find(targetMask, 1, "first");
end

if isempty(rowIndex)
    error("helperBuildG45CoordinateSanityTable:MissingTarget", ...
        "G4.5 case %s does not include target %s.", ...
        string(caseRecord.CaseDatasetId), string(targetId));
end

targetRow = targetTable(rowIndex, :);

end

function assumptionRow = localSelectAssumptionRow(g45ReportData, caseId, targetId)

assumptionTable = g45ReportData.AssumptionsSummaryTable;
caseMask = string(assumptionTable.CaseDatasetId) == string(caseId);
targetMask = string(assumptionTable.TargetId) == string(targetId);
rowIndex = find(caseMask & targetMask, 1, "first");

if isempty(rowIndex)
    error("helperBuildG45CoordinateSanityTable:MissingAssumption", ...
        "G4.5 assumptions summary does not include %s/%s.", ...
        string(caseId), string(targetId));
end

assumptionRow = assumptionTable(rowIndex, :);

end

function centerFrequency_Hz = localCenterFrequencyHz(caseRecord)

centerFrequency_Hz = NaN;

if isfield(caseRecord, "TruthJson") && ...
        isfield(caseRecord.TruthJson, "center_frequency_hz")
    centerFrequency_Hz = double(caseRecord.TruthJson.center_frequency_hz);
end

if ~(isfinite(centerFrequency_Hz) && centerFrequency_Hz > 0)
    error("helperBuildG45CoordinateSanityTable:MissingCenterFrequency", ...
        "G4.5 case %s does not provide a valid center_frequency_hz field.", ...
        string(caseRecord.CaseDatasetId));
end

end