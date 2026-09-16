# Source Register

All source paths are read-only evidence for this standalone instructional
package. The final composition reads no source bundle at render time; it reads
only the compact JSON generated from `results.Trajectory`.

| ID | Stage | Source | Evidence used by Deep Dive 2 |
| --- | --- | --- | --- |
| S1 | Paired producer and runner | `runRealBackgroundSyntheticPipeline.m` | Preserve reference/control, inject surveillance only, retain diagnostic claim boundary. |
| S2 | Echo conditioning | External `helperSyntheticBuildConditionedEchoSeed.m` | Conditioned echo-only seed and RMS matching. |
| S3 | Native-function audit | `runRealBackgroundSyntheticPipeline.m` | Echo synthesis and paired pipeline implementation context. |
| S4 | Synchronization | `private/helperPrepareG3SyncInputs.m` | Integer lag and residual cross-phase preparation. |
| S5 | Correction reuse | `helperAnalyzeG5Mitigation.m` | Unit-magnitude residual-frequency correction convention. |
| S6 | Resampling/CPI | `helperResampleG4FullRepetition.m` | Whole-repetition `resample` contract before CPI selection. |
| S7 | Mitigation candidate | `helperAnalyzeG5Mitigation.m` | `dsp.LMSFilter` residual candidate implementation. |
| S8 | CAF power map | `helperFormG4ProductionMap.m` | `ambgfun`, power conversion, and rows=Doppler/columns=delay orientation. |
| S9 | Candidate generation | `helperAnalyzeG6ProductDiscrimination.m` | Fixed support, CA-CFAR, 7×3 NMS, and truth-blind candidate sequence. |
| S10 | Association | `helperAnalyzeG6ProductDiscrimination.m` | Normalized delay/Doppler cost and post-hoc `matchpairs`. |
| S11 | 45 km scenario | `artifacts/20260622T102123/Field_Background_Synthetic_Demo/field_background_demo_final_20260908/fieldBackgroundSyntheticPipelineResults.mat` | SHA-256 `d64ac4ef034f6278050b084e9ebbf73a386c91b6f997ff8afe04107ca1cd0dea`; trajectory scalar source for the in-support marker. |
| S12 | 15 km scenario | `artifacts/20260622T102123/Field_Background_Synthetic_Demo/field_background_close_target_support_probe_20260914T190224119Z/fieldBackgroundSyntheticPipelineResults.mat` | SHA-256 `ed77b873a08381b5291f30765697b65b9690f1bbbd6eb2420429fc2b2a563419`; trajectory scalar source for the visible, outside-support marker. |

The MATLAB extractor verifies S11/S12 hashes, verifies common Tx/Rx geometry,
uses `geodetic2enu` with `wgs84Ellipsoid("meter")`, and writes only scalar
JSON fields for Tx, initial ENU scenario waypoints, representative display
markers, support, and limitations.
