package com.ticketlegacy.web.interceptor;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.servlet.HandlerInterceptor;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.concurrent.TimeUnit;

public class RateLimitInterceptor implements HandlerInterceptor {
    private static final Logger log = LoggerFactory.getLogger(RateLimitInterceptor.class);
    private static final int MAX_REQUESTS = 30;
    private static final int WINDOW_SECONDS = 60;

    @Autowired private StringRedisTemplate redisTemplate;

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) throws Exception {
        if ("GET".equalsIgnoreCase(request.getMethod())) return true;

        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) return true;

        try {
            String key = "ratelimit:" + memberId + ":" + request.getRequestURI();
            Long count = redisTemplate.opsForValue().increment(key);

            if (count != null && count == 1) {
                redisTemplate.expire(key, WINDOW_SECONDS, TimeUnit.SECONDS);
            }
            if (count != null && count > MAX_REQUESTS) {
                log.warn("Rate limit 초과: memberId={}, URI={}", memberId, request.getRequestURI());
                response.setStatus(429);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write(
                        "{\"success\":false,\"message\":\"요청이 너무 많습니다. 잠시 후 다시 시도해주세요.\",\"errorCode\":\"COMMON_001\"}");
                return false;
            }
        } catch (Exception e) {
            log.warn("Rate Limit Redis 오류 — 통과 처리: {}", e.getMessage());
        }
        return true;
    }
}
