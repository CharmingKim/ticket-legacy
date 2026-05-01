package com.ticketlegacy.domain.enums;

public enum PromoterApprovalStatus {
    PENDING, APPROVED, REJECTED, SUSPENDED;

    public boolean canTransitionTo(PromoterApprovalStatus next) {
        switch (this) {
            case PENDING:   return next == APPROVED  || next == REJECTED;
            case APPROVED:  return next == SUSPENDED || next == REJECTED;
            case REJECTED:  return false;
            case SUSPENDED: return next == APPROVED  || next == REJECTED;
            default:        return false;
        }
    }
}
