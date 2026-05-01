package com.ticketlegacy.exception;

import lombok.Getter;
import lombok.AllArgsConstructor;

@Getter @AllArgsConstructor
public enum ErrorCode {
    // 좌석
    SEAT_ALREADY_HELD("SEAT_001", "이미 선점된 좌석입니다.", 409),
    SEAT_NOT_AVAILABLE("SEAT_002", "선택할 수 없는 좌석입니다.", 400),
    SEAT_HOLD_EXPIRED("SEAT_003", "선점 시간이 만료되었습니다.", 410),
    // 결제
    PAYMENT_DUPLICATE("PAY_001", "이미 처리된 결제입니다.", 409),
    PAYMENT_FAILED("PAY_002", "결제에 실패했습니다.", 500),
    PAYMENT_AMOUNT_MISMATCH("PAY_003", "결제 금액이 일치하지 않습니다.", 400),
    // 공연/회차
    PERFORMANCE_NOT_FOUND("PERF_001", "공연을 찾을 수 없습니다.", 404),
    SCHEDULE_NOT_FOUND("PERF_002", "회차를 찾을 수 없습니다.", 404),
    PERFORMANCE_NOT_EDITABLE("PERF_003", "수정할 수 없는 상태의 공연입니다. (DRAFT 상태만 수정 가능)", 400),
    PERFORMANCE_APPROVAL_INVALID("PERF_004", "잘못된 승인 상태 전환입니다.", 400),
    PERFORMANCE_FORBIDDEN("PERF_005", "해당 공연에 대한 접근 권한이 없습니다.", 403),
    PERFORMANCE_STATUS_INVALID_TRANSITION("PERF_006", "허용되지 않는 공연 상태 전환입니다.", 400),
    // 회원
    MEMBER_NOT_FOUND("MBR_001", "회원을 찾을 수 없습니다.", 404),
    MEMBER_STATUS_INVALID_TRANSITION("MBR_002", "허용되지 않는 상태 전환입니다.", 400),
    MEMBER_ALREADY_WITHDRAWN("MBR_003", "이미 탈퇴한 회원입니다.", 409),
    MEMBER_CANNOT_MODIFY_SELF("MBR_004", "본인 계정의 상태는 변경할 수 없습니다.", 403),
    // 기획사
    PROMOTER_NOT_FOUND("PRO_001", "기획사를 찾을 수 없습니다.", 404),
    PROMOTER_NOT_APPROVED("PRO_002", "승인되지 않은 기획사 계정입니다.", 403),
    PROMOTER_ALREADY_REGISTERED("PRO_003", "이미 등록된 기획사입니다.", 409),
    PROMOTER_SUSPENDED("PRO_004", "정지된 기획사 계정입니다.", 403),
    PROMOTER_STATUS_INVALID_TRANSITION("PRO_005", "허용되지 않는 기획사 상태 전환입니다.", 400),
    // 공연장 담당자
    VENUE_MANAGER_NOT_FOUND("VM_001", "공연장 담당자 정보를 찾을 수 없습니다.", 404),
    VENUE_MANAGER_NOT_APPROVED("VM_002", "승인되지 않은 공연장 담당자 계정입니다.", 403),
    VENUE_MANAGER_FORBIDDEN("VM_003", "담당하지 않는 공연장입니다.", 403),
    SECTION_IN_USE("VM_004", "공연에 사용 중인 구역은 삭제할 수 없습니다.", 409),
    VENUE_MANAGER_STATUS_INVALID_TRANSITION("VM_005", "허용되지 않는 공연장 담당자 상태 전환입니다.", 400),
    // 예약
    RESERVATION_NOT_FOUND("RSV_001", "예약을 찾을 수 없습니다.", 404),
    RESERVATION_CANCEL_FAILED("RSV_002", "예약 취소에 실패했습니다.", 400),
    // 쿠폰
    COUPON_NOT_FOUND("CPN_001", "쿠폰을 찾을 수 없습니다.", 404),
    COUPON_ALREADY_USED("CPN_002", "이미 사용된 쿠폰입니다.", 409),
    COUPON_EXPIRED("CPN_003", "만료된 쿠폰입니다.", 410),
    COUPON_INVALID("CPN_004", "사용할 수 없는 쿠폰입니다.", 400),
    // 공지
    NOTICE_NOT_FOUND("NTC_001", "공지사항을 찾을 수 없습니다.", 404),
    // 대기열
    QUEUE_NOT_PASSED("QUEUE_001", "대기열을 통과하지 않았습니다.", 403),
    // 인증
    AUTH_REQUIRED("AUTH_001", "로그인이 필요합니다.", 401),
    AUTH_FORBIDDEN("AUTH_002", "접근 권한이 없습니다.", 403),
    AUTH_LOGIN_FAILED("AUTH_003", "이메일 또는 비밀번호가 일치하지 않습니다.", 401),
    AUTH_EMAIL_DUPLICATE("AUTH_004", "이미 사용 중인 이메일입니다.", 409),
    AUTH_PENDING_APPROVAL("AUTH_005", "승인 대기 중인 계정입니다. 관리자 승인 후 로그인 가능합니다.", 403),
    // 공통
    RATE_LIMITED("COMMON_001", "요청이 너무 많습니다. 잠시 후 다시 시도해주세요.", 429),
    INVALID_INPUT("COMMON_002", "입력값이 올바르지 않습니다.", 400),
    INTERNAL_ERROR("COMMON_999", "서버 내부 오류입니다.", 500);

    private final String code;
    private final String message;
    private final int httpStatus;
}
