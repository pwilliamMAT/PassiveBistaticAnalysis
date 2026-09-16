"""ManimGL scene for the math-first passive-bistatic deep dive.

All dynamic plots are analytic/code-drawn. Final 45 km and 15 km outcome
cards use only ``deep_dive_data_v1/evidence.json``. No raw IQ, full retained
map, MATLAB call, detector change, or pipeline rerun occurs here.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

import numpy as np

DEEP_DIVE_ROOT = Path(__file__).resolve().parent
if str(DEEP_DIVE_ROOT) not in sys.path:
    sys.path.insert(0, str(DEEP_DIVE_ROOT))

from manimlib import *  # noqa: E402

from citation_cards import REFERENCES_CARD, SOURCE_CARDS
from video_contract import CHAPTERS  # noqa: E402


DATA_ROOT = DEEP_DIVE_ROOT / "deep_dive_data_v1"
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


class DeepDiveData:
    """Read the local compact teaching package only."""

    def __init__(self) -> None:
        self.evidence = json.loads(
            (DATA_ROOT / "evidence.json").read_text(encoding="utf-8")
        )
        self.analytic = json.loads(
            (DATA_ROOT / "analytic_demo.json").read_text(encoding="utf-8")
        )

    def example(self, label: str) -> dict[str, Any]:
        return next(
            item for item in self.evidence["final_examples"] if item["label"] == label
        )


class DeepDiveScene(Scene):
    """Shared layout and code-drawn visual helpers."""

    def setup(self) -> None:
        super().setup()
        self.camera.fps = int(self.camera.fps)
        self.camera.background_color = BACKGROUND
        self.data = DeepDiveData()

    def panel(
        self,
        title: str,
        lines: list[str],
        width: float,
        height: float,
        color: str = CYAN,
        body_size: float = 21,
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
        title_text = _text(title, 24, color, width - 0.36)
        title_text.next_to(box.get_top(), DOWN, buff=0.18)
        body = VGroup(*[_text(line, body_size, INK, width - 0.45) for line in lines])
        body.arrange(DOWN, aligned_edge=LEFT, buff=0.12)
        body.next_to(title_text, DOWN, buff=0.18)
        return VGroup(box, title_text, body)

    def caption_card(self, content: str) -> VGroup:
        caption = _text(content, 24, INK, 12.2)
        plate = RoundedRectangle(
            corner_radius=0.12,
            width=max(12.35, caption.get_width() + 0.55),
            height=caption.get_height() + 0.45,
            stroke_color="#31516D",
            stroke_width=1.5,
            fill_color="#06101B",
            fill_opacity=0.96,
        )
        caption.move_to(plate)
        group = VGroup(plate, caption)
        group.to_edge(DOWN, buff=0.16)
        return group

    def source_card(self, source_id: str) -> Text:
        source_text = SOURCE_CARDS[source_id]
        card = _text(source_text, 15, MUTED, 13.0)
        return card

    def chapter(self, chapter_spec: dict[str, Any], visual: Mobject) -> None:
        """Render one chapter at its planned duration."""

        header = _text(chapter_spec["title"], 31, CYAN, 13.2)
        header.to_edge(UP, buff=0.16)
        source = self.source_card(chapter_spec["source"])
        source.next_to(header, DOWN, buff=0.05)
        visual.shift(DOWN * 0.22)
        captions = chapter_spec["captions"]
        caption = self.caption_card(captions[0])

        intro_s = 1.0
        first_caption_s = 0.4
        caption_change_s = 0.4
        outro_s = 1.0
        wait_s = (
            float(chapter_spec["duration_s"])
            - intro_s
            - first_caption_s
            - (len(captions) - 1) * caption_change_s
            - outro_s
        ) / len(captions)

        self.play(FadeIn(header), FadeIn(source), FadeIn(visual), run_time=intro_s)
        self.play(FadeIn(caption), run_time=first_caption_s)
        self.wait(wait_s)
        for next_caption in captions[1:]:
            replacement = self.caption_card(next_caption)
            self.play(FadeTransform(caption, replacement), run_time=caption_change_s)
            caption = replacement
            self.wait(wait_s)
        self.play(FadeOut(VGroup(header, source, visual, caption)), run_time=outro_s)

    def arrow_between(self, left: Mobject, right: Mobject, color: str = CYAN) -> Arrow:
        return Arrow(
            left.get_right(),
            right.get_left(),
            buff=0.16,
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
        trace_label = _text(label, 18, color, width)
        trace_label.next_to(baseline, DOWN, buff=0.12)
        return VGroup(baseline, vertical, trace, trace_label)

    def evidence_boundary_visual(self) -> VGroup:
        field = self.panel(
            "Recorded field inputs",
            ["reference x_ref", "surveillance x_surv,field", "same capture background"],
            3.6,
            2.15,
            PURPLE,
            19,
        )
        control = self.panel(
            "Control",
            ["x_ref unchanged", "x_surv unchanged", "truth-blind processing"],
            3.4,
            2.15,
            CYAN,
            19,
        )
        injected = self.panel(
            "Injected case",
            ["x_ref unchanged", "x_surv + e_echo", "same processing settings"],
            3.6,
            2.15,
            AMBER,
            19,
        )
        field.move_to(LEFT * 4.3 + UP * 0.45)
        control.move_to(LEFT * 0.1 + UP * 1.45)
        injected.move_to(LEFT * 0.1 + DOWN * 1.55)
        arrows = VGroup(
            self.arrow_between(field, control, CYAN),
            self.arrow_between(field, injected, AMBER),
        )
        formula = self.panel(
            "Declared intervention",
            ["x_surv,inj = x_surv,field + e_echo", "Only surveillance receives the synthetic delta."],
            5.1,
            1.55,
            BLUE,
            18,
        )
        formula.move_to(RIGHT * 4.25 + UP * 1.05)
        boundary = self.panel(
            "Claim boundary",
            ["No field-aircraft detection claim", "No detector retune • no tracking"],
            5.1,
            1.35,
            RED,
            18,
        )
        boundary.move_to(RIGHT * 4.25 + DOWN * 1.75)
        return VGroup(field, control, injected, arrows, formula, boundary)

    def geometry_visual(self) -> VGroup:
        baseline = Line(LEFT * 5.8 + DOWN * 2.2, RIGHT * 5.7 + DOWN * 2.2, color=GRID)
        tx = Dot(LEFT * 3.9 + DOWN * 2.2, color=PURPLE, radius=0.11)
        rx = Dot(LEFT * 1.7 + DOWN * 2.2, color=CYAN, radius=0.11)
        target = Dot(RIGHT * 1.1 + UP * 1.55, color=GREEN, radius=0.13)
        direct = DashedLine(tx.get_center(), rx.get_center(), color=MUTED)
        path_1 = DashedLine(tx.get_center(), target.get_center(), color=GREEN)
        path_2 = DashedLine(target.get_center(), rx.get_center(), color=GREEN)
        labels = VGroup(
            _text("Tx", 20, PURPLE).next_to(tx, DOWN, buff=0.1),
            _text("Rx", 20, CYAN).next_to(rx, DOWN, buff=0.1),
            _text("target", 20, GREEN).next_to(target, UP, buff=0.1),
            _text("B", 18, MUTED).next_to(direct, DOWN, buff=0.1),
            _text("R_T", 18, GREEN).next_to(path_1, UP, buff=0.1),
            _text("R_R", 18, GREEN).next_to(path_2, RIGHT, buff=0.1),
        )
        equation = self.panel(
            "Physical geometry",
            ["r_b = R_T + R_R - B  [m]", "tau_b = r_b / c  [s]", "|f_b| = |d(R_T + R_R)/dt| / lambda  [Hz]"],
            5.7,
            2.45,
            GREEN,
            19,
        )
        equation.move_to(RIGHT * 3.4 + UP * 1.0)
        convention = self.panel(
            "Saved display convention",
            ["display delay = -excess delay", "display Doppler = -bistatic Doppler"],
            5.7,
            1.35,
            AMBER,
            18,
        )
        convention.move_to(RIGHT * 3.4 + DOWN * 1.5)
        return VGroup(baseline, direct, path_1, path_2, tx, rx, target, labels, equation, convention)

    def echo_visual(self) -> VGroup:
        reference = self.waveform(
            self.data.analytic["reference_real"],
            LEFT * 5.4 + UP * 1.3,
            3.1,
            1.25,
            PURPLE,
            "reference-derived seed",
        )
        conditioned = self.panel(
            "Echo-only conditioning",
            ["optional dominant-line suppression", "RMS match to original seed"],
            3.3,
            1.55,
            CYAN,
            18,
        )
        conditioned.move_to(LEFT * 0.6 + UP * 1.25)
        propagation = self.panel(
            "Propagation P{·}",
            ["delay tau_b", "Doppler f_b", "relative amplitude a"],
            2.8,
            1.8,
            GREEN,
            18,
        )
        propagation.move_to(RIGHT * 3.1 + UP * 1.25)
        output = self.waveform(
            self.data.analytic["surveillance_real"],
            LEFT * 1.5 + DOWN * 1.85,
            4.3,
            1.25,
            AMBER,
            "surveillance delta e_echo",
        )
        arrows = VGroup(
            self.arrow_between(reference, conditioned, PURPLE),
            self.arrow_between(conditioned, propagation, CYAN),
            Arrow(propagation.get_bottom(), output.get_top(), buff=0.15, color=AMBER, stroke_width=4),
        )
        equation = _text("e_echo[n] = a · P{x_seed}[n]     a = 10^(G_dB/20)", 23, INK, 11.8)
        equation.move_to(RIGHT * 1.0 + DOWN * 0.55)
        caveat = _text("-18 dB = normalized scenario gain; not calibrated received power", 18, MUTED, 11.8)
        caveat.next_to(equation, DOWN, buff=0.12)
        return VGroup(reference, conditioned, propagation, output, arrows, equation, caveat)

    def synchronization_visual(self) -> VGroup:
        reference = self.waveform(
            self.data.analytic["reference_real"],
            LEFT * 5.6 + UP * 1.5,
            4.1,
            1.15,
            PURPLE,
            "reference x[n]",
        )
        surveillance = self.waveform(
            self.data.analytic["surveillance_real"],
            LEFT * 5.6 + DOWN * 0.55,
            4.1,
            1.15,
            AMBER,
            "surveillance y[n] before alignment",
        )
        lag = self.panel(
            "Integer alignment",
            ["r_xy[k] = sum x[n] y*[n-k]", "k_hat = argmax |r_xy[k]|", "finddelay + normalized xcorr"],
            4.5,
            2.15,
            CYAN,
            18,
        )
        lag.move_to(RIGHT * 3.2 + UP * 1.3)
        phase_origin = RIGHT * 1.35 + DOWN * 2.1
        phase_axis = VGroup(
            Line(phase_origin, phase_origin + RIGHT * 4.0, color=GRID),
            Line(phase_origin, phase_origin + UP * 1.6, color=GRID),
        )
        phase_values = self.data.analytic["phase_rad"]
        points = [
            phase_origin
            + RIGHT * 3.8 * index / (len(phase_values) - 1)
            + UP * 1.25 * value / max(phase_values)
            for index, value in enumerate(phase_values)
        ]
        phase_line = VMobject(color=GREEN, stroke_width=3)
        phase_line.set_points_smoothly(points)
        phase_label = _text("cross-phase slope → residual frequency", 17, GREEN, 4.0)
        phase_label.next_to(phase_axis, DOWN, buff=0.12)
        correction = self.panel(
            "Residual correction",
            ["phi(t) ~= phi_0 + 2*pi*Delta_f*t", "multiply by exp(-j2*pi*Delta_f*n/F_s)", "reuse correction from control"],
            5.6,
            1.55,
            GREEN,
            17,
        )
        correction.move_to(RIGHT * 2.8 + DOWN * 0.1)
        return VGroup(reference, surveillance, lag, phase_axis, phase_line, phase_label, correction)

    def cpi_visual(self) -> VGroup:
        rate_1 = self.panel(
            "Input samples",
            ["F_s = 6.144 MHz", "complete corrected repetition"],
            3.0,
            1.55,
            PURPLE,
            19,
        )
        rate_2 = self.panel(
            "resample",
            ["p = 1, q = 200", "anti-alias FIR first"],
            2.8,
            1.55,
            CYAN,
            19,
        )
        rate_3 = self.panel(
            "Map-domain CPI",
            ["F_s' = 30.72 kHz", "T_CPI = 100 ms", "N = 3,072 samples"],
            3.2,
            1.75,
            GREEN,
            18,
        )
        rate_1.move_to(LEFT * 4.4 + UP * 0.9)
        rate_2.move_to(LEFT * 0.6 + UP * 0.9)
        rate_3.move_to(RIGHT * 3.6 + UP * 0.9)
        arrows = VGroup(
            self.arrow_between(rate_1, rate_2, PURPLE),
            self.arrow_between(rate_2, rate_3, CYAN),
        )
        scale = self.panel(
            "Do not conflate these",
            ["nominal CPI Doppler scale: 1/T = 10 Hz", "saved Doppler grid spacing: 3.75 Hz", "saved delay grid spacing: 32.55 microseconds"],
            9.8,
            1.8,
            AMBER,
            20,
        )
        scale.move_to(DOWN * 1.55)
        note = _text("Grid spacing samples coordinates; it does not independently establish physical resolution.", 19, MUTED, 11.8)
        note.move_to(DOWN * 2.65)
        return VGroup(rate_1, rate_2, rate_3, arrows, scale, note)

    def lms_visual(self) -> VGroup:
        reference = self.panel(
            "Reference x[n]",
            ["predictor input", "reference-correlated leakage"],
            3.0,
            1.45,
            PURPLE,
            18,
        )
        surveillance = self.panel(
            "Surveillance d[n]",
            ["desired input", "field background + optional echo"],
            3.3,
            1.45,
            AMBER,
            18,
        )
        lms = self.panel(
            "Normalized LMS",
            ["y_hat[n] = predicted component", "e[n] = d[n] - y_hat[n]", "residual e[n] goes to CAF"],
            3.8,
            2.1,
            CYAN,
            18,
        )
        residual = self.panel(
            "Candidate residual",
            ["none / conservative / aggressive", "fixed downstream detector"],
            3.4,
            1.45,
            GREEN,
            18,
        )
        reference.move_to(LEFT * 4.6 + UP * 1.25)
        surveillance.move_to(LEFT * 4.5 + DOWN * 1.3)
        lms.move_to(LEFT * 0.3)
        residual.move_to(RIGHT * 4.2)
        arrows = VGroup(
            self.arrow_between(reference, lms, PURPLE),
            self.arrow_between(surveillance, lms, AMBER),
            self.arrow_between(lms, residual, GREEN),
        )
        curve_origin = RIGHT * 2.2 + DOWN * 2.25
        curve_axis = VGroup(
            Line(curve_origin, curve_origin + RIGHT * 3.7, color=GRID),
            Line(curve_origin, curve_origin + UP * 1.3, color=GRID),
        )
        values = self.data.analytic["lms_error_power"]
        points = [
            curve_origin
            + RIGHT * 3.5 * index / (len(values) - 1)
            + UP * 1.15 * value
            for index, value in enumerate(values)
        ]
        curve = VMobject(color=GREEN, stroke_width=3)
        curve.set_points_smoothly(points)
        curve_label = _text("analytic residual-error trend", 16, MUTED, 3.7)
        curve_label.next_to(curve_axis, DOWN, buff=0.1)
        return VGroup(reference, surveillance, lms, residual, arrows, curve_axis, curve, curve_label)

    def caf_visual(self) -> VGroup:
        frame = Rectangle(
            width=5.5,
            height=3.6,
            stroke_color="#7395B8",
            stroke_width=2,
            fill_color=PANEL_DARK,
            fill_opacity=0.95,
        )
        frame.move_to(RIGHT * 3.2 + UP * 0.15)
        cells = VGroup()
        rows, columns = 9, 13
        for row in range(rows):
            for column in range(columns):
                delay_factor = (column - 7) / 3.4
                doppler_factor = (row - 4) / 2.2
                value = np.exp(-(delay_factor**2 + doppler_factor**2))
                color = interpolate_color(BLUE, AMBER, value)
                cell = Square(
                    side_length=0.32,
                    stroke_width=0.2,
                    stroke_color=PANEL_DARK,
                    fill_color=color,
                    fill_opacity=0.95,
                )
                cell.move_to(
                    frame.get_center()
                    + RIGHT * (column - (columns - 1) / 2) * 0.34
                    + DOWN * (row - (rows - 1) / 2) * 0.34
                )
                cells.add(cell)
        axes = VGroup(
            _text("delay tau →", 18, MUTED).next_to(frame, DOWN, buff=0.1),
            _text("Doppler f", 18, MUTED).rotate(PI / 2).next_to(frame, LEFT, buff=0.12),
            _text("code-drawn CAF power concept", 16, MUTED, 5.2).next_to(frame, UP, buff=0.08),
        )
        inputs = self.panel(
            "Two synchronized signals",
            ["reference x_ref[n]", "candidate surveillance y[n]"],
            3.5,
            1.55,
            PURPLE,
            19,
        )
        inputs.move_to(LEFT * 4.2 + UP * 1.4)
        transform = self.panel(
            "ambgfun",
            ["delay hypotheses", "Doppler hypotheses", "magnitude → power"],
            2.8,
            1.9,
            CYAN,
            18,
        )
        transform.move_to(LEFT * 0.6 + UP * 1.25)
        arrow = self.arrow_between(transform, frame, CYAN)
        formula = self.panel(
            "Displayed map",
            ["P(tau, f) = |A(tau, f)|^2", "matrix: rows = Doppler; columns = delay"],
            7.1,
            1.45,
            GREEN,
            20,
        )
        formula.move_to(LEFT * 1.5 + DOWN * 2.25)
        return VGroup(frame, cells, axes, inputs, transform, arrow, formula)

    def detector_visual(self) -> VGroup:
        stencil = self.data.analytic["cfar_stencil"]
        rows = int(stencil["rows_doppler"])
        columns = int(stencil["columns_delay"])
        cut_row = int(stencil["cut_row"])
        cut_column = int(stencil["cut_column"])
        grid_cells = VGroup()
        for row in range(rows):
            for column in range(columns):
                row_distance = abs(row - cut_row)
                column_distance = abs(column - cut_column)
                is_cut = row == cut_row and column == cut_column
                is_guard = (
                    row_distance <= int(stencil["guard_half_rows"])
                    and column_distance <= int(stencil["guard_half_columns"])
                )
                is_training = (
                    row_distance <= int(stencil["training_half_rows"])
                    and column_distance <= int(stencil["training_half_columns"])
                    and not is_guard
                )
                color = PANEL_DARK
                if is_training:
                    color = BLUE
                if is_guard:
                    color = AMBER
                if is_cut:
                    color = RED
                cell = Square(
                    side_length=0.29,
                    stroke_color="#2E4A66",
                    stroke_width=0.5,
                    fill_color=color,
                    fill_opacity=0.95,
                )
                cell.move_to(
                    LEFT * 3.6
                    + RIGHT * (column - (columns - 1) / 2) * 0.31
                    + DOWN * (row - (rows - 1) / 2) * 0.31
                )
                grid_cells.add(cell)
        stencil_label = self.panel(
            "CA-CFAR stencil",
            ["blue: training • amber: guard • red: CUT", "P_CUT > alpha(Pfa) · P_hat_noise", "320 training cells in executed geometry"],
            6.2,
            1.75,
            CYAN,
            18,
        )
        grid_cells.shift(UP * 0.5)
        stencil_label.move_to(LEFT * 3.6 + DOWN * 2.25)
        nms_frame = Rectangle(
            width=3.4,
            height=3.0,
            stroke_color=GREEN,
            stroke_width=2,
            fill_color=PANEL_DARK,
            fill_opacity=0.96,
        )
        nms_frame.move_to(RIGHT * 3.7 + UP * 0.25)
        nms_values = self.data.analytic["nms_power"]
        nms_cells = VGroup()
        for row, values in enumerate(nms_values):
            for column, value in enumerate(values):
                color = interpolate_color(BLUE, AMBER, float(value))
                cell = Square(
                    side_length=0.42,
                    stroke_width=0.4,
                    stroke_color="#2E4A66",
                    fill_color=color,
                    fill_opacity=0.95,
                )
                cell.move_to(
                    nms_frame.get_center()
                    + RIGHT * (column - 2) * 0.45
                    + DOWN * (row - 2) * 0.45
                )
                nms_cells.add(cell)
        retained = Circle(radius=0.28, color=GREEN, stroke_width=4)
        retained.move_to(nms_cells[12])
        nms_label = self.panel(
            "7×3 NMS",
            ["imdilate finds local maxima", "bwconncomp resolves plateaus", "retain one candidate peak"],
            4.2,
            1.8,
            GREEN,
            18,
        )
        nms_label.move_to(RIGHT * 3.7 + DOWN * 2.15)
        return VGroup(grid_cells, stencil_label, nms_frame, nms_cells, retained, nms_label)

    def association_visual(self) -> VGroup:
        frame = Rectangle(
            width=7.2,
            height=4.1,
            stroke_color="#7395B8",
            stroke_width=2,
            fill_color=PANEL_DARK,
            fill_opacity=0.95,
        )
        frame.move_to(LEFT * 1.8 + UP * 0.25)
        candidates = VGroup(
            Dot(frame.get_center() + LEFT * 2.3 + DOWN * 0.9, color=AMBER),
            Dot(frame.get_center() + LEFT * 0.7 + UP * 0.8, color=AMBER),
            Dot(frame.get_center() + RIGHT * 1.1 + UP * 0.2, color=AMBER),
            Dot(frame.get_center() + RIGHT * 2.5 + DOWN * 1.1, color=AMBER),
        )
        truth = Square(side_length=0.42, color=GREEN, fill_opacity=0.12, stroke_width=3)
        truth.rotate(PI / 4)
        truth.move_to(candidates[2].get_center() + RIGHT * 0.25 + UP * 0.1)
        link = Line(candidates[2].get_center(), truth.get_center(), color=GREEN, stroke_width=3)
        labels = VGroup(
            _text("delay error / h_tau", 18, MUTED).next_to(frame, DOWN, buff=0.1),
            _text("Doppler error / h_f", 18, MUTED).rotate(PI / 2).next_to(frame, LEFT, buff=0.1),
            _text("truth-blind candidates", 18, AMBER).next_to(frame, UP, buff=0.08),
            _text("truth window", 18, GREEN).next_to(truth, RIGHT, buff=0.14),
        )
        formula = self.panel(
            "Post-hoc cost",
            ["d_tau = |tau_truth - tau_det| / h_tau", "d_f = |f_truth - f_det| / h_f", "cost = sqrt(d_tau^2 + d_f^2)"],
            4.6,
            2.05,
            CYAN,
            18,
        )
        formula.move_to(RIGHT * 4.6 + UP * 0.8)
        match = self.panel(
            "One-to-one association",
            ["matchpairs(cost, 2.0, 'min')", "only allowed matches are labeled"],
            4.6,
            1.45,
            GREEN,
            18,
        )
        match.move_to(RIGHT * 4.6 + DOWN * 1.7)
        return VGroup(frame, candidates, truth, link, labels, formula, match)

    def final_cases_visual(self) -> VGroup:
        positive = self.data.example("45 km positive control")
        near = self.data.example("15 km baseline")
        pass_panel = self.panel(
            "45 km positive control",
            [
                f"display: {positive['display_delay_us']:.1f} us, +{positive['display_doppler_hz']:.1f} Hz",
                "inside frozen detector support",
                "criterion passed • post-hoc truth match",
                "no matched-control nuisance association",
            ],
            5.8,
            3.0,
            GREEN,
            19,
        )
        near_panel = self.panel(
            "15 km baseline",
            [
                f"display: {near['display_delay_us']:.1f} us, +{near['display_doppler_hz']:.1f} Hz",
                "valid physics-map coordinate",
                "outside frozen delay support",
                "detector evaluation: NO — not evaluated",
            ],
            5.8,
            3.0,
            AMBER,
            19,
        )
        pass_panel.move_to(LEFT * 3.2 + UP * 0.6)
        near_panel.move_to(RIGHT * 3.2 + UP * 0.6)
        boundary = self.panel(
            "What the examples do not authorize",
            ["No detector-support widening • no retune • no field-aircraft detection claim • no tracking"],
            11.6,
            1.1,
            RED,
            19,
        )
        boundary.move_to(DOWN * 1.65)
        references = VGroup(*[_text(line, 13, MUTED, 12.2) for line in REFERENCES_CARD])
        references.arrange(DOWN, aligned_edge=LEFT, buff=0.04)
        references.move_to(DOWN * 2.53)
        return VGroup(pass_panel, near_panel, boundary, references)


class MathFirstPassiveBistaticDeepDive(DeepDiveScene):
    """A 13 minute 20 second, 1080p, caption-led instructional video."""

    def construct(self) -> None:
        visuals = [
            self.evidence_boundary_visual(),
            self.geometry_visual(),
            self.echo_visual(),
            self.synchronization_visual(),
            self.cpi_visual(),
            self.lms_visual(),
            self.caf_visual(),
            self.detector_visual(),
            self.association_visual(),
            self.final_cases_visual(),
        ]
        for chapter_spec, visual in zip(CHAPTERS, visuals, strict=True):
            self.chapter(chapter_spec, visual)
