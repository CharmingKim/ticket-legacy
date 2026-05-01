package com.ticketlegacy.service;

import com.ticketlegacy.domain.Member;
import com.ticketlegacy.domain.MemberSanction;
import com.ticketlegacy.domain.MemberStatusHistory;
import com.ticketlegacy.domain.Promoter;
import com.ticketlegacy.domain.VenueManager;
import com.ticketlegacy.domain.enums.MemberStatus;
import com.ticketlegacy.dto.request.MemberSearchQuery;
import com.ticketlegacy.dto.response.MemberSummaryDto;
import com.ticketlegacy.dto.response.PageResponse;
import java.util.List;
import java.util.stream.Collectors;
import com.ticketlegacy.dto.request.LoginRequest;
import com.ticketlegacy.dto.request.MemberJoinRequest;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.repository.MemberMapper;
import com.ticketlegacy.repository.MemberSanctionMapper;
import com.ticketlegacy.repository.MemberStatusHistoryMapper;
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

    @Autowired private MemberMapper              memberMapper;
    @Autowired private MemberStatusHistoryMapper historyMapper;
    @Autowired private MemberSanctionMapper      sanctionMapper;
    @Autowired private PromoterMapper            promoterMapper;
    @Autowired private VenueManagerMapper        venueManagerMapper;
    @Autowired private BCryptPasswordEncoder     passwordEncoder;
    @Autowired private JwtUtil                   jwtUtil;

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
    // 관리자 전용 — 회원 조회 / 상태 변경
    // ──────────────────────────────────────────

    /** 페이지 검색 — 비밀번호 없는 DTO 반환 */
    public PageResponse<MemberSummaryDto> searchMembers(MemberSearchQuery query) {
        List<Member> members = memberMapper.findAll(
                query.getRole(), query.getStatus(), query.getKeyword(),
                query.getOffset(), query.getSize());
        int total = memberMapper.countFiltered(query.getRole(), query.getStatus(), query.getKeyword());
        List<MemberSummaryDto> dtos = members.stream()
                .map(MemberSummaryDto::from)
                .collect(Collectors.toList());
        return PageResponse.of(dtos, total, query.getPage(), query.getSize());
    }

    /** @deprecated 컨트롤러에서 직접 호출 금지. searchMembers(MemberSearchQuery) 사용. */
    @Deprecated
    public List<Member> findAll(String role, String status, String keyword, int page, int pageSize) {
        return memberMapper.findAll(role, status, keyword, (page - 1) * pageSize, pageSize);
    }

    /** @deprecated 컨트롤러에서 직접 호출 금지. searchMembers(MemberSearchQuery) 사용. */
    @Deprecated
    public int countFiltered(String role, String status, String keyword) {
        return memberMapper.countFiltered(role, status, keyword);
    }

    /**
     * FSM 기반 상태 전환 — 허용되지 않는 전환은 BusinessException.
     * 모든 전환은 member_status_history에 자동 기록.
     * SUSPENDED/WITHDRAWN 전환 시 member_sanction에도 사유 기록.
     */
    @Transactional
    public void updateAdminStatus(Long memberId, MemberStatus newStatus, Long adminMemberId, String reason) {
        Member m = memberMapper.findById(memberId);
        if (m == null) throw new BusinessException(ErrorCode.MEMBER_NOT_FOUND);

        MemberStatus current;
        try {
            current = MemberStatus.valueOf(m.getStatus());
        } catch (IllegalArgumentException e) {
            log.warn("알 수 없는 현재 상태값 '{}' — 강제 전환 허용: memberId={}", m.getStatus(), memberId);
            memberMapper.updateStatus(memberId, newStatus.name());
            return;
        }

        if (current == MemberStatus.WITHDRAWN) {
            throw new BusinessException(ErrorCode.MEMBER_ALREADY_WITHDRAWN);
        }
        if (!current.canTransitionTo(newStatus)) {
            throw new BusinessException(ErrorCode.MEMBER_STATUS_INVALID_TRANSITION,
                    current.name() + " → " + newStatus.name());
        }

        memberMapper.updateStatus(memberId, newStatus.name());

        MemberStatusHistory history = new MemberStatusHistory();
        history.setMemberId(memberId);
        history.setFromStatus(current.name());
        history.setToStatus(newStatus.name());
        history.setChangedBy(adminMemberId);
        history.setReason(reason);
        historyMapper.insert(history);

        if (newStatus == MemberStatus.SUSPENDED || newStatus == MemberStatus.WITHDRAWN) {
            MemberSanction sanction = new MemberSanction();
            sanction.setMemberId(memberId);
            sanction.setSanctionType(newStatus.name());
            sanction.setReason(reason != null ? reason : "(사유 미입력)");
            sanction.setSanctionedBy(adminMemberId != null ? adminMemberId : 0L);
            sanctionMapper.insert(sanction);
        }

        log.info("어드민 회원 상태 변경: memberId={}, {} → {}, adminId={}", memberId, current, newStatus, adminMemberId);
    }

    /** 이전 호환용 — adminMemberId/reason 없는 호출. */
    @Transactional
    public void updateAdminStatus(Long memberId, MemberStatus newStatus) {
        updateAdminStatus(memberId, newStatus, null, null);
    }

    /** String 오버로드 — 이전 호환용. */
    @Transactional
    public void updateAdminStatus(Long memberId, String status) {
        MemberStatus newStatus;
        try {
            newStatus = MemberStatus.valueOf(status);
        } catch (IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.MEMBER_STATUS_INVALID_TRANSITION,
                    "'" + status + "'은 유효한 상태값이 아닙니다.");
        }
        updateAdminStatus(memberId, newStatus, null, null);
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
