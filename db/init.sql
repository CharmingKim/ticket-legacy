-- =============================================================================
--  TicketLegacy — 전체 스키마 + 시드 데이터 (재실행 안전)
--  실행:  mysql -uroot -p1234 < db/init.sql
--          또는  source db/init.sql;
--
--  대상 DB : springgreen6
--  공통 비밀번호(평문 Cks159753!) BCrypt:
--    $2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO
-- =============================================================================

CREATE DATABASE IF NOT EXISTS springgreen6
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE springgreen6;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ─────────────────────────────────────────────────────────
-- 1. DROP (역순 + FK 무시)
-- ─────────────────────────────────────────────────────────
DROP TABLE IF EXISTS entrance_log;
DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS reservation_seat;
DROP TABLE IF EXISTS reservation;
DROP TABLE IF EXISTS coupon;
DROP TABLE IF EXISTS coupon_template;
DROP TABLE IF EXISTS seat_inventory;
DROP TABLE IF EXISTS seat;
DROP TABLE IF EXISTS schedule;
DROP TABLE IF EXISTS performance_section_override;
DROP TABLE IF EXISTS performance_seat_grade;
DROP TABLE IF EXISTS performance;
DROP TABLE IF EXISTS notice;
DROP TABLE IF EXISTS venue_manager;
DROP TABLE IF EXISTS promoter;
DROP TABLE IF EXISTS venue_stage_section;
DROP TABLE IF EXISTS venue_stage_config;
DROP TABLE IF EXISTS venue_seat_template;
DROP TABLE IF EXISTS venue_section;
DROP TABLE IF EXISTS venue;
DROP TABLE IF EXISTS member;

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- 2. 테이블 정의 (FK 부모 → 자식 순서)
-- =============================================================================

