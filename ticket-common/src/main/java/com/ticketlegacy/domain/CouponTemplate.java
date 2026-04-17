package com.ticketlegacy.domain;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class CouponTemplate {
    private Long templateId;
    private Long promoterId;
    private Long performanceId;
    private String codePrefix;
    private String name;
    private String discountType;    // FIXED | PERCENT
    private int discountValue;
    private int minAmount;
    private Integer maxDiscount;
    private int totalQuantity;
    private int issuedCount;
    private LocalDateTime validFrom;
    private LocalDateTime validUntil;
    private boolean isActive;
    private LocalDateTime createdAt;

    // 조인 필드
    private String promoterCompanyName;
    private String performanceTitle;

    /** 남은 수량 */
    public int getRemainingQuantity() {
        return Math.max(0, totalQuantity - issuedCount);
    }

    /** 할인 금액 계산 (결제금액 기준) */
    public int calculateDiscount(int amount) {
        if (amount < minAmount) return 0;
        if ("PERCENT".equals(discountType)) {
            int discount = (int) Math.round(amount * discountValue / 100.0);
            return maxDiscount != null ? Math.min(discount, maxDiscount) : discount;
        }
        return Math.min(discountValue, amount); // FIXED, 결제금액 초과 불가
    }
}
