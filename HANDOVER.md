# TicketLegacy — 인수인계 문서

> 최신 업데이트: 2026-05-01 (10차 세션 — Phase A 테스트 2항목 통과, 회원 상태 드롭다운 FSM 적용)
> 목적: 다음 세션이 현재 상태·미해결 이슈·실행 절차를 빠르게 파악

## 🎯 작업 자세 (Claude 가 코드 짤 때의 마인드셋)

**대기업 시니어 개발자처럼 개발한다.** 토이 포트폴리오 수준이 아니라 실제 운영되는 엔터프라이즈 서비스 기준으로:

- 컨벤션을 무비판적으로 따르지 말 것 — 기존 패턴이 어색하면 짚고 개선안 제시 (예: 화면 데이터를 `model.addAttribute` 6개로 흩뿌리지 말고 ViewModel/PageDTO 로 응집)
- 도메인-매퍼-JSP 정합성을 항상 의식 (필드명·타입·null 처리)
- 트랜잭션 경계, 동시성, 멱등성, 보안(JWT/CSRF/XSS/SQLi) 을 모든 변경에서 점검
- "동작하면 끝" 이 아니라 "운영에서 안 터지는가" 기준 — 데이터 0건/대량/경계값/장애 시나리오 고려
- 변명·우회 금지. 하드코딩, mock, 임시 fetch 우회 등은 발견 즉시 HANDOVER §10 에 기록
- 사용자가 묻기 전에 잠재 위험 (다음 단계에서 터질 가능성) 을 사전 경고

이 원칙은 모든 파일 수정·리뷰·설계 결정에 적용된다.

---

## 🚀 다음 세션 시작 가이드 (여기부터 읽기)

**직전 세션(8차)에서 한 것**
- **Phase A (인프라)**: MemberStatus FSM, ApiResponse 개선, PageResponse, GlobalExceptionHandler 3-WAR 동기화
- **Phase B1 (Member 봉인)**: MemberSearchQuery/MemberStatusCommand/MemberSummaryDto + FSM validateTransition + 컨트롤러 완전 typed

**직전 세션(9차)에서 한 것**
- **Phase B2 (Promoter 봉인)**: PromoterApprovalStatus FSM enum, RegisterPromoterCommand, PromoterRejectCommand, PromoterSearchQuery, PromoterSummaryDto 신규 + PromoterService 완전 재작성 (typed + FSM) + 컨트롤러 완전 typed + dashboardPromoters/settlementPage DTO화

**직전 세션(9차)에서도 한 것 (이어서)**
- **Phase B3 (VenueManager 봉인)**: VenueManagerApprovalStatus FSM, RegisterVenueManagerCommand, VenueManagerSearchQuery, VenueManagerSummaryDto + VenueManagerMapper findAll/countAll 추가 + VenueManagerService 완전 재작성 + 컨트롤러 완전 typed

**직전 세션(9차)에서도 한 것 (이어서)**
- **Phase B4 (Performance 봉인)**: PerformanceApprovalStatus FSM enum, PerformanceReviewCommand, PerformanceSearchQuery, PerformanceSummaryDto + PerformanceApprovalService FSM 적용 + 컨트롤러 완전 typed + dashboard.js 응답 구조 수정(`list`→`data.content`)

**직전 세션(10차)에서 한 것**
- **Phase A 테스트 전항목 통과 (3/3) ✅ 완전 봉인**
- **Phase B1 회원목록/검색/JSON보안/SUSPENDED·WITHDRAWN FSM 테스트 통과** — DORMANT 2개 항목만 잔여: `ApiResponse { success, message, data, errorCode }` 구조 확인 ✅ / `GlobalExceptionHandler` 잘못된 JSON → 400 확인 ✅ / 존재하지 않는 memberId 상태변경 → 404 `MBR_001` 확인 ✅ — **Phase A 완전 봉인**
- **JSP EL 버그 수정** (`member-list.jsp`): JS 템플릿 리터럴 `${item.name}` 등을 JSP EL이 서버사이드에서 `"false"` 로 치환하는 문제 → 문자열 연결(`+`)로 전면 교체. `loadVenueOptions()` 동일 수정.
- **회원 상태 드롭다운 FSM 적용** (`member-list.jsp`, `member-search.jsp`): 현재 상태 기반 유효 전환만 노출 (DORMANT 제거 — 시스템 자동 전환 전용), WITHDRAWN 시 SweetAlert 확인 다이얼로그 추가, WITHDRAWN 회원은 "변경 불가" 텍스트로 표시

