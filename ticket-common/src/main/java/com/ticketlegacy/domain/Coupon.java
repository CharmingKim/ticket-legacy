package com.ticketlegacy.domain;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class Coupon {
    private Long couponId;
    private Long templateId;
    private Long memberId;
    private String couponCode;
    private String status;          // ISSUED | USED | EXPIRED | CANCELLED
    private LocalDateTime usedAt;
    private Long reservationId;
    private LocalDateTime issuedAt;
    private LocalDateTime expiresAt;

    // 조인 필드
    private String templateName;
    private String discountType;
    private int discountValue;
    private int minAmount;
    private Integer maxDiscount;
    private String memberName;
    private String memberEmail;

    // JSP alias getters
    public String getCouponName()    { return templateName; }
    public int    getDiscountAmount(){ return discountValue; }
    public LocalDateTime getExpiryDate() { return expiresAt; }
}
