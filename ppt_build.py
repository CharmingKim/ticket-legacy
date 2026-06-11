"""
TicketLegacy PPT 수정 스크립트
- 슬라이드 7: 미구현 항목 제거
- ER 다이어그램 슬라이드 추가 (슬라이드 14 위치)
- 배포 아키텍처 슬라이드 추가 (슬라이드 20 위치)
- 출력: ticketlegacy_final.pptx
"""
import sys, io, copy
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.oxml.ns import qn
from pptx.enum.shapes import MSO_SHAPE_TYPE
from lxml import etree

SRC = 'D:/springGreen/springframework/works/ticket-parent/ticketlegacy_v4.pptx'
DST = 'D:/springGreen/springframework/works/ticket-parent/ticketlegacy_final.pptx'

prs = Presentation(SRC)
W = prs.slide_width   # 9144000
H = prs.slide_height  # 5143500

# ── 색상 팔레트 ──────────────────────────────────────────────────────────
BG      = RGBColor(0x0D, 0x11, 0x17)
WHITE   = RGBColor(0xFF, 0xFF, 0xFF)
LGRAY   = RGBColor(0xC0, 0xC8, 0xE0)
ACCENT  = RGBColor(0x3D, 0x8E, 0xFF)   # 밝은 파랑
GOLD    = RGBColor(0xFF, 0xC8, 0x5C)   # 골드
GREEN   = RGBColor(0x06, 0xD6, 0xA0)   # 민트
RED     = RGBColor(0xEF, 0x47, 0x6F)   # 레드
PURPLE  = RGBColor(0xA8, 0x6E, 0xFF)   # 보라
TEAL    = RGBColor(0x00, 0xC9, 0xC8)   # 틸
NAVY    = RGBColor(0x04, 0x1F, 0x60)   # 네이비


# ════════════════════════════════════════════════════════════════════════
# 헬퍼 함수
# ════════════════════════════════════════════════════════════════════════

def set_bg(slide, color=BG):
    fill = slide.background.fill
    fill.solid()
    fill.fore_color.rgb = color


def add_textbox(slide, text, x, y, w, h, size=12, bold=False,
                color=WHITE, align=PP_ALIGN.LEFT, wrap=True):
    tb = slide.shapes.add_textbox(x, y, w, h)
    tb.text_frame.word_wrap = wrap
    p = tb.text_frame.paragraphs[0]
    p.text = text
    p.alignment = align
    run = p.runs[0]
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.color.rgb = color
    return tb


def add_rect(slide, x, y, w, h, fill_color, line_color=None, line_width=Pt(0.75)):
    from pptx.util import Pt as _Pt
    shape = slide.shapes.add_shape(1, x, y, w, h)
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill_color
    if line_color:
        shape.line.color.rgb = line_color
        shape.line.width = line_width
    else:
        shape.line.fill.background()
    return shape


def entity_box(slide, x, y, w, h, title, fields, accent, title_size=9, field_size=7.5):
    """도메인 엔티티 박스 (제목 + 필드 목록)"""
    box = add_rect(slide, x, y, w, h, fill_color=RGBColor(0x14, 0x1C, 0x2C),
                   line_color=accent, line_width=Pt(1.2))

    # 제목 배경 바
    title_h = Pt(16)
    add_rect(slide, x, y, w, int(title_h), fill_color=accent)

    # 제목 텍스트
    tb = slide.shapes.add_textbox(x + Pt(4), y, w - Pt(8), int(title_h))
    tf = tb.text_frame
    p = tf.paragraphs[0]
    p.text = title
    p.alignment = PP_ALIGN.LEFT
    r = p.runs[0]
    r.font.size = Pt(title_size)
    r.font.bold = True
    r.font.color.rgb = WHITE

    # 필드 텍스트
    field_y = y + int(title_h) + Pt(3)
    field_h = h - int(title_h) - Pt(6)
    tb2 = slide.shapes.add_textbox(x + Pt(6), field_y, w - Pt(10), field_h)
    tf2 = tb2.text_frame
    tf2.word_wrap = True
    first = True
    for f in fields:
        if first:
            p2 = tf2.paragraphs[0]
            first = False
        else:
            p2 = tf2.add_paragraph()
        p2.text = f
        r2 = p2.runs[0] if p2.runs else p2.add_run()
        r2.font.size = Pt(field_size)
        r2.font.color.rgb = LGRAY
        p2.space_before = Pt(1)


