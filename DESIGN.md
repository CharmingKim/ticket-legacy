# TicketLegacy 설계 명세서

> 이 문서는 "왜 이렇게 만들었는가"를 기록한다.
> 코드는 어떻게(How)를 말하고, 이 문서는 왜(Why)를 말한다.

---

## 1. 레이어드 아키텍처 — 왜 계층을 나누는가

```
HTTP 요청
    ↓
Controller      (HTTP 번역기 — 요청/응답 형식만 담당)
    ↓
Service         (비즈니스 규칙 — 이 계층만 "어떻게 처리할지" 안다)
    ↓
Repository      (데이터 접근 — SQL만 안다)
    ↓
Database
```

### 핵심 원칙: 각 계층은 바로 아래 계층만 알아야 한다

**Controller가 Mapper를 직접 쓰면 안 되는 이유:**
```java
// 나쁜 예 (이전 코드)
@PostMapping("/api/members/{id}/status")
public ResponseEntity<?> update(@PathVariable Long id, @RequestBody Map<String, String> body) {
    memberMapper.updateStatus(id, body.get("status")); // Controller가 DB를 직접 건드림
}
```
문제점:
- `@Transactional`이 없어 트랜잭션 경계가 없음 → 실패해도 롤백 안 됨
- AOP(로깅, 감사 추적)가 작동하지 않음
- 같은 로직이 필요한 곳마다 복붙해야 함 → 중복 코드
- 비즈니스 규칙(FSM 검증 등)을 어디에 써야 할지 불명확

**올바른 구조:**
```java
// 좋은 예 (현재 코드)
@PostMapping("/api/members/{id}/status")
public ResponseEntity<ApiResponse<Void>> update(
        @PathVariable Long id,
        @Valid @RequestBody MemberStatusCommand cmd) {
    memberService.updateAdminStatus(id, cmd.getStatus()); // Service에만 위임
    return ResponseEntity.ok(ApiResponse.successMessage("상태가 변경되었습니다."));
}
```
Controller는 딱 3가지만 한다: 요청 받기 → Service 호출 → 응답 반환.

---

## 2. Command 패턴 — 왜 Map 대신 Command 객체를 쓰는가

### 문제: `Map<String, Object>` 안티패턴

```java
// 나쁜 예
@PostMapping("/api/venues")
public ResponseEntity<?> createVenue(@RequestBody Map<String, Object> body) {
    String name = (String) body.get("name");       // 타입 캐스팅 — 런타임 오류 가능
    if (name == null || name.isBlank()) return ...; // 검증 코드가 컨트롤러에 산재
    int scale = body.get("seatScale") != null
        ? ((Number) body.get("seatScale")).intValue() : 0; // 장황한 null 처리
    venueAdminService.createVenue(name, address, scale);
}
```

**문제점 3가지:**
1. **컴파일 타임 안전성 없음** — `body.get("seat_scale")` (오타)해도 컴파일러가 못 잡음
2. **검증 코드 분산** — 각 Controller 메서드마다 null 체크, 타입 변환 코드 중복
3. **API 계약 불명확** — 이 API가 어떤 필드를 받는지 코드만 봐서는 알기 어려움

### 해결: Command 객체

```java
// 좋은 예
@Getter @NoArgsConstructor
public class MemberStatusCommand {
    @NotNull(message = "변경할 상태값은 필수입니다.")
    private MemberStatus status; // 타입 자체가 허용 값을 제한함
}

// Controller
@PostMapping("/api/members/{id}/status")
public ResponseEntity<ApiResponse<Void>> update(
        @PathVariable Long id,
        @Valid @RequestBody MemberStatusCommand command) { // @Valid가 자동 검증
    memberService.updateAdminStatus(id, command.getStatus());
}
```

**이점:**
- `MemberStatus`가 enum이므로 잘못된 값("ACTV" 오타 등)은 Jackson이 역직렬화 단계에서 400 오류 반환
- `@Valid`가 `@NotNull` 위반을 자동 감지 → Controller 코드에 검증 로직 없음
- 이 API가 받는 필드가 Command 클래스 자체로 문서화됨

---

## 3. FSM (Finite State Machine) — 왜 상태 전환 규칙을 코드로 명시하는가

### 문제: 상태 관리 없이 직접 바꾸면

```java
// 나쁜 예
memberMapper.updateStatus(memberId, "ACTIVE"); // 뭐든 ACTIVE로 바꿀 수 있음
```

