package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.Reservation;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.dto.request.MemberSearchQuery;
import com.ticketlegacy.dto.request.MemberStatusCommand;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.dto.response.MemberSummaryDto;
import com.ticketlegacy.dto.response.PageResponse;
import com.ticketlegacy.service.MemberService;
import com.ticketlegacy.service.PortalDashboardService;
import com.ticketlegacy.service.ReservationService;
import com.ticketlegacy.web.support.AuthMember;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import javax.validation.Valid;
import java.util.List;
import java.util.Map;

@Controller
@RequiredArgsConstructor
@RequestMapping("/backoffice/staff")
public class BackofficeStaffController {

    private final PortalDashboardService portalDashboardService;
    private final MemberService          memberService;
    private final ReservationService     reservationService;

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
        List<Reservation> list = reservationService.searchReservations(keyword, status, page, pageSize);
        int total = reservationService.countReservations(keyword, status);
        return ResponseEntity.ok(Map.of("list", list, "total", total, "page", page));
    }

    @GetMapping("/api/reservations/{reservationId}")
    @ResponseBody
    public ResponseEntity<?> reservationDetail(@PathVariable Long reservationId) {
        return ResponseEntity.ok(reservationService.findById(reservationId));
    }

    @PostMapping("/api/reservations/{reservationId}/cancel")
    @ResponseBody
    public ResponseEntity<?> cancelReservation(@PathVariable Long reservationId) {
        reservationService.cancelByOperator(reservationId);
        return ResponseEntity.ok(Map.of("message", "Reservation has been cancelled by staff."));
    }

    @GetMapping("/api/members")
    @ResponseBody
    public ResponseEntity<ApiResponse<PageResponse<MemberSummaryDto>>> searchMembers(
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
}
