package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.Performance;
import com.ticketlegacy.domain.PerformanceSeatGrade;
import com.ticketlegacy.domain.PerformanceSectionOverride;
import com.ticketlegacy.domain.Schedule;
import com.ticketlegacy.service.AdminPerformanceService;
import com.ticketlegacy.service.PerformanceApprovalService;
import com.ticketlegacy.service.PortalDashboardService;
import com.ticketlegacy.service.PromoterService;
import com.ticketlegacy.service.VenueAdminService;
import com.ticketlegacy.repository.PerformanceSeatGradeMapper;
import com.ticketlegacy.repository.PerformanceSectionOverrideMapper;
import com.ticketlegacy.repository.ScheduleMapper;
import com.ticketlegacy.repository.VenueStageConfigMapper;
import com.ticketlegacy.web.support.LoginUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Controller
@RequiredArgsConstructor
@RequestMapping("/partner/promoter")
public class PartnerPromoterController {

    private final PerformanceApprovalService performanceApprovalService;
    private final PromoterService promoterService;
    private final AdminPerformanceService adminPerformanceService;
    private final VenueAdminService venueAdminService;
    private final PortalDashboardService portalDashboardService;
    private final ScheduleMapper scheduleMapper;
    private final PerformanceSeatGradeMapper performanceSeatGradeMapper;
    private final VenueStageConfigMapper venueStageConfigMapper;
    private final PerformanceSectionOverrideMapper performanceSectionOverrideMapper;

