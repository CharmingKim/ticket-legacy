package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor
public class VenueManager {
    private Long managerId;
    private Long memberId;
    private Long venueId;
    private String department;
    private String position;
    private String approvalStatus;   // PENDING / APPROVED / REJECTED
    private Long approvedBy;
    private LocalDateTime approvedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // 조인 조회용
    private String memberEmail;
    private String memberName;
    private String memberPhone;
    private String venueName;
}
