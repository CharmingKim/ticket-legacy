package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
public class Inquiry {
    private Long inquiryId;
    private Long memberId;
    private String category; // GENERAL|PAYMENT|REFUND|TICKET|ACCOUNT|OTHER
    private String title;
    private String content;
    private String status; // PENDING|ANSWERED|CLOSED
    private String answer;
    private Long answeredBy;
    private LocalDateTime answeredAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