    private Long currentPromoterId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return ((LoginUser) auth.getPrincipal()).getPromoterId();
    }

    @GetMapping("/dashboard")
    public String dashboard(Model model) {
        Long promoterId = currentPromoterId();
        model.addAttribute("promoter", promoterService.findById(promoterId));
        model.addAttribute("summary", portalDashboardService.getPromoterDashboard(promoterId));
        model.addAttribute("recentPerformances",
                performanceApprovalService.findByPromoter(promoterId, null, 1, 8));
        model.addAttribute("salesRows", portalDashboardService.getPromoterSalesRows(promoterId));
        return "partner/promoter/dashboard";
    }

    @GetMapping("/performances")
    public String performances(Model model) {
        Long promoterId = currentPromoterId();
        model.addAttribute("promoter", promoterService.findById(promoterId));
        model.addAttribute("venues", venueAdminService.findAllVenues());
        model.addAttribute("summary", portalDashboardService.getPromoterDashboard(promoterId));
        return "partner/promoter/performance-list";
    }

    @GetMapping("/performances/new")
    public String performanceForm(Model model) {
        model.addAttribute("venues", venueAdminService.findAllVenues());
        return "partner/promoter/performance-form";
    }

    @GetMapping("/sales-report")
    public String salesReport(Model model) {
        model.addAttribute("salesRows", portalDashboardService.getPromoterSalesRows(currentPromoterId()));
        return "partner/promoter/sales-report";
    }

    @GetMapping("/settlement")
    public String settlement(@RequestParam(required = false) String yearMonth, Model model) {
        Long promoterId = currentPromoterId();
        model.addAttribute("defaultYearMonth", portalDashboardService.defaultYearMonth());
        model.addAttribute("rows", portalDashboardService.getSettlementRows(promoterId, yearMonth));
        return "partner/promoter/settlement";
    }

    @GetMapping("/api/dashboard/summary")
    @ResponseBody
    public ResponseEntity<?> dashboardSummary() {
        return ResponseEntity.ok(portalDashboardService.getPromoterDashboard(currentPromoterId()));
    }

    @GetMapping("/api/sales-report")
    @ResponseBody
    public ResponseEntity<?> salesReportRows() {
        return ResponseEntity.ok(portalDashboardService.getPromoterSalesRows(currentPromoterId()));
    }

    @GetMapping("/api/settlement")
    @ResponseBody
    public ResponseEntity<?> settlementRows(@RequestParam(required = false) String yearMonth) {
        return ResponseEntity.ok(Map.of(
                "yearMonth", yearMonth == null || yearMonth.isBlank()
                        ? portalDashboardService.defaultYearMonth()
                        : yearMonth,
                "rows", portalDashboardService.getSettlementRows(currentPromoterId(), yearMonth)
        ));
    }

    @GetMapping("/api/performances")
    @ResponseBody
    public ResponseEntity<?> myPerformances(@RequestParam(required = false) String approvalStatus,
                                            @RequestParam(defaultValue = "1") int page) {
        Long promoterId = currentPromoterId();
        List<Performance> list = performanceApprovalService.findByPromoter(promoterId, approvalStatus, page, 20);
        int total = performanceApprovalService.countByPromoter(promoterId, approvalStatus);
        return ResponseEntity.ok(Map.of("list", list, "total", total, "page", page));
    }

    @PostMapping("/api/performances")
    @ResponseBody
    public ResponseEntity<?> createPerformance(@RequestBody Map<String, Object> body) {
        Performance performance = performanceApprovalService.createDraft(currentPromoterId(), body);
        return ResponseEntity.ok(Map.of(
                "performanceId", performance.getPerformanceId(),
                "message", "Draft performance has been created."
        ));
    }

    @PatchMapping("/api/performances/{performanceId}")
    @ResponseBody
    public ResponseEntity<?> updatePerformance(@PathVariable Long performanceId,
                                               @RequestBody Map<String, Object> body) {
        performanceApprovalService.updateDraft(performanceId, currentPromoterId(), body);
        return ResponseEntity.ok(Map.of("message", "Performance draft has been updated."));
    }

    @PostMapping("/api/performances/{performanceId}/submit")
    @ResponseBody
    public ResponseEntity<?> submitForReview(@PathVariable Long performanceId) {
        performanceApprovalService.submitForReview(performanceId, currentPromoterId());
        return ResponseEntity.ok(Map.of("message", "Review request has been submitted."));
    }

    @GetMapping("/api/performances/{performanceId}/schedules")
    @ResponseBody
    public ResponseEntity<?> getSchedules(@PathVariable Long performanceId) {
        promoterService.verifyPerformanceOwnership(currentPromoterId(), performanceId);
        return ResponseEntity.ok(scheduleMapper.findByPerformanceId(performanceId));
    }

    @PostMapping("/api/performances/{performanceId}/schedules")
    @ResponseBody
    public ResponseEntity<?> createSchedule(@PathVariable Long performanceId,
                                            @RequestBody Map<String, Object> body) {
        promoterService.verifyPerformanceOwnership(currentPromoterId(), performanceId);
        Schedule schedule = new Schedule();
        schedule.setPerformanceId(performanceId);
        schedule.setShowDate(LocalDate.parse((String) body.get("showDate")));
        schedule.setShowTime(LocalTime.parse((String) body.get("showTime")));
        scheduleMapper.insert(schedule);
        return ResponseEntity.ok(Map.of("scheduleId", schedule.getScheduleId(), "message", "Schedule created."));
    }

    @DeleteMapping("/api/performances/{performanceId}/schedules/{scheduleId}")
    @ResponseBody
    public ResponseEntity<?> deleteSchedule(@PathVariable Long performanceId,
                                            @PathVariable Long scheduleId) {
        promoterService.verifyPerformanceOwnership(currentPromoterId(), performanceId);
        scheduleMapper.deleteById(scheduleId);
        return ResponseEntity.ok(Map.of("message", "Schedule removed."));
    }

    @GetMapping("/api/performances/{performanceId}/seat-grades")
    @ResponseBody
    public ResponseEntity<?> getSeatGrades(@PathVariable Long performanceId) {
        promoterService.verifyPerformanceOwnership(currentPromoterId(), performanceId);
        return ResponseEntity.ok(performanceSeatGradeMapper.findByPerformanceId(performanceId));
    }

    @PostMapping("/api/performances/{performanceId}/seat-grades")
    @ResponseBody
    public ResponseEntity<?> saveSeatGrades(@PathVariable Long performanceId,
                                            @RequestBody Map<String, Object> body) {
        promoterService.verifyPerformanceOwnership(currentPromoterId(), performanceId);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> gradeData = (List<Map<String, Object>>) body.get("grades");
        List<PerformanceSeatGrade> grades = gradeData.stream().map(item -> {
            PerformanceSeatGrade grade = new PerformanceSeatGrade();
            grade.setSectionId(((Number) item.get("sectionId")).longValue());
            grade.setGrade((String) item.get("grade"));
            grade.setPrice(((Number) item.get("price")).intValue());
            return grade;
        }).collect(Collectors.toList());
        adminPerformanceService.savePerformanceSeatGrades(performanceId, grades);
        return ResponseEntity.ok(Map.of("message", "Seat grades have been saved."));
    }

    @PostMapping("/api/performances/{performanceId}/seats")
    @ResponseBody
    public ResponseEntity<?> generateSeats(@PathVariable Long performanceId) {
        promoterService.verifyPerformanceOwnership(currentPromoterId(), performanceId);
        int count = adminPerformanceService.generateSeats(performanceId);
        return ResponseEntity.ok(Map.of("count", count, "message", "Performance seats generated."));
    }

    @DeleteMapping("/api/performances/{performanceId}/seats")
    @ResponseBody
    public ResponseEntity<?> deleteSeats(@PathVariable Long performanceId) {
        promoterService.verifyPerformanceOwnership(currentPromoterId(), performanceId);
        int deleted = adminPerformanceService.deleteSeats(performanceId);
        return ResponseEntity.ok(Map.of("count", deleted, "message", "Performance seats deleted."));
    }

    @PostMapping("/api/schedules/{scheduleId}/inventories")
    @ResponseBody
    public ResponseEntity<?> generateInventories(@PathVariable Long scheduleId) {
        adminPerformanceService.generateScheduleInventories(scheduleId);
        return ResponseEntity.ok(Map.of("message", "Seat inventories generated."));
    }

    @GetMapping("/api/performances/{performanceId}/section-overrides")
    @ResponseBody
    public ResponseEntity<?> getSectionOverrides(@PathVariable Long performanceId) {
        promoterService.verifyPerformanceOwnership(currentPromoterId(), performanceId);
        return ResponseEntity.ok(performanceSectionOverrideMapper.findByPerformanceId(performanceId));
    }

    @PostMapping("/api/performances/{performanceId}/section-overrides")
    @ResponseBody
    public ResponseEntity<?> upsertSectionOverride(@PathVariable Long performanceId,
                                                   @RequestBody Map<String, Object> body) {
        promoterService.verifyPerformanceOwnership(currentPromoterId(), performanceId);
        PerformanceSectionOverride override = new PerformanceSectionOverride();
        override.setPerformanceId(performanceId);
        override.setSectionId(((Number) body.get("sectionId")).longValue());
        override.setActive(!Boolean.FALSE.equals(body.get("isActive")));
        override.setCustomRows(body.get("customRows") != null
                ? ((Number) body.get("customRows")).intValue() : null);
        override.setCustomSeatsPerRow(body.get("customSeatsPerRow") != null
                ? ((Number) body.get("customSeatsPerRow")).intValue() : null);
        override.setNote((String) body.getOrDefault("note", ""));
        adminPerformanceService.savePerformanceSectionOverride(performanceId, override);
        return ResponseEntity.ok(Map.of("message", "Section override saved."));
    }

    @GetMapping("/api/venues/{venueId}/stage-configs")
    @ResponseBody
    public ResponseEntity<?> getStageConfigs(@PathVariable Long venueId) {
        return ResponseEntity.ok(venueStageConfigMapper.findByVenueId(venueId));
    }

    @GetMapping("/api/venues/{venueId}/sections")
    @ResponseBody
    public ResponseEntity<?> getSections(@PathVariable Long venueId) {
        return ResponseEntity.ok(venueAdminService.findSectionsByVenueId(venueId));
    }
}