**다음 세션 시작 순서**
1. **Phase A 나머지**: 존재하지 않는 회원 ID 상태변경 → 404 확인 (F12 Console fetch로 30초)
2. **Phase B1 이어서 테스트**: 회원 목록 렌더링·검색·FSM 항목들
3. **Phase 2 어드민 기능 완성** — 통계 NPE 방어, 회원 상세 조회 모달
2. **Phase 3 파트너** — 좌석등급 설정 UI
3. **Phase 4 유저** — 쿠폰 적용 UI, 공연 검색/필터

**즉시 실행 체크리스트**
```bash
# 1. MySQL 8 기동 확인
mysql -uroot -p1234 springgreen6 -e "SELECT 1"

# 2. Redis 기동 확인 (ticket-user 필수)
redis-cli ping    # → PONG

# 3. 3개 WAR 기동 (각각 별도 터미널)
mvn tomcat7:run -pl ticket-user    -am    # :8080
mvn tomcat7:run -pl ticket-partner -am    # :8081
mvn tomcat7:run -pl ticket-admin   -am    # :8082
```

---

---

## 1. 아키텍처 한 눈에

Maven 멀티모듈 / 단일 DB(`springgreen6`) / 3-WAR.

| 모듈 | 포트 | 역할 | 테스트 계정 (비번 `Cks159753!`) |
|---|---|---|---|
| `ticket-user` | 8080 | 일반 회원 (공연/좌석/결제) | `user1@test.com` (user2·3도 동일) |
| `ticket-partner` | 8081 | 기획사, 공연장 담당 | `promoter1@test.com` (APPROVED) / `venue1@test.com` |
| `ticket-admin` | 8082 | 슈퍼어드민, 스태프 | `admin@ticketlegacy.com` / `staff@ticketlegacy.com` |
| `ticket-common` | (jar) | 도메인·서비스·매퍼 공유 | — |

> `promoter2@test.com` 은 PENDING 상태로 시드돼 있어 어드민 승인 플로우 검증용으로 사용.

**핵심 제약**: Spring MVC 5.3 (Boot 아님), Java 11, `javax.*` 필수, MyBatis 3.5, JSP + Tiles 3, JJWT 0.11.5.

**인프라 선조건**
- MySQL 8, 스키마 `springgreen6`, 계정 root/1234 (root-context.xml에 하드코딩)
- Redis localhost:6379 — **ticket-user 필수**, admin/partner 미사용
- 환경변수 `JWT_SECRET_KEY` (Base64) — 3개 WAR 동일 값

---

## 2. 실행

```bash
# 전체 빌드
mvn clean package -pl ticket-common,ticket-user,ticket-partner,ticket-admin -am

# 개별 실행 (각 터미널)
mvn tomcat7:run -pl ticket-user -am
mvn tomcat7:run -pl ticket-partner -am
mvn tomcat7:run -pl ticket-admin -am
```

**STS 사용 시**: Tomcat 9 + `testEnvironment="true"` 격리 배포. 소스 변경 후:
```bash
bash deploy-sync.sh [user|partner|admin|all]   # JSP/CSS/JS 즉시 반영
# Java 변경 시 → 해당 서버 Restart 필수
```

---

## 3. 인증·URL 매핑

### 로그인 API (전 포털 정규화 완료)

| 포털 | 로그인 | 회원가입 | 로그아웃 |
|---|---|---|---|
| user | `POST /api/member/login` | `POST /api/member/join` | `POST /api/member/logout` |
| partner | `POST /partner/api/login` | 없음 (어드민이 생성) | `POST /partner/api/logout` |
| admin | `POST /admin/api/login` | 없음 | `POST /admin/api/logout` |

### 접근 제어

- JWT HttpOnly 쿠키 · 2시간 만료 — 포털별 쿠키명: `USER_TOKEN` / `PARTNER_TOKEN` / `ADMIN_TOKEN`
- `JwtAuthenticationFilter` — 쿠키 파싱 → SecurityContext 설정
- 각 포털 `security-context.xml`에서 역할 기반 차단
  - `/backoffice/super/**` → SUPER_ADMIN
  - `/backoffice/staff/**` → SUPER_ADMIN + STAFF
  - `/partner/promoter/**` → PROMOTER
  - `/partner/venue/**` → VENUE_MANAGER

### 역할·가입 경로

| Role | 생성 방법 |
|---|---|
| `MEMBER` | `/member/join` 자가 가입 |
| `PROMOTER` / `VENUE_MANAGER` | SUPER_ADMIN이 어드민에서 생성 + 승인 |
| `STAFF` | SUPER_ADMIN 직접 생성 |
| `SUPER_ADMIN` | DB 시드 |

