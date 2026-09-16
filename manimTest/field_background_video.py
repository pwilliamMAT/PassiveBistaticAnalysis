"""Caption-led ManimGL visualization of two compact diagnostic results.

Run ``extract_compact_results.py`` first.  This module uses ManimGL
(``manimlib``) only; every numeric visual is either a code-drawn diagram or
comes from the local ``manim_video_data_v1`` package.
"""

from __future__ import annotations

import csv
import hashlib
import json
import math
import sys
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image

TRIAL_ROOT = Path(__file__).resolve().parent
if str(TRIAL_ROOT) not in sys.path:
    sys.path.insert(0, str(TRIAL_ROOT))

from manimlib import *  # noqa: E402

from captions import GLOSSARY, SCENES, SOURCE_CARD, VIDEO_SUBTITLE, VIDEO_TITLE  # noqa: E402


DATA_ROOT = TRIAL_ROOT / "data" / "manim_video_data_v1"
GENERATED_IMAGE_ROOT = TRIAL_ROOT / "output" / "generated_map_images"
BACKGROUND = "#091321"
PANEL = "#10243A"
PANEL_DARK = "#0C1B2B"
INK = "#EAF2F8"
MUTED = "#A8BACD"
CYAN = "#45D7F2"
BLUE = "#3F82F6"
GREEN = "#57D68D"
AMBER = "#FFB454"
RED = "#FF6B6B"
PURPLE = "#C792EA"
GRID = "#35526E"


def _fit_width(mobject: Mobject, width: float) -> Mobject:
    """Scale down text without growing short labels."""

    if mobject.get_width() > width:
        mobject.scale(width / mobject.get_width())
    return mobject


def _text(
    content: str,
    font_size: float = 28,
    color: str = INK,
    width: float | None = None,
) -> Text:
    value = Text(content, font_size=font_size, color=color)
    if width is not None:
        _fit_width(value, width)
    return value


def _rgb_from_power_db(power_db: np.ndarray) -> np.ndarray:
    """Make a compact, deterministic blue-to-gold map image without matplotlib."""

    normalized = np.clip((power_db.astype(float) + 50.0) / 50.0, 0.0, 1.0)
    red = np.clip(20.0 + 235.0 * normalized**1.4, 0.0, 255.0)
    green = np.clip(30.0 + 205.0 * normalized**1.1, 0.0, 255.0)
    blue = np.clip(75.0 + 170.0 * (1.0 - normalized) ** 1.4, 0.0, 255.0)
    rgb = np.dstack((red, green, blue)).astype(np.uint8)
    return np.flipud(rgb)


def _write_map_image(power_db: np.ndarray) -> Path:
    """Materialize a deterministic raster only under the ignored output root."""

    rgb = _rgb_from_power_db(power_db)
    image_name = f"compact_map_{hashlib.sha256(rgb.tobytes()).hexdigest()[:20]}.png"
    image_path = GENERATED_IMAGE_ROOT / image_name
    if not image_path.is_file():
        GENERATED_IMAGE_ROOT.mkdir(parents=True, exist_ok=True)
        Image.fromarray(rgb).save(image_path)
    return image_path


