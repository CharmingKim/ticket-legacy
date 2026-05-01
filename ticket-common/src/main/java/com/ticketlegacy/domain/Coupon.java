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
    public LocalDateTime getExpiryDate() { return expiresAt; }

    /** UI 표기용 — PERCENT/FIXED 구분해서 사람이 읽는 텍스트로 변환 */
    public String getDiscountText() {
        if ("PERCENT".equals(discountType)) {
            String s = discountValue + "%";
            if (maxDiscount != null && maxDiscount > 0) s += " (최대 " + String.format("%,d", maxDiscount) + "원)";
            return s;
        }
        return String.format("%,d", discountValue) + "원";
    }

    /** 결제금액 기준 실제 할인액 계산 (서버측 검증과 동일 로직) */
    public int calculateDiscount(int amount) {
        if (amount < minAmount) return 0;
        if ("PERCENT".equals(discountType)) {
            int d = (int) Math.round(amount * discountValue / 100.0);
            return maxDiscount != null ? Math.min(d, maxDiscount) : d;
        }
        return Math.min(discountValue, amount);
    }
}
