# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

## 테스트 계정

| 계정 | 비밀번호 | 포털 |
|---|---|---|
| `user1@test.com` | `user123` | ticket-user (8080) |
| `promoter1@test.com` | `user123` | ticket-partner (8081) |
| `admin@ticketlegacy.com` | `admin123` | ticket-admin (8082) |
