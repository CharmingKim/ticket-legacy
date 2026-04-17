package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor
public class Promoter {
    private Long promoterId;
    private Long memberId;
    private String companyName;
    private String businessRegNo;
    private String representative;
    private String contactEmail;
    private String contactPhone;
    private String contractDocUrl;
    private String approvalStatus;   // PENDING / APPROVED / REJECTED / SUSPENDED
    private Long approvedBy;
    private LocalDateTime approvedAt;
    private String rejectReason;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // 조인 조회용 (member 정보)
    private String memberEmail;
    private String memberName;
    private String memberPhone;
}
