package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Coupon;
import com.ticketlegacy.domain.CouponTemplate;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface CouponMapper {

    // ── 쿠폰 템플릿 ───────────────────────────────
    int insertTemplate(CouponTemplate template);
    CouponTemplate findTemplateById(@Param("templateId") Long templateId);
    List<CouponTemplate> findAllTemplates(@Param("promoterId") Long promoterId,
                                          @Param("isActive") Boolean isActive);
    int updateTemplateActive(@Param("templateId") Long templateId,
                             @Param("isActive") boolean isActive);
    int incrementIssuedCount(@Param("templateId") Long templateId);

    // ── 발급 쿠폰 ─────────────────────────────────
    int insertCoupon(Coupon coupon);
    Coupon findByCode(@Param("couponCode") String couponCode);
    List<Coupon> findByMemberId(@Param("memberId") Long memberId);
    int useCoupon(@Param("couponCode") String couponCode,
                  @Param("reservationId") Long reservationId);
    int expireOverdueCoupons();

    // ── 통계 ──────────────────────────────────────
    int countIssuedByTemplate(@Param("templateId") Long templateId);
    int countUsedByTemplate(@Param("templateId") Long templateId);
}
