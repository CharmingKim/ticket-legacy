package com.ticketlegacy.web.controller;

import com.ticketlegacy.service.PerformanceApprovalService;
import com.ticketlegacy.service.PortalDashboardService;
import com.ticketlegacy.service.PromoterService;
import com.ticketlegacy.service.VenueAdminService;
import com.ticketlegacy.service.VenueManagerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.Map;

/**
 * SUPER_ADMIN 대시보드 / 정산 API 엔드포인트
 * URL prefix: /backoffice/super/api/dashboard/**
 */
@Controller
@RequiredArgsConstructor
@RequestMapping("/backoffice/super")
public class BackofficeSuperAnalyticsController {

    private final PortalDashboardService     portalDashboardService;
    private final PromoterService            promoterService;
    private final VenueManagerService        venueManagerService;
    private final VenueAdminService          venueAdminService;
    private final PerformanceApprovalService performanceApprovalService;

    /** KPI 요약 카드 */
    @GetMapping("/api/dashboard/summary")
    @ResponseBody
    public ResponseEntity<?> dashboardSummary() {
        return ResponseEntity.ok(portalDashboardService.getBackofficeSummary());
    }

    /** 최근 예약 탭 */
    @GetMapping("/api/dashboard/recent-reservations")
    @ResponseBody
    public ResponseEntity<?> recentReservations() {
        return ResponseEntity.ok(portalDashboardService.getRecentReservations(10));
    }

    /** 기획사 탭: PENDING 우선 20건 */
    @GetMapping("/api/dashboard/promoters")
    @ResponseBody
    public ResponseEntity<?> dashboardPromoters() {
        // PENDING 먼저, 그 다음 전체 (최대 30건)
        return ResponseEntity.ok(promoterService.findByStatus(null, 1, 30));
    }

    /** 공연장 담당자 탭: PENDING 최대 30건 */
    @GetMapping("/api/dashboard/venue-managers")
    @ResponseBody
    public ResponseEntity<?> dashboardVenueManagers() {
        return ResponseEntity.ok(venueManagerService.findByStatus("PENDING", 1, 30));
    }

    /** 공연 심사 대기 탭 */
    @GetMapping("/api/dashboard/review-performances")
    @ResponseBody
    public ResponseEntity<?> dashboardReviewPerformances() {
        return ResponseEntity.ok(performanceApprovalService.findAll("REVIEW", 1, 30));
    }

    /** 공연장 탭 */
    @GetMapping("/api/dashboard/venues")
    @ResponseBody
    public ResponseEntity<?> dashboardVenues() {
        return ResponseEntity.ok(venueAdminService.findAllVenues());
    }

    /** 정산 리포트 */
    @GetMapping("/api/settlement/report")
    @ResponseBody
    public ResponseEntity<?> settlementReport(@RequestParam(required = false) Long promoterId,
                                              @RequestParam(required = false) String yearMonth) {
        return ResponseEntity.ok(Map.of(
                "yearMonth", yearMonth == null || yearMonth.isBlank()
                        ? portalDashboardService.defaultYearMonth()
                        : yearMonth,
                "rows", portalDashboardService.getSettlementRows(promoterId, yearMonth)
        ));
    }
}
