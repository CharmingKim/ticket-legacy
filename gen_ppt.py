# -*- coding: utf-8 -*-
from pptx import Presentation
from pptx.util import Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.chart.data import ChartData
from pptx.enum.chart import XL_CHART_TYPE
from pptx.oxml.ns import qn
from lxml import etree
import copy

# ── Colors ──────────────────────────────────────────────
NAVY      = RGBColor(0x04, 0x1F, 0x60)
BLUE_GRAY = RGBColor(0x66, 0x71, 0x98)
BG_COLOR  = RGBColor(0xF3, 0xF4, 0xFA)
WHITE     = RGBColor(0xFF, 0xFF, 0xFF)
BLACK     = RGBColor(0x00, 0x00, 0x00)
ACCENT    = RGBColor(0x2E, 0x5B, 0xFF)
LIGHT_BG  = RGBColor(0xEE, 0xF0, 0xFB)
DIVIDER   = RGBColor(0xCC, 0xD0, 0xE8)
GREEN     = RGBColor(0x1B, 0x8A, 0x5A)
ORANGE    = RGBColor(0xE8, 0x7A, 0x1E)

# ── Dimensions (EMU) ────────────────────────────────────
W = 18288000   # 20"
H = 10287000   # 11.25"

def px(inches): return int(inches * 914400)

FONT_T = "Gotham Bold"
FONT_B = "Canva Sans"

# ── Low-level helpers ────────────────────────────────────
def _set_bg(slide, color: RGBColor):
    bg = slide.background
    fill = bg.fill
    fill.solid()
    fill.fore_color.rgb = color

def _rect(slide, left, top, width, height, fill_color=None, border_color=None, border_pt=0):
    from pptx.util import Emu as E
    shape = slide.shapes.add_shape(1, left, top, width, height)  # MSO_SHAPE_TYPE.RECTANGLE=1
    shape.line.width = Pt(border_pt) if border_pt else Pt(0)
    if fill_color:
        shape.fill.solid()
        shape.fill.fore_color.rgb = fill_color
    else:
        shape.fill.background()
    if border_color and border_pt:
        shape.line.color.rgb = border_color
    else:
        shape.line.fill.background()
    return shape

def _tb(slide, text, left, top, width, height,
        font=FONT_B, size=18, color=BLACK, bold=False,
        align=PP_ALIGN.LEFT, wrap=True, line_spacing=None):
    txBox = slide.shapes.add_textbox(left, top, width, height)
    tf = txBox.text_frame
    tf.word_wrap = wrap
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.name = font
    run.font.size = Pt(size)
    run.font.color.rgb = color
    run.font.bold = bold
    if line_spacing:
        from pptx.util import Pt as P2
        from pptx.oxml.ns import qn as q
        pPr = p._p.get_or_add_pPr()
        lnSpc = etree.SubElement(pPr, q('a:lnSpc'))
        spcPct = etree.SubElement(lnSpc, q('a:spcPct'))
        spcPct.set('val', str(int(line_spacing * 1000)))
    return txBox

def _tb_multi(slide, lines, left, top, width, height,
              font=FONT_B, size=16, color=BLACK, bold=False,
              align=PP_ALIGN.LEFT, line_spacing=1.3):
    txBox = slide.shapes.add_textbox(left, top, width, height)
    tf = txBox.text_frame
    tf.word_wrap = True
    first = True
    for line in lines:
        if first:
            p = tf.paragraphs[0]
            first = False
        else:
            p = tf.add_paragraph()
        p.alignment = align
        run = p.add_run()
        run.text = line
        run.font.name = font
        run.font.size = Pt(size)
        run.font.color.rgb = color
        run.font.bold = bold
        pPr = p._p.get_or_add_pPr()
        lnSpc = etree.SubElement(pPr, qn('a:lnSpc'))
        spcPct = etree.SubElement(lnSpc, qn('a:spcPct'))
        spcPct.set('val', str(int(line_spacing * 100000)))
    return txBox

def _header(slide, title, part_label=None):
    """Navy header bar with white title."""
    _rect(slide, 0, 0, W, px(1.3), fill_color=NAVY)
    _tb(slide, title,
        px(0.55), px(0.18), px(14), px(0.95),
        font=FONT_T, size=40, color=WHITE, bold=True)
    if part_label:
        _tb(slide, part_label,
            px(15.8), px(0.38), px(3.8), px(0.6),
            font=FONT_B, size=14, color=DIVIDER,
            align=PP_ALIGN.RIGHT)

def _page_num(slide, num):
    _tb(slide, str(num),
        px(19.3), px(10.6), px(0.6), px(0.4),
        font=FONT_B, size=11, color=BLUE_GRAY, align=PP_ALIGN.RIGHT)

def _divider_line(slide, y):
    _rect(slide, px(0.5), y, px(19), px(0.012), fill_color=DIVIDER)

def _bullet_item(slide, icon_char, text, x, y, icon_color=ACCENT, text_size=16):
    _rect(slide, x, y + px(0.04), px(0.32), px(0.32), fill_color=icon_color)
    _tb(slide, text, x + px(0.45), y - px(0.02), px(8.5), px(0.45),
        font=FONT_B, size=text_size, color=BLACK)

def _add_fade_animation(slide, shape):
    """Add a simple Fade entrance animation to a shape."""
    try:
        spTree = slide.shapes._spTree
        timing = slide._element.find(qn('p:timing'))
        if timing is None:
            timing_xml = '<p:timing xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:tnLst><p:par><p:cTn id="1" dur="indefinite" restart="whenNotActive" nodeType="tmRoot"><p:childTnLst><p:seq concurrent="1" nextAc="seek"><p:cTn id="2" dur="indefinite" nodeType="mainSeq"><p:childTnLst/></p:cTn><p:prevCondLst><p:cond evt="onPrevClick" delay="0"><p:tn/></p:cond></p:prevCondLst><p:nextCondLst><p:cond evt="onNextClick" delay="0"><p:tn/></p:cond></p:nextCondLst></p:seq></p:childTnLst></p:cTn></p:par></p:tnLst><p:bldLst/></p:timing>'
            timing = etree.fromstring(timing_xml)
            slide._element.append(timing)
    except Exception:
        pass

# ── Slide factories ──────────────────────────────────────

def slide_title(prs):
    layout = prs.slide_layouts[6]  # Blank
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    # Big navy block left
    _rect(s, 0, 0, px(8.5), H, fill_color=NAVY)
    # Accent stripe
    _rect(s, px(8.5), 0, px(0.08), H, fill_color=ACCENT)
    # Logo area placeholder
    _rect(s, px(0.6), px(0.6), px(1.5), px(0.35), fill_color=ACCENT)
    _tb(s, "TICKET LEGACY", px(0.6), px(0.55), px(7.5), px(0.5),
        font=FONT_T, size=11, color=WHITE, bold=True)
    # Main title
    _tb_multi(s, ["TicketLegacy", "공연 예매 플랫폼"],
              px(0.55), px(2.2), px(7.8), px(3.5),
              font=FONT_T, size=56, color=WHITE, bold=True, line_spacing=1.15)
    # Subtitle
    _tb(s, "Spring MVC 5.3 | Multi-WAR | JWT | Redis | MyBatis",
        px(0.55), px(5.5), px(7.8), px(0.6),
        font=FONT_B, size=17, color=DIVIDER)
    _divider_line(s, px(6.2)); _divider_line(s, px(6.23))
    # Meta
    _tb_multi(s, ["팀 프로젝트 최종 발표", "2026.05.06"],
              px(0.55), px(6.5), px(7.8), px(1.2),
              font=FONT_B, size=16, color=LIGHT_BG, line_spacing=1.5)
    # Right side decorative
    _tb(s, "Enterprise-Grade\nTicketing System",
        px(9.2), px(3.5), px(8.5), px(2.0),
        font=FONT_T, size=38, color=NAVY, bold=True)
    _tb(s, "3개 포털 | 45개 테이블 | 200+ 공연 데이터\nRedis 좌석 락 | FSM 상태 관리 | BCrypt 인증",
        px(9.2), px(6.0), px(8.5), px(1.5),
        font=FONT_B, size=16, color=BLUE_GRAY)
    # Decorative circles
    for i, (cx, cy, r, col) in enumerate([
        (px(17.5), px(1.5), px(1.2), RGBColor(0x04,0x1F,0x60)),
        (px(16.8), px(9.2), px(0.8), RGBColor(0x66,0x71,0x98)),
    ]):
        shape = s.shapes.add_shape(9, cx-r, cy-r, r*2, r*2)  # 9=OVAL
        shape.fill.solid(); shape.fill.fore_color.rgb = col
        shape.line.fill.background()
    _page_num(s, 1)
    return s

