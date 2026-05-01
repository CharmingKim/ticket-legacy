package com.ticketlegacy.service;

import com.ticketlegacy.domain.Member;
import com.ticketlegacy.domain.Promoter;
import com.ticketlegacy.domain.enums.PromoterApprovalStatus;
import com.ticketlegacy.dto.request.PromoterSearchQuery;
import com.ticketlegacy.dto.request.RegisterPromoterCommand;
import com.ticketlegacy.dto.response.PageResponse;
import com.ticketlegacy.dto.response.PromoterSummaryDto;
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
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PromoterService {

    private final PromoterMapper         promoterMapper;
    private final MemberMapper           memberMapper;
    private final PerformanceMapper      performanceMapper;
    private final BCryptPasswordEncoder  passwordEncoder;

    // ──────────────────────────────────────────
    // 기획사 가입 신청
    // ──────────────────────────────────────────

    @Transactional
    public void registerPromoter(RegisterPromoterCommand command) {
        if (memberMapper.existsByEmail(command.getEmail()) > 0) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_DUPLICATE);
        }

        Member member = new Member();
        member.setEmail(command.getEmail());
        member.setPassword(passwordEncoder.encode(command.getPassword()));
        member.setName(command.getName());
        member.setPhone(command.getPhone());
        member.setRole("PROMOTER");
        member.setStatus("PENDING_APPROVAL");
        memberMapper.insert(member);

        Promoter promoter = new Promoter();
        promoter.setMemberId(member.getMemberId());
        promoter.setCompanyName(command.getCompanyName());
        promoter.setBusinessRegNo(command.getBusinessRegNo());
        promoter.setRepresentative(command.getRepresentative());
        promoter.setContactEmail(command.getEmail());
        promoter.setContactPhone(command.getPhone());
        promoter.setApprovalStatus(PromoterApprovalStatus.PENDING.name());
        promoterMapper.insert(promoter);

        log.info("기획사 가입 신청: email={}, company={}", command.getEmail(), command.getCompanyName());
    }

    // ──────────────────────────────────────────
    // SUPER_ADMIN: 기획사 승인/반려/정지
    // ──────────────────────────────────────────

    @Transactional
    public void approvePromoter(Long promoterId, Long adminMemberId) {
        Promoter promoter = getPromoterOrThrow(promoterId);
        PromoterApprovalStatus current = parseStatus(promoter.getApprovalStatus());
        validateTransition(current, PromoterApprovalStatus.APPROVED);

        promoterMapper.updateApproval(promoterId, PromoterApprovalStatus.APPROVED.name(), adminMemberId, null);
        memberMapper.updateStatus(promoter.getMemberId(), "ACTIVE");
        log.info("기획사 승인: promoterId={}, adminMemberId={}, {} → APPROVED", promoterId, adminMemberId, current);
    }

    @Transactional
    public void rejectPromoter(Long promoterId, Long adminMemberId, String reason) {
        Promoter promoter = getPromoterOrThrow(promoterId);
        PromoterApprovalStatus current = parseStatus(promoter.getApprovalStatus());
        validateTransition(current, PromoterApprovalStatus.REJECTED);

        promoterMapper.updateApproval(promoterId, PromoterApprovalStatus.REJECTED.name(), adminMemberId, reason);
        memberMapper.updateStatus(promoter.getMemberId(), "DORMANT");
        log.info("기획사 반려: promoterId={}, reason={}, {} → REJECTED", promoterId, reason, current);
    }

    @Transactional
    public void suspendPromoter(Long promoterId, Long adminMemberId) {
        Promoter promoter = getPromoterOrThrow(promoterId);
        PromoterApprovalStatus current = parseStatus(promoter.getApprovalStatus());
        validateTransition(current, PromoterApprovalStatus.SUSPENDED);

        promoterMapper.updateApproval(promoterId, PromoterApprovalStatus.SUSPENDED.name(), adminMemberId, "운영 정지");
        memberMapper.updateStatus(promoter.getMemberId(), "DORMANT");
        log.info("기획사 정지: promoterId={}, {} → SUSPENDED", promoterId, current);
    }

    // ──────────────────────────────────────────
    // 조회 (typed API)
    // ──────────────────────────────────────────

    public PageResponse<PromoterSummaryDto> searchPromoters(PromoterSearchQuery query) {
        String status = (query.getStatus() == null || query.getStatus().isBlank()) ? null : query.getStatus();
        List<Promoter> rows;
        int total;
        if (status == null) {
            rows  = promoterMapper.findAll(query.getOffset(), query.getSize());
            total = promoterMapper.countAll();
        } else {
            rows  = promoterMapper.findByStatus(status, query.getOffset(), query.getSize());
            total = promoterMapper.countByStatus(status);
        }
        List<PromoterSummaryDto> content = rows.stream()
                .map(PromoterSummaryDto::from)
                .collect(Collectors.toList());
        return PageResponse.of(content, total, query.getPage(), query.getSize());
    }

    public List<PromoterSummaryDto> findApprovedSummaries() {
        return promoterMapper.findByStatus(PromoterApprovalStatus.APPROVED.name(), 0, 200)
                .stream()
                .map(PromoterSummaryDto::from)
                .collect(Collectors.toList());
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
    // 소유권 검증 (Partner 포털에서 사용)
    // ──────────────────────────────────────────

    public void verifyPerformanceOwnership(Long promoterId, Long performanceId) {
        var perf = performanceMapper.findById(performanceId);
        if (perf == null) throw new BusinessException(ErrorCode.PERFORMANCE_NOT_FOUND);
        if (!promoterId.equals(perf.getPromoterId())) {
            throw new BusinessException(ErrorCode.PERFORMANCE_FORBIDDEN);
        }
    }

    // ──────────────────────────────────────────
    // internal
    // ──────────────────────────────────────────

    private Promoter getPromoterOrThrow(Long promoterId) {
        Promoter p = promoterMapper.findById(promoterId);
        if (p == null) throw new BusinessException(ErrorCode.PROMOTER_NOT_FOUND);
        return p;
    }

    private PromoterApprovalStatus parseStatus(String raw) {
        try {
            return PromoterApprovalStatus.valueOf(raw);
        } catch (IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.INTERNAL_ERROR, "알 수 없는 기획사 상태: " + raw);
        }
    }

    private void validateTransition(PromoterApprovalStatus current, PromoterApprovalStatus next) {
        if (!current.canTransitionTo(next)) {
            throw new BusinessException(ErrorCode.PROMOTER_STATUS_INVALID_TRANSITION,
                    current.name() + " → " + next.name());
        }
    }
}
