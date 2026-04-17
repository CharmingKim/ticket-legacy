package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.Member;
import com.ticketlegacy.domain.Reservation;
import com.ticketlegacy.repository.MemberMapper;
import com.ticketlegacy.repository.ReservationMapper;
import com.ticketlegacy.service.PortalDashboardService;
import com.ticketlegacy.service.ReservationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.List;
import java.util.Map;

@Controller
@RequiredArgsConstructor
@RequestMapping("/backoffice/staff")
public class BackofficeStaffController {

    private final PortalDashboardService portalDashboardService;
    private final ReservationMapper reservationMapper;
    private final MemberMapper memberMapper;
    private final ReservationService reservationService;

    @GetMapping("/dashboard")
    public String dashboard(Model model) {
        model.addAttribute("summary", portalDashboardService.getBackofficeSummary());
        model.addAttribute("recentReservations", portalDashboardService.getRecentReservations(8));
        return "backoffice/staff/dashboard";
    }

    @GetMapping("/reservation-search")
    public String reservationSearch() {
        return "backoffice/staff/reservation-search";
    }

    @GetMapping("/member-search")
    public String memberSearch() {
        return "backoffice/staff/member-search";
    }

    @GetMapping("/api/dashboard/summary")
    @ResponseBody
    public ResponseEntity<?> dashboardSummary() {
        return ResponseEntity.ok(portalDashboardService.getBackofficeSummary());
    }

    @GetMapping("/api/reservations")
    @ResponseBody
    public ResponseEntity<?> searchReservations(@RequestParam(required = false) String keyword,
                                                @RequestParam(required = false) String status,
                                                @RequestParam(defaultValue = "1") int page) {
        int pageSize = 20;
        List<Reservation> list = reservationMapper.searchByKeyword(keyword, status, (page - 1) * pageSize, pageSize);
        int total = reservationMapper.countByKeyword(keyword, status);
        return ResponseEntity.ok(Map.of("list", list, "total", total, "page", page));
    }

    @GetMapping("/api/reservations/{reservationId}")
    @ResponseBody
    public ResponseEntity<?> reservationDetail(@PathVariable Long reservationId) {
        return ResponseEntity.ok(reservationMapper.findById(reservationId));
    }

    @PostMapping("/api/reservations/{reservationId}/cancel")
    @ResponseBody
    public ResponseEntity<?> cancelReservation(@PathVariable Long reservationId) {
        reservationService.cancelByOperator(reservationId);
        return ResponseEntity.ok(Map.of("message", "Reservation has been cancelled by staff."));
    }

    @GetMapping("/api/members")
    @ResponseBody
    public ResponseEntity<?> searchMembers(@RequestParam(required = false) String role,
                                           @RequestParam(required = false) String status,
                                           @RequestParam(required = false) String keyword,
                                           @RequestParam(defaultValue = "1") int page) {
        int pageSize = 20;
        List<Member> list = memberMapper.findAll(role, status, keyword, (page - 1) * pageSize, pageSize);
        int total = memberMapper.countFiltered(role, status, keyword);
        return ResponseEntity.ok(Map.of("list", list, "total", total, "page", page));
    }

    @PostMapping("/api/members/{memberId}/status")
    @ResponseBody
    public ResponseEntity<?> updateMemberStatus(@PathVariable Long memberId,
                                                @RequestBody Map<String, String> body) {
        memberMapper.updateStatus(memberId, body.get("status"));
        return ResponseEntity.ok(Map.of("message", "Member status updated."));
    }
}