def insert_slide_at(prs, position):
    """blank 슬라이드를 삽입하고 position으로 이동"""
    layout = prs.slide_layouts[0]
    slide = prs.slides.add_slide(layout)
    # XML에서 슬라이드 순서 조정
    sldIdLst = prs.slides._sldIdLst
    items = list(sldIdLst)
    moved = items[-1]
    sldIdLst.remove(moved)
    sldIdLst.insert(position, moved)
    return slide


def slide_section_header(prs, position, part_num, part_en, title_ko, subtitle_ko):
    """파트 섹션 헤더 슬라이드"""
    slide = insert_slide_at(prs, position)
    set_bg(slide)
    # 파트 번호
    add_textbox(slide, f'{part_num:02d}', Inches(0.6), Inches(1.8),
                Inches(1.5), Inches(1.5), size=72, bold=True, color=ACCENT, align=PP_ALIGN.CENTER)
    # PART label
    add_textbox(slide, f'PART  {part_num:02d}', Inches(2.0), Inches(2.0),
                Inches(5), Inches(0.6), size=11, bold=True, color=ACCENT)
    # 한국어 제목
    add_textbox(slide, title_ko, Inches(2.0), Inches(2.5),
                Inches(7), Inches(0.9), size=28, bold=True, color=WHITE)
    # 부제
    add_textbox(slide, subtitle_ko, Inches(2.0), Inches(3.3),
                Inches(7), Inches(0.5), size=13, color=LGRAY)
    return slide


# ════════════════════════════════════════════════════════════════════════
# 1. 슬라이드 7 수정 — 미구현 항목 제거
# ════════════════════════════════════════════════════════════════════════
REMOVE_TEXTS = {'QR 입장 스캔 처리', '판매 현황 조회'}
slide7 = prs.slides[6]
to_del = []
for shape in slide7.shapes:
    if hasattr(shape, 'text') and shape.text.strip() in REMOVE_TEXTS:
        to_del.append(shape._element)
for el in to_del:
    el.getparent().remove(el)
print('✅ 슬라이드 7 수정 완료 (미구현 2개 제거)')


# ════════════════════════════════════════════════════════════════════════
# 2. 구현 기능 전체 현황 슬라이드 추가 (슬라이드 8 위치 = index 7)
# ════════════════════════════════════════════════════════════════════════
feat_slide = insert_slide_at(prs, 7)
set_bg(feat_slide)

add_textbox(feat_slide, '구현 기능 전체 현황 — 포털별 상세',
            Inches(0.4), Inches(0.12), Inches(12), Inches(0.55),
            size=20, bold=True, color=WHITE)
add_textbox(feat_slide, '소스코드 기준 실제 구현 확인 · 28개 테이블 사용 · Mapper XML 27개',
            Inches(0.4), Inches(0.65), Inches(12), Inches(0.32),
            size=10, color=LGRAY)

line_f = feat_slide.shapes.add_shape(1, Inches(0.4), Inches(0.94), Inches(11.8), Pt(1.2))
line_f.fill.solid(); line_f.fill.fore_color.rgb = ACCENT
line_f.line.fill.background()

COL_W = Inches(3.9)
COL_H = Inches(4.45)
ROW_Y = Inches(1.03)

# ── Column 1: ticket-user ──
add_rect(feat_slide, Inches(0.35), ROW_Y, COL_W, COL_H,
         fill_color=RGBColor(0x05, 0x22, 0x18), line_color=GREEN, line_width=Pt(1.2))
