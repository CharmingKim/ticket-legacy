package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.*;
import com.ticketlegacy.dto.request.MemberSearchQuery;
import com.ticketlegacy.dto.request.MemberStatusCommand;
import com.ticketlegacy.dto.request.PromoterRejectCommand;
import com.ticketlegacy.dto.request.PromoterSearchQuery;
import com.ticketlegacy.dto.request.RegisterPromoterCommand;
import com.ticketlegacy.dto.request.PerformanceReviewCommand;
import com.ticketlegacy.dto.request.PerformanceSearchQuery;
import com.ticketlegacy.dto.request.RegisterVenueManagerCommand;
import com.ticketlegacy.dto.request.VenueManagerSearchQuery;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.dto.response.MemberSummaryDto;
import com.ticketlegacy.dto.response.PageResponse;
import com.ticketlegacy.dto.response.PerformanceSummaryDto;
import com.ticketlegacy.dto.response.PromoterSummaryDto;
import com.ticketlegacy.dto.response.VenueManagerSummaryDto;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.service.*;
import com.ticketlegacy.web.support.AuthMember;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 백오피스 — SUPER_ADMIN 전용 컨트롤러.
 * URL: /backoffice/super/**
 * security-context.xml: hasRole('SUPER_ADMIN')
 *
 * 담당 업무:
 *  - 기획사(Promoter) 승인/반려/정지
 *  - 공연장 담당자(VenueManager) 승인/반려
 *  - 공연 심사 (REVIEW → APPROVED/REJECTED → PUBLISHED)
 *  - 공연장 마스터 CRUD
 *  - 전체 회원 조회/상태변경
 *  - 정산 승인
 *  - 시스템 통계 대시보드
 */
@Controller
@RequestMapping("/backoffice/super")
public class BackofficeSuperController {

    @Autowired private PromoterService            promoterService;
    @Autowired private VenueManagerService        venueManagerService;
    @Autowired private PerformanceApprovalService performanceApprovalService;
    @Autowired private VenueAdminService          venueAdminService;
    @Autowired private AdminPerformanceService    adminPerformanceService;
    @Autowired private MemberService              memberService;
    @Autowired private PortalDashboardService     portalDashboardService;

    // ─────────────────────────────────────────────
    // 대시보드
    // ─────────────────────────────────────────────

    @GetMapping("/dashboard")
    public String dashboard(Model model) {
        Map<String, Object> summary = portalDashboardService.getBackofficeSummary();
        model.addAttribute("pendingPromoterCount",   summary.get("pendingPromoters"));
        model.addAttribute("pendingVmCount",         summary.get("pendingVenueManagers"));
        model.addAttribute("reviewPerformanceCount", summary.get("reviewPerformances"));
        model.addAttribute("venues",                 venueAdminService.findAllVenues());
        model.addAttribute("totalMemberCount",       summary.get("totalMembers"));
        model.addAttribute("todayReservationCount",  summary.get("todayReservations"));
        return "backoffice/super/dashboard";
    }

    @GetMapping("/api/dashboard/summary")
    @ResponseBody
    public ResponseEntity<?> dashboardSummary() {
        return ResponseEntity.ok(portalDashboardService.getBackofficeSummary());
    }

    @GetMapping("/api/dashboard/promoters")
    @ResponseBody
    public ResponseEntity<List<PromoterSummaryDto>> dashboardPromoters() {
        PromoterSearchQuery pendingQ  = new PromoterSearchQuery();
        pendingQ.setStatus("PENDING"); pendingQ.setPage(1); pendingQ.setSize(10);
        PromoterSearchQuery approvedQ = new PromoterSearchQuery();
        approvedQ.setStatus("APPROVED"); approvedQ.setPage(1); approvedQ.setSize(10);

        List<PromoterSummaryDto> merged = new java.util.ArrayList<>();
        merged.addAll(promoterService.searchPromoters(pendingQ).getContent());
        merged.addAll(promoterService.searchPromoters(approvedQ).getContent());
        return ResponseEntity.ok(merged);
    }