def slide_script(prs, num, lines):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, LIGHT_BG)
    _rect(s, 0, 0, px(0.12), H, fill_color=BLUE_GRAY)
    _rect(s, 0, 0, W, px(0.9), fill_color=DIVIDER)
    _tb(s, f"📋  발표 대본  —  슬라이드 {num-1}",
        px(0.3), px(0.12), px(10), px(0.65),
        font=FONT_T, size=16, color=NAVY, bold=True)
    _tb(s, "SPEAKER NOTES",
        px(16), px(0.18), px(3.8), px(0.5),
        font=FONT_B, size=12, color=BLUE_GRAY, align=PP_ALIGN.RIGHT)
    _tb_multi(s, lines,
              px(0.55), px(1.15), px(17.5), px(8.8),
              font=FONT_B, size=17, color=BLACK, line_spacing=1.55)
    _page_num(s, num)
    return s

def slide_toc(prs, num):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, "목  차", "TABLE OF CONTENTS")
    sections = [
        ("01", "프로젝트 개요",         "배경 · 목표 · 개발 환경"),
        ("02", "요구사항 명세",          "기능 요구사항 · 비기능 요구사항"),
        ("03", "시스템 아키텍처",        "멀티모듈 구조 · 기술 스택 · DB 설계"),
        ("04", "핵심 기능 구현",         "동시성 제어 · FSM · 인증·보안"),
        ("05", "데이터 & 성과",          "200+ 공연 데이터셋 · 구현 완성도"),
        ("06", "기술적 도전 & 해결",     "주요 이슈 3가지"),
        ("07", "향후 계획 & 결론",       "로드맵 · 핵심 가치 · Q&A"),
    ]
    col_w = px(8.5)
    for i, (no, title, sub) in enumerate(sections):
        row, col = divmod(i, 2) if i < 6 else (3, 0)
        if i < 6:
            row, col = divmod(i, 2)
        else:
            row, col = 3, 0
        x = px(0.5) + col * (col_w + px(0.4))
        y = px(1.55) + row * px(2.05)
        _rect(s, x, y, col_w, px(1.7), fill_color=WHITE, border_color=DIVIDER, border_pt=1)
        _rect(s, x, y, px(0.6), px(1.7), fill_color=NAVY)
        _tb(s, no, x + px(0.08), y + px(0.55), px(0.45), px(0.6),
            font=FONT_T, size=18, color=WHITE, bold=True, align=PP_ALIGN.CENTER)
        _tb(s, title, x + px(0.75), y + px(0.2), col_w - px(0.9), px(0.65),
            font=FONT_T, size=20, color=NAVY, bold=True)
        _tb(s, sub, x + px(0.75), y + px(0.95), col_w - px(0.9), px(0.55),
            font=FONT_B, size=14, color=BLUE_GRAY)
    _page_num(s, num)
    return s

def slide_section_break(prs, num, section_no, title, subtitle):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, NAVY)
    _rect(s, 0, 0, px(0.5), H, fill_color=ACCENT)
    _rect(s, px(0.5), px(4.0), W - px(0.5), px(0.08), fill_color=WHITE)
    _tb(s, f"PART  {section_no}", px(1.5), px(2.8), px(16), px(0.8),
        font=FONT_B, size=18, color=DIVIDER, bold=False)
    _tb(s, title, px(1.5), px(3.5), px(16), px(1.8),
        font=FONT_T, size=54, color=WHITE, bold=True)
    _tb(s, subtitle, px(1.5), px(5.4), px(16), px(0.8),
        font=FONT_B, size=20, color=BLUE_GRAY)
    _page_num(s, num)
    return s

def slide_bullets(prs, num, title, part, items, two_col=False):
    """items: list of (icon_color, text) or (icon_color, title, body)"""
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, title, part)
    if not two_col:
        for i, item in enumerate(items):
            y = px(1.55) + i * px(1.02)
            if len(item) == 2:
                col, text = item
                _rect(s, px(0.5), y + px(0.1), px(0.35), px(0.35), fill_color=col)
                _tb(s, text, px(1.05), y, px(16.8), px(0.85),
                    font=FONT_B, size=17, color=BLACK)
            else:
                col, ttl, body = item
                _rect(s, px(0.5), y + px(0.08), px(0.35), px(0.35), fill_color=col)
                _tb(s, ttl, px(1.05), y, px(16.8), px(0.5),
                    font=FONT_T, size=18, color=NAVY, bold=True)
                _tb(s, body, px(1.05), y + px(0.48), px(16.8), px(0.45),
                    font=FONT_B, size=15, color=BLUE_GRAY)
    else:
        half = len(items) // 2 + len(items) % 2
        for i, item in enumerate(items):
            col_x = px(0.5) if i < half else px(9.7)
            y = px(1.55) + (i % half) * px(1.05)
            col, ttl, body = item if len(item) == 3 else (item[0], item[1], "")
            _rect(s, col_x, y + px(0.08), px(0.32), px(0.32), fill_color=col)
            _tb(s, ttl, col_x + px(0.48), y, px(8.2), px(0.5),
                font=FONT_T, size=17, color=NAVY, bold=True)
            if body:
                _tb(s, body, col_x + px(0.48), y + px(0.45), px(8.2), px(0.48),
                    font=FONT_B, size=14, color=BLUE_GRAY)
    _page_num(s, num)
    return s

def slide_cards(prs, num, title, part, cards):
    """cards: list of (header_color, title, body_lines[])  max 4"""
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, title, part)
    n = len(cards)
    card_w = int((W - px(1.0) - px(0.3) * (n-1)) / n)
    for i, (hcol, ctitle, clines) in enumerate(cards):
        x = px(0.5) + i * (card_w + px(0.3))
        y = px(1.5)
        h = px(8.5)
        _rect(s, x, y, card_w, h, fill_color=WHITE, border_color=DIVIDER, border_pt=1)
        _rect(s, x, y, card_w, px(0.55), fill_color=hcol)
        _tb(s, ctitle, x + px(0.2), y + px(0.08), card_w - px(0.4), px(0.4),
            font=FONT_T, size=16, color=WHITE, bold=True)
        for j, line in enumerate(clines):
            ly = y + px(0.75) + j * px(0.88)
            _rect(s, x + px(0.2), ly + px(0.12), px(0.22), px(0.22), fill_color=hcol)
            _tb(s, line, x + px(0.55), ly, card_w - px(0.7), px(0.8),
                font=FONT_B, size=14, color=BLACK)
    _page_num(s, num)
    return s

def slide_two_panel(prs, num, title, part, left_title, left_lines, right_title, right_lines, left_col=NAVY, right_col=ACCENT):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, title, part)
    pw = px(8.8)
    # Left panel
    _rect(s, px(0.5), px(1.5), pw, px(8.5), fill_color=WHITE, border_color=DIVIDER, border_pt=1)
    _rect(s, px(0.5), px(1.5), pw, px(0.55), fill_color=left_col)
    _tb(s, left_title, px(0.7), px(1.58), pw - px(0.3), px(0.42),
        font=FONT_T, size=17, color=WHITE, bold=True)
    for i, line in enumerate(left_lines):
        ly = px(2.25) + i * px(0.85)
        _rect(s, px(0.7), ly + px(0.11), px(0.22), px(0.22), fill_color=left_col)
        _tb(s, line, px(1.1), ly, pw - px(0.7), px(0.75),
            font=FONT_B, size=15, color=BLACK)
    # Right panel
    rx = px(0.5) + pw + px(0.35)
    _rect(s, rx, px(1.5), pw, px(8.5), fill_color=WHITE, border_color=DIVIDER, border_pt=1)
    _rect(s, rx, px(1.5), pw, px(0.55), fill_color=right_col)
    _tb(s, right_title, rx + px(0.2), px(1.58), pw - px(0.3), px(0.42),
        font=FONT_T, size=17, color=WHITE, bold=True)
    for i, line in enumerate(right_lines):
        ly = px(2.25) + i * px(0.85)
        _rect(s, rx + px(0.2), ly + px(0.11), px(0.22), px(0.22), fill_color=right_col)
        _tb(s, line, rx + px(0.6), ly, pw - px(0.7), px(0.75),
            font=FONT_B, size=15, color=BLACK)
    _page_num(s, num)
    return s

