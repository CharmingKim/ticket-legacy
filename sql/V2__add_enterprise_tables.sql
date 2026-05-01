-- TicketLegacy Enterprise Table Migration V2
-- 실행 전 반드시 백업: mysqldump -uroot -p1234 springgreen6 > backup_before_v2.sql

USE springgreen6;

-- ============================================================
-- 1순위: 법적/운영 필수
-- ============================================================

-- 회원 상태 변경 감사 이력 (누가 언제 왜 바꿨는지)
CREATE TABLE IF NOT EXISTS member_status_history (
    history_id   BIGINT       PRIMARY KEY AUTO_INCREMENT,
    member_id    BIGINT       NOT NULL,
    from_status  VARCHAR(30),
    to_status    VARCHAR(30)  NOT NULL,
    changed_by   BIGINT,                  -- 처리 어드민 member_id (NULL=시스템)
    reason       VARCHAR(500),
    created_at   DATETIME     DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_msh_member (member_id),
    INDEX idx_msh_created (created_at)
);

-- 제재 이력 (정지/탈퇴 사유 상세 기록)
CREATE TABLE IF NOT EXISTS member_sanction (
    sanction_id    BIGINT       PRIMARY KEY AUTO_INCREMENT,
    member_id      BIGINT       NOT NULL,
    sanction_type  VARCHAR(30)  NOT NULL,  -- SUSPENDED, WITHDRAWN
    reason         VARCHAR(500) NOT NULL,
    sanctioned_by  BIGINT       NOT NULL,
    sanctioned_at  DATETIME     DEFAULT CURRENT_TIMESTAMP,
    lifted_at      DATETIME,
    lifted_by      BIGINT,
    lift_reason    VARCHAR(500),
    INDEX idx_ms_member (member_id)
);

-- 약관 버전 관리
CREATE TABLE IF NOT EXISTS terms (
    terms_id      BIGINT       PRIMARY KEY AUTO_INCREMENT,
    terms_type    VARCHAR(30)  NOT NULL,   -- SERVICE, PRIVACY, MARKETING, AGE
    version       VARCHAR(20)  NOT NULL,
    title         VARCHAR(200) NOT NULL,
    content       LONGTEXT     NOT NULL,
    is_required   BOOLEAN      DEFAULT TRUE,
    effective_at  DATETIME     NOT NULL,
    created_at    DATETIME     DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_terms_type_ver (terms_type, version)
);

-- 회원 약관 동의 이력 (개인정보보호법 의무)
CREATE TABLE IF NOT EXISTS member_terms_agreement (
    agreement_id  BIGINT    PRIMARY KEY AUTO_INCREMENT,
    member_id     BIGINT    NOT NULL,
    terms_id      BIGINT    NOT NULL,
    agreed        BOOLEAN   NOT NULL,
    ip_address    VARCHAR(45),
    agreed_at     DATETIME  DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_mta_member_terms (member_id, terms_id),
    INDEX idx_mta_member (member_id)
);

-- 환불 정책 (공연별, 기간별 차등 환불율)
CREATE TABLE IF NOT EXISTS refund_policy (
    policy_id        BIGINT       PRIMARY KEY AUTO_INCREMENT,
    performance_id   BIGINT,                -- NULL = 플랫폼 기본 정책
    days_before_show INT          NOT NULL, -- 공연 D-N 기준
    refund_rate      TINYINT      NOT NULL, -- 환불율 % (100=전액, 0=불가)
    description      VARCHAR(300),
    created_at       DATETIME     DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_rp_performance (performance_id)
);

-- 환불 이력 (금감원 기준 전액 추적)
CREATE TABLE IF NOT EXISTS refund (
    refund_id      BIGINT       PRIMARY KEY AUTO_INCREMENT,
    payment_id     BIGINT       NOT NULL,
    reservation_id BIGINT       NOT NULL,
    member_id      BIGINT       NOT NULL,
    refund_amount  INT          NOT NULL,
    refund_reason  VARCHAR(500),
    refund_type    VARCHAR(30)  NOT NULL,   -- USER_CANCEL, ADMIN_CANCEL, PERFORMANCE_CANCEL
    status         VARCHAR(20)  NOT NULL DEFAULT 'PENDING', -- PENDING, COMPLETED, REJECTED
    processed_by   BIGINT,
    processed_at   DATETIME,
    pg_refund_id   VARCHAR(200),
    created_at     DATETIME     DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_refund_payment (payment_id),
    INDEX idx_refund_member (member_id),
    INDEX idx_refund_status (status)
);

-- 정산 확정 헤더 (기획사별 월 정산)
CREATE TABLE IF NOT EXISTS settlement (
    settlement_id   BIGINT      PRIMARY KEY AUTO_INCREMENT,
    promoter_id     BIGINT      NOT NULL,
    settlement_month VARCHAR(7) NOT NULL,   -- YYYY-MM
    total_sales     BIGINT      NOT NULL DEFAULT 0,
    platform_fee    INT         NOT NULL DEFAULT 0,
    vat             INT         NOT NULL DEFAULT 0,
    net_amount      BIGINT      NOT NULL DEFAULT 0, -- 실지급액
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING, CONFIRMED, PAID
    confirmed_by    BIGINT,
    confirmed_at    DATETIME,
    paid_at         DATETIME,
    note            VARCHAR(500),
    created_at      DATETIME    DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_settlement_promoter_month (promoter_id, settlement_month)
);

