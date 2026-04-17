package com.ticketlegacy.domain;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor
public class Payment {
    private Long paymentId;
    private Long reservationId;
    private String idempotencyKey;
    private int amount;
    private String method;
    private String pgTransactionId;
    private String status;
    private String failureReason;
    private LocalDateTime createdAt;
    private LocalDateTime completedAt;
}
