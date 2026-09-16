"""Validate the deep-dive data contract and optional rendered MP4."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

DEEP_DIVE_ROOT = Path(__file__).resolve().parent
REPOSITORY_ROOT = DEEP_DIVE_ROOT.parents[1]
DATA_ROOT = DEEP_DIVE_ROOT / "deep_dive_data_v1"
FORBIDDEN_SUFFIXES = {".mat", ".bb", ".npz", ".npy", ".wav", ".mp3"}


class ContractError(RuntimeError):
    """Raised when a local educational-data contract is invalid."""


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_data() -> dict[str, Any]:
    """Validate compact data, source provenance, and claim boundary."""

    manifest = _read_json(DATA_ROOT / "manifest.json")
    evidence = _read_json(DATA_ROOT / "evidence.json")
    analytic = _read_json(DATA_ROOT / "analytic_demo.json")

    if manifest["schema_version"] != "deep_dive_data_v1":
        raise ContractError("Unexpected deep-dive manifest schema.")
    if evidence["schema_version"] != "deep_dive_evidence_v1":
        raise ContractError("Unexpected evidence schema.")
    if analytic["schema_version"] != "deep_dive_analytic_demo_v1":
        raise ContractError("Unexpected analytic-demo schema.")

    for path in DATA_ROOT.rglob("*"):
        if path.is_file() and path.suffix.lower() in FORBIDDEN_SUFFIXES:
            raise ContractError(f"Forbidden retained data type: {path.name}")

    claim_boundary = manifest["claim_boundary"]
    if any(claim_boundary.values()):
        raise ContractError("The compact package claims an excluded activity.")

    examples = {row["label"]: row for row in evidence["final_examples"]}
    positive = examples.get("45 km positive control")
    near = examples.get("15 km baseline")
    if positive is None or near is None:
        raise ContractError("Both final examples are required.")
    if positive["conclusion"] != "criterion_passed":
        raise ContractError("45 km result must remain criterion passed.")
    if not positive["detector_evaluated"] or not positive["injected_truth_matched_post_hoc"]:
        raise ContractError("45 km result must remain evaluated and associated.")
    if near["conclusion"] != "not_evaluated_outside_detector_support":
        raise ContractError("15 km result must remain not evaluated.")
    if near["detector_evaluated"] or near["injected_truth_matched_post_hoc"]:
        raise ContractError("15 km baseline cannot claim detector evaluation or a match.")

    detector = evidence["detector_contract"]
    if detector["candidate_generation_truth_blind"] is not True:
        raise ContractError("Candidate generation must remain truth blind.")
    if detector["nms_rows_doppler_columns_delay"] != [7, 3]:
        raise ContractError("NMS geometry must remain 7 by 3.")
    if detector["pfa_design_input"] != 1.0e-3:
        raise ContractError("Highlighted Pfa must remain 1e-3.")

    for source in manifest["source_evidence"]:
        source_path = REPOSITORY_ROOT / source["relative_path"]
        if not source_path.is_file():
            raise ContractError(f"Evidence source is unavailable: {source_path}")
        if _sha256(source_path) != source["sha256"]:
            raise ContractError(f"Evidence hash mismatch: {source_path.name}")

    return {
        "data_files": sorted(path.name for path in DATA_ROOT.glob("*.json")),
        "source_count": len(manifest["source_evidence"]),
        "planned_duration_s": 800,
    }


def validate_video(path: Path) -> dict[str, Any]:
    """Validate a finished H.264 1080p, 30 fps instructional MP4."""

    if not path.is_file():
        raise ContractError(f"Video is missing: {path}")
    command = [
        "ffprobe",
        "-v",
        "error",
        "-show_entries",
        "format=duration:stream=codec_name,width,height,avg_frame_rate",
        "-of",
        "json",
        str(path),
    ]
    try:
        completed = subprocess.run(
            command, check=True, capture_output=True, text=True
        )
    except FileNotFoundError as error:
        raise ContractError("ffprobe is required to validate the rendered MP4.") from error
    except subprocess.CalledProcessError as error:
        raise ContractError(error.stderr.strip() or "ffprobe failed.") from error

    probe = json.loads(completed.stdout)
    video_stream = next(
        (stream for stream in probe.get("streams", []) if stream.get("width")),
        None,
    )
    if video_stream is None:
        raise ContractError("No video stream found.")
    duration_s = float(probe["format"]["duration"])
    if not 720.0 <= duration_s <= 900.0:
        raise ContractError(f"Video duration must be 12–15 minutes, found {duration_s:.2f} s.")
    if (video_stream["width"], video_stream["height"]) != (1920, 1080):
        raise ContractError("Video must be 1920 by 1080.")
    if video_stream["codec_name"] != "h264":
        raise ContractError("Video codec must be H.264.")
    numerator, denominator = video_stream["avg_frame_rate"].split("/")
    frame_rate = float(numerator) / float(denominator)
    if abs(frame_rate - 30.0) > 0.1:
        raise ContractError(f"Video must be 30 fps, found {frame_rate:.3f}.")
    return {
        "duration_s": duration_s,
        "frame_rate": frame_rate,
        "size": [video_stream["width"], video_stream["height"]],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", type=Path)
    args = parser.parse_args()
    try:
        result = validate_data()
        if args.video is not None:
            result["video"] = validate_video(args.video)
    except ContractError as error:
        print(f"DEEP-DIVE CONTRACT FAILED: {error}", file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
