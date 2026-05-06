package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.Coupon;
import com.ticketlegacy.domain.Notice;
import com.ticketlegacy.domain.Reservation;
import com.ticketlegacy.dto.request.LoginRequest;
import com.ticketlegacy.dto.request.MemberJoinRequest;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.service.CouponService;
import com.ticketlegacy.service.MemberService;
import com.ticketlegacy.service.NoticeService;
import com.ticketlegacy.service.ReservationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.validation.Valid;
import java.util.List;
import java.util.Map;

@Controller
public class MemberController {

    @Autowired private MemberService memberService;
    @Autowired private CouponService couponService;
    @Autowired private NoticeService noticeService;
    @Autowired private ReservationService reservationService;
    @Autowired private com.ticketlegacy.service.WishlistService wishlistService;
    @Autowired private com.ticketlegacy.service.ReviewService reviewService;
    @Autowired private com.ticketlegacy.service.InquiryService inquiryService;

    @GetMapping("/member/login")
    public String loginPage() {
        return "member/login";
    }

    @GetMapping("/member/join")
    public String joinPage() {
        return "member/join";
    }

    @PostMapping("/api/member/join")
    @ResponseBody
    public ApiResponse<String> join(@RequestBody @Valid MemberJoinRequest request) {
        memberService.join(request);
        return ApiResponse.success("Member registration completed.");
    }

    @PostMapping("/api/member/login")
    @ResponseBody
    public ApiResponse<Map<String, String>> login(@RequestBody @Valid LoginRequest request,
                                                  HttpServletResponse response) {
        MemberService.LoginResult result = memberService.login(request);

        Cookie cookie = new Cookie("USER_TOKEN", result.token);
        cookie.setHttpOnly(true);
        cookie.setPath("/");
        cookie.setMaxAge(60 * 60 * 2);
        response.addCookie(cookie);

        Map<String, String> data = Map.of(
                "message", "Login successful.",
                "role", result.role,
                "name", result.name,
                "redirectUrl", result.redirectUrl
        );
        return ApiResponse.success(data);
    }

    @PostMapping("/api/member/logout")
    @ResponseBody
    public ApiResponse<String> logout(HttpServletResponse response) {
        Cookie cookie = new Cookie("USER_TOKEN", null);
        cookie.setHttpOnly(true);
        cookie.setPath("/");
        cookie.setMaxAge(0);
        response.addCookie(cookie);
        return ApiResponse.success("Logout completed.");
    }

    // ──────────────────────────────────────────
    // 마이페이지 - 회원 정보 관리
    // ──────────────────────────────────────────

    @GetMapping("/member/change-password")
    public String changePasswordPage() {
        return "member/change-password";
    }

    @PostMapping("/api/member/change-password")
    @ResponseBody
    public ApiResponse<String> changePassword(@RequestBody Map<String, String> request, HttpServletRequest req, HttpServletResponse res) {
        Long memberId = (Long) req.getAttribute("loginMemberId");
        memberService.changePassword(memberId, request.get("currentPassword"), request.get("newPassword"));
        
        // 비밀번호 변경 성공 시 자동 로그아웃 처리
        Cookie cookie = new Cookie("USER_TOKEN", null);
        cookie.setHttpOnly(true);
        cookie.setPath("/");
        cookie.setMaxAge(0);
        res.addCookie(cookie);
        
        return ApiResponse.success("비밀번호가 변경되었습니다. 다시 로그인해주세요.");
    }

    @GetMapping("/member/edit")
    public String editProfilePage() {
        return "member/edit-profile";
    }

    @PostMapping("/api/member/update")
    @ResponseBody
    public ApiResponse<String> updateProfile(@RequestBody Map<String, String> request, HttpServletRequest req) {
        Long memberId = (Long) req.getAttribute("loginMemberId");
        memberService.updateProfile(memberId, request.get("name"), request.get("phone"));
        return ApiResponse.success("회원정보가 수정되었습니다.");
    }

