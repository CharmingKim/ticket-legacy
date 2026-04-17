package com.ticketlegacy.service;

import com.ticketlegacy.domain.Coupon;
import com.ticketlegacy.domain.CouponTemplate;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.repository.CouponMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * 쿠폰 발급/사용/검증 서비스
 *
 * 비즈니스 규칙:
 *  - 쿠폰은 템플릿 기반으로 발급 (수량 제한)
 *  - 쿠폰 코드는 UUID 기반 고유값 생성
 *  - 만료일 이후 자동 EXPIRED 처리 (스케줄러 연동 필요)
 *  - 1예약 1쿠폰만 사용 가능 (결제 시 검증)
 */
@Slf4j
@Service
public class CouponService {

    @Autowired private CouponMapper couponMapper;

    // ─────────────────────────────────────────────
    // 쿠폰 템플릿 관리
    // ─────────────────────────────────────────────

    @Transactional
    public CouponTemplate createTemplate(CouponTemplate template) {
        couponMapper.insertTemplate(template);
        log.info("쿠폰 템플릿 생성: templateId={}, name={}", template.getTemplateId(), template.getName());
        return template;
    }

    public List<CouponTemplate> findAllTemplates(Long promoterId, Boolean isActive) {
        return couponMapper.findAllTemplates(promoterId, isActive);
    }

    public CouponTemplate findTemplateById(Long templateId) {
        CouponTemplate template = couponMapper.findTemplateById(templateId);
        if (template == null) throw new BusinessException(ErrorCode.INVALID_INPUT, "쿠폰 템플릿을 찾을 수 없습니다.");
        return template;
    }

    @Transactional
    public void deactivateTemplate(Long templateId) {
        couponMapper.updateTemplateActive(templateId, false);
    }

    // ─────────────────────────────────────────────
    // 쿠폰 발급
    // ─────────────────────────────────────────────

    /**
     * 회원에게 쿠폰 1장 발급
     * 수량 초과 / 유효기간 만료 시 예외
     */
    @Transactional
    public Coupon issueCoupon(Long templateId, Long memberId) {
        CouponTemplate template = findTemplateById(templateId);

        if (!template.isActive())
            throw new BusinessException(ErrorCode.INVALID_INPUT, "비활성 쿠폰 템플릿입니다.");
        if (template.getRemainingQuantity() <= 0)
            throw new BusinessException(ErrorCode.INVALID_INPUT, "쿠폰 발급 수량이 모두 소진되었습니다.");
        if (LocalDateTime.now().isAfter(template.getValidUntil()))
            throw new BusinessException(ErrorCode.INVALID_INPUT, "쿠폰 유효기간이 만료되었습니다.");

        // 고유 쿠폰 코드 생성: 접두어 + UUID 앞 8자리
        String code = template.getCodePrefix() + "-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Coupon coupon = new Coupon();
        coupon.setTemplateId(templateId);
        coupon.setMemberId(memberId);
        coupon.setCouponCode(code);
        coupon.setExpiresAt(template.getValidUntil());

        couponMapper.insertCoupon(coupon);
        couponMapper.incrementIssuedCount(templateId);

        log.info("쿠폰 발급: couponCode={}, memberId={}, templateId={}", code, memberId, templateId);
        return coupon;
    }

    // ─────────────────────────────────────────────
    // 쿠폰 조회/검증
    // ─────────────────────────────────────────────

    public List<Coupon> findByMemberId(Long memberId) {
        return couponMapper.findByMemberId(memberId);
    }

    /**
     * 쿠폰 유효성 검증 + 할인 금액 계산
     * @return 할인 금액 (0이면 적용 불가)
     */
    public int validateAndCalculateDiscount(String couponCode, int paymentAmount) {
        Coupon coupon = couponMapper.findByCode(couponCode);
        if (coupon == null) throw new BusinessException(ErrorCode.INVALID_INPUT, "유효하지 않은 쿠폰 코드입니다.");
        if (!"ISSUED".equals(coupon.getStatus()))
            throw new BusinessException(ErrorCode.INVALID_INPUT, "이미 사용되었거나 만료된 쿠폰입니다.");
        if (LocalDateTime.now().isAfter(coupon.getExpiresAt()))
            throw new BusinessException(ErrorCode.INVALID_INPUT, "쿠폰 유효기간이 만료되었습니다.");

        // 임시 CouponTemplate으로 계산
        CouponTemplate t = new CouponTemplate();
        t.setDiscountType(coupon.getDiscountType());
        t.setDiscountValue(coupon.getDiscountValue());
        t.setMinAmount(coupon.getMinAmount());
        t.setMaxDiscount(coupon.getMaxDiscount());

        int discount = t.calculateDiscount(paymentAmount);
        if (discount == 0)
            throw new BusinessException(ErrorCode.INVALID_INPUT,
                "최소 결제 금액(" + coupon.getMinAmount() + "원) 미만으로 쿠폰을 사용할 수 없습니다.");
        return discount;
    }

    // ─────────────────────────────────────────────
    // 쿠폰 사용 처리
    // ─────────────────────────────────────────────

    @Transactional
    public void useCoupon(String couponCode, Long reservationId) {
        int updated = couponMapper.useCoupon(couponCode, reservationId);
        if (updated == 0)
            throw new BusinessException(ErrorCode.INVALID_INPUT, "쿠폰 사용 처리 실패 (이미 사용 or 만료)");
        log.info("쿠폰 사용: couponCode={}, reservationId={}", couponCode, reservationId);
    }

    // ─────────────────────────────────────────────
    // 스케줄러: 만료 쿠폰 일괄 처리
    // ─────────────────────────────────────────────

    @Transactional
    public int expireOverdueCoupons() {
        int count = couponMapper.expireOverdueCoupons();
        if (count > 0) log.info("만료 쿠폰 {} 건 처리 완료", count);
        return count;
    }
}