-- ── member ───────────────────────────────────────────────
CREATE TABLE member (
    member_id      BIGINT       NOT NULL AUTO_INCREMENT,
    email          VARCHAR(120) NOT NULL,
    password       VARCHAR(120) NOT NULL,
    name           VARCHAR(60)  NOT NULL,
    phone          VARCHAR(30)  NULL,
    role           VARCHAR(30)  NOT NULL DEFAULT 'USER'
                   COMMENT 'USER | SUPER_ADMIN | ADMIN(legacy) | STAFF | PROMOTER | VENUE_MANAGER',
    status         VARCHAR(30)  NOT NULL DEFAULT 'ACTIVE'
                   COMMENT 'ACTIVE | DORMANT | WITHDRAWN | PENDING_APPROVAL',
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login_at  DATETIME     NULL,
    PRIMARY KEY (member_id),
    UNIQUE KEY uk_member_email (email),
    KEY idx_member_role_status (role, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── venue ────────────────────────────────────────────────
CREATE TABLE venue (
    venue_id        BIGINT       NOT NULL AUTO_INCREMENT,
    api_facility_id VARCHAR(30)  NULL COMMENT 'KOPIS mt10id',
    name            VARCHAR(150) NOT NULL,
    address         VARCHAR(255) NULL,
    seat_scale      INT          NULL,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (venue_id),
    UNIQUE KEY uk_venue_api (api_facility_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── venue_section (구역 정의) ────────────────────────────
CREATE TABLE venue_section (
    section_id     BIGINT       NOT NULL AUTO_INCREMENT,
    venue_id       BIGINT       NOT NULL,
    section_name   VARCHAR(60)  NOT NULL,
    section_type   VARCHAR(30)  NOT NULL COMMENT 'FLOOR|BALCONY|VIP_BOX|STANDING|PREMIUM',
    total_rows     INT          NOT NULL,
    seats_per_row  INT          NOT NULL,
    display_order  INT          NOT NULL DEFAULT 0,
    PRIMARY KEY (section_id),
    KEY idx_vs_venue (venue_id),
    CONSTRAINT fk_vs_venue FOREIGN KEY (venue_id)
        REFERENCES venue (venue_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── venue_seat_template (좌석 템플릿) ────────────────────
CREATE TABLE venue_seat_template (
    template_id  BIGINT      NOT NULL AUTO_INCREMENT,
    venue_id     BIGINT      NOT NULL,
    section_id   BIGINT      NOT NULL,
    seat_row     VARCHAR(10) NOT NULL,
    seat_number  INT         NOT NULL,
    seat_type    VARCHAR(20) NOT NULL DEFAULT 'NORMAL'
                 COMMENT 'NORMAL|ACCESSIBLE|OBSTRUCTED|AISLE',
    PRIMARY KEY (template_id),
    UNIQUE KEY uk_vst_seat (venue_id, section_id, seat_row, seat_number),
    KEY idx_vst_section (section_id),
    CONSTRAINT fk_vst_venue   FOREIGN KEY (venue_id)
        REFERENCES venue (venue_id) ON DELETE CASCADE,
    CONSTRAINT fk_vst_section FOREIGN KEY (section_id)
        REFERENCES venue_section (section_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── venue_stage_config (공연장 무대 구성) ────────────────
CREATE TABLE venue_stage_config (
    config_id    BIGINT       NOT NULL AUTO_INCREMENT,
    venue_id     BIGINT       NOT NULL,
    config_name  VARCHAR(80)  NOT NULL,
    description  VARCHAR(255) NULL,
    is_default   TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (config_id),
    KEY idx_vsc_venue (venue_id),
    CONSTRAINT fk_vsc_venue FOREIGN KEY (venue_id)
        REFERENCES venue (venue_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── venue_stage_section (구성 ↔ 구역 매핑) ───────────────
CREATE TABLE venue_stage_section (
    id                    BIGINT     NOT NULL AUTO_INCREMENT,
    config_id             BIGINT     NOT NULL,
    section_id            BIGINT     NOT NULL,
    is_active             TINYINT(1) NOT NULL DEFAULT 1,
    custom_rows           INT        NULL,
    custom_seats_per_row  INT        NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_vss_pair (config_id, section_id),
    KEY idx_vss_section (section_id),
    CONSTRAINT fk_vss_config  FOREIGN KEY (config_id)
        REFERENCES venue_stage_config (config_id) ON DELETE CASCADE,
    CONSTRAINT fk_vss_section FOREIGN KEY (section_id)
        REFERENCES venue_section (section_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── promoter (기획사) ────────────────────────────────────
CREATE TABLE promoter (
    promoter_id      BIGINT       NOT NULL AUTO_INCREMENT,
    member_id        BIGINT       NOT NULL,
    company_name     VARCHAR(120) NOT NULL,
    business_reg_no  VARCHAR(20)  NULL,
    representative   VARCHAR(60)  NULL,
    contact_email    VARCHAR(120) NULL,
    contact_phone    VARCHAR(30)  NULL,
    contract_doc_url VARCHAR(500) NULL,
    approval_status  VARCHAR(20)  NOT NULL DEFAULT 'PENDING'
                     COMMENT 'PENDING|APPROVED|REJECTED|SUSPENDED',
    approved_by      BIGINT       NULL,
    approved_at      DATETIME     NULL,
    reject_reason    VARCHAR(500) NULL,
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (promoter_id),
    UNIQUE KEY uk_promoter_member (member_id),
    UNIQUE KEY uk_promoter_brn    (business_reg_no),
    KEY idx_promoter_status (approval_status),
    CONSTRAINT fk_promoter_member   FOREIGN KEY (member_id)
        REFERENCES member (member_id) ON DELETE CASCADE,
    CONSTRAINT fk_promoter_approver FOREIGN KEY (approved_by)
        REFERENCES member (member_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── venue_manager (공연장 담당자) ────────────────────────
CREATE TABLE venue_manager (
    manager_id      BIGINT      NOT NULL AUTO_INCREMENT,
    member_id       BIGINT      NOT NULL,
    venue_id        BIGINT      NOT NULL,
    department      VARCHAR(80) NULL,
    position        VARCHAR(80) NULL,
    approval_status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                    COMMENT 'PENDING|APPROVED|REJECTED',
    approved_by     BIGINT      NULL,
    approved_at     DATETIME    NULL,
    created_at      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (manager_id),
    UNIQUE KEY uk_vm_member (member_id),
    KEY idx_vm_venue  (venue_id),
    KEY idx_vm_status (approval_status),
    CONSTRAINT fk_vm_member   FOREIGN KEY (member_id)
        REFERENCES member (member_id) ON DELETE CASCADE,
    CONSTRAINT fk_vm_venue    FOREIGN KEY (venue_id)
        REFERENCES venue (venue_id) ON DELETE RESTRICT,
    CONSTRAINT fk_vm_approver FOREIGN KEY (approved_by)
        REFERENCES member (member_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── notice (공지) ────────────────────────────────────────
CREATE TABLE notice (
    notice_id        BIGINT       NOT NULL AUTO_INCREMENT,
    title            VARCHAR(200) NOT NULL,
    content          TEXT         NOT NULL,
    notice_type      VARCHAR(30)  NOT NULL DEFAULT 'SYSTEM'
                     COMMENT 'SYSTEM|EVENT|PERFORMANCE|MAINTENANCE',
    target_role      VARCHAR(20)  NOT NULL DEFAULT 'ALL'
                     COMMENT 'ALL|USER|PROMOTER|VENUE_MANAGER',
    is_pinned        TINYINT(1)   NOT NULL DEFAULT 0,
    is_active        TINYINT(1)   NOT NULL DEFAULT 1,
    author_member_id BIGINT       NOT NULL,
    view_count       INT          NOT NULL DEFAULT 0,
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (notice_id),
    KEY idx_notice_active (is_active, target_role),
    CONSTRAINT fk_notice_author FOREIGN KEY (author_member_id)
        REFERENCES member (member_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── performance ──────────────────────────────────────────
CREATE TABLE performance (
    performance_id   BIGINT       NOT NULL AUTO_INCREMENT,
    api_perf_id      VARCHAR(30)  NULL,
    title            VARCHAR(200) NOT NULL,
    category         VARCHAR(40)  NOT NULL DEFAULT 'CONCERT'
                     COMMENT 'CONCERT|MUSICAL|PLAY|BALLET|CLASSIC|EXHIBITION|FAMILY',
    age_limit        VARCHAR(40)  NULL,
    running_time     INT          NULL,
    min_price        INT          NULL,
    venue_id         BIGINT       NOT NULL,
    venue_name       VARCHAR(150) NOT NULL,
    description      TEXT         NULL,
    poster_url       VARCHAR(500) NULL,
    total_seats      INT          NOT NULL DEFAULT 0,
    ticket_open_at   DATETIME     NULL,
    start_date       DATE         NOT NULL,
    end_date         DATE         NOT NULL,
    status           VARCHAR(20)  NOT NULL DEFAULT 'UPCOMING'
                     COMMENT 'UPCOMING|ON_SALE|SOLD_OUT|ENDED',
    stage_config_id  BIGINT       NULL,
    promoter_id      BIGINT       NULL COMMENT 'NULL = SUPER_ADMIN 직접 등록',
    approval_status  VARCHAR(20)  NOT NULL DEFAULT 'DRAFT'
                     COMMENT 'DRAFT|REVIEW|APPROVED|REJECTED|PUBLISHED',
    approval_note    VARCHAR(500) NULL,
    reviewed_by      BIGINT       NULL,
    reviewed_at      DATETIME     NULL,
    created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (performance_id),
    UNIQUE KEY uk_perf_api (api_perf_id),
    KEY idx_perf_venue           (venue_id),
    KEY idx_perf_promoter_status (promoter_id, approval_status),
    KEY idx_perf_status_open     (approval_status, status, ticket_open_at),
    CONSTRAINT fk_perf_venue        FOREIGN KEY (venue_id)
        REFERENCES venue (venue_id) ON DELETE RESTRICT,
    CONSTRAINT fk_perf_stage_config FOREIGN KEY (stage_config_id)
        REFERENCES venue_stage_config (config_id) ON DELETE SET NULL,
    CONSTRAINT fk_perf_promoter     FOREIGN KEY (promoter_id)
        REFERENCES promoter (promoter_id) ON DELETE SET NULL,
    CONSTRAINT fk_perf_reviewer     FOREIGN KEY (reviewed_by)
        REFERENCES member (member_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── performance_seat_grade (공연-구역 가격) ──────────────
CREATE TABLE performance_seat_grade (
    grade_id       BIGINT      NOT NULL AUTO_INCREMENT,
    performance_id BIGINT      NOT NULL,
    section_id     BIGINT      NOT NULL,
    grade          VARCHAR(20) NOT NULL COMMENT 'VIP|R|S|A|STANDING',
    price          INT         NOT NULL,
    PRIMARY KEY (grade_id),
    UNIQUE KEY uk_psg_pair (performance_id, section_id),
    KEY idx_psg_section (section_id),
    CONSTRAINT fk_psg_perf    FOREIGN KEY (performance_id)
        REFERENCES performance (performance_id) ON DELETE CASCADE,
    CONSTRAINT fk_psg_section FOREIGN KEY (section_id)
        REFERENCES venue_section (section_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── performance_section_override ─────────────────────────
CREATE TABLE performance_section_override (
    override_id           BIGINT       NOT NULL AUTO_INCREMENT,
    performance_id        BIGINT       NOT NULL,
    section_id            BIGINT       NOT NULL,
    is_active             TINYINT(1)   NOT NULL DEFAULT 1,
    custom_rows           INT          NULL,
    custom_seats_per_row  INT          NULL,
    note                  VARCHAR(255) NULL,
    PRIMARY KEY (override_id),
    UNIQUE KEY uk_pso_pair (performance_id, section_id),
    KEY idx_pso_section (section_id),
    CONSTRAINT fk_pso_perf    FOREIGN KEY (performance_id)
        REFERENCES performance (performance_id) ON DELETE CASCADE,
    CONSTRAINT fk_pso_section FOREIGN KEY (section_id)
        REFERENCES venue_section (section_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── schedule (회차) ──────────────────────────────────────
CREATE TABLE schedule (
    schedule_id         BIGINT      NOT NULL AUTO_INCREMENT,
    performance_id      BIGINT      NOT NULL,
    show_date           DATE        NOT NULL,
    show_time           TIME        NOT NULL,
    available_seats     INT         NOT NULL DEFAULT 0,
    status              VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE'
                        COMMENT 'AVAILABLE|SOLD_OUT|CLOSED',
    max_seats_per_order INT         NOT NULL DEFAULT 4,
    PRIMARY KEY (schedule_id),
    UNIQUE KEY uk_schedule_pdt (performance_id, show_date, show_time),
    CONSTRAINT fk_schedule_perf FOREIGN KEY (performance_id)
        REFERENCES performance (performance_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── seat (공연별 좌석 인스턴스) ──────────────────────────
CREATE TABLE seat (
    seat_id        BIGINT      NOT NULL AUTO_INCREMENT,
    performance_id BIGINT      NOT NULL,
    section        VARCHAR(60) NOT NULL,
    seat_row       VARCHAR(10) NOT NULL,
    seat_number    INT         NOT NULL,
    grade          VARCHAR(20) NOT NULL,
    price          INT         NOT NULL,
    PRIMARY KEY (seat_id),
    UNIQUE KEY uk_seat_unique (performance_id, section, seat_row, seat_number),
    KEY idx_seat_perf (performance_id),
    CONSTRAINT fk_seat_perf FOREIGN KEY (performance_id)
        REFERENCES performance (performance_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── seat_inventory (회차별 좌석 가용 상태) ───────────────
CREATE TABLE seat_inventory (
    inventory_id BIGINT      NOT NULL AUTO_INCREMENT,
    schedule_id  BIGINT      NOT NULL,
    seat_id      BIGINT      NOT NULL,
    status       VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE'
                 COMMENT 'AVAILABLE|HELD|RESERVED',
    hold_type    VARCHAR(20) NOT NULL DEFAULT 'PUBLIC'
                 COMMENT 'PUBLIC|KILL|COMP|SPONSOR|ADMIN',
    held_by      BIGINT      NULL,
    held_until   DATETIME    NULL,
    version      INT         NOT NULL DEFAULT 0,
    PRIMARY KEY (inventory_id),
    UNIQUE KEY uk_inv_pair (schedule_id, seat_id),
    KEY idx_inv_schedule_status (schedule_id, status, hold_type),
    KEY idx_inv_held_until (held_until),
    KEY idx_inv_held_by (held_by),
    CONSTRAINT fk_inv_schedule FOREIGN KEY (schedule_id)
        REFERENCES schedule (schedule_id) ON DELETE CASCADE,
    CONSTRAINT fk_inv_seat     FOREIGN KEY (seat_id)
        REFERENCES seat (seat_id) ON DELETE CASCADE,
    CONSTRAINT fk_inv_holder   FOREIGN KEY (held_by)
        REFERENCES member (member_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── coupon_template ──────────────────────────────────────
CREATE TABLE coupon_template (
    template_id     BIGINT      NOT NULL AUTO_INCREMENT,
    promoter_id     BIGINT      NULL COMMENT 'NULL = 플랫폼 전체 쿠폰',
    performance_id  BIGINT      NULL COMMENT 'NULL = 모든 공연 적용',
    code_prefix     VARCHAR(20) NULL,
    name            VARCHAR(120) NOT NULL,
    discount_type   VARCHAR(10) NOT NULL DEFAULT 'FIXED'
                    COMMENT 'FIXED|PERCENT',
    discount_value  INT         NOT NULL,
    min_amount      INT         NOT NULL DEFAULT 0,
    max_discount    INT         NULL,
    total_quantity  INT         NOT NULL DEFAULT 0,
    issued_count    INT         NOT NULL DEFAULT 0,
    valid_from      DATETIME    NULL,
    valid_until     DATETIME    NULL,
    is_active       TINYINT(1)  NOT NULL DEFAULT 1,
    created_at      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (template_id),
    KEY idx_ct_promoter (promoter_id),
    KEY idx_ct_perf     (performance_id),
    CONSTRAINT fk_ct_promoter FOREIGN KEY (promoter_id)
        REFERENCES promoter (promoter_id) ON DELETE SET NULL,
    CONSTRAINT fk_ct_perf     FOREIGN KEY (performance_id)
        REFERENCES performance (performance_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── reservation ──────────────────────────────────────────
CREATE TABLE reservation (
    reservation_id BIGINT      NOT NULL AUTO_INCREMENT,
    reservation_no VARCHAR(40) NOT NULL,
    schedule_id    BIGINT      NOT NULL,
    member_id      BIGINT      NOT NULL,
    total_amount   INT         NOT NULL,
    seat_count     INT         NOT NULL,
    status         VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                   COMMENT 'PENDING|CONFIRMED|CANCELLED|REFUNDED',
    created_at     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    confirmed_at   DATETIME    NULL,
    cancelled_at   DATETIME    NULL,
    PRIMARY KEY (reservation_id),
    UNIQUE KEY uk_reservation_no (reservation_no),
    KEY idx_reservation_member  (member_id, created_at),
    KEY idx_reservation_sched   (schedule_id, status),
    KEY idx_reservation_status  (status),
    CONSTRAINT fk_reservation_sched  FOREIGN KEY (schedule_id)
        REFERENCES schedule (schedule_id) ON DELETE RESTRICT,
    CONSTRAINT fk_reservation_member FOREIGN KEY (member_id)
        REFERENCES member (member_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── reservation_seat ─────────────────────────────────────
CREATE TABLE reservation_seat (
    id             BIGINT NOT NULL AUTO_INCREMENT,
    reservation_id BIGINT NOT NULL,
    seat_id        BIGINT NOT NULL,
    price          INT    NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_rs_pair (reservation_id, seat_id),
    KEY idx_rs_seat (seat_id),
    CONSTRAINT fk_rs_reservation FOREIGN KEY (reservation_id)
        REFERENCES reservation (reservation_id) ON DELETE CASCADE,
    CONSTRAINT fk_rs_seat        FOREIGN KEY (seat_id)
        REFERENCES seat (seat_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── coupon (발급된 쿠폰) ─────────────────────────────────
CREATE TABLE coupon (
    coupon_id      BIGINT      NOT NULL AUTO_INCREMENT,
    template_id    BIGINT      NOT NULL,
    member_id      BIGINT      NOT NULL,
    coupon_code    VARCHAR(40) NOT NULL,
    status         VARCHAR(20) NOT NULL DEFAULT 'ISSUED'
                   COMMENT 'ISSUED|USED|EXPIRED|CANCELLED',
    used_at        DATETIME    NULL,
    reservation_id BIGINT      NULL,
    issued_at      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at     DATETIME    NOT NULL,
    PRIMARY KEY (coupon_id),
    UNIQUE KEY uk_coupon_code (coupon_code),
    KEY idx_coupon_member  (member_id),
    KEY idx_coupon_template(template_id),
    CONSTRAINT fk_coupon_template    FOREIGN KEY (template_id)
        REFERENCES coupon_template (template_id) ON DELETE RESTRICT,
    CONSTRAINT fk_coupon_member      FOREIGN KEY (member_id)
        REFERENCES member (member_id) ON DELETE CASCADE,
    CONSTRAINT fk_coupon_reservation FOREIGN KEY (reservation_id)
        REFERENCES reservation (reservation_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── payment (PaymentMapper.xml 컬럼 기준) ────────────────
--   ※ 도메인 Payment.java 와 컬럼명이 일부 다름 (id vs payment_id 등)
--     운영 가능한 형태는 PaymentMapper.xml. 아래 스키마는 Mapper 기준.
CREATE TABLE payment (
    id                BIGINT       NOT NULL AUTO_INCREMENT,
    reservation_id    BIGINT       NOT NULL,
    member_id         BIGINT       NOT NULL,
    amount            INT          NOT NULL,
    coupon_id         BIGINT       NULL,
    discount_amount   INT          NOT NULL DEFAULT 0,
    final_amount      INT          NOT NULL,
    method            VARCHAR(20)  NOT NULL DEFAULT 'CARD'
                      COMMENT 'CARD|BANK_TRANSFER',
    status            VARCHAR(20)  NOT NULL DEFAULT 'PENDING'
                      COMMENT 'PENDING|COMPLETED|FAILED|REFUNDED',
    idempotency_key   VARCHAR(80)  NOT NULL,
    pg_transaction_id VARCHAR(80)  NULL,
    fail_reason       VARCHAR(500) NULL,
    created_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at      DATETIME     NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_payment_idem (idempotency_key),
    KEY idx_payment_reservation (reservation_id),
    KEY idx_payment_status_created (status, created_at),
    CONSTRAINT fk_payment_reservation FOREIGN KEY (reservation_id)
        REFERENCES reservation (reservation_id) ON DELETE CASCADE,
    CONSTRAINT fk_payment_member      FOREIGN KEY (member_id)
        REFERENCES member (member_id) ON DELETE RESTRICT,
    CONSTRAINT fk_payment_coupon      FOREIGN KEY (coupon_id)
        REFERENCES coupon (coupon_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── entrance_log (입장 체크인) ───────────────────────────
CREATE TABLE entrance_log (
    entrance_log_id BIGINT       NOT NULL AUTO_INCREMENT,
    reservation_id  BIGINT       NOT NULL,
    schedule_id     BIGINT       NOT NULL,
    venue_id        BIGINT       NOT NULL,
    member_id       BIGINT       NOT NULL,
    checked_in_by   BIGINT       NULL,
    note            VARCHAR(255) NULL,
    checked_in_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (entrance_log_id),
    UNIQUE KEY uk_el_reservation (reservation_id),
    KEY idx_el_venue_date (venue_id, checked_in_at),
    KEY idx_el_schedule   (schedule_id),
    CONSTRAINT fk_el_reservation FOREIGN KEY (reservation_id)
        REFERENCES reservation (reservation_id) ON DELETE CASCADE,
    CONSTRAINT fk_el_schedule    FOREIGN KEY (schedule_id)
        REFERENCES schedule (schedule_id) ON DELETE RESTRICT,
    CONSTRAINT fk_el_venue       FOREIGN KEY (venue_id)
        REFERENCES venue (venue_id) ON DELETE RESTRICT,
    CONSTRAINT fk_el_member      FOREIGN KEY (member_id)
        REFERENCES member (member_id) ON DELETE RESTRICT,
    CONSTRAINT fk_el_checker     FOREIGN KEY (checked_in_by)
        REFERENCES member (member_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 3. 시드 데이터
--    공통 비밀번호: Cks159753!
--    BCrypt: $2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO
-- =============================================================================

-- ── members (8명) ────────────────────────────────────────
INSERT INTO member (member_id, email, password, name, phone, role, status) VALUES
(1, 'admin@ticketlegacy.com',  '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '슈퍼관리자',  '010-0000-0001', 'SUPER_ADMIN',   'ACTIVE'),
(2, 'staff@ticketlegacy.com',  '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '운영스태프',  '010-0000-0002', 'STAFF',         'ACTIVE'),
(3, 'user1@test.com',          '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '김유저',      '010-1111-1111', 'USER',          'ACTIVE'),
(4, 'user2@test.com',          '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '이팬',        '010-2222-2222', 'USER',          'ACTIVE'),
(5, 'user3@test.com',          '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '박관객',      '010-3333-3333', 'USER',          'ACTIVE'),
(6, 'promoter1@test.com',      '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '한국엔터(주)','02-555-1001',   'PROMOTER',      'ACTIVE'),
(7, 'promoter2@test.com',      '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '서울뮤직(주)','02-555-1002',   'PROMOTER',      'ACTIVE'),
(8, 'venue1@test.com',         '$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO', '잠실담당자',  '010-9999-0001', 'VENUE_MANAGER', 'ACTIVE');

-- ── venues (3개) ─────────────────────────────────────────
INSERT INTO venue (venue_id, api_facility_id, name, address, seat_scale) VALUES
(1, 'FC000001', '잠실종합운동장 주경기장', '서울특별시 송파구 올림픽로 25',  69950),
(2, 'FC000002', '올림픽홀',                 '서울특별시 송파구 올림픽로 424', 2452),
(3, 'FC000003', '블루스퀘어 마스터카드홀', '서울특별시 용산구 이태원로 294', 1766);

-- ── venue_section ────────────────────────────────────────
--   venue1: VIP(2x5), R(3x8), S(4x10), A(5x12)
--   venue2: R(2x6), S(3x8), A(4x10)
--   venue3: VIP(2x4), R(3x6), S(4x8)
INSERT INTO venue_section (section_id, venue_id, section_name, section_type, total_rows, seats_per_row, display_order) VALUES
(1,  1, 'VIP구역', 'VIP_BOX',  2, 5, 1),
(2,  1, 'R구역',   'FLOOR',    3, 8, 2),
(3,  1, 'S구역',   'FLOOR',    4, 10, 3),
(4,  1, 'A구역',   'BALCONY',  5, 12, 4),
(5,  2, 'R구역',   'FLOOR',    2, 6, 1),
(6,  2, 'S구역',   'FLOOR',    3, 8, 2),
(7,  2, 'A구역',   'BALCONY',  4, 10, 3),
(8,  3, 'VIP구역', 'VIP_BOX',  2, 4, 1),
(9,  3, 'R구역',   'FLOOR',    3, 6, 2),
(10, 3, 'S구역',   'BALCONY',  4, 8, 3);

-- ── venue_stage_config (각 venue 1개씩) ──────────────────
INSERT INTO venue_stage_config (config_id, venue_id, config_name, description, is_default) VALUES
(1, 1, '풀구성',     '잠실주경기장 표준 구성',     1),
(2, 2, '표준',       '올림픽홀 표준',                1),
(3, 3, '풀구성',     '블루스퀘어 표준',              1);

-- ── venue_stage_section (config × section 매핑) ─────────
INSERT INTO venue_stage_section (config_id, section_id, is_active, custom_rows, custom_seats_per_row) VALUES
(1, 1, 1, NULL, NULL),
(1, 2, 1, NULL, NULL),
(1, 3, 1, NULL, NULL),
(1, 4, 1, NULL, NULL),
(2, 5, 1, NULL, NULL),
(2, 6, 1, NULL, NULL),
(2, 7, 1, NULL, NULL),
(3, 8, 1, NULL, NULL),
(3, 9, 1, NULL, NULL),
(3, 10, 1, NULL, NULL);

-- ── venue_seat_template (section의 좌석 템플릿) ─────────
--   각 섹션의 행/열만큼 NORMAL 좌석을 미리 등록
--   행은 'A','B'... 형태 (CHAR(64+r))
INSERT INTO venue_seat_template (venue_id, section_id, seat_row, seat_number, seat_type)
WITH RECURSIVE
  rng(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM rng WHERE n < 30)
SELECT vs.venue_id,
       vs.section_id,
       CHAR(64 + r.n) AS seat_row,
       c.n            AS seat_number,
       'NORMAL'
FROM   venue_section vs
JOIN   rng r ON r.n <= vs.total_rows
JOIN   rng c ON c.n <= vs.seats_per_row;

-- ── promoter (2개: 1명 APPROVED, 1명 PENDING) ───────────
INSERT INTO promoter (promoter_id, member_id, company_name, business_reg_no, representative,
                      contact_email, contact_phone, contract_doc_url,
                      approval_status, approved_by, approved_at) VALUES
(1, 6, '한국엔터테인먼트(주)', '111-22-33333', '김대표',
   'biz@hkent.co.kr',  '02-555-1001', NULL,
   'APPROVED', 1, NOW()),
(2, 7, '서울뮤직컴퍼니(주)',   '222-33-44444', '이대표',
   'biz@seoulmusic.kr', '02-555-1002', NULL,
   'PENDING',  NULL, NULL);

-- ── venue_manager (1명 APPROVED) ─────────────────────────
INSERT INTO venue_manager (manager_id, member_id, venue_id, department, position,
                            approval_status, approved_by, approved_at) VALUES
(1, 8, 1, '운영팀', '담당매니저', 'APPROVED', 1, NOW());

-- ── notice (3개) ─────────────────────────────────────────
INSERT INTO notice (notice_id, title, content, notice_type, target_role,
                     is_pinned, is_active, author_member_id, view_count) VALUES
(1, '서비스 오픈 안내',
 '<p>티켓레거시 서비스를 정식 오픈했습니다. 많은 이용 부탁드립니다.</p>',
 'SYSTEM', 'ALL', 1, 1, 1, 0),
(2, '결제 시스템 점검 (06:00~07:00)',
 '<p>매월 첫째 주 일요일 새벽 1시간 동안 결제 시스템 점검이 진행됩니다.</p>',
 'MAINTENANCE', 'ALL', 0, 1, 1, 0),
(3, '기획사 정산 방식 변경',
 '<p>2026년 5월부터 정산 비율이 90:10으로 일원화됩니다.</p>',
 'SYSTEM', 'PROMOTER', 0, 1, 1, 0);

-- ── performance (4개) ────────────────────────────────────
--   1: PUBLISHED + ON_SALE  (promoter1, venue1)  ← 사용자 노출
--   2: PUBLISHED + ON_SALE  (promoter1, venue2)  ← 사용자 노출
--   3: REVIEW               (promoter2, venue1)  ← 어드민 심사 대기
--   4: APPROVED             (promoter1, venue3)  ← 게시 대기
INSERT INTO performance
  (performance_id, api_perf_id, title, category, age_limit, running_time, min_price,
   venue_id, venue_name, description, poster_url, total_seats,
   ticket_open_at, start_date, end_date,
   status, stage_config_id, promoter_id,
   approval_status, approval_note, reviewed_by, reviewed_at)
VALUES
(1, 'PF000001', '2026 IU CONCERT : THE GOLDEN HOUR', 'CONCERT',
   '8세 이상', 180, 132000,
   1, '잠실종합운동장 주경기장',
   '<p>아이유의 대규모 단독 콘서트.</p><ul><li>오프닝 게스트 : 새소년</li></ul>',
   'https://placehold.co/400x550?text=IU+Concert', 134,
   DATE_SUB(NOW(), INTERVAL 1 DAY),
   DATE_ADD(CURDATE(), INTERVAL 30 DAY),
   DATE_ADD(CURDATE(), INTERVAL 31 DAY),
   'ON_SALE', 1, 1,
   'PUBLISHED', '심사 통과', 1, NOW()),

(2, 'PF000002', '뮤지컬 〈라이온 킹〉 인터내셔널 투어', 'MUSICAL',
   '7세 이상', 150, 88000,
   2, '올림픽홀',
   '<p>디즈니 뮤지컬 라이온킹의 인터내셔널 투어 한국 공연.</p>',
   'https://placehold.co/400x550?text=Lion+King', 76,
   DATE_SUB(NOW(), INTERVAL 1 DAY),
   DATE_ADD(CURDATE(), INTERVAL 14 DAY),
   DATE_ADD(CURDATE(), INTERVAL 60 DAY),
   'ON_SALE', 2, 1,
   'PUBLISHED', '심사 통과', 1, NOW()),

(3, 'PF000003', 'BTS WORLD TOUR 2026 - SEOUL', 'CONCERT',
   '전체관람가', 200, 165000,
   1, '잠실종합운동장 주경기장',
   '<p>방탄소년단 월드투어 서울 공연 (심사 대기 샘플).</p>',
   'https://placehold.co/400x550?text=BTS+Tour', 0,
   DATE_ADD(NOW(), INTERVAL 7 DAY),
   DATE_ADD(CURDATE(), INTERVAL 50 DAY),
   DATE_ADD(CURDATE(), INTERVAL 51 DAY),
   'UPCOMING', 1, 2,
   'REVIEW', NULL, NULL, NULL),

(4, 'PF000004', '국립발레단 〈백조의 호수〉', 'BALLET',
   '5세 이상', 130, 50000,
   3, '블루스퀘어 마스터카드홀',
   '<p>국립발레단 정기공연. 차이콥스키 백조의 호수.</p>',
   'https://placehold.co/400x550?text=Swan+Lake', 0,
   DATE_ADD(NOW(), INTERVAL 14 DAY),
   DATE_ADD(CURDATE(), INTERVAL 45 DAY),
   DATE_ADD(CURDATE(), INTERVAL 47 DAY),
   'UPCOMING', 3, 1,
   'APPROVED', '승인됨, 게시 대기', 1, NOW());

-- ── performance_seat_grade (공연 1·2 가격 매핑) ─────────
--   performance 1 (잠실)
INSERT INTO performance_seat_grade (performance_id, section_id, grade, price) VALUES
(1, 1, 'VIP', 220000),
(1, 2, 'R',   165000),
(1, 3, 'S',   132000),
(1, 4, 'A',    99000);

--   performance 2 (올림픽홀)
INSERT INTO performance_seat_grade (performance_id, section_id, grade, price) VALUES
(2, 5, 'R', 154000),
(2, 6, 'S', 121000),
(2, 7, 'A',  88000);

--   performance 4 (블루스퀘어)
INSERT INTO performance_seat_grade (performance_id, section_id, grade, price) VALUES
(4,  8, 'VIP', 110000),
(4,  9, 'R',    77000),
(4, 10, 'S',    50000);

-- ── seat (공연 × 구역 × 행 × 열) ────────────────────────
--   venue_section의 행/열을 그대로 사용 (override 없음)
--   ORDER BY 로 삽입 순서를 보장 → seat_id 가 (perf, section, row, num) 순서로 부여
INSERT INTO seat (performance_id, section, seat_row, seat_number, grade, price)
WITH RECURSIVE
  rng(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM rng WHERE n < 30)
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

-- ── schedule (회차) ──────────────────────────────────────
--   performance 1: 2회차
--   performance 2: 3회차
--   performance 4: 2회차
INSERT INTO schedule (schedule_id, performance_id, show_date, show_time, available_seats, status, max_seats_per_order) VALUES
(1, 1, DATE_ADD(CURDATE(), INTERVAL 30 DAY), '19:00:00', 0, 'AVAILABLE', 4),
(2, 1, DATE_ADD(CURDATE(), INTERVAL 31 DAY), '18:00:00', 0, 'AVAILABLE', 4),
(3, 2, DATE_ADD(CURDATE(), INTERVAL 14 DAY), '14:00:00', 0, 'AVAILABLE', 4),
(4, 2, DATE_ADD(CURDATE(), INTERVAL 14 DAY), '19:30:00', 0, 'AVAILABLE', 4),
(5, 2, DATE_ADD(CURDATE(), INTERVAL 21 DAY), '15:00:00', 0, 'AVAILABLE', 4),
(6, 4, DATE_ADD(CURDATE(), INTERVAL 45 DAY), '19:30:00', 0, 'AVAILABLE', 4),
(7, 4, DATE_ADD(CURDATE(), INTERVAL 47 DAY), '15:00:00', 0, 'AVAILABLE', 4);

-- ── seat_inventory (회차 × 좌석 모두 AVAILABLE/PUBLIC) ──
INSERT INTO seat_inventory (schedule_id, seat_id, status, hold_type, version)
SELECT sc.schedule_id, s.seat_id, 'AVAILABLE', 'PUBLIC', 0
FROM   schedule sc
JOIN   seat s ON s.performance_id = sc.performance_id;

-- ── schedule.available_seats / performance.total_seats 보정
UPDATE schedule sc
JOIN (
  SELECT schedule_id, COUNT(*) AS cnt
  FROM   seat_inventory
  WHERE  status = 'AVAILABLE' AND hold_type = 'PUBLIC'
  GROUP BY schedule_id
) x ON x.schedule_id = sc.schedule_id
SET sc.available_seats = x.cnt;

UPDATE performance p
JOIN (
  SELECT performance_id, COUNT(*) AS cnt FROM seat GROUP BY performance_id
) x ON x.performance_id = p.performance_id
SET p.total_seats = x.cnt;

-- ── coupon_template (2개) ────────────────────────────────
INSERT INTO coupon_template
  (template_id, promoter_id, performance_id, code_prefix, name,
   discount_type, discount_value, min_amount, max_discount,
   total_quantity, issued_count, valid_from, valid_until, is_active)
VALUES
(1, 1, 1, 'IU2026', '아이유 콘서트 1만원 할인',
   'FIXED', 10000, 100000, NULL,
   100, 1,
   DATE_SUB(NOW(), INTERVAL 7 DAY),
   DATE_ADD(NOW(), INTERVAL 30 DAY), 1),
(2, NULL, NULL, 'WELCOME', '신규회원 10% 할인 (최대 2만원)',
   'PERCENT', 10, 50000, 20000,
   1000, 1,
   DATE_SUB(NOW(), INTERVAL 30 DAY),
   DATE_ADD(NOW(), INTERVAL 365 DAY), 1);

-- ── coupon (테스트 발급) ────────────────────────────────
INSERT INTO coupon (coupon_id, template_id, member_id, coupon_code, status,
                    used_at, reservation_id, issued_at, expires_at) VALUES
(1, 1, 3, 'IU2026-USER1-0001', 'ISSUED', NULL, NULL, NOW(),
   DATE_ADD(NOW(), INTERVAL 30 DAY)),
(2, 2, 3, 'WELCOME-USER1',     'ISSUED', NULL, NULL, NOW(),
   DATE_ADD(NOW(), INTERVAL 365 DAY));

-- ── reservation (샘플 1건 — user1이 공연1 회차1 VIP 2석 예매 완료) ──
--   seat_id 를 하드코딩하지 않고 (공연·구역·행·번호) 로 조회해 사용 → 삽입 순서 무관
INSERT INTO reservation (reservation_id, reservation_no, schedule_id, member_id,
                          total_amount, seat_count, status, confirmed_at)
VALUES
(1, 'R20260420000001', 1, 3, 440000, 2, 'CONFIRMED', NOW());

INSERT INTO reservation_seat (reservation_id, seat_id, price)
SELECT 1, s.seat_id, s.price
FROM   seat s
WHERE  s.performance_id = 1
  AND  s.section        = 'VIP구역'
  AND  s.seat_row       = 'A'
  AND  s.seat_number   IN (1, 2);

-- 점유된 seat_inventory 갱신 (RESERVED)
UPDATE seat_inventory si
JOIN   seat s ON s.seat_id = si.seat_id
SET    si.status = 'RESERVED', si.version = si.version + 1
WHERE  si.schedule_id = 1
  AND  s.performance_id = 1
  AND  s.section        = 'VIP구역'
  AND  s.seat_row       = 'A'
  AND  s.seat_number   IN (1, 2);

-- schedule.available_seats 재계산 (RESERVED 제외)
UPDATE schedule sc
JOIN (
  SELECT schedule_id, COUNT(*) AS cnt
  FROM   seat_inventory
  WHERE  status = 'AVAILABLE' AND hold_type = 'PUBLIC'
  GROUP BY schedule_id
) x ON x.schedule_id = sc.schedule_id
SET sc.available_seats = x.cnt;

-- ── payment (위 reservation 결제 완료 샘플) ──────────────
INSERT INTO payment (id, reservation_id, member_id, amount, coupon_id,
                      discount_amount, final_amount, status,
                      idempotency_key, pg_transaction_id, completed_at)
VALUES
(1, 1, 3, 440000, NULL, 0, 440000, 'COMPLETED',
   'IDEMP-R20260420000001', 'PG-MOCK-0000000001', NOW());

-- =============================================================================
-- 4. AUTO_INCREMENT 정렬
-- =============================================================================
ALTER TABLE member          AUTO_INCREMENT = 100;
ALTER TABLE venue           AUTO_INCREMENT = 100;
ALTER TABLE venue_section   AUTO_INCREMENT = 100;
ALTER TABLE venue_stage_config  AUTO_INCREMENT = 100;
ALTER TABLE venue_stage_section AUTO_INCREMENT = 100;
ALTER TABLE promoter        AUTO_INCREMENT = 100;
ALTER TABLE venue_manager   AUTO_INCREMENT = 100;
ALTER TABLE notice          AUTO_INCREMENT = 100;
ALTER TABLE performance     AUTO_INCREMENT = 100;
ALTER TABLE performance_seat_grade        AUTO_INCREMENT = 100;
ALTER TABLE performance_section_override  AUTO_INCREMENT = 100;
ALTER TABLE schedule        AUTO_INCREMENT = 100;
ALTER TABLE coupon_template AUTO_INCREMENT = 100;
ALTER TABLE coupon          AUTO_INCREMENT = 100;
ALTER TABLE reservation     AUTO_INCREMENT = 100;
ALTER TABLE payment         AUTO_INCREMENT = 100;
ALTER TABLE entrance_log    AUTO_INCREMENT = 100;

-- =============================================================================
-- 5. 검증 쿼리 (수동 확인용 — 주석 해제하여 사용)
-- =============================================================================
-- SELECT role, COUNT(*) FROM member GROUP BY role;
-- SELECT performance_id, title, approval_status, status, total_seats FROM performance;
-- SELECT schedule_id, performance_id, show_date, show_time, available_seats FROM schedule;
-- SELECT COUNT(*) AS inventory_rows FROM seat_inventory;
-- SELECT status, COUNT(*) FROM seat_inventory GROUP BY status;
