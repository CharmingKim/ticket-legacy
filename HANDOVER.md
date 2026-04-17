# TicketLegacy — 인수인계 문서

> 작성 기준일: 2026-04-17  
> 작성 목적: 이후 세션(Opus 등 다른 모델)이 컨텍스트 없이도 즉시 작업을 이어갈 수 있도록 현재 상태, 완료 작업, 미해결 이슈, 확장 방향을 상세히 기술

---

## 1. 프로젝트 개요

**TicketLegacy**는 공연 좌석 예매 시스템으로, 하나의 Maven 멀티모듈 프로젝트(`ticket-parent`) 안에 세 개의 독립 웹 애플리케이션이 구성되어 있다.

| 모듈 | 포트 | 대상 사용자 | 역할 |
|---|---|---|---|
| `ticket-user` | 8080 | 일반 회원(MEMBER) | 공연 목록/상세, 좌석 선택, 결제, 예매 내역, 마이페이지 |
| `ticket-partner` | 8081 | 기획사(PROMOTER), 공연장관리자(VENUE_MANAGER) | 공연 등록/관리, 공연장 운영, 입장 처리, 정산 조회 |
| `ticket-admin` | 8082 | 슈퍼어드민(SUPER_ADMIN), 스태프(STAFF) | 회원/공연/정산/쿠폰/공지 전체 관리, 통계 |
| `ticket-common` | (lib) | 공통 | 도메인, 서비스, 레포지토리, 유틸 등 공유 코드 |

### 기술 스택

- **Backend**: Spring MVC 5.3, Spring Security 5.8, MyBatis 3.5
- **DB**: MySQL 8 — 스키마 `springgreen6` (3개 포털 공유 단일 DB)
- **캐시/락**: Redis (Lettuce) — 좌석 분산락, 대기열 관리
- **뷰**: JSP + JSTL + Apache Tiles 3
- **인증**: JWT (JJWT 0.11.5) — HttpOnly 쿠키, 2시간 만료
- **빌드**: Maven, Java 11
- **개발환경**: STS4 + Tomcat 9, `testEnvironment="true"` 격리 배포

### STS 배포 경로

```
.metadata/.plugins/org.eclipse.wst.server.core/
  tmp1/wtpwebapps/ticket-admin/   ← ticket-admin 배포
  tmp2/wtpwebapps/ticket-partner/ ← ticket-partner 배포
  tmp3/wtpwebapps/ticket-user/    ← ticket-user 배포
```

**중요**: STS 설정이 "Never publish automatically"이므로 소스 변경 후 배포 폴더에도 직접 복사해야 한다. 프로젝트 루트의 `deploy-sync.sh` 스크립트로 일괄 처리:

```bash
bash deploy-sync.sh all        # 전체
bash deploy-sync.sh user       # ticket-user만
bash deploy-sync.sh partner    # ticket-partner만
bash deploy-sync.sh admin      # ticket-admin만
```

Java 파일 변경 시에는 스크립트 후 반드시 **서버 Restart** 필요.

---

## 2. 인증 및 역할 체계

### 역할 구분

| Role | 가입 방법 | 로그인 포털 | 접근 경로 |
|---|---|---|---|
| `MEMBER` | `/member/join` 자가 가입 | ticket-user (8080) | `/`, `/performance/**`, `/reservation/**`, `/seat/**` |
| `PROMOTER` | SUPER_ADMIN이 어드민에서 계정 생성 후 승인 | ticket-partner (8081) | `/partner/promoter/**` |
| `VENUE_MANAGER` | SUPER_ADMIN이 어드민에서 계정 생성 후 승인 | ticket-partner (8081) | `/partner/venue/**` |
| `STAFF` | SUPER_ADMIN이 직접 생성 | ticket-admin (8082) | `/backoffice/staff/**` |
| `SUPER_ADMIN` | DB 시드 데이터로만 존재 | ticket-admin (8082) | `/backoffice/super/**`, `/backoffice/staff/**` |

### JWT 흐름

1. 로그인 API → JWT 발급 → HttpOnly 쿠키(`ACCESS_TOKEN`)에 저장
2. 모든 요청에서 `JwtAuthenticationFilter`가 쿠키 검증 → `SecurityContextHolder` 설정
3. 각 포털의 로그인 API는 역할 검증 후 거부:
   - `ticket-user` `/api/member/login` — 역할 무관 허용 (단, PROMOTER/VENUE_MANAGER 로그인 시 파트너 포털 URL로 redirectUrl 반환)
   - `ticket-partner` `/partner/api/login` — PROMOTER, VENUE_MANAGER만 허용
   - `ticket-admin` `/admin/api/login` — SUPER_ADMIN, STAFF만 허용

