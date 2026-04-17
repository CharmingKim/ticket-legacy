package com.ticketlegacy.web.controller;

import com.ticketlegacy.service.CouponService;
import com.ticketlegacy.service.NoticeService;
import com.ticketlegacy.web.support.LoginUser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 파트너 포털 — 기획사 쿠폰/공지 조회
 * URL: /partner/promoter/coupons, /partner/promoter/notices
 */
@Controller
@RequestMapping("/partner/promoter")
public class PartnerCouponController {

    @Autowired private CouponService couponService;
    @Autowired private NoticeService noticeService;

    private Long currentPromoterId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return ((LoginUser) auth.getPrincipal()).getPromoterId();
    }

    // ─────────────────────────────────────────────
    // 쿠폰
    // ─────────────────────────────────────────────

    /** 내 기획사에서 사용된 쿠폰 목록 (읽기 전용) */
    @GetMapping("/api/coupons/templates")
    @ResponseBody
    public ResponseEntity<?> myTemplates() {
        Long promoterId = currentPromoterId();
        return ResponseEntity.ok(couponService.findAllTemplates(promoterId, true));
    }

    // ─────────────────────────────────────────────
    // 공지사항 (파트너 읽기 전용)
    // ─────────────────────────────────────────────

    /** 파트너 포털 공지사항 뷰 페이지 */
    @GetMapping("/notices")
    public String noticesPage(
            @RequestParam(required = false) String noticeType,
            @RequestParam(defaultValue = "1") int page,
            org.springframework.ui.Model model) {
        model.addAttribute("notices", noticeService.findActiveForRole("PROMOTER"));
        model.addAttribute("page", page);
        return "partner/promoter/notices";
    }

    /** 파트너용 공지사항 API (PROMOTER/ALL 대상) */
    @GetMapping("/api/notices")
    @ResponseBody
    public ResponseEntity<?> partnerNotices() {
        return ResponseEntity.ok(noticeService.findActiveForRole("PROMOTER"));
    }
}
