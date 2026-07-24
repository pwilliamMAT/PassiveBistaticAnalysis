function snapshotPath = helperWriteComparisonSnapshot(bundleRoot, ...
    comparisonSnapshot)
%HELPERWRITECOMPARISONSNAPSHOT Write the normalized stage snapshot.

arguments
    bundleRoot (1,1) string
    comparisonSnapshot (1,1) struct
end

snapshotPath = fullfile(bundleRoot, "comparison_snapshot.mat");

try
    save(snapshotPath, "comparisonSnapshot");
catch saveException
    error("helperWriteComparisonSnapshot:SaveFailed", ...
        "Failed to write comparison snapshot %s: %s", ...
        snapshotPath, saveException.message);
end

end