### 테스트 계정 (DB 시드 기준)

| 계정 | 역할 | 포털 |
|---|---|---|
| `user1@test.com` / `user123` | MEMBER | ticket-user |
| `admin@ticketlegacy.com` / `admin123` | SUPER_ADMIN | ticket-admin |

---

## 3. 요청 처리 파이프라인

```
HTTP
 → JwtAuthenticationFilter (JWT 검증)
 → RateLimitInterceptor (IP당 요청 제한, ticket-user만)
 → QueueInterceptor (공연별 동시 접속 500명 제한, ticket-user만)
 → AuthInterceptor (loginMemberId, loginRole을 request attribute에 설정)
 → Controller → Service → MyBatis Mapper → MySQL
```

**동시성 제어 (좌석)**:
1. Redis SETNX로 좌석 락 선점
2. DB `UPDATE ... WHERE status = 'AVAILABLE'` 낙관적 락
3. 결제 테이블 `idempotency_key UNIQUE` 제약으로 중복 결제 방지
4. Redis 불가 시 DB 락만으로 graceful degradation

---

## 4. 모듈별 컨트롤러 및 뷰 현황

### ticket-user (8080)

| Controller | 주요 URL | 뷰 |
|---|---|---|
| `MemberController` | `GET /member/login`, `GET /member/join`, `GET /member/mypage`, `POST /api/member/join`, `POST /api/member/login`, `POST /api/member/logout` | member/login, member/join, member/mypage |
| `PerformanceController` | `GET /`, `GET /performance/list`, `GET /performance/detail/{id}` | performance/list, performance/detail |
| `SeatController` | `GET /seat/select/{scheduleId}`, `/api/seats/**` | seat/select |
| `ReservationController` | `GET /reservation/confirm/{id}`, `GET /reservation/history`, `/api/reservation/**` | reservation/confirm, reservation/history |
| `PaymentController` | `POST /api/payment/process` | (API only) |
| `QueueController` | `GET /queue/waiting`, `/api/queue/**` | queue/waiting |

**뷰 목록**: join, login, mypage, performance/list, performance/detail, seat/select, reservation/confirm, reservation/history, queue/waiting, error/404, 500, 503

### ticket-partner (8081)

