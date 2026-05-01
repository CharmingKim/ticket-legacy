package com.ticketlegacy.domain.enums;

public enum PerformanceApprovalStatus {
    DRAFT, REVIEW, APPROVED, REJECTED, PUBLISHED;

    public boolean canTransitionTo(PerformanceApprovalStatus next) {
        switch (this) {
            case DRAFT:     return next == REVIEW;
            case REVIEW:    return next == APPROVED || next == REJECTED;
            case APPROVED:  return next == PUBLISHED || next == DRAFT;
            case REJECTED:  return next == REVIEW    || next == DRAFT;
            case PUBLISHED: return false;
            default:        return false;
        }
    }
}
