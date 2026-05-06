package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
public class Faq {
    private Long faqId;
    private String category; // GENERAL|PAYMENT|REFUND|TICKET|ACCOUNT|OTHER
    private String question;
    private String answer;
    private Integer sortOrder;
    private Boolean isActive;
    private LocalDateTime createdAt;
}
