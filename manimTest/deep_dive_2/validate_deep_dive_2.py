"""Validate Deep Dive 2 data, teaching contract, and optional rendered MP4."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

from video_contract import (
    CHAPTERS,
    EXPECTED_VIDEO_SECONDS,
    FRAME_RATE,
    PLANNED_DURATION_S,
    RESOLUTION,
)


DEEP_DIVE_2_ROOT = Path(__file__).resolve().parent
REPOSITORY_ROOT = DEEP_DIVE_2_ROOT.parents[1]
DATA_ROOT = DEEP_DIVE_2_ROOT / "deep_dive_2_data_v1"
FORBIDDEN_SUFFIXES = {".mat", ".bb", ".npz", ".npy", ".wav", ".mp3"}
EXPECTED_SOURCES = {
    "S11": {
        "relative_path": (
            "artifacts/20260622T102123/Field_Background_Synthetic_Demo/"
            "field_background_demo_final_20260908/"
            "fieldBackgroundSyntheticPipelineResults.mat"
        ),
        "sha256": "d64ac4ef034f6278050b084e9ebbf73a386c91b6f997ff8afe04107ca1cd0dea",
    },
    "S12": {
        "relative_path": (
            "artifacts/20260622T102123/Field_Background_Synthetic_Demo/"
            "field_background_close_target_support_probe_20260914T190224119Z/"
            "fieldBackgroundSyntheticPipelineResults.mat"
        ),
        "sha256": "ed77b873a08381b5291f30765697b65b9690f1bbbd6eb2420429fc2b2a563419",
    },
}


class ContractError(RuntimeError):
    """Raised when a Deep Dive 2 contract is invalid."""


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def validate_teaching_contract() -> None:
    """Validate exact timing, sources, learning beats, and restricted wording."""

    _require(PLANNED_DURATION_S == EXPECTED_VIDEO_SECONDS, "Planned duration is not 900 s.")
    _require(FRAME_RATE == 30, "Frame rate must be 30 fps.")
    _require(RESOLUTION == (1920, 1080), "Resolution must be 1920×1080.")
    _require(len(CHAPTERS) == 10, "Deep Dive 2 must contain ten chapters.")
    _require(
        len({chapter["id"] for chapter in CHAPTERS}) == len(CHAPTERS),
        "Chapter IDs must be unique.",
    )
    _require(
        all(len(chapter["captions"]) == 4 for chapter in CHAPTERS),
        "Every chapter must retain four timed learning beats.",
    )
    _require(
        all(chapter["source"] in {"S1", "S4", "S6", "S7", "S8", "S9", "S10", "S11S12"} for chapter in CHAPTERS),
        "A chapter has an unregistered source ID.",
    )

    restricted_text = "\n".join(
        [
            (DEEP_DIVE_2_ROOT / "narration.md").read_text(encoding="utf-8"),
            "\n".join(
                caption for chapter in CHAPTERS for caption in chapter["captions"]
            ),
        ]
    ).lower()
    for forbidden in ("missed", "receiver range", "bistatic range"):
        _require(
            forbidden not in restricted_text,
            f"Restricted teaching wording is present: {forbidden!r}.",
        )


def validate_data() -> dict[str, Any]:
    """Validate compact geometry, hashes, support logic, and claim exclusions."""

    manifest = _read_json(DATA_ROOT / "manifest.json")
    geometry = _read_json(DATA_ROOT / "compact_geometry.json")
    analytic = _read_json(DATA_ROOT / "analytic_demo.json")

    _require(manifest["schema_version"] == "deep_dive_2_data_v1", "Bad manifest schema.")
    _require(
        geometry["SchemaVersion"] == "deep_dive_2_compact_geometry_v1",
        "Bad compact-geometry schema.",
    )
    _require(
        analytic["schema_version"] == "deep_dive_2_analytic_demo_v1",
        "Bad analytic-data schema.",
    )
    for path in DATA_ROOT.rglob("*"):
        if path.is_file() and path.suffix.lower() in FORBIDDEN_SUFFIXES:
            raise ContractError(f"Forbidden retained data type: {path.name}")

    for filename, record in manifest["files"].items():
        path = DATA_ROOT / filename
        _require(path.is_file(), f"Manifest data file is missing: {filename}.")
        _require(
            _sha256(path) == record["sha256"],
            f"Data hash mismatch: {filename}. Regenerate or audit it.",
        )

    _require(
        manifest["fixed_source_ids"] == ["S11", "S12"],
        "Fixed source IDs changed.",
    )
    source_records = {item["Id"]: item for item in geometry["Sources"]}
    _require(set(source_records) == set(EXPECTED_SOURCES), "Source IDs are invalid.")
    for source_id, expected in EXPECTED_SOURCES.items():
        record = source_records[source_id]
        _require(
            record["RelativePath"] == expected["relative_path"],
            f"{source_id} source path changed.",
        )
        _require(
            record["Sha256"] == expected["sha256"],
            f"{source_id} source hash record changed.",
        )
        source_path = REPOSITORY_ROOT / record["RelativePath"]
        _require(source_path.is_file(), f"{source_id} source bundle is absent.")
        _require(
            _sha256(source_path) == record["Sha256"],
            f"{source_id} source bundle hash mismatch.",
        )

    _require(geometry["SharedTxRxGeometry"] is True, "Tx/Rx geometry must match.")
    transmitter = geometry["Transmitter"]
    _require(abs(transmitter["East_km"] - 9.290) < 0.005, "Tx east ENU is invalid.")
    _require(abs(transmitter["North_km"] - 1.155) < 0.005, "Tx north ENU is invalid.")
    _require(geometry["PlanView"]["AltitudeOmitted"] is True, "Plan-view limitation changed.")
    _require(
        geometry["DetectorSupport"]["Delay_us"] == [-1200, -150],
        "Frozen delay support changed.",
    )
    _require(
        geometry["DetectorSupport"]["Doppler_Hz"] == [-750, 750],
        "Frozen Doppler support changed.",
    )
    _require(
        geometry["DisplayConvention"]["Delay"] == "tau_display = -tau_excess",
        "Display-delay convention changed.",
    )
    _require(
        geometry["DisplayConvention"]["Doppler"] == "f_display = -f_bistatic",
        "Display-Doppler convention changed.",
    )

    scenarios = {item["SourceId"]: item for item in geometry["Scenarios"]}
    _require(set(scenarios) == {"S11", "S12"}, "Scenario source links changed.")
    inside = scenarios["S11"]
    outside = scenarios["S12"]
    _require(
        inside["Label"] == "45 km receiver-local north-offset scenario",
        "45 km wording changed.",
    )
    _require(
        outside["Label"] == "15 km receiver-local north-offset scenario",
        "15 km wording changed.",
    )
    _require(
        abs(inside["InitialWaypoint"]["North_km"] - 45.021) < 0.005,
        "45 km initial ENU north coordinate is invalid.",
    )
    _require(
        abs(outside["InitialWaypoint"]["North_km"] - 15.007) < 0.005,
        "15 km initial ENU north coordinate is invalid.",
    )
    _require(
        inside["PhysicalExcessDelay_us"] > 0 and outside["PhysicalExcessDelay_us"] > 0,
        "Physical excess delay must remain positive.",
    )
    _require(
        abs(inside["DisplayDelay_us"] + 269.5) < 0.1
        and abs(inside["DisplayDoppler_Hz"] - 591.9) < 0.1,
        "45 km display marker is invalid.",
    )
    _require(
        abs(outside["DisplayDelay_us"] + 76.5) < 0.1
        and abs(outside["DisplayDoppler_Hz"] - 540.5) < 0.1,
        "15 km display marker is invalid.",
    )
    _require(inside["DetectorEligible"] is True, "45 km must be detector-eligible.")
    _require(outside["DetectorEligible"] is False, "15 km must remain ineligible.")
    _require(
        all(value is False for value in manifest["claim_boundary"].values()),
        "Manifest claims an excluded activity.",
    )
    _require(
        all(value is False for value in geometry["ClaimBoundary"].values()),
        "Geometry evidence claims an excluded activity.",
    )
    return {
        "data_files": sorted(manifest["files"]),
        "source_count": len(source_records),
        "planned_duration_s": PLANNED_DURATION_S,
    }


def validate_video(path: Path) -> dict[str, Any]:
    """Validate a 900-second, 1080p, H.264, 30 fps, no-audio MP4."""

    _require(path.is_file(), f"Video is missing: {path}")
    command = [
        "ffprobe",
        "-v",
        "error",
        "-show_entries",
        "format=duration:stream=codec_name,codec_type,width,height,avg_frame_rate",
        "-of",
        "json",
        str(path),
    ]
    try:
        completed = subprocess.run(command, check=True, capture_output=True, text=True)
    except FileNotFoundError as error:
        raise ContractError("ffprobe is required to validate the MP4.") from error
    except subprocess.CalledProcessError as error:
        raise ContractError(error.stderr.strip() or "ffprobe failed.") from error

    probe = json.loads(completed.stdout)
    streams = probe.get("streams", [])
    video_stream = next(
        (stream for stream in streams if stream.get("codec_type") == "video"),
        None,
    )
    _require(video_stream is not None, "No video stream was found.")
    _require(
        all(stream.get("codec_type") != "audio" for stream in streams),
        "The Deep Dive 2 MP4 must not contain audio.",
    )
    _require(video_stream["codec_name"] == "h264", "Video codec must be H.264.")
    _require(
        (video_stream["width"], video_stream["height"]) == (1920, 1080),
        "Video resolution must be 1920×1080.",
    )
    numerator, denominator = video_stream["avg_frame_rate"].split("/")
    frame_rate = float(numerator) / float(denominator)
    _require(abs(frame_rate - 30.0) < 0.01, "Video frame rate must be 30 fps.")
    duration_s = float(probe["format"]["duration"])
    _require(
        abs(duration_s - EXPECTED_VIDEO_SECONDS) <= 0.2,
        f"Video duration must be 900 s, found {duration_s:.3f} s.",
    )
    return {
        "duration_s": duration_s,
        "frame_rate": frame_rate,
        "size": [video_stream["width"], video_stream["height"]],
        "audio_streams": 0,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", type=Path)
    arguments = parser.parse_args()
    try:
        validate_teaching_contract()
        result = validate_data()
        if arguments.video is not None:
            result["video"] = validate_video(arguments.video)
    except ContractError as error:
        print(f"DEEP-DIVE-2 CONTRACT FAILED: {error}", file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
