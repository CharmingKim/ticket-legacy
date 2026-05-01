package com.ticketlegacy.domain;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor
public class Payment {
    private Long id;
    private Long reservationId;
    private Long memberId;
    private int amount;
    private Long couponId;
    private int discountAmount;
    private int finalAmount;
    private String method;
    private String status;
    private String idempotencyKey;
    private String pgTransactionId;
    private String failReason;
    private LocalDateTime createdAt;
    private LocalDateTime completedAt;

    public Long getPaymentId()      { return id; }
    public void setPaymentId(Long v) { this.id = v; }
}