| Controller | 주요 URL | 뷰 |
|---|---|---|
| `PartnerLoginController` | `GET /partner/login`, `POST /partner/api/login`, `POST /partner/api/logout` | member/login |
| `PartnerPromoterController` | `GET /partner/promoter/dashboard`, `/performances`, `/performances/new`, `/sales-report`, `/settlement` + 다수 API | partner/promoter/* |
| `PartnerVenueController` | `GET /partner/venue/dashboard`, `/venue-info`, `/schedule-calendar`, `/entrance` + 다수 API | partner/venue/* |
| `PartnerCouponController` | `GET /partner/promoter/notices` + API | partner/promoter/notices |

**뷰 목록**: partner/promoter/dashboard, performance-list, performance-form, sales-report, settlement, notices, partner/venue/dashboard, venue-info, schedule-calendar, entrance

### ticket-admin (8082)

| Controller | 주요 URL | 뷰 |
|---|---|---|
| `AdminLoginController` | `GET /admin/login`, `POST /admin/api/login`, `POST /admin/api/logout` | member/login |
| `BackofficeSuperController` | `/backoffice/super/dashboard`, `member-list`, `settlement`, + 공연/좌석/기획사 승인 다수 API | backoffice/super/* |
| `BackofficeStaffController` | `/backoffice/staff/dashboard`, `reservation-search`, `member-search` + API | backoffice/staff/* |
| `BackofficeCouponController` | `/backoffice/super/coupons`, `/notices` + API | backoffice/super/coupons, notices |
| `BackofficeAnalyticsController` | `/backoffice/super/api/analytics/**` | (API only) |
| `BackofficeSuperAnalyticsController` | `/backoffice/super/statistics` | backoffice/super/statistics |

**뷰 목록**: backoffice/super/dashboard, member-list, statistics, settlement, coupons, notices, backoffice/staff/dashboard, reservation-search, member-search

---

## 5. 공통 모듈 (ticket-common)

### 도메인 클래스 (20개)

`Member`, `Performance`, `Schedule`, `Seat`, `SeatInventory`, `Reservation`, `ReservationSeat`, `Payment`, `Coupon`, `CouponTemplate`, `Promoter`, `VenueManager`, `Venue`, `VenueSection`, `VenueStageConfig`, `VenueStageSection`, `VenueSeatTemplate`, `PerformanceSeatGrade`, `PerformanceSectionOverride`, `Notice`, `EntranceLog`

### 서비스 클래스 (11개)

`MemberService`, `PerformanceApprovalService`, `AdminPerformanceService`, `PromoterService`, `VenueManagerService`, `VenueAdminService`, `ReservationService`, `CouponService`, `NoticeService`, `EntranceService`, `PortalDashboardService`

### Mapper (21개)

`MemberMapper`, `PerformanceMapper`, `ScheduleMapper`, `SeatMapper`, `SeatInventoryMapper`, `ReservationMapper`, `PaymentMapper(user모듈)`, `CouponMapper`, `PromoterMapper`, `VenueManagerMapper`, `VenueMapper`, `VenueSectionMapper`, `VenueStageConfigMapper`, `VenueStageSectionMapper`, `VenueSeatTemplateMapper`, `PerformanceSeatGradeMapper`, `PerformanceSectionOverrideMapper`, `NoticeMapper`, `EntranceLogMapper`, `AnalyticsMapper`, `PortalQueryMapper`

### 주요 Enum

- `MemberRole`: MEMBER, PROMOTER, VENUE_MANAGER, STAFF, SUPER_ADMIN
- `ReservationStatus`: PENDING, CONFIRMED, CANCELLED, REFUNDED
- `PaymentStatus`: PENDING, COMPLETED, FAILED, REFUNDED
- `SeatStatus`: AVAILABLE, HELD, RESERVED, BLOCKED
- `Performance.approvalStatus`: DRAFT, REVIEW, APPROVED, REJECTED, PUBLISHED

### 공연 승인 워크플로우

```
PROMOTER 등록 → DRAFT
→ submit 요청 → REVIEW
→ SUPER_ADMIN 승인 → APPROVED
→ SUPER_ADMIN publish → PUBLISHED (공개 판매 시작)
→ SUPER_ADMIN 반려 → REJECTED (수정 후 재요청 가능)
```

---

## 6. 이번 세션에서 완료한 작업

### 서버 기동 관련 (초기 설정)

- STS `testEnvironment="true"` 설정으로 tmp1/2/3 격리 배포 구성
- 포트 충돌 수정 (8005/6/7 shutdown, 8080/1/2 HTTP)
- Spring Security에 `pattern="/" permitAll` 추가로 STS 180초 타임아웃 해결
- `root-context.xml` MyBatis mapperLocations를 `classpath:` (star 없음)로 수정 — 중복 namespace 오류 해결

### 도메인 수정

- `Performance`: `ageLimit`, `runningTime`, `minPrice` 필드 추가, `getGenre()` alias getter 추가
- `Schedule`: `getStartDatetime()` computed getter 추가 (showDate + showTime 조합)
- `Coupon`: `getCouponName()`, `getDiscountAmount()`, `getExpiryDate()` alias getter 추가

### JSP 버그 수정

- JSP에서 `p.id` → `p.performanceId` 등 잘못된 프로퍼티 참조 수정
- `fmt:formatDate` (Java 8 LocalDate 미지원) → 커스텀 TLD `tl:fmt` 방식으로 변경
- `DateUtil.java`를 `ticket-user/src/main/java`에 배치하여 Eclipse WTP 컴파일 적용

### 가입 플로우 분리

- `member/join.jsp`에서 PROMOTER/VENUE_MANAGER 탭 제거 → MEMBER 전용 가입만 유지
- `MemberController`에서 promoter/venue-manager join 엔드포인트 제거

### 로그인 API URL 수정 (전 포털 공통 버그)

| 포털 | 수정 전 | 수정 후 |
|---|---|---|
| ticket-user login | `/member/api/login` | `/api/member/login` |
| ticket-user join | `/member/api/join` | `/api/member/join` |
| ticket-user logout | `/member/api/logout` | `/api/member/logout` |
| ticket-partner login | `/api/member/login` | `/partner/api/login` |
| ticket-partner logout | `/api/member/logout` | `/partner/api/logout` |
| ticket-admin login | `/api/member/login` | `/admin/api/login` |
| ticket-admin logout | `/api/member/logout` | `/admin/api/logout` |

### 로그인 UI 리디자인

- ticket-partner `member/login.jsp`: 구식 Bootstrap card → PARTNER PORTAL 브랜딩 재설계
- ticket-admin `member/login.jsp`: 구식 Bootstrap card → BACKOFFICE 브랜딩 재설계
- 파트너/어드민 로그인 페이지에서 회원가입 링크 제거

### 루트 경로 리다이렉트

- ticket-partner: `GET /` → redirect `/partner/login`
- ticket-admin: `GET /` → redirect `/admin/login`

### 레거시 컨트롤러 삭제

삭제된 파일:
- `ticket-partner`: `PromoterController.java` (`/promoter/**`), `VenueManagerController.java` (`/venue-manager/**`)
- `ticket-admin`: `AdminController.java` (`/admin/**`), `SuperAdminController.java` (`/superadmin/**`)
- `ticket-admin`: `admin/dashboard.jsp`, `superadmin/dashboard.jsp`
- `ticket-admin` `tiles-config.xml`: `admin/dashboard`, `superadmin/dashboard` 정의 제거
- 각 security-context.xml에서 레거시 intercept-url 제거

### common.js 개선 (파트너/어드민)

- `patch` 메서드 추가
- `toast` 유틸 추가 (SweetAlert2 기반 toast)
- 로그아웃 URL 각 포털 전용 API로 수정

### 어드민 버그 수정

- `backoffice-layout.jsp`: Public Site 링크 `http://localhost:8080/` (새 탭) 으로 수정
- `backoffice-sidebar.jsp`: My Account → 로그아웃 버튼으로 교체
- `settlement.jsp`: API URL `/settlement/report` → `/settlement` 수정
- `notices.jsp`, `coupons.jsp`: `LocalDateTime` 배열 직렬화 처리 (`fmtDate`, `fmtDt` 함수 개선)
- `BackofficeCouponController`: `datetime-local` 입력값(`HH:mm` 초 없음) 파싱 수정
- `statistics.jsp`: 페이지 로드 시 일별 트렌드 차트 즉시 표시

---

## 7. 미해결 이슈 및 TODO

### 긴급 (기능 불가)

#### ticket-user

- [ ] **회원가입 미작동**: `/api/member/join` 호출 시 오류 발생 여부 미확인 — `MemberService.join()` 내부 로직 및 DB insert 검증 필요
- [ ] **공연 상태 표시 오류**: 판매 전 공연이 "매진"으로 표시됨 — `performance/list.jsp` 또는 `PerformanceService`에서 status 판정 로직 확인 필요. `UPCOMING` 상태를 "오픈 예정"으로, `SOLD_OUT`만 "매진"으로 표시해야 함
- [ ] **좌석 선택 → 결제 플로우 전체 미검증**: seat/select.jsp → 결제 API → 예매 확인 전 구간

#### ticket-partner

- [ ] **500/503 오류 다수**: 어떤 페이지/기능인지 로그로 추가 확인 필요
  - 대시보드 API 실패 가능성 (DB 데이터 없을 경우)
  - 공연 등록 폼 submit 미검증
  - 정산 조회 미검증

#### ticket-admin

- [ ] **쿠폰 생성 500 재확인**: Java 수정(BackofficeCouponController) 후 서버 재시작 필요
- [ ] **통계 API 실패 여부**: `/backoffice/super/api/analytics/all` — DB에 데이터가 없으면 NPE 등 발생 가능
- [ ] **회원 관리 공연 승인 기능 미검증**: 기획사 신청 승인/반려 플로우

### 구조적 개선 필요

- [ ] **`DateUtil` 중복**: `ticket-common`에 있으나 `ticket-user`에도 중복 존재 — `ticket-common` 것을 사용하고 `ticket-user` 것 제거 필요 (STS WTP 클래스로딩 이슈로 임시 추가한 것)
- [ ] **Jackson LocalDateTime 직렬화**: `root-context.xml`의 Jackson ObjectMapper에 `WRITE_DATES_AS_TIMESTAMPS = false` 미설정 — 현재 LocalDateTime이 배열 `[2026,4,17,14,30,0]`로 직렬화됨. 각 JSP에서 배열/문자열 양쪽 처리하는 `fmtDate`/`fmtDt` 헬퍼로 우회 중. 근본 수정: `root-context.xml`에 아래 추가:
  ```xml
  <property name="featuresToDisable">
      <array>
          <value>#{T(com.fasterxml.jackson.databind.SerializationFeature).WRITE_DATES_AS_TIMESTAMPS}</value>
      </array>
  </property>
  ```
  이 수정 시 모든 날짜가 ISO 문자열로 통일되어 JS 처리가 단순해짐
- [ ] **PROMOTER/VENUE_MANAGER 계정 생성 UI 부재**: 현재 어드민에서 파트너 계정을 생성할 수 있는 UI가 없음. `BackofficeSuperController`에 API는 있으나 화면이 없음 — 회원 관리 페이지에 "파트너 계정 생성" 모달 추가 필요

### 기능 확장 (추가 개발)

#### ticket-user 확장 포인트

- [ ] 공연 검색/필터 (카테고리, 날짜, 지역, 가격대)
- [ ] 공연 상세 → 리뷰/별점 기능
- [ ] 마이페이지: 쿠폰 목록 표시 및 적용, 취소/환불 내역
- [ ] 결제 게이트웨이 실제 연동 (현재 mock 처리)
- [ ] SNS 공유 기능

#### ticket-partner 확장 포인트

- [ ] 공연 등록 폼(`performance-form.jsp`) — 스케줄/좌석 등급 설정 UI 완성도 검증
- [ ] 판매 리포트 차트 구현 (현재 테이블만)
- [ ] 기획사 정산 내역 상세 (월별 breakdown)
- [ ] 입장 QR 스캔 연동 (현재 예매번호 수동 입력)
- [ ] 공연장 좌석 배치도 시각화

#### ticket-admin 확장 포인트

- [ ] 파트너 계정 생성/관리 UI
- [ ] 회원 상세 조회 페이지 (현재 목록만)
- [ ] 공연 승인 페이지 (현재 dashboard에 포함 — 별도 페이지로 분리 고려)
- [ ] 환불 처리 기능
- [ ] 공지사항 수신 대상별 미리보기

---

## 8. 배포 주의사항

### 소스 변경 후 배포 절차

```
1. 소스 파일 수정 (ticket-*/src/main/...)
2. bash deploy-sync.sh [user|partner|admin|all]
3. Java 파일 변경 있으면 → STS에서 해당 서버 Restart
4. JSP/CSS/JS만 변경 → 브라우저 새로고침으로 반영 (JSP 캐시는 스크립트가 자동 삭제)
```

### PID 강제 종료 (포트 충돌 시)

```bash
# 현재 포트 사용 PID 확인
netstat -ano | grep -E "8080|8081|8082"

