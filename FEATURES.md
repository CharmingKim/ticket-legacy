# TicketLegacy — 구현 기능 전체 목록

> 소스코드 기준 실제 구현 확인 (2026-05-07)  
> DB 테이블: 45개 설계 / 28개 실제 사용 / Mapper XML 27개 (ticket-common 공유)

---

## ticket-user (port 8080) — 일반 사용자 포털

### 공연 탐색
- 메인 페이지: TOP 5 랭킹 + 최신 12개 공연
- 공연 목록 다중 필터: 장르 / 상태 / 키워드 / 날짜 범위 / 가격 범위 / 정렬
- 공연 상세: 스케줄 목록, 좌석 등급별 가격, 리뷰/평점

### 좌석 선택 & 예매 (Dual-Defense 동시성 제어)
- 인터랙티브 좌석 지도 — 실시간 상태 표시 (AVAILABLE / HELD / MY_HOLD / RESERVED)
- **1차 방어**: Redis Lua 스크립트 원자적 SETNX (TTL 10분)
- **2차 방어**: DB `WHERE status='AVAILABLE'` 조건부 UPDATE (Redis 장애 대비)
- 개인별 좌석 선점 수 제한
- 만료 좌석 자동 해제 (`@Scheduled` 배치)

### 대기열 (Redis Sorted Set)
- 스케줄당 최대 500명 동시 접속 관리
- `@Scheduled(3초)` 자동 처리 — 대기 → 통과
- 현재 위치 + 예상 대기 시간 실시간 표시
- Redis 장애 시 graceful degradation (대기열 우회)

### 결제
- 멱등성 키(idempotency_key) — 중복 결제 원천 방지
- 쿠폰 할인 적용 + 최종 금액 계산
- PG 연동 시뮬레이션 (pg_transaction_id 생성)
- 결제 실패 시 고아 PENDING 예약 자동 정리

### 환불 (날짜 기반 수수료 계산)
- 10일 전: 전액 환불
- 7~9일 전: 10% 수수료
- 3~6일 전: 20% 수수료
- 1~2일 전: 30% 수수료
- 당일 이후: 환불 불가
- 쿠폰 사용 결제 전액 환불 시 쿠폰 자동 복구

### 회원
- 회원가입 / 로그인 / 로그아웃 (JWT HS256, BCrypt)
- 프로필 수정 (이름 / 전화번호)
- 비밀번호 변경 (변경 후 자동 로그아웃)
- 회원 탈퇴 (사유 기록, 상태: DELETED)
- 마이페이지: 예매 통계, 보유 쿠폰, 최근 활동

### 쿠폰
- 보유 쿠폰 목록 조회
- 쿠폰 코드 유효성 검증 + 할인 금액 계산

### 위시리스트
- 공연 위시리스트 등록/해제 (토글)
- 위시리스트 목록 조회

### 취소 대기 (Waitlist)
- 매진 공연 취소 대기 등록/해제
- 대기 목록 조회

### 리뷰
- 공연 리뷰 작성 (1~5점 평점 + 내용)
- 리뷰 수정/삭제 (본인 확인)
- 평균 평점 계산 및 표시

### 고객 지원
- 공지사항 목록/상세 (역할별 필터링: USER/ALL)
- 1:1 문의 작성/조회/삭제
- FAQ 조회
- 디지털 티켓 조회 (CONFIRMED 상태 예매만)

---

## ticket-partner (port 8081) — 파트너 포털

### 기획사 (PROMOTER)
- 대시보드: KPI (공연 수, 매출, 정산 현황, 최근 공연)
- **공연 등록 워크플로우**:
  1. 공연 초안 생성 (제목/장르/공연장/설명/포스터/날짜)
  2. 스케줄 추가/삭제 (날짜, 시간)
  3. 좌석 등급 설정 (구역별 등급명, 가격)
  4. 구역 오버라이드 (커스텀 행수/좌석수)
  5. 좌석 생성/삭제 (공연장 템플릿 기반 일괄 생성)
  6. 관리자 심사 요청 (DRAFT → SUBMITTED)
- 판매 리포트: 공연별 판매 데이터 조회
- 정산 조회: 연월 선택 정산 내역
- 공지사항 조회 (PROMOTER/ALL 역할)
- 쿠폰 템플릿 조회

### 공연장 담당자 (VENUE_MANAGER)
- 대시보드: 예정 공연 스케줄 요약
- **공연장 정보 관리**:
  - 구역 추가/삭제 (이름, 타입, 행수, 좌석수)
  - 좌석 템플릿 재생성
  - 스테이지 구성 생성/삭제
  - 스테이지 구역 매핑 (커스텀 행수/좌석수 오버라이드)
- 스케줄 달력: 월별 공연 일정 조회
- **입장 관리 (체크인)**:
  - 날짜/키워드로 체크인 대상 검색
  - 예매 번호 기반 입장 처리 + 메모 기록
  - entrance_log 기록

---

## ticket-admin (port 8082) — 백오피스

