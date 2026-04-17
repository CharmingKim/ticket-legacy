# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 역할

ticket-common은 3개 WAR 모듈(user·partner·admin)이 공유하는 JAR 라이브러리. 독립 실행 불가.

## 포함 대상 (common에 두는 것)

| 패키지 | 내용 |
|---|---|
| `domain/` | 20개 도메인 클래스 + `enums/` (MemberRole, PaymentStatus 등) |
| `exception/` | BusinessException, ErrorCode(40+개), 전용 예외 클래스 |
| `util/` | JwtUtil (JWT 발급·검증), IdempotencyKeyGenerator |
| `dto/request/` | LoginRequest, MemberJoinRequest, PaymentRequest, SeatHoldRequest |
| `dto/response/` | ApiResponse (공통 응답 래퍼) |
| `repository/` | 18개 Mapper 인터페이스 (SeatMapper, PaymentMapper 제외) |
| `service/` | MemberService, CouponService, ReservationService 등 9개 |

## Common에 절대 두지 않는 것

- DataSource / HikariCP 설정 — 각 WAR의 `root-context.xml`에서 선언
- RedisConnectionFactory / StringRedisTemplate Bean — ticket-user `root-context.xml` 전용
- Spring XML context 파일, web.xml, security-context.xml
- `@Controller`, `@ControllerAdvice` — WAR 모듈 전용
- ticket-user 전용: SeatService, QueueService, PaymentService, PerformanceService
- ticket-partner 전용: VenueManagerService, EntranceService

## Mapper XML 위치 규칙

```
ticket-common/src/main/resources/mybatis/mapper/   ← common Mapper XML 18개
ticket-user/src/main/resources/mybatis/mapper/     ← PaymentMapper.xml
```
각 WAR의 `root-context.xml`에서 `classpath:mybatis/mapper/**/*.xml` 로 스캔 — common JAR 안의 XML도 classpath에 포함되어 자동 인식.

## MemberService.LoginResult 주의

`LoginResult`는 MemberService의 **static inner class**이며 `public final` 필드만 있음. getter 없음.
```java
// 올바른 접근
result.token
result.role
result.name
result.redirectUrl

// 잘못된 접근 (컴파일 에러)
result.getToken()  // ❌
```

## ReservationService.redisTemplate

`@Autowired(required=false)` — Redis 없이도 동작. ticket-admin/partner에서는 null이 되므로 해당 서비스의 Redis 관련 메서드 호출 시 null 체크 로직이 내장되어 있음.