---

## 4. 3차 세션에서 추가된 내용 (2026-04-20, 3차)

### DB 전체 스키마 + 시드 구축

| 항목 | 파일 | 내용 |
|---|---|---|
| **`db/init.sql` 신설** | `db/init.sql` | 21개 테이블 DDL + FK 순서 반영 시드. 재실행 안전 (DROP + 재생성). MySQL 8 에서 실제 실행 검증 완료. |
| **시드 계정 8개** | `db/init.sql` (member INSERT) | SUPER_ADMIN · STAFF · USER×3 · PROMOTER×2(1 APPROVED, 1 PENDING) · VENUE_MANAGER. 공통 비번 `Cks159753!` (BCrypt `$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO`) |
| **시드 공연 4건** | `db/init.sql` | PUBLISHED+ON_SALE×2 (IU·라이온킹) / REVIEW×1 (BTS) / APPROVED×1 (백조의 호수, publish 대기). 각 단계별 E2E 입력값 역할. |
| **좌석/인벤토리 612행** | `db/init.sql` | venue_section 의 total_rows×seats_per_row 를 recursive CTE 로 전개 → seat_inventory 전부 AVAILABLE. 샘플 예매 1건(VIP A1·A2 RESERVED + payment COMPLETED) 포함. |
| **섹션 5 E2E 절차 재작성** | `HANDOVER.md` | 시드 기반 D→C→A→B 순서로 단축. 각 단계 데이터 준비 없이 즉시 실행 가능. |

### 2차 세션 — 어드민 백오피스 (유지)

| 항목 | 파일 | 원인 / 조치 |
|---|---|---|
| **어드민 대시보드 API 6개 추가** | `BackofficeSuperController.java` | JSP는 `/api/dashboard/summary` 등을 호출했으나 엔드포인트 없음 → 6개 신규 추가 (summary, promoters, venue-managers, review-performances, venues, recent-reservations) |
| **대시보드 JSP 필드명 정합** | `backoffice/super/dashboard.jsp` | `p.status`→`approvalStatus`, `v.venueManagerId`→`managerId`, `p.representativeName`→`representative` 등 도메인 실제 필드에 맞춤 |
| **PROMOTER/VM 생성 API + UI** | `BackofficeSuperController.java`, `member-list.jsp` | `POST /api/promoters`, `POST /api/venue-managers` 엔드포인트 신규 + `member-list.jsp`에 생성 모달 2개 추가. `promoterService.registerPromoter()` / `venueManagerService.registerVenueManager()` 재사용 |

### 1차 세션 내용 (유지)

## 4b. 1차 세션에서 수정된 내용 (2026-04-20)

| 항목 | 파일 | 원인 |
|---|---|---|
| **ticket-user 회원가입 차단** | `ticket-user/.../security-context.xml` | permitAll URL이 옛 경로(`/member/api/join`). 새 경로(`/api/member/join`)로 교체 |
| **Jackson LocalDateTime 직렬화** | 3개 `root-context.xml` | `WRITE_DATES_AS_TIMESTAMPS=false` 추가 → 배열 `[2026,4,20,...]` → ISO 문자열. JSP의 `fmtDate`/`fmtDt` 배열 처리 우회 로직은 이제 불필요 (향후 정리 가능) |
| **공연 상태 표시 (UPCOMING/ENDED)** | `ticket-user/.../performance/detail.jsp` | 판매 전 공연이 "매진"으로 보이던 문제. `performance.status`별로 `오픈 예정` / `공연 종료` / `매진` 분기 + 클릭 차단 메시지 |
| **NoticeService.findById 트랜잭션** | `ticket-common/.../NoticeService.java` | SELECT + UPDATE(view count) 를 `@Transactional`로 묶음 |

**트랜잭션 인프라 점검 결과**: 3개 WAR 모두 `tx:annotation-driven` 구성됨. 주요 서비스(MemberService, PromoterService, ReservationService, PaymentService, CouponService, VenueAdminService, NoticeService, AdminPerformanceService 등) 변경 메서드에 `@Transactional` 부여됨. 추가 적용 필요시 본 섹션 참고.

---

## 5. 미해결 이슈 (우선순위)

> E2E 전 구간(공연 등록 → 승인 → 게시 → 결제) 7차 세션에서 검증 완료. 아래는 기능 미완성 / 코드 품질 이슈.

