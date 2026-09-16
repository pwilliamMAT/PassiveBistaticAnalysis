# Full References

## Project evidence

1. `runRealBackgroundSyntheticPipeline.m`, paired field-background synthetic
   runner and compact-result contract.
2. `private/helperPrepareG3SyncInputs.m`, G3 lag, residual-frequency, and
   coherence preparation.
3. `helperResampleG4FullRepetition.m`, complete-repetition resampling
   provenance.
4. `helperAnalyzeG5Mitigation.m`, normalized-LMS candidate implementation.
5. `helperFormG4ProductionMap.m`, passive-map power and orientation contract.
6. `helperAnalyzeG6ProductDiscrimination.m`, fixed CA-CFAR/NMS and post-hoc
   association implementation.
7. Accepted 45 km compact result:
   `field_background_demo_final_20260908/fieldBackgroundSyntheticPipelineResults.mat`.
8. Current 15 km baseline compact result:
   `field_background_close_target_support_probe_20260914T190224119Z/fieldBackgroundSyntheticPipelineResults.mat`.
9. `PROJECT_STATE.md`, “Field-background synthetic-target demonstration.”
10. `LessonsLearned.md`, LL-014, “Near Truth Was Excluded by the Frozen
    Detector Support.”

## MathWorks documentation

1. [`finddelay`](https://www.mathworks.com/help/signal/ref/finddelay.html)
2. [`xcorr`](https://www.mathworks.com/help/signal/ref/xcorr.html)
3. [`resample`](https://www.mathworks.com/help/signal/ref/resample.html)
4. [`dsp.LMSFilter`](https://www.mathworks.com/help/dsp/ref/dsp.lmsfilter-system-object.html)
5. [`ambgfun`](https://www.mathworks.com/help/phased/ref/ambgfun.html)
6. [`phased.CFARDetector2D`](https://www.mathworks.com/help/phased/ref/phased.cfardetector2d-system-object.html)
7. [`imdilate`](https://www.mathworks.com/help/images/ref/imdilate.html)
8. [`bwconncomp`](https://www.mathworks.com/help/images/ref/bwconncomp.html)
9. [`matchpairs`](https://www.mathworks.com/help/stats/matchpairs.html)
10. [`phased.WidebandFreeSpace`](https://www.mathworks.com/help/phased/ref/phased.widebandfreespace-system-object.html)