add_textbox(feat_slide, '🟢  ticket-user  :8080',
            Inches(0.45), ROW_Y + Pt(5), COL_W - Pt(10), Pt(18),
            size=10, bold=True, color=GREEN)
user_items = [
    '공연 목록 다중 필터 검색 (장르/가격/날짜/정렬)',
    '인터랙티브 좌석 지도 (실시간 상태 표시)',
    'Dual-Defense 좌석 선점 (Redis Lua + DB)',
    '대기열 (Redis Sorted Set, 500명 동시 제한)',
    '결제 멱등성 키 (중복 결제 방지)',
    '날짜 기반 환불 수수료 계산 (D-10/7/3/1)',
    '쿠폰 적용 + 환불 시 쿠폰 자동 복구',
    '위시리스트 / 취소 대기 (Waitlist)',
    '공연 리뷰 (1~5점 평점)',
    '디지털 티켓 조회',
    '1:1 문의 / 공지사항 / FAQ',
    '회원 가입·로그인·프로필·탈퇴 (FSM)',
]
tb_u = feat_slide.shapes.add_textbox(Inches(0.45), ROW_Y + Pt(26), COL_W - Pt(12), COL_H - Pt(32))
tf_u = tb_u.text_frame; tf_u.word_wrap = True
for i, item in enumerate(user_items):
    p = tf_u.paragraphs[0] if i == 0 else tf_u.add_paragraph()
    p.text = f'· {item}'
    r = p.runs[0] if p.runs else p.add_run()
    r.font.size = Pt(8.2)
    r.font.color.rgb = LGRAY
    p.space_before = Pt(1.8)

# ── Column 2: ticket-partner ──
add_rect(feat_slide, Inches(4.3), ROW_Y, COL_W, COL_H,
         fill_color=RGBColor(0x22, 0x18, 0x04), line_color=GOLD, line_width=Pt(1.2))
add_textbox(feat_slide, '🟡  ticket-partner  :8081',
            Inches(4.4), ROW_Y + Pt(5), COL_W - Pt(10), Pt(18),
            size=10, bold=True, color=GOLD)
partner_items = [
    '[기획사 PROMOTER]',
    '대시보드 KPI (공연 수/매출/정산)',
    '공연 등록 워크플로우 6단계',
    '  초안→스케줄→좌석등급→오버라이드',
    '  →좌석생성→심사요청 (DRAFT→SUBMITTED)',
    '판매 리포트 (공연별)',
    '정산 조회 (연월 선택)',
    '쿠폰 템플릿 조회',
    '',
    '[공연장 담당자 VENUE_MANAGER]',
    '대시보드 (예정 공연 요약)',
    '공연장 구역·좌석 템플릿 관리',
    '스테이지 구성 생성/오버라이드',
    '스케줄 달력 (월별)',
    '입장 체크인 (예매번호 기반 + 메모)',
]
tb_p = feat_slide.shapes.add_textbox(Inches(4.4), ROW_Y + Pt(26), COL_W - Pt(12), COL_H - Pt(32))
tf_p = tb_p.text_frame; tf_p.word_wrap = True
for i, item in enumerate(partner_items):
    p = tf_p.paragraphs[0] if i == 0 else tf_p.add_paragraph()
    is_header = item.startswith('[')
    p.text = item if is_header else (f'· {item}' if item.strip() else '')
    r = p.runs[0] if p.runs else p.add_run()
    r.font.size = Pt(8.2)
    r.font.bold = is_header
    r.font.color.rgb = GOLD if is_header else LGRAY
    p.space_before = Pt(1.8)

# ── Column 3: ticket-admin ──
add_rect(feat_slide, Inches(8.25), ROW_Y, COL_W, COL_H,
         fill_color=RGBColor(0x22, 0x06, 0x10), line_color=RED, line_width=Pt(1.2))
