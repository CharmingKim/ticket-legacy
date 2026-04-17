package com.ticketlegacy.service;

import com.ticketlegacy.domain.Member;
import com.ticketlegacy.domain.Promoter;
import com.ticketlegacy.domain.VenueManager;
import com.ticketlegacy.dto.request.LoginRequest;
import com.ticketlegacy.dto.request.MemberJoinRequest;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.repository.MemberMapper;
import com.ticketlegacy.repository.PromoterMapper;
import com.ticketlegacy.repository.VenueManagerMapper;
import com.ticketlegacy.util.JwtUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
public class MemberService {

    @Autowired private MemberMapper         memberMapper;
    @Autowired private PromoterMapper       promoterMapper;
    @Autowired private VenueManagerMapper   venueManagerMapper;
    @Autowired private BCryptPasswordEncoder passwordEncoder;
    @Autowired private JwtUtil              jwtUtil;

    // ──────────────────────────────────────────
    // 일반 회원가입
    // ──────────────────────────────────────────

    @Transactional
    public void join(MemberJoinRequest request) {
        if (memberMapper.existsByEmail(request.getEmail()) > 0) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_DUPLICATE);
        }
        Member member = new Member();
        member.setEmail(request.getEmail());
        member.setPassword(passwordEncoder.encode(request.getPassword()));
        member.setName(request.getName());
        member.setPhone(request.getPhone());
        member.setRole("USER");
        memberMapper.insert(member);
        log.info("일반 회원가입: email={}", request.getEmail());
    }

    // ──────────────────────────────────────────
    // 로그인 — 역할별 토큰 + redirectUrl 반환
    // ──────────────────────────────────────────

    @Transactional
    public LoginResult login(LoginRequest request) {
        Member member = memberMapper.findByEmail(request.getEmail());
        if (member == null || !passwordEncoder.matches(request.getPassword(), member.getPassword())) {
            throw new BusinessException(ErrorCode.AUTH_LOGIN_FAILED);
        }
        if ("PENDING_APPROVAL".equals(member.getStatus())) {
            throw new BusinessException(ErrorCode.AUTH_PENDING_APPROVAL);
        }
        if (!"ACTIVE".equals(member.getStatus())) {
            throw new BusinessException(ErrorCode.AUTH_LOGIN_FAILED, "비활성 계정입니다.");
        }
        memberMapper.updateLastLogin(member.getMemberId());

        String token;
        String redirectUrl;

        switch (member.getRole()) {
            case "SUPER_ADMIN":
            case "ADMIN":   // 구 ADMIN도 슈퍼어드민 대시보드로 (이전 호환)
                token = jwtUtil.generateToken(member.getMemberId(), member.getEmail(), "SUPER_ADMIN");
                redirectUrl = "/backoffice/super/dashboard";
                break;

            case "STAFF":
                token = jwtUtil.generateToken(member.getMemberId(), member.getEmail(), "STAFF");
                redirectUrl = "/backoffice/staff/dashboard";
                break;

            case "PROMOTER":
                Promoter promoter = promoterMapper.findByMemberId(member.getMemberId());
                if (promoter == null || !"APPROVED".equals(promoter.getApprovalStatus())) {
                    throw new BusinessException(ErrorCode.PROMOTER_NOT_APPROVED);
                }
                token = jwtUtil.generateToken(
                        member.getMemberId(), member.getEmail(), member.getRole(),
                        promoter.getPromoterId());
                redirectUrl = "/partner/promoter/dashboard";
                break;

            case "VENUE_MANAGER":
                VenueManager vm = venueManagerMapper.findByMemberId(member.getMemberId());
                if (vm == null || !"APPROVED".equals(vm.getApprovalStatus())) {
                    throw new BusinessException(ErrorCode.VENUE_MANAGER_NOT_APPROVED);
                }
                token = jwtUtil.generateToken(
                        member.getMemberId(), member.getEmail(), member.getRole(),
                        null, vm.getVenueId());
                redirectUrl = "/partner/venue/dashboard";
                break;

            default: // USER
                token = jwtUtil.generateToken(member.getMemberId(), member.getEmail(), member.getRole());
                redirectUrl = "/";
        }

        log.info("로그인 성공: memberId={}, role={}", member.getMemberId(), member.getRole());
        return new LoginResult(token, member.getRole(), member.getName(), redirectUrl);
    }

    public Member findById(Long memberId) {
        Member m = memberMapper.findById(memberId);
        if (m == null) throw new BusinessException(ErrorCode.MEMBER_NOT_FOUND);
        return m;
    }

    // ──────────────────────────────────────────
    // 로그인 결과 VO
    // ──────────────────────────────────────────

    public static class LoginResult {
        public final String token;
        public final String role;
        public final String name;
        public final String redirectUrl;

        public LoginResult(String token, String role, String name, String redirectUrl) {
            this.token       = token;
            this.role        = role;
            this.name        = name;
            this.redirectUrl = redirectUrl;
        }
    }
}
