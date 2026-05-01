package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor
public class MemberSanction {
    private Long          sanctionId;
    private Long          memberId;
    private String        sanctionType;  // SUSPENDED, WITHDRAWN
    private String        reason;
    private Long          sanctionedBy;
    private LocalDateTime sanctionedAt;
    private LocalDateTime liftedAt;
    private Long          liftedBy;
    private String        liftReason;
}
