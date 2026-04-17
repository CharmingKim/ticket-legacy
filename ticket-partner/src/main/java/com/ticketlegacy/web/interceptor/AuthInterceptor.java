package com.ticketlegacy.web.interceptor;

import com.ticketlegacy.util.JwtUtil;
import io.jsonwebtoken.Claims;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.Arrays;

/**
 * 모든 요청에서 JWT를 파싱하여 request attribute에 주입.
 * 인증 강제는 Spring Security intercept-url에서 처리.
 */
public class AuthInterceptor implements HandlerInterceptor {

    @Autowired private JwtUtil jwtUtil;

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) throws Exception {
        String token = extractTokenFromCookie(request);

        if (token != null && jwtUtil.validateToken(token)) {
            Claims claims = jwtUtil.parseClaims(token);
            Long memberId = claims.get("memberId", Long.class);
            String role   = claims.get("role", String.class);
            String email  = claims.getSubject();

            request.setAttribute("loginMemberId", memberId);
            request.setAttribute("loginRole",     role);
            request.setAttribute("loginEmail",    email);

            // 역할별 식별자 (JSP EL 및 컨트롤러에서 활용)
            Object promoterIdVal = claims.get("promoterId");
            Object venueIdVal    = claims.get("venueId");
            if (promoterIdVal != null) {
                request.setAttribute("loginPromoterId",
                        promoterIdVal instanceof Number
                                ? ((Number) promoterIdVal).longValue()
                                : Long.parseLong(promoterIdVal.toString()));
            }
            if (venueIdVal != null) {
                request.setAttribute("loginVenueId",
                        venueIdVal instanceof Number
                                ? ((Number) venueIdVal).longValue()
                                : Long.parseLong(venueIdVal.toString()));
            }
        }
        return true;
    }

    private String extractTokenFromCookie(HttpServletRequest request) {
        if (request.getCookies() == null) return null;
        return Arrays.stream(request.getCookies())
                .filter(c -> "ACCESS_TOKEN".equals(c.getName()))
                .map(Cookie::getValue)
                .findFirst().orElse(null);
    }
}