def slide_arch_diagram(prs, num):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, "시스템 아키텍처", "PART 03")
    boxes = [
        (px(0.5),  px(1.6), px(5.5), px(2.2), NAVY,   "ticket-user",    "port 8080\n일반 회원 포털"),
        (px(6.4),  px(1.6), px(5.5), px(2.2), RGBColor(0x17,0x5F,0x8A),   "ticket-partner", "port 8081\n기획사·공연장 포털"),
        (px(12.3), px(1.6), px(5.5), px(2.2), RGBColor(0x4A,0x1A,0x6B),   "ticket-admin",   "port 8082\n슈퍼어드민·스태프"),
        (px(6.4),  px(4.5), px(5.5), px(2.2), GREEN,  "ticket-common",  "공유 JAR\n도메인·서비스·매퍼"),
        (px(0.5),  px(7.2), px(3.8), px(2.0), RGBColor(0xB8,0x45,0x00), "MySQL 8",        "springgreen6 DB\n45개 테이블"),
        (px(4.8),  px(7.2), px(3.8), px(2.0), RGBColor(0xC4,0x10,0x2C), "Redis",          "localhost:6379\n좌석 선점·세션"),
        (px(9.1),  px(7.2), px(3.8), px(2.0), BLUE_GRAY, "JWT",         "HS256 서명\n3-WAR 공유 시크릿"),
        (px(13.4), px(7.2), px(3.8), px(2.0), RGBColor(0x1B,0x6C,0x3A), "Spring Security","역할 기반 접근\nFSM 상태 제어"),
    ]
    for bx, by, bw, bh, col, title, sub in boxes:
        _rect(s, bx, by, bw, bh, fill_color=col)
        _tb(s, title, bx+px(0.15), by+px(0.2), bw-px(0.3), px(0.55),
            font=FONT_T, size=18, color=WHITE, bold=True)
        _tb(s, sub, bx+px(0.15), by+px(0.75), bw-px(0.3), px(1.1),
            font=FONT_B, size=13, color=LIGHT_BG)
    # arrows DOWN from WAR boxes to common
    for ax in [px(3.25), px(9.15), px(15.05)]:
        _rect(s, ax, px(3.82), px(0.06), px(0.7), fill_color=DIVIDER)
    # label
    _tb(s, "의존 (→ ticket-common)", px(6.9), px(4.2), px(4.5), px(0.35),
        font=FONT_B, size=12, color=BLUE_GRAY, align=PP_ALIGN.CENTER)
    _tb(s, "공유 인프라", px(0.5), px(6.75), px(17), px(0.4),
        font=FONT_T, size=14, color=BLUE_GRAY)
    _page_num(s, num)
    return s

def slide_bar_chart(prs, num, title, part, chart_title, categories, series_data):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, title, part)
    cd = ChartData()
    cd.categories = categories
    for name, vals in series_data:
        cd.add_series(name, vals)
    chart = s.shapes.add_chart(
        XL_CHART_TYPE.COLUMN_CLUSTERED,
        px(0.5), px(1.5), px(17.3), px(8.5), cd
    ).chart
    chart.has_title = True
    chart.chart_title.text_frame.text = chart_title
    chart.chart_title.text_frame.paragraphs[0].runs[0].font.size = Pt(16)
    chart.chart_title.text_frame.paragraphs[0].runs[0].font.color.rgb = NAVY
    chart.plots[0].series[0].format.fill.solid()
    chart.plots[0].series[0].format.fill.fore_color.rgb = NAVY
    _page_num(s, num)
    return s

def slide_donut_chart(prs, num):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, "데이터셋 구성 현황", "PART 05")
    cd = ChartData()
    cd.categories = ["공연(Performance)", "공연회차(Schedule)", "좌석(Seat)", "예매(Reservation)", "회원(Member)", "쿠폰(Coupon)"]
    cd.add_series("레코드 수", (214, 856, 12840, 320, 15, 45))
    chart = s.shapes.add_chart(
        XL_CHART_TYPE.DOUGHNUT,
        px(0.5), px(1.5), px(9.0), px(8.5), cd
    ).chart
    chart.has_title = True
    chart.chart_title.text_frame.text = "도메인별 데이터 분포"
    # Right side stats
    stats = [
        (NAVY,  "214건",    "공연 데이터 (data_extension.sql)"),
        (GREEN, "12,840석", "좌석 인벤토리 (WITH RECURSIVE)"),
        (ACCENT,"45개",     "DB 테이블 (schema_total.sql)"),
        (ORANGE,"3-WAR",    "독립 배포 (단일 DB 공유)"),
    ]
    for i, (col, val, desc) in enumerate(stats):
        y = px(2.0) + i * px(1.85)
        _rect(s, px(10.0), y, px(7.5), px(1.5), fill_color=WHITE, border_color=DIVIDER, border_pt=1)
        _rect(s, px(10.0), y, px(0.45), px(1.5), fill_color=col)
        _tb(s, val,  px(10.65), y + px(0.15), px(6.5), px(0.65),
            font=FONT_T, size=28, color=col, bold=True)
        _tb(s, desc, px(10.65), y + px(0.85), px(6.5), px(0.45),
            font=FONT_B, size=14, color=BLUE_GRAY)
    _page_num(s, num)
    return s

def slide_flow(prs, num, title, part, steps):
    """steps: list of (color, step_no, label, desc)"""
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, title, part)
    n = len(steps)
    step_w = int((W - px(1.0) - px(0.25) * (n-1)) / n)
    for i, (col, no, label, desc) in enumerate(steps):
        x = px(0.5) + i * (step_w + px(0.25))
        y = px(2.0)
        _rect(s, x, y, step_w, px(7.8), fill_color=WHITE, border_color=DIVIDER, border_pt=1)
        _rect(s, x, y, step_w, px(0.55), fill_color=col)
        _tb(s, f"STEP {no}", x + px(0.15), y + px(0.08), step_w - px(0.3), px(0.4),
            font=FONT_T, size=13, color=WHITE, bold=True)
        _tb(s, label, x + px(0.15), y + px(0.75), step_w - px(0.3), px(0.9),
            font=FONT_T, size=18, color=col, bold=True)
        _tb(s, desc, x + px(0.15), y + px(1.75), step_w - px(0.3), px(5.6),
            font=FONT_B, size=14, color=BLACK, wrap=True)
        # Arrow (except last)
        if i < n - 1:
            ax = x + step_w + px(0.05)
            _rect(s, ax, px(5.6), px(0.15), px(0.06), fill_color=BLUE_GRAY)
    _page_num(s, num)
    return s

def slide_fsm(prs, num):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, "FSM — 상태 전환 다이어그램", "PART 04")
    # Performance FSM
    _tb(s, "공연(Performance) 승인 FSM", px(0.5), px(1.45), px(8.5), px(0.5),
        font=FONT_T, size=18, color=NAVY, bold=True)
    perf_states = [
        (px(0.5),  px(2.1), "DRAFT",     RGBColor(0x95,0xA5,0xA6)),
        (px(3.8),  px(2.1), "REVIEW",    ORANGE),
        (px(7.1),  px(2.1), "APPROVED",  GREEN),
        (px(10.4), px(2.1), "PUBLISHED", ACCENT),
        (px(3.8),  px(3.6), "REJECTED",  RGBColor(0xC0,0x39,0x2B)),
    ]
    sw, sh = px(2.8), px(1.1)
    for sx, sy, label, col in perf_states:
        _rect(s, sx, sy, sw, sh, fill_color=col)
        _tb(s, label, sx + px(0.1), sy + px(0.3), sw - px(0.2), px(0.55),
            font=FONT_T, size=15, color=WHITE, bold=True, align=PP_ALIGN.CENTER)
    # Member FSM
    _tb(s, "회원(Member) 상태 FSM", px(9.5), px(1.45), px(8.5), px(0.5),
        font=FONT_T, size=18, color=NAVY, bold=True)
    mem_states = [
        (px(9.5),  px(2.1), "PENDING\nAPPROVAL", RGBColor(0xF3,0x9C,0x12)),
        (px(12.8), px(2.1), "ACTIVE",     GREEN),
        (px(12.8), px(3.6), "SUSPENDED",  ORANGE),
        (px(9.5),  px(3.6), "DORMANT",    BLUE_GRAY),
        (px(16.1), px(2.8), "WITHDRAWN",  RGBColor(0xC0,0x39,0x2B)),
    ]
    for sx, sy, label, col in mem_states:
        _rect(s, sx, sy, sw, sh, fill_color=col)
        _tb(s, label, sx + px(0.1), sy + px(0.2), sw - px(0.2), px(0.7),
            font=FONT_T, size=13, color=WHITE, bold=True, align=PP_ALIGN.CENTER)
    # Legend
    _tb(s, "FSM 보장: validateTransition() — 허용되지 않는 전환 → BusinessException 400",
        px(0.5), px(5.0), px(17.5), px(0.55),
        font=FONT_B, size=15, color=BLUE_GRAY)
    # Table for all FSMs
    _rect(s, px(0.5), px(5.7), W - px(1.0), px(4.2), fill_color=WHITE, border_color=DIVIDER, border_pt=1)
    headers = ["도메인", "상태 목록", "터미널 상태", "전환 검증 메서드"]
    col_xs = [px(0.7), px(4.0), px(9.0), px(13.0)]
    col_ws = [px(3.0), px(4.7), px(3.7), px(4.8)]
    _rect(s, px(0.5), px(5.7), W - px(1.0), px(0.5), fill_color=NAVY)
    for j, (hdr, cx, cw) in enumerate(zip(headers, col_xs, col_ws)):
        _tb(s, hdr, cx, px(5.75), cw, px(0.4),
            font=FONT_T, size=13, color=WHITE, bold=True)
    rows = [
        ("Member",       "PENDING_APPROVAL / ACTIVE / SUSPENDED / DORMANT / WITHDRAWN", "WITHDRAWN", "MemberStatus.canTransitionTo()"),
        ("Promoter",     "PENDING / APPROVED / REJECTED / SUSPENDED",                   "REJECTED",  "PromoterApprovalStatus.canTransitionTo()"),
        ("VenueManager", "PENDING / APPROVED / REJECTED",                                "REJECTED",  "VenueManagerApprovalStatus.canTransitionTo()"),
        ("Performance",  "DRAFT / REVIEW / APPROVED / REJECTED / PUBLISHED",             "PUBLISHED", "PerformanceApprovalStatus.validateTransition()"),
    ]
    for ri, (d, st, term, meth) in enumerate(rows):
        ry = px(6.3) + ri * px(0.8)
        bg = WHITE if ri % 2 == 0 else BG_COLOR
        _rect(s, px(0.5), ry, W - px(1.0), px(0.78), fill_color=bg)
        for val, cx, cw in zip([d, st, term, meth], col_xs, col_ws):
            col_txt = NAVY if val == d else (RGBColor(0xC0,0x39,0x2B) if val == term else BLACK)
            _tb(s, val, cx, ry + px(0.1), cw, px(0.58),
                font=FONT_B, size=12, color=col_txt, bold=(val==d))
    _page_num(s, num)
    return s

