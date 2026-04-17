package com.ticketlegacy.service;

import com.ticketlegacy.domain.Performance;
import com.ticketlegacy.domain.Promoter;
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

@Slf4j
@Service
@RequiredArgsConstructor
public class PerformanceApprovalService {

    private final PerformanceMapper performanceMapper;
    private final PromoterMapper    promoterMapper;

    // ──────────────────────────────────────────
    // 기획사: 공연 등록/수정/검토 요청
    // ──────────────────────────────────────────

    /**
     * 기획사가 공연을 임시 저장(DRAFT)으로 등록.
     */
    @Transactional
    public Performance createDraft(Long promoterId, Map<String, Object> body) {
        Promoter promoter = promoterMapper.findById(promoterId);
        if (promoter == null || !"APPROVED".equals(promoter.getApprovalStatus())) {
            throw new BusinessException(ErrorCode.PROMOTER_NOT_APPROVED);
        }

        Performance p = new Performance();
        p.setTitle((String) body.get("title"));
        p.setCategory((String) body.get("category"));
        p.setVenueName((String) body.getOrDefault("venueName", ""));
        p.setDescription((String) body.getOrDefault("description", ""));
        p.setPosterUrl((String) body.getOrDefault("posterUrl", ""));
        if (body.get("venueId") != null) {
            p.setVenueId(((Number) body.get("venueId")).longValue());
        }
        if (body.get("ticketOpenAt") != null) {
            p.setTicketOpenAt(java.time.LocalDateTime.parse((String) body.get("ticketOpenAt")));
        }
        if (body.get("startDate") != null) {
            p.setStartDate(java.time.LocalDate.parse((String) body.get("startDate")));
        }
        if (body.get("endDate") != null) {
            p.setEndDate(java.time.LocalDate.parse((String) body.get("endDate")));
        }
        p.setStatus("UPCOMING");
        p.setTotalSeats(0);
        p.setPromoterId(promoterId);
        p.setApprovalStatus("DRAFT");

        performanceMapper.insert(p);
        log.info("공연 DRAFT 생성: promoterId={}, title={}", promoterId, p.getTitle());
        return p;
    }

    /**
     * DRAFT 상태 공연 수정 (기획사만).
     */
    @Transactional
    public void updateDraft(Long performanceId, Long promoterId, Map<String, Object> body) {
        Performance perf = getAndVerifyOwnership(performanceId, promoterId);
        if (!"DRAFT".equals(perf.getApprovalStatus()) && !"REJECTED".equals(perf.getApprovalStatus())) {
            throw new BusinessException(ErrorCode.PERFORMANCE_NOT_EDITABLE);
        }

        if (body.containsKey("title"))       perf.setTitle((String) body.get("title"));
        if (body.containsKey("description")) perf.setDescription((String) body.get("description"));
        if (body.containsKey("posterUrl"))   perf.setPosterUrl((String) body.get("posterUrl"));
        if (body.containsKey("venueName"))   perf.setVenueName((String) body.get("venueName"));
        if (body.containsKey("venueId") && body.get("venueId") != null) {
            perf.setVenueId(((Number) body.get("venueId")).longValue());
        }
        if (body.containsKey("stageConfigId") && body.get("stageConfigId") != null) {
            perf.setStageConfigId(((Number) body.get("stageConfigId")).longValue());
        }
        if (body.containsKey("ticketOpenAt") && body.get("ticketOpenAt") != null) {
            perf.setTicketOpenAt(java.time.LocalDateTime.parse((String) body.get("ticketOpenAt")));
        }
        if (body.containsKey("startDate") && body.get("startDate") != null) {
            perf.setStartDate(java.time.LocalDate.parse((String) body.get("startDate")));
        }
        if (body.containsKey("endDate") && body.get("endDate") != null) {
            perf.setEndDate(java.time.LocalDate.parse((String) body.get("endDate")));
        }
        performanceMapper.update(perf);
        log.info("공연 DRAFT 수정: performanceId={}", performanceId);
    }