WITHDRAWN(탈퇴)된 회원을 어드민 실수로 ACTIVE로 복구할 수 있음.
ACTIVE → PENDING_APPROVAL 같은 말이 안 되는 전환도 가능.

### 해결: FSM enum

```java
public enum MemberStatus {
    PENDING_APPROVAL, ACTIVE, SUSPENDED, DORMANT, WITHDRAWN;

    public boolean canTransitionTo(MemberStatus next) {
        switch (this) {
            case ACTIVE:    return next == SUSPENDED || next == WITHDRAWN || next == DORMANT;
            case WITHDRAWN: return false; // terminal — 어떤 전환도 불가
            // ...
        }
    }
}
```

```
                ┌─────────────┐
                │PENDING_APPRO│
                └──────┬──────┘
              승인↓    │반려
         ┌────────┐    ↓
         │ ACTIVE │←──SUSPENDED
         └────────┘       ↑
           ↓  ↓           │정지해제
        DORMANT WITHDRAWN  │
           ↓(재로그인)      │
         ACTIVE           │(이 루트는 서비스 로직)
```

`Service.updateAdminStatus()`가 전환 시 `canTransitionTo()` 검사 → 불가하면 `BusinessException` 발생.

**이것이 바로 "비즈니스 규칙은 Service에만"의 실체다.** FSM이 Service에 있어야 어떤 Controller에서 호출하든 동일한 규칙이 적용된다.

---

## 4. DTO 패턴 — 왜 Domain 객체를 직접 응답하면 안 되는가

### 문제: Domain 직접 노출

```java
// 나쁜 예 (이전 코드)
List<Member> members = memberMapper.findAll(...);
return ResponseEntity.ok(Map.of("list", members)); // Member.password가 JSON에 포함됨!
```

`Member` 도메인에는 `password` 필드가 있다. BCrypt 해시라도 클라이언트에 노출되면:
- 해시 알고리즘 식별 가능
- 오프라인 브루트포스 공격 가능
- 보안 감사(Security Audit)에서 즉시 지적됨

### 해결 1: `@JsonIgnore` (최소 방어)

```java
public class Member {
    @JsonIgnore
    private String password; // JSON 직렬화에서 제외
}
```

### 해결 2: `MemberSummaryDto` (완전 분리)

```java
@Getter
public class MemberSummaryDto {
    private final Long memberId;
    private final String email;
    private final String name;
    // password 필드 자체가 없음

    public static MemberSummaryDto from(Member m) {
        return new MemberSummaryDto(m);
    }
}
```

**왜 둘 다 했나?**
- `@JsonIgnore`: Domain 객체가 직렬화되는 모든 경로의 방어막 (2중 안전망)
- `MemberSummaryDto`: API 계약(응답 스펙)을 명시적으로 정의 — 어떤 필드를 내보낼지 의도적으로 선택

**원칙: API 응답에 나가는 필드는 의도적으로 선택해야 한다. 실수로 노출되는 구조는 안 된다.**

---

## 5. `ApiResponse<T>` — 왜 응답 봉투(Envelope)가 필요한가

### 문제: 일관성 없는 응답

```json
// 성공 응답 A (어떤 API)
{ "list": [...], "total": 100 }

// 성공 응답 B (다른 API)
{ "message": "완료" }

// 에러 응답
"Internal Server Error"  (← 500 에러일 때 HTML이 오는 경우도!)
```

프론트엔드가 매 API마다 다른 파싱 로직이 필요. 에러 처리도 API마다 다름.

### 해결: 통일된 봉투

```json
// 모든 성공 응답
{
  "success": true,
  "message": "OK",
  "data": { ... },
  "errorCode": null
}

// 모든 에러 응답
{
  "success": false,
  "message": "허용되지 않는 상태 전환입니다.",
  "data": null,
  "errorCode": "MBR_002"
}
```

프론트엔드는 `response.success`로 성공/실패 판단, `response.data`에서 데이터, `response.message`에서 메시지.
**한 가지 패턴만 알면 된다.**

### `errorCode`가 있는 이유

단순 메시지만 주면 프론트엔드가 메시지 문자열 비교를 해야 한다:
```javascript
if (result.message === "허용되지 않는 상태 전환입니다.") // 취약함 — 메시지 바꾸면 깨짐
```

