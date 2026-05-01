package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor
public class MemberStatusHistory {
    private Long          historyId;
    private Long          memberId;
    private String        fromStatus;
    private String        toStatus;
    private Long          changedBy;
    private String        reason;
    private LocalDateTime createdAt;
}
