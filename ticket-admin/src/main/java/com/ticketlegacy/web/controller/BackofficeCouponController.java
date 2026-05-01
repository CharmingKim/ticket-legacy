package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.CouponTemplate;
import com.ticketlegacy.domain.Notice;
import com.ticketlegacy.service.CouponService;
import com.ticketlegacy.service.NoticeService;
import com.ticketlegacy.service.PromoterService;
import com.ticketlegacy.web.support.AuthMember;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 백오피스 — 쿠폰/공지사항 관리 컨트롤러.
 * URL: /backoffice/super/coupon/** 및 /backoffice/super/notice/**
 * security-context.xml: /backoffice/super/** → hasRole('SUPER_ADMIN')
 */
@Controller
@RequestMapping("/backoffice/super")
public class BackofficeCouponController {

    @Autowired private CouponService  couponService;
    @Autowired private NoticeService  noticeService;
    @Autowired private PromoterService promoterService;

    // ─────────────────────────────────────────────
    // 쿠폰 템플릿 관리
    // ─────────────────────────────────────────────

    /** datetime-local 입력은 초가 없는 "yyyy-MM-dd'T'HH:mm" 형식으로 옴 */
    private LocalDateTime parseDateTime(String s) {
        if (s == null || s.isBlank()) return null;
        if (s.length() == 16) s = s + ":00";
        return LocalDateTime.parse(s);
    }

    @GetMapping("/coupons")
    public String couponPage(Model model) {
        model.addAttribute("templates", couponService.findAllTemplates(null, null));
        model.addAttribute("promoters", promoterService.findApprovedSummaries());
        return "backoffice/super/coupons";
    }

    @GetMapping("/api/coupons/templates")
    @ResponseBody
    public ResponseEntity<?> listTemplates(
            @RequestParam(required = false) Long promoterId,
            @RequestParam(required = false) Boolean isActive) {
        return ResponseEntity.ok(couponService.findAllTemplates(promoterId, isActive));
    }

    @PostMapping("/api/coupons/templates")
    @ResponseBody
    public ResponseEntity<?> createTemplate(@RequestBody Map<String, Object> body) {
        CouponTemplate t = new CouponTemplate();
        t.setCodePrefix((String) body.get("codePrefix"));
        t.setName((String) body.get("name"));
        t.setDiscountType((String) body.getOrDefault("discountType", "FIXED"));
        t.setDiscountValue(((Number) body.get("discountValue")).intValue());
        t.setMinAmount(body.get("minAmount") != null ? ((Number) body.get("minAmount")).intValue() : 0);
        t.setMaxDiscount(body.get("maxDiscount") != null ? ((Number) body.get("maxDiscount")).intValue() : null);
        t.setTotalQuantity(body.get("totalQuantity") != null ? ((Number) body.get("totalQuantity")).intValue() : 100);
        t.setValidFrom(parseDateTime((String) body.get("validFrom")));
        t.setValidUntil(parseDateTime((String) body.get("validUntil")));
        if (body.get("promoterId") != null) t.setPromoterId(((Number) body.get("promoterId")).longValue());
        if (body.get("performanceId") != null) t.setPerformanceId(((Number) body.get("performanceId")).longValue());
        couponService.createTemplate(t);
        return ResponseEntity.ok(Map.of("templateId", t.getTemplateId(), "message", "쿠폰 템플릿이 생성되었습니다."));
    }

    @PostMapping("/api/coupons/templates/{templateId}/issue")
    @ResponseBody
    public ResponseEntity<?> issueCoupon(@PathVariable Long templateId,
                                          @RequestBody Map<String, Object> body) {
        Long memberId = ((Number) body.get("memberId")).longValue();
        var coupon = couponService.issueCoupon(templateId, memberId);
        return ResponseEntity.ok(Map.of("couponCode", coupon.getCouponCode(),
                "message", "쿠폰이 발급되었습니다: " + coupon.getCouponCode()));
    }

    @PostMapping("/api/coupons/templates/{templateId}/deactivate")
    @ResponseBody
    public ResponseEntity<?> deactivateTemplate(@PathVariable Long templateId) {
        couponService.deactivateTemplate(templateId);
        return ResponseEntity.ok(Map.of("message", "쿠폰 템플릿이 비활성화되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 공지사항 관리
    // ─────────────────────────────────────────────

    @GetMapping("/notices")
    public String noticePage(Model model) {
        model.addAttribute("notices", noticeService.findAll(null, 1));
        return "backoffice/super/notices";
    }

    @GetMapping("/api/notices")
    @ResponseBody
    public ResponseEntity<?> listNotices(
            @RequestParam(required = false) String noticeType,
            @RequestParam(defaultValue = "1") int page) {
        List<Notice> list  = noticeService.findAll(noticeType, page);
        int          total = noticeService.countAll(noticeType);
        return ResponseEntity.ok(Map.of("list", list, "total", total, "page", page));
    }

    @PostMapping("/api/notices")
    @ResponseBody
    public ResponseEntity<?> createNotice(@RequestBody Map<String, Object> body,
                                           @AuthMember Long adminMemberId) {
        Notice n = new Notice();
        n.setTitle((String) body.get("title"));
        n.setContent((String) body.get("content"));
        n.setNoticeType((String) body.getOrDefault("noticeType", "SYSTEM"));
        n.setTargetRole((String) body.getOrDefault("targetRole", "ALL"));
        n.setPinned(Boolean.TRUE.equals(body.get("isPinned")));
        n.setAuthorMemberId(adminMemberId);
        noticeService.create(n);
        return ResponseEntity.ok(Map.of("noticeId", n.getNoticeId(), "message", "공지사항이 등록되었습니다."));
    }

    @PatchMapping("/api/notices/{noticeId}")
    @ResponseBody
    public ResponseEntity<?> updateNotice(@PathVariable Long noticeId,
                                           @RequestBody Map<String, Object> body) {
        Notice n = noticeService.findById(noticeId);
        if (body.containsKey("title"))      n.setTitle((String) body.get("title"));
        if (body.containsKey("content"))    n.setContent((String) body.get("content"));
        if (body.containsKey("isPinned"))   n.setPinned(Boolean.TRUE.equals(body.get("isPinned")));
        if (body.containsKey("targetRole")) n.setTargetRole((String) body.get("targetRole"));
        noticeService.update(n);
        return ResponseEntity.ok(Map.of("message", "공지사항이 수정되었습니다."));
    }

    @DeleteMapping("/api/notices/{noticeId}")
    @ResponseBody
    public ResponseEntity<?> deleteNotice(@PathVariable Long noticeId) {
        noticeService.deactivate(noticeId);
        return ResponseEntity.ok(Map.of("message", "공지사항이 삭제되었습니다."));
    }
}
