"""No-render contract tests for the standalone Deep Dive 2 package."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

TEST_ROOT = Path(__file__).resolve().parents[1]
if str(TEST_ROOT) not in sys.path:
    sys.path.insert(0, str(TEST_ROOT))

from validate_deep_dive_2 import validate_data, validate_teaching_contract
from video_contract import CHAPTERS, FRAME_RATE, PLANNED_DURATION_S, RESOLUTION


class DeepDive2ContractTest(unittest.TestCase):
    def test_exact_fifteen_minute_timing(self) -> None:
        self.assertEqual(PLANNED_DURATION_S, 900)
        self.assertEqual(FRAME_RATE, 30)
        self.assertEqual(RESOLUTION, (1920, 1080))
        self.assertEqual(sum(chapter["duration_s"] for chapter in CHAPTERS), 900)

    def test_four_timed_beats_and_registered_sources(self) -> None:
        self.assertEqual(len(CHAPTERS), 10)
        self.assertEqual(len({chapter["id"] for chapter in CHAPTERS}), 10)
        self.assertTrue(all(len(chapter["captions"]) == 4 for chapter in CHAPTERS))
        self.assertTrue(
            all(
                chapter["source"]
                in {"S1", "S4", "S6", "S7", "S8", "S9", "S10", "S11S12"}
                for chapter in CHAPTERS
            )
        )
        validate_teaching_contract()

    def test_compact_geometry_and_detector_boundary(self) -> None:
        result = validate_data()
        self.assertEqual(result["source_count"], 2)
        self.assertEqual(result["planned_duration_s"], 900)
        self.assertEqual(
            result["data_files"], ["analytic_demo.json", "compact_geometry.json"]
        )


if __name__ == "__main__":
    unittest.main()
