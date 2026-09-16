"""Create a small, auditable data package for the isolated ManimGL video.

This script is intentionally a read-only consumer of the two saved compact
MATLAB result bundles.  It never starts MATLAB, loads raw IQ, retains a full
ambiguity map, or recomputes the processing pipeline.

MATLAB string scalars in these legacy MAT files are saved as MCOS objects that
``scipy.io.loadmat`` exposes as opaque objects.  The extractor therefore
verifies their outcome *semantics* through the explicit saved boolean fields
that produced those labels, rather than fabricating a string decoder.  Numeric
configuration, compact map views, trajectories, retention audit, and source
hashes are loaded directly through SciPy.
"""

from __future__ import annotations

import csv
import hashlib
import json
import math
import platform
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

import numpy as np
import scipy
from scipy.io import loadmat


TRIAL_ROOT = Path(__file__).resolve().parent
REPOSITORY_ROOT = TRIAL_ROOT.parent
PACKAGE_ROOT = TRIAL_ROOT / "data" / "manim_video_data_v1"
PACKAGE_SCHEMA = "manim_video_data_v1"
FIXED_CANDIDATES = ("none", "conservative_lms", "aggressive_lms")
CASE_ORDER = ("field_only_control", "field_plus_geo_target")
FORBIDDEN_FIELD_NAMES = {
    "samples",
    "radarscans",
    "rawiq",
    "maplinear",
    "fullmap",
    "fullmapcollection",
}


class ContractError(RuntimeError):
    """Raised when a saved bundle does not satisfy this trial's data contract."""


@dataclass(frozen=True)
class SourceSpec:
    label: str
    relative_path: Path
    north_offset_m: float
    expected_outcome: str

    @property
    def absolute_path(self) -> Path:
        return REPOSITORY_ROOT / self.relative_path


SOURCES = (
    SourceSpec(
        label="45km_positive_control",
        relative_path=Path(
            "artifacts/20260622T102123/Field_Background_Synthetic_Demo/"
            "field_background_demo_final_20260908/"
            "fieldBackgroundSyntheticPipelineResults.mat"
        ),
        north_offset_m=45_000.0,
        expected_outcome="criterion_passed",
    ),
    SourceSpec(
        label="15km_detector_ineligible",
        relative_path=Path(
            "artifacts/20260622T102123/Field_Background_Synthetic_Demo/"
            "field_background_explained_20260914T153126038/"
            "fieldBackgroundSyntheticPipelineResults.mat"
        ),
        north_offset_m=15_000.0,
        expected_outcome="outside_detector_support_not_evaluated",
    ),
)