add_textbox(feat_slide, '🔴  ticket-admin  :8082',
            Inches(8.35), ROW_Y + Pt(5), COL_W - Pt(10), Pt(18),
            size=10, bold=True, color=RED)
admin_items = [
    '[SUPER_ADMIN]',
    '대시보드 전체 현황',
    '회원 관리 (검색/상태 변경 FSM)',
    '기획사 관리 (승인/반려/정지 FSM)',
    '공연장 담당자 관리 (승인/반려 FSM)',
    '공연 심사 워크플로우',
    '  승인/반려/게시/초안롤백',
    '공연장 마스터 관리 (구역/템플릿)',
    '스테이지 구성 관리',
    '좌석 hold_type 일괄 변경',
    '  (RESERVED/VIP/STAFF)',
    '정산 관리 (기획사별/연월별)',
    '',
    '[STAFF]',
    '예매 검색·상세·강제 취소',
    '회원 검색',
]
tb_a = feat_slide.shapes.add_textbox(Inches(8.35), ROW_Y + Pt(26), COL_W - Pt(12), COL_H - Pt(32))
tf_a = tb_a.text_frame; tf_a.word_wrap = True
for i, item in enumerate(admin_items):
    p = tf_a.paragraphs[0] if i == 0 else tf_a.add_paragraph()
    is_header = item.startswith('[')
    p.text = item if is_header else (f'· {item}' if item.strip() else '')
    r = p.runs[0] if p.runs else p.add_run()
    r.font.size = Pt(8.2)
    r.font.bold = is_header
    r.font.color.rgb = RED if is_header else LGRAY
    p.space_before = Pt(1.8)

print('✅ 구현 기능 전체 현황 슬라이드 추가 완료')


# ════════════════════════════════════════════════════════════════════════
# 3. ER 다이어그램 슬라이드 추가 (슬라이드 15 위치 = index 14, 기능 슬라이드 추가로 +1)
# ════════════════════════════════════════════════════════════════════════
er_slide = insert_slide_at(prs, 14)
set_bg(er_slide)

# 제목
add_textbox(er_slide, '핵심 도메인 ER 다이어그램', Inches(0.4), Inches(0.15),
            Inches(10), Inches(0.6), size=22, bold=True, color=WHITE)
add_textbox(er_slide, '45개 테이블 중 핵심 12개 엔티티 및 주요 연관관계',
            Inches(0.4), Inches(0.72), Inches(10), Inches(0.35),
            size=11, color=LGRAY)

# 가로 구분선
line = er_slide.shapes.add_shape(1,
    Inches(0.4), Inches(1.0), Inches(11.8), Pt(1.5))
line.fill.solid(); line.fill.fore_color.rgb = ACCENT
line.line.fill.background()

# ── 엔티티 박스 배치 (3열 × 3행) ──────────────────────────────────────
BW = Inches(3.55)   # box width
BH = Inches(1.38)   # box height
GAP_X = Inches(0.18)
GAP_Y = Inches(0.16)
START_X = Inches(0.35)
START_Y = Inches(1.12)

