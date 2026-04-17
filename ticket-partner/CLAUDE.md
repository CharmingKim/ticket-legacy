# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 역할

파트너 포털 WAR — 공연 기획사(PROMOTER)와 공연장 담당자(VENUE_MANAGER)의 관리 대시보드. `port 8081`.

## 실행

```bash
# ticket-parent 디렉토리에서
mvn tomcat7:run -pl ticket-partner -am

# 접속: http://localhost:8081/partner/login
# 테스트 계정: promoter1@test.com / user123
```

**사전 조건**: MySQL(`springgreen6`)만 필요. Redis 미사용.

## Redis 미사용

ticket-partner는 Redis Bean이 없음. `root-context.xml`에 `LettuceConnectionFactory` 등록 없음.
공통 서비스의 `ReservationService.redisTemplate`은 `@Autowired(required=false)`이므로 null 허용.

## URL 구조

| 경로 | 역할 | 접근 권한 |
|---|---|---|
| `/partner/login` | 파트너 로그인 페이지 | 공개 |
| `/partner/promoter/**` | 기획사 공연 관리 | PROMOTER |
| `/partner/venue/**` | 공연장·좌석 관리 | VENUE_MANAGER |

## 레거시 URL 정규화

구 프로젝트의 `/promoter/**`, `/venue-manager/**` 경로는 ticket-partner에서 흡수됨:
- `/promoter` → `/partner/promoter`로 통합
- `/venue-manager` → `/partner/venue`로 통합

## ticket-partner 전용 클래스 (common에 없음)

- `service/`: VenueManagerService, EntranceService
- `repository/`: VenueManagerMapper, VenueSeatTemplateMapper, EntranceLogMapper

## 공연 등록 워크플로우 상태머신

```
DRAFT → SUBMITTED → (admin 심사) → APPROVED / REJECTED
```
`PerformanceApprovalService`(common)가 상태 전이 관리. SUBMITTED 이후는 어드민 전용 처리.
기획사는 DRAFT·SUBMITTED 상태만 접근 가능.