### ✅ 코드 설계 정리 완료 (7차 세션)

- **Mapper 직접 주입 제거**: `BackofficeSuperController` Mapper 9개 → 전부 Service 계층으로 이전. `BackofficeStaffController` Mapper 2개도 동일 처리.
- **서비스 계층 메서드 추가**: `MemberService.findAll/countFiltered/updateAdminStatus`, `VenueAdminService.findStageConfigs/createStageConfig/deleteStageConfig/findStageSections/upsertStageSection`, `AdminPerformanceService.findSchedulesByPerformanceId/createSchedule/findSectionOverrides`, `ReservationService.searchReservations/countReservations`, `PortalDashboardService.getSettlementSummary/toLong` 
- **Payment 도메인**: `id`/`method`/`failReason` 이미 정합 완료. 추가 조치 불필요.
- **MemberRole enum**: `STAFF`, `SUPER_ADMIN`, `PROMOTER`, `VENUE_MANAGER` 추가 완료.

### 🟡 기능 미완성

- **공연 공개(publish) UI 없음**: API(`POST /api/performances/{id}/publish`)는 있음. 어드민 대시보드 "공연 심사" 탭에 APPROVED 공연 대상 Publish 버튼 없음.
- **어드민 공연 승인 전 미리보기 없음**: 일정·좌석·가격 확인 없이 승인/반려만 가능. 상세 모달 필요.
- **파트너 좌석등급 UI 없음**: `performance-list.jsp`에 등급 설정 버튼 없음 (API는 존재).
- **통계 API NPE**: 데이터 0건 시 `/backoffice/super/api/analytics/all` — null 방어 없음.

### 🔵 개선 포인트

- **파트너 계정 생성 모달**: admin `member-list.jsp`에 기획사/공연장담당자 생성 UI 이미 구현됨 (API + Modal 모두 있음).
- **DateUtil 중복**: `ticket-common`, `ticket-user` 양쪽 존재. `ticket-user` 쪽 제거 후 common 사용.
- **MemberRole enum dead code**: `enum { USER, ADMIN }` — 실제 역할(`SUPER_ADMIN`, `STAFF`, `PROMOTER`, `VENUE_MANAGER`)과 불일치.
- **결제 게이트웨이 mock**: `PaymentService.simulatePgPayment()` 항상 true — 실제 PG 연동 필요.

### 🟢 기능 확장 (Phase 4~5)

- user: 공연 검색/필터 (카테고리·날짜·가격대), 쿠폰 적용 UI, 환불 플로우
- partner: 판매 리포트 차트, QR 스캔 입장
- admin: 회원 상세 조회, 강제탈퇴(예매 일괄취소), 환불 처리

---

## 6. 모듈 요약

### ticket-user (8080)

Controller: MemberController, PerformanceController, SeatController, ReservationController, PaymentController, QueueController
전용 서비스: PerformanceService, SeatService(Redis 좌석 락), QueueService(@Scheduled 3s), PaymentService
전용 인터셉터: AuthInterceptor, RateLimitInterceptor(30 req/min), QueueInterceptor

### ticket-partner (8081)

Controller: PartnerLoginController, PartnerPromoterController, PartnerVenueController, PartnerCouponController
전용 서비스: VenueManagerService, EntranceService

### ticket-admin (8082)

Controller: AdminLoginController, BackofficeSuperController, BackofficeStaffController, BackofficeCouponController, BackofficeAnalyticsController, BackofficeSuperAnalyticsController

### ticket-common

- 도메인 20개 (Member/Performance/Schedule/Seat/SeatInventory/Reservation/ReservationSeat/Payment/Coupon/CouponTemplate/Promoter/VenueManager/Venue 등)
- 서비스 11개 (MemberService, ReservationService, CouponService, PromoterService, VenueAdminService, VenueManagerService, EntranceService, NoticeService, PerformanceApprovalService, AdminPerformanceService, PortalDashboardService)
- 매퍼 인터페이스 21개 + MyBatis XML 18개

---

## 7. 주요 워크플로우

**공연 승인**: DRAFT → REVIEW → APPROVED / REJECTED → PUBLISHED

**좌석 예매 (Dual-Defense)**:
1. Redis Lua 스크립트로 원자적 선점 (HOLD 10분)
2. DB `WHERE status='AVAILABLE'` 낙관적 락
3. Payment에 `idempotency_key UNIQUE` 중복 결제 차단
4. Redis 장애 시 DB-only 모드로 강등 (graceful)

**예매 상태**: PENDING(선점) → CONFIRMED(결제완료) → CANCELLED / REFUNDED