    @GetMapping("/api/dashboard/venue-managers")
    @ResponseBody
    public ResponseEntity<List<VenueManagerSummaryDto>> dashboardVenueManagers() {
        VenueManagerSearchQuery pendingQ  = new VenueManagerSearchQuery();
        pendingQ.setStatus("PENDING"); pendingQ.setPage(1); pendingQ.setSize(10);
        VenueManagerSearchQuery approvedQ = new VenueManagerSearchQuery();
        approvedQ.setStatus("APPROVED"); approvedQ.setPage(1); approvedQ.setSize(10);

        List<VenueManagerSummaryDto> merged = new java.util.ArrayList<>();
        merged.addAll(venueManagerService.searchVenueManagers(pendingQ).getContent());
        merged.addAll(venueManagerService.searchVenueManagers(approvedQ).getContent());
        return ResponseEntity.ok(merged);
    }

    @GetMapping("/api/dashboard/review-performances")
    @ResponseBody
    public ResponseEntity<?> dashboardReviewPerformances() {
        return ResponseEntity.ok(performanceApprovalService.findAll("REVIEW", 1, 20));
    }

    @GetMapping("/api/dashboard/venues")
    @ResponseBody
    public ResponseEntity<?> dashboardVenues() {
        return ResponseEntity.ok(venueAdminService.findAllVenues());
    }

    @GetMapping("/api/dashboard/recent-reservations")
    @ResponseBody
    public ResponseEntity<?> dashboardRecentReservations() {
        return ResponseEntity.ok(portalDashboardService.getRecentReservations(10));
    }

    // ─────────────────────────────────────────────
    // 시스템 통계
    // ─────────────────────────────────────────────

    @GetMapping("/statistics")
    public String statistics(Model model) {
        return "backoffice/super/statistics";
    }

    @GetMapping("/api/statistics/summary")
    @ResponseBody
    public ResponseEntity<?> statisticsSummary() {
        Map<String, Object> bs = portalDashboardService.getBackofficeSummary();
        Map<String, Object> summary = Map.of(
            "totalMembers",      bs.get("totalMembers"),
            "totalPromoters",    promoterService.countByStatus(null),
            "totalPerformances", performanceApprovalService.countAll(null),
            "totalVenues",       venueAdminService.findAllVenues().size(),
            "todayReservations", bs.get("todayReservations"),
            "pendingApprovals",  promoterService.countByStatus("PENDING")
                                     + venueManagerService.countByStatus("PENDING")
                                     + performanceApprovalService.countAll("REVIEW")
        );
        return ResponseEntity.ok(summary);
    }

    // ─────────────────────────────────────────────
    // 전체 회원 관리
    // ─────────────────────────────────────────────

    @GetMapping("/member-list")
    public String memberList(Model model) {
        return "backoffice/super/member-list";
    }

    @GetMapping("/api/members")
    @ResponseBody
    public ResponseEntity<ApiResponse<PageResponse<MemberSummaryDto>>> listMembers(
            @Valid @ModelAttribute MemberSearchQuery query) {
        return ResponseEntity.ok(ApiResponse.success(memberService.searchMembers(query)));
    }