### SUPER_ADMIN
- 대시보드: 전체 현황 (보류 승인 수, 공연 수, 회원 수, 최근 예매)
- 통계: 시스템 전체 KPI
- **회원 관리**: 검색 (이름/이메일/상태) + 상태 변경 (ACTIVE/SUSPENDED/DELETED)
- **기획사 관리**: 목록 / 승인 / 반려(사유) / 정지 (FSM)
- **공연장 담당자 관리**: 목록 / 승인 / 반려 (FSM)
- **공연 심사 워크플로우**:
  - 심사 대기 목록 조회 (스케줄/좌석등급 포함 상세 조회)
  - 승인 (SUBMITTED → APPROVED, 메모)
  - 반려 (사유 기록)
  - 게시 (APPROVED → ON_SALE)
  - 초안 롤백 (DRAFT 복귀)
- **공연장 마스터 관리**: 공연장 생성 / 구역 추가/삭제 / 좌석 템플릿 생성
- **스테이지 구성 관리**: 생성/삭제 / 구역 매핑
- **좌석 인벤토리 관리**: 생성/삭제 / hold_type 일괄 변경 (RESERVED/VIP/STAFF)
- **정산 관리**: 기획사별/연월별 정산 조회

### STAFF
- 대시보드: 시스템 요약 + 최근 예매
- 예매 검색: 키워드/상태 필터 + 상세 조회
- 회원 검색: 이름/이메일 검색
- 예매 강제 취소 (운영자 권한)

---

## ticket-common — 공유 라이브러리

### 공유 규모
- Mapper XML: **27개** (3개 WAR 모두 공유)
- Service 클래스: **15개** (단일 소스로 3개 포털 동작)
- 도메인 클래스: **20개+**
- ErrorCode enum: **40개+** (비즈니스 예외 코드)

### JWT 인증 구조
- JwtUtil: HS256, `JWT_SECRET_KEY` 환경변수 우선 적용 → fallback 랜덤 키
- 포털별 쿠키 분리: `USER_TOKEN` / `PARTNER_TOKEN` / `ADMIN_TOKEN`
  - 동일 localhost에서 쿠키 덮어쓰기 방지
- 역할 기반 접근 제어 (security-context.xml per WAR)
- `RateLimitInterceptor`: POST 요청 30회/분 제한 (/api/**)

### FSM 도메인 (잘못된 상태 전이 원천 차단)
| 도메인 | 상태 전이 |
|---|---|
| Performance | DRAFT → SUBMITTED → APPROVED/REJECTED, APPROVED → ON_SALE, 롤백 지원 |
| Member | ACTIVE → SUSPENDED → DELETED |
| Promoter | PENDING → APPROVED/REJECTED, APPROVED → SUSPENDED |
| VenueManager | PENDING → APPROVED/REJECTED |

### Request / Response 공통 구조
- `ApiResponse<T>`: 제네릭 응답 래퍼 (success / message / data)
- `PageResponse<T>`: 페이지네이션 응답
- `BusinessException` + `ErrorCode`: 전역 예외 처리

---

## 미구현 — 스키마만 존재 (17개 테이블)

| 테이블 | 용도 | 비고 |
|---|---|---|
| accessible_seat | 장애인 좌석 | - |
| admin_action_log | 어드민 행동 로그 | - |
| daily_stats | 일별 통계 | - |
| performance_stats | 공연 통계 | - |
| member_terms_agreement | 약관 동의 이력 | - |
| notification | 알림 | - |
| notification_template | 알림 템플릿 | - |
| point_balance | 포인트 잔액 | - |
| point_history | 포인트 이력 | - |
| queue_token | 대기열 토큰 | 기능은 Redis Sorted Set으로 구현 |
| refund | 환불 상세 이력 | 환불 로직은 payment 테이블로 처리 |
| refund_policy | 환불 정책 | 로직은 PaymentService에 하드코딩 |
| review_report | 리뷰 신고 | - |
| search_keyword_log | 검색어 로그 | - |
| settlement | 정산 | 조회는 PortalQueryMapper로 처리 |
| settlement_item | 정산 항목 | 동일 |
| terms | 약관 | - |

---

## 기술 하이라이트 요약

| 기술 | 구현 내용 |
|---|---|
| **Dual-Defense 동시성** | Redis Lua 원자 선점 + DB 조건부 UPDATE 이중 방어 |
| **Queue System** | Redis Sorted Set, @Scheduled 3초 처리, 500명 동시 제한 |
| **Payment 멱등성** | idempotency_key UNIQUE 제약으로 중복 결제 방지 |
| **날짜 기반 환불** | 관람일 D-10/7/3/1 기준 0%~100% 수수료 계산 |
| **쿠폰 복구** | 전액 환불 시 사용 쿠폰 자동 복원 |
| **FSM** | 4개 도메인 상태 전이 강제 (잘못된 전이 시 예외) |
| **3-WAR JWT 공유** | 동일 SECRET_KEY + 포털별 쿠키 분리 |
| **Redis Graceful Degradation** | Redis 장애 시 DB-only 모드 자동 강등 |
| **AWS 배포** | EC2 t3.micro + RDS MySQL + Docker Compose (2GB swap) |
| **Elasticsearch** | PerformanceSearchService (연결 가능 시 키워드 검색) |
