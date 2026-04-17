# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 역할

백오피스 포털 WAR — 내부 직원(STAFF)과 최고 관리자(SUPER_ADMIN)의 운영 대시보드. `port 8082`.

## 실행

```bash
# ticket-parent 디렉토리에서
mvn tomcat7:run -pl ticket-admin -am

# 접속: http://localhost:8082/admin/login
# 테스트 계정: admin@ticketlegacy.com / admin123
```

**사전 조건**: MySQL(`springgreen6`)만 필요. Redis 미사용.

## Redis 미사용

ticket-admin은 Redis Bean 없음. `root-context.xml`에 `LettuceConnectionFactory` 없음.
`ReservationService.redisTemplate = null` — 관련 메서드(좌석 캐시 등)는 graceful degradation 처리됨.

## URL 구조 및 역할 분리

| 경로 | 역할 | 접근 권한 |
|---|---|---|
| `/admin/login` | 관리자 로그인 | 공개 |
| `/backoffice/super/**` | 회원관리·통계·정산·쿠폰 | SUPER_ADMIN |
| `/backoffice/staff/**` | 예매조회·회원조회 | STAFF, SUPER_ADMIN |

## Mapper 직접 주입 금지

`BackofficeSuperController` 등에서 Mapper를 직접 `@Autowired`하지 말 것.
반드시 Service 계층을 통해 접근. 위반 시 트랜잭션 경계 누락 및 AOP 누락 발생.

## Cross-Project 케이스: 강제 탈퇴

어드민에서 회원 강제탈퇴 시 해당 회원의 예매 일괄취소가 필요:
- `ReservationService`(common)를 ticket-admin에서 직접 호출
- 동일 트랜잭션 내 처리 (`@Transactional` on service method)
- ticket-user로 HTTP 요청 불필요 — 동일 DB 공유

## 레거시 URL

`/admin/**`, `/superadmin/**` 경로는 하위 호환용으로 유지 (security-context.xml에서 SUPER_ADMIN 매핑).
신규 기능은 반드시 `/backoffice/**` 하위에 추가.