errorCode가 있으면:
```javascript
if (result.errorCode === "MBR_002") // 안정적 — 코드는 안 바뀜
```

---

## 6. `PageResponse<T>` — 왜 페이지네이션 래퍼가 필요한가

### 이전: 매번 같은 패턴 복붙

```java
// 각 컨트롤러마다 반복
return ResponseEntity.ok(Map.of("list", list, "total", total, "page", page));
```

JSP/JS에서: `response.list`, `response.total`, `response.page` — 필드명이 API마다 다를 수도 있음

### 현재: 단일 표준

```java
// 서비스에서
return PageResponse.of(dtos, totalCount, page, size);

// 응답 구조 (모든 목록 API 동일)
{
  "data": {
    "content": [...],
    "page": 1,
    "size": 20,
    "totalElements": 150,
    "totalPages": 8,
    "first": true,
    "last": false
  }
}
```

JS에서: `response.data.content`, `response.data.totalElements` — 어떤 목록 API든 동일.

`first`, `last`는 "이전/다음 버튼 활성화" 여부를 계산할 필요 없이 바로 쓸 수 있게 제공.

---

## 7. `GlobalExceptionHandler` — 왜 예외를 한 곳에서 처리하는가

### 문제: 예외를 컨트롤러에서 try-catch하면

```java
// 나쁜 예 — 모든 컨트롤러마다 반복
try {
    memberService.updateAdminStatus(id, status);
    return ResponseEntity.ok(...);
} catch (BusinessException e) {
    return ResponseEntity.status(e.getErrorCode().getHttpStatus()).body(...);
} catch (Exception e) {
    return ResponseEntity.status(500).body(...);
}
```

20개 API에서 20번 반복. 새 예외 타입 추가하면 20곳 수정.

### 해결: `@ControllerAdvice`

```java
@ControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResponse<?>> handle(BusinessException e) {
        return ResponseEntity.status(e.getErrorCode().getHttpStatus())
                .body(ApiResponse.error(e.getErrorCode()));
    }
}
```

단 한 곳에서 모든 예외를 처리. 새 예외 타입 추가도 여기만 수정.

### `HttpMessageNotReadableException`을 추가한 이유

```json
// 잘못된 JSON
POST /api/members/1/status
{ "status": "ACTIV" }  ← MemberStatus enum에 없는 값
```

이전: 500 Internal Server Error → 디버깅 어려움
지금: 400 Bad Request + "요청 본문을 읽을 수 없습니다" → 클라이언트가 즉시 수정 가능

**원칙: 클라이언트 잘못은 4xx, 서버 잘못은 5xx.** 이전에는 클라이언트 오류를 5xx로 응답하는 버그가 있었다.

---

## 8. 응집도(Cohesion)와 결합도(Coupling)

### 응집도 — "관련 있는 것들이 얼마나 모여있는가"

**낮은 응집도 (나쁨):**
```java
// MemberService가 정산 계산도 하고, 통계도 하고, 회원도 관리하면?
class MemberService {
    void updateStatus() { ... }
    Map calculateSettlement() { ... } // ← 여기 있으면 안 됨
    List getAnalytics() { ... }       // ← 여기 있으면 안 됨
}
```

**높은 응집도 (좋음):**
```java
class MemberService       { // 회원 관련만 }
class PortalDashboardService { // 대시보드 집계만 }
class AdminPerformanceService { // 공연 관리만 }
```

### 결합도 — "모듈들이 얼마나 서로 의존하는가"

**높은 결합도 (나쁨):**
```java
// Controller가 Mapper, Service, Domain, 외부 API 모두 직접 의존
class BackofficeSuperController {
    @Autowired MemberMapper memberMapper;     // DB 직접
    @Autowired ScheduleMapper scheduleMapper; // DB 직접
    @Autowired ExternalApiClient apiClient;  // 외부 API 직접
}
```

**낮은 결합도 (좋음):**
```java
class BackofficeSuperController {
    @Autowired MemberService memberService;     // Service만 의존
    @Autowired VenueAdminService venueAdminService;
    // Mapper, DB, 외부 API는 모름 → 변경해도 Controller 수정 불필요
}
```

---

## 9. 파일 목록 — 각 파일의 존재 이유

### ticket-common — 3개 WAR 공유 라이브러리