entities = [
    # row 0
    (0, 0, '👤 member', GREEN, [
        '🔑 member_id  PK',
        '   email  UNIQUE',
        '   password (BCrypt)',
        '   role  ENUM',
        '   status  FSM ENUM',
    ]),
    (0, 1, '🏢 promoter', ACCENT, [
        '🔑 promoter_id  PK',
        '→  member_id  FK',
        '   company_name',
        '   approval_status  FSM',
    ]),
    (0, 2, '🏟 venue / venue_section', TEAL, [
        '🔑 venue_id  PK',
        '   name, address',
        '── venue_section ──',
        '🔑 section_id  PK',
        '→  venue_id  FK',
    ]),
    # row 1
    (1, 0, '🎭 performance', GOLD, [
        '🔑 performance_id  PK',
        '→  promoter_id  FK',
        '→  venue_id  FK',
        '   approval_status  FSM',
        '   (DRAFT→PUBLISHED)',
    ]),
    (1, 1, '📅 schedule', GOLD, [
        '🔑 schedule_id  PK',
        '→  performance_id  FK',
        '   start_time',
        '   total_seats',
        '   available_seats',
    ]),
    (1, 2, '🪑 seat / seat_inventory', GREEN, [
        '🔑 seat_id  PK',
        '→  section_id  FK',
        '── seat_inventory ──',
        '→  schedule_id  FK',
        '   status (AVAILABLE/HOLD)',
    ]),
    # row 2
    (2, 0, '📋 reservation', RED, [
        '🔑 reservation_id  PK',
        '→  member_id  FK',
        '→  schedule_id  FK',
        '   status  FSM',
        '   (PENDING→CONFIRMED)',
    ]),
    (2, 1, '💳 payment', RED, [
        '🔑 payment_id  PK',
        '→  reservation_id  FK',
        '   idempotency_key  UNIQUE',
        '   amount, status',
        '   (중복결제 방지)',
    ]),
    (2, 2, '🎟 coupon / coupon_template', PURPLE, [
        '🔑 coupon_id  PK',
        '→  member_id  FK',
        '→  template_id  FK',
        '   status (ISSUED/USED)',
        '   expires_at',
    ]),
]

for (row, col, title, accent, fields) in entities:
    x = START_X + col * (BW + GAP_X)
    y = START_Y + row * (BH + GAP_Y)
    entity_box(er_slide, x, y, BW, BH, title, fields, accent)

print('✅ ER 다이어그램 슬라이드 추가 완료')


# ════════════════════════════════════════════════════════════════════════
# 4. 결제 멱등성 & 환불 수수료 슬라이드 (PART04 인증 다음, PART05 직전 = index 20)
# ════════════════════════════════════════════════════════════════════════
pay_slide = insert_slide_at(prs, 20)
set_bg(pay_slide)

add_textbox(pay_slide, '결제 멱등성 & 날짜 기반 환불 수수료',
            Inches(0.4), Inches(0.12), Inches(12), Inches(0.55),
            size=22, bold=True, color=WHITE)
add_textbox(pay_slide, '중복 결제 원천 차단 · 관람일 기준 단계적 수수료 · 쿠폰 자동 복구',
            Inches(0.4), Inches(0.65), Inches(12), Inches(0.32),
            size=11, color=LGRAY)
line_p = pay_slide.shapes.add_shape(1, Inches(0.4), Inches(0.94), Inches(11.8), Pt(1.2))
line_p.fill.solid(); line_p.fill.fore_color.rgb = ACCENT
line_p.line.fill.background()

# 왼쪽 — 결제 멱등성
add_rect(pay_slide, Inches(0.35), Inches(1.1), Inches(5.7), Inches(4.0),
         fill_color=RGBColor(0x08, 0x1C, 0x30), line_color=ACCENT, line_width=Pt(1.2))
add_textbox(pay_slide, '💳  결제 멱등성 (Idempotency)',
            Inches(0.55), Inches(1.18), Inches(5.3), Pt(20),
            size=13, bold=True, color=ACCENT)

pay_steps = [
    ('문제', '네트워크 오류 시 "결제하기" 재클릭 → 중복 청구 위험', RED),
    ('해결', 'idempotency_key UNIQUE 제약\n동일 키로 재시도 시 INSERT 차단', GREEN),
    ('부가', '결제 실패 시 고아 PENDING 예약\n자동 정리 (orphan cleanup)', GOLD),
]
py = Inches(1.55)
for label, text, color in pay_steps:
    add_rect(pay_slide, Inches(0.55), py, Inches(5.3), Inches(0.95),
             fill_color=RGBColor(0x10, 0x28, 0x44), line_color=color, line_width=Pt(0.8))
    add_textbox(pay_slide, label, Inches(0.65), py + Pt(4), Inches(0.7), Pt(14),
                size=8, bold=True, color=color)
    add_textbox(pay_slide, text, Inches(1.4), py + Pt(4), Inches(4.3), Pt(28),
                size=9, color=LGRAY)
    py += Inches(1.02)