def slide_dual_defense(prs, num):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, "좌석 예매 동시성 제어 — Dual Defense", "PART 04")
    steps = [
        (ACCENT, "1단계", "Redis Lua\n원자적 선점",
         "Lua 스크립트로\nAVAILABLE 확인 후\nHOLD 상태 원자 전환\n(10분 TTL)\n\n→ 네트워크 분산\n  레이스 컨디션 방지"),
        (NAVY, "2단계", "DB 낙관적 락\n이중 검증",
         "WHERE status=\n'AVAILABLE'\n조건부 UPDATE\n\n→ Redis 장애 시에도\n  DB-only 모드로\n  자동 강등"),
        (GREEN, "3단계", "결제 멱등성\n중복 방지",
         "payment 테이블\nidempotency_key\nUNIQUE 제약\n\n→ 네트워크 재시도\n  중복 결제 차단"),
        (ORANGE, "4단계", "예매 확정\n상태 전환",
         "PENDING →\nCONFIRMED\n(결제 완료)\n\n→ seat_inventory\n  RESERVED 전환\n  트랜잭션 보장"),
    ]
    sw = px(4.2)
    for i, (col, no, label, desc) in enumerate(steps):
        x = px(0.5) + i * (sw + px(0.3))
        _rect(s, x, px(1.5), sw, px(8.6), fill_color=WHITE, border_color=DIVIDER, border_pt=1)
        _rect(s, x, px(1.5), sw, px(0.6), fill_color=col)
        _tb(s, no, x + px(0.15), px(1.58), sw - px(0.3), px(0.45),
            font=FONT_T, size=14, color=WHITE, bold=True)
        _tb(s, label, x + px(0.15), px(2.3), sw - px(0.3), px(1.0),
            font=FONT_T, size=17, color=col, bold=True)
        _tb(s, desc, x + px(0.15), px(3.45), sw - px(0.3), px(6.3),
            font=FONT_B, size=14, color=BLACK)
        if i < 3:
            _rect(s, x + sw + px(0.06), px(5.5), px(0.18), px(0.06), fill_color=BLUE_GRAY)
    _page_num(s, num)
    return s

def slide_jwt_security(prs, num):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, "인증 & 보안 아키텍처", "PART 04")
    # JWT flow
    _tb(s, "JWT HttpOnly 쿠키 기반 인증 플로우", px(0.5), px(1.5), px(10), px(0.5),
        font=FONT_T, size=18, color=NAVY, bold=True)
    jwt_steps = [
        (px(0.5),  "①  로그인 요청\nPOST /api/member/login", NAVY),
        (px(4.0),  "②  JWT 발급\nHS256 + 2h 만료", ACCENT),
        (px(7.5),  "③  HttpOnly 쿠키\nXSS 방어 자동 적용", GREEN),
        (px(11.0), "④  요청 시 자동 전송\nJwtAuthenticationFilter", ORANGE),
        (px(14.5), "⑤  역할 검증\nSecurity Context 설정", RGBColor(0x7B,0x1F,0xA2)),
    ]
    for bx, txt, col in jwt_steps:
        _rect(s, bx, px(2.15), px(3.3), px(1.8), fill_color=col)
        _tb(s, txt, bx + px(0.1), px(2.25), px(3.1), px(1.6),
            font=FONT_B, size=13, color=WHITE)
    # Cookie names
    _tb(s, "포털별 쿠키명 분리 (localhost 덮어쓰기 방지)", px(0.5), px(4.2), px(10), px(0.45),
        font=FONT_T, size=16, color=NAVY, bold=True)
    cookies = [
        (px(0.5),  "USER_TOKEN",    "ticket-user :8080",    NAVY),
        (px(6.2),  "PARTNER_TOKEN", "ticket-partner :8081", RGBColor(0x17,0x5F,0x8A)),
        (px(11.9), "ADMIN_TOKEN",   "ticket-admin :8082",   RGBColor(0x4A,0x1A,0x6B)),
    ]
    for cx, name, portal, col in cookies:
        _rect(s, cx, px(4.8), px(5.4), px(1.2), fill_color=col)
        _tb(s, name, cx + px(0.15), px(4.9), px(5.1), px(0.5),
            font=FONT_T, size=16, color=WHITE, bold=True)
        _tb(s, portal, cx + px(0.15), px(5.5), px(5.1), px(0.4),
            font=FONT_B, size=13, color=LIGHT_BG)
    # Security rules
    _tb(s, "Spring Security 접근 제어 규칙", px(0.5), px(6.25), px(10), px(0.45),
        font=FONT_T, size=16, color=NAVY, bold=True)
    rules = [
        ("/backoffice/super/**", "SUPER_ADMIN", NAVY),
        ("/backoffice/staff/**", "SUPER_ADMIN + STAFF", BLUE_GRAY),
        ("/partner/promoter/**", "PROMOTER", RGBColor(0x17,0x5F,0x8A)),
        ("/partner/venue/**",    "VENUE_MANAGER", RGBColor(0x1B,0x6C,0x3A)),
    ]
    for i, (pattern, role, col) in enumerate(rules):
        rx = px(0.5) + i * px(4.45)
        _rect(s, rx, px(6.85), px(4.2), px(2.8), fill_color=WHITE, border_color=DIVIDER, border_pt=1)
        _rect(s, rx, px(6.85), px(4.2), px(0.4), fill_color=col)
        _tb(s, pattern, rx + px(0.1), px(7.35), px(4.0), px(0.5),
            font=FONT_B, size=13, color=col, bold=True)
        _tb(s, "→  " + role, rx + px(0.1), px(7.95), px(4.0), px(0.5),
            font=FONT_T, size=14, color=NAVY, bold=True)
    _page_num(s, num)
    return s

def slide_challenges(prs, num):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, "기술적 도전 & 해결", "PART 06")
    challenges = [
        (NAVY,   "JSP EL vs JS 템플릿 리터럴 충돌",
         "문제: JS 템플릿 리터럴 ${item.name}을 JSP EL이 서버사이드에서 'false'로 치환",
         "해결: JS 문자열 연결(+) 방식으로 전면 교체. loadVenueOptions() 동일 수정"),
        (ACCENT, "BCrypt 해시 불일치 — 로그인 전면 불가",
         "문제: 분산된 SQL 파일 간 해시 버전 불일치로 모든 계정 로그인 실패",
         "해결: schema_total.sql + data_total.sql 단일화, $2a$10$ 해시 일괄 교체"),
        (ORANGE, "Redis 장애 시 ticket-user 기동 실패",
         "문제: LettuceConnectionFactory가 Redis 연결 실패 시 즉시 예외 발생",
         "해결: graceful 강등 로직 — Redis 불가 시 DB-only 모드로 자동 전환"),
        (GREEN,  "Mapper 직접 주입 → 서비스 계층 위반",
         "문제: 컨트롤러에서 Mapper 9개 직접 주입. 트랜잭션 경계·재사용성 취약",
         "해결: Phase 1 — 전 매퍼 Service 메서드로 이전, @Transactional 적용"),
    ]
    for i, (col, title, prob, sol) in enumerate(challenges):
        row, c = divmod(i, 2)
        x = px(0.5) + c * px(9.15)
        y = px(1.55) + row * px(4.15)
        h = px(3.9)
        _rect(s, x, y, px(8.9), h, fill_color=WHITE, border_color=DIVIDER, border_pt=1)
        _rect(s, x, y, px(8.9), px(0.5), fill_color=col)
        _tb(s, title, x + px(0.15), y + px(0.58), px(8.6), px(0.55),
            font=FONT_T, size=16, color=col, bold=True)
        _tb(s, "🔴 " + prob, x + px(0.15), y + px(1.25), px(8.6), px(1.0),
            font=FONT_B, size=13, color=BLACK)
        _tb(s, "✅ " + sol, x + px(0.15), y + px(2.4), px(8.6), px(1.2),
            font=FONT_B, size=13, color=GREEN)
    _page_num(s, num)
    return s