---

## 8. 파일 위치 빠른 참조

| 목적 | 경로 |
|---|---|
| 도메인 | `ticket-common/src/main/java/com/ticketlegacy/domain/` |
| 서비스 | `ticket-common/src/main/java/com/ticketlegacy/service/` |
| 매퍼 XML | `ticket-common/src/main/resources/mybatis/mapper/` |
| JWT 필터 | `ticket-*/src/main/java/.../web/filter/JwtAuthenticationFilter.java` |
| 시큐리티 | `ticket-*/src/main/webapp/WEB-INF/spring/security-context.xml` |
| MVC | `ticket-*/src/main/webapp/WEB-INF/spring/servlet-context.xml` |
| DB·MyBatis | `ticket-*/src/main/webapp/WEB-INF/spring/root-context.xml` |
| Tiles | `ticket-*/src/main/webapp/WEB-INF/tiles/tiles-config.xml` |
| 배포 스크립트 | `deploy-sync.sh` |
| **DB 스키마 + 시드** | **`db/init.sql`** |

---

## 9. 트러블슈팅

**포트 충돌**
```bash
netstat -ano | grep -E "8080|8081|8082"
taskkill /PID <pid> /F
```

**Redis 없이 ticket-user 기동 실패**
→ `root-context.xml`의 `LettuceConnectionFactory`는 연결 실패 시 예외. Redis 반드시 실행.

**MyBatis 중복 namespace 오류**
→ `mapperLocations`를 `classpath:` (star 없음)로. 이미 `classpath:mybatis/mapper/**/*.xml`로 설정됨.

**DB 초기화 / 시드 재주입**
```bash
mysql -uroot -p1234 < db/init.sql
```
→ `springgreen6` 스키마 DROP + 재생성 + 시드. 기존 데이터 전부 삭제되므로 개발 환경에서만 사용.

---

## 10. 3차 세션에서 발견된 코드 레벨 이슈 (운영 영향)

> 본 섹션의 이슈들은 `db/init.sql` 만들며 도메인 ↔ 매퍼 XML 대조 중 발견한 것. 스키마는 동작하는 매퍼 기준으로 만들었으나, 도메인 정리가 필요한 부분.

### 1) `Payment` 도메인 ↔ `PaymentMapper.xml` 컬럼명 불일치

- **도메인 필드**: `paymentId`, `idempotencyKey`, `method`, `failureReason`
- **매퍼 컬럼** : `id`, `idempotency_key`, (없음), `fail_reason`
- 매퍼 resultMap 은 `<id property="id" column="id" />` 로 매핑하지만, `Payment.java` 에 `id` 필드가 없어 **PK가 도메인에 영원히 안 채워짐**. `method` / `failureReason` 필드도 매퍼가 세팅하지 않음.
- 파일: `ticket-common/src/main/java/com/ticketlegacy/domain/Payment.java`, `ticket-user/src/main/resources/mybatis/mapper/PaymentMapper.xml`
- **조치 안**: Payment 도메인을 매퍼 컬럼에 맞춰 재정의하거나, 매퍼 resultMap 을 도메인에 맞춰 수정. 어느 쪽이든 깨진 필드(`method`, `failureReason`, `paymentId`) 사용처 없는지 grep 후 정리 필요.

### 2) `MemberRole` enum이 dead code

- `ticket-common/.../domain/enums/MemberRole.java` 는 `enum { USER, ADMIN }` 만 정의.
- 실제 코드(MemberService, PromoterService, VenueManagerService, security-context.xml)는 `SUPER_ADMIN`, `STAFF`, `PROMOTER`, `VENUE_MANAGER` 문자열을 직접 사용.
- **조치 안**: enum 을 실제 사용 값으로 확장하고 문자열 리터럴을 enum 참조로 교체. 또는 enum 삭제.

### 3) ~~`PromoterService.registerPromoter` 가 member.status 를 즉시 ACTIVE 로 세팅~~ ✅ 해결 (9차)

- 9차 세션에서 `registerPromoter(RegisterPromoterCommand)`로 재작성. member.status를 `PENDING_APPROVAL`로 초기화하고, `approvePromoter()` 시 `ACTIVE`로 전환하도록 수정.

---

## 11. 5차 세션 수정 내역 (2026-04-30)

