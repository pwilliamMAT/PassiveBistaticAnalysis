"""Lightweight no-render checks for the isolated video contract."""

from __future__ import annotations

import unittest

from captions import SCENES, total_duration_s
from extract_compact_results import CASE_ORDER, FIXED_CANDIDATES, SOURCES


class TrialContractTest(unittest.TestCase):
    def test_has_eight_captioned_scenes(self) -> None:
        self.assertEqual(len(SCENES), 8)
        self.assertEqual(len({scene["id"] for scene in SCENES}), 8)
        self.assertTrue(all(len(scene["captions"]) >= 3 for scene in SCENES))

    def test_duration_is_six_to_eight_minutes(self) -> None:
        self.assertGreaterEqual(total_duration_s(), 360)
        self.assertLessEqual(total_duration_s(), 480)

    def test_fixed_data_contract(self) -> None:
        self.assertEqual(CASE_ORDER, ("field_only_control", "field_plus_geo_target"))
        self.assertEqual(
            FIXED_CANDIDATES,
            ("none", "conservative_lms", "aggressive_lms"),
        )
        self.assertEqual(
            [source.expected_outcome for source in SOURCES],
            ["criterion_passed", "outside_detector_support_not_evaluated"],
        )


if __name__ == "__main__":
    unittest.main()