    /**
     * 기획사가 검토 요청 (DRAFT → REVIEW).
     */
    @Transactional
    public void submitForReview(Long performanceId, Long promoterId) {
        Performance perf = getAndVerifyOwnership(performanceId, promoterId);
        if (!"DRAFT".equals(perf.getApprovalStatus()) && !"REJECTED".equals(perf.getApprovalStatus())) {
            throw new BusinessException(ErrorCode.PERFORMANCE_APPROVAL_INVALID,
                    "DRAFT 또는 REJECTED 상태에서만 검토 요청이 가능합니다.");
        }
        performanceMapper.updateApprovalStatus(performanceId, "REVIEW", null, null);
        log.info("공연 검토 요청: performanceId={}, promoterId={}", performanceId, promoterId);
    }

    // ──────────────────────────────────────────
    // SUPER_ADMIN: 공연 승인/반려/게시
    // ──────────────────────────────────────────

    /**
     * SUPER_ADMIN이 공연 승인 (REVIEW → APPROVED).
     */
    @Transactional
    public void approve(Long performanceId, Long adminMemberId, String note) {
        Performance perf = getPerformanceOrThrow(performanceId);
        if (!"REVIEW".equals(perf.getApprovalStatus())) {
            throw new BusinessException(ErrorCode.PERFORMANCE_APPROVAL_INVALID,
                    "REVIEW 상태의 공연만 승인할 수 있습니다.");
        }
        performanceMapper.updateApprovalStatus(performanceId, "APPROVED", note, adminMemberId);
        log.info("공연 승인: performanceId={}, adminMemberId={}", performanceId, adminMemberId);
    }

    /**
     * SUPER_ADMIN이 공연 반려 (REVIEW → REJECTED).
     */
    @Transactional
    public void reject(Long performanceId, Long adminMemberId, String note) {
        Performance perf = getPerformanceOrThrow(performanceId);
        if (!"REVIEW".equals(perf.getApprovalStatus())) {
            throw new BusinessException(ErrorCode.PERFORMANCE_APPROVAL_INVALID,
                    "REVIEW 상태의 공연만 반려할 수 있습니다.");
        }
        performanceMapper.updateApprovalStatus(performanceId, "REJECTED", note, adminMemberId);
        log.info("공연 반려: performanceId={}, note={}", performanceId, note);
    }

    /**
     * SUPER_ADMIN이 공연 게시 (APPROVED → PUBLISHED, status=ON_SALE).
     */
    @Transactional
    public void publish(Long performanceId) {
        Performance perf = getPerformanceOrThrow(performanceId);
        if (!"APPROVED".equals(perf.getApprovalStatus())) {
            throw new BusinessException(ErrorCode.PERFORMANCE_APPROVAL_INVALID,
                    "APPROVED 상태의 공연만 게시할 수 있습니다.");
        }
        performanceMapper.updateApprovalStatus(performanceId, "PUBLISHED", null, null);
        perf.setStatus("ON_SALE");
        performanceMapper.update(perf);
        log.info("공연 게시(판매 시작): performanceId={}", performanceId);
    }

    /**
     * SUPER_ADMIN이 공연을 DRAFT로 롤백 (기획사가 다시 수정 가능하도록).
     */
    @Transactional
    public void rollbackToDraft(Long performanceId) {
        getPerformanceOrThrow(performanceId);
        performanceMapper.updateApprovalStatus(performanceId, "DRAFT", "SUPER_ADMIN 요청에 의한 수정 개방", null);
        log.info("공연 DRAFT 롤백: performanceId={}", performanceId);
    }

    // ──────────────────────────────────────────
    // 조회
    // ──────────────────────────────────────────

    public List<Performance> findByPromoter(Long promoterId, String approvalStatus, int page, int size) {
        return performanceMapper.findByPromoterIdAndApprovalStatus(
                promoterId, approvalStatus, (page - 1) * size, size);
    }

    public int countByPromoter(Long promoterId, String approvalStatus) {
        return performanceMapper.countByPromoterIdAndApprovalStatus(promoterId, approvalStatus);
    }

    public List<Performance> findAll(String approvalStatus, int page, int size) {
        return performanceMapper.findAllByApprovalStatus(approvalStatus, (page - 1) * size, size);
    }

    public int countAll(String approvalStatus) {
        return performanceMapper.countAllByApprovalStatus(approvalStatus);
    }

    // ──────────────────────────────────────────
    // 내부 유틸
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
}