| 항목 | 파일 | 내용 |
|---|---|---|
| **쿠키명 분리** | 3개 모듈 `JwtAuthenticationFilter.java`, 로그인/로그아웃 컨트롤러, `partner-layout.jsp` | `ACCESS_TOKEN` → `USER_TOKEN` / `ADMIN_TOKEN` / `PARTNER_TOKEN`. localhost 동일 도메인에서 쿠키 덮어쓰기 방지 |
| **cancelOrphan 추가** | `ReservationService.java`, `PaymentController.java` | memberId 소유권 검사 없는 시스템 취소 메서드. 결제 실패 후 PENDING 예약 누적 방지 |
| **쿠폰 ISSUED 필터** | `CouponMapper.xml` | `findByMemberId`에 `AND c.status = 'ISSUED' AND c.expires_at > NOW()` 추가 |
| **어드민 공연 탭** | `dashboard.jsp` | REVIEW+APPROVED 동시 표시, 게시(Publish) 버튼, 회원관리 Quick Link |
| **파트너 null 가드** | `PartnerPromoterController.java`, `PartnerVenueController.java` | `currentPromoterId()` / `currentVenueId()` null 시 BusinessException(AUTH_FORBIDDEN) |

**⚠️ 재시작 시 주의**: 쿠키명이 변경되었으므로 브라우저에서 **기존 `ACCESS_TOKEN` 쿠키를 수동 삭제** 후 재로그인해야 합니다. 개발자도구 → Application → Cookies → `localhost` → `ACCESS_TOKEN` 삭제.

### 4) 시드용 `INSERT … SELECT` 순서 함정 (참고용)

- `INSERT INTO seat … WITH RECURSIVE` 조합 시 `seat_id` 가 expected 순서로 부여된다는 보장 없음.
- `db/init.sql` 에서는 `ORDER BY` + reservation seed 의 seat_id 조회 기반 처리로 회피 중. 향후 시드 추가 시 동일 패턴 권장 (seat_id 하드코딩 금지).

---

## 12. 고도화 로드맵 (7차 세션 수립)

### ✅ Phase A — 인프라 기반 (8차 세션 완료)

- **`MemberStatus` FSM enum**: PENDING_APPROVAL/ACTIVE/SUSPENDED/DORMANT/WITHDRAWN + `canTransitionTo()` 전환 규칙 명시
- **`Member.password` @JsonIgnore**: 비밀번호 JSON 응답 노출 보안 이슈 수정
- **`ApiResponse<T>` 개선**: `successMessage()` 추가, `error(String)` errorCode "UNKNOWN"→INVALID_INPUT 수정, `ValidationError` 내부 클래스 추가
- **`PageResponse<T>` 신규**: 페이지네이션 표준 래퍼 (content/page/size/totalElements/totalPages/first/last)
- **`GlobalExceptionHandler` 3-WAR 동기화**: `HttpMessageNotReadableException`(JSON 파싱 오류→400), `MissingServletRequestParameterException`(필수 파라미터 누락→400) 핸들러 추가
- **`ErrorCode` 확장**: `MEMBER_STATUS_INVALID_TRANSITION`, `MEMBER_ALREADY_WITHDRAWN` 추가

### ✅ Phase B1 — Member 도메인 봉인 (8차 세션 완료)

**봉인 기준 달성: 이 도메인은 더 이상 구조 변경 없이 기능 추가만.**

| 항목 | 내용 |
|---|---|
| `MemberSearchQuery` | `@Valid @ModelAttribute` — role/status/keyword/page/size 타입 쿼리 |
| `MemberStatusCommand` | `@Valid @RequestBody` — `MemberStatus` enum + `@NotNull` |
| `MemberSummaryDto` | password 제외 안전한 응답 DTO, `MemberSummaryDto.from(Member)` static factory |
| `MemberService.searchMembers()` | `PageResponse<MemberSummaryDto>` 반환 — 타입 안전 |
| `MemberService.updateAdminStatus()` | FSM `canTransitionTo()` 검증 → WITHDRAWN 터미널 상태 방어 |
| 컨트롤러 | `BackofficeSuperController`, `BackofficeStaffController` 완전 typed — `Map<>` 없음 |
| JSP | `response.data.content` 구조 반영, SUSPENDED 상태 옵션 추가 |

**Member 상태 FSM:**
```
PENDING_APPROVAL → ACTIVE, SUSPENDED
ACTIVE           → SUSPENDED, WITHDRAWN, DORMANT
SUSPENDED        → ACTIVE, WITHDRAWN
DORMANT          → ACTIVE
WITHDRAWN        → (없음) — terminal
```

### ✅ Phase B2 — Promoter 도메인 봉인 (9차 세션 완료)