# 오른쪽 — 환불 수수료
add_rect(pay_slide, Inches(6.3), Inches(1.1), Inches(5.7), Inches(4.0),
         fill_color=RGBColor(0x1A, 0x0C, 0x08), line_color=RED, line_width=Pt(1.2))
add_textbox(pay_slide, '🔄  날짜 기반 환불 수수료',
            Inches(6.5), Inches(1.18), Inches(5.3), Pt(20),
            size=13, bold=True, color=RED)

refund_rows = [
    ('관람일 10일 전~',  '전액 환불  (수수료 0%)',   GREEN),
    ('관람일 7~9일 전', '수수료 10%',              GOLD),
    ('관람일 3~6일 전', '수수료 20%',              GOLD),
    ('관람일 1~2일 전', '수수료 30%',              RED),
    ('당일 및 이후',    '환불 불가  (0원)',          RED),
    ('쿠폰 전액환불 시', '사용 쿠폰 자동 복구',       PURPLE),
]
ry = Inches(1.56)
for day, fee, color in refund_rows:
    add_rect(pay_slide, Inches(6.5), ry, Inches(5.3), Inches(0.52),
             fill_color=RGBColor(0x22, 0x0E, 0x0E), line_color=color, line_width=Pt(0.6))
    add_textbox(pay_slide, day,  Inches(6.62), ry + Pt(5), Inches(2.2), Pt(14), size=9, color=LGRAY)
    add_textbox(pay_slide, fee,  Inches(8.9),  ry + Pt(5), Inches(2.7), Pt(14), size=9, bold=True, color=color)
    ry += Inches(0.56)

print('✅ 결제 멱등성 & 환불 슬라이드 추가 완료')


# ════════════════════════════════════════════════════════════════════════
# 5. Elasticsearch 설계 슬라이드 (결제 슬라이드 다음, PART05 직전 = index 21)
# ════════════════════════════════════════════════════════════════════════
es_slide = insert_slide_at(prs, 21)
set_bg(es_slide)

add_textbox(es_slide, 'Elasticsearch 검색 엔진 — 설계 & 구현 완료',
            Inches(0.4), Inches(0.12), Inches(12), Inches(0.55),
            size=22, bold=True, color=WHITE)
add_textbox(es_slide, '코드 구현 완료 · 현재 배포환경에서는 DB fallback 동작 · Phase 4 OpenSearch 연동 예정',
            Inches(0.4), Inches(0.65), Inches(12), Inches(0.32),
            size=10.5, color=LGRAY)
line_e = es_slide.shapes.add_shape(1, Inches(0.4), Inches(0.94), Inches(11.8), Pt(1.2))
line_e.fill.solid(); line_e.fill.fore_color.rgb = TEAL
line_e.line.fill.background()

# 상단 4개 기능 카드
es_features = [
    ('🔤  동의어 사전',
     '아이유 ↔ IU ↔ 이지은\nBTS ↔ 방탄 ↔ 방탄소년단\n임영웅 ↔ HERO ↔ 영웅시대', TEAL),
    ('🔍  오타 교정',
     'Fuzziness.AUTO 적용\n첫 글자부터 오타 허용\nmultiMatchQuery 복합 검색', ACCENT),
    ('✨  하이라이팅',
     '검색어 강조 태그 삽입\n<em class="tl-highlight">\n제목·설명 필드 적용', GOLD),
    ('💡  자동완성',
     'matchPhrasePrefixQuery\n2글자 이상 입력 시 동작\n최대 10개 추천', GREEN),
]
ex = Inches(0.35)
for title, body, color in es_features:
    add_rect(es_slide, ex, Inches(1.1), Inches(2.82), Inches(1.95),
             fill_color=RGBColor(0x08, 0x22, 0x22), line_color=color, line_width=Pt(1))
    add_textbox(es_slide, title, ex + Pt(6), Inches(1.17), Inches(2.7), Pt(16),
                size=10, bold=True, color=color)
    add_textbox(es_slide, body, ex + Pt(6), Inches(1.42), Inches(2.7), Inches(1.5),
                size=8.5, color=LGRAY)
    ex += Inches(2.97)