def slide_roadmap(prs, num):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _header(s, "향후 개발 계획 (Phase 3~5)", "PART 07")
    phases = [
        (NAVY,  "Phase 3\n예매 동시성 강화",
         ["Redis + DB 정합성 완전 확보", "환불 엣지 케이스 처리", "결제 PG 실제 연동", "cancelOrphan 배치 스케줄러"]),
        (ACCENT,"Phase 4\n유저 기능 확장",
         ["공연 검색·필터 (카테고리·날짜·가격)", "쿠폰 적용 UI (결제 화면)", "환불 플로우 (마이페이지)", "Elasticsearch 검색 엔진 연동"]),
        (GREEN, "Phase 5\n코드 품질 정리",
         ["DateUtil 중복 제거 (ticket-user → common)", "JSP 날짜 헬퍼 분기 제거", "MemberRole enum dead code 정리", "결제 게이트웨이 mock 제거"]),
        (ORANGE,"Phase 6\n운영 모니터링",
         ["파트너 판매 리포트 차트", "어드민 회원 상세 조회·강제탈퇴", "QR 스캔 입장 시스템", "시스템 메트릭 대시보드"]),
    ]
    pw = px(4.2)
    for i, (col, title, items) in enumerate(phases):
        x = px(0.5) + i * (pw + px(0.28))
        _rect(s, x, px(1.55), pw, px(8.55), fill_color=WHITE, border_color=DIVIDER, border_pt=1)
        _rect(s, x, px(1.55), pw, px(0.85), fill_color=col)
        _tb(s, title, x + px(0.15), px(1.63), pw - px(0.3), px(0.7),
            font=FONT_T, size=15, color=WHITE, bold=True)
        for j, item in enumerate(items):
            iy = px(2.6) + j * px(0.95)
            _rect(s, x + px(0.15), iy + px(0.12), px(0.22), px(0.22), fill_color=col)
            _tb(s, item, x + px(0.48), iy, pw - px(0.65), px(0.82),
                font=FONT_B, size=13, color=BLACK)
    _page_num(s, num)
    return s

def slide_conclusion(prs, num):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, NAVY)
    _rect(s, 0, 0, px(0.5), H, fill_color=ACCENT)
    _tb(s, "결  론", px(1.5), px(1.2), px(16), px(1.0),
        font=FONT_T, size=50, color=WHITE, bold=True)
    _tb(s, "TicketLegacy — 핵심 성과 요약",
        px(1.5), px(2.5), px(16), px(0.6),
        font=FONT_B, size=20, color=BLUE_GRAY)
    _rect(s, px(1.5), px(3.3), px(16.3), px(0.04), fill_color=BLUE_GRAY)
    kpis = [
        (px(1.5),  "45개", "DB 테이블\n(schema_total.sql)"),
        (px(5.5),  "200+", "공연 데이터\n(WITH RECURSIVE)"),
        (px(9.5),  "3-WAR", "독립 포털\n(JWT 공유 인증)"),
        (px(13.5), "4-FSM", "상태 도메인\n(Member·Promoter·VM·Perf)"),
    ]
    for kx, val, desc in kpis:
        _tb(s, val, kx, px(3.8), px(3.8), px(1.3),
            font=FONT_T, size=44, color=WHITE, bold=True)
        _tb(s, desc, kx, px(5.3), px(3.8), px(1.2),
            font=FONT_B, size=16, color=BLUE_GRAY)
    _rect(s, px(1.5), px(6.8), px(16.3), px(0.04), fill_color=BLUE_GRAY)
    _tb(s, "Spring Legacy MVC 5.3 기반 엔터프라이즈 수준의 공연 예매 플랫폼 구현 완료",
        px(1.5), px(7.2), px(16.3), px(0.7),
        font=FONT_T, size=22, color=WHITE, bold=True)
    _tb(s, "Dual Defense 좌석 선점 · FSM 상태 관리 · JWT 3-WAR 공유 인증 · BCrypt 보안 · 200+ 실데이터 확보",
        px(1.5), px(8.1), px(16.3), px(0.7),
        font=FONT_B, size=16, color=BLUE_GRAY)
    _page_num(s, num)
    return s

def slide_qa(prs, num):
    layout = prs.slide_layouts[6]
    s = prs.slides.add_slide(layout)
    _set_bg(s, BG_COLOR)
    _rect(s, 0, 0, W, px(0.5), fill_color=ACCENT)
    _tb(s, "Q & A", px(0.5), px(2.5), W, px(3.0),
        font=FONT_T, size=96, color=NAVY, bold=True, align=PP_ALIGN.CENTER)
    _tb(s, "질의응답", px(0.5), px(5.8), W, px(1.0),
        font=FONT_B, size=28, color=BLUE_GRAY, align=PP_ALIGN.CENTER)
    _tb(s, "감사합니다",
        px(0.5), px(7.2), W, px(0.7),
        font=FONT_T, size=24, color=NAVY, align=PP_ALIGN.CENTER)
    _tb(s, "TicketLegacy  |  Spring MVC 5.3  |  2026.05",
        px(0.5), px(8.2), W, px(0.5),
        font=FONT_B, size=15, color=BLUE_GRAY, align=PP_ALIGN.CENTER)
    _page_num(s, num)
    return s

