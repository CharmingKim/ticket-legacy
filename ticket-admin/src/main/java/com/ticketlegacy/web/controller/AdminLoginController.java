package com.ticketlegacy.web.controller;

import com.ticketlegacy.dto.request.LoginRequest;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.service.MemberService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletResponse;
import java.util.Map;

/**
 * 어드민 전용 로그인.
 * SUPER_ADMIN / STAFF 계정만 로그인 가능 (MemberService.login이 redirectUrl로 검증).
 */
@Controller
@RequestMapping("/admin")
public class AdminLoginController {

    @Autowired private MemberService memberService;

    @GetMapping("/login")
    public String loginPage() {
        return "member/login";
    }

    @PostMapping("/api/login")
    @ResponseBody
    public ResponseEntity<ApiResponse<Map<String, String>>> login(
            @RequestBody LoginRequest request,
            HttpServletResponse response) {

        MemberService.LoginResult result = memberService.login(request);

        // 어드민 서버 — SUPER_ADMIN / STAFF 만 허용
        if (!"SUPER_ADMIN".equals(result.role) && !"STAFF".equals(result.role)) {
            return ResponseEntity.status(403)
                    .body(ApiResponse.error("관리자 계정이 아닙니다."));
        }

        Cookie cookie = new Cookie("ACCESS_TOKEN", result.token);
        cookie.setHttpOnly(true);
        cookie.setPath("/");
        cookie.setMaxAge(60 * 60 * 2); // 2시간
        response.addCookie(cookie);

        return ResponseEntity.ok(ApiResponse.success(Map.of(
                "token",       result.token,
                "role",        result.role,
                "name",        result.name,
                "redirectUrl", result.redirectUrl
        )));
    }

    @PostMapping("/api/logout")
    @ResponseBody
    public ResponseEntity<ApiResponse<?>> logout(HttpServletResponse response) {
        Cookie cookie = new Cookie("ACCESS_TOKEN", "");
        cookie.setMaxAge(0);
        cookie.setPath("/");
        response.addCookie(cookie);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