# 하단 — 인덱싱 흐름
add_rect(es_slide, Inches(0.35), Inches(3.2), Inches(7.3), Inches(1.95),
         fill_color=RGBColor(0x06, 0x18, 0x20), line_color=TEAL, line_width=Pt(1))
add_textbox(es_slide, '📦  인덱싱 흐름',
            Inches(0.55), Inches(3.27), Inches(7.0), Pt(16),
            size=10, bold=True, color=TEAL)
flow_items = [
    '공연 등록/수정 시 → @Async indexPerformance() 비동기 호출 (메인 트랜잭션 지연 없음)',
    '전체 재인덱싱 → GET /api/search/reindex  (214개 공연 일괄 등록)',
    '검색 요청 → ES 성공 시 결과 반환, 실패 시 DB LIKE 검색 자동 fallback',
]
iy = Inches(3.5)
for item in flow_items:
    add_textbox(es_slide, f'·  {item}', Inches(0.55), iy, Inches(7.0), Pt(16),
                size=9, color=LGRAY)
    iy += Pt(18)

# 우측 — Phase 계획
add_rect(es_slide, Inches(7.8), Inches(3.2), Inches(4.15), Inches(1.95),
         fill_color=RGBColor(0x10, 0x10, 0x28), line_color=PURPLE, line_width=Pt(1))
add_textbox(es_slide, '🗺  Phase 4 계획',
            Inches(8.0), Inches(3.27), Inches(3.9), Pt(16),
            size=10, bold=True, color=PURPLE)
phase_items = [
    'AWS OpenSearch Service 연동',
    'Edge Ngram 자동완성 인덱스',
    '실시간 인기 검색어 (Redis ZSet)',
    '검색 키워드 로그 분석',
]
py2 = Inches(3.5)
for item in phase_items:
    add_textbox(es_slide, f'·  {item}', Inches(8.0), py2, Inches(3.8), Pt(14),
                size=9, color=LGRAY)
    py2 += Pt(18)

print('✅ Elasticsearch 슬라이드 추가 완료')


# ════════════════════════════════════════════════════════════════════════
# 6. 배포 아키텍처 슬라이드 추가 (PART05 데이터셋 다음 = index 24)
# ════════════════════════════════════════════════════════════════════════
deploy_slide = insert_slide_at(prs, 24)
set_bg(deploy_slide)

add_textbox(deploy_slide, '배포 아키텍처 — AWS EC2 + Docker + RDS',
            Inches(0.4), Inches(0.15), Inches(11), Inches(0.6),
            size=22, bold=True, color=WHITE)
add_textbox(deploy_slide, 'Docker Compose 기반 3-WAR 컨테이너화 · Amazon RDS MySQL · EC2 t3.micro',
            Inches(0.4), Inches(0.72), Inches(11), Inches(0.35),
            size=11, color=LGRAY)

line2 = deploy_slide.shapes.add_shape(1,
    Inches(0.4), Inches(1.0), Inches(11.8), Pt(1.5))
line2.fill.solid(); line2.fill.fore_color.rgb = ACCENT
line2.line.fill.background()

# EC2 박스 (왼쪽 큰 박스)
ec2_box = add_rect(deploy_slide,
    Inches(0.35), Inches(1.15), Inches(6.8), Inches(4.0),
    fill_color=RGBColor(0x10, 0x1C, 0x3A),
    line_color=ACCENT, line_width=Pt(1.5))

