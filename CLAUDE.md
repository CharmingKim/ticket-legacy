# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 토큰 효율 지침 (Claude 작업 원칙)

**파일 읽기**
- 파일 전체가 필요한 경우에만 `Read` 사용. 특정 심볼/패턴 탐색은 반드시 `Grep` 또는 `Glob` 먼저.
- 큰 파일(500줄+)은 `offset`/`limit`으로 필요한 구간만 읽는다.
- 이미 읽은 내용은 재독하지 않는다 — 컨텍스트에 있으면 그대로 사용.

**파일 수정**
- 기존 파일 수정 시 `Edit` 사용 (diff 전송). `Write`는 신규 파일 또는 전면 재작성에만.
- 여러 파일에 걸친 단순 치환은 `replace_all: true` 활용.

**탐색 전략**
- 구조 파악 → `Glob` (패턴 매칭). 심볼 탐색 → `Grep`. 파일 내용 → `Read`.
- 불확실하면 `Grep` 먼저, 히트 확인 후 `Read`.
- 3개 이상의 독립 조회는 병렬 툴콜로 한 번에 처리.

**응답 스타일**
- 작업 중 진행 상황은 한 문장으로. 내부 추론 설명 금지.
- 완료 후 요약: 변경된 것 + 다음 할 것, 2문장 이내.
- 코드 외에 불필요한 설명 추가 금지.

## 프로젝트 구조

Maven 멀티모듈 — 단일 DB를 공유하는 3-WAR 분리 아키텍처.

```
ticket-parent/          ← POM aggregator (버전 관리)
├── ticket-common/      ← 공유 JAR  (도메인·예외·서비스·매퍼)
├── ticket-user/        ← WAR  port 8080  (일반 사용자)
├── ticket-partner/     ← WAR  port 8081  (기획사·공연장 담당자)
└── ticket-admin/       ← WAR  port 8082  (SUPER_ADMIN·STAFF)
```

## 빌드 명령

```bash
# 전체 빌드 (4개 모듈)
mvn clean compile

# 특정 모듈만 (의존 모듈 포함)
mvn clean compile -pl ticket-user -am
mvn clean compile -pl ticket-admin -am
mvn clean compile -pl ticket-partner -am

# WAR 패키징
mvn clean package -pl ticket-user -am

# 서버 실행 (각각 별도 터미널)
mvn tomcat7:run -pl ticket-user    # → http://localhost:8080
mvn tomcat7:run -pl ticket-partner # → http://localhost:8081
mvn tomcat7:run -pl ticket-admin   # → http://localhost:8082
```

## 핵심 제약사항

- **Spring Legacy MVC 5.3** — Spring Boot 아님. `jakarta.*` 패키지 절대 사용 금지, 반드시 `javax.*` 유지
- **Java 11** — record, sealed class 사용 불가
- **JWT secret**: 환경변수 `JWT_SECRET_KEY` (Base64 인코딩). 3개 서버 모두 동일한 값 설정 필요
- **MySQL schema**: `springgreen6` — 3개 모듈이 단일 DB 공유, 각각 독립 HikariCP 풀
- **Redis**: ticket-user만 필수 (localhost:6379). ticket-admin은 선택적, ticket-partner는 미사용

## 모듈 간 의존 관계

```
ticket-user    → ticket-common
ticket-partner → ticket-common
ticket-admin   → ticket-common
ticket-common  → (외부 의존성만)
```

ticket-user ↔ ticket-partner ↔ ticket-admin 간 직접 의존 없음. 공유는 DB + JWT를 통해서만.

## 포털별 진입점

| 모듈 | 포트 | 로그인 URL | 대상 역할 |
|---|---|---|---|
| ticket-user | 8080 | `/member/login` | 일반 회원 |
| ticket-partner | 8081 | `/partner/login` | PROMOTER, VENUE_MANAGER |
| ticket-admin | 8082 | `/admin/login` | SUPER_ADMIN, STAFF |

## JWT 토큰 공유 방식

3개 서버가 동일한 `JWT_SECRET_KEY`로 서명·검증. 사용자가 ticket-user에서 발급받은 JWT를 ticket-partner에서는 사용 불가 — 역할(role) 기반으로 각 포털의 `security-context.xml`에서 차단.

## 코드 변경 전 전수 검색 필수

`ticket-common`의 Service 메서드를 **제거하거나 시그니처를 변경**하기 전에 반드시 3개 WAR 전체에서 해당 메서드명을 검색해 모든 호출처를 확인한다.

- `ticket-common` Service는 `ticket-user` · `ticket-partner` · `ticket-admin` 셋 다 의존
- 한 WAR에서만 확인하면 나머지 WAR에서 컴파일 에러 발생
- 검색 범위: 프로젝트 루트 전체 (`ticket-admin/`, `ticket-partner/`, `ticket-user/` 포함)

## 테스트 계정

| 계정 | 비밀번호 | 포털 |
|---|---|---|
| `user1@test.com` | `Cks159753!` | ticket-user (8080) |
| `promoter1@test.com` | `Cks159753!` | ticket-partner (8081) |
| `venue1@test.com` | `Cks159753!` | ticket-partner (8081) |
| `admin@ticketlegacy.com` | `Cks159753!` | ticket-admin (8082) |
| `staff@ticketlegacy.com` | `Cks159753!` | ticket-admin (8082) |

> 12차 세션(2026-05-06)에서 전 계정 BCrypt 해시 일괄 교체. DB 재주입 시 `schema_total.sql` → `data_total.sql` → `data_extension.sql` 순서.
> BCrypt hash: `$2a$10$uXbsu3ZmwyTylFYvS/YVZuJ3BkeOTSW1wf2YQRxQH0yG9weU8v7MO`
