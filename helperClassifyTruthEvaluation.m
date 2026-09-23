function [status, detail] = helperClassifyTruthEvaluation( ...
    truthWithinPhysicsMap, truthWithinDetectorSupport, truthMatched)
%HELPERCLASSIFYTRUTHEVALUATION Classify whether detector truth was evaluated.
%
%   [STATUS, DETAIL] = HELPERCLASSIFYTRUTHEVALUATION(INMAP, INSUPPORT,
%   MATCHED) distinguishes an invalid map placement, a truth location the
%   fixed detector never evaluated, and eligible detection outcomes.

arguments
    truthWithinPhysicsMap (1,1) logical
    truthWithinDetectorSupport (1,1) logical
    truthMatched (1,1) logical
end

if ~truthWithinPhysicsMap
    status = "outside_physics_map_invalid";
    detail = "Generator truth is outside the full-map placement region.";
elseif ~truthWithinDetectorSupport
    status = "outside_detector_support_not_evaluated";
    detail = "Truth is in the full map but outside fixed CFAR/NMS support.";
elseif truthMatched
    status = "eligible_and_detected";
    detail = "Truth was eligible for CFAR/NMS and matched post hoc.";
else
    status = "eligible_not_detected";
    detail = "Truth was eligible for CFAR/NMS but had no post-hoc match.";
end

end
