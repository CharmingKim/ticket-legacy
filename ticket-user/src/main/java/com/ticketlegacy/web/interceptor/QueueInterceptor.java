package com.ticketlegacy.web.interceptor;

import com.ticketlegacy.service.QueueService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class QueueInterceptor implements HandlerInterceptor {
    private static final Logger log = LoggerFactory.getLogger(QueueInterceptor.class);

    @Autowired private QueueService queueService;

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) throws Exception {
        Long scheduleId = extractScheduleId(request);
        Long memberId = (Long) request.getAttribute("loginMemberId");

        if (scheduleId == null || memberId == null) return true;

        boolean passed = queueService.hasPassed(scheduleId, memberId);
        if (!passed) {
            log.info("대기열 미통과 처리: memberId={}, scheduleId={}", memberId, scheduleId);
            String ajaxHeader = request.getHeader("X-Requested-With");
            if ("XMLHttpRequest".equals(ajaxHeader) || request.getRequestURI().startsWith("/api/")) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"error\":\"대기열 세션이 만료되었거나 올바르지 않은 접근입니다.\"}");
            } else {
                response.sendRedirect("/queue/waiting?scheduleId=" + scheduleId);
            }
            return false;
        }
        return true;
    }

    private Long extractScheduleId(HttpServletRequest request) {
        String uri = request.getRequestURI();
        try {
            if (uri.startsWith("/api/seats/hold/")) {
                String[] parts = uri.split("/");
                return Long.parseLong(parts[4]);
            } else if (uri.startsWith("/api/seats/") || uri.startsWith("/seat/select/")) {
                String[] parts = uri.split("/");
                return Long.parseLong(parts[parts.length - 1]);
            }
            String param = request.getParameter("scheduleId");
            return param != null ? Long.parseLong(param) : null;
        } catch (Exception e) {
            return null;
        }
    }
}
