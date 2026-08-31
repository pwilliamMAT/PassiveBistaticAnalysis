function samples = helperResolveRadarSamples(sessionData, radarTableRow)
%HELPERRESOLVERADARSAMPLES Reuse loaded IQ or decode one selected scan.

arguments
    sessionData (1,1) struct
    radarTableRow (1,1) double {mustBeInteger, mustBePositive}
end

radarTable = sessionData.RadarTable;

if radarTableRow > height(radarTable)
    error("helperResolveRadarSamples:RowOutOfRange", ...
        "Radar-table row %d exceeds the available %d rows.", ...
        radarTableRow, height(radarTable));
end

samples = complex(int16.empty(0, 0));

if isfield(sessionData, "RadarScans") && ...
        ~isempty(sessionData.RadarScans)
    manifestIndex = radarTable.ManifestIndex(radarTableRow);
    scanManifestIndices = [sessionData.RadarScans.ManifestIndex].';
    scanIndex = find(scanManifestIndices == manifestIndex, 1, "first");

    if ~isempty(scanIndex) && ...
            isfield(sessionData.RadarScans(scanIndex), "Samples")
        samples = sessionData.RadarScans(scanIndex).Samples;
    end
end

if isempty(samples)
    absoluteFilePath = fullfile(string(sessionData.DatasetRoot), ...
        strrep(radarTable.RelativePath(radarTableRow), "/", filesep));
    scan = helperScanBasebandCaptureFile(absoluteFilePath, true);
    samples = scan.Samples;
end

expectedSize = [ ...
    double(radarTable.NumSamples(radarTableRow)), ...
    double(radarTable.NumChannels(radarTableRow)) ...
    ];

if ~isequal(size(samples), expectedSize)
    error("helperResolveRadarSamples:UnexpectedSampleShape", ...
        "Expected [%d x %d] samples for repetition %d but found [%d x %d].", ...
        expectedSize(1), expectedSize(2), ...
        radarTable.Repetition(radarTableRow), size(samples, 1), ...
        size(samples, 2));
end

end
