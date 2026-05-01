package com.ticketlegacy.web.interceptor;

import com.ticketlegacy.util.JwtUtil;
import io.jsonwebtoken.Claims;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.Arrays;

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
        }
        return true;
    }

    private String extractTokenFromCookie(HttpServletRequest request) {
        if (request.getCookies() == null) return null;
        return Arrays.stream(request.getCookies())
                .filter(c -> "ADMIN_TOKEN".equals(c.getName()))
                .map(Cookie::getValue)
                .findFirst().orElse(null);
    }
}
