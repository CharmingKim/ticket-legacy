package com.ticketlegacy.dto.response;

import com.ticketlegacy.domain.Promoter;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class PromoterSummaryDto {

    private final Long          promoterId;
    private final Long          memberId;
    private final String        companyName;
    private final String        businessRegNo;
    private final String        representative;
    private final String        contactEmail;
    private final String        contactPhone;
    private final String        approvalStatus;
    private final LocalDateTime approvedAt;
    private final String        rejectReason;
    private final LocalDateTime createdAt;
    private final String        memberEmail;
    private final String        memberName;
    private final String        memberPhone;

    private PromoterSummaryDto(Promoter p) {
        this.promoterId     = p.getPromoterId();
        this.memberId       = p.getMemberId();
        this.companyName    = p.getCompanyName();
        this.businessRegNo  = p.getBusinessRegNo();
        this.representative = p.getRepresentative();
        this.contactEmail   = p.getContactEmail();
        this.contactPhone   = p.getContactPhone();
        this.approvalStatus = p.getApprovalStatus();
        this.approvedAt     = p.getApprovedAt();
        this.rejectReason   = p.getRejectReason();
        this.createdAt      = p.getCreatedAt();
        this.memberEmail    = p.getMemberEmail();
        this.memberName     = p.getMemberName();
        this.memberPhone    = p.getMemberPhone();
    }

    public static PromoterSummaryDto from(Promoter p) {
        return new PromoterSummaryDto(p);
    }
}
