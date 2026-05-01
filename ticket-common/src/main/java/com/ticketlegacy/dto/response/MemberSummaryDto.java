package com.ticketlegacy.dto.response;

import com.ticketlegacy.domain.Member;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class MemberSummaryDto {

    private final Long          memberId;
    private final String        email;
    private final String        name;
    private final String        phone;
    private final String        role;
    private final String        status;
    private final LocalDateTime createdAt;
    private final LocalDateTime lastLoginAt;
    private final LocalDateTime withdrawnAt;

    private MemberSummaryDto(Member m) {
        this.memberId    = m.getMemberId();
        this.email       = m.getEmail();
        this.name        = m.getName();
        this.phone       = m.getPhone();
        this.role        = m.getRole();
        this.status      = m.getStatus();
        this.createdAt   = m.getCreatedAt();
        this.lastLoginAt = m.getLastLoginAt();
        this.withdrawnAt = m.getWithdrawnAt();
    }

    public static MemberSummaryDto from(Member m) {
        return new MemberSummaryDto(m);
    }
}
