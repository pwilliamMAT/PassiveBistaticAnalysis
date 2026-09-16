classdef extractDeepDive2CompactGeometryEvidenceTest < matlab.unittest.TestCase
    %EXTRACTDEEPDIVE2COMPACTGEOMETRYEVIDENCETEST Compact evidence tests.

    properties (SetAccess = private)
        Evidence
        OutputDirectory
    end

    methods (TestClassSetup)
        function extractEvidence(testCase)
            packageRoot = fileparts(fileparts(mfilename("fullpath")));
            projectRoot = fileparts(fileparts(packageRoot));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(packageRoot));

            testCase.OutputDirectory = string(tempname);
            mkdir(testCase.OutputDirectory);
            testCase.addTeardown(@() rmdir(testCase.OutputDirectory, "s"));
            testCase.Evidence = extractDeepDive2CompactGeometryEvidence( ...
                projectRoot, ...
                OutputDirectory=testCase.OutputDirectory);
        end
    end

    methods (Test)
        function testSourceHashesAndSharedGeometry(testCase)
            evidence = testCase.Evidence;

            testCase.verifyEqual(evidence.SchemaVersion, ...
                "deep_dive_2_compact_geometry_v1");
            testCase.verifyTrue(evidence.SharedTxRxGeometry);
            testCase.verifyEqual(string({evidence.Sources.Id}), ["S11", "S12"]);
            testCase.verifyEqual(evidence.Sources(1).Sha256, ...
                "d64ac4ef034f6278050b084e9ebbf73a386c91b6f997ff8afe04107ca1cd0dea");
            testCase.verifyEqual(evidence.Sources(2).Sha256, ...
                "ed77b873a08381b5291f30765697b65b9690f1bbbd6eb2420429fc2b2a563419");
        end

        function testReceiverLocalEnuGeometry(testCase)
            evidence = testCase.Evidence;
            scenarios = evidence.Scenarios;

            testCase.verifyEqual(evidence.Transmitter.East_km, 9.290, ...
                AbsTol=0.005);
            testCase.verifyEqual(evidence.Transmitter.North_km, 1.155, ...
                AbsTol=0.005);
            testCase.verifyEqual(scenarios(1).InitialWaypoint.East_km, 0.0, ...
                AbsTol=0.005);
            testCase.verifyEqual(scenarios(1).InitialWaypoint.North_km, 45.021, ...
                AbsTol=0.005);
            testCase.verifyEqual(scenarios(2).InitialWaypoint.East_km, 0.0, ...
                AbsTol=0.005);
            testCase.verifyEqual(scenarios(2).InitialWaypoint.North_km, 15.007, ...
                AbsTol=0.005);
            testCase.verifyTrue(evidence.PlanView.AltitudeOmitted);
        end

        function testDisplayCoordinatesAndSupportLogic(testCase)
            evidence = testCase.Evidence;
            scenarios = evidence.Scenarios;

            testCase.verifyGreaterThan(scenarios(1).PhysicalExcessDelay_us, 0.0);
            testCase.verifyGreaterThan(scenarios(2).PhysicalExcessDelay_us, 0.0);
            testCase.verifyEqual(scenarios(1).DisplayDelay_us, -269.5, ...
                AbsTol=0.1);
            testCase.verifyEqual(scenarios(1).DisplayDoppler_Hz, 591.9, ...
                AbsTol=0.1);
            testCase.verifyEqual(scenarios(2).DisplayDelay_us, -76.5, ...
                AbsTol=0.1);
            testCase.verifyEqual(scenarios(2).DisplayDoppler_Hz, 540.5, ...
                AbsTol=0.1);
            testCase.verifyTrue(scenarios(1).DetectorEligible);
            testCase.verifyFalse(scenarios(2).DetectorEligible);
            testCase.verifyEqual(evidence.DetectorSupport.Delay_us, ...
                [-1200.0, -150.0], AbsTol=0.0);
            testCase.verifyEqual(evidence.DetectorSupport.Doppler_Hz, ...
                [-750.0, 750.0], AbsTol=0.0);
        end

        function testWritesScalarJsonOnly(testCase)
            outputPath = fullfile(testCase.OutputDirectory, ...
                "compact_geometry.json");
            contents = fileread(outputPath);

            testCase.verifyTrue(isfile(outputPath));
            testCase.verifyNotEmpty(contents);
            testCase.verifyFalse(contains(lower(contents), "rawiq"));
            testCase.verifyFalse(contains(lower(contents), "fullmap"));
        end
    end
end
