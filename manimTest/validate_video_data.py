"""Validate compact extracted data and optionally the rendered MP4."""

from __future__ import annotations

import argparse
import csv
import json
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np

from captions import SCENES, total_duration_s
from extract_compact_results import (
    PACKAGE_ROOT,
    PACKAGE_SCHEMA,
    SOURCES,
    ContractError,
    _sha256,
    validate_all_sources,
)


class ValidationError(RuntimeError):
    """Raised when a derived package or render does not satisfy the contract."""


def _load_json(path: Path) -> dict:
    if not path.is_file():
        raise ValidationError(f"Required file is missing: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def validate_caption_contract() -> None:
    if len(SCENES) != 8:
        raise ValidationError(f"Expected eight captioned scenes; found {len(SCENES)}.")
    if not 360 <= total_duration_s() <= 480:
        raise ValidationError(f"Planned duration {total_duration_s()} s is outside 6–8 minutes.")
    for scene in SCENES:
        if len(scene["captions"]) < 3:
            raise ValidationError(f"{scene['id']} has too few captions.")
        if any(len(caption) > 210 for caption in scene["captions"]):
            raise ValidationError(f"{scene['id']} contains an unreadably long caption.")


def validate_package() -> None:
    # Revalidate the read-only source predicate first; this detects changed sources.
    bundles = validate_all_sources()
    metadata = _load_json(PACKAGE_ROOT / "metadata.json")
    manifest = _load_json(PACKAGE_ROOT / "manifest.json")
    geometry = _load_json(PACKAGE_ROOT / "detector_geometry.json")
    if metadata.get("schema_version") != PACKAGE_SCHEMA:
        raise ValidationError("Metadata schema version is incorrect.")
    if manifest.get("schema_version") != PACKAGE_SCHEMA:
        raise ValidationError("Manifest schema version is incorrect.")
    expected_source_hashes = {
        bundle["spec"].label: bundle["source_sha256"] for bundle in bundles
    }
    if manifest.get("source_sha256") != expected_source_hashes:
        raise ValidationError("Manifest source hashes no longer match the verified source bundles.")
    files = dict(manifest.get("files", []))
    if not files:
        raise ValidationError("Manifest contains no package files.")
    for filename, expected in files.items():
        path = PACKAGE_ROOT / filename
        if not path.is_file():
            raise ValidationError(f"Manifest file is absent: {filename}")
        if _sha256(path) != expected["sha256"]:
            raise ValidationError(f"Manifest hash mismatch: {filename}")
        if path.stat().st_size != expected["size_bytes"]:
            raise ValidationError(f"Manifest size mismatch: {filename}")
    if geometry["cut_delay_limits_us"] != [-1200.0, -150.0]:
        raise ValidationError("Detector delay support differs from the frozen rectangle.")
    if geometry["cut_doppler_limits_hz"] != [-750.0, 750.0]:
        raise ValidationError("Detector Doppler support differs from the frozen rectangle.")
    if geometry["actual_cut_count"] != 12832:
        raise ValidationError("Detector CUT count is not 12,832.")
    truth_file = PACKAGE_ROOT / metadata["truth_evaluation_file"]
    with truth_file.open(newline="", encoding="utf-8") as input_file:
        truth_rows = list(csv.DictReader(input_file))
    outcomes = {row["scenario"]: row for row in truth_rows}
    positive = outcomes.get("45km_positive_control")
    ineligible = outcomes.get("15km_detector_ineligible")
    if positive is None or ineligible is None:
        raise ValidationError("Truth table must contain both source scenarios.")
    if positive["conclusion_outcome"] != "criterion_passed":
        raise ValidationError("Positive-control outcome is incorrect.")
    if ineligible["evaluation_status"] != "outside_detector_support_not_evaluated":
        raise ValidationError("15 km case is not labeled as not evaluated.")
    if ineligible["detector_evaluated"].lower() != "false":
        raise ValidationError("15 km case incorrectly reports detector evaluation.")
    records = metadata.get("view_records", [])
    if not records:
        raise ValidationError("No compact map-view records were exported.")
    for record in records:
        if record["power_shape"] != [401, 32]:
            raise ValidationError(f"Unexpected compact map shape: {record['file']}")
        with np.load(PACKAGE_ROOT / record["file"]) as view:
            if view["power_db"].shape != (401, 32):
                raise ValidationError(f"NPZ power shape mismatch: {record['file']}")
            if view["delay_s"].size != 32 or view["doppler_hz"].size != 401:
                raise ValidationError(f"NPZ axes mismatch: {record['file']}")
            if "raw_iq" in view.files or "map_linear" in view.files or "full_map" in view.files:
                raise ValidationError(f"Prohibited source representation in {record['file']}")
    for spec in SOURCES:
        if not spec.absolute_path.is_file():
            raise ValidationError(f"Source disappeared: {spec.absolute_path}")


def validate_video(video_path: Path) -> None:
    ffprobe = shutil.which("ffprobe")
    if not ffprobe:
        raise ValidationError("ffprobe is required for MP4 validation but was not found.")
    if not video_path.is_file():
        raise ValidationError(f"Video does not exist: {video_path}")
    command = [
        ffprobe,
        "-v",
        "error",
        "-select_streams",
        "v:0",
        "-show_entries",
        "stream=codec_name,width,height,avg_frame_rate:format=duration",
        "-of",
        "json",
        str(video_path),
    ]
    completed = subprocess.run(command, capture_output=True, text=True, check=False)
    if completed.returncode != 0:
        raise ValidationError(f"ffprobe failed: {completed.stderr.strip()}")
    probe = json.loads(completed.stdout)
    stream = probe.get("streams", [{}])[0]
    if stream.get("codec_name") != "h264":
        raise ValidationError(f"Expected H.264 MP4; found {stream.get('codec_name')!r}.")
    if (stream.get("width"), stream.get("height")) != (1920, 1080):
        raise ValidationError("Video resolution is not 1920×1080.")
    frame_rate = stream.get("avg_frame_rate", "0/1")
    numerator, denominator = (float(part) for part in frame_rate.split("/"))
    if denominator == 0 or abs(numerator / denominator - 30.0) > 1e-6:
        raise ValidationError(f"Video frame rate is not 30 fps: {frame_rate}.")
    duration_s = float(probe.get("format", {}).get("duration", 0.0))
    if not 360.0 <= duration_s <= 480.0:
        raise ValidationError(f"Video duration {duration_s:.2f} s is outside 6–8 minutes.")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", type=Path, help="Optional MP4 to inspect with ffprobe.")
    arguments = parser.parse_args()
    try:
        validate_caption_contract()
        validate_package()
        if arguments.video:
            validate_video(arguments.video)
    except (ContractError, ValidationError) as error:
        print(f"VALIDATION FAILED: {error}", file=sys.stderr)
        return 2
    print("Validated source bundles, compact package, and caption contract.")
    if arguments.video:
        print(f"Validated MP4: {arguments.video}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
