-- =============================================================================
--  TicketLegacy ENTERPRISE MASTER DATASET
--  기존 init.sql 원본 데이터 기반 - schema_total.sql (45 tables) 호환
--  비밀번호: Cks159753! (hash: $2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO)
-- =============================================================================

USE springgreen6;

SET FOREIGN_KEY_CHECKS = 0;

-- ── 0. TRUNCATE (순서 주의: 자식 테이블부터) ─────────────────
TRUNCATE TABLE `seat_inventory`;
TRUNCATE TABLE `reservation_seat`;
TRUNCATE TABLE `payment`;
TRUNCATE TABLE `reservation`;
TRUNCATE TABLE `coupon`;
TRUNCATE TABLE `coupon_template`;
TRUNCATE TABLE `entrance_log`;
TRUNCATE TABLE `performance_seat_grade`;
TRUNCATE TABLE `seat`;
TRUNCATE TABLE `schedule`;
TRUNCATE TABLE `performance_section_override`;
TRUNCATE TABLE `performance_wishlist`;
TRUNCATE TABLE `performance_stats`;
TRUNCATE TABLE `performance_review`;
TRUNCATE TABLE `performance`;
TRUNCATE TABLE `venue_stage_section`;
TRUNCATE TABLE `venue_stage_config`;
TRUNCATE TABLE `venue_seat_template`;
TRUNCATE TABLE `venue_section`;
TRUNCATE TABLE `venue_manager`;
TRUNCATE TABLE `promoter`;
TRUNCATE TABLE `venue`;
TRUNCATE TABLE `notice`;
TRUNCATE TABLE `faq`;
TRUNCATE TABLE `member_terms_agreement`;
TRUNCATE TABLE `member_status_history`;
TRUNCATE TABLE `member_sanction`;
TRUNCATE TABLE `notification`;
TRUNCATE TABLE `point_history`;
TRUNCATE TABLE `point_balance`;
TRUNCATE TABLE `member`;

