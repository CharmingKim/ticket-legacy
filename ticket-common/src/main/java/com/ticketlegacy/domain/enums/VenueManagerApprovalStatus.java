package com.ticketlegacy.domain.enums;

public enum VenueManagerApprovalStatus {
    PENDING, APPROVED, REJECTED;

    public boolean canTransitionTo(VenueManagerApprovalStatus next) {
        switch (this) {
            case PENDING:  return next == APPROVED || next == REJECTED;
            case APPROVED: return next == REJECTED;
            case REJECTED: return false;
            default:       return false;
        }
    }
}
