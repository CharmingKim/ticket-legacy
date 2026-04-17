package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.Schedule;
import com.ticketlegacy.domain.VenueSection;
import com.ticketlegacy.domain.VenueStageConfig;
import com.ticketlegacy.domain.VenueStageSection;
import com.ticketlegacy.service.EntranceService;
import com.ticketlegacy.service.PortalDashboardService;
import com.ticketlegacy.service.VenueAdminService;
import com.ticketlegacy.service.VenueManagerService;
import com.ticketlegacy.repository.ScheduleMapper;
import com.ticketlegacy.repository.VenueStageConfigMapper;
import com.ticketlegacy.repository.VenueStageSectionMapper;
import com.ticketlegacy.web.support.AuthMember;
import com.ticketlegacy.web.support.LoginUser;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Controller
@RequiredArgsConstructor
@RequestMapping("/partner/venue")
public class PartnerVenueController {

    private final VenueManagerService venueManagerService;
    private final VenueAdminService venueAdminService;
    private final VenueStageConfigMapper venueStageConfigMapper;
    private final VenueStageSectionMapper venueStageSectionMapper;
    private final ScheduleMapper scheduleMapper;
    private final PortalDashboardService portalDashboardService;
    private final EntranceService entranceService;

    private Long currentVenueId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return ((LoginUser) auth.getPrincipal()).getVenueId();
    }

    private Long currentMemberId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return ((LoginUser) auth.getPrincipal()).getMemberId();
    }

    @GetMapping("/dashboard")
    public String dashboard(Model model) {
        Long venueId = currentVenueId();
        model.addAttribute("venue", venueAdminService.findVenueById(venueId));
        model.addAttribute("summary", portalDashboardService.getVenueDashboard(venueId));
        model.addAttribute("upcomingSchedules", portalDashboardService.getUpcomingVenueSchedules(venueId, 8));
        return "partner/venue/dashboard";
    }

    @GetMapping("/venue-info")
    public String venueInfo(Model model) {
        Long venueId = currentVenueId();
        model.addAttribute("venue", venueAdminService.findVenueById(venueId));
        model.addAttribute("sections", venueAdminService.findSectionsByVenueId(venueId));
        model.addAttribute("stageConfigs", venueStageConfigMapper.findByVenueId(venueId));
        return "partner/venue/venue-info";
    }

    @GetMapping("/schedule-calendar")
    public String scheduleCalendar(Model model) {
        Long venueId = currentVenueId();
        model.addAttribute("venue", venueAdminService.findVenueById(venueId));
        model.addAttribute("schedules", portalDashboardService.getVenueCalendar(venueId));
        return "partner/venue/schedule-calendar";
    }

    @GetMapping("/entrance")
    public String entrance(Model model) {
        model.addAttribute("today", LocalDate.now().toString());
        return "partner/venue/entrance";
    }

    @GetMapping("/api/dashboard/summary")
    @ResponseBody
    public ResponseEntity<?> dashboardSummary() {
        return ResponseEntity.ok(portalDashboardService.getVenueDashboard(currentVenueId()));
    }

    @GetMapping("/api/schedules/calendar")
    @ResponseBody
    public ResponseEntity<?> scheduleCalendarData() {
        return ResponseEntity.ok(portalDashboardService.getVenueCalendar(currentVenueId()));
    }

    @GetMapping("/api/entrance")
    @ResponseBody
    public ResponseEntity<?> entranceCandidates(@RequestParam(required = false) String showDate,
                                                @RequestParam(required = false) String keyword) {
        return ResponseEntity.ok(portalDashboardService.searchEntranceCandidates(currentVenueId(), showDate, keyword));
    }

    @PostMapping("/api/entrance/check-in")
    @ResponseBody
    public ResponseEntity<?> checkIn(@RequestBody Map<String, String> body) {
        String reservationNo = body.get("reservationNo");
        String note = body.getOrDefault("note", "");
        return ResponseEntity.ok(Map.of(
                "message", "Guest checked in successfully.",
                "entry", entranceService.checkIn(currentVenueId(), reservationNo, currentMemberId(), note)
        ));
    }

    @GetMapping("/api/venues/my")
    @ResponseBody
    public ResponseEntity<?> getMyVenue() {
        return ResponseEntity.ok(venueAdminService.findVenueById(currentVenueId()));
    }

    @GetMapping("/api/venues/{venueId}/sections")
    @ResponseBody
    public ResponseEntity<?> getSections(@PathVariable Long venueId, @AuthMember Long memberId) {
        venueManagerService.verifyVenueOwnership(memberId, venueId);
        return ResponseEntity.ok(venueAdminService.findSectionsByVenueId(venueId));
    }

    @PostMapping("/api/venues/{venueId}/sections")
    @ResponseBody
    public ResponseEntity<?> addSection(@PathVariable Long venueId,
                                        @RequestBody Map<String, Object> body,
                                        @AuthMember Long memberId) {
        venueManagerService.verifyVenueOwnership(memberId, venueId);
        VenueSection section = venueAdminService.addSection(
                venueId,
                (String) body.get("sectionName"),
                (String) body.getOrDefault("sectionType", "FLOOR"),
                ((Number) body.getOrDefault("totalRows", 1)).intValue(),
                ((Number) body.getOrDefault("seatsPerRow", 1)).intValue(),
                ((Number) body.getOrDefault("displayOrder", 0)).intValue()
        );
        return ResponseEntity.ok(Map.of("sectionId", section.getSectionId(), "message", "Section created."));
    }

    @DeleteMapping("/api/venues/{venueId}/sections/{sectionId}")
    @ResponseBody
    public ResponseEntity<?> deleteSection(@PathVariable Long venueId,
                                           @PathVariable Long sectionId,
                                           @AuthMember Long memberId) {
        venueManagerService.verifyVenueOwnership(memberId, venueId);
        venueAdminService.deleteSection(sectionId);
        return ResponseEntity.ok(Map.of("message", "Section removed."));
    }

    @PostMapping("/api/venues/{venueId}/template")
    @ResponseBody
    public ResponseEntity<?> generateTemplate(@PathVariable Long venueId, @AuthMember Long memberId) {
        venueManagerService.verifyVenueOwnership(memberId, venueId);
        int count = venueAdminService.generateTemplate(venueId);
        return ResponseEntity.ok(Map.of("count", count, "message", "Seat template regenerated."));
    }

    @GetMapping("/api/venues/{venueId}/stage-configs")
    @ResponseBody
    public ResponseEntity<?> getStageConfigs(@PathVariable Long venueId, @AuthMember Long memberId) {
        venueManagerService.verifyVenueOwnership(memberId, venueId);
        return ResponseEntity.ok(venueStageConfigMapper.findByVenueId(venueId));
    }

    @PostMapping("/api/venues/{venueId}/stage-configs")
    @ResponseBody
    public ResponseEntity<?> createStageConfig(@PathVariable Long venueId,
                                               @RequestBody Map<String, Object> body,
                                               @AuthMember Long memberId) {
        venueManagerService.verifyVenueOwnership(memberId, venueId);
        VenueStageConfig config = new VenueStageConfig();
        config.setVenueId(venueId);
        config.setConfigName((String) body.get("configName"));
        config.setDescription((String) body.getOrDefault("description", ""));
        config.setDefaultConfig(Boolean.TRUE.equals(body.get("isDefault")));
        venueStageConfigMapper.insert(config);
        return ResponseEntity.ok(Map.of("configId", config.getConfigId(), "message", "Stage configuration created."));
    }

    @DeleteMapping("/api/venues/{venueId}/stage-configs/{configId}")
    @ResponseBody
    public ResponseEntity<?> deleteStageConfig(@PathVariable Long venueId,
                                               @PathVariable Long configId,
                                               @AuthMember Long memberId) {
        venueManagerService.verifyVenueOwnership(memberId, venueId);
        venueStageConfigMapper.deleteById(configId);
        return ResponseEntity.ok(Map.of("message", "Stage configuration removed."));
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
        VenueStageSection stageSection = new VenueStageSection();
        stageSection.setConfigId(configId);
        stageSection.setSectionId(((Number) body.get("sectionId")).longValue());
        stageSection.setActive(!Boolean.FALSE.equals(body.get("isActive")));
        stageSection.setCustomRows(body.get("customRows") != null
                ? ((Number) body.get("customRows")).intValue() : null);
        stageSection.setCustomSeatsPerRow(body.get("customSeatsPerRow") != null
                ? ((Number) body.get("customSeatsPerRow")).intValue() : null);
        venueStageSectionMapper.upsert(stageSection);
        return ResponseEntity.ok(Map.of("message", "Stage section updated."));
    }
}
