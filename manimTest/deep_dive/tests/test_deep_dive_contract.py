"""No-render tests for the math-first passive-bistatic deep dive."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

TEST_ROOT = Path(__file__).resolve().parents[1]
if str(TEST_ROOT) not in sys.path:
    sys.path.insert(0, str(TEST_ROOT))

from validate_deep_dive import validate_data
from video_contract import CHAPTERS, FRAME_RATE, PLANNED_DURATION_S, RESOLUTION


class DeepDiveContractTest(unittest.TestCase):
    def test_timing_contract_is_twelve_to_fifteen_minutes(self) -> None:
        self.assertEqual(PLANNED_DURATION_S, 800)
        self.assertGreaterEqual(PLANNED_DURATION_S, 12 * 60)
        self.assertLessEqual(PLANNED_DURATION_S, 15 * 60)
        self.assertEqual(FRAME_RATE, 30)
        self.assertEqual(RESOLUTION, (1920, 1080))

    def test_each_chapter_has_captions_and_a_source(self) -> None:
        self.assertEqual(len(CHAPTERS), 10)
        self.assertEqual(len({chapter["id"] for chapter in CHAPTERS}), 10)
        self.assertTrue(all(len(chapter["captions"]) == 3 for chapter in CHAPTERS))
        self.assertTrue(all(chapter["source"].startswith("S") for chapter in CHAPTERS))

    def test_compact_evidence_contract(self) -> None:
        result = validate_data()
        self.assertEqual(result["source_count"], 2)
        self.assertEqual(result["planned_duration_s"], 800)


if __name__ == "__main__":
    unittest.main()
