"""Standalone 15-minute ManimGL sequel about map reading and detector support.

All maps, waveforms, and diagrams in this file are analytic/code-drawn. The
only saved evidence read at render time is ``compact_geometry.json``, which
contains scalar WGS-84 geometry and source hashes extracted by the local
MATLAB-only extractor. The scene neither calls MATLAB nor replays the
pipeline, changes detector support, creates ``objectDetection``, or tracks.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import numpy as np

DEEP_DIVE_2_ROOT = Path(__file__).resolve().parent
if str(DEEP_DIVE_2_ROOT) not in sys.path:
    sys.path.insert(0, str(DEEP_DIVE_2_ROOT))

from manimlib import *  # noqa: E402,F403

from citation_cards import REFERENCES_CARD, SOURCE_CARDS
from video_contract import CHAPTERS


DATA_ROOT = DEEP_DIVE_2_ROOT / "deep_dive_2_data_v1"
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


class DeepDive2Data:
    """Read the sequel's own scalar evidence and analytic teaching arrays."""

    def __init__(self) -> None:
        self.geometry = json.loads(
            (DATA_ROOT / "compact_geometry.json").read_text(encoding="utf-8")
        )
        self.analytic = json.loads(
            (DATA_ROOT / "analytic_demo.json").read_text(encoding="utf-8")
        )

    def scenario(self, source_id: str) -> dict[str, Any]:
        return next(
            item
            for item in self.geometry["Scenarios"]
            if item["SourceId"] == source_id
        )