| 파일 | 왜 만들었나 |
|---|---|
| `domain/enums/MemberStatus.java` | 회원 상태 FSM. 허용 전환 규칙을 코드로 명시. 실수로 잘못된 상태 전환 불가 |
| `domain/enums/MemberRole.java` | 실제 사용 역할 5개 정의. 이전엔 `USER`, `ADMIN` 2개뿐이어서 dead code |
| `domain/Member.java` | `@JsonIgnore on password` — API 응답에 비밀번호 해시 노출 방지 |
| `exception/ErrorCode.java` | HTTP 상태 코드 + 에러 코드 + 메시지를 한 곳에서 관리. 산발적 문자열 제거 |
| `exception/BusinessException.java` | `ErrorCode`를 감싸는 RuntimeException. try-catch 없이 throws만으로 에러 전달 |
| `dto/request/MemberSearchQuery.java` | 회원 목록 검색 파라미터. `@Valid`로 page/size 범위 제한 |
| `dto/request/MemberStatusCommand.java` | 상태 변경 요청. `MemberStatus` enum 사용 → 잘못된 값 자동 거부 |
| `dto/response/ApiResponse.java` | 모든 API 응답의 봉투. success/message/data/errorCode 통일 |
| `dto/response/PageResponse.java` | 목록 API 공통 페이지네이션 구조. 매번 `Map.of("list",...)` 반복 제거 |
| `dto/response/MemberSummaryDto.java` | password 없는 안전한 회원 응답 DTO. API 응답 필드를 의도적으로 선택 |
| `service/MemberService.java` | `updateAdminStatus()` — FSM 검증, `searchMembers()` — `PageResponse` 반환 |

### ticket-admin — 관리자 WAR

| 파일 | 왜 만들었나 |
|---|---|
| `web/advice/GlobalExceptionHandler.java` | 모든 예외를 한 곳에서 처리. `HttpMessageNotReadableException` 추가로 JSON 오류 → 400 |
| `web/controller/BackofficeSuperController.java` | Mapper 9개 → Service 7개. `Map<>` → 타입 안전 Command/DTO |
| `web/controller/BackofficeStaffController.java` | Mapper 2개 제거. Member/Reservation 조회 모두 Service 통해서 |

---

## 10. 이 프로젝트에서 앞으로 지킬 규칙

### Controller 작성 규칙

```java
// Controller는 딱 이것만
@PostMapping("/api/something")
public ResponseEntity<ApiResponse<SomeDto>> doSomething(
        @Valid @RequestBody SomeCommand command,  // 1. 입력 받기 (@Valid)
        @AuthMember Long memberId) {
    SomeDto result = someService.doSomething(command, memberId); // 2. Service 호출
    return ResponseEntity.ok(ApiResponse.success(result));       // 3. 응답 반환
}
```

### Service 작성 규칙

```java
// Service는 비즈니스 규칙만
@Transactional
public SomeDto doSomething(SomeCommand command, Long memberId) {
    // 1. 입력 검증 (도메인 규칙)
    // 2. 비즈니스 로직
    // 3. Mapper 호출
    // 4. DTO 변환 후 반환
}
```

### 절대 하지 말 것

- Controller에서 Mapper `@Autowired` — Service 통해서만
- `Map<String, Object>` body 파싱 — Command 객체 만들기
- Domain 객체 직접 API 응답 — DTO 만들기 (특히 password, 내부 필드 노출 주의)
- `ResponseEntity.ok(Map.of("message", "..."))` — `ApiResponse.successMessage()` 사용
- `try-catch` in Controller — GlobalExceptionHandler에서 처리
- `IllegalArgumentException("잘못된 값")` — `BusinessException(ErrorCode.XXX)` 사용

---

## 11. 다음 봉인 대상 (Phase B2~)

| Phase | 도메인 | 핵심 작업 |
|---|---|---|
| B2 | Promoter (기획사) | 승인/반려 FSM, `ApprovalStatus` enum, `RegisterPromoterCommand`, `PromoterDto` |
| B3 | Performance (공연 심사) | REVIEW→APPROVED→PUBLISHED FSM, 미리보기 API |
| B4 | Settlement (정산) | `SettlementQuery`, 집계 DTO |
| B5 | Analytics (통계) | NPE 방어, 빈 컬렉션 보장 |
| C1 | 파트너 좌석등급 | `SaveSeatGradeCommand` |
| D1 | 유저 쿠폰 | `CouponApplyCommand`, 할인 계산 |