# 강제 종료 (Windows)
taskkill /PID <pid> /F
```

### 서버 설정 파일 위치

```
Servers/Tomcat v9.0 Server at localhost (ticket-user)-config/server.xml    (port: 8005/8080)
Servers/Tomcat v9.0 Server at localhost (ticket-partner)-config/server.xml  (port: 8006/8081)
Servers/Tomcat v9.0 Server at localhost (ticket-admin)-config/server.xml    (port: 8007/8082)
```

---

## 9. 핵심 파일 위치 빠른 참조

| 목적 | 파일 경로 |
|---|---|
| 공통 도메인 | `ticket-common/src/main/java/com/ticketlegacy/domain/` |
| 공통 서비스 | `ticket-common/src/main/java/com/ticketlegacy/service/` |
| MyBatis XML | `ticket-common/src/main/resources/mybatis/mapper/` |
| JWT 필터 | `ticket-*/src/main/java/.../web/filter/JwtAuthenticationFilter.java` |
| 시큐리티 설정 | `ticket-*/src/main/webapp/WEB-INF/spring/security-context.xml` |
| MVC 설정 | `ticket-*/src/main/webapp/WEB-INF/spring/servlet-context.xml` |
| DB/MyBatis 설정 | `ticket-*/src/main/webapp/WEB-INF/spring/root-context.xml` |
| 타일즈 설정 | `ticket-*/src/main/webapp/WEB-INF/tiles/tiles-config.xml` |
| TLD (날짜 포맷) | `ticket-user/src/main/webapp/WEB-INF/tlds/tl.tld` |
| 배포 스크립트 | `ticket-parent/deploy-sync.sh` |
| 유저 공통 JS | `ticket-user/src/main/webapp/resources/js/common.js` |
| 파트너 공통 JS | `ticket-partner/src/main/webapp/resources/js/common.js` |
| 어드민 공통 JS | `ticket-admin/src/main/webapp/resources/js/common.js` |
