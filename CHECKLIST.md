# TicketLegacy — 테스트 체크리스트

> 테스트 완료 항목은 `- [x]`로 표시.
> 완료된 Phase는 HANDOVER.md §12에 반영 요청.
> 기동: admin `http://localhost:8082` / 계정 `admin@ticketlegacy.com` / `admin123`

---


## Phase B1 — Member 도메인

### 상태 FSM
- [ ] DORMANT 회원 → ACTIVE 변경 → 성공
- [ ] DORMANT 회원 → SUSPENDED 변경 시도 → 400 MEMBER_STATUS_INVALID_TRANSITION

---

## Phase B2 — Promoter 도메인

### 기획사 생성 (member-list 우측 상단 "기획사 추가" 버튼)
- [ ] 필수항목 누락(email 비움) → 클라이언트 경고 또는 400
- [ ] 비밀번호 7자 입력 → 400 "8자 이상"
- [ ] 이미 가입된 이메일 → 409 AUTH_EMAIL_DUPLICATE
- [ ] 정상 입력 → 200, "기획사 계정이 등록되었습니다. (승인 대기)"
- [ ] DB 확인: member.status = PENDING_APPROVAL, promoter.approval_status = PENDING

### 기획사 승인/반려/정지 (대시보드 기획사 탭)
- [ ] PENDING 기획사 → 승인 → 200, member.status = ACTIVE
- [ ] APPROVED 기획사 → 재승인 시도 → 400 PRO_005
- [ ] REJECTED 기획사 → 승인 시도 → 400 PRO_005
- [ ] PENDING 기획사 → 반려 (사유 입력) → 200, member.status = DORMANT
- [ ] 반려 사유 501자 입력 → 400 validation
- [ ] APPROVED 기획사 → 정지 → 200, member.status = DORMANT
- [ ] PENDING 기획사 → 정지 시도 → 400 PRO_005

### 목록 API
- [ ] `GET /backoffice/super/api/promoters` 응답이 `ApiResponse.data.content` 구조
- [ ] `GET /backoffice/super/api/promoters?page=0` → 400 (page 최솟값 1)

### 연동 확인
- [ ] 대시보드 기획사 탭 — promoterId / companyName / approvalStatus 정상 렌더링
- [ ] 정산 페이지 드롭다운 — APPROVED 기획사만 노출

---

## Phase B3 — VenueManager 도메인

### 공연장 담당자 생성 (member-list "공연장담당자 추가" 버튼)
- [ ] 필수항목 누락(venueId 미선택) → 400
- [ ] 비밀번호 7자 → 400 "8자 이상"
- [ ] 이메일 중복 → 409 AUTH_EMAIL_DUPLICATE
- [ ] 정상 입력 → 200, DB: member(PENDING_APPROVAL) + venue_manager(PENDING)

### 승인/반려 FSM (대시보드 공연장담당자 탭)
- [ ] PENDING → 승인 → 200, member.status = ACTIVE
- [ ] APPROVED 상태에서 재승인 시도 → 400 VM_005
- [ ] REJECTED 상태에서 승인 시도 → 400 VM_005
- [ ] PENDING → 반려 → 200, member.status = DORMANT
- [ ] REJECTED 상태에서 반려 시도 → 400 VM_005

### 목록 API
- [ ] `GET /backoffice/super/api/venue-managers` 응답 `ApiResponse.data.content` 구조
- [ ] `GET /backoffice/super/api/venue-managers?status=APPROVED` 필터링
- [ ] `GET /backoffice/super/api/venue-managers?page=0` → 400

### 연동 확인
- [ ] 대시보드 공연장담당자 탭 — managerId / memberName / venueName / approvalStatus 렌더링

---

## Phase B4 — Performance 도메인

### FSM 전환 검증
- [ ] REVIEW 공연 → 승인 → 200
- [ ] DRAFT 공연 → 승인 시도 → 400 PERF_006
- [ ] PUBLISHED 공연 → 재승인 시도 → 400 PERF_006
- [ ] REVIEW 공연 → 반려 (note 포함) → 200
- [ ] APPROVED 공연 → 게시(publish) → 200, status=ON_SALE
- [ ] DRAFT 공연 → 게시 시도 → 400 PERF_006
- [ ] APPROVED 공연 → DRAFT 롤백 → 200

### 목록 API 구조
- [ ] `GET /api/performances?approvalStatus=REVIEW` → `ApiResponse.data.content` 배열
- [ ] 대시보드 공연 심사 탭 — 심사중/승인완료 공연 정상 렌더링 (data.content 구조)