-- 정산 세부 항목 (공연별 내역)
CREATE TABLE IF NOT EXISTS settlement_item (
    item_id           BIGINT       PRIMARY KEY AUTO_INCREMENT,
    settlement_id     BIGINT       NOT NULL,
    performance_id    BIGINT       NOT NULL,
    performance_title VARCHAR(200),
    sold_count        INT          NOT NULL DEFAULT 0,
    refund_count      INT          NOT NULL DEFAULT 0,
    gross_amount      BIGINT       NOT NULL DEFAULT 0,
    refund_amount     BIGINT       NOT NULL DEFAULT 0,
    net_amount        BIGINT       NOT NULL DEFAULT 0,
    INDEX idx_si_settlement (settlement_id)
);

-- ============================================================
-- 2순위: 서비스 품질
-- ============================================================

-- 알림 템플릿 (문구 하드코딩 방지)
CREATE TABLE IF NOT EXISTS notification_template (
    template_id    BIGINT       PRIMARY KEY AUTO_INCREMENT,
    template_code  VARCHAR(50)  NOT NULL UNIQUE, -- RESERVATION_CONFIRMED, CANCELLED 등
    channel        VARCHAR(20)  NOT NULL,         -- EMAIL, SMS, PUSH, IN_APP
    title_template VARCHAR(200) NOT NULL,
    body_template  LONGTEXT     NOT NULL,
    is_active      BOOLEAN      DEFAULT TRUE,
    created_at     DATETIME     DEFAULT CURRENT_TIMESTAMP
);

-- 알림 발송 이력
CREATE TABLE IF NOT EXISTS notification (
    notification_id BIGINT      PRIMARY KEY AUTO_INCREMENT,
    member_id       BIGINT      NOT NULL,
    template_id     BIGINT,
    channel         VARCHAR(20) NOT NULL,
    title           VARCHAR(200) NOT NULL,
    body            TEXT        NOT NULL,
    related_type    VARCHAR(50),  -- RESERVATION, PERFORMANCE, SYSTEM
    related_id      BIGINT,
    is_read         BOOLEAN     DEFAULT FALSE,
    sent_at         DATETIME,
    read_at         DATETIME,
    created_at      DATETIME    DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_notif_member (member_id),
    INDEX idx_notif_unread (member_id, is_read)
);