class DeepDive2Scene(Scene):
    """Shared layout plus analytic visual helpers for the sequel."""

    def setup(self) -> None:
        super().setup()
        self.camera.fps = int(self.camera.fps)
        self.camera.background_color = BACKGROUND
        self.data = DeepDive2Data()

    def panel(
        self,
        title: str,
        lines: list[str],
        width: float,
        height: float,
        color: str = CYAN,
        body_size: float = 20,
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
        title_text = _text(title, 23, color, width - 0.36)
        title_text.next_to(box.get_top(), DOWN, buff=0.16)
        body = VGroup(*[_text(line, body_size, INK, width - 0.45) for line in lines])
        body.arrange(DOWN, aligned_edge=LEFT, buff=0.11)
        body.next_to(title_text, DOWN, buff=0.14)
        return VGroup(box, title_text, body)

    def caption_card(self, content: str) -> VGroup:
        caption = _text(content, 22, INK, 12.35)
        plate = RoundedRectangle(
            corner_radius=0.12,
            width=max(12.55, caption.get_width() + 0.55),
            height=caption.get_height() + 0.42,
            stroke_color="#31516D",
            stroke_width=1.5,
            fill_color="#06101B",
            fill_opacity=0.97,
        )
        caption.move_to(plate)
        group = VGroup(plate, caption)
        group.to_edge(DOWN, buff=0.14)
        return group

    def source_card(self, source_id: str) -> Text:
        return _text(SOURCE_CARDS[source_id], 15, MUTED, 13.0)

    def chapter(self, chapter_spec: dict[str, Any], visual: Mobject) -> None:
        """Hold a four-beat teaching visual for its exact allotted duration."""

        header = _text(chapter_spec["title"], 30, CYAN, 13.2)
        header.to_edge(UP, buff=0.14)
        source = self.source_card(chapter_spec["source"])
        source.next_to(header, DOWN, buff=0.04)
        visual.shift(DOWN * 0.2)
        captions = chapter_spec["captions"]
        caption = self.caption_card(captions[0])

        frame_rate = int(self.camera.fps)
        intro_s = 1.0
        first_caption_s = 0.4
        caption_change_s = 0.4
        outro_s = 1.0
        fixed_frame_count = int(
            round(
                (
                    intro_s
                    + first_caption_s
                    + (len(captions) - 1) * caption_change_s
                    + outro_s
                )
                * frame_rate
            )
        )
        available_hold_frames = (
            int(chapter_spec["duration_s"]) * frame_rate - fixed_frame_count
        )
        hold_base_frames, extra_frames = divmod(
            available_hold_frames, len(captions)
        )
        hold_frames = [
            hold_base_frames + int(index < extra_frames)
            for index in range(len(captions))
        ]

        self.play(FadeIn(header), FadeIn(source), FadeIn(visual), run_time=intro_s)
        self.play(FadeIn(caption), run_time=first_caption_s)
        self.wait(hold_frames[0] / frame_rate)
        for caption_index, next_caption in enumerate(captions[1:], start=1):
            replacement = self.caption_card(next_caption)
            self.play(FadeTransform(caption, replacement), run_time=caption_change_s)
            caption = replacement
            self.wait(hold_frames[caption_index] / frame_rate)
        self.play(FadeOut(VGroup(header, source, visual, caption)), run_time=outro_s)

    def arrow_between(self, left: Mobject, right: Mobject, color: str = CYAN) -> Arrow:
        return Arrow(
            left.get_right(),
            right.get_left(),
            buff=0.14,
            color=color,
            stroke_width=4,
        )

    def waveform(
        self,
        samples: list[float],
        origin: np.ndarray,
        width: float,
        height: float,
        color: str,
        label: str,
    ) -> VGroup:
        baseline = Line(origin, origin + RIGHT * width, color=GRID, stroke_width=1.5)
        vertical = Line(
            origin + UP * height / 2,
            origin + DOWN * height / 2,
            color=GRID,
            stroke_width=1.5,
        )
        points = [
            origin
            + RIGHT * width * index / (len(samples) - 1)
            + UP * height * 0.42 * value
            for index, value in enumerate(samples)
        ]
        trace = VMobject(color=color, stroke_width=3)
        trace.set_points_smoothly(points)
        trace_label = _text(label, 16, color, width)
        trace_label.next_to(baseline, DOWN, buff=0.1)
        return VGroup(baseline, vertical, trace, trace_label)

    def _analytic_map(
        self,
        title: str,
        direct_strength: float,
        target_strength: float,
        color: str,
        note: str,
    ) -> VGroup:
        """Create a code-drawn, explicitly non-recorded teaching map."""

        frame = RoundedRectangle(
            corner_radius=0.08,
            width=3.95,
            height=2.85,
            stroke_color=color,
            stroke_width=2,
            fill_color=PANEL_DARK,
            fill_opacity=0.96,
        )
        rows, columns = 9, 12
        cells = VGroup()
        for row in range(rows):
            for column in range(columns):
                delay = (column - 9.5) / 1.25
                doppler = (row - 4.0) / 0.85
                direct = direct_strength * np.exp(-(delay**2 + doppler**2))
                target = target_strength * np.exp(
                    -(
                        ((column - 3.2) / 1.25) ** 2
                        + ((row - 2.1) / 1.0) ** 2
                    )
                )
                value = min(1.0, 0.08 + direct + target)
                cell = Square(
                    side_length=0.25,
                    stroke_width=0.2,
                    stroke_color=PANEL_DARK,
                    fill_color=interpolate_color(BLUE, AMBER, value),
                    fill_opacity=0.98,
                )
                cell.move_to(
                    frame.get_center()
                    + RIGHT * (column - (columns - 1) / 2) * 0.27
                    + DOWN * (row - (rows - 1) / 2) * 0.27
                )
                cells.add(cell)
        heading = _text(title, 19, color, 3.65)
        heading.next_to(frame, UP, buff=0.08)
        annotation = _text(note, 14, MUTED, 3.6)
        annotation.next_to(frame, DOWN, buff=0.08)
        return VGroup(frame, cells, heading, annotation)

    def evidence_boundary_visual(self) -> VGroup:
        field = self.panel(
            "Recorded field inputs",
            ["reference x_ref", "surveillance x_surv,field", "same capture background"],
            3.55,
            2.05,
            PURPLE,
            18,
        )
        control = self.panel(
            "Control path",
            ["x_ref unchanged", "x_surv unchanged", "truth-blind processing"],
            3.3,
            2.0,
            CYAN,
            18,
        )
        injected = self.panel(
            "Injected path",
            ["x_ref unchanged", "x_surv + e_echo", "same processing settings"],
            3.45,
            2.0,
            AMBER,
            18,
        )
        field.move_to(LEFT * 4.45 + UP * 0.4)
        control.move_to(LEFT * 0.3 + UP * 1.35)
        injected.move_to(LEFT * 0.3 + DOWN * 1.35)
        arrows = VGroup(
            self.arrow_between(field, control, CYAN),
            self.arrow_between(field, injected, AMBER),
        )
        intervention = self.panel(
            "Declared intervention",
            ["x_surv,inj = x_surv,field + e_echo", "Only surveillance changes."],
            5.2,
            1.4,
            BLUE,
            18,
        )
        intervention.move_to(RIGHT * 4.1 + UP * 1.0)
        boundary = self.panel(
            "Claim boundary",
            ["No field-aircraft detection", "No product selection • no tracking"],
            5.2,
            1.3,
            RED,
            18,
        )
        boundary.move_to(RIGHT * 4.1 + DOWN * 1.45)
        return VGroup(field, control, injected, arrows, intervention, boundary)

    def geometry_visual(self) -> VGroup:
        baseline = Line(LEFT * 5.7 + DOWN * 2.15, RIGHT * 5.7 + DOWN * 2.15, color=GRID)
        tx = Dot(LEFT * 3.9 + DOWN * 2.15, color=PURPLE, radius=0.11)
        rx = Dot(LEFT * 1.7 + DOWN * 2.15, color=CYAN, radius=0.11)
        target = Dot(RIGHT * 0.9 + UP * 1.5, color=GREEN, radius=0.13)
        direct = DashedLine(tx.get_center(), rx.get_center(), color=MUTED)
        path_1 = DashedLine(tx.get_center(), target.get_center(), color=GREEN)
        path_2 = DashedLine(target.get_center(), rx.get_center(), color=GREEN)
        labels = VGroup(
            _text("Tx", 19, PURPLE).next_to(tx, DOWN, buff=0.08),
            _text("Rx", 19, CYAN).next_to(rx, DOWN, buff=0.08),
            _text("target", 19, GREEN).next_to(target, UP, buff=0.08),
            _text("B", 17, MUTED).next_to(direct, DOWN, buff=0.08),
            _text("R_T", 17, GREEN).next_to(path_1, UP, buff=0.08),
            _text("R_R", 17, GREEN).next_to(path_2, RIGHT, buff=0.08),
        )
        physics = self.panel(
            "Physical geometry",
            ["r_excess = R_T + R_R − B  [m]", "tau_excess = r_excess / c  [s]", "path-rate sets bistatic Doppler"],
            5.7,
            2.3,
            GREEN,
            18,
        )
        physics.move_to(RIGHT * 3.45 + UP * 1.0)
        convention = self.panel(
            "This project's display convention",
            ["tau_display = −tau_excess", "f_display = −f_bistatic"],
            5.7,
            1.3,
            AMBER,
            18,
        )
        convention.move_to(RIGHT * 3.45 + DOWN * 1.45)
        return VGroup(
            baseline,
            direct,
            path_1,
            path_2,
            tx,
            rx,
            target,
            labels,
            physics,
            convention,
        )

    def echo_visual(self) -> VGroup:
        seed = self.waveform(
            self.data.analytic["reference_real"],
            LEFT * 5.45 + UP * 1.25,
            3.0,
            1.1,
            PURPLE,
            "reference-derived seed",
        )
        conditioning = self.panel(
            "Condition",
            ["echo-only copy", "RMS match to seed"],
            2.55,
            1.45,
            CYAN,
            18,
        )
        propagation = self.panel(
            "Propagate",
            ["delay", "Doppler", "relative amplitude"],
            2.65,
            1.7,
            GREEN,
            18,
        )
        injection = self.panel(
            "Inject",
            ["surveillance only", "field background stays present"],
            3.0,
            1.45,
            AMBER,
            18,
        )
        conditioning.move_to(LEFT * 1.65 + UP * 1.25)
        propagation.move_to(RIGHT * 1.45 + UP * 1.2)
        injection.move_to(RIGHT * 4.65 + UP * 1.2)
        echo = self.waveform(
            self.data.analytic["aligned_real"],
            LEFT * 2.1 + DOWN * 1.65,
            5.2,
            1.2,
            AMBER,
            "geometry-driven surveillance delta e_echo",
        )
        arrows = VGroup(
            self.arrow_between(seed, conditioning, PURPLE),
            self.arrow_between(conditioning, propagation, CYAN),
            self.arrow_between(propagation, injection, GREEN),
            Arrow(injection.get_bottom(), echo.get_top(), buff=0.14, color=AMBER),
        )
        gain = self.panel(
            "Relative scenario amplitude",
            ["a = 10^(G_dB/20)", "−18 dB is not a calibrated RCS or received-power model"],
            8.8,
            1.25,
            BLUE,
            17,
        )
        gain.move_to(RIGHT * 1.0 + DOWN * 2.35)
        return VGroup(seed, conditioning, propagation, injection, echo, arrows, gain)

    def synchronization_visual(self) -> VGroup:
        reference = self.waveform(
            self.data.analytic["reference_real"],
            LEFT * 5.65 + UP * 1.8,
            4.1,
            1.0,
            PURPLE,
            "reference x[n]",
        )
        before = self.waveform(
            self.data.analytic["misaligned_real"],
            LEFT * 5.65 + DOWN * 0.0,
            4.1,
            1.0,
            AMBER,
            "surveillance before alignment",
        )
        after = self.waveform(
            self.data.analytic["aligned_real"],
            LEFT * 5.65 + DOWN * 1.8,
            4.1,
            1.0,
            GREEN,
            "surveillance after correction",
        )
        alignment = self.panel(
            "Integer alignment",
            ["k_hat = argmax |r_xy[k]|", "finddelay + normalized xcorr"],
            4.9,
            1.55,
            CYAN,
            18,
        )
        alignment.move_to(RIGHT * 3.25 + UP * 1.5)
        phase = self.panel(
            "Residual phase correction",
            ["phi(t) ≈ phi_0 + 2πΔf t", "apply unit-magnitude phase ramp", "reuse control-derived correction"],
            5.15,
            1.85,
            GREEN,
            17,
        )
        phase.move_to(RIGHT * 3.15 + DOWN * 0.8)
        before_label = _text("misaligned peaks / phase slope", 16, AMBER, 4.1)
        before_label.next_to(before, RIGHT, buff=0.15)
        after_label = _text("corrected coherence", 16, GREEN, 4.1)
        after_label.next_to(after, RIGHT, buff=0.15)
        return VGroup(
            reference,
            before,
            after,
            alignment,
            phase,
            before_label,
            after_label,
        )

    def cpi_visual(self) -> VGroup:
        full = self.panel(
            "Whole corrected repetition",
            ["F_s = 6.144 MHz", "filtering begins before CPI selection"],
            3.25,
            1.6,
            PURPLE,
            18,
        )
        reduce = self.panel(
            "Filter and reduce",
            ["resample", "F_s' = F_s / q", "q = 200"],
            2.85,
            1.8,
            CYAN,
            18,
        )
        select = self.panel(
            "Select map CPI",
            ["100 ms", "3,072 samples", "1 / T_CPI = 10 Hz"],
            3.05,
            1.8,
            GREEN,
            18,
        )
        full.move_to(LEFT * 4.45 + UP * 0.85)
        reduce.move_to(LEFT * 0.65 + UP * 0.85)
        select.move_to(RIGHT * 3.15 + UP * 0.85)
        arrows = VGroup(
            self.arrow_between(full, reduce, PURPLE),
            self.arrow_between(reduce, select, CYAN),
        )
        sequence = _text("filter complete repetition  →  reduce rate  →  select CPI", 23, INK, 11.4)
        sequence.move_to(UP * 2.45)
        limitation = self.panel(
            "Resolution limit",
            ["Saved coordinate spacing is not an independent physical-resolution claim.", "Finite duration and bandwidth still constrain separability."],
            10.6,
            1.45,
            AMBER,
            19,
        )
        limitation.move_to(DOWN * 1.6)
        return VGroup(full, reduce, select, arrows, sequence, limitation)

    def mitigation_visual(self) -> VGroup:
        before = self._analytic_map(
            "Before",
            0.95,
            0.62,
            AMBER,
            "dominant direct-path / near-zero-Doppler structure",
        )
        conservative = self._analytic_map(
            "Conservative mitigation",
            0.45,
            0.65,
            GREEN,
            "leakage reduced; target-like lobe retained",
        )
        aggressive = self._analytic_map(
            "Aggressive mitigation",
            0.16,
            0.24,
            RED,
            "stronger suppression; target-like lobe weakened",
        )
        before.move_to(LEFT * 4.35 + UP * 0.25)
        conservative.move_to(UP * 0.25)
        aggressive.move_to(RIGHT * 4.35 + UP * 0.25)
        equation = self.panel(
            "Conceptual residual",
            ["e[n] = d[n] − d_hat[n]", "Only the residual candidate continues to map formation."],
            7.4,
            1.2,
            CYAN,
            18,
        )
        equation.move_to(LEFT * 2.65 + DOWN * 2.2)
        disclaimer = _text(
            "Analytic teaching patterns—not recorded maps and not a formal product decision.",
            17,
            MUTED,
            11.5,
        )
        disclaimer.move_to(RIGHT * 1.0 + DOWN * 2.2)
        return VGroup(before, conservative, aggressive, equation, disclaimer)

    def caf_visual(self) -> VGroup:
        map_panel = self._analytic_map(
            "Code-drawn CAF-power concept",
            0.15,
            0.9,
            GREEN,
            "rows: Doppler • columns: delay",
        )
        map_panel.scale(1.25)
        map_panel[-1].next_to(map_panel[2], UP, buff=0.08)
        map_panel.move_to(RIGHT * 3.25 + UP * 0.2)
        input_panel = self.panel(
            "Hypothesis matching",
            ["synchronized reference", "candidate surveillance", "delay and Doppler hypotheses"],
            3.65,
            1.75,
            PURPLE,
            18,
        )
        input_panel.move_to(LEFT * 4.2 + UP * 1.25)
        ambgfun_panel = self.panel(
            "Implementation",
            ["ambgfun", "magnitude → power", "P(tau, f) = |A(tau, f)|²"],
            3.65,
            1.75,
            CYAN,
            18,
        )
        ambgfun_panel.move_to(LEFT * 4.2 + DOWN * 1.2)
        arrow = Arrow(
            ambgfun_panel.get_right(),
            map_panel.get_left(),
            buff=0.18,
            color=CYAN,
            stroke_width=4,
        )
        caveat = self.panel(
            "CAF equation boundary",
            ["No signed or normalized CAF summation formula is shown.", "The displayed orientation is project-specific."],
            9.7,
            1.2,
            AMBER,
            18,
        )
        caveat.move_to(DOWN * 2.35)
        return VGroup(input_panel, ambgfun_panel, map_panel, arrow, caveat)

    def detector_visual(self) -> VGroup:
        frame = Rectangle(
            width=5.55,
            height=3.7,
            stroke_color="#7395B8",
            stroke_width=2,
            fill_color=PANEL_DARK,
            fill_opacity=0.96,
        )
        frame.move_to(LEFT * 3.55 + UP * 0.25)
        support = Rectangle(
            width=4.3,
            height=3.25,
            stroke_color=GREEN,
            stroke_width=3,
            fill_opacity=0.06,
            fill_color=GREEN,
        )
        support.move_to(frame.get_center() + LEFT * 0.32)
        labels = VGroup(
            _text("displayed delay [µs] →", 17, MUTED).next_to(frame, DOWN, buff=0.09),
            _text("displayed Doppler [Hz]", 17, MUTED).rotate(PI / 2).next_to(frame, LEFT, buff=0.1),
            _text("frozen detector support", 17, GREEN).next_to(support, UP, buff=0.06),
            _text("−1200", 14, MUTED).next_to(support.get_left(), DOWN, buff=0.05),
            _text("−150", 14, MUTED).next_to(support.get_right(), DOWN, buff=0.05),
        )
        candidate_dots = VGroup(
            Dot(support.get_center() + LEFT * 1.25 + UP * 0.55, color=AMBER),
            Dot(support.get_center() + LEFT * 0.25 + DOWN * 0.7, color=AMBER),
            Dot(support.get_center() + RIGHT * 0.9 + UP * 1.0, color=AMBER),
        )
        flow = self.panel(
            "Truth-blind candidate generation",
            ["1. fixed search rectangle", "2. P_CUT > alpha(Pfa) · P_hat_noise", "3. 7×3 NMS retains sparse peaks"],
            5.4,
            2.0,
            CYAN,
            18,
        )
        flow.move_to(RIGHT * 3.55 + UP * 0.7)
        nms = self.panel(
            "Local decision scope",
            ["CFAR estimates local background from training cells.", "Pfa is a design input—not measured field false-alarm rate."],
            5.4,
            1.55,
            AMBER,
            17,
        )
        nms.move_to(RIGHT * 3.55 + DOWN * 1.55)
        return VGroup(frame, support, labels, candidate_dots, flow, nms)

    def association_visual(self) -> VGroup:
        stage_1 = self.panel(
            "1. Candidate generation",
            ["truth-blind dots", "fixed support, CFAR, NMS"],
            3.55,
            1.5,
            AMBER,
            18,
        )
        stage_2 = self.panel(
            "2. Truth appears after",
            ["expected delay/Doppler", "allowed uncertainty window"],
            3.55,
            1.5,
            GREEN,
            18,
        )
        stage_3 = self.panel(
            "3. One-to-one labels",
            ["normalized association cost", "matchpairs"],
            3.55,
            1.5,
            CYAN,
            18,
        )
        stage_1.move_to(LEFT * 4.35 + UP * 1.2)
        stage_2.move_to(UP * 1.2)
        stage_3.move_to(RIGHT * 4.35 + UP * 1.2)
        arrows = VGroup(
            self.arrow_between(stage_1, stage_2, GREEN),
            self.arrow_between(stage_2, stage_3, CYAN),
        )
        candidate_area = Rectangle(
            width=8.5,
            height=2.25,
            stroke_color="#7395B8",
            stroke_width=1.5,
            fill_color=PANEL_DARK,
            fill_opacity=0.96,
        )
        candidate_area.move_to(DOWN * 1.15)
        candidates = VGroup(
            Dot(candidate_area.get_center() + LEFT * 2.8 + DOWN * 0.35, color=AMBER),
            Dot(candidate_area.get_center() + LEFT * 0.7 + UP * 0.4, color=AMBER),
            Dot(candidate_area.get_center() + RIGHT * 1.25 + UP * 0.05, color=AMBER),
        )
        truth = Circle(radius=0.32, color=GREEN, stroke_width=3)
        truth.move_to(candidates[2].get_center() + RIGHT * 0.22 + UP * 0.08)
        match = Line(candidates[2].get_center(), truth.get_center(), color=GREEN, stroke_width=3)
        cost = _text(
            "cost = sqrt((Δtau / h_tau)² + (Δf / h_f)²)",
            21,
            INK,
            10.8,
        )
        cost.move_to(DOWN * 2.55)
        return VGroup(
            stage_1,
            stage_2,
            stage_3,
            arrows,
            candidate_area,
            candidates,
            truth,
            match,
            cost,
        )

    def _plan_point(
        self,
        frame: Rectangle,
        east_km: float,
        north_km: float,
    ) -> np.ndarray:
        east_min, east_max = -5.0, 12.0
        north_min, north_max = -4.0, 49.0
        return (
            frame.get_corner(DL)
            + RIGHT * frame.get_width() * (east_km - east_min) / (east_max - east_min)
            + UP * frame.get_height() * (north_km - north_min) / (north_max - north_min)
        )

    def _coordinate_point(
        self,
        frame: Rectangle,
        delay_us: float,
        doppler_hz: float,
    ) -> np.ndarray:
        delay_min, delay_max = -1250.0, 50.0
        doppler_min, doppler_max = -750.0, 750.0
        return (
            frame.get_corner(DL)
            + RIGHT
            * frame.get_width()
            * (delay_us - delay_min)
            / (delay_max - delay_min)
            + UP
            * frame.get_height()
            * (doppler_hz - doppler_min)
            / (doppler_max - doppler_min)
        )

    def final_cases_visual(self) -> VGroup:
        geometry = self.data.geometry
        scenario_45 = self.data.scenario("S11")
        scenario_15 = self.data.scenario("S12")

        plan = Rectangle(
            width=4.7,
            height=3.85,
            stroke_color="#7395B8",
            stroke_width=2,
            fill_color=PANEL_DARK,
            fill_opacity=0.96,
        )
        plan.move_to(LEFT * 4.55 + UP * 0.35)
        rx = Dot(self._plan_point(plan, 0.0, 0.0), color=CYAN, radius=0.095)
        tx_geometry = geometry["Transmitter"]
        tx = Dot(
            self._plan_point(plan, tx_geometry["East_km"], tx_geometry["North_km"]),
            color=PURPLE,
            radius=0.095,
        )
        point_45 = scenario_45["InitialWaypoint"]
        point_15 = scenario_15["InitialWaypoint"]
        target_45 = Dot(
            self._plan_point(plan, point_45["East_km"], point_45["North_km"]),
            color=GREEN,
            radius=0.1,
        )
        target_15 = Dot(
            self._plan_point(plan, point_15["East_km"], point_15["North_km"]),
            color=AMBER,
            radius=0.1,
        )
        plan_labels = VGroup(
            _text("Receiver-local East/North plan view", 17, CYAN, 4.5).next_to(plan, UP, buff=0.07),
            _text("E [km] →", 15, MUTED).next_to(plan, DOWN, buff=0.07),
            _text("N [km]", 15, MUTED).rotate(PI / 2).next_to(plan, LEFT, buff=0.07),
            _text("Rx origin", 14, CYAN).next_to(rx, DOWN + RIGHT, buff=0.07),
            _text("Tx", 14, PURPLE).next_to(tx, UP + RIGHT, buff=0.07),
            _text(
                "45 km receiver-local\nnorth-offset scenario",
                11,
                GREEN,
                2.2,
            ).next_to(target_45, LEFT + DOWN, buff=0.07),
            _text(
                "15 km receiver-local\nnorth-offset scenario",
                11,
                AMBER,
                2.2,
            ).next_to(target_15, LEFT + DOWN, buff=0.07),
            _text("altitude omitted", 13, MUTED).next_to(plan, DOWN, buff=0.3),
        )

        coordinate_map = Rectangle(
            width=6.45,
            height=3.85,
            stroke_color="#7395B8",
            stroke_width=2,
            fill_color=PANEL_DARK,
            fill_opacity=0.96,
        )
        coordinate_map.move_to(RIGHT * 3.1 + UP * 0.35)
        support_left = self._coordinate_point(coordinate_map, -1200.0, 0.0)[0]
        support_right = self._coordinate_point(coordinate_map, -150.0, 0.0)[0]
        support = Rectangle(
            width=support_right - support_left,
            height=coordinate_map.get_height(),
            stroke_color=GREEN,
            stroke_width=2.5,
            fill_color=GREEN,
            fill_opacity=0.06,
        )
        support.move_to(
            np.array(
                [
                    (support_left + support_right) / 2,
                    coordinate_map.get_center()[1],
                    0.0,
                ]
            )
        )
        marker_45 = Dot(
            self._coordinate_point(
                coordinate_map,
                scenario_45["DisplayDelay_us"],
                scenario_45["DisplayDoppler_Hz"],
            ),
            color=GREEN,
            radius=0.1,
        )
        marker_15 = Dot(
            self._coordinate_point(
                coordinate_map,
                scenario_15["DisplayDelay_us"],
                scenario_15["DisplayDoppler_Hz"],
            ),
            color=AMBER,
            radius=0.1,
        )
        map_labels = VGroup(
            _text(
                "Range–Doppler (excess-delay–Doppler) coordinate map",
                17,
                CYAN,
                6.2,
            ).next_to(coordinate_map, UP, buff=0.07),
            _text("schematic—not a saved ambiguity image", 13, MUTED, 6.2).next_to(
                coordinate_map, UP, buff=0.34
            ),
            _text("displayed delay [µs] →", 15, MUTED).next_to(
                coordinate_map, DOWN, buff=0.07
            ),
            _text("displayed Doppler [Hz]", 15, MUTED).rotate(PI / 2).next_to(
                coordinate_map, LEFT, buff=0.07
            ),
            _text("−1250", 13, MUTED).next_to(coordinate_map.get_left(), DOWN, buff=0.05),
            _text("+50", 13, MUTED).next_to(coordinate_map.get_right(), DOWN, buff=0.05),
            _text("frozen detector rectangle", 14, GREEN).next_to(
                support.get_top(), DOWN, buff=0.06
            ),
            _text(
                "45 km receiver-local\nnorth-offset scenario\n(−269.5 µs, +591.9 Hz)",
                10,
                GREEN,
                2.75,
            ).next_to(
                marker_45, LEFT + DOWN, buff=0.07
            ),
            _text(
                "15 km receiver-local\nnorth-offset scenario\n(−76.5 µs, +540.5 Hz)",
                10,
                AMBER,
                2.65,
            ).next_to(
                marker_15, LEFT + UP, buff=0.07
            ),
        )
        convention = self.panel(
            "Convention and boundary",
            [
                "tau_display = −tau_excess     f_display = −f_bistatic",
                "Physical excess delay is positive; negative displayed delay is intentional.",
                "This project's display convention—not a universal passive-bistatic or CAF sign rule.",
            ],
            12.6,
            1.3,
            AMBER,
            14,
        )
        convention.move_to(UP * -2.3)
        return VGroup(
            plan,
            rx,
            tx,
            target_45,
            target_15,
            plan_labels,
            coordinate_map,
            support,
            marker_45,
            marker_15,
            map_labels,
            convention,
        )


class ReadingPassiveBistaticMapDeepDive2(DeepDive2Scene):
    """A caption-led 900-second instructional sequel with no generated audio."""

    def construct(self) -> None:
        visuals = [
            self.evidence_boundary_visual(),
            self.geometry_visual(),
            self.echo_visual(),
            self.synchronization_visual(),
            self.cpi_visual(),
            self.mitigation_visual(),
            self.caf_visual(),
            self.detector_visual(),
            self.association_visual(),
            self.final_cases_visual(),
        ]
        for chapter_spec, visual in zip(CHAPTERS, visuals, strict=True):
            self.chapter(chapter_spec, visual)


class DeepDive2Smoke(DeepDive2Scene):
    """Fast visual smoke scene for key processing and final-case compositions."""

    def construct(self) -> None:
        mitigation = self.mitigation_visual()
        mitigation.scale(0.84)
        mitigation.shift(UP * 0.2)
        title = _text("Deep Dive 2 visual smoke: analytic mitigation patterns", 28, CYAN, 13.0)
        title.to_edge(UP, buff=0.18)
        self.add(title, mitigation)
        self.wait(1.0)
        self.remove(title, mitigation)

        final = self.final_cases_visual()
        final.scale(0.83)
        final.shift(UP * 0.15)
        title = _text("Deep Dive 2 visual smoke: linked geometry and detector boundary", 26, CYAN, 13.0)
        title.to_edge(UP, buff=0.18)
        self.add(title, final)
        self.wait(1.0)


class DeepDive2FinalCaseReview(DeepDive2Scene):
    """Static review frame using the same final-chapter layout as the render."""

    def construct(self) -> None:
        chapter_spec = CHAPTERS[-1]
        header = _text(chapter_spec["title"], 30, CYAN, 13.2)
        header.to_edge(UP, buff=0.14)
        source = self.source_card(chapter_spec["source"])
        source.next_to(header, DOWN, buff=0.04)
        visual = self.final_cases_visual()
        visual.shift(DOWN * 0.2)
        caption = self.caption_card(chapter_spec["captions"][1])
        self.add(header, source, visual, caption)
