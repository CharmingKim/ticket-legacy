package com.ticketlegacy.util;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Base64;
import java.util.Date;

/**
 * JWT 서명 키는 환경변수 JWT_SECRET_KEY 또는 properties jwt.secret.key 로 주입.
 * 3개 서버(user/partner/admin)가 동일 secret 을 공유해야 토큰 교차 검증 가능.
 * 로컬 개발: jwt-local.properties 에 jwt.secret.key=<base64-256bit> 설정 후 gitignore 처리.
 */
@Component
public class JwtUtil {
    private static final Logger log = LoggerFactory.getLogger(JwtUtil.class);
    private static final long EXPIRATION_MS = 1000L * 60 * 60 * 2; // 2시간

    /**
     * 환경변수 JWT_SECRET_KEY 우선, 없으면 properties jwt.secret.key 사용.
     * 값은 Base64 인코딩된 256bit(32바이트) 이상 문자열이어야 함.
     */
    @Value("${jwt.secret.key:#{null}}")
    private String secretKeyBase64;

    private Key secretKey;

    @PostConstruct
    public void init() {
        if (secretKeyBase64 != null && !secretKeyBase64.isBlank()) {
            byte[] keyBytes = Base64.getDecoder().decode(secretKeyBase64);
            this.secretKey = Keys.hmacShaKeyFor(keyBytes);
            log.info("JwtUtil: 환경변수/properties 에서 JWT secret key 로드 완료");
        } else {
            // 로컬 개발 fallback — 서버 재시작 시마다 키가 변경되므로 단일 서버에서만 허용
            this.secretKey = Keys.secretKeyFor(SignatureAlgorithm.HS256);
            log.warn("JwtUtil: JWT_SECRET_KEY 미설정 — 랜덤 키 사용 (단일 서버 로컬 전용)");
        }
    }

    /** 일반 회원 / SUPER_ADMIN 토큰 생성 */
    public String generateToken(Long memberId, String email, String role) {
        return buildToken(memberId, email, role, null, null);
    }

    /** 기획사(PROMOTER) 토큰 생성 — promoterId 포함 */
    public String generateToken(Long memberId, String email, String role, Long promoterId) {
        return buildToken(memberId, email, role, promoterId, null);
    }

    /** 공연장 담당자(VENUE_MANAGER) 토큰 생성 — venueId 포함 */
    public String generateToken(Long memberId, String email, String role, Long promoterId, Long venueId) {
        return buildToken(memberId, email, role, promoterId, venueId);
    }

    private String buildToken(Long memberId, String email, String role,
                               Long promoterId, Long venueId) {
        Date now = new Date();
        JwtBuilder builder = Jwts.builder()
                .setSubject(email)
                .claim("memberId",   memberId)
                .claim("role",       role)
                .setIssuedAt(now)
                .setExpiration(new Date(now.getTime() + EXPIRATION_MS))
                .signWith(secretKey);
        if (promoterId != null) builder.claim("promoterId", promoterId);
        if (venueId    != null) builder.claim("venueId",    venueId);
        return builder.compact();
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder().setSigningKey(secretKey).build().parseClaimsJws(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            log.debug("JWT 검증 실패: {}", e.getMessage());
            return false;
        }
    }

    public Claims parseClaims(String token) {
        return Jwts.parserBuilder().setSigningKey(secretKey).build()
                .parseClaimsJws(token).getBody();
    }
}
