package com.ticketlegacy.service;

import com.ticketlegacy.domain.Performance;
import com.ticketlegacy.domain.Promoter;
import com.ticketlegacy.domain.enums.PerformanceApprovalStatus;
import com.ticketlegacy.dto.request.PerformanceSearchQuery;
import com.ticketlegacy.dto.response.PageResponse;
import com.ticketlegacy.dto.response.PerformanceSummaryDto;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.repository.PerformanceMapper;
import com.ticketlegacy.repository.PromoterMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PerformanceApprovalService {

    private final PerformanceMapper performanceMapper;
    private final PromoterMapper    promoterMapper;

    // ──────────────────────────────────────────
    // 기획사: 공연 등록/수정/검토 요청
    // ──────────────────────────────────────────

    @Transactional
    public Performance createDraft(Long promoterId, Map<String, Object> body) {
        Promoter promoter = promoterMapper.findById(promoterId);
        if (promoter == null || !PerformanceApprovalStatus.APPROVED.name().equals(promoter.getApprovalStatus())) {
            throw new BusinessException(ErrorCode.PROMOTER_NOT_APPROVED);
        }

        Performance p = new Performance();
        p.setTitle((String) body.get("title"));
        p.setCategory((String) body.get("category"));
        p.setVenueName((String) body.getOrDefault("venueName", ""));
        p.setDescription((String) body.getOrDefault("description", ""));
        p.setPosterUrl((String) body.getOrDefault("posterUrl", ""));
        if (body.get("venueId") != null)
            p.setVenueId(((Number) body.get("venueId")).longValue());
        if (body.get("ticketOpenAt") != null)
            p.setTicketOpenAt(java.time.LocalDateTime.parse((String) body.get("ticketOpenAt")));
        if (body.get("startDate") != null)
            p.setStartDate(java.time.LocalDate.parse((String) body.get("startDate")));
        if (body.get("endDate") != null)
            p.setEndDate(java.time.LocalDate.parse((String) body.get("endDate")));
        p.setStatus("UPCOMING");
        p.setTotalSeats(0);
        p.setPromoterId(promoterId);
        p.setApprovalStatus(PerformanceApprovalStatus.DRAFT.name());

        performanceMapper.insert(p);
        log.info("공연 DRAFT 생성: promoterId={}, title={}", promoterId, p.getTitle());
        return p;
    }

    @Transactional
    public void updateDraft(Long performanceId, Long promoterId, Map<String, Object> body) {
        Performance perf = getAndVerifyOwnership(performanceId, promoterId);
        PerformanceApprovalStatus current = parseStatus(perf.getApprovalStatus());
        if (current != PerformanceApprovalStatus.DRAFT && current != PerformanceApprovalStatus.REJECTED) {
            throw new BusinessException(ErrorCode.PERFORMANCE_NOT_EDITABLE);
        }

        if (body.containsKey("title"))       perf.setTitle((String) body.get("title"));
        if (body.containsKey("description")) perf.setDescription((String) body.get("description"));
        if (body.containsKey("posterUrl"))   perf.setPosterUrl((String) body.get("posterUrl"));
        if (body.containsKey("venueName"))   perf.setVenueName((String) body.get("venueName"));
        if (body.containsKey("venueId") && body.get("venueId") != null)
            perf.setVenueId(((Number) body.get("venueId")).longValue());
        if (body.containsKey("stageConfigId") && body.get("stageConfigId") != null)
            perf.setStageConfigId(((Number) body.get("stageConfigId")).longValue());
        if (body.containsKey("ticketOpenAt") && body.get("ticketOpenAt") != null)
            perf.setTicketOpenAt(java.time.LocalDateTime.parse((String) body.get("ticketOpenAt")));
        if (body.containsKey("startDate") && body.get("startDate") != null)
            perf.setStartDate(java.time.LocalDate.parse((String) body.get("startDate")));
        if (body.containsKey("endDate") && body.get("endDate") != null)
            perf.setEndDate(java.time.LocalDate.parse((String) body.get("endDate")));
        performanceMapper.update(perf);
        log.info("공연 DRAFT 수정: performanceId={}", performanceId);
    }

    @Transactional
    public void submitForReview(Long performanceId, Long promoterId) {
        Performance perf = getAndVerifyOwnership(performanceId, promoterId);
        PerformanceApprovalStatus current = parseStatus(perf.getApprovalStatus());
        validateTransition(current, PerformanceApprovalStatus.REVIEW);
        performanceMapper.updateApprovalStatus(performanceId, PerformanceApprovalStatus.REVIEW.name(), null, null);
        log.info("공연 검토 요청: performanceId={}, promoterId={}", performanceId, promoterId);
    }

    // ──────────────────────────────────────────
    // SUPER_ADMIN: 공연 승인/반려/게시
    // ──────────────────────────────────────────

    @Transactional
    public void approve(Long performanceId, Long adminMemberId, String note) {
        Performance perf = getPerformanceOrThrow(performanceId);
        validateTransition(parseStatus(perf.getApprovalStatus()), PerformanceApprovalStatus.APPROVED);
        performanceMapper.updateApprovalStatus(performanceId, PerformanceApprovalStatus.APPROVED.name(), note, adminMemberId);
        log.info("공연 승인: performanceId={}, adminMemberId={}", performanceId, adminMemberId);
    }

    @Transactional
    public void reject(Long performanceId, Long adminMemberId, String note) {
        Performance perf = getPerformanceOrThrow(performanceId);
        validateTransition(parseStatus(perf.getApprovalStatus()), PerformanceApprovalStatus.REJECTED);
        performanceMapper.updateApprovalStatus(performanceId, PerformanceApprovalStatus.REJECTED.name(), note, adminMemberId);
        log.info("공연 반려: performanceId={}, note={}", performanceId, note);
    }

    @Transactional
    public void publish(Long performanceId) {
        Performance perf = getPerformanceOrThrow(performanceId);
        validateTransition(parseStatus(perf.getApprovalStatus()), PerformanceApprovalStatus.PUBLISHED);
        performanceMapper.updateApprovalStatus(performanceId, PerformanceApprovalStatus.PUBLISHED.name(), null, null);
        perf.setStatus("ON_SALE");
        performanceMapper.update(perf);
        log.info("공연 게시(판매 시작): performanceId={}", performanceId);
    }

    @Transactional
    public void rollbackToDraft(Long performanceId) {
        Performance perf = getPerformanceOrThrow(performanceId);
        validateTransition(parseStatus(perf.getApprovalStatus()), PerformanceApprovalStatus.DRAFT);
        performanceMapper.updateApprovalStatus(performanceId, PerformanceApprovalStatus.DRAFT.name(), "SUPER_ADMIN 요청에 의한 수정 개방", null);
        log.info("공연 DRAFT 롤백: performanceId={}", performanceId);
    }

    // ──────────────────────────────────────────
    // 조회 (typed API)
    // ──────────────────────────────────────────

    public PageResponse<PerformanceSummaryDto> searchPerformances(PerformanceSearchQuery query) {
        String status = (query.getApprovalStatus() == null || query.getApprovalStatus().isBlank())
                ? null : query.getApprovalStatus();
        List<Performance> rows = performanceMapper.findAllByApprovalStatus(status, query.getOffset(), query.getSize());
        int total = performanceMapper.countAllByApprovalStatus(status);
        List<PerformanceSummaryDto> content = rows.stream()
                .map(PerformanceSummaryDto::from)
                .collect(Collectors.toList());
        return PageResponse.of(content, total, query.getPage(), query.getSize());
    }

    public List<Performance> findByPromoter(Long promoterId, String approvalStatus, int page, int size) {
        return performanceMapper.findByPromoterIdAndApprovalStatus(
                promoterId, approvalStatus, (page - 1) * size, size);
    }

    public int countByPromoter(Long promoterId, String approvalStatus) {
        return performanceMapper.countByPromoterIdAndApprovalStatus(promoterId, approvalStatus);
    }

    @Deprecated
    public List<Performance> findAll(String approvalStatus, int page, int size) {
        return performanceMapper.findAllByApprovalStatus(approvalStatus, (page - 1) * size, size);
    }

    @Deprecated
    public int countAll(String approvalStatus) {
        return performanceMapper.countAllByApprovalStatus(approvalStatus);
    }

    // ──────────────────────────────────────────
    // internal
    // ──────────────────────────────────────────

    private Performance getPerformanceOrThrow(Long performanceId) {
        Performance p = performanceMapper.findById(performanceId);
        if (p == null) throw new BusinessException(ErrorCode.PERFORMANCE_NOT_FOUND);
        return p;
    }

    private Performance getAndVerifyOwnership(Long performanceId, Long promoterId) {
        Performance perf = getPerformanceOrThrow(performanceId);
        if (!promoterId.equals(perf.getPromoterId())) {
            throw new BusinessException(ErrorCode.PERFORMANCE_FORBIDDEN);
        }
        return perf;
    }

    private PerformanceApprovalStatus parseStatus(String raw) {
        try {
            return PerformanceApprovalStatus.valueOf(raw);
        } catch (IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.INTERNAL_ERROR, "알 수 없는 공연 승인 상태: " + raw);
        }
    }

    private void validateTransition(PerformanceApprovalStatus current, PerformanceApprovalStatus next) {
        if (!current.canTransitionTo(next)) {
            throw new BusinessException(ErrorCode.PERFORMANCE_STATUS_INVALID_TRANSITION,
                    current.name() + " → " + next.name());
        }
    }
}
