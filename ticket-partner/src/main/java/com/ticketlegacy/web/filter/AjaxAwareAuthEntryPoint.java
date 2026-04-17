package com.ticketlegacy.web.filter;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;

/**
 * 미인증 요청 처리:
 *  - AJAX 요청 (Accept: application/json 또는 X-Requested-With: XMLHttpRequest) → 401 JSON
 *  - 일반 페이지 요청 → /member/login 으로 리다이렉트
 */
public class AjaxAwareAuthEntryPoint implements AuthenticationEntryPoint {

    private static final ObjectMapper mapper = new ObjectMapper();

    @Override
    public void commence(HttpServletRequest request,
                         HttpServletResponse response,
                         AuthenticationException authException) throws IOException {
        if (isAjaxRequest(request)) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(mapper.writeValueAsString(
                    Map.of("success", false, "message", "로그인이 필요합니다.", "code", "AUTH_REQUIRED")
            ));
        } else {
            response.sendRedirect(request.getContextPath() + "/partner/login");
        }
    }

    private boolean isAjaxRequest(HttpServletRequest request) {
        String accept = request.getHeader("Accept");
        String xrw    = request.getHeader("X-Requested-With");
        String uri    = request.getRequestURI();
        return "XMLHttpRequest".equalsIgnoreCase(xrw)
                || (accept != null && accept.contains("application/json"))
                || (uri != null && uri.contains("/api/"));
    }
}
