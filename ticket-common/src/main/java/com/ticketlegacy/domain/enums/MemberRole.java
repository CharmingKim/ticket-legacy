package com.ticketlegacy.domain.enums;

public enum MemberRole {
    USER,
    STAFF,
    SUPER_ADMIN,
    PROMOTER,
    VENUE_MANAGER,
    /** @deprecated 구 ADMIN 역할 — SUPER_ADMIN으로 통합됨. DB 호환 목적으로만 유지. */
    @Deprecated
    ADMIN
}