-- ── 1. MEMBER (8명) ──────────────────────────────────────────
INSERT INTO `member` (member_id, email, password, name, phone, role, status) VALUES
(1, 'admin@ticketlegacy.com',  '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '슈퍼관리자',    '010-0000-0001', 'SUPER_ADMIN',   'ACTIVE'),
(2, 'staff@ticketlegacy.com',  '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '운영스태프',    '010-0000-0002', 'STAFF',         'ACTIVE'),
(3, 'user1@test.com',          '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '김유저',        '010-1111-1111', 'USER',          'ACTIVE'),
(4, 'user2@test.com',          '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '이팬',          '010-2222-2222', 'USER',          'ACTIVE'),
(5, 'user3@test.com',          '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '박관객',        '010-3333-3333', 'USER',          'ACTIVE'),
(6, 'promoter1@test.com',      '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '한국엔터(주)',  '02-555-1001',   'PROMOTER',      'ACTIVE'),
(7, 'promoter2@test.com',      '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '서울뮤직(주)', '02-555-1002',   'PROMOTER',      'ACTIVE'),
(8, 'venue1@test.com',         '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '잠실담당자',   '010-9999-0001', 'VENUE_MANAGER', 'ACTIVE');

-- ── 2. VENUE ─────────────────────────────────────────────────
INSERT INTO `venue` (venue_id, api_facility_id, name, address, seat_scale) VALUES
(1, 'FC000001', '잠실종합운동장 주경기장',   '서울특별시 송파구 올림픽로 25',   69950),
(2, 'FC000002', '올림픽홀',                  '서울특별시 송파구 올림픽로 424',  2452),
(3, 'FC000003', '블루스퀘어 마스터카드홀',   '서울특별시 용산구 이태원로 294',  1766);

-- ── 3. VENUE_SECTION ─────────────────────────────────────────
INSERT INTO `venue_section` (section_id, venue_id, section_name, section_type, total_rows, seats_per_row, display_order) VALUES
(1,  1, 'VIP구역', 'VIP_BOX', 2, 5,  1),
(2,  1, 'R구역',   'FLOOR',   3, 8,  2),
(3,  1, 'S구역',   'FLOOR',   4, 10, 3),
(4,  1, 'A구역',   'BALCONY', 5, 12, 4),
(5,  2, 'R구역',   'FLOOR',   2, 6,  1),
(6,  2, 'S구역',   'FLOOR',   3, 8,  2),
(7,  2, 'A구역',   'BALCONY', 4, 10, 3),
(8,  3, 'VIP구역', 'VIP_BOX', 2, 4,  1),
(9,  3, 'R구역',   'FLOOR',   3, 6,  2),
(10, 3, 'S구역',   'BALCONY', 4, 8,  3);

-- ── 4. VENUE_STAGE_CONFIG ─────────────────────────────────────
INSERT INTO `venue_stage_config` (config_id, venue_id, config_name, description, is_default) VALUES
(1, 1, '풀구성', '잠실주경기장 표준 구성', 1),
(2, 2, '표준',   '올림픽홀 표준',          1),
(3, 3, '풀구성', '블루스퀘어 표준',        1);

-- ── 5. VENUE_STAGE_SECTION ────────────────────────────────────
INSERT INTO `venue_stage_section` (config_id, section_id, is_active) VALUES
(1, 1, 1), (1, 2, 1), (1, 3, 1), (1, 4, 1),
(2, 5, 1), (2, 6, 1), (2, 7, 1),
(3, 8, 1), (3, 9, 1), (3, 10, 1);

-- ── 6. VENUE_SEAT_TEMPLATE (각 섹션의 좌석 미리 등록) ─────────
INSERT INTO `venue_seat_template` (venue_id, section_id, seat_row, seat_number, seat_type)
WITH RECURSIVE rng(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM rng WHERE n < 30)
SELECT vs.venue_id, vs.section_id, CHAR(64 + r.n), c.n, 'NORMAL'
FROM   venue_section vs
JOIN   rng r ON r.n <= vs.total_rows
JOIN   rng c ON c.n <= vs.seats_per_row;

-- ── 7. PROMOTER ───────────────────────────────────────────────
INSERT INTO `promoter` (promoter_id, member_id, company_name, business_reg_no, representative,
                        contact_email, contact_phone, approval_status, approved_by, approved_at) VALUES
(1, 6, '한국엔터테인먼트(주)', '111-22-33333', '김대표', 'biz@hkent.co.kr',   '02-555-1001', 'APPROVED', 1, NOW()),
(2, 7, '서울뮤직컴퍼니(주)',   '222-33-44444', '이대표', 'biz@seoulmusic.kr', '02-555-1002', 'PENDING',  NULL, NULL);

-- ── 8. VENUE_MANAGER ─────────────────────────────────────────
INSERT INTO `venue_manager` (manager_id, member_id, venue_id, department, position,
                              approval_status, approved_by, approved_at) VALUES
(1, 8, 1, '운영팀', '담당매니저', 'APPROVED', 1, NOW());

-- ── 9. NOTICE ─────────────────────────────────────────────────
INSERT INTO `notice` (notice_id, title, content, notice_type, target_role, is_pinned, is_active, author_member_id, view_count) VALUES
(1, '서비스 오픈 안내',            '<p>티켓레거시 서비스를 정식 오픈했습니다. 많은 이용 부탁드립니다.</p>',                        'SYSTEM',      'ALL',      1, 1, 1, 0),
(2, '결제 시스템 점검 (06:00~07:00)', '<p>매월 첫째 주 일요일 새벽 1시간 동안 결제 시스템 점검이 진행됩니다.</p>',              'MAINTENANCE', 'ALL',      0, 1, 1, 0),
(3, '기획사 정산 방식 변경',       '<p>2026년 5월부터 정산 비율이 90:10으로 일원화됩니다.</p>',                                    'SYSTEM',      'PROMOTER', 0, 1, 1, 0);

-- ── 10. FAQ ───────────────────────────────────────────────────
INSERT INTO `faq` (faq_id, category, question, answer, sort_order, is_active) VALUES
(1, 'RESERVATION', '예매는 어떻게 하나요?',         '공연 상세 페이지에서 날짜와 좌석을 선택 후 결제하시면 됩니다.',                      1, 1),
(2, 'RESERVATION', '한 번에 몇 매까지 예매 가능한가요?', '공연별로 다르지만 일반적으로 최대 4매까지 가능합니다.',                       2, 1),
(3, 'PAYMENT',     '결제 수단은 무엇이 있나요?',      '신용카드, 계좌이체 등을 지원합니다.',                                             3, 1),
(4, 'PAYMENT',     '무통장 입금 기한은?',             '예매 완료 후 익일 23시 59분까지 입금하셔야 합니다.',                              4, 1),
(5, 'REFUND',      '취소 수수료 규정은?',             '관람일 10일 전까지 전액 환불, 이후 기간에 따라 차등 적용됩니다.',                   5, 1),
(6, 'REFUND',      '당일 취소가 가능한가요?',         '관람 당일 취소는 불가합니다. 전일 17시까지만 가능합니다.',                        6, 1),
(7, 'SUPPORT',     '티켓 배송은 언제 시작되나요?',    '공연일 기준 약 2주 전부터 순차 배송됩니다.',                                      7, 1),
(8, 'SUPPORT',     '분실/파손 시 재발급 되나요?',     '재발급은 불가하며, 모바일 티켓의 경우 앱에서 다시 확인하실 수 있습니다.',           8, 1);

-- ── 11. PERFORMANCE ───────────────────────────────────────────
INSERT INTO `performance` (performance_id, api_perf_id, title, category, age_limit, running_time, min_price,
                            venue_id, venue_name, description, poster_url, total_seats,
                            ticket_open_at, start_date, end_date,
                            status, stage_config_id, promoter_id,
                            approval_status, approval_note, reviewed_by, reviewed_at) VALUES
(1, 'PF000001', '2026 IU CONCERT : THE GOLDEN HOUR', 'CONCERT',
   '8세 이상', 180, 132000,
   1, '잠실종합운동장 주경기장',
   '<p>아이유의 대규모 단독 콘서트.</p><ul><li>오프닝 게스트 : 새소년</li></ul>',
   'https://placehold.co/400x550?text=IU+Concert', 134,
   DATE_SUB(NOW(), INTERVAL 1 DAY),
   DATE_ADD(CURDATE(), INTERVAL 30 DAY), DATE_ADD(CURDATE(), INTERVAL 31 DAY),
   'ON_SALE', 1, 1, 'PUBLISHED', '심사 통과', 1, NOW()),

(2, 'PF000002', '뮤지컬 〈라이온 킹〉 인터내셔널 투어', 'MUSICAL',
   '7세 이상', 150, 88000,
   2, '올림픽홀',
   '<p>디즈니 뮤지컬 라이온킹의 인터내셔널 투어 한국 공연.</p>',
   'https://placehold.co/400x550?text=Lion+King', 76,
   DATE_SUB(NOW(), INTERVAL 1 DAY),
   DATE_ADD(CURDATE(), INTERVAL 14 DAY), DATE_ADD(CURDATE(), INTERVAL 60 DAY),
   'ON_SALE', 2, 1, 'PUBLISHED', '심사 통과', 1, NOW()),

(3, 'PF000003', 'BTS WORLD TOUR 2026 - SEOUL', 'CONCERT',
   '전체관람가', 200, 165000,
   1, '잠실종합운동장 주경기장',
   '<p>방탄소년단 월드투어 서울 공연 (심사 대기 샘플).</p>',
   'https://placehold.co/400x550?text=BTS+Tour', 0,
   DATE_ADD(NOW(), INTERVAL 7 DAY),
   DATE_ADD(CURDATE(), INTERVAL 50 DAY), DATE_ADD(CURDATE(), INTERVAL 51 DAY),
   'UPCOMING', 1, 2, 'REVIEW', NULL, NULL, NULL),

(4, 'PF000004', '국립발레단 〈백조의 호수〉', 'BALLET',
   '5세 이상', 130, 50000,
   3, '블루스퀘어 마스터카드홀',
   '<p>국립발레단 정기공연. 차이콥스키 백조의 호수.</p>',
   'https://placehold.co/400x550?text=Swan+Lake', 0,
   DATE_ADD(NOW(), INTERVAL 14 DAY),
   DATE_ADD(CURDATE(), INTERVAL 45 DAY), DATE_ADD(CURDATE(), INTERVAL 47 DAY),
   'UPCOMING', 3, 1, 'APPROVED', '승인됨, 게시 대기', 1, NOW());

-- ── 12. PERFORMANCE_SEAT_GRADE ────────────────────────────────
INSERT INTO `performance_seat_grade` (performance_id, section_id, grade, price) VALUES
(1, 1, 'VIP', 220000), (1, 2, 'R', 165000), (1, 3, 'S', 132000), (1, 4, 'A', 99000),
(2, 5, 'R',   154000), (2, 6, 'S', 121000), (2, 7, 'A',  88000),
(4, 8, 'VIP', 110000), (4, 9, 'R',  77000), (4, 10, 'S', 50000);

-- ── 13. SEAT (공연×구역×행×열 자동 생성) ─────────────────────
INSERT INTO `seat` (performance_id, section, seat_row, seat_number, grade, price)
WITH RECURSIVE rng(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM rng WHERE n < 30)
SELECT psg.performance_id,
       vs.section_name,
       CHAR(64 + r.n),
       c.n,
       psg.grade,
       psg.price
FROM   performance_seat_grade psg
JOIN   venue_section vs ON vs.section_id = psg.section_id
JOIN   rng r ON r.n <= vs.total_rows
JOIN   rng c ON c.n <= vs.seats_per_row
ORDER BY psg.performance_id, vs.display_order, r.n, c.n;

-- ── 14. SCHEDULE ─────────────────────────────────────────────
INSERT INTO `schedule` (schedule_id, performance_id, show_date, show_time, available_seats, status, max_seats_per_order) VALUES
(1, 1, DATE_ADD(CURDATE(), INTERVAL 30 DAY), '19:00:00', 0, 'AVAILABLE', 4),
(2, 1, DATE_ADD(CURDATE(), INTERVAL 31 DAY), '18:00:00', 0, 'AVAILABLE', 4),
(3, 2, DATE_ADD(CURDATE(), INTERVAL 14 DAY), '14:00:00', 0, 'AVAILABLE', 4),
(4, 2, DATE_ADD(CURDATE(), INTERVAL 14 DAY), '19:30:00', 0, 'AVAILABLE', 4),
(5, 2, DATE_ADD(CURDATE(), INTERVAL 21 DAY), '15:00:00', 0, 'AVAILABLE', 4),
(6, 4, DATE_ADD(CURDATE(), INTERVAL 45 DAY), '19:30:00', 0, 'AVAILABLE', 4),
(7, 4, DATE_ADD(CURDATE(), INTERVAL 47 DAY), '15:00:00', 0, 'AVAILABLE', 4);

-- ── 15. SEAT_INVENTORY (회차×좌석 전체 AVAILABLE) ──────────────
INSERT INTO `seat_inventory` (schedule_id, seat_id, status, hold_type, version)
SELECT sc.schedule_id, s.seat_id, 'AVAILABLE', 'PUBLIC', 0
FROM   schedule sc
JOIN   seat s ON s.performance_id = sc.performance_id;

-- ── 16. available_seats / total_seats 보정 ────────────────────
UPDATE `schedule` sc
JOIN (
  SELECT schedule_id, COUNT(*) AS cnt
  FROM   seat_inventory
  WHERE  status = 'AVAILABLE' AND hold_type = 'PUBLIC'
  GROUP BY schedule_id
) x ON x.schedule_id = sc.schedule_id
SET sc.available_seats = x.cnt;

UPDATE `performance` p
JOIN (
  SELECT performance_id, COUNT(*) AS cnt FROM seat GROUP BY performance_id
) x ON x.performance_id = p.performance_id
SET p.total_seats = x.cnt;

-- ── 17. COUPON_TEMPLATE ───────────────────────────────────────
INSERT INTO `coupon_template` (template_id, promoter_id, performance_id, code_prefix, name,
                                discount_type, discount_value, min_amount, max_discount,
                                total_quantity, issued_count, valid_from, valid_until, is_active) VALUES
(1, 1, 1, 'IU2026',  '아이유 콘서트 1만원 할인',    'FIXED',   10000, 100000, NULL,  100, 1, DATE_SUB(NOW(), INTERVAL 7 DAY),  DATE_ADD(NOW(), INTERVAL 30 DAY),  1),
(2, NULL, NULL, 'WELCOME', '신규회원 10% 할인 (최대 2만원)', 'PERCENT', 10, 50000, 20000, 1000, 1, DATE_SUB(NOW(), INTERVAL 30 DAY), DATE_ADD(NOW(), INTERVAL 365 DAY), 1);

-- ── 18. COUPON ────────────────────────────────────────────────
INSERT INTO `coupon` (coupon_id, template_id, member_id, coupon_code, status, issued_at, expires_at) VALUES
(1, 1, 3, 'IU2026-USER1-0001', 'ISSUED', NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY)),
(2, 2, 3, 'WELCOME-USER1',     'ISSUED', NOW(), DATE_ADD(NOW(), INTERVAL 365 DAY));

-- ── 19. RESERVATION (샘플 1건 — user1이 공연1 VIP 2석) ─────────
INSERT INTO `reservation` (reservation_id, reservation_no, schedule_id, member_id,
                            total_amount, seat_count, status, confirmed_at) VALUES
(1, 'R20260420000001', 1, 3, 440000, 2, 'CONFIRMED', NOW());

INSERT INTO `reservation_seat` (reservation_id, seat_id, price)
SELECT 1, s.seat_id, s.price
FROM   seat s
WHERE  s.performance_id = 1
  AND  s.section        = 'VIP구역'
  AND  s.seat_row       = 'A'
  AND  s.seat_number   IN (1, 2);

UPDATE `seat_inventory` si
JOIN   seat s ON s.seat_id = si.seat_id
SET    si.status = 'RESERVED', si.version = si.version + 1
WHERE  si.schedule_id = 1
  AND  s.performance_id = 1
  AND  s.section        = 'VIP구역'
  AND  s.seat_row       = 'A'
  AND  s.seat_number   IN (1, 2);

-- schedule.available_seats 재계산
UPDATE `schedule` sc
JOIN (
  SELECT schedule_id, COUNT(*) AS cnt
  FROM   seat_inventory
  WHERE  status = 'AVAILABLE' AND hold_type = 'PUBLIC'
  GROUP BY schedule_id
) x ON x.schedule_id = sc.schedule_id
SET sc.available_seats = x.cnt;

-- ── 20. PAYMENT ───────────────────────────────────────────────
INSERT INTO `payment` (id, reservation_id, member_id, amount, coupon_id,
                        discount_amount, final_amount, status,
                        idempotency_key, pg_transaction_id, completed_at) VALUES
(1, 1, 3, 440000, NULL, 0, 440000, 'COMPLETED',
   'IDEMP-R20260420000001', 'PG-MOCK-0000000001', NOW());

-- ── 21. AUTO_INCREMENT 정렬 ───────────────────────────────────
ALTER TABLE `member`                     AUTO_INCREMENT = 100;
ALTER TABLE `venue`                      AUTO_INCREMENT = 100;
ALTER TABLE `venue_section`              AUTO_INCREMENT = 100;
ALTER TABLE `venue_stage_config`         AUTO_INCREMENT = 100;
ALTER TABLE `venue_stage_section`        AUTO_INCREMENT = 100;
ALTER TABLE `promoter`                   AUTO_INCREMENT = 100;
ALTER TABLE `venue_manager`              AUTO_INCREMENT = 100;
ALTER TABLE `notice`                     AUTO_INCREMENT = 100;
ALTER TABLE `performance`                AUTO_INCREMENT = 100;
ALTER TABLE `performance_seat_grade`     AUTO_INCREMENT = 100;
ALTER TABLE `performance_section_override` AUTO_INCREMENT = 100;
ALTER TABLE `schedule`                   AUTO_INCREMENT = 100;
ALTER TABLE `coupon_template`            AUTO_INCREMENT = 100;
ALTER TABLE `coupon`                     AUTO_INCREMENT = 100;
ALTER TABLE `reservation`                AUTO_INCREMENT = 100;
ALTER TABLE `payment`                    AUTO_INCREMENT = 100;
ALTER TABLE `entrance_log`               AUTO_INCREMENT = 100;

-- ── 22. 추가 VENUE (새 공연장) ────────────────────────────────────────
INSERT INTO `venue` (venue_id, api_facility_id, name, address, seat_scale) VALUES
(4, 'FC000004', 'DDP 공연장', '서울특별시 중구 을지로 281', 5000);

-- ── 23. 추가 VENUE_SECTION (새 공연장 섹션) ────────────────────────────────────
INSERT INTO `venue_section` (section_id, venue_id, section_name, section_type, total_rows, seats_per_row, display_order) VALUES
(11, 4, 'VIP구역', 'VIP_BOX', 2, 6, 1),
(12, 4, 'R구역',   'FLOOR',   3, 10,2),
(13, 4, 'S구역',   'FLOOR',   4, 12,3),
(14, 4, 'A구역',   'BALCONY', 5, 15,4);

-- ── 24. 추가 PERFORMANCE (10개) ────────────────────────────────────────
INSERT INTO `performance` (performance_id, api_perf_id, title, category, age_limit, running_time, min_price,
                            venue_id, venue_name, description, poster_url, total_seats,
                            ticket_open_at, start_date, end_date,
                            status, stage_config_id, promoter_id,
                            approval_status, approval_note, reviewed_by, reviewed_at) VALUES
(5,  'PF000005', '2024 BTS World Tour – Seoul',               'CONCERT',  '전체관람가', 180, 160000, 1, '잠실종합운동장 주경기장', '<p>BTS 월드투어 서울공연.</p>', 'https://placehold.co/400x550?text=BTS+Seoul', 0, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_ADD(CURDATE(), INTERVAL 60 DAY), DATE_ADD(CURDATE(), INTERVAL 61 DAY), 'ON_SALE', 1, 2, 'PUBLISHED', '심사 통과', 1, NOW()),
(6,  'PF000006', '뮤지컬 [닥터 스트레인지] 한국 투어',      'MUSICAL',  '12세 이상',   150, 90000,  2, '올림픽홀',              '<p>닥터 스트레인지 뮤지컬.</p>',      'https://placehold.co/400x550?text=Doctor+Strange', 0, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(CURDATE(), INTERVAL 30 DAY), DATE_ADD(CURDATE(), INTERVAL 45 DAY), 'ON_SALE', 2, 1, 'PUBLISHED', '심사 통과', 1, NOW()),
(7,  'PF000007', '클래식 마스터클래스 – 피아노 콩쿠르',      'CLASSIC',  '15세 이상',   120, 60000,  3, '블루스퀘어 마스터카드홀', '<p>피아니스트 콩쿠르.</p>',         'https://placehold.co/400x550?text=Classical+Piano', 0, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_ADD(CURDATE(), INTERVAL 20 DAY), DATE_ADD(CURDATE(), INTERVAL 21 DAY), 'ON_SALE', 3, 1, 'PUBLISHED', '심사 통과', 1, NOW()),
(8,  'PF000008', '연극 [햄릿] 현대 해석',                    'PLAY',     '전체관람가',   130, 75000,  1, '잠실종합운동장 주경기장', '<p>현대적 햄릿.</p>',               'https://placehold.co/400x550?text=Hamlet+Play', 0, DATE_SUB(NOW(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 40 DAY), DATE_ADD(CURDATE(), INTERVAL 41 DAY), 'UPCOMING', 1, 1, 'REVIEW', NULL, NULL, NULL),
(9,  'PF000009', '페스티벌 [서울 뮤직 페스티벌]',          'FESTIVAL', '전체관람가',   200, 110000, 4, 'DDP 공연장',            '<p>다양한 아티스트 라인업.</p>',      'https://placehold.co/400x550?text=Seoul+Music+Fest', 0, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_ADD(CURDATE(), INTERVAL 70 DAY), DATE_ADD(CURDATE(), INTERVAL 72 DAY), 'UPCOMING', 4, 2, 'PENDING', NULL, NULL, NULL),
(10, 'PF000010', '전시 [디지털 아트 갤러리]',                'EXHIBITION','전체관람가',   90,  30000,  2, '올림픽홀',              '<p>디지털 아트 전시.</p>',           'https://placehold.co/400x550?text=Digital+Art', 0, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_ADD(CURDATE(), INTERVAL 55 DAY), DATE_ADD(CURDATE(), INTERVAL 57 DAY), 'UPCOMING', 2, 1, 'PENDING', NULL, NULL, NULL),
(11, 'PF000011', '콘서트 [김진호 인디 밴드]',               'CONCERT',  '15세 이상',   110, 80000,  3, '블루스퀘어 마스터카드홀', '<p>인디 밴드 스페셜.</p>',          'https://placehold.co/400x550?text=Indie+Concert', 0, DATE_SUB(NOW(), INTERVAL 4 DAY), DATE_ADD(CURDATE(), INTERVAL 25 DAY), DATE_ADD(CURDATE(), INTERVAL 26 DAY), 'ON_SALE', 3, 1, 'PUBLISHED', '심사 통과', 1, NOW()),
(12, 'PF000012', '코미디 쇼 [웃음의 순간]',                'COMEDY',   '전체관람가',   100, 50000,  1, '잠실종합운동장 주경기장', '<p>국내 최정상 코미디언 라인업.</p>', 'https://placehold.co/400x550?text=Comedy+Show', 0, DATE_SUB(NOW(), INTERVAL 6 DAY), DATE_ADD(CURDATE(), INTERVAL 35 DAY), DATE_ADD(CURDATE(), INTERVAL 36 DAY), 'UPCOMING', 1, 2, 'PENDING', NULL, NULL, NULL),
(13, 'PF000013', '발레 [라 트라비아타]',                    'BALLET',   '5세 이상',    120, 95000,  3, '블루스퀘어 마스터카드홀', '<p>클래식 발레 공연.</p>',           'https://placehold.co/400x550?text=Ballet+Traviata', 0, DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_ADD(CURDATE(), INTERVAL 15 DAY), DATE_ADD(CURDATE(), INTERVAL 16 DAY), 'UPCOMING', 3, 1, 'PENDING', NULL, NULL, NULL),
(14, 'PF000014', '예술 강연 [미술사와 현대] ',                'LECTURE',  '전체관람가',   80,  40000,  4, 'DDP 공연장',            '<p>전문가 강연.</p>',                 'https://placehold.co/400x550?text=Art+Talk', 0, DATE_SUB(NOW(), INTERVAL 8 DAY), DATE_ADD(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 11 DAY), 'UPCOMING', 4, 1, 'PENDING', NULL, NULL, NULL);

-- ── 25. PERFORMANCE_SEAT_GRADE for new performances ────────────────────────
INSERT INTO `performance_seat_grade` (performance_id, section_id, grade, price) VALUES
(5, 1, 'VIP', 250000), (5, 2, 'R', 180000), (5, 3, 'S', 150000), (5, 4, 'A', 120000),
(6, 5, 'R', 120000), (6, 6, 'S', 100000), (6, 7, 'A', 80000),
(7, 8, 'VIP', 130000), (7, 9, 'R', 90000), (7,10, 'S', 70000),
(8, 1, 'VIP', 200000), (8, 2, 'R', 150000), (8, 3, 'S', 120000), (8, 4, 'A', 90000),
(9,11, 'VIP', 220000), (9,12, 'R', 170000), (9,13, 'S', 130000), (9,14, 'A', 100000),
(10,5, 'R', 90000), (10,6, 'S', 75000), (10,7, 'A', 60000),
(11,8, 'VIP', 190000), (11,9, 'R', 140000), (11,10,'S',110000),
(12,1, 'VIP', 180000), (12,2, 'R', 130000), (12,3, 'S', 100000), (12,4, 'A', 80000),
(13,8, 'VIP', 210000), (13,9, 'R', 160000), (13,10,'S',130000),
(14,11,'VIP', 200000), (14,12,'R', 150000), (14,13,'S', 120000);

-- ── 26. SCHEDULE for new performances (2회차씩) ───────────────────────
INSERT INTO `schedule` (schedule_id, performance_id, show_date, show_time, available_seats, status, max_seats_per_order) VALUES
(8, 5, DATE_ADD(CURDATE(), INTERVAL 60 DAY), '19:00:00', 0, 'AVAILABLE', 4),
(9, 5, DATE_ADD(CURDATE(), INTERVAL 61 DAY), '18:00:00', 0, 'AVAILABLE', 4),
(10,6, DATE_ADD(CURDATE(), INTERVAL 30 DAY), '20:00:00', 0, 'AVAILABLE', 4),
(11,6, DATE_ADD(CURDATE(), INTERVAL 31 DAY), '15:00:00', 0, 'AVAILABLE', 4),
(12,7, DATE_ADD(CURDATE(), INTERVAL 20 DAY), '19:30:00', 0, 'AVAILABLE', 4),
(13,7, DATE_ADD(CURDATE(), INTERVAL 21 DAY), '14:30:00', 0, 'AVAILABLE', 4),
(14,8, DATE_ADD(CURDATE(), INTERVAL 45 DAY), '18:30:00', 0, 'AVAILABLE', 4),
(15,8, DATE_ADD(CURDATE(), INTERVAL 46 DAY), '13:30:00', 0, 'AVAILABLE', 4),
(16,9, DATE_ADD(CURDATE(), INTERVAL 70 DAY), '20:00:00', 0, 'AVAILABLE', 4),
(17,9, DATE_ADD(CURDATE(), INTERVAL 71 DAY), '16:00:00', 0, 'AVAILABLE', 4),
(18,10,DATE_ADD(CURDATE(), INTERVAL 55 DAY), '11:00:00', 0, 'AVAILABLE', 4),
(19,10,DATE_ADD(CURDATE(), INTERVAL 56 DAY), '17:00:00', 0, 'AVAILABLE', 4),
(20,11,DATE_ADD(CURDATE(), INTERVAL 25 DAY), '19:00:00', 0, 'AVAILABLE', 4),
(21,11,DATE_ADD(CURDATE(), INTERVAL 26 DAY), '15:00:00', 0, 'AVAILABLE', 4),
(22,12,DATE_ADD(CURDATE(), INTERVAL 35 DAY), '20:30:00', 0, 'AVAILABLE', 4),
(23,12,DATE_ADD(CURDATE(), INTERVAL 36 DAY), '14:30:00', 0, 'AVAILABLE', 4),
(24,13,DATE_ADD(CURDATE(), INTERVAL 15 DAY), '19:00:00', 0, 'AVAILABLE', 4),
(25,13,DATE_ADD(CURDATE(), INTERVAL 16 DAY), '13:00:00', 0, 'AVAILABLE', 4),
(26,14,DATE_ADD(CURDATE(), INTERVAL 10 DAY), '18:00:00', 0, 'AVAILABLE', 4),
(27,14,DATE_ADD(CURDATE(), INTERVAL 11 DAY), '12:00:00', 0, 'AVAILABLE', 4);

-- ── 27. SEAT (generate seats for new performances) ───────────────────────
INSERT INTO `seat` (performance_id, section, seat_row, seat_number, grade, price)
WITH RECURSIVE rng(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM rng WHERE n < 30)
SELECT psg.performance_id,
       vs.section_name,
       CHAR(64 + r.n),
       c.n,
       psg.grade,
       psg.price
FROM   performance_seat_grade psg
JOIN   venue_section vs ON vs.section_id = psg.section_id
JOIN   rng r ON r.n <= vs.total_rows
JOIN   rng c ON c.n <= vs.seats_per_row
WHERE  psg.performance_id BETWEEN 5 AND 14
ORDER BY psg.performance_id, vs.display_order, r.n, c.n;

-- ── 28. SEAT_INVENTORY for new schedules ─────────────────────────────────
INSERT INTO `seat_inventory` (schedule_id, seat_id, status, hold_type, version)
SELECT sc.schedule_id, s.seat_id, 'AVAILABLE', 'PUBLIC', 0
FROM   schedule sc
JOIN   seat s ON s.performance_id = sc.performance_id
WHERE  sc.schedule_id BETWEEN 8 AND 27;

-- ── 29. 재계산: available_seats / total_seats ──────────────────────────────
UPDATE `schedule` sc
JOIN (
  SELECT schedule_id, COUNT(*) AS cnt
  FROM   seat_inventory
  WHERE  status = 'AVAILABLE' AND hold_type = 'PUBLIC'
  GROUP BY schedule_id
) x ON x.schedule_id = sc.schedule_id
SET sc.available_seats = x.cnt;

UPDATE `performance` p
JOIN (
  SELECT performance_id, COUNT(*) AS cnt FROM seat GROUP BY performance_id
) x ON x.performance_id = p.performance_id
SET p.total_seats = x.cnt;

SET FOREIGN_KEY_CHECKS = 1;