    @PostMapping("/api/members/{memberId}/status")
    @ResponseBody
    public ResponseEntity<ApiResponse<Void>> updateMemberStatus(
            @PathVariable Long memberId,
            @Valid @RequestBody MemberStatusCommand command,
            @AuthMember Long adminMemberId) {
        if (memberId.equals(adminMemberId)) {
            throw new BusinessException(ErrorCode.MEMBER_CANNOT_MODIFY_SELF);
        }
        memberService.updateAdminStatus(memberId, command.getStatus(), adminMemberId, command.getReason());
        return ResponseEntity.ok(ApiResponse.successMessage("회원 상태가 변경되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 기획사 관리
    // ─────────────────────────────────────────────

    @GetMapping("/api/promoters")
    @ResponseBody
    public ResponseEntity<ApiResponse<PageResponse<PromoterSummaryDto>>> listPromoters(
            @Valid @ModelAttribute PromoterSearchQuery query) {
        return ResponseEntity.ok(ApiResponse.success(promoterService.searchPromoters(query)));
    }

    @PostMapping("/api/promoters")
    @ResponseBody
    public ResponseEntity<ApiResponse<Void>> createPromoter(
            @Valid @RequestBody RegisterPromoterCommand command) {
        promoterService.registerPromoter(command);
        return ResponseEntity.ok(ApiResponse.successMessage("기획사 계정이 등록되었습니다. (승인 대기)"));
    }

    @PostMapping("/api/promoters/{promoterId}/approve")
    @ResponseBody
    public ResponseEntity<ApiResponse<Void>> approvePromoter(@PathVariable Long promoterId,
                                                              @AuthMember Long adminMemberId) {
        promoterService.approvePromoter(promoterId, adminMemberId);
        return ResponseEntity.ok(ApiResponse.successMessage("기획사가 승인되었습니다."));
    }

    @PostMapping("/api/promoters/{promoterId}/reject")
    @ResponseBody
    public ResponseEntity<ApiResponse<Void>> rejectPromoter(@PathVariable Long promoterId,
                                                             @Valid @RequestBody PromoterRejectCommand command,
                                                             @AuthMember Long adminMemberId) {
        promoterService.rejectPromoter(promoterId, adminMemberId, command.getReason());
        return ResponseEntity.ok(ApiResponse.successMessage("기획사가 반려되었습니다."));
    }

    @PostMapping("/api/promoters/{promoterId}/suspend")
    @ResponseBody
    public ResponseEntity<ApiResponse<Void>> suspendPromoter(@PathVariable Long promoterId,
                                                              @AuthMember Long adminMemberId) {
        promoterService.suspendPromoter(promoterId, adminMemberId);
        return ResponseEntity.ok(ApiResponse.successMessage("기획사가 정지되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 공연장 담당자 관리
    // ─────────────────────────────────────────────

    @GetMapping("/api/venue-managers")
    @ResponseBody
    public ResponseEntity<ApiResponse<PageResponse<VenueManagerSummaryDto>>> listVenueManagers(
            @Valid @ModelAttribute VenueManagerSearchQuery query) {
        return ResponseEntity.ok(ApiResponse.success(venueManagerService.searchVenueManagers(query)));
    }

    @PostMapping("/api/venue-managers")
    @ResponseBody
    public ResponseEntity<ApiResponse<Void>> createVenueManager(
            @Valid @RequestBody RegisterVenueManagerCommand command) {
        venueManagerService.registerVenueManager(command);
        return ResponseEntity.ok(ApiResponse.successMessage("공연장 담당자 계정이 등록되었습니다. (승인 대기)"));
    }

    @PostMapping("/api/venue-managers/{managerId}/approve")
    @ResponseBody
    public ResponseEntity<ApiResponse<Void>> approveVenueManager(@PathVariable Long managerId,
                                                                   @AuthMember Long adminMemberId) {
        venueManagerService.approveVenueManager(managerId, adminMemberId);
        return ResponseEntity.ok(ApiResponse.successMessage("공연장 담당자가 승인되었습니다."));
    }

    @PostMapping("/api/venue-managers/{managerId}/reject")
    @ResponseBody
    public ResponseEntity<ApiResponse<Void>> rejectVenueManager(@PathVariable Long managerId,
                                                                  @AuthMember Long adminMemberId) {
        venueManagerService.rejectVenueManager(managerId, adminMemberId);
        return ResponseEntity.ok(ApiResponse.successMessage("공연장 담당자가 반려되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 공연 심사/승인 관리
    // ─────────────────────────────────────────────

    @GetMapping("/api/performances")
    @ResponseBody
    public ResponseEntity<ApiResponse<PageResponse<PerformanceSummaryDto>>> listPerformances(
            @Valid @ModelAttribute PerformanceSearchQuery query) {
        return ResponseEntity.ok(ApiResponse.success(performanceApprovalService.searchPerformances(query)));
    }

    @PostMapping("/api/performances/{performanceId}/approve")
    @ResponseBody
    public ResponseEntity<ApiResponse<Void>> approvePerformance(
            @PathVariable Long performanceId,
            @Valid @RequestBody(required = false) PerformanceReviewCommand command,
            @AuthMember Long adminMemberId) {
        String note = command != null ? command.getNote() : null;
        performanceApprovalService.approve(performanceId, adminMemberId, note);
        return ResponseEntity.ok(ApiResponse.successMessage("공연이 승인되었습니다."));
    }

    @PostMapping("/api/performances/{performanceId}/reject")
    @ResponseBody
    public ResponseEntity<ApiResponse<Void>> rejectPerformance(
            @PathVariable Long performanceId,
            @Valid @RequestBody PerformanceReviewCommand command,
            @AuthMember Long adminMemberId) {
        performanceApprovalService.reject(performanceId, adminMemberId, command.getNote());
        return ResponseEntity.ok(ApiResponse.successMessage("공연이 반려되었습니다."));
    }

    @PostMapping("/api/performances/{performanceId}/publish")
    @ResponseBody
    public ResponseEntity<ApiResponse<Void>> publishPerformance(@PathVariable Long performanceId) {
        performanceApprovalService.publish(performanceId);
        return ResponseEntity.ok(ApiResponse.successMessage("공연이 게시(ON_SALE)되었습니다."));
    }

    @PostMapping("/api/performances/{performanceId}/rollback-to-draft")
    @ResponseBody
    public ResponseEntity<ApiResponse<Void>> rollbackToDraft(@PathVariable Long performanceId) {
        performanceApprovalService.rollbackToDraft(performanceId);
        return ResponseEntity.ok(ApiResponse.successMessage("공연이 DRAFT로 롤백되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 공연장 마스터 관리 (CRUD)
    // ─────────────────────────────────────────────

    @GetMapping("/api/venues")
    @ResponseBody
    public ResponseEntity<?> getVenues() {
        return ResponseEntity.ok(venueAdminService.findAllVenues());
    }

    @PostMapping("/api/venues")
    @ResponseBody
    public ResponseEntity<?> createVenue(@RequestBody Map<String, Object> body) {
        String name      = (String) body.get("name");
        String address   = (String) body.getOrDefault("address", "");
        int    seatScale = body.get("seatScale") != null ? ((Number) body.get("seatScale")).intValue() : 0;
        if (name == null || name.isBlank())
            return ResponseEntity.badRequest().body(Map.of("message", "공연장 이름은 필수입니다."));
        Venue v = venueAdminService.createVenue(name, address, seatScale);
        return ResponseEntity.ok(Map.of("venueId", v.getVenueId(), "message", "공연장이 등록되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 공연장 구역 관리
    // ─────────────────────────────────────────────

    @GetMapping("/api/venues/{venueId}/sections")
    @ResponseBody
    public ResponseEntity<?> getSections(@PathVariable Long venueId) {
        return ResponseEntity.ok(venueAdminService.findSectionsByVenueId(venueId));
    }

    @PostMapping("/api/venues/{venueId}/sections")
    @ResponseBody
    public ResponseEntity<?> addSection(@PathVariable Long venueId,
                                         @RequestBody Map<String, Object> body) {
        String sectionName = (String) body.get("sectionName");
        String sectionType = (String) body.getOrDefault("sectionType", "FLOOR");
        int totalRows      = ((Number) body.getOrDefault("totalRows", 1)).intValue();
        int seatsPerRow    = ((Number) body.getOrDefault("seatsPerRow", 1)).intValue();
        int displayOrder   = ((Number) body.getOrDefault("displayOrder", 0)).intValue();
        if (sectionName == null || sectionName.isBlank())
            return ResponseEntity.badRequest().body(Map.of("message", "구역 이름은 필수입니다."));
        VenueSection s = venueAdminService.addSection(venueId, sectionName, sectionType,
                totalRows, seatsPerRow, displayOrder);
        return ResponseEntity.ok(Map.of("sectionId", s.getSectionId(), "message", "구역이 등록되었습니다."));
    }

    @DeleteMapping("/api/venues/{venueId}/sections/{sectionId}")
    @ResponseBody
    public ResponseEntity<?> deleteSection(@PathVariable Long venueId, @PathVariable Long sectionId) {
        venueAdminService.deleteSection(sectionId);
        return ResponseEntity.ok(Map.of("message", "구역이 삭제되었습니다."));
    }

    @PostMapping("/api/venues/{venueId}/template")
    @ResponseBody
    public ResponseEntity<?> generateTemplate(@PathVariable Long venueId) {
        int count = venueAdminService.generateTemplate(venueId);
        return ResponseEntity.ok(Map.of("count", count, "message", count + "석의 좌석 템플릿이 생성되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 무대구성 관리
    // ─────────────────────────────────────────────

    @GetMapping("/api/venues/{venueId}/stage-configs")
    @ResponseBody
    public ResponseEntity<?> getStageConfigs(@PathVariable Long venueId) {
        return ResponseEntity.ok(venueAdminService.findStageConfigs(venueId));
    }

    @PostMapping("/api/venues/{venueId}/stage-configs")
    @ResponseBody
    public ResponseEntity<?> createStageConfig(@PathVariable Long venueId,
                                                @RequestBody Map<String, Object> body) {
        String configName   = (String) body.get("configName");
        String description  = (String) body.getOrDefault("description", "");
        boolean isDefault   = Boolean.TRUE.equals(body.get("isDefault"));
        VenueStageConfig config = venueAdminService.createStageConfig(venueId, configName, description, isDefault);
        return ResponseEntity.ok(Map.of("configId", config.getConfigId(), "message", "무대구성이 등록되었습니다."));
    }

    @DeleteMapping("/api/venues/{venueId}/stage-configs/{configId}")
    @ResponseBody
    public ResponseEntity<?> deleteStageConfig(@PathVariable Long venueId, @PathVariable Long configId) {
        venueAdminService.deleteStageConfig(configId);
        return ResponseEntity.ok(Map.of("message", "무대구성이 삭제되었습니다."));
    }

    @GetMapping("/api/stage-configs/{configId}/sections")
    @ResponseBody
    public ResponseEntity<?> getStageSections(@PathVariable Long configId) {
        return ResponseEntity.ok(venueAdminService.findStageSections(configId));
    }

    @PostMapping("/api/stage-configs/{configId}/sections")
    @ResponseBody
    public ResponseEntity<?> upsertStageSection(@PathVariable Long configId,
                                                  @RequestBody Map<String, Object> body) {
        VenueStageSection ss = new VenueStageSection();
        ss.setConfigId(configId);
        ss.setSectionId(((Number) body.get("sectionId")).longValue());
        ss.setActive(!Boolean.FALSE.equals(body.get("isActive")));
        ss.setCustomRows(body.get("customRows") != null ? ((Number) body.get("customRows")).intValue() : null);
        ss.setCustomSeatsPerRow(body.get("customSeatsPerRow") != null ? ((Number) body.get("customSeatsPerRow")).intValue() : null);
        venueAdminService.upsertStageSection(ss);
        return ResponseEntity.ok(Map.of("message", "저장되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 공연 좌석/회차 관리
    // ─────────────────────────────────────────────

    @GetMapping("/api/performances/{performanceId}/schedules")
    @ResponseBody
    public ResponseEntity<?> getSchedules(@PathVariable Long performanceId) {
        return ResponseEntity.ok(adminPerformanceService.findSchedulesByPerformanceId(performanceId));
    }

    @PostMapping("/api/performances/{performanceId}/schedules")
    @ResponseBody
    public ResponseEntity<?> createSchedule(@PathVariable Long performanceId,
                                             @RequestBody Map<String, Object> body) {
        Schedule s = adminPerformanceService.createSchedule(
                performanceId,
                LocalDate.parse((String) body.get("showDate")),
                LocalTime.parse((String) body.get("showTime")));
        return ResponseEntity.ok(Map.of("scheduleId", s.getScheduleId(), "message", "회차가 등록되었습니다."));
    }

    @PostMapping("/api/performances/{performanceId}/seats")
    @ResponseBody
    public ResponseEntity<?> generateSeats(@PathVariable Long performanceId) {
        int count = adminPerformanceService.generateSeats(performanceId);
        return ResponseEntity.ok(Map.of("count", count, "message", count + "석 생성되었습니다."));
    }

    @DeleteMapping("/api/performances/{performanceId}/seats")
    @ResponseBody
    public ResponseEntity<?> deleteSeats(@PathVariable Long performanceId) {
        int deleted = adminPerformanceService.deleteSeats(performanceId);
        return ResponseEntity.ok(Map.of("count", deleted, "message", deleted + "석 삭제되었습니다."));
    }

    @PostMapping("/api/schedules/{scheduleId}/inventories")
    @ResponseBody
    public ResponseEntity<?> generateInventories(@PathVariable Long scheduleId) {
        adminPerformanceService.generateScheduleInventories(scheduleId);
        return ResponseEntity.ok(Map.of("message", "좌석 인벤토리가 활성화되었습니다."));
    }

    @PostMapping("/api/performances/{performanceId}/seat-grades")
    @ResponseBody
    public ResponseEntity<?> saveSeatGrades(@PathVariable Long performanceId,
                                             @RequestBody Map<String, Object> body) {
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> gradeData = (List<Map<String, Object>>) body.get("grades");
        List<PerformanceSeatGrade> grades = gradeData.stream().map(d -> {
            PerformanceSeatGrade g = new PerformanceSeatGrade();
            g.setSectionId(((Number) d.get("sectionId")).longValue());
            g.setGrade((String) d.get("grade"));
            g.setPrice(((Number) d.get("price")).intValue());
            return g;
        }).collect(Collectors.toList());
        adminPerformanceService.savePerformanceSeatGrades(performanceId, grades);
        return ResponseEntity.ok(Map.of("message", "등급/가격이 저장되었습니다."));
    }

    @GetMapping("/api/performances/{performanceId}/section-overrides")
    @ResponseBody
    public ResponseEntity<?> getSectionOverrides(@PathVariable Long performanceId) {
        return ResponseEntity.ok(adminPerformanceService.findSectionOverrides(performanceId));
    }

    @PostMapping("/api/performances/{performanceId}/section-overrides")
    @ResponseBody
    public ResponseEntity<?> upsertSectionOverride(@PathVariable Long performanceId,
                                                    @RequestBody Map<String, Object> body) {
        PerformanceSectionOverride override = new PerformanceSectionOverride();
        override.setSectionId(((Number) body.get("sectionId")).longValue());
        override.setActive(!Boolean.FALSE.equals(body.get("isActive")));
        override.setCustomRows(body.get("customRows") != null ? ((Number) body.get("customRows")).intValue() : null);
        override.setCustomSeatsPerRow(body.get("customSeatsPerRow") != null ? ((Number) body.get("customSeatsPerRow")).intValue() : null);
        override.setNote((String) body.getOrDefault("note", ""));
        adminPerformanceService.savePerformanceSectionOverride(performanceId, override);
        return ResponseEntity.ok(Map.of("message", "저장되었습니다."));
    }

    @PostMapping("/api/inventories/hold-type")
    @ResponseBody
    public ResponseEntity<?> updateHoldType(@RequestBody Map<String, Object> body) {
        Long scheduleId = ((Number) body.get("scheduleId")).longValue();
        @SuppressWarnings("unchecked")
        List<Long> seatIds = ((List<Object>) body.get("seatIds")).stream()
                .map(v -> ((Number) v).longValue()).collect(Collectors.toList());
        String holdType = (String) body.get("holdType");
        adminPerformanceService.updateHoldType(scheduleId, seatIds, holdType);
        return ResponseEntity.ok(Map.of("message", seatIds.size() + "석이 " + holdType + "으로 변경되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 정산 관리
    // ─────────────────────────────────────────────

    @GetMapping("/settlement")
    public String settlementPage(Model model) {
        model.addAttribute("promoters", promoterService.findApprovedSummaries());
        model.addAttribute("defaultYearMonth", portalDashboardService.defaultYearMonth());
        return "backoffice/super/settlement";
    }

    @GetMapping("/api/settlement")
    @ResponseBody
    public ResponseEntity<?> listSettlements(
            @RequestParam(required = false) Long promoterId,
            @RequestParam(required = false) String yearMonth) {
        return ResponseEntity.ok(portalDashboardService.getSettlementSummary(promoterId, yearMonth));
    }
}