**봉인 기준 달성: 이 도메인은 더 이상 구조 변경 없이 기능 추가만.**

| 항목 | 내용 |
|---|---|
| `PromoterApprovalStatus` | FSM enum — PENDING/APPROVED/REJECTED/SUSPENDED + `canTransitionTo()` 전환 규칙 |
| `RegisterPromoterCommand` | `@NotBlank` email·password·name·companyName, `@Size(min=8)` password, `@Email` 검증 |
| `PromoterRejectCommand` | reason `@Size(max=500)` — optional이지만 크기 제한 |
| `PromoterSearchQuery` | status/page/size + `@Min`/`@Max` 범위 검증 |
| `PromoterSummaryDto` | 민감 정보 없는 안전한 응답 DTO, `PromoterSummaryDto.from(Promoter)` static factory |
| `PromoterService` | `registerPromoter(RegisterPromoterCommand)` 완전 typed. approve/reject/suspend 모두 FSM 검증 추가. `searchPromoters()` → `PageResponse<PromoterSummaryDto>`, `findApprovedSummaries()` 신규 |
| `ErrorCode.PRO_005` | `PROMOTER_STATUS_INVALID_TRANSITION` — 허용되지 않는 상태 전환 |
| 컨트롤러 | `listPromoters`, `createPromoter`, `approvePromoter`, `rejectPromoter`, `suspendPromoter` 완전 typed. `dashboardPromoters` → `List<PromoterSummaryDto>`. `settlementPage` → `findApprovedSummaries()` |

**Promoter 승인 FSM:**
```
PENDING   → APPROVED, REJECTED
APPROVED  → SUSPENDED, REJECTED
REJECTED  → (없음) — terminal
SUSPENDED → APPROVED, REJECTED
```

---

### ✅ Phase B3 — VenueManager 도메인 봉인 (9차 세션 완료)

**봉인 기준 달성: 이 도메인은 더 이상 구조 변경 없이 기능 추가만.**

| 항목 | 내용 |
|---|---|
| `VenueManagerApprovalStatus` | FSM enum — PENDING/APPROVED/REJECTED + `canTransitionTo()` |
| `RegisterVenueManagerCommand` | `@NotBlank` email·password·name, `@NotNull` venueId, `@Size(min=8)` password |
| `VenueManagerSearchQuery` | status/page/size + `@Min`/`@Max` |
| `VenueManagerSummaryDto` | 안전한 응답 DTO, `from(VenueManager)` static factory |
| `VenueManagerMapper` | `findAll`/`countAll` 추가 (상태 무관 전체 조회 지원) |
| `VenueManagerService` | `registerVenueManager(Command)` typed, approve/reject FSM 검증, `searchVenueManagers()` → `PageResponse<VenueManagerSummaryDto>` |
| `ErrorCode.VM_005` | `VENUE_MANAGER_STATUS_INVALID_TRANSITION` 추가 |
| 컨트롤러 | `listVenueManagers`, `createVenueManager`, `approveVenueManager`, `rejectVenueManager` 완전 typed. `dashboardVenueManagers` → `List<VenueManagerSummaryDto>` |

**VenueManager 승인 FSM:**
```
PENDING  → APPROVED, REJECTED
APPROVED → REJECTED
REJECTED → (없음) — terminal
```

---

### ✅ Phase B4 — Performance 도메인 봉인 (9차 세션 완료)

**봉인 기준 달성: 이 도메인은 더 이상 구조 변경 없이 기능 추가만.**

| 항목 | 내용 |
|---|---|
| `PerformanceApprovalStatus` | FSM enum — DRAFT/REVIEW/APPROVED/REJECTED/PUBLISHED |
| `PerformanceReviewCommand` | note `@Size(max=1000)` — approve/reject 공통 |
| `PerformanceSearchQuery` | approvalStatus/page/size + `@Min`/`@Max` |
| `PerformanceSummaryDto` | 안전한 응답 DTO, `from(Performance)` static factory |
| `PerformanceApprovalService` | 모든 상태 전환 FSM `validateTransition()` 적용. `searchPerformances()` → `PageResponse<PerformanceSummaryDto>` |
| `ErrorCode.PERF_006` | `PERFORMANCE_STATUS_INVALID_TRANSITION` 추가 |
| 컨트롤러 | `listPerformances`, `approvePerformance`, `rejectPerformance`, `publishPerformance`, `rollbackToDraft` 완전 typed |
| `dashboard.jsp` | `reviewResp[0].list` → `reviewResp[0].data.content` 수정 |