class TrialData:
    """Read only the local package emitted by extract_compact_results.py."""

    def __init__(self) -> None:
        metadata_path = DATA_ROOT / "metadata.json"
        if not metadata_path.is_file():
            raise RuntimeError(
                "Compact data package is missing. Run extract_compact_results.py first."
            )
        self.metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        self.geometry = json.loads(
            (DATA_ROOT / self.metadata["detector_geometry_file"]).read_text(
                encoding="utf-8"
            )
        )
        self.truth = self._read_csv(DATA_ROOT / self.metadata["truth_evaluation_file"])
        self.g3 = self._read_csv(DATA_ROOT / self.metadata["g3_reuse_file"])
        self.trajectories = {
            item["scenario"]: self._read_csv(DATA_ROOT / item["file"])
            for item in self.metadata["trajectory_files"]
        }
        self.views = {
            (
                item["scenario"],
                item["view_kind"],
                item["case_id"],
                item["candidate_name"],
            ): item
            for item in self.metadata["view_records"]
        }

    @staticmethod
    def _read_csv(path: Path) -> list[dict[str, str]]:
        with path.open(newline="", encoding="utf-8") as input_file:
            return list(csv.DictReader(input_file))

    def trajectory_summary(self, scenario: str) -> dict[str, float]:
        rows = self.trajectories[scenario]
        midpoint = rows[len(rows) // 2]
        return {
            "delay_us": float(midpoint["display_delay_us"]),
            "doppler_hz": float(midpoint["display_doppler_hz"]),
            "north_m": float(midpoint["north_m"]),
            "east_m": float(midpoint["east_m"]),
        }

    def g3_summary(self) -> dict[str, float]:
        row = self.g3[0]
        return {
            "lag": float(row["applied_lag_samples"]),
            "residual_hz": float(row["applied_residual_frequency_hz"]),
            "spread_hz": float(row["residual_frequency_spread_hz"]),
            "window_count": float(row["window_count"]),
        }

    def view(
        self,
        scenario: str,
        view_kind: str,
        case_id: str,
        candidate_name: str,
    ) -> dict[str, np.ndarray]:
        item = self.views[(scenario, view_kind, case_id, candidate_name)]
        with np.load(DATA_ROOT / item["file"]) as loaded:
            return {name: loaded[name].copy() for name in loaded.files}


class TrialScene(Scene):
    """Shared ManimGL drawing helpers for the full and smoke scenes."""

    def setup(self) -> None:
        super().setup()
        # ManimGL 1.7.2's CLI leaves an explicitly supplied --fps value as a
        # string. Normalize it before Scene.play computes frame intervals.
        self.camera.fps = int(self.camera.fps)
        self.camera.background_color = BACKGROUND
        self.data = TrialData()

    def panel(
        self,
        title: str,
        lines: list[str],
        width: float,
        height: float,
        color: str = CYAN,
        body_size: float = 22,
    ) -> VGroup:
        box = RoundedRectangle(
            corner_radius=0.14,
            width=width,
            height=height,
            stroke_color=color,
            stroke_width=2,
            fill_color=PANEL,
            fill_opacity=0.96,
        )
        title_text = _text(title, 25, color, width - 0.35)
        title_text.next_to(box.get_top(), DOWN, buff=0.18)
        body = VGroup(
            *[_text(line, body_size, INK, width - 0.45) for line in lines]
        )
        body.arrange(DOWN, aligned_edge=LEFT, buff=0.13)
        body.next_to(title_text, DOWN, buff=0.22)
        return VGroup(box, title_text, body)

    def caption_card(self, content: str) -> VGroup:
        caption = _text(content, 26, INK, 12.0)
        plate = RoundedRectangle(
            corner_radius=0.12,
            width=max(12.2, caption.get_width() + 0.5),
            height=caption.get_height() + 0.42,
            stroke_color="#31516D",
            stroke_width=1.5,
            fill_color="#06101B",
            fill_opacity=0.94,
        )
        caption.move_to(plate)
        group = VGroup(plate, caption)
        group.to_edge(DOWN, buff=0.18)
        return group

    def chapter(
        self,
        scene_spec: dict[str, Any],
        visual: Mobject,
    ) -> None:
        """Render one captioned chapter at its planned duration."""

        header = _text(scene_spec["title"], 33, CYAN, 13.0)
        header.to_edge(UP, buff=0.23)
        visual.shift(DOWN * 0.18)
        captions = scene_spec["captions"]
        caption = self.caption_card(captions[0])
        segment_s = (float(scene_spec["duration_s"]) - 2.0) / len(captions)
        self.play(FadeIn(header), FadeIn(visual), run_time=1.0)
        self.play(FadeIn(caption), run_time=0.5)
        self.wait(segment_s - 0.5)
        for next_caption in captions[1:]:
            replacement = self.caption_card(next_caption)
            self.play(FadeTransform(caption, replacement), run_time=0.5)
            caption = replacement
            self.wait(segment_s - 0.5)
        self.play(FadeOut(Group(header, visual, caption)), run_time=1.0)

    def map_panel(
        self,
        title: str,
        view: dict[str, np.ndarray],
        width: float,
        height: float,
        marker: tuple[float, float] | None = None,
        marker_color: str = GREEN,
        subtitle: str = "saved compact power view",
    ) -> VGroup:
        frame = RoundedRectangle(
            corner_radius=0.10,
            width=width,
            height=height,
            stroke_color="#5E83A8",
            stroke_width=1.4,
            fill_color=PANEL_DARK,
            fill_opacity=1.0,
        )
        image = ImageMobject(str(_write_map_image(view["power_db"])))
        # Preserve a usable physical-coordinate panel aspect rather than the
        # retained 401×32 array's pixel aspect. The axes carry different units.
        image.set_width(width - 0.24, stretch=True)
        image.set_height(height - 0.55, stretch=True)
        image.move_to(frame.get_center() + DOWN * 0.12)
        title_text = _text(title, 19, INK, width - 0.25)
        title_text.next_to(frame.get_top(), DOWN, buff=0.08)
        subtitle_text = _text(subtitle, 14, MUTED, width - 0.25)
        subtitle_text.next_to(frame.get_bottom(), UP, buff=0.05)
        group = Group(frame, image, title_text, subtitle_text)
        if marker is not None:
            delay_us, doppler_hz = marker
            delay_axis_us = view["delay_s"] * 1e6
            doppler_axis_hz = view["doppler_hz"]
            x_fraction = (delay_us - delay_axis_us.min()) / (
                delay_axis_us.max() - delay_axis_us.min()
            )
            y_fraction = (doppler_hz - doppler_axis_hz.min()) / (
                doppler_axis_hz.max() - doppler_axis_hz.min()
            )
            x = image.get_left()[0] + float(x_fraction) * image.get_width()
            y = image.get_bottom()[1] + float(y_fraction) * image.get_height()
            marker_dot = Dot(np.array([x, y, 0]), radius=0.065, color=marker_color)
            marker_ring = Circle(radius=0.12, color=marker_color, stroke_width=2)
            marker_ring.move_to(marker_dot)
            group.add(marker_dot, marker_ring)
        return group

    def arrow_between(self, left: Mobject, right: Mobject, color: str = CYAN) -> Arrow:
        return Arrow(
            left.get_right(),
            right.get_left(),
            buff=0.14,
            color=color,
            stroke_width=4,
        )

    def geometry_visual(self) -> VGroup:
        """Code-drawn geometry using the retained trajectory summaries."""

        control = self.data.trajectory_summary("45km_positive_control")
        near = self.data.trajectory_summary("15km_detector_ineligible")
        floor = Line(LEFT * 5.6 + DOWN * 2.5, RIGHT * 5.8 + DOWN * 2.5, color=GRID)
        receiver = Dot(LEFT * 3.9 + DOWN * 2.5, color=CYAN, radius=0.11)
        transmitter = Dot(LEFT * 2.0 + DOWN * 2.2, color=PURPLE, radius=0.11)
        target_15 = Dot(LEFT * 3.9 + DOWN * 0.65, color=AMBER, radius=0.11)
        target_45 = Dot(LEFT * 3.9 + UP * 2.0, color=GREEN, radius=0.11)
        labels = VGroup(
            _text("Rx", 21, CYAN).next_to(receiver, DOWN, buff=0.1),
            _text("Tx", 21, PURPLE).next_to(transmitter, DOWN, buff=0.1),
            _text("15 km", 21, AMBER).next_to(target_15, LEFT, buff=0.15),
            _text("45 km", 21, GREEN).next_to(target_45, LEFT, buff=0.15),
        )
        paths = VGroup(
            DashedLine(transmitter.get_center(), target_15.get_center(), color=AMBER),
            DashedLine(target_15.get_center(), receiver.get_center(), color=AMBER),
            DashedLine(transmitter.get_center(), target_45.get_center(), color=GREEN),
            DashedLine(target_45.get_center(), receiver.get_center(), color=GREEN),
        )
        coordinates = self.panel(
            "Saved map-display coordinates",
            [
                f"45 km: {control['delay_us']:.1f} µs, {control['doppler_hz']:.1f} Hz",
                f"15 km: {near['delay_us']:.1f} µs, {near['doppler_hz']:.1f} Hz",
                "display delay = −excess delay",
                "display Doppler = −bistatic Doppler",
            ],
            5.1,
            2.2,
            color=BLUE,
            body_size=18,
        )
        coordinates.move_to(RIGHT * 3.2 + UP * 0.75)
        geometry_title = _text("Geometry drives delay and Doppler", 25, INK, 6.3)
        geometry_title.move_to(LEFT * 2.2 + UP * 3.0)
        return VGroup(floor, paths, receiver, transmitter, target_15, target_45, labels, coordinates, geometry_title)

    def support_visual(self) -> VGroup:
        """Draw context coordinates but intentionally no invented full-map power."""

        delay_min, delay_max = -1200.0, 200.0
        doppler_min, doppler_max = -1000.0, 1000.0
        frame = Rectangle(
            width=7.1,
            height=4.4,
            stroke_color="#7395B8",
            stroke_width=2,
            fill_color=PANEL_DARK,
            fill_opacity=0.9,
        )
        frame.move_to(RIGHT * 2.7 + UP * 0.2)

        def map_point(delay_us: float, doppler_hz: float) -> np.ndarray:
            x = frame.get_left()[0] + (delay_us - delay_min) / (delay_max - delay_min) * frame.get_width()
            y = frame.get_bottom()[1] + (doppler_hz - doppler_min) / (doppler_max - doppler_min) * frame.get_height()
            return np.array([x, y, 0])

        detector_left = map_point(-1200.0, -750.0)
        detector_right = map_point(-150.0, 750.0)
        support = Rectangle(
            width=detector_right[0] - detector_left[0],
            height=detector_right[1] - detector_left[1],
            stroke_color=CYAN,
            stroke_width=3,
            fill_color=CYAN,
            fill_opacity=0.10,
        )
        support.move_to((detector_left + detector_right) / 2)
        label = _text("fixed CFAR/NMS support", 18, CYAN, 3.0)
        label.next_to(support.get_top(), DOWN, buff=0.12)
        control = self.data.trajectory_summary("45km_positive_control")
        near = self.data.trajectory_summary("15km_detector_ineligible")
        point_45 = Dot(map_point(control["delay_us"], control["doppler_hz"]), color=GREEN, radius=0.085)
        point_15 = Dot(map_point(near["delay_us"], near["doppler_hz"]), color=AMBER, radius=0.085)
        point_labels = VGroup(
            _text("45 km\neligible", 16, GREEN, 1.2).next_to(point_45, LEFT, buff=0.08),
            _text("15 km\nnot evaluated", 16, AMBER, 1.5).next_to(point_15, RIGHT, buff=0.08),
        )
        axis_labels = VGroup(
            _text("delay (µs) →", 17, MUTED).next_to(frame, DOWN, buff=0.10),
            _text("Doppler (Hz)", 17, MUTED).rotate(PI / 2).next_to(frame, LEFT, buff=0.10),
            _text("physics-map coordinate context\n(no full-map power retained)", 16, MUTED, 5.2).next_to(frame, UP, buff=0.08),
        )
        return VGroup(frame, support, label, point_45, point_15, point_labels, axis_labels)


class FieldBackgroundTrial(TrialScene):
    """One 395-second, eight-chapter 1080p captioned movie."""

    def claim_boundary_visual(self) -> VGroup:
        positive = self.panel(
            "45 km positive control",
            [
                "criterion passed",
                "detector evaluated",
                "post-hoc injected-truth match",
                "no matched-control nuisance match",
            ],
            5.6,
            2.7,
            color=GREEN,
            body_size=20,
        )
        ineligible = self.panel(
            "15 km explanatory case",
            [
                "outside detector support",
                "physics-map placement valid",
                "detector evaluation: no",
                "not evaluated ≠ missed",
            ],
            5.6,
            2.7,
            color=AMBER,
            body_size=20,
        )
        positive.move_to(LEFT * 3.1 + UP * 0.8)
        ineligible.move_to(RIGHT * 3.1 + UP * 0.8)
        boundary = self.panel(
            "Claim boundary held constant",
            [
                "Diagnostic synthetic integration only",
                "No field-aircraft detection claim",
                "No tracking claim; no formal gate change",
            ],
            8.4,
            1.55,
            color=RED,
            body_size=20,
        )
        boundary.move_to(DOWN * 2.35)
        lead = _text(VIDEO_TITLE, 35, INK, 12.0)
        lead.move_to(UP * 3.0)
        subtitle = _text(VIDEO_SUBTITLE, 19, MUTED, 12.2)
        subtitle.next_to(lead, DOWN, buff=0.12)
        return VGroup(lead, subtitle, positive, ineligible, boundary)

    def paired_input_visual(self) -> VGroup:
        reference = self.panel(
            "Reference channel",
            ["field reference", "unchanged in both paths"],
            3.3,
            1.45,
            color=PURPLE,
            body_size=18,
        )
        control = self.panel(
            "Control surveillance",
            ["untouched field capture", "no injected echo"],
            3.3,
            1.45,
            color=CYAN,
            body_size=18,
        )
        injected = self.panel(
            "Injected surveillance",
            ["same field capture", "+ geometry-driven echo only"],
            3.5,
            1.45,
            color=AMBER,
            body_size=18,
        )
        g3 = self.panel(
            "Shared processing boundary",
            ["control-derived G3 correction", "same G4/G5/G6-D settings"],
            3.7,
            1.45,
            color=GREEN,
            body_size=18,
        )
        reference.move_to(LEFT * 4.6 + UP * 1.6)
        control.move_to(LEFT * 4.6 + DOWN * 0.8)
        injected.move_to(LEFT * 0.55 + DOWN * 0.8)
        g3.move_to(RIGHT * 3.9 + UP * 0.35)
        arrows = VGroup(
            self.arrow_between(reference, g3, PURPLE),
            self.arrow_between(control, injected, CYAN),
            self.arrow_between(injected, g3, AMBER),
        )
        note = self.panel(
            "Paired-control invariant",
            [
                "Reference unchanged • control surveillance unchanged",
                "Only injected surveillance differs • no target-aware tuning",
            ],
            10.5,
            1.35,
            color=BLUE,
            body_size=19,
        )
        note.move_to(DOWN * 2.65)
        return VGroup(reference, control, injected, g3, arrows, note)

    def g3_visual(self) -> VGroup:
        summary = self.data.g3_summary()
        control = self.panel(
            "1. Untouched control",
            ["derive lag and residual-frequency correction"],
            3.1,
            1.65,
            color=CYAN,
            body_size=18,
        )
        correction = self.panel(
            "2. Saved G3 correction",
            [
                f"lag: {summary['lag']:.0f} sample",
                f"residual: {summary['residual_hz']:.4f} Hz",
                f"spread: {summary['spread_hz']:.3f} Hz",
                f"windows: {summary['window_count']:.0f}",
            ],
            3.4,
            2.15,
            color=GREEN,
            body_size=18,
        )
        two_paths = self.panel(
            "3. Exact reuse",
            ["control path", "injected path", "no second fit"],
            3.1,
            1.90,
            color=AMBER,
            body_size=19,
        )
        control.move_to(LEFT * 4.4 + UP * 0.4)
        correction.move_to(ORIGIN + UP * 0.4)
        two_paths.move_to(RIGHT * 4.3 + UP * 0.4)
        arrows = VGroup(
            self.arrow_between(control, correction),
            self.arrow_between(correction, two_paths),
        )
        timeline = Line(LEFT * 5.3 + DOWN * 2.0, RIGHT * 5.3 + DOWN * 2.0, color=GRID, stroke_width=4)
        control_tick = Dot(timeline.get_left() + RIGHT * 1.4, color=CYAN)
        reuse_tick = Dot(timeline.get_right() + LEFT * 1.4, color=AMBER)
        timeline_label = _text("Control-derived correction → reused in both paired paths", 23, MUTED, 10.5)
        timeline_label.next_to(timeline, DOWN, buff=0.18)
        return VGroup(control, correction, two_paths, arrows, timeline, control_tick, reuse_tick, timeline_label)

    def cpi_visual(self) -> VGroup:
        cpi = RoundedRectangle(
            corner_radius=0.12,
            width=4.2,
            height=1.05,
            stroke_color=CYAN,
            stroke_width=3,
            fill_color=PANEL,
            fill_opacity=0.95,
        )
        cpi.move_to(LEFT * 4.4 + UP * 1.0)
        cpi_label = _text("100 ms coherent processing interval", 22, INK, 3.9).move_to(cpi)
        nominal = self.panel(
            "Nominal Fourier scale",
            ["1 / T = 10 Hz", "from a 100 ms CPI"],
            3.0,
            1.45,
            color=GREEN,
            body_size=20,
        )
        nominal.move_to(ORIGIN + UP * 1.0)
        display = self.panel(
            "Saved display grid",
            ["3.75 Hz Doppler spacing", "coordinate sampling ≠ resolution"],
            3.4,
            1.45,
            color=AMBER,
            body_size=19,
        )
        display.move_to(RIGHT * 4.45 + UP * 1.0)
        arrows = VGroup(self.arrow_between(cpi, nominal), self.arrow_between(nominal, display))
        caf = self.panel(
            "Conceptual CAF-power flow",
            [
                "reference × surveillance",
                "delay and Doppler coordinates",
                "power-map display",
                "no formal signed equation shown",
            ],
            7.8,
            2.25,
            color=BLUE,
            body_size=21,
        )
        caf.move_to(DOWN * 1.55)
        mini_grid = VGroup(
            *[
                Line(LEFT * 2.6 + RIGHT * step + DOWN * 1.55, LEFT * 2.6 + RIGHT * step + UP * 0.35, color=GRID, stroke_width=1)
                for step in np.linspace(0, 5.2, 7)
            ],
            *[
                Line(LEFT * 2.6 + DOWN * 1.55 + UP * step, RIGHT * 2.6 + DOWN * 1.55 + UP * step, color=GRID, stroke_width=1)
                for step in np.linspace(0, 1.9, 5)
            ],
        )
        mini_grid.move_to(caf.get_center() + DOWN * 0.25)
        return VGroup(cpi, cpi_label, nominal, display, arrows, caf, mini_grid)

    def mitigation_visual(self) -> VGroup:
        summary = self.data.trajectory_summary("45km_positive_control")
        marker = (summary["delay_us"], summary["doppler_hz"])
        panels = []
        titles = (
            ("No mitigation", "none", BLUE),
            ("Conservative LMS", "conservative_lms", GREEN),
            ("Aggressive LMS", "aggressive_lms", AMBER),
        )
        for title, candidate, color in titles:
            view = self.data.view(
                "45km_positive_control",
                "detector_region",
                "field_plus_geo_target",
                candidate,
            )
            panel = self.map_panel(
                title,
                view,
                3.85,
                4.0,
                marker=marker,
                marker_color=color,
                subtitle="saved injected detector-region power",
            )
            panels.append(panel)
        row = Group(*panels).arrange(RIGHT, buff=0.35)
        row.move_to(UP * 0.25)
        legend = self.panel(
            "Green/orange/blue dot is a post-hoc truth marker for explanation only",
            ["The detector did not use this marker to generate candidates."],
            10.4,
            1.15,
            color=PURPLE,
            body_size=19,
        )
        legend.move_to(DOWN * 2.7)
        return Group(row, legend)

    def detector_support_visual(self) -> VGroup:
        near = self.data.trajectory_summary("15km_detector_ineligible")
        target_view = self.data.view(
            "15km_detector_ineligible",
            "target_centered",
            "field_plus_geo_target",
            "conservative_lms",
        )
        map_panel = self.map_panel(
            "Retained 15 km target-centered compact view",
            target_view,
            4.25,
            3.8,
            marker=(near["delay_us"], near["doppler_hz"]),
            marker_color=AMBER,
            subtitle="saved local physics-map detail",
        )
        # Keep the detector card above the persistent caption band while
        # preserving a clear gap below the map/support row.
        map_panel.move_to(LEFT * 4.3 + UP * 0.80)
        support = self.support_visual()
        support.scale(0.86)
        support.move_to(RIGHT * 2.7 + UP * 0.80)
        geometry = self.data.geometry
        detector_note = self.panel(
            "Frozen detector geometry",
            [
                f"delay: {geometry['cut_delay_limits_us'][0]:.0f} to {geometry['cut_delay_limits_us'][1]:.0f} µs",
                f"Doppler: ±{geometry['cut_doppler_limits_hz'][1]:.0f} Hz • {geometry['actual_cut_count']:,} CUTs",
                "CA-CFAR: 320 training cells • NMS 7×3 • Pfa = 10⁻³ design input",
            ],
            11.9,
            1.35,
            color=CYAN,
            body_size=16,
        )
        detector_note.move_to(DOWN * 1.88)
        return Group(map_panel, support, detector_note)

    def association_visual(self) -> VGroup:
        detection = self.panel(
            "Truth-blind detector",
            ["fixed CFAR", "fixed NMS", "candidate detections"],
            3.0,
            1.65,
            color=CYAN,
            body_size=19,
        )
        lock = _text("truth remains hidden\nwhile candidates are generated", 18, MUTED, 2.8)
        association = self.panel(
            "Post-hoc association",
            ["one-to-one truth matching", "after detection generation"],
            3.1,
            1.65,
            color=PURPLE,
            body_size=19,
        )
        detection.move_to(LEFT * 4.4 + UP * 1.6)
        lock.move_to(LEFT * 0.65 + UP * 1.6)
        association.move_to(RIGHT * 3.7 + UP * 1.6)
        arrows = VGroup(
            Arrow(detection.get_right(), lock.get_left(), buff=0.16, color=CYAN, stroke_width=4),
            Arrow(lock.get_right(), association.get_left(), buff=0.16, color=PURPLE, stroke_width=4),
        )
        outcome_45 = self.panel(
            "45 km outcome",
            [
                "eligible and evaluated",
                "criterion passed at Pfa = 10⁻³",
                "diagnostic only",
            ],
            4.9,
            1.9,
            color=GREEN,
            body_size=19,
        )
        outcome_15 = self.panel(
            "15 km outcome",
            [
                "physics-map valid",
                "outside detector support",
                "not evaluated — not missed",
            ],
            4.9,
            1.9,
            color=AMBER,
            body_size=19,
        )
        # Reserve the lower visual band for the source card and caption.
        outcome_45.move_to(LEFT * 3.2 + DOWN * 0.25)
        outcome_15.move_to(RIGHT * 3.2 + DOWN * 0.25)
        source_lines = [_text(line, 15, MUTED, 11.7) for line in SOURCE_CARD]
        source_group = VGroup(*source_lines).arrange(DOWN, aligned_edge=LEFT, buff=0.04)
        source_box = RoundedRectangle(
            corner_radius=0.08,
            width=max(11.9, source_group.get_width() + 0.34),
            height=source_group.get_height() + 0.24,
            stroke_color="#405D78",
            stroke_width=1,
            fill_color="#07111C",
            fill_opacity=0.90,
        )
        source_group.move_to(source_box)
        source_card = VGroup(source_box, source_group)
        source_card.move_to(DOWN * 2.0)
        return VGroup(
            detection,
            lock,
            association,
            arrows,
            outcome_45,
            outcome_15,
            source_card,
        )

    def construct(self) -> None:
        self.chapter(SCENES[0], self.claim_boundary_visual())
        self.chapter(SCENES[1], self.geometry_visual())
        self.chapter(SCENES[2], self.paired_input_visual())
        self.chapter(SCENES[3], self.g3_visual())
        self.chapter(SCENES[4], self.cpi_visual())
        self.chapter(SCENES[5], self.mitigation_visual())
        self.chapter(SCENES[6], self.detector_support_visual())
        self.chapter(SCENES[7], self.association_visual())


class SmokeGeometryMapCfar(TrialScene):
    """Short isolated smoke render that exercises geometry, map images, and CFAR support."""

    def construct(self) -> None:
        geometry = self.geometry_visual()
        map_view = self.data.view(
            "45km_positive_control",
            "detector_region",
            "field_plus_geo_target",
            "conservative_lms",
        )
        summary = self.data.trajectory_summary("45km_positive_control")
        map_panel = self.map_panel(
            "45 km compact detector-region power",
            map_view,
            4.2,
            3.8,
            marker=(summary["delay_us"], summary["doppler_hz"]),
            subtitle="saved compact view",
        )
        geometry.scale(0.67)
        geometry.move_to(LEFT * 3.4 + UP * 0.2)
        map_panel.move_to(RIGHT * 3.7 + UP * 0.25)
        support_note = self.panel(
            "CFAR/NMS smoke check",
            ["fixed delay −1200 to −150 µs", "fixed Doppler ±750 Hz • 12,832 CUTs"],
            11.5,
            1.25,
            color=CYAN,
            body_size=20,
        )
        support_note.move_to(DOWN * 2.65)
        title = _text("ManimGL smoke: geometry + compact map + frozen detector", 29, CYAN, 13.0)
        title.to_edge(UP, buff=0.25)
        caption = self.caption_card(
            "Smoke render only: validates the isolated data path and visual primitives."
        )
        self.play(FadeIn(title), FadeIn(geometry), FadeIn(map_panel), FadeIn(support_note), FadeIn(caption), run_time=1.0)
        self.wait(8.0)
        self.play(FadeOut(Group(title, geometry, map_panel, support_note, caption)), run_time=1.0)


class PreflightAllChapters(FieldBackgroundTrial):
    """Construct every visual without timing waits; used before a full render."""

    def construct(self) -> None:
        builders = (
            self.claim_boundary_visual,
            self.geometry_visual,
            self.paired_input_visual,
            self.g3_visual,
            self.cpi_visual,
            self.mitigation_visual,
            self.detector_support_visual,
            self.association_visual,
        )
        for build_visual in builders:
            visual = build_visual()
            self.add(visual, self.caption_card("Preflight: caption styling and chapter visual."))
            self.clear()
