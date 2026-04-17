package com.ticketlegacy.web.support;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * JWT 파싱 후 SecurityContext에 저장되는 인증 사용자 정보.
 * JwtAuthenticationFilter에서 생성 → @AuthMember ArgumentResolver에서 추출.
 */
@Getter
@AllArgsConstructor
public class LoginUser {
    private final Long   memberId;
    private final String email;
    private final String role;
    private final Long   promoterId;  // PROMOTER 역할일 때만 non-null
    private final Long   venueId;     // VENUE_MANAGER 역할일 때만 non-null
}