-- 포인트 잔액 (회원당 1건)
CREATE TABLE IF NOT EXISTS point_balance (
    balance_id       BIGINT   PRIMARY KEY AUTO_INCREMENT,
    member_id        BIGINT   NOT NULL UNIQUE,
    total_earned     INT      NOT NULL DEFAULT 0,
    total_used       INT      NOT NULL DEFAULT 0,
    available_point  INT      NOT NULL DEFAULT 0,
    updated_at       DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 포인트 이력
CREATE TABLE IF NOT EXISTS point_history (
    history_id    BIGINT       PRIMARY KEY AUTO_INCREMENT,
    member_id     BIGINT       NOT NULL,
    point_type    VARCHAR(20)  NOT NULL,   -- EARN, USE, EXPIRE, ADMIN_ADJUST
    amount        INT          NOT NULL,   -- 양수=적립, 음수=차감
    balance_after INT          NOT NULL,
    related_type  VARCHAR(50),             -- RESERVATION, REFUND, ADMIN
    related_id    BIGINT,
    description   VARCHAR(200),
    expires_at    DATETIME,
    created_at    DATETIME     DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ph_member (member_id),
    INDEX idx_ph_created (created_at),
    INDEX idx_ph_expires (expires_at)
);

-- 공연 리뷰 (실관람 인증 필수)
CREATE TABLE IF NOT EXISTS performance_review (
    review_id      BIGINT     PRIMARY KEY AUTO_INCREMENT,
    performance_id BIGINT     NOT NULL,
    member_id      BIGINT     NOT NULL,
    reservation_id BIGINT     NOT NULL,   -- 실관람 인증
    rating         TINYINT    NOT NULL,   -- 1~5
    content        TEXT,
    is_visible     BOOLEAN    DEFAULT TRUE,
    created_at     DATETIME   DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME,
    UNIQUE KEY uk_review_member_perf (member_id, performance_id),
    INDEX idx_review_performance (performance_id)
);

-- 리뷰 신고
CREATE TABLE IF NOT EXISTS review_report (
    report_id    BIGINT       PRIMARY KEY AUTO_INCREMENT,
    review_id    BIGINT       NOT NULL,
    reporter_id  BIGINT       NOT NULL,
    reason       VARCHAR(30)  NOT NULL,   -- SPAM, ABUSE, IRRELEVANT, SPOILER
    detail       VARCHAR(500),
    status       VARCHAR(20)  DEFAULT 'PENDING', -- PENDING, RESOLVED, DISMISSED
    processed_by BIGINT,
    created_at   DATETIME     DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_rr_review (review_id)
);

-- FAQ
CREATE TABLE IF NOT EXISTS faq (
    faq_id           BIGINT       PRIMARY KEY AUTO_INCREMENT,
    category         VARCHAR(50)  NOT NULL, -- RESERVATION, PAYMENT, REFUND, ACCOUNT, ETC
    question         VARCHAR(500) NOT NULL,
    answer           LONGTEXT     NOT NULL,
    display_order    INT          DEFAULT 0,
    is_active        BOOLEAN      DEFAULT TRUE,
    author_member_id BIGINT,
    view_count       INT          DEFAULT 0,
    created_at       DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME
);

-- ============================================================
-- 3순위: 분석/인프라
-- ============================================================

-- 검색어 로그 (인기 검색어 · 트렌드)
CREATE TABLE IF NOT EXISTS search_keyword_log (
    log_id       BIGINT       PRIMARY KEY AUTO_INCREMENT,
    keyword      VARCHAR(200) NOT NULL,
    member_id    BIGINT,                  -- NULL = 비로그인
    result_count INT,
    searched_at  DATETIME     DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_skl_keyword (keyword),
    INDEX idx_skl_searched (searched_at)
);

-- 일별 통계 스냅샷 (배치 집계 결과 캐시)
CREATE TABLE IF NOT EXISTS daily_stats (
    stats_date              DATE   PRIMARY KEY,
    new_members             INT    DEFAULT 0,
    active_members          INT    DEFAULT 0,
    total_reservations      INT    DEFAULT 0,
    confirmed_reservations  INT    DEFAULT 0,
    cancelled_reservations  INT    DEFAULT 0,
    total_sales             BIGINT DEFAULT 0,
    total_refunds           BIGINT DEFAULT 0,
    new_performances        INT    DEFAULT 0,
    created_at              DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 공연별 판매 통계 스냅샷
CREATE TABLE IF NOT EXISTS performance_stats (
    performance_id  BIGINT         PRIMARY KEY,
    total_seats     INT            DEFAULT 0,
    sold_seats      INT            DEFAULT 0,
    reserved_seats  INT            DEFAULT 0,
    cancelled_seats INT            DEFAULT 0,
    total_revenue   BIGINT         DEFAULT 0,
    avg_rating      DECIMAL(3,2)   DEFAULT 0.00,
    review_count    INT            DEFAULT 0,
    view_count      INT            DEFAULT 0,
    updated_at      DATETIME       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 어드민 전체 행위 감사 로그
CREATE TABLE IF NOT EXISTS admin_action_log (
    log_id          BIGINT       PRIMARY KEY AUTO_INCREMENT,
    admin_member_id BIGINT       NOT NULL,
    action_type     VARCHAR(60)  NOT NULL,  -- MEMBER_STATUS_CHANGE, PERFORMANCE_APPROVE 등
    target_type     VARCHAR(50),            -- MEMBER, PERFORMANCE, PROMOTER 등
    target_id       BIGINT,
    before_value    TEXT,
    after_value     TEXT,
    ip_address      VARCHAR(45),
    created_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_aal_admin (admin_member_id),
    INDEX idx_aal_created (created_at),
    INDEX idx_aal_target (target_type, target_id)
);

-- 대기열 영속화 (Redis 장애 시 복구용)
CREATE TABLE IF NOT EXISTS queue_token (
    token_id       BIGINT       PRIMARY KEY AUTO_INCREMENT,
    token_key      VARCHAR(100) NOT NULL UNIQUE,
    member_id      BIGINT       NOT NULL,
    performance_id BIGINT       NOT NULL,
    queue_position INT,
    status         VARCHAR(20)  DEFAULT 'WAITING', -- WAITING, ACTIVE, EXPIRED, USED
    issued_at      DATETIME     DEFAULT CURRENT_TIMESTAMP,
    expires_at     DATETIME,
    activated_at   DATETIME,
    INDEX idx_qt_member_perf (member_id, performance_id),
    INDEX idx_qt_expires (expires_at)
);

-- 장애인석 관리
CREATE TABLE IF NOT EXISTS accessible_seat (
    accessible_id   BIGINT      PRIMARY KEY AUTO_INCREMENT,
    seat_id         BIGINT      NOT NULL UNIQUE,
    accessible_type VARCHAR(30) NOT NULL,  -- WHEELCHAIR, COMPANION, LOW_VISION
    companion_count TINYINT     DEFAULT 1,
    note            VARCHAR(200),
    is_active       BOOLEAN     DEFAULT TRUE
);

-- 기본 환불 정책 데이터 (티켓팅 업계 표준)
INSERT IGNORE INTO refund_policy (performance_id, days_before_show, refund_rate, description) VALUES
(NULL, 10, 100, '관람일 10일 전 이전: 100% 환불'),
(NULL, 9,  90,  '관람일 9일 전: 90% 환불'),
(NULL, 7,  80,  '관람일 7일 전: 80% 환불'),
(NULL, 3,  70,  '관람일 3일 전: 70% 환불'),
(NULL, 1,  0,   '관람일 전날 이후: 환불 불가');
