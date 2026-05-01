package com.ticketlegacy.dto.response;

import com.ticketlegacy.domain.VenueManager;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class VenueManagerSummaryDto {

    private final Long          managerId;
    private final Long          memberId;
    private final Long          venueId;
    private final String        department;
    private final String        position;
    private final String        approvalStatus;
    private final LocalDateTime approvedAt;
    private final LocalDateTime createdAt;
    private final String        memberEmail;
    private final String        memberName;
    private final String        memberPhone;
    private final String        venueName;

    private VenueManagerSummaryDto(VenueManager vm) {
        this.managerId      = vm.getManagerId();
        this.memberId       = vm.getMemberId();
        this.venueId        = vm.getVenueId();
        this.department     = vm.getDepartment();
        this.position       = vm.getPosition();
        this.approvalStatus = vm.getApprovalStatus();
        this.approvedAt     = vm.getApprovedAt();
        this.createdAt      = vm.getCreatedAt();
        this.memberEmail    = vm.getMemberEmail();
        this.memberName     = vm.getMemberName();
        this.memberPhone    = vm.getMemberPhone();
        this.venueName      = vm.getVenueName();
    }

    public static VenueManagerSummaryDto from(VenueManager vm) {
        return new VenueManagerSummaryDto(vm);
    }
}