add_textbox(deploy_slide, '☁  AWS EC2  t3.micro  (1GB RAM + 2GB Swap)',
            Inches(0.55), Inches(1.2), Inches(6.4), Inches(0.45),
            size=11, bold=True, color=ACCENT)

# Docker Compose 내부 컨테이너들
containers = [
    ('ticket-user',    ':8080 → :8080', GREEN,  Inches(0.55), Inches(1.7)),
    ('ticket-partner', ':8081 → :8080', GOLD,   Inches(0.55), Inches(2.45)),
    ('ticket-admin',   ':8082 → :8080', RED,    Inches(0.55), Inches(3.2)),
    ('Redis 7-alpine', 'maxmemory 50mb', TEAL,  Inches(0.55), Inches(3.95)),
]
for (name, port, color, cx, cy) in containers:
    add_rect(deploy_slide, cx, cy, Inches(3.0), Inches(0.62),
             fill_color=RGBColor(0x14, 0x22, 0x44), line_color=color, line_width=Pt(1))
    add_textbox(deploy_slide, f'🐳  {name}', cx + Pt(8), cy + Pt(4),
                Inches(1.8), Inches(0.35), size=10, bold=True, color=color)
    add_textbox(deploy_slide, port, cx + Inches(2.0), cy + Pt(4),
                Inches(1.0), Inches(0.35), size=9, color=LGRAY)

add_textbox(deploy_slide, '(Docker Compose)',
            Inches(3.7), Inches(1.7), Inches(3.2), Inches(3.0),
            size=9, color=RGBColor(0x40, 0x60, 0xA0))

# RDS 박스 (오른쪽 위)
add_rect(deploy_slide,
    Inches(7.5), Inches(1.15), Inches(4.35), Inches(1.8),
    fill_color=RGBColor(0x10, 0x22, 0x18),
    line_color=GREEN, line_width=Pt(1.5))
add_textbox(deploy_slide, '🗄  Amazon RDS',
            Inches(7.7), Inches(1.2), Inches(4.0), Inches(0.45),
            size=12, bold=True, color=GREEN)
add_textbox(deploy_slide,
            'MySQL 8  ·  db.t3.micro\nspringgreen6 스키마\n45개 테이블 · 200+ 공연 데이터',
            Inches(7.7), Inches(1.65), Inches(4.0), Inches(1.2),
            size=10, color=LGRAY)

# Security Group 박스 (오른쪽 아래)
add_rect(deploy_slide,
    Inches(7.5), Inches(3.2), Inches(4.35), Inches(1.95),
    fill_color=RGBColor(0x1A, 0x10, 0x28),
    line_color=PURPLE, line_width=Pt(1.5))
add_textbox(deploy_slide, '🔒  AWS Security Group',
            Inches(7.7), Inches(3.25), Inches(4.0), Inches(0.45),
            size=12, bold=True, color=PURPLE)
add_textbox(deploy_slide,
            'Inbound: 22(SSH) · 8080 · 8081 · 8082\nRDS SG: EC2 → MySQL 3306\nJWT_SECRET_KEY  환경변수 주입',
            Inches(7.7), Inches(3.72), Inches(4.0), Inches(1.3),
            size=10, color=LGRAY)

# 포털 접속 URL
add_textbox(deploy_slide,
            '🌐  ticket-user  http://54.92.139.234:8080\n'
            '🌐  ticket-partner  http://54.92.139.234:8081\n'
            '🌐  ticket-admin  http://54.92.139.234:8082',
            Inches(0.35), Inches(5.0), Inches(11.8), Inches(0.5),
            size=10, bold=False, color=ACCENT)

print('✅ 배포 아키텍처 슬라이드 추가 완료')


# ════════════════════════════════════════════════════════════════════════
# 저장
# ════════════════════════════════════════════════════════════════════════
prs.save(DST)
print(f'\n✅ 저장 완료 → {DST}')
print(f'   총 슬라이드 수: {len(prs.slides)}장')
