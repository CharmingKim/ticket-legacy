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
 * 파트너 포털 전용 로그인.
 * PROMOTER / VENUE_MANAGER 계정만 허용.
 */
@Controller
@RequestMapping("/partner")
public class PartnerLoginController {

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

        if (!"PROMOTER".equals(result.role) && !"VENUE_MANAGER".equals(result.role)) {
            return ResponseEntity.status(403)
                    .body(ApiResponse.error("파트너 계정이 아닙니다."));
        }

        Cookie cookie = new Cookie("PARTNER_TOKEN", result.token);
        cookie.setHttpOnly(true);
        cookie.setPath("/");
        cookie.setMaxAge(60 * 60 * 2);
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
        Cookie cookie = new Cookie("PARTNER_TOKEN", "");
        cookie.setMaxAge(0);
        cookie.setPath("/");
        response.addCookie(cookie);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
