-- ==============================================================
--  data_extension.sql (Fixed Version)
--  200+ Performances with standard SQL compatibility
-- ==============================================================

USE springgreen6;

-- 1. 200개의 공연 생성 (ID: 15 ~ 214)
INSERT INTO `performance` (performance_id, api_perf_id, title, category, age_limit, 
    running_time, min_price, venue_id, venue_name, description, poster_url, 
    total_seats, ticket_open_at, start_date, end_date, 
    status, stage_config_id, promoter_id, 
    approval_status, approval_note, reviewed_by, reviewed_at)
WITH RECURSIVE seq(n) AS (
    SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 200
)
SELECT 
    15 + n - 1 AS performance_id,
    CONCAT('PF', LPAD(15 + n - 1, 6, '0')) AS api_perf_id,
    CONCAT(
        CASE (n % 9)
            WHEN 0 THEN '월드 투어: ' WHEN 1 THEN '뮤지컬 ' WHEN 2 THEN '오케스트라 '
            WHEN 3 THEN '연극 ' WHEN 4 THEN '락 페스티벌 ' WHEN 5 THEN '특별 전시 '
            WHEN 6 THEN '스탠딩 코미디 ' WHEN 7 THEN '발레 ' ELSE '인문학 강연 '
        END, 
        '프로젝트 #', n
    ) AS title,
    CASE (n % 9)
        WHEN 0 THEN 'CONCERT' WHEN 1 THEN 'MUSICAL' WHEN 2 THEN 'CLASSIC'
        WHEN 3 THEN 'PLAY' WHEN 4 THEN 'FESTIVAL' WHEN 5 THEN 'EXHIBITION'
        WHEN 6 THEN 'COMEDY' WHEN 7 THEN 'BALLET' ELSE 'LECTURE'
    END AS category,
    IF(n % 2 = 0, '전체관람가', '12세 이상') AS age_limit,
    100 + (n % 60) AS running_time,
    50000 + (n * 500) AS min_price,
    (n % 4) + 1 AS venue_id,
    CASE (n % 4) + 1
        WHEN 1 THEN '잠실종합운동장 주경기장'
        WHEN 2 THEN '올림픽홀'
        WHEN 3 THEN '블루스퀘어 마스터카드홀'
        ELSE 'DDP 공연장'
    END AS venue_name,
    CONCAT('<p>공연 번호 ', n, '번에 대한 상세 설명입니다. Elasticsearch 검색 테스트를 위한 풍부한 텍스트를 포함합니다.</p>') AS description,
    CONCAT('https://picsum.photos/seed/perf', n + 100, '/400/550') AS poster_url,
    0 AS total_seats,
    DATE_SUB(NOW(), INTERVAL 1 DAY) AS ticket_open_at,
    DATE_ADD(CURDATE(), INTERVAL (n % 90) DAY) AS start_date,
    DATE_ADD(CURDATE(), INTERVAL (n % 90 + 3) DAY) AS end_date,
    'ON_SALE' AS status,
    ((n % 4) % 3) + 1 AS stage_config_id,
    IF(n % 2 = 0, 1, 2) AS promoter_id,
    'PUBLISHED' AS approval_status,
    'Bulk Inserted' AS approval_note,
    1 AS reviewed_by,
    NOW() AS reviewed_at
FROM seq;

-- 2. 공연별 등급 자동 생성
INSERT INTO `performance_seat_grade` (performance_id, section_id, grade, price)
SELECT 
    p.performance_id,
    vs.section_id,
    CASE WHEN vs.section_type = 'VIP_BOX' THEN 'VIP' WHEN vs.section_type = 'FLOOR' THEN 'R' ELSE 'A' END,
    p.min_price + 20000
FROM performance p
JOIN venue_section vs ON vs.venue_id = p.venue_id
WHERE p.performance_id >= 15;

-- 3. 스케줄 자동 생성 (공연당 1회차)
INSERT INTO `schedule` (schedule_id, performance_id, show_date, show_time, available_seats, status, max_seats_per_order)
SELECT 
    100 + n AS schedule_id,
    15 + n - 1 AS performance_id,
    DATE_ADD(CURDATE(), INTERVAL (n % 90) DAY),
    '19:00:00',
    0,
    'AVAILABLE',
    4
FROM (SELECT n FROM (WITH RECURSIVE seq2(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq2 WHERE n < 200) SELECT n FROM seq2) AS sub) AS seq_table;

-- 4. 좌석(Seat) 자동 생성
INSERT INTO `seat` (performance_id, section, seat_row, seat_number, grade, price)
WITH RECURSIVE rng(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM rng WHERE n < 20)
SELECT 
    psg.performance_id,
    vs.section_name,
    CHAR(64 + r.n),
    c.n,
    psg.grade,
    psg.price
FROM performance_seat_grade psg
JOIN venue_section vs ON vs.section_id = psg.section_id
JOIN rng r ON r.n <= vs.total_rows
JOIN rng c ON c.n <= vs.seats_per_row
WHERE psg.performance_id >= 15;

-- 5. 인벤토리(Inventory) 생성
INSERT INTO `seat_inventory` (schedule_id, seat_id, status, hold_type, version)
SELECT 
    sc.schedule_id,
    s.seat_id,
    'AVAILABLE',
    'PUBLIC',
    0
FROM schedule sc
JOIN seat s ON s.performance_id = sc.performance_id
WHERE sc.schedule_id >= 100;

-- 6. 좌석 수 보정
UPDATE `schedule` sc
JOIN (SELECT schedule_id, COUNT(*) AS cnt FROM seat_inventory GROUP BY schedule_id) x ON x.schedule_id = sc.schedule_id
SET sc.available_seats = x.cnt
WHERE sc.schedule_id >= 100;

UPDATE `performance` p
JOIN (SELECT performance_id, COUNT(*) AS cnt FROM seat GROUP BY performance_id) x ON x.performance_id = p.performance_id
SET p.total_seats = x.cnt
WHERE p.performance_id >= 15;
