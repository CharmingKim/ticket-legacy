# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 역할

사용자 포털 WAR — 일반 회원의 공연 탐색·예매·결제 처리. `port 8080`.

## 실행

```bash
# ticket-parent 디렉토리에서
mvn tomcat7:run -pl ticket-user -am

# 접속: http://localhost:8080
# 테스트 계정: user1@test.com / user123
```

**사전 조건**: MySQL(`springgreen6`)과 Redis(`localhost:6379`) 모두 실행 중이어야 함.

## Redis 의존성 (필수)

ticket-user의 4개 Bean이 `StringRedisTemplate`를 **하드 @Autowired** (required=false 아님):

| Bean | Redis 용도 |
|---|---|
| `SeatService` | 좌석 선점 (Lua SETNX, HOLD=10분) |
| `QueueService` | 대기열 (Sorted Set, @Scheduled 3초) |
| `PaymentService` | 결제 중복 방지 캐시 |
| `RateLimitInterceptor` | API rate limit (30 req/min, POST만) |

Redis가 없으면 서버 기동 자체가 실패. `root-context.xml`의 `LettuceConnectionFactory` 빈이 연결 실패 시 예외 발생.

## 요청 처리 파이프라인

```
HTTP → JwtAuthenticationFilter(Security) → AuthInterceptor → RateLimitInterceptor(/api/**) → QueueInterceptor(/seat/**,/api/seats/**) → Controller
```

- `AuthInterceptor`: JWT 쿠키 파싱 → request attribute에 `loginMemberId` 등 설정
- `QueueInterceptor`: Redis에서 대기열 통과 여부 확인. 미통과 시 `/queue/waiting?scheduleId=` 리다이렉트
- `RateLimitInterceptor`: GET 요청은 스킵. POST/PUT/DELETE만 체크

## 좌석 선점 Dual-Defense 패턴

1. Redis SETNX (빠른 선점) — Lua 스크립트로 원자 실행
2. DB `WHERE status = 'AVAILABLE'` UPDATE (Redis 장애 대비)

두 방어선 모두 `SeatService`에 구현. Redis 장애 시 DB-only 모드로 자동 강등.

## 공개 URL (인증 불필요)

`security-context.xml` 기준:
```
/, /member/login, /member/join/**, /member/api/login, /member/api/join
/performance/list, /performance/detail/**, /api/performances/**
/queue/**, /api/queue/**
/css/**, /js/**, /images/**, /resources/**
```

## ticket-user 전용 클래스 (common에 없음)

- `service/`: PerformanceService, SeatService, QueueService, PaymentService
- `repository/`: PaymentMapper (+PaymentMapper.xml)
- `dto/response/`: QueuePositionResponse, SeatHoldResult, SeatStatusResponse
- `web/filter/`: JwtAuthenticationFilter, AjaxAwareAuthEntryPoint
- `web/interceptor/`: AuthInterceptor, RateLimitInterceptor, QueueInterceptor
- `web/support/`: @AuthMember, LoginUser, AuthMemberArgumentResolver
