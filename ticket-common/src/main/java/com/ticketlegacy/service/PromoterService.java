package com.ticketlegacy.service;

import com.ticketlegacy.domain.Member;
import com.ticketlegacy.domain.Promoter;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.repository.MemberMapper;
import com.ticketlegacy.repository.PerformanceMapper;
import com.ticketlegacy.repository.PromoterMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class PromoterService {

    private final PromoterMapper     promoterMapper;
    private final MemberMapper       memberMapper;
    private final PerformanceMapper  performanceMapper;
    private final BCryptPasswordEncoder passwordEncoder;

    // ──────────────────────────────────────────
    // 기획사 가입 신청
    // ──────────────────────────────────────────

    @Transactional
    public void registerPromoter(Map<String, String> body) {
        String email = body.get("email");
        if (memberMapper.existsByEmail(email) > 0) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_DUPLICATE);
        }

        // 1) member 생성 (role=PROMOTER, status=ACTIVE — 샘플이므로 즉시 활성)
        Member member = new Member();
        member.setEmail(email);
        member.setPassword(passwordEncoder.encode(body.get("password")));
        member.setName(body.get("name"));
        member.setPhone(body.get("phone"));
        member.setRole("PROMOTER");
        member.setStatus("PENDING_APPROVAL");
        memberMapper.insert(member);

        // 2) promoter 프로필 생성
        Promoter promoter = new Promoter();
        promoter.setMemberId(member.getMemberId());
        promoter.setCompanyName(body.get("companyName"));
        promoter.setBusinessRegNo(body.get("businessRegNo"));
        promoter.setRepresentative(body.get("representative"));
        promoter.setContactEmail(body.getOrDefault("contactEmail", email));
        promoter.setContactPhone(body.getOrDefault("contactPhone", body.get("phone")));
        promoter.setApprovalStatus("PENDING");
        promoterMapper.insert(promoter);

        log.info("기획사 가입 신청: email={}, company={}", email, promoter.getCompanyName());
    }

    // ──────────────────────────────────────────
    // SUPER_ADMIN: 기획사 승인/반려/정지
    // ──────────────────────────────────────────

    @Transactional
    public void approvePromoter(Long promoterId, Long adminMemberId) {
        Promoter promoter = getPromoterOrThrow(promoterId);
        if (!"PENDING".equals(promoter.getApprovalStatus())) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "승인 대기 상태의 기획사만 승인할 수 있습니다.");
        }
        promoterMapper.updateApproval(promoterId, "APPROVED", adminMemberId, null);
        memberMapper.updateStatus(promoter.getMemberId(), "ACTIVE");
        log.info("기획사 승인: promoterId={}, adminMemberId={}", promoterId, adminMemberId);
    }

    @Transactional
    public void rejectPromoter(Long promoterId, Long adminMemberId, String reason) {
        Promoter promoter = getPromoterOrThrow(promoterId);
        promoterMapper.updateApproval(promoterId, "REJECTED", adminMemberId, reason);
        memberMapper.updateStatus(promoter.getMemberId(), "DORMANT");
        log.info("기획사 반려: promoterId={}, reason={}", promoterId, reason);
    }

    @Transactional
    public void suspendPromoter(Long promoterId, Long adminMemberId) {
        Promoter promoter = getPromoterOrThrow(promoterId);
        promoterMapper.updateApproval(promoterId, "SUSPENDED", adminMemberId, "운영 정지");
        memberMapper.updateStatus(promoter.getMemberId(), "DORMANT");
        log.info("기획사 정지: promoterId={}", promoterId);
    }

    // ──────────────────────────────────────────
    // 조회
    // ──────────────────────────────────────────

    public List<Promoter> findByStatus(String status, int page, int size) {
        int offset = (page - 1) * size;
        if (status == null || status.isBlank()) {
            return promoterMapper.findAll(offset, size);
        }
        return promoterMapper.findByStatus(status, offset, size);
    }

    public int countByStatus(String status) {
        if (status == null || status.isBlank()) return promoterMapper.countAll();
        return promoterMapper.countByStatus(status);
    }

    public Promoter findByMemberId(Long memberId) {
        return promoterMapper.findByMemberId(memberId);
    }

    public Promoter findById(Long promoterId) {
        return getPromoterOrThrow(promoterId);
    }

    // ──────────────────────────────────────────
    // 소유권 검증 (PromoterController에서 사용)
    // ──────────────────────────────────────────

    /**
     * 해당 공연이 현재 기획사 소유인지 검증.
     * performance.promoter_id == promoterId 아니면 PERFORMANCE_FORBIDDEN 예외.
     */
    public void verifyPerformanceOwnership(Long promoterId, Long performanceId) {
        var perf = performanceMapper.findById(performanceId);
        if (perf == null) throw new BusinessException(ErrorCode.PERFORMANCE_NOT_FOUND);
        if (!promoterId.equals(perf.getPromoterId())) {
            throw new BusinessException(ErrorCode.PERFORMANCE_FORBIDDEN);
        }
    }

    private Promoter getPromoterOrThrow(Long promoterId) {
        Promoter p = promoterMapper.findById(promoterId);
        if (p == null) throw new BusinessException(ErrorCode.PROMOTER_NOT_FOUND);
        return p;
    }
}