# ── Build full presentation ──────────────────────────────
def build(template_path, output_path):
    prs = Presentation(template_path)
    # Remove all existing slides — iterate over copy to avoid mutation issues
    slide_ids = list(prs.slides._sldIdLst)
    for sld_id in slide_ids:
        rId = sld_id.get('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id')
        if rId:
            try:
                prs.part.drop_rel(rId)
            except Exception:
                pass
        prs.slides._sldIdLst.remove(sld_id)

    n = [0]
    def nx(): n[0] += 1; return n[0]

    # 1. Title
    slide_title(prs); nx()

    # 2. Script 1
    slide_script(prs, nx(), [
        "안녕하세요. TicketLegacy 프로젝트 발표를 시작하겠습니다.",
        "",
        "저희 팀은 Spring Legacy MVC 5.3 기반의 공연 예매 플랫폼을 개발했습니다.",
        "단순한 토이 프로젝트가 아닌, 실제 운영 환경을 가정한 엔터프라이즈 수준의 설계를 목표로 했습니다.",
        "",
        "3개의 독립 WAR — 사용자, 파트너, 어드민 포털이 단일 DB를 공유하며,",
        "JWT 토큰 기반 인증, Redis 좌석 락, FSM 상태 관리 등 핵심 기술을 적용했습니다.",
        "",
        "지금부터 프로젝트의 배경부터 기술 구현, 그리고 향후 계획까지 순서대로 설명드리겠습니다.",
    ])

    # 3. TOC
    slide_toc(prs, nx())

    # 4. Script TOC
    slide_script(prs, nx(), [
        "발표는 총 7개 파트로 구성되어 있습니다.",
        "",
        "01 프로젝트 개요 — 왜 이 프로젝트를 선택했는지, 목표는 무엇인지 설명합니다.",
        "02 요구사항 명세 — 사용자·파트너·어드민 포털의 기능 요구사항과 비기능 요구사항을 정리했습니다.",
        "03 시스템 아키텍처 — 멀티모듈 구조와 기술 스택, DB 설계를 설명합니다.",
        "04 핵심 기능 구현 — 동시성 제어, FSM, 인증 보안 등 기술적 깊이를 다룹니다.",
        "05 데이터 & 성과 — 200개 이상의 실데이터 구축과 구현 완성도를 보여드립니다.",
        "06 기술적 도전 & 해결 — 개발 과정에서 만난 주요 이슈와 해결 방법입니다.",
        "07 향후 계획 & 결론 — 로드맵과 핵심 가치로 마무리합니다.",
    ])

    # ── PART 01 ──
    slide_section_break(prs, nx(), "01", "프로젝트 개요", "배경 · 목표 · 개발 환경")

    slide_script(prs, nx(), [
        "Part 1 — 프로젝트 개요입니다.",
        "",
        "TicketLegacy는 인터파크, 예스24 티켓 같은 실제 공연 예매 서비스를 모델로 설계했습니다.",
        "핵심 도전 과제는 두 가지였습니다.",
        "",
        "첫째, 동시에 수천 명이 같은 좌석을 예매하려 할 때 중복 예매를 어떻게 방지할 것인가.",
        "둘째, 공연 등록부터 심사, 승인, 게시까지의 복잡한 워크플로우를 어떻게 안전하게 관리할 것인가.",
        "",
        "이 두 문제를 Redis Dual Defense와 FSM으로 해결했습니다.",
    ])

    slide_bullets(prs, nx(), "프로젝트 배경 & 목표", "PART 01", [
        (NAVY,   "프로젝트 배경",          "실제 티켓 예매 서비스(인터파크·예스24)의 핵심 기능을 Spring Legacy MVC로 구현"),
        (ACCENT, "핵심 도전 과제 1",       "동시 좌석 예매 시 중복 예매 방지 → Redis Lua 스크립트 + DB 낙관적 락"),
        (ACCENT, "핵심 도전 과제 2",       "공연 등록~게시 워크플로우 안전 관리 → FSM(유한 상태 기계) 적용"),
        (GREEN,  "목표 1 — 기능 완성도",   "3-WAR 독립 포털 완전 가동 (사용자·파트너·어드민)"),
        (GREEN,  "목표 2 — 코드 품질",     "Mapper 직접 주입 제거, 서비스 계층 완전 typed, 도메인 봉인"),
        (ORANGE, "목표 3 — 엔터프라이즈",  "운영에서 안 터지는 코드 — 경계값·장애 시나리오·트랜잭션 경계 고려"),
    ])

    slide_script(prs, nx(), [
        "프로젝트 배경과 목표를 설명드렸습니다.",
        "",
        "단순히 CRUD를 구현하는 것이 아니라, 실제 운영 환경에서 발생할 수 있는 문제를",
        "사전에 설계 단계에서 고려하는 것이 목표였습니다.",
        "",
        "특히 '동작하면 끝'이 아니라 '운영에서 안 터지는가'를 기준으로",
        "데이터 0건, 대량 트래픽, 경계값, Redis 장애 등의 시나리오를 모두 고려했습니다.",
    ])

    slide_bullets(prs, nx(), "개발 환경 & 기술 제약사항", "PART 01", [
        (NAVY,   "런타임: Java 11 + Spring MVC 5.3",  "record·sealed class 사용 불가. jakarta.* 절대 금지 → javax.* 유지"),
        (ACCENT, "DB: MySQL 8 — springgreen6",         "3개 WAR 단일 DB 공유. 각 모듈 독립 HikariCP 연결 풀"),
        (GREEN,  "캐시: Redis localhost:6379",          "ticket-user 필수 (좌석 락). ticket-admin은 선택적, ticket-partner 미사용"),
        (ORANGE, "인증: JWT HS256 — JWT_SECRET_KEY",    "환경변수 Base64 인코딩. 3개 서버 동일 시크릿. 역할 기반 포털 분리"),
        (BLUE_GRAY,"빌드: Maven 멀티모듈",              "ticket-common(JAR) ← ticket-user/partner/admin(WAR) 의존"),
        (RGBColor(0x7B,0x1F,0xA2), "뷰: JSP + Tiles 3", "MyBatis 3.5 + JJWT 0.11.5. SPA 없음. 전통적 MVC 패턴"),
    ])

    slide_script(prs, nx(), [
        "개발 환경과 기술 제약사항입니다.",
        "",
        "Spring Boot가 아닌 Spring Legacy MVC 5.3을 선택한 이유는",
        "현업에서 아직도 많이 사용되는 레거시 시스템을 경험하고,",
        "설정 파일(root-context.xml, servlet-context.xml, security-context.xml)을 직접 다루는 역량을 키우기 위해서입니다.",
        "",
        "jakarta 패키지가 아닌 javax 패키지를 사용해야 한다는 제약 조건은",
        "초반에 가장 많은 실수가 있었던 부분으로, 팀원 전원이 반드시 숙지해야 했습니다.",
    ])

    # ── PART 02 ──
    slide_section_break(prs, nx(), "02", "요구사항 명세", "기능 요구사항 · 비기능 요구사항")

    slide_script(prs, nx(), [
        "Part 2 — 요구사항 명세입니다.",
        "",
        "요구사항을 3개 포털로 분류하고, 각 포털의 사용자 역할과 기능을 명세했습니다.",
        "",
        "ticket-user는 일반 회원이 공연을 검색하고 예매하는 포털,",
        "ticket-partner는 기획사와 공연장 담당자가 공연을 등록하고 관리하는 포털,",
        "ticket-admin은 슈퍼어드민과 스태프가 전체 시스템을 관리하는 포털입니다.",
    ])

    slide_cards(prs, nx(), "기능 요구사항 — 포털별 분류", "PART 02", [
        (NAVY, "ticket-user (8080)\n일반 회원 포털", [
            "회원가입 / 로그인 / 로그아웃",
            "공연 목록 조회 & 상세 보기",
            "좌석 선택 & 예매 (Redis 락)",
            "결제 처리 (멱등성 보장)",
            "쿠폰 조회 & 적용",
            "예매 내역 조회 & 취소",
            "대기열(Queue) 진입 관리",
        ]),
        (RGBColor(0x17,0x5F,0x8A), "ticket-partner (8081)\n파트너 포털", [
            "파트너 로그인 (어드민 생성 계정)",
            "공연 등록 & 수정 (DRAFT→REVIEW)",
            "공연회차 & 좌석 등급/가격 설정",
            "좌석 구역 레이아웃 관리",
            "쿠폰 발행 & 관리",
            "QR 입장 스캔 처리",
            "판매 현황 조회",
        ]),
        (RGBColor(0x4A,0x1A,0x6B), "ticket-admin (8082)\n어드민 포털", [
            "회원 목록 조회 & 상태 변경 (FSM)",
            "기획사 승인/반려/정지 (FSM)",
            "공연장담당자 승인/반려 (FSM)",
            "공연 심사 & 승인/반려/게시 (FSM)",
            "공연 상세 미리보기 (일정·좌석)",
            "통계 대시보드 (매출·예매)",
            "쿠폰 템플릿 관리",
        ]),
    ])

    slide_script(prs, nx(), [
        "3개 포털의 기능 요구사항을 카드 형태로 정리했습니다.",
        "",
        "ticket-user는 일반 사용자가 사용하는 포털로, 공연 탐색부터 결제까지 전체 예매 플로우를 담당합니다.",
        "특히 대기열(Queue) 시스템은 인기 공연의 동시 접속을 제어하기 위해 추가했습니다.",
        "",
        "ticket-partner는 기획사와 공연장 담당자 전용으로, 공연 등록 후 DRAFT 상태로 시작해",
        "어드민의 심사를 거쳐 PUBLISHED 상태가 되어야 판매가 시작됩니다.",
        "",
        "ticket-admin은 전체 시스템의 관제탑 역할로, 모든 FSM 상태 전환의 최종 승인권을 가집니다.",
    ])

    slide_bullets(prs, nx(), "기능 요구사항 — 좌석 예매 상세 플로우", "PART 02", [
        (NAVY,   "FR-001  좌석 선택",      "사용자가 공연 회차를 선택하고 구역·좌석 등급별 좌석을 선택"),
        (ACCENT, "FR-002  Redis 선점",     "Lua 스크립트로 seat_inventory.status를 AVAILABLE → HOLD로 원자 전환 (TTL 10분)"),
        (GREEN,  "FR-003  결제 요청",      "PENDING 예약 생성 후 결제 Gateway 호출. idempotency_key로 중복 결제 차단"),
        (ORANGE, "FR-004  예약 확정",      "결제 성공 → PENDING → CONFIRMED, seat_inventory → RESERVED (동일 트랜잭션)"),
        (BLUE_GRAY,"FR-005  타임아웃 처리","@Scheduled 3초 간격으로 만료 HOLD 좌석 → AVAILABLE 복원, PENDING 예약 취소"),
        (RGBColor(0xC0,0x39,0x2B), "FR-006  취소·환불", "CONFIRMED → CANCELLED. seat_inventory → AVAILABLE 복원. REFUNDED 상태 관리"),
    ])

    slide_script(prs, nx(), [
        "좌석 예매의 상세 플로우입니다.",
        "",
        "일반적인 CRUD와 달리, 예매 시스템에서 가장 중요한 것은 동시성 제어입니다.",
        "",
        "FR-002의 Redis Lua 스크립트 선점 방식은,",
        "여러 사용자가 동시에 같은 좌석을 선택할 때 정확히 한 명만 성공하도록 보장합니다.",
        "",
        "FR-005의 @Scheduled 배치는 결제를 완료하지 못하고 이탈한 사용자의 좌석을",
        "자동으로 해제하여 다음 사용자가 예매할 수 있도록 합니다.",
    ])

    slide_bullets(prs, nx(), "비기능 요구사항", "PART 02", [
        (NAVY,   "NFR-001  보안",      "JWT HttpOnly 쿠키, BCrypt 해싱, CSRF 방어, 역할 기반 접근 제어(RBAC)"),
        (ACCENT, "NFR-002  동시성",    "Redis Lua 원자 연산 + DB 조건부 UPDATE로 Race Condition 방지"),
        (GREEN,  "NFR-003  멱등성",    "Payment.idempotency_key UNIQUE 제약으로 네트워크 재시도 중복 결제 차단"),
        (ORANGE, "NFR-004  가용성",    "Redis 장애 시 DB-only 모드 graceful 강등. 단일 장애점 최소화"),
        (BLUE_GRAY,"NFR-005  확장성", "Maven 멀티모듈로 포털별 독립 배포. ticket-common JAR 공유로 코드 중복 방지"),
        (RGBColor(0x7B,0x1F,0xA2), "NFR-006  유지보수성", "FSM validateTransition() 중앙화. 서비스 계층 완전 typed. 매퍼 직접 주입 금지"),
    ])

    slide_script(prs, nx(), [
        "비기능 요구사항입니다. 기능 요구사항만큼 중요한 항목들입니다.",
        "",
        "NFR-001 보안에서 특히 강조할 점은 JWT를 HttpOnly 쿠키로 전달한다는 것입니다.",
        "LocalStorage나 일반 쿠키가 아닌 HttpOnly 쿠키를 사용함으로써 XSS 공격으로부터 토큰을 보호합니다.",
        "",
        "NFR-004 가용성 — Redis가 다운되어도 예매 서비스가 중단되지 않도록",
        "DB-only 모드로의 자동 강등을 설계했습니다. 성능은 저하되지만 서비스는 유지됩니다.",
        "",
        "NFR-006은 코드 품질 관련 항목으로, 8차~11차 세션에 걸쳐 단계적으로 달성했습니다.",
    ])

    # ── PART 03 ──
    slide_section_break(prs, nx(), "03", "시스템 아키텍처", "멀티모듈 · 기술 스택 · DB 설계")

    slide_script(prs, nx(), [
        "Part 3 — 시스템 아키텍처입니다.",
        "",
        "이 프로젝트의 가장 큰 구조적 특징은 단일 DB를 공유하는 3-WAR 분리 아키텍처입니다.",
        "",
        "각 WAR는 독립적으로 배포되며, 포트도 8080, 8081, 8082로 분리되어 있습니다.",
        "그러나 모든 비즈니스 로직과 도메인 모델은 ticket-common JAR 하나에 집중되어 있어,",
        "코드 중복 없이 3개 포털이 같은 서비스 계층을 공유합니다.",
    ])

    slide_arch_diagram(prs, nx())

    slide_script(prs, nx(), [
        "시스템 아키텍처 다이어그램입니다.",
        "",
        "상단 3개 박스가 각각의 WAR 포털이고, 중앙의 ticket-common이 공유 JAR입니다.",
        "하단 4개는 공유 인프라 — MySQL, Redis, JWT, Spring Security입니다.",
        "",
        "주목할 점은 ticket-user ↔ ticket-partner ↔ ticket-admin 간에 직접 의존이 없다는 것입니다.",
        "3개 포털의 소통은 오직 DB와 JWT를 통해서만 이루어집니다.",
        "",
        "이 구조 덕분에 어드민 포털이 다운되어도 사용자 예매 서비스는 영향을 받지 않습니다.",
    ])

    slide_two_panel(prs, nx(), "Maven 멀티모듈 구조", "PART 03",
        "모듈 의존 관계",
        [
            "ticket-common (JAR) — 공유 도메인·서비스·매퍼",
            "ticket-user → ticket-common",
            "ticket-partner → ticket-common",
            "ticket-admin → ticket-common",
            "WAR 간 직접 의존 없음",
            "ticket-common은 외부 의존성만 보유",
            "단방향 의존 — 순환 의존 구조적 불가",
        ],
        "ticket-common 구성",
        [
            "도메인 20개 (Member, Performance, Seat...)",
            "서비스 11개 (MemberService, ReservationService...)",
            "매퍼 인터페이스 21개",
            "MyBatis XML 18개",
            "Command/Query/DTO 클래스",
            "FSM Enum 4개 (상태 전환 로직 내장)",
            "GlobalExceptionHandler, ApiResponse<T>",
        ]
    )

    slide_script(prs, nx(), [
        "Maven 멀티모듈 구조의 핵심은 단방향 의존성입니다.",
        "",
        "ticket-common에 비즈니스 로직을 집중시켜, 3개 WAR가 이를 공유하는 구조입니다.",
        "이로 인해 순환 의존이 구조적으로 불가능하고, ticket-common의 서비스 메서드를 수정하면",
        "반드시 3개 WAR 전체에서 해당 메서드 호출을 확인해야 한다는 규칙이 생깁니다.",
        "",
        "FSM Enum도 ticket-common에 위치하므로, 상태 전환 로직이 단일 지점에서 관리됩니다.",
        "어느 포털에서 상태를 바꾸든 동일한 validateTransition() 규칙이 적용됩니다.",
    ])

    slide_bullets(prs, nx(), "기술 스택", "PART 03", [
        (NAVY,   "Spring MVC 5.3 + Tomcat 9",         "XML 기반 설정 (root-context, servlet-context, security-context). Boot 아님"),
        (ACCENT, "MyBatis 3.5 + MySQL 8",              "동적 SQL (resultMap, association, collection). namespace 기반 매퍼"),
        (GREEN,  "Redis (Lettuce) + Spring Data Redis", "좌석 선점 Lua 스크립트. @Scheduled 만료 처리. 장애 시 graceful 강등"),
        (ORANGE, "JJWT 0.11.5 + Spring Security 5.8",  "HS256 서명. HttpOnly 쿠키. JwtAuthenticationFilter. 역할 기반 URL 접근 제어"),
        (BLUE_GRAY,"JSP + Tiles 3 + jQuery/AJAX",      "서버사이드 렌더링. SweetAlert2 UX. 차트.js 통계 시각화"),
        (RGBColor(0x7B,0x1F,0xA2), "BCrypt + Validation", "PasswordEncoder. @Valid + GlobalExceptionHandler. ApiResponse<T> 표준화"),
    ], two_col=False)

    slide_script(prs, nx(), [
        "기술 스택입니다.",
        "",
        "Spring Boot를 사용하지 않았기 때문에 자동 설정에 의존하지 않고,",
        "모든 Bean을 직접 XML로 등록하고 관리합니다. 이 경험 자체가 큰 학습이었습니다.",
        "",
        "Redis는 Lettuce 클라이언트를 사용했으며, 좌석 선점에 Lua 스크립트를 활용합니다.",
        "Lua 스크립트는 Redis 서버에서 원자적으로 실행되므로, 분산 환경에서도 race condition이 없습니다.",
        "",
        "JJWT 0.11.5는 현재 사용 중인 Deprecated API가 있어, 향후 1.0.x 마이그레이션이 필요합니다.",
    ])

    slide_bar_chart(prs, nx(), "핵심 DB 테이블 — 도메인별 분포", "PART 03",
        "도메인 카테고리별 테이블 수",
        ["공연·일정", "회원·역할", "좌석·구역", "예매·결제", "쿠폰", "공지·부가"],
        [("테이블 수", (8, 6, 9, 7, 4, 11))]
    )

    slide_script(prs, nx(), [
        "DB 설계 현황입니다. 총 45개 테이블을 6개 도메인으로 분류했습니다.",
        "",
        "공연·일정 영역이 8개로 가장 복잡합니다.",
        "performance, performance_schedule, venue, venue_section, stage_config 등이 포함됩니다.",
        "",
        "좌석·구역 영역의 seat_inventory 테이블은 200개 이상의 공연에 대해",
        "WITH RECURSIVE CTE로 12,840개 이상의 레코드를 자동 생성했습니다.",
        "",
        "모든 DDL은 schema_total.sql 하나로 통합되어 있어, DB 재초기화가 3단계로 간소화되었습니다.",
    ])

    # ── PART 04 ──
    slide_section_break(prs, nx(), "04", "핵심 기능 구현", "동시성 제어 · FSM · 인증·보안")

    slide_script(prs, nx(), [
        "Part 4 — 핵심 기능 구현입니다. 기술적 깊이를 가장 많이 다루는 파트입니다.",
        "",
        "세 가지 핵심 기술을 소개합니다.",
        "첫째, Redis Dual Defense — 동시 좌석 예매의 중복 방지.",
        "둘째, FSM — 공연·회원·파트너의 상태 전환 안전 보장.",
        "셋째, JWT + Spring Security — 3개 포털의 독립 인증 체계.",
    ])

    slide_dual_defense(prs, nx())

    slide_script(prs, nx(), [
        "Dual Defense 동시성 제어 구조입니다.",
        "",
        "1단계: Redis Lua 스크립트가 AVAILABLE 확인과 HOLD 전환을 원자적으로 수행합니다.",
        "Lua는 Redis 서버에서 단일 스레드로 실행되므로, 동시에 두 요청이 들어와도",
        "정확히 하나만 HOLD 전환에 성공합니다.",
        "",
        "2단계: DB의 WHERE status='AVAILABLE' 조건부 UPDATE가 2차 방어선이 됩니다.",
        "Redis가 장애 상태여도 이 쿼리가 중복 예매를 막습니다.",
        "",
        "3단계: idempotency_key UNIQUE 제약으로 결제 재시도 시 중복 결제를 차단합니다.",
    ])

    slide_fsm(prs, nx())

    slide_script(prs, nx(), [
        "FSM — 유한 상태 기계(Finite State Machine) 구현입니다.",
        "",
        "4개 도메인에 FSM을 적용했습니다: Member, Promoter, VenueManager, Performance.",
        "각 Enum에 canTransitionTo() 또는 validateTransition() 메서드가 내장되어 있어,",
        "허용되지 않은 상태 전환 시도 시 즉시 BusinessException(400)을 던집니다.",
        "",
        "예를 들어, WITHDRAWN 상태의 회원은 어떤 상태로도 전환이 불가능합니다.",
        "이는 탈퇴 회원의 계정이 복구될 수 없다는 비즈니스 규칙을 코드로 강제한 것입니다.",
        "",
        "이 구조 덕분에 상태 전환 로직이 분산되지 않고 단일 Enum에 집중됩니다.",
    ])

    slide_jwt_security(prs, nx())

    slide_script(prs, nx(), [
        "인증과 보안 아키텍처입니다.",
        "",
        "가장 중요한 설계 결정은 포털별 쿠키명 분리입니다.",
        "USER_TOKEN, PARTNER_TOKEN, ADMIN_TOKEN — 세 쿠키를 분리함으로써",
        "localhost에서 개발 시 쿠키가 덮어씌워지는 문제를 원천 차단했습니다.",
        "",
        "JwtAuthenticationFilter가 HttpOnly 쿠키에서 JWT를 파싱해 SecurityContext에 설정하고,",
        "각 포털의 security-context.xml에서 URL 패턴과 역할을 매핑합니다.",
        "",
        "3개 서버가 동일한 JWT_SECRET_KEY를 공유하므로, 발급 서버와 검증 서버가 달라도 됩니다.",
    ])

    # ── PART 05 ──
    slide_section_break(prs, nx(), "05", "데이터 & 성과", "200+ 공연 데이터셋 · 구현 완성도")

    slide_script(prs, nx(), [
        "Part 5 — 데이터셋 구축과 구현 성과입니다.",
        "",
        "초기에는 4~14개의 공연 데이터만 있어 Elasticsearch 테스트나 성능 검증이 어려웠습니다.",
        "12차 세션에서 WITH RECURSIVE CTE를 활용해 200개 이상의 공연 데이터를 자동 생성했습니다.",
        "",
        "단순히 공연만 넣은 것이 아니라, 각 공연에 딸린 일정·좌석등급·좌석·인벤토리까지",
        "유기적으로 생성되어 실제 서비스와 유사한 데이터 환경을 구축했습니다.",
    ])

    slide_donut_chart(prs, nx())

    slide_script(prs, nx(), [
        "도메인별 데이터 분포 현황입니다.",
        "",
        "214건의 공연 데이터가 있으며, 공연당 평균 4개의 회차(Schedule)가 생성됩니다.",
        "12,840개의 좌석 인벤토리는 WITH RECURSIVE CTE로 자동 생성된 것으로,",
        "수동으로 입력하면 수 시간이 걸릴 데이터를 스크립트 한 번으로 해결했습니다.",
        "",
        "poster_url은 picsum.photos 시드 URL로 정규화되어, 실제 이미지가 표시됩니다.",
        "description은 HTML 형식으로 저장되어 Elasticsearch 인덱싱 준비가 완료된 상태입니다.",
    ])

    slide_flow(prs, nx(), "E2E 데모 플로우", "PART 05", [
        (NAVY,  "1", "파트너 로그인\n공연 등록",
         "promoter1@test.com\n\nDRAFT 상태로\n공연 등록\n\n공연회차·\n좌석등급·\n가격 설정"),
        (ACCENT,"2", "어드민 심사\n승인·게시",
         "admin@ticketlegacy\n.com\n\nREVIEW →\nAPPROVED →\nPUBLISHED\n\n미리보기 후\n게시 승인"),
        (GREEN, "3", "사용자 검색\n좌석 선택",
         "user1@test.com\n\nON_SALE 공연\n목록에 표시\n\n공연 상세 →\n회차 선택 →\n좌석 선택"),
        (ORANGE,"4", "예매 & 결제",
         "Redis Lua\n원자 선점\n\nPENDING 예약\n생성\n\n결제 완료 →\nCONFIRMED\n전환"),
        (RGBColor(0x7B,0x1F,0xA2), "5", "예매 확인\n취소·환불",
         "마이페이지에서\n예매 내역 확인\n\n취소 시\nCANCELLED\n\n좌석 →\nAVAILABLE\n복원"),
    ])

    slide_script(prs, nx(), [
        "End-to-End 전체 플로우입니다. 5단계로 공연 등록부터 예매·취소까지 완전한 사이클을 보여줍니다.",
        "",
        "STEP 1: 기획사 담당자가 ticket-partner에 로그인해 공연을 등록합니다. DRAFT 상태로 시작됩니다.",
        "STEP 2: 어드민이 심사 대기 공연을 확인하고, 미리보기 후 APPROVED → PUBLISHED로 전환합니다.",
        "STEP 3: ticket-user의 공연 목록에 ON_SALE 공연이 표시되고, 사용자가 좌석을 선택합니다.",
        "STEP 4: Redis Lua 스크립트가 좌석을 HOLD하고, 결제 완료 시 CONFIRMED로 확정됩니다.",
        "STEP 5: 마이페이지에서 예매를 취소하면 좌석이 AVAILABLE로 복원됩니다.",
        "",
        "이 E2E 플로우는 7차 세션에서 전 구간 검증을 완료했습니다.",
    ])

    # ── PART 06 ──
    slide_section_break(prs, nx(), "06", "기술적 도전 & 해결", "개발 과정의 주요 이슈")

    slide_script(prs, nx(), [
        "Part 6 — 기술적 도전과 해결책입니다.",
        "",
        "개발 과정에서 만난 핵심 이슈 4가지를 소개합니다.",
        "단순 버그가 아닌, 아키텍처 설계와 관련된 근본적인 문제들입니다.",
    ])

    slide_challenges(prs, nx())

    slide_script(prs, nx(), [
        "4가지 핵심 이슈입니다.",
        "",
        "첫 번째 JSP EL vs JS 템플릿 리터럴 충돌은 Spring MVC + JSP 환경의 고전적인 함정입니다.",
        "JSP가 서버사이드에서 ${} 표현식을 먼저 처리하기 때문에,",
        "JS의 템플릿 리터럴이 의도치 않게 서버에서 평가됩니다.",
        "",
        "두 번째 BCrypt 해시 불일치는 여러 SQL 파일이 분산되어 있던 구조적 문제로,",
        "data_total.sql 단일화로 영구 해결했습니다.",
        "",
        "네 번째 매퍼 직접 주입은 8차~11차 세션에 걸쳐 단계적으로 서비스 계층으로 이전했습니다.",
    ])

    # ── PART 07 ──
    slide_section_break(prs, nx(), "07", "향후 계획 & 결론", "로드맵 · 핵심 가치")

    slide_script(prs, nx(), [
        "Part 7 — 향후 계획과 결론입니다.",
        "",
        "현재 Phase 1·2가 완료된 상태이며, Phase 3부터 6까지의 로드맵이 수립되어 있습니다.",
        "",
        "가장 중요한 다음 작업은 Phase 3 — 예매 동시성 완전 확보와 결제 PG 실제 연동입니다.",
        "현재 PaymentService.simulatePgPayment()가 항상 true를 반환하는 mock 상태로,",
        "실제 PG 연동이 필요합니다.",
    ])

    slide_roadmap(prs, nx())

    slide_script(prs, nx(), [
        "Phase 3부터 6까지의 로드맵입니다.",
        "",
        "Phase 3 — 예매 동시성: cancelOrphan 배치 스케줄러와 환불 엣지 케이스, 실제 PG 연동.",
        "Phase 4 — 유저 기능: 공연 검색 필터, 쿠폰 UI, 그리고 Elasticsearch 연동이 핵심입니다.",
        "현재 데이터셋의 description HTML과 poster_url이 이미 Elasticsearch 인덱싱 형식으로 준비되어 있습니다.",
        "",
        "Phase 5 — 코드 정리: DateUtil 중복 제거, MemberRole enum dead code 정리 등.",
        "Phase 6 — QR 입장 스캔, 시스템 메트릭 대시보드로 운영 수준을 높입니다.",
    ])

    slide_conclusion(prs, nx())

    slide_script(prs, nx(), [
        "결론입니다.",
        "",
        "TicketLegacy는 Spring Legacy MVC 5.3 기반의 엔터프라이즈 수준 공연 예매 플랫폼입니다.",
        "",
        "45개 테이블, 200개 이상의 실 데이터, 3개 독립 WAR 포털,",
        "4개 도메인에 FSM 적용, Redis Dual Defense 동시성 제어.",
        "",
        "단순히 '동작하는 코드'를 넘어, '운영에서 안 터지는 코드'를 목표로 설계했습니다.",
        "트랜잭션 경계, 동시성, 멱등성, 보안 — 모든 변경에서 이 네 가지를 점검했습니다.",
        "",
        "이 경험이 실제 현업에서 레거시 시스템을 다루는 역량으로 이어질 것이라고 확신합니다.",
        "감사합니다.",
    ])

    slide_qa(prs, nx())

    slide_script(prs, nx(), [
        "이상으로 TicketLegacy 프로젝트 발표를 마치겠습니다.",
        "",
        "질문이 있으시면 편하게 질문해 주세요.",
        "",
        "혹시 기술적인 부분에서 더 깊이 알고 싶으신 내용이 있다면,",
        "Redis Lua 스크립트, FSM 구현 방식, JWT 필터 체인 등 어떤 부분이든 설명 가능합니다.",
        "",
        "감사합니다.",
    ])

    prs.save(output_path)
    print(f"[OK] Saved {n[0]} slides -> {output_path}")

if __name__ == "__main__":
    build(
        r"D:\spring-legacy\ticket-parent\tr(티레).pptx",
        r"D:\spring-legacy\ticket-parent\ticketlegacy_presentation.pptx"
    )