def _require_mapping(value: Any, path: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ContractError(f"{path} must be a MATLAB struct decoded as a mapping.")
    return value


def _require_fields(mapping: dict[str, Any], names: Iterable[str], path: str) -> None:
    missing = [name for name in names if name not in mapping]
    if missing:
        raise ContractError(f"{path} is missing required field(s): {', '.join(missing)}.")


def _scalar(value: Any, path: str) -> Any:
    if isinstance(value, np.ndarray):
        if value.size != 1:
            raise ContractError(f"{path} must be scalar; found shape {value.shape}.")
        return value.reshape(-1)[0].item()
    if isinstance(value, np.generic):
        return value.item()
    return value


def _as_float(value: Any, path: str) -> float:
    scalar = _scalar(value, path)
    if isinstance(scalar, (bool, np.bool_)):
        return float(scalar)
    if not isinstance(scalar, (int, float, np.number)):
        raise ContractError(f"{path} must be numeric.")
    result = float(scalar)
    if not math.isfinite(result):
        raise ContractError(f"{path} must be finite.")
    return result


def _as_bool(value: Any, path: str) -> bool:
    scalar = _scalar(value, path)
    if isinstance(scalar, (bool, np.bool_, int, np.integer, float, np.floating)):
        return bool(scalar)
    raise ContractError(f"{path} must be logical or numeric scalar.")


def _as_vector(value: Any, path: str) -> np.ndarray:
    vector = np.asarray(value, dtype=float).reshape(-1)
    if vector.size == 0 or not np.all(np.isfinite(vector)):
        raise ContractError(f"{path} must be a nonempty finite numeric vector.")
    return vector


def _as_matrix(value: Any, path: str) -> np.ndarray:
    matrix = np.asarray(value, dtype=float)
    if matrix.ndim != 2 or matrix.size == 0 or not np.all(np.isfinite(matrix)):
        raise ContractError(f"{path} must be a nonempty finite numeric matrix.")
    return matrix


def _close(actual: float, expected: float, path: str, atol: float = 1e-12) -> None:
    if not math.isclose(actual, expected, rel_tol=0.0, abs_tol=atol):
        raise ContractError(f"{path}={actual!r}; expected {expected!r}.")


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source_file:
        for block in iter(lambda: source_file.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _load_result(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise ContractError(f"Required source MAT file is missing: {path}")
    try:
        loaded = loadmat(path, simplify_cells=True)
    except Exception as error:  # SciPy produces several parser-specific types.
        raise ContractError(f"SciPy could not read {path.name}: {error}") from error
    if "results" not in loaded:
        raise ContractError(f"{path.name} does not contain the expected 'results' struct.")
    return _require_mapping(loaded["results"], f"{path.name}.results")


def _walk_field_names(value: Any, path: str = "results") -> list[str]:
    """Return forbidden field paths visible to SciPy without inspecting arrays."""

    found: list[str] = []
    if isinstance(value, dict):
        for name, child in value.items():
            child_path = f"{path}.{name}"
            if name.lower() in FORBIDDEN_FIELD_NAMES:
                found.append(child_path)
            found.extend(_walk_field_names(child, child_path))
    elif isinstance(value, (list, tuple)):
        for index, child in enumerate(value):
            found.extend(_walk_field_names(child, f"{path}[{index}]"))
    return found


def _validate_claim_boundary(results: dict[str, Any], path: str) -> None:
    boundary = _require_mapping(results["ClaimBoundary"], f"{path}.ClaimBoundary")
    _require_fields(
        boundary,
        (
            "DiagnosticIntegrationOnly",
            "FieldDetectionClaimed",
            "TrackingClaimed",
            "FormalG4RStateChanged",
            "FormalG6OrG8Enabled",
            "TruthUse",
        ),
        f"{path}.ClaimBoundary",
    )
    if not _as_bool(boundary["DiagnosticIntegrationOnly"], "ClaimBoundary.DiagnosticIntegrationOnly"):
        raise ContractError("The bundle is not marked diagnostic-only.")
    for field in (
        "FieldDetectionClaimed",
        "TrackingClaimed",
        "FormalG4RStateChanged",
        "FormalG6OrG8Enabled",
    ):
        if _as_bool(boundary[field], f"ClaimBoundary.{field}"):
            raise ContractError(f"Claim boundary unexpectedly enables {field}.")


def _validate_compact_audit(results: dict[str, Any], path: str) -> None:
    audit = _require_mapping(results["CompactResultAudit"], f"{path}.CompactResultAudit")
    _require_fields(
        audit,
        (
            "Compact",
            "RawIqPresent",
            "FullMapCollectionPresent",
            "LargestNumericElementCount",
        ),
        f"{path}.CompactResultAudit",
    )
    if not _as_bool(audit["Compact"], "CompactResultAudit.Compact"):
        raise ContractError("Saved result does not pass its own compact-retention audit.")
    if _as_bool(audit["RawIqPresent"], "CompactResultAudit.RawIqPresent"):
        raise ContractError("Saved result reports raw IQ.")
    if _as_bool(audit["FullMapCollectionPresent"], "CompactResultAudit.FullMapCollectionPresent"):
        raise ContractError("Saved result reports a complete map collection.")
    if _as_float(audit["LargestNumericElementCount"], "CompactResultAudit.LargestNumericElementCount") > 401 * 32:
        raise ContractError("Saved result exceeds the compact 401×32 numeric-view limit.")
    forbidden_paths = _walk_field_names(results)
    if forbidden_paths:
        raise ContractError(
            "Visible prohibited retained field(s): " + ", ".join(forbidden_paths)
        )


def _validate_configuration(results: dict[str, Any], spec: SourceSpec) -> dict[str, Any]:
    configuration = _require_mapping(results["Configuration"], "results.Configuration")
    _require_fields(
        configuration,
        (
            "CpiDurationS",
            "TrajectoryNorthOffsetM",
            "TrajectorySpeedMps",
            "PfaToHighlight",
            "EchoGainDB",
            "MapDecimationFactor",
        ),
        "results.Configuration",
    )
    _close(_as_float(configuration["CpiDurationS"], "Configuration.CpiDurationS"), 0.1, "Configuration.CpiDurationS")
    _close(
        _as_float(configuration["TrajectoryNorthOffsetM"], "Configuration.TrajectoryNorthOffsetM"),
        spec.north_offset_m,
        "Configuration.TrajectoryNorthOffsetM",
        atol=1e-9,
    )
    _close(_as_float(configuration["TrajectorySpeedMps"], "Configuration.TrajectorySpeedMps"), 150.0, "Configuration.TrajectorySpeedMps")
    _close(_as_float(configuration["PfaToHighlight"], "Configuration.PfaToHighlight"), 1e-3, "Configuration.PfaToHighlight")
    _close(_as_float(configuration["EchoGainDB"], "Configuration.EchoGainDB"), -18.0, "Configuration.EchoGainDB")
    _close(_as_float(configuration["MapDecimationFactor"], "Configuration.MapDecimationFactor"), 200.0, "Configuration.MapDecimationFactor")
    return configuration


def _validate_detector_configuration(results: dict[str, Any]) -> dict[str, Any]:
    g6d = _require_mapping(results["G6D"], "results.G6D")
    configuration = _require_mapping(g6d["Configuration"], "results.G6D.Configuration")
    _require_fields(
        configuration,
        (
            "CutDelayLimits_s",
            "CutDopplerLimits_Hz",
            "ExpectedCutCount",
            "GuardBandSize",
            "TrainingBandSize",
            "TrainingCellCount",
            "Pfa",
            "NmsNeighborhood",
            "DetectionGenerationTruthBlind",
        ),
        "results.G6D.Configuration",
    )
    expected_vectors = {
        "CutDelayLimits_s": np.array([-1.2e-3, -0.15e-3]),
        "CutDopplerLimits_Hz": np.array([-750.0, 750.0]),
        "GuardBandSize": np.array([3.0, 1.0]),
        "TrainingBandSize": np.array([12.0, 4.0]),
        "NmsNeighborhood": np.array([7.0, 3.0]),
        "Pfa": np.array([1e-2, 3e-3, 1e-3, 3e-4, 1e-4, 3e-5, 1e-5, 3e-6, 1e-6]),
    }
    for field, expected in expected_vectors.items():
        actual = _as_vector(configuration[field], f"G6D.Configuration.{field}")
        if actual.shape != expected.shape or not np.allclose(actual, expected, rtol=0.0, atol=1e-12):
            raise ContractError(f"G6D.Configuration.{field} does not match the frozen detector contract.")
    _close(_as_float(configuration["ExpectedCutCount"], "G6D.Configuration.ExpectedCutCount"), 12832.0, "G6D.Configuration.ExpectedCutCount")
    _close(_as_float(configuration["TrainingCellCount"], "G6D.Configuration.TrainingCellCount"), 320.0, "G6D.Configuration.TrainingCellCount")
    if not _as_bool(configuration["DetectionGenerationTruthBlind"], "G6D.Configuration.DetectionGenerationTruthBlind"):
        raise ContractError("Saved detector configuration is not truth-blind.")
    return configuration


def _semantic_outcome(results: dict[str, Any], spec: SourceSpec) -> dict[str, Any]:
    """Validate the saved boolean predicate behind the expected outcome label."""

    verification = _require_mapping(results["Verification"], "results.Verification")
    _require_fields(
        verification,
        (
            "MapPlacementAgreesWithGeneratorTruth",
            "G3DerivedOnceFromControl",
            "G3CorrectionReusedExactly",
            "G6DIntegrityPassed",
            "G6DCellGeometryExact",
            "DetectionGeneratedBeforeTruthAssociation",
            "HighlightPfa",
            "ConservativeInjectedTargetMatch",
            "ConservativeControlNuisanceMatch",
            "FinalDetectionCriterionPassed",
            "NoRetuningPerformed",
            "AllStructuralChecksPassed",
        ),
        "results.Verification",
    )
    for field in (
        "MapPlacementAgreesWithGeneratorTruth",
        "G3DerivedOnceFromControl",
        "G3CorrectionReusedExactly",
        "G6DIntegrityPassed",
        "G6DCellGeometryExact",
        "DetectionGeneratedBeforeTruthAssociation",
        "NoRetuningPerformed",
        "AllStructuralChecksPassed",
    ):
        if not _as_bool(verification[field], f"Verification.{field}"):
            raise ContractError(f"Expected structural check failed: Verification.{field}.")
    _close(_as_float(verification["HighlightPfa"], "Verification.HighlightPfa"), 1e-3, "Verification.HighlightPfa")

    if spec.expected_outcome == "criterion_passed":
        required_true = (
            "TruthWithinMapAndDetectorSupport",
            "ConservativeInjectedTargetMatch",
            "FinalDetectionCriterionPassed",
        )
        for field in required_true:
            if field not in verification or not _as_bool(verification[field], f"Verification.{field}"):
                raise ContractError(f"45 km semantic outcome mismatch: {field} must be true.")
        if _as_bool(verification["ConservativeControlNuisanceMatch"], "Verification.ConservativeControlNuisanceMatch"):
            raise ContractError("45 km semantic outcome mismatch: matched-control nuisance is present.")
        return {
            "evaluation_status": "eligible_and_detected",
            "conclusion_outcome": "criterion_passed",
            "detector_evaluated": True,
            "injected_truth_matched_post_hoc": True,
            "matched_control_nuisance_match": False,
        }

    required_false = (
        "TruthWithinDetectorSupport",
        "TruthWithinMapAndDetectorSupport",
        "FinalDetectionCriterionEvaluated",
        "FinalDetectionCriterionPassed",
        "ConservativeInjectedTargetMatch",
    )
    if "TruthWithinPhysicsMap" not in verification or not _as_bool(
        verification["TruthWithinPhysicsMap"], "Verification.TruthWithinPhysicsMap"
    ):
        raise ContractError("15 km semantic outcome mismatch: truth is not in the physics map.")
    for field in required_false:
        if field not in verification:
            raise ContractError(f"15 km semantic outcome is missing {field}.")
        if _as_bool(verification[field], f"Verification.{field}"):
            raise ContractError(f"15 km semantic outcome mismatch: {field} must be false.")
    return {
        "evaluation_status": "outside_detector_support_not_evaluated",
        "conclusion_outcome": "not_evaluated_outside_detector_support",
        "detector_evaluated": False,
        "injected_truth_matched_post_hoc": False,
        "matched_control_nuisance_match": False,
    }


def _validate_g3(results: dict[str, Any]) -> dict[str, float]:
    g3 = _require_mapping(results["G3"], "results.G3")
    correction = _require_mapping(g3["Correction"], "results.G3.Correction")
    _require_fields(
        correction,
        (
            "AppliedLag_samples",
            "AppliedResidualFrequency_Hz",
            "LagResidualMax_samples",
            "ResidualFrequencySpread_Hz",
            "WindowCount",
        ),
        "results.G3.Correction",
    )
    return {
        "applied_lag_samples": _as_float(correction["AppliedLag_samples"], "G3.Correction.AppliedLag_samples"),
        "applied_residual_frequency_hz": _as_float(
            correction["AppliedResidualFrequency_Hz"],
            "G3.Correction.AppliedResidualFrequency_Hz",
        ),
        "lag_residual_max_samples": _as_float(
            correction["LagResidualMax_samples"],
            "G3.Correction.LagResidualMax_samples",
        ),
        "residual_frequency_spread_hz": _as_float(
            correction["ResidualFrequencySpread_Hz"],
            "G3.Correction.ResidualFrequencySpread_Hz",
        ),
        "window_count": _as_float(correction["WindowCount"], "G3.Correction.WindowCount"),
    }


def _validate_trajectory(results: dict[str, Any]) -> dict[str, np.ndarray]:
    trajectory = _require_mapping(results["Trajectory"], "results.Trajectory")
    _require_fields(
        trajectory,
        (
            "WaypointsLla_deg_m",
            "TimeOfArrival_s",
            "TruthTime_s",
            "ExcessDelay_s",
            "BistaticDoppler_Hz",
            "TxLla_deg_m",
            "RxLla_deg_m",
        ),
        "results.Trajectory",
    )
    waypoints = _as_matrix(trajectory["WaypointsLla_deg_m"], "Trajectory.WaypointsLla_deg_m")
    if waypoints.shape != (3, 3):
        raise ContractError(f"Trajectory.WaypointsLla_deg_m must be 3×3; found {waypoints.shape}.")
    waypoint_times = _as_vector(trajectory["TimeOfArrival_s"], "Trajectory.TimeOfArrival_s")
    truth_time = _as_vector(trajectory["TruthTime_s"], "Trajectory.TruthTime_s")
    delay_s = _as_vector(trajectory["ExcessDelay_s"], "Trajectory.ExcessDelay_s")
    doppler_hz = _as_vector(trajectory["BistaticDoppler_Hz"], "Trajectory.BistaticDoppler_Hz")
    if waypoint_times.size != 3 or truth_time.size != delay_s.size or truth_time.size != doppler_hz.size:
        raise ContractError("Trajectory arrays do not share their expected lengths.")
    if not np.all(np.diff(waypoint_times) > 0) or not np.all(np.diff(truth_time) >= 0):
        raise ContractError("Trajectory time axes must be nondecreasing.")
    tx = _as_vector(trajectory["TxLla_deg_m"], "Trajectory.TxLla_deg_m")
    rx = _as_vector(trajectory["RxLla_deg_m"], "Trajectory.RxLla_deg_m")
    if tx.size != 3 or rx.size != 3:
        raise ContractError("Transmitter and receiver coordinates must be latitude/longitude/altitude triples.")
    return {
        "waypoints": waypoints,
        "waypoint_times": waypoint_times,
        "truth_time": truth_time,
        "excess_delay_s": delay_s,
        "bistatic_doppler_hz": doppler_hz,
        "tx_lla": tx,
        "rx_lla": rx,
    }


def _as_view_list(value: Any, path: str) -> list[dict[str, Any]]:
    if not isinstance(value, list) or not value:
        raise ContractError(f"{path} must be a nonempty MATLAB struct array decoded as a list.")
    views = [_require_mapping(item, f"{path}[{index}]") for index, item in enumerate(value)]
    return views


def _extract_views(
    views: list[dict[str, Any]],
    path: str,
    power_field: str,
    expected_field_names: tuple[str, ...],
) -> list[dict[str, Any]]:
    if len(views) != len(CASE_ORDER) * len(FIXED_CANDIDATES):
        raise ContractError(f"{path} must contain six compact views; found {len(views)}.")
    extracted: list[dict[str, Any]] = []
    for index, view in enumerate(views):
        _require_fields(view, expected_field_names, f"{path}[{index}]")
        power = _as_matrix(view[power_field], f"{path}[{index}].{power_field}")
        delay_s = _as_vector(view["DelayAxis_s"], f"{path}[{index}].DelayAxis_s")
        doppler_hz = _as_vector(view["DopplerAxis_Hz"], f"{path}[{index}].DopplerAxis_Hz")
        if power.shape != (doppler_hz.size, delay_s.size):
            raise ContractError(f"{path}[{index}] power dimensions do not match its axes.")
        if power.shape != (401, 32):
            raise ContractError(f"{path}[{index}] must retain only a 401×32 compact view.")
        if not np.all(np.diff(delay_s) > 0) or not np.all(np.diff(doppler_hz) > 0):
            raise ContractError(f"{path}[{index}] axes must be strictly increasing.")
        if not np.all(np.isfinite(power)):
            raise ContractError(f"{path}[{index}] power is not finite.")
        case_id = CASE_ORDER[index // len(FIXED_CANDIDATES)]
        candidate_name = FIXED_CANDIDATES[index % len(FIXED_CANDIDATES)]
        item = {
            "case_id": case_id,
            "candidate_name": candidate_name,
            "power_db": power.astype(np.float32),
            "delay_s": delay_s,
            "doppler_hz": doppler_hz,
        }
        if "ExpectedDelay_s" in view:
            expected_delay = _as_vector(view["ExpectedDelay_s"], f"{path}[{index}].ExpectedDelay_s")
            expected_doppler = _as_vector(view["ExpectedDoppler_Hz"], f"{path}[{index}].ExpectedDoppler_Hz")
            if not np.all((expected_delay >= delay_s.min()) & (expected_delay <= delay_s.max())):
                raise ContractError(f"{path}[{index}] expected delay is not in the saved compact view.")
            if not np.all((expected_doppler >= doppler_hz.min()) & (expected_doppler <= doppler_hz.max())):
                raise ContractError(f"{path}[{index}] expected Doppler is not in the saved compact view.")
            if not _as_bool(view["TargetWithinView"], f"{path}[{index}].TargetWithinView"):
                raise ContractError(f"{path}[{index}] does not retain the target in its compact view.")
            item["expected_delay_s"] = expected_delay
            item["expected_doppler_hz"] = expected_doppler
        extracted.append(item)
    return extracted


def validate_source_bundle(spec: SourceSpec) -> dict[str, Any]:
    """Load and validate one source bundle without writing any files."""

    results = _load_result(spec.absolute_path)
    _require_fields(
        results,
        (
            "SchemaVersion",
            "ClaimBoundary",
            "Configuration",
            "Trajectory",
            "G3",
            "G6D",
            "DetectionRegionViews",
            "Verification",
            "Conclusion",
            "CompactResultAudit",
        ),
        f"{spec.absolute_path.name}.results",
    )
    _validate_claim_boundary(results, spec.absolute_path.name)
    _validate_compact_audit(results, spec.absolute_path.name)
    configuration = _validate_configuration(results, spec)
    detector = _validate_detector_configuration(results)
    outcome = _semantic_outcome(results, spec)
    trajectory = _validate_trajectory(results)
    g3 = _validate_g3(results)
    detector_views = _extract_views(
        _as_view_list(results["DetectionRegionViews"], "results.DetectionRegionViews"),
        "results.DetectionRegionViews",
        "DetectionRegionPower_dB",
        ("CaseId", "CandidateName", "DetectionRegionPower_dB", "DelayAxis_s", "DopplerAxis_Hz"),
    )
    target_views: list[dict[str, Any]] = []
    if "TargetCenteredViews" in results:
        target_views = _extract_views(
            _as_view_list(results["TargetCenteredViews"], "results.TargetCenteredViews"),
            "results.TargetCenteredViews",
            "TargetRegionPower_dB",
            (
                "CaseId",
                "CandidateName",
                "ViewRole",
                "TargetRegionPower_dB",
                "DelayAxis_s",
                "DopplerAxis_Hz",
                "ExpectedDelay_s",
                "ExpectedDoppler_Hz",
                "TargetWithinView",
            ),
        )
    return {
        "spec": spec,
        "results": results,
        "configuration": configuration,
        "detector": detector,
        "outcome": outcome,
        "trajectory": trajectory,
        "g3": g3,
        "detector_views": detector_views,
        "target_views": target_views,
        "source_sha256": _sha256(spec.absolute_path),
        "source_size_bytes": spec.absolute_path.stat().st_size,
    }


def validate_all_sources() -> list[dict[str, Any]]:
    """Validate both compact source bundles and return normalized records."""

    bundles = [validate_source_bundle(spec) for spec in SOURCES]
    reference_detector = bundles[0]["detector"]
    reference_g3 = bundles[0]["g3"]
    for bundle in bundles[1:]:
        for field in (
            "CutDelayLimits_s",
            "CutDopplerLimits_Hz",
            "Pfa",
            "GuardBandSize",
            "TrainingBandSize",
            "NmsNeighborhood",
        ):
            if not np.array_equal(
                np.asarray(bundle["detector"][field]),
                np.asarray(reference_detector[field]),
            ):
                raise ContractError(f"Detector configuration differs between source bundles: {field}.")
        for field in reference_g3:
            if not math.isclose(bundle["g3"][field], reference_g3[field], rel_tol=0.0, abs_tol=1e-12):
                raise ContractError(f"Saved G3 correction differs between paired bundles: {field}.")
    return bundles


def _write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def _local_enu_from_lla(
    lla_deg_m: np.ndarray,
    reference_lla_deg_m: np.ndarray,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Use a small-area equirectangular projection for the diagram only."""

    latitude_scale = 111_132.0
    longitude_scale = 111_320.0 * math.cos(math.radians(float(reference_lla_deg_m[0])))
    east_m = (lla_deg_m[:, 1] - reference_lla_deg_m[1]) * longitude_scale
    north_m = (lla_deg_m[:, 0] - reference_lla_deg_m[0]) * latitude_scale
    up_m = lla_deg_m[:, 2] - reference_lla_deg_m[2]
    return east_m, north_m, up_m


def _write_trajectory_csv(path: Path, bundle: dict[str, Any]) -> dict[str, float]:
    trajectory = bundle["trajectory"]
    truth_time = trajectory["truth_time"]
    waypoint_times = trajectory["waypoint_times"]
    east_waypoints, north_waypoints, up_waypoints = _local_enu_from_lla(
        trajectory["waypoints"],
        trajectory["rx_lla"],
    )
    east = np.interp(truth_time, waypoint_times, east_waypoints)
    north = np.interp(truth_time, waypoint_times, north_waypoints)
    up = np.interp(truth_time, waypoint_times, up_waypoints)
    rows = [
        {
            "time_s": float(truth_time[index]),
            "east_m": float(east[index]),
            "north_m": float(north[index]),
            "up_m": float(up[index]),
            "excess_delay_us": float(trajectory["excess_delay_s"][index] * 1e6),
            "bistatic_doppler_hz": float(trajectory["bistatic_doppler_hz"][index]),
            "display_delay_us": float(-trajectory["excess_delay_s"][index] * 1e6),
            "display_doppler_hz": float(-trajectory["bistatic_doppler_hz"][index]),
        }
        for index in range(truth_time.size)
    ]
    _write_csv(
        path,
        rows,
        [
            "time_s",
            "east_m",
            "north_m",
            "up_m",
            "excess_delay_us",
            "bistatic_doppler_hz",
            "display_delay_us",
            "display_doppler_hz",
        ],
    )
    return {
        "median_excess_delay_us": float(np.median(trajectory["excess_delay_s"]) * 1e6),
        "median_bistatic_doppler_hz": float(np.median(trajectory["bistatic_doppler_hz"])),
        "median_display_delay_us": float(-np.median(trajectory["excess_delay_s"]) * 1e6),
        "median_display_doppler_hz": float(-np.median(trajectory["bistatic_doppler_hz"])),
    }


def _write_view_package(
    package_root: Path,
    scenario_label: str,
    view_kind: str,
    views: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for view in views:
        filename = f"{scenario_label}_{view_kind}_{view['case_id']}_{view['candidate_name']}.npz"
        output_path = package_root / filename
        arrays: dict[str, np.ndarray] = {
            "power_db": view["power_db"],
            "delay_s": view["delay_s"],
            "doppler_hz": view["doppler_hz"],
        }
        if "expected_delay_s" in view:
            arrays["expected_delay_s"] = view["expected_delay_s"]
            arrays["expected_doppler_hz"] = view["expected_doppler_hz"]
        np.savez_compressed(output_path, **arrays)
        records.append(
            {
                "scenario": scenario_label,
                "view_kind": view_kind,
                "case_id": view["case_id"],
                "candidate_name": view["candidate_name"],
                "file": filename,
                "power_shape": list(view["power_db"].shape),
                "delay_spacing_us": float(np.median(np.diff(view["delay_s"])) * 1e6),
                "doppler_spacing_hz": float(np.median(np.diff(view["doppler_hz"]))),
                "contains_expected_truth": "expected_delay_s" in view,
            }
        )
    return records


def extract_package() -> Path:
    """Validate sources and write the local, compact Manim data package."""

    bundles = validate_all_sources()
    PACKAGE_ROOT.mkdir(parents=True, exist_ok=True)
    trajectory_rows: list[dict[str, Any]] = []
    view_records: list[dict[str, Any]] = []
    truth_rows: list[dict[str, Any]] = []
    g3_rows: list[dict[str, Any]] = []
    source_records: list[dict[str, Any]] = []

    for bundle in bundles:
        spec: SourceSpec = bundle["spec"]
        trajectory_file = f"trajectory_{spec.label}.csv"
        trajectory_summary = _write_trajectory_csv(PACKAGE_ROOT / trajectory_file, bundle)
        trajectory_rows.append(
            {
                "scenario": spec.label,
                "file": trajectory_file,
                **trajectory_summary,
            }
        )
        view_records.extend(
            _write_view_package(
                PACKAGE_ROOT,
                spec.label,
                "detector_region",
                bundle["detector_views"],
            )
        )
        if bundle["target_views"]:
            view_records.extend(
                _write_view_package(
                    PACKAGE_ROOT,
                    spec.label,
                    "target_centered",
                    bundle["target_views"],
                )
            )
        outcome = bundle["outcome"]
        truth_rows.append(
            {
                "scenario": spec.label,
                "target_offset_km": spec.north_offset_m / 1000.0,
                "evaluation_status": outcome["evaluation_status"],
                "conclusion_outcome": outcome["conclusion_outcome"],
                "detector_evaluated": outcome["detector_evaluated"],
                "injected_truth_matched_post_hoc": outcome["injected_truth_matched_post_hoc"],
                "matched_control_nuisance_match": outcome["matched_control_nuisance_match"],
                "pfa_design_input": 1e-3,
            }
        )
        g3_rows.append(
            {
                "scenario": spec.label,
                "derived_from": "field_only_control",
                "reused_for": "field_plus_geo_target",
                **bundle["g3"],
            }
        )
        source_records.append(
            {
                "label": spec.label,
                "relative_path": spec.relative_path.as_posix(),
                "sha256": bundle["source_sha256"],
                "size_bytes": bundle["source_size_bytes"],
                "expected_outcome": spec.expected_outcome,
            }
        )

    _write_csv(
        PACKAGE_ROOT / "truth_evaluation.csv",
        truth_rows,
        [
            "scenario",
            "target_offset_km",
            "evaluation_status",
            "conclusion_outcome",
            "detector_evaluated",
            "injected_truth_matched_post_hoc",
            "matched_control_nuisance_match",
            "pfa_design_input",
        ],
    )
    _write_csv(
        PACKAGE_ROOT / "g3_reuse.csv",
        g3_rows,
        [
            "scenario",
            "derived_from",
            "reused_for",
            "applied_lag_samples",
            "applied_residual_frequency_hz",
            "lag_residual_max_samples",
            "residual_frequency_spread_hz",
            "window_count",
        ],
    )
    detector = bundles[0]["detector"]
    detector_geometry = {
        "cut_delay_limits_us": (np.asarray(detector["CutDelayLimits_s"]) * 1e6).tolist(),
        "cut_doppler_limits_hz": np.asarray(detector["CutDopplerLimits_Hz"]).tolist(),
        "actual_cut_count": int(_as_float(detector["ExpectedCutCount"], "ExpectedCutCount")),
        "guard_band_size_rows_doppler_columns_delay": np.asarray(detector["GuardBandSize"]).astype(int).tolist(),
        "training_band_size_rows_doppler_columns_delay": np.asarray(detector["TrainingBandSize"]).astype(int).tolist(),
        "training_cell_count": int(_as_float(detector["TrainingCellCount"], "TrainingCellCount")),
        "pfa_design_inputs": np.asarray(detector["Pfa"]).tolist(),
        "nms_neighborhood_rows_doppler_columns_delay": np.asarray(detector["NmsNeighborhood"]).astype(int).tolist(),
        "axis_orientation": "rows_doppler_columns_delay",
        "detection_generation_truth_blind": True,
    }
    (PACKAGE_ROOT / "detector_geometry.json").write_text(
        json.dumps(detector_geometry, indent=2) + "\n",
        encoding="utf-8",
    )
    metadata = {
        "schema_version": PACKAGE_SCHEMA,
        "purpose": (
            "Read-only derived compact visualization data for the isolated "
            "ManimGL trial; not a detector or tracker result."
        ),
        "source_bundles": source_records,
        "trajectory_files": trajectory_rows,
        "view_records": view_records,
        "fixed_candidate_order": list(FIXED_CANDIDATES),
        "fixed_case_order": list(CASE_ORDER),
        "detector_geometry_file": "detector_geometry.json",
        "truth_evaluation_file": "truth_evaluation.csv",
        "g3_reuse_file": "g3_reuse.csv",
        "cpi_duration_s": 0.1,
        "nominal_cpi_doppler_scale_hz": 10.0,
        "caf_equation_policy": (
            "No formal signed or normalized CAF equation is displayed. The "
            "compact saved artifact supports display coordinates and power views, "
            "not a standalone equation convention."
        ),
        "matlab_string_handling": (
            "Legacy MATLAB MCOS strings are opaque to scipy.io.loadmat. Outcome "
            "labels are validated by their explicit saved boolean semantic predicates."
        ),
        "claim_boundary": {
            "diagnostic_synthetic_integration_only": True,
            "field_detection_claimed": False,
            "tracking_claimed": False,
            "formal_g4r_state_changed": False,
            "formal_g6_or_g8_enabled": False,
        },
        "tool_versions": {
            "python": sys.version.split()[0],
            "numpy": np.__version__,
            "scipy": scipy.__version__,
            "platform": platform.platform(),
        },
    }
    (PACKAGE_ROOT / "metadata.json").write_text(
        json.dumps(metadata, indent=2) + "\n",
        encoding="utf-8",
    )
    manifest = {
        "schema_version": PACKAGE_SCHEMA,
        "files": sorted(
            {
                path.name: {
                    "sha256": _sha256(path),
                    "size_bytes": path.stat().st_size,
                }
                for path in PACKAGE_ROOT.iterdir()
                if path.is_file() and path.name != "manifest.json"
            }.items()
        ),
        "source_sha256": {
            record["label"]: record["sha256"] for record in source_records
        },
    }
    (PACKAGE_ROOT / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )
    return PACKAGE_ROOT


def main() -> int:
    try:
        package = extract_package()
    except ContractError as error:
        print(f"DATA CONTRACT FAILED: {error}", file=sys.stderr)
        return 2
    print(f"Created validated compact package: {package}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