    @GetMapping("/member/withdraw")
    public String withdrawPage() {
        return "member/withdraw";
    }

    @PostMapping("/api/member/withdraw")
    @ResponseBody
    public ApiResponse<String> withdraw(@RequestBody Map<String, String> request, HttpServletRequest req, HttpServletResponse res) {
        Long memberId = (Long) req.getAttribute("loginMemberId");
        memberService.withdraw(memberId, request.get("password"), request.get("reason"));
        
        // 탈퇴 성공 시 자동 로그아웃 처리
        Cookie cookie = new Cookie("USER_TOKEN", null);
        cookie.setHttpOnly(true);
        cookie.setPath("/");
        cookie.setMaxAge(0);
        res.addCookie(cookie);
        
        return ApiResponse.success("회원 탈퇴가 완료되었습니다.");
    }

    @GetMapping("/member/mypage")
    public String mypage(HttpServletRequest req, org.springframework.ui.Model model) {
        Long memberId = (Long) req.getAttribute("loginMemberId");
        if (memberId == null) return "redirect:/member/login";

        // 최근 예매 (5건)
        List<Reservation> recentRes = reservationService.findByMemberWithStatus(memberId, null, 1, 5);
        
        // 쿠폰 목록
        List<Coupon> coupons = couponService.findByMemberId(memberId);
        
        // 통계 데이터
        int resCount = reservationService.countByMemberWithStatus(memberId, "CONFIRMED");
        int couponCount = coupons.size();
        int wishCount = wishlistService.getWishlist(memberId).size();
        int reviewCount = reviewService.countByMemberId(memberId);
        int inquiryCount = inquiryService.getMyInquiryCount(memberId);

        model.addAttribute("recentReservations", recentRes);
        model.addAttribute("coupons", coupons);
        model.addAttribute("resCount", resCount);
        model.addAttribute("couponCount", couponCount);
        model.addAttribute("wishCount", wishCount);
        model.addAttribute("reviewCount", reviewCount);
        model.addAttribute("inquiryCount", inquiryCount);

        return "member/mypage";
    }

    @GetMapping("/member/coupons")
    public String couponsPage(HttpServletRequest req, org.springframework.ui.Model model) {
        Long memberId = (Long) req.getAttribute("loginMemberId");
        if (memberId == null) return "redirect:/member/login";
        model.addAttribute("coupons", couponService.findByMemberId(memberId));
        return "member/coupons";
    }

    @GetMapping("/api/member/coupons")
    @ResponseBody
    public ApiResponse<List<Coupon>> myCoupons(HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        return ApiResponse.success(couponService.findByMemberId(memberId));
    }

    @GetMapping("/api/coupons/validate")
    @ResponseBody
    public ApiResponse<Map<String, Object>> validateCoupon(
            @RequestParam String code,
            @RequestParam int amount,
            HttpServletRequest request) {
        int discount = couponService.validateAndCalculateDiscount(code, amount);
        return ApiResponse.success(Map.of(
            "discount", discount,
            "finalAmount", Math.max(0, amount - discount),
            "message", "쿠폰 적용 가능: " + discount + "원 할인"
        ));
    }

    @GetMapping("/api/notices/public")
    @ResponseBody
    public ApiResponse<List<Notice>> publicNotices(HttpServletRequest request) {
        String role = (String) request.getAttribute("loginRole");
        String targetRole = role != null ? role : "USER";
        return ApiResponse.success(noticeService.findActiveForRole(targetRole));
    }

    @GetMapping("/api/member/reservations")
    @ResponseBody
    public ApiResponse<Map<String, Object>> myReservations(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(required = false) String status,
            HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        List<Reservation> list  = reservationService.findByMemberWithStatus(memberId, status, page, 10);
        int               total = reservationService.countByMemberWithStatus(memberId, status);
        return ApiResponse.success(Map.of("list", list, "total", total, "page", page));
    }
}
