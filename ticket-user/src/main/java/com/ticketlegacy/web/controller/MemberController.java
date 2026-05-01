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

    @GetMapping("/member/mypage")
    public String mypage() {
        return "member/mypage";
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