**Performance 승인 FSM:**
```
DRAFT     → REVIEW
REVIEW    → APPROVED, REJECTED
APPROVED  → PUBLISHED, DRAFT (관리자 롤백)
REJECTED  → REVIEW, DRAFT (관리자 롤백)
PUBLISHED → (없음) — terminal
```

---

### ✅ Phase 1 — 코드 설계 정리 (7차 세션 완료)

**목표**: Mapper 직접 주입 제거 + 비즈니스 로직 서비스 계층으로 이동

| 작업 | 대상 파일 | 내용 |
|---|---|---|
| VenueAdminService 메서드 추가 | `ticket-common/.../VenueAdminService.java` | `createStageConfig()`, `upsertStageSection()` — 컨트롤러에서 꺼냄 |
| AdminPerformanceService 메서드 추가 | `ticket-common/.../AdminPerformanceService.java` | `createSchedule()`, `savePerformanceSectionOverride()` 트랜잭션 래핑 |
| MemberService.updateStatus() 추가 | `ticket-common/.../MemberService.java` | `@Transactional` + 감사 이력. admin/staff 양쪽에서 사용 |
| 정산 집계 서비스 이동 | `PortalDashboardService` or 신규 `SettlementService` | `listSettlements()` 집계 로직 + `toLong/toInt` 헬퍼 이동 |
| 컨트롤러 Mapper 주입 제거 | `BackofficeSuperController.java`, `BackofficeStaffController.java` | 위 서비스 메서드 사용으로 교체 후 9개 Mapper `@Autowired` 제거 |
| Payment 도메인 정합 | `ticket-common/.../domain/Payment.java` | `paymentId`→`id`, `method`, `failureReason` 필드·getter 매퍼와 일치 |
| MemberRole enum 확장 | `ticket-common/.../domain/enums/MemberRole.java` | `SUPER_ADMIN`, `STAFF`, `PROMOTER`, `VENUE_MANAGER` 추가 |

### Phase 2 — 어드민 기능 완성

| 작업 | 파일 | 내용 |
|---|---|---|
| Publish 버튼 UI | `super/dashboard.jsp` | APPROVED 공연 행에 "게시" 버튼 → `POST /backoffice/super/api/performances/{id}/publish` |
| 공연 승인 전 미리보기 | `super/dashboard.jsp` + API | 심사 탭에서 공연 클릭 시 일정·좌석·가격 모달 노출 |
| 통계 NPE 방어 | `BackofficeAnalyticsController.java` | 데이터 0건 시 빈 컬렉션 반환 (null 대신) |
| 회원 상세 조회 | `super/member-list.jsp` + API | 회원 행 클릭 → 예약 이력·쿠폰·정지 이력 모달 |
| 강제 탈퇴 | `MemberService.java` + 컨트롤러 | 예매 일괄취소 + 회원 WITHDRAWN 상태 전환 (동일 트랜잭션) |

### Phase 3 — 파트너 기능 완성

| 작업 | 파일 | 내용 |
|---|---|---|
| 좌석등급 설정 UI | `promoter/performance-list.jsp` | 공연 행에 "등급 설정" 버튼 → 모달에서 구역별 grade/price 입력 → `POST /api/performances/{id}/seat-grades` |
| 파트너 계정 생성 모달 | `super/member-list.jsp` | 어드민에서 기획사/공연장담당자 생성 (API 이미 있음, UI만 없음) |
| 판매 리포트 | `promoter/sales-report.jsp` | 회차별 판매율 차트 (Bar Chart), 등급별 매출 도넛 |

### Phase 4 — 유저 기능 강화

| 작업 | 파일 | 내용 |
|---|---|---|
| 공연 검색/필터 | `performance/list.jsp` + `PerformanceMapper.xml` | 카테고리·날짜·가격대 필터 + 키워드 검색 |
| 쿠폰 적용 UI | `reservation/payment.jsp` | 결제 화면에서 보유 쿠폰 선택 → 할인 금액 실시간 반영 |
| 환불 플로우 | `ReservationService.java` + JSP | 마이페이지에서 환불 신청 → REFUNDED 상태 전환 + seat_inventory AVAILABLE 복원 |

### Phase 5 — 코드 정리

| 작업 | 내용 |
|---|---|
| DateUtil 중복 제거 | `ticket-user` 쪽 DateUtil 삭제, `ticket-common` 참조로 통일 |
| JSP 날짜 헬퍼 정리 | `fmtDate`/`fmtDt` 배열 처리 분기 제거 (ISO 문자열로 통일된 상태) |
