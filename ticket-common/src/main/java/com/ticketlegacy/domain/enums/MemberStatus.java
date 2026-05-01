package com.ticketlegacy.domain.enums;

/**
 * 회원 상태 FSM.
 *
 * 허용 전환:
 *   PENDING_APPROVAL → ACTIVE      (어드민 승인)
 *   PENDING_APPROVAL → SUSPENDED   (어드민 반려/즉시 정지)
 *   ACTIVE           → SUSPENDED   (어드민 정지)
 *   ACTIVE           → WITHDRAWN   (강제 탈퇴)
 *   ACTIVE           → DORMANT     (장기 미접속 시스템 전환)
 *   SUSPENDED        → ACTIVE      (정지 해제)
 *   SUSPENDED        → WITHDRAWN   (강제 탈퇴)
 *   DORMANT          → ACTIVE      (재로그인 시 자동 복귀)
 *   WITHDRAWN        → (없음)      terminal
 */
public enum MemberStatus {
    PENDING_APPROVAL,
    ACTIVE,
    SUSPENDED,
    DORMANT,
    WITHDRAWN;

    public boolean canTransitionTo(MemberStatus next) {
        switch (this) {
            case PENDING_APPROVAL:
                return next == ACTIVE || next == SUSPENDED;
            case ACTIVE:
                return next == SUSPENDED || next == WITHDRAWN || next == DORMANT;
            case SUSPENDED:
                return next == ACTIVE || next == WITHDRAWN;
            case DORMANT:
                return next == ACTIVE;
            case WITHDRAWN:
                return false;
            default:
                return false;
        }
    }
}
