package com.ticketlegacy.service;

import com.ticketlegacy.domain.Reservation;
import com.ticketlegacy.domain.Schedule;
import com.ticketlegacy.repository.EntranceLogMapper;
import com.ticketlegacy.repository.MemberMapper;
import com.ticketlegacy.repository.PortalQueryMapper;
import com.ticketlegacy.repository.ReservationMapper;
import com.ticketlegacy.repository.ScheduleMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class PortalDashboardService {

    private static final DateTimeFormatter YEAR_MONTH_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM");

    private final PerformanceApprovalService performanceApprovalService;
    private final PromoterService promoterService;
    private final VenueManagerService venueManagerService;
    private final VenueAdminService venueAdminService;
    private final MemberMapper memberMapper;
    private final ReservationMapper reservationMapper;
    private final ScheduleMapper scheduleMapper;
    private final EntranceLogMapper entranceLogMapper;
    private final PortalQueryMapper portalQueryMapper;

    public Map<String, Object> getPromoterDashboard(Long promoterId) {
        Map<String, Object> finance = portalQueryMapper.findPromoterFinancialSummary(promoterId);
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("totalPerformances", performanceApprovalService.countByPromoter(promoterId, null));
        summary.put("draftCount", performanceApprovalService.countByPromoter(promoterId, "DRAFT"));
        summary.put("reviewCount", performanceApprovalService.countByPromoter(promoterId, "REVIEW"));
        summary.put("publishedCount", performanceApprovalService.countByPromoter(promoterId, "PUBLISHED"));
        summary.put("confirmedReservations", metric(finance, "confirmedReservations", "confirmed_reservations"));
        summary.put("grossSales", metric(finance, "grossSales", "gross_sales"));
        summary.put("refundCount", metric(finance, "refundCount", "refund_count"));
        return summary;
    }

    public List<Map<String, Object>> getPromoterSalesRows(Long promoterId) {
        return portalQueryMapper.findPromoterSalesRows(promoterId);
    }

    public List<Map<String, Object>> getSettlementRows(Long promoterId, String yearMonth) {
        return portalQueryMapper.findSettlementRows(promoterId, normalizeYearMonth(yearMonth));
    }

    public Map<String, Object> getVenueDashboard(Long venueId) {
        List<Schedule> schedules = scheduleMapper.findByVenueId(venueId);
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("totalSections", venueAdminService.findSectionsByVenueId(venueId).size());
        summary.put("totalSchedules", schedules.size());
        summary.put("upcomingSchedules", scheduleMapper.findUpcomingByVenueId(venueId, 5).size());
        summary.put("checkedInToday", entranceLogMapper.countByVenueIdAndDate(venueId, LocalDate.now()));
        summary.put("templateSeatCount", venueAdminService.getTemplateCount(venueId));
        return summary;
    }

    public List<Schedule> getVenueCalendar(Long venueId) {
        return scheduleMapper.findByVenueId(venueId);
    }

    public List<Schedule> getUpcomingVenueSchedules(Long venueId, int limit) {
        return scheduleMapper.findUpcomingByVenueId(venueId, limit);
    }

    public List<Map<String, Object>> searchEntranceCandidates(Long venueId, String showDate, String keyword) {
        return portalQueryMapper.findEntranceCandidates(venueId, showDate, keyword);
    }

    public Map<String, Object> getBackofficeSummary() {
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("totalMembers", memberMapper.countAll());
        summary.put("pendingPromoters", promoterService.countByStatus("PENDING"));
        summary.put("pendingVenueManagers", venueManagerService.countByStatus("PENDING"));
        summary.put("reviewPerformances", performanceApprovalService.countAll("REVIEW"));
        summary.put("todayReservations", reservationMapper.countToday());
        summary.put("todayConfirmedReservations", reservationMapper.countConfirmedToday());
        summary.put("cancelledReservations", reservationMapper.countByStatus("CANCELLED"));
        summary.put("approvedPromoters", promoterService.countByStatus("APPROVED"));
        summary.put("venues", venueAdminService.findAllVenues().size());
        return summary;
    }

    public List<Reservation> getRecentReservations(int limit) {
        return reservationMapper.searchByKeyword(null, null, 0, limit);
    }

    public Map<String, Object> getSettlementSummary(Long promoterId, String yearMonth) {
        String ym = normalizeYearMonth(yearMonth);
        List<Map<String, Object>> rows = portalQueryMapper.findSettlementRows(promoterId, ym);
        long totalGross    = rows.stream().mapToLong(r -> toLong(r.get("gross_sales"))).sum();
        long totalFee      = rows.stream().mapToLong(r -> toLong(r.get("platform_fee"))).sum();
        long totalPayable  = rows.stream().mapToLong(r -> toLong(r.get("payable_amount"))).sum();
        int  totalRsvCount = rows.stream().mapToInt(r -> toInt(r.get("confirmed_reservations"))).sum();

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("rows",          rows);
        result.put("yearMonth",     ym);
        result.put("totalGross",    totalGross);
        result.put("totalFee",      totalFee);
        result.put("totalPayable",  totalPayable);
        result.put("totalRsvCount", totalRsvCount);
        return result;
    }

    public String defaultYearMonth() {
        return YearMonth.now().format(YEAR_MONTH_FORMAT);
    }

    private String normalizeYearMonth(String yearMonth) {
        if (yearMonth == null || yearMonth.isBlank()) {
            return defaultYearMonth();
        }
        return yearMonth;
    }

    private int toInt(Object value) {
        if (value == null) return 0;
        if (value instanceof Number) return ((Number) value).intValue();
        try { return Integer.parseInt(value.toString()); } catch (Exception e) { return 0; }
    }

    private long toLong(Object value) {
        if (value == null) return 0L;
        if (value instanceof Number) return ((Number) value).longValue();
        try { return Long.parseLong(value.toString()); } catch (Exception e) { return 0L; }
    }

    private int metric(Map<String, Object> source, String... keys) {
        if (source == null) {
            return 0;
        }
        for (String key : keys) {
            if (source.containsKey(key) && source.get(key) != null) {
                return toInt(source.get(key));
            }
        }
        return 0;
    }
}
