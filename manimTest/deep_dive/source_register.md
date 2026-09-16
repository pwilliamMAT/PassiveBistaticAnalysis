# Source Register

All repository paths below are read-only evidence for this educational
artifact. MathWorks links are the official native-function documentation
citations rendered in abbreviated form in the video.

| ID | Stage | Authoritative source | Exact evidence / code location | Citation |
| --- | --- | --- | --- | --- |
| S1 | Producer | `C:\Users\pwilliam\agenticProjects\flightTest_SynthDataBranch\SyntheticHDTVSimulation\generateRealBackgroundSyntheticSuite.m` | Producer preserves recorded reference and injects target echoes only in surveillance; Code Analyzer: no issues. | Local source; [WidebandFreeSpace](https://www.mathworks.com/help/phased/ref/phased.widebandfreespace-system-object.html) |
| S2 | Seed conditioning | `...\helperSyntheticBuildConditionedEchoSeed.m` | Lines 6–13 define a conditioned echo-only copy; lines 26 and 64–68 RMS-match it after optional line suppression. | Local source; [periodogram](https://www.mathworks.com/help/signal/ref/periodogram.html) |
| S3 | Paired runner | `runRealBackgroundSyntheticPipeline.m` | Lines 395–423 enforce reference/control preservation and finite nonzero injected surveillance; lines 779–793 record the native-function audit. Code Analyzer: no issues. | Local source |
| S4 | Synchronization | `private/helperPrepareG3SyncInputs.m` | Lines 361–365 call `finddelay` and normalized `xcorr`; lines 467–475 fit cross-phase slope. Code Analyzer: no issues. | [finddelay](https://www.mathworks.com/help/signal/ref/finddelay.html); [xcorr](https://www.mathworks.com/help/signal/ref/xcorr.html) |
| S5 | Residual phase correction | `helperAnalyzeG5Mitigation.m` | `localApplyResidualFrequencyCorrection` forms `exp(-1j*2*pi*f*n/Fs)`. | Local source |
| S6 | Resampling / CPI | `helperResampleG4FullRepetition.m` | Lines 27–53 call `resample`, record the returned FIR, and freeze complete-repetition filtering before CPI extraction. | [resample](https://www.mathworks.com/help/signal/ref/resample.html) |
| S7 | LMS candidate | `helperAnalyzeG5Mitigation.m` | Lines 245–251 define candidate profiles; lines 1079–1095 call `dsp.LMSFilter` and retain residual error. Code Analyzer: no issues. | [dsp.LMSFilter](https://www.mathworks.com/help/dsp/ref/dsp.lmsfilter-system-object.html) |
| S8 | CAF / map power | `helperFormG4ProductionMap.m` | Lines 39–67 call `ambgfun`, square magnitude, and freeze rows=Doppler/columns=delay. | [ambgfun](https://www.mathworks.com/help/phased/ref/ambgfun.html) |
| S9 | Detector | `helperAnalyzeG6ProductDiscrimination.m` | Lines 611–635 obtain CA-CFAR noise; lines 639–680 apply 7×3 NMS and deterministic plateau handling. Code Analyzer: no issues. | [phased.CFARDetector2D](https://www.mathworks.com/help/phased/ref/phased.cfardetector2d-system-object.html); [imdilate](https://www.mathworks.com/help/images/ref/imdilate.html); [bwconncomp](https://www.mathworks.com/help/images/ref/bwconncomp.html) |
| S10 | Association | `helperAnalyzeG6ProductDiscrimination.m` | Lines 850–910 normalize delay/Doppler errors and call `matchpairs` after detection generation. | [matchpairs](https://www.mathworks.com/help/stats/matchpairs.html) |
| S11 | 45 km outcome | `artifacts/20260622T102123/Field_Background_Synthetic_Demo/field_background_demo_final_20260908/fieldBackgroundSyntheticPipelineResults.mat` | SHA-256 `d64ac4ef034f6278050b084e9ebbf73a386c91b6f997ff8afe04107ca1cd0dea`; accepted criterion-passed compact result. | [PROJECT_STATE.md](../../PROJECT_STATE.md) |
| S12 | 15 km baseline | `artifacts/20260622T102123/Field_Background_Synthetic_Demo/field_background_close_target_support_probe_20260914T190224119Z/fieldBackgroundSyntheticPipelineResults.mat` | SHA-256 `ed77b873a08381b5291f30765697b65b9690f1bbbd6eb2420429fc2b2a563419`; baseline is `not_evaluated_outside_detector_support`. | [PROJECT_STATE.md](../../PROJECT_STATE.md); [LessonsLearned.md](../../LessonsLearned.md#ll-014--2026-09-14--near-truth-was-excluded-by-the-frozen-detector-support) |

The 15 km support-only replay result is intentionally not used as a final
applied example. It is outside the video’s frozen-detector teaching boundary.
