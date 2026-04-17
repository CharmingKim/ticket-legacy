package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.*;
import com.ticketlegacy.repository.*;
import com.ticketlegacy.service.*;
import java.time.YearMonth;
import com.ticketlegacy.web.support.AuthMember;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

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
    @Autowired private MemberMapper               memberMapper;
    @Autowired private ScheduleMapper             scheduleMapper;
    @Autowired private PerformanceMapper          performanceMapper;
    @Autowired private PerformanceSeatGradeMapper performanceSeatGradeMapper;
    @Autowired private VenueStageConfigMapper     venueStageConfigMapper;
    @Autowired private VenueStageSectionMapper    venueStageSectionMapper;
    @Autowired private PerformanceSectionOverrideMapper performanceSectionOverrideMapper;
    @Autowired private ReservationMapper          reservationMapper;
    @Autowired private PortalQueryMapper          portalQueryMapper;

    // ─────────────────────────────────────────────
    // 대시보드
    // ─────────────────────────────────────────────

    @GetMapping("/dashboard")
    public String dashboard(Model model) {
        model.addAttribute("pendingPromoterCount",   promoterService.countByStatus("PENDING"));
        model.addAttribute("pendingVmCount",         venueManagerService.countByStatus("PENDING"));
        model.addAttribute("reviewPerformanceCount", performanceApprovalService.countAll("REVIEW"));
        model.addAttribute("venues",                 venueAdminService.findAllVenues());
        model.addAttribute("totalMemberCount",       memberMapper.countAll());
        model.addAttribute("todayReservationCount",  reservationMapper.countToday());
        return "backoffice/super/dashboard";
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
        Map<String, Object> summary = Map.of(
            "totalMembers",      memberMapper.countAll(),
            "totalPromoters",    promoterService.countByStatus(null),
            "totalPerformances", performanceApprovalService.countAll(null),
            "totalVenues",       venueAdminService.findAllVenues().size(),
            "todayReservations", reservationMapper.countToday(),
            "pendingApprovals",  promoterService.countByStatus("PENDING") + venueManagerService.countByStatus("PENDING") + performanceApprovalService.countAll("REVIEW")
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
    public ResponseEntity<?> listMembers(
            @RequestParam(required = false) String role,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") int page) {
        List<Member> list  = memberMapper.findAll(role, status, keyword, (page - 1) * 20, 20);
        int          total = memberMapper.countFiltered(role, status, keyword);
        return ResponseEntity.ok(Map.of("list", list, "total", total, "page", page));
    }

    @PostMapping("/api/members/{memberId}/status")
    @ResponseBody
    public ResponseEntity<?> updateMemberStatus(@PathVariable Long memberId,
                                                 @RequestBody Map<String, String> body) {
        String status = body.get("status");
        memberMapper.updateStatus(memberId, status);
        return ResponseEntity.ok(Map.of("message", "회원 상태가 변경되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 기획사 관리
    // ─────────────────────────────────────────────

    @GetMapping("/api/promoters")
    @ResponseBody
    public ResponseEntity<?> listPromoters(
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int page) {
        List<Promoter> list  = promoterService.findByStatus(status, page, 20);
        int            total = promoterService.countByStatus(status);
        return ResponseEntity.ok(Map.of("list", list, "total", total, "page", page));
    }

    @PostMapping("/api/promoters/{promoterId}/approve")
    @ResponseBody
    public ResponseEntity<?> approvePromoter(@PathVariable Long promoterId,
                                              @AuthMember Long adminMemberId) {
        promoterService.approvePromoter(promoterId, adminMemberId);
        return ResponseEntity.ok(Map.of("message", "기획사가 승인되었습니다."));
    }

    @PostMapping("/api/promoters/{promoterId}/reject")
    @ResponseBody
    public ResponseEntity<?> rejectPromoter(@PathVariable Long promoterId,
                                             @RequestBody Map<String, String> body,
                                             @AuthMember Long adminMemberId) {
        promoterService.rejectPromoter(promoterId, adminMemberId, body.getOrDefault("reason", ""));
        return ResponseEntity.ok(Map.of("message", "기획사가 반려되었습니다."));
    }

    @PostMapping("/api/promoters/{promoterId}/suspend")
    @ResponseBody
    public ResponseEntity<?> suspendPromoter(@PathVariable Long promoterId,
                                              @AuthMember Long adminMemberId) {
        promoterService.suspendPromoter(promoterId, adminMemberId);
        return ResponseEntity.ok(Map.of("message", "기획사가 정지되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 공연장 담당자 관리
    // ─────────────────────────────────────────────

    @GetMapping("/api/venue-managers")
    @ResponseBody
    public ResponseEntity<?> listVenueManagers(
            @RequestParam(required = false, defaultValue = "PENDING") String status,
            @RequestParam(defaultValue = "1") int page) {
        List<VenueManager> list  = venueManagerService.findByStatus(status, page, 20);
        int                total = venueManagerService.countByStatus(status);
        return ResponseEntity.ok(Map.of("list", list, "total", total, "page", page));
    }

    @PostMapping("/api/venue-managers/{managerId}/approve")
    @ResponseBody
    public ResponseEntity<?> approveVenueManager(@PathVariable Long managerId,
                                                  @AuthMember Long adminMemberId) {
        venueManagerService.approveVenueManager(managerId, adminMemberId);
        return ResponseEntity.ok(Map.of("message", "공연장 담당자가 승인되었습니다."));
    }

    @PostMapping("/api/venue-managers/{managerId}/reject")
    @ResponseBody
    public ResponseEntity<?> rejectVenueManager(@PathVariable Long managerId,
                                                 @AuthMember Long adminMemberId) {
        venueManagerService.rejectVenueManager(managerId, adminMemberId);
        return ResponseEntity.ok(Map.of("message", "공연장 담당자가 반려되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 공연 심사/승인 관리
    // ─────────────────────────────────────────────

    @GetMapping("/api/performances")
    @ResponseBody
    public ResponseEntity<?> listPerformances(
            @RequestParam(required = false) String approvalStatus,
            @RequestParam(defaultValue = "1") int page) {
        List<Performance> list  = performanceApprovalService.findAll(approvalStatus, page, 20);
        int               total = performanceApprovalService.countAll(approvalStatus);
        return ResponseEntity.ok(Map.of("list", list, "total", total, "page", page));
    }

    @PostMapping("/api/performances/{performanceId}/approve")
    @ResponseBody
    public ResponseEntity<?> approvePerformance(@PathVariable Long performanceId,
                                                 @RequestBody(required = false) Map<String, String> body,
                                                 @AuthMember Long adminMemberId) {
        String note = body != null ? body.getOrDefault("note", "") : "";
        performanceApprovalService.approve(performanceId, adminMemberId, note);
        return ResponseEntity.ok(Map.of("message", "공연이 승인되었습니다."));
    }

    @PostMapping("/api/performances/{performanceId}/reject")
    @ResponseBody
    public ResponseEntity<?> rejectPerformance(@PathVariable Long performanceId,
                                                @RequestBody Map<String, String> body,
                                                @AuthMember Long adminMemberId) {
        performanceApprovalService.reject(performanceId, adminMemberId, body.getOrDefault("note", ""));
        return ResponseEntity.ok(Map.of("message", "공연이 반려되었습니다."));
    }

    @PostMapping("/api/performances/{performanceId}/publish")
    @ResponseBody
    public ResponseEntity<?> publishPerformance(@PathVariable Long performanceId) {
        performanceApprovalService.publish(performanceId);
        return ResponseEntity.ok(Map.of("message", "공연이 게시(ON_SALE)되었습니다."));
    }

    @PostMapping("/api/performances/{performanceId}/rollback-to-draft")
    @ResponseBody
    public ResponseEntity<?> rollbackToDraft(@PathVariable Long performanceId) {
        performanceApprovalService.rollbackToDraft(performanceId);
        return ResponseEntity.ok(Map.of("message", "공연이 DRAFT로 롤백되었습니다."));
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
        return ResponseEntity.ok(venueStageConfigMapper.findByVenueId(venueId));
    }

    @PostMapping("/api/venues/{venueId}/stage-configs")
    @ResponseBody
    public ResponseEntity<?> createStageConfig(@PathVariable Long venueId,
                                                @RequestBody Map<String, Object> body) {
        VenueStageConfig config = new VenueStageConfig();
        config.setVenueId(venueId);
        config.setConfigName((String) body.get("configName"));
        config.setDescription((String) body.getOrDefault("description", ""));
        config.setDefaultConfig(Boolean.TRUE.equals(body.get("isDefault")));
        venueStageConfigMapper.insert(config);
        return ResponseEntity.ok(Map.of("configId", config.getConfigId(), "message", "무대구성이 등록되었습니다."));
    }

    @DeleteMapping("/api/venues/{venueId}/stage-configs/{configId}")
    @ResponseBody
    public ResponseEntity<?> deleteStageConfig(@PathVariable Long venueId, @PathVariable Long configId) {
        venueStageConfigMapper.deleteById(configId);
        return ResponseEntity.ok(Map.of("message", "무대구성이 삭제되었습니다."));
    }

    @GetMapping("/api/stage-configs/{configId}/sections")
    @ResponseBody
    public ResponseEntity<?> getStageSections(@PathVariable Long configId) {
        return ResponseEntity.ok(venueStageSectionMapper.findByConfigId(configId));
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
        venueStageSectionMapper.upsert(ss);
        return ResponseEntity.ok(Map.of("message", "저장되었습니다."));
    }

    // ─────────────────────────────────────────────
    // 공연 좌석/회차 관리
    // ─────────────────────────────────────────────

    @GetMapping("/api/performances/{performanceId}/schedules")
    @ResponseBody
    public ResponseEntity<?> getSchedules(@PathVariable Long performanceId) {
        return ResponseEntity.ok(scheduleMapper.findByPerformanceId(performanceId));
    }

    @PostMapping("/api/performances/{performanceId}/schedules")
    @ResponseBody
    public ResponseEntity<?> createSchedule(@PathVariable Long performanceId,
                                             @RequestBody Map<String, Object> body) {
        Schedule s = new Schedule();
        s.setPerformanceId(performanceId);
        s.setShowDate(LocalDate.parse((String) body.get("showDate")));
        s.setShowTime(LocalTime.parse((String) body.get("showTime")));
        scheduleMapper.insert(s);
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
        return ResponseEntity.ok(performanceSectionOverrideMapper.findByPerformanceId(performanceId));
    }

    @PostMapping("/api/performances/{performanceId}/section-overrides")
    @ResponseBody
    public ResponseEntity<?> upsertSectionOverride(@PathVariable Long performanceId,
                                                    @RequestBody Map<String, Object> body) {
        PerformanceSectionOverride override = new PerformanceSectionOverride();
        override.setPerformanceId(performanceId);
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
    // 정산 관리 페이지
    // ─────────────────────────────────────────────

    @GetMapping("/settlement")
    public String settlementPage(Model model) {
        model.addAttribute("promoters", promoterService.findByStatus("APPROVED", 1, 100));
        model.addAttribute("defaultYearMonth", java.time.YearMonth.now().toString());
        return "backoffice/super/settlement";
    }

    @GetMapping("/api/settlement")
    @ResponseBody
    public ResponseEntity<?> listSettlements(
            @RequestParam(required = false) Long promoterId,
            @RequestParam(required = false) String yearMonth) {
        String ym = (yearMonth != null && !yearMonth.isBlank()) ? yearMonth : YearMonth.now().toString();
        List<Map<String, Object>> rows = portalQueryMapper.findSettlementRows(promoterId, ym);
        // 합계 계산
        long totalGross     = rows.stream().mapToLong(r -> toLong(r.get("gross_sales"))).sum();
        long totalFee       = rows.stream().mapToLong(r -> toLong(r.get("platform_fee"))).sum();
        long totalPayable   = rows.stream().mapToLong(r -> toLong(r.get("payable_amount"))).sum();
        int  totalResvCount = rows.stream().mapToInt(r -> toInt(r.get("confirmed_reservations"))).sum();
        return ResponseEntity.ok(Map.of(
            "rows",        rows,
            "yearMonth",   ym,
            "totalGross",  totalGross,
            "totalFee",    totalFee,
            "totalPayable",totalPayable,
            "totalRsvCount", totalResvCount
        ));
    }

    private static long toLong(Object v) {
        if (v == null) return 0L;
        if (v instanceof Number) return ((Number) v).longValue();
        try { return Long.parseLong(v.toString()); } catch (Exception e) { return 0L; }
    }
    private static int toInt(Object v) {
        if (v == null) return 0;
        if (v instanceof Number) return ((Number) v).intValue();
        try { return Integer.parseInt(v.toString()); } catch (Exception e) { return 0; }
    }
}
