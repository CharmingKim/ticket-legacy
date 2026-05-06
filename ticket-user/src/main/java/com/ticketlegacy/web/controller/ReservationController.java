package com.ticketlegacy.web.controller;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import javax.servlet.http.HttpServletRequest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.ticketlegacy.domain.Coupon;
import com.ticketlegacy.domain.Reservation;
import com.ticketlegacy.domain.Schedule;
import com.ticketlegacy.domain.SeatInventory;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.repository.ScheduleMapper;
import com.ticketlegacy.repository.SeatInventoryMapper;
import com.ticketlegacy.domain.Member;
import com.ticketlegacy.service.CouponService;
import com.ticketlegacy.service.MemberService;
import com.ticketlegacy.service.PaymentService;
import com.ticketlegacy.service.ReservationService;

@Controller
public class ReservationController {

    @Autowired private ReservationService reservationService;
    @Autowired private PaymentService paymentService;
    @Autowired private MemberService memberService;
    @Autowired private ScheduleMapper scheduleMapper;
    @Autowired private SeatInventoryMapper seatInventoryMapper;
    @Autowired private CouponService couponService;

    @GetMapping("/reservation/confirm")
    public String confirmPage(@RequestParam Long scheduleId,
                               @RequestParam String seatIds,
                               HttpServletRequest request, Model model) {
        Long memberId = (Long) request.getAttribute("loginMemberId");

        List<Long> seatIdList = Arrays.stream(seatIds.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(Long::valueOf)
                .collect(Collectors.toList());

        Schedule schedule = scheduleMapper.findById(scheduleId);
        List<SeatInventory> seats = seatIdList.isEmpty()
                ? Collections.emptyList()
                : seatInventoryMapper.findByScheduleAndSeatIds(scheduleId, seatIdList);
        int totalAmount = seats.stream().mapToInt(SeatInventory::getPrice).sum();
        List<Coupon> coupons = memberId != null
                ? couponService.findByMemberId(memberId)
                : Collections.emptyList();
        Member member = memberId != null ? memberService.findById(memberId) : null;

        model.addAttribute("schedule", schedule);
        model.addAttribute("seats", seats);
        model.addAttribute("totalAmount", totalAmount);
        model.addAttribute("coupons", coupons);
        model.addAttribute("member", member);
        model.addAttribute("scheduleId", scheduleId);
        model.addAttribute("seatIds", seatIds);
        return "reservation/confirm";
    }

    @GetMapping("/reservation/history")
    public String historyPage(@RequestParam(defaultValue = "1") int page,
                               HttpServletRequest request, Model model) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        int size = 10;
        List<Reservation> list  = reservationService.findByMemberId(memberId, page, size);
        int total       = reservationService.countByMemberWithStatus(memberId, null);
        int totalPages  = (int) Math.ceil((double) total / size);
        model.addAttribute("reservations",  list);
        model.addAttribute("currentPage",   page);
        model.addAttribute("totalPages",    totalPages);
        return "reservation/history";
    }

    @GetMapping("/reservation/detail/{reservationId}")
    public String detailPage(@PathVariable Long reservationId,
                             HttpServletRequest request, Model model) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        Reservation reservation = reservationService.findById(reservationId);
        
        if (!reservation.getMemberId().equals(memberId)) {
            return "redirect:/"; // 권한 없음
        }
        
        model.addAttribute("reservation", reservation);
        return "reservation/detail";
    }

    @GetMapping("/reservation/ticket/{reservationId}")
    public String ticketPage(@PathVariable Long reservationId,
                             HttpServletRequest request, Model model) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        Reservation reservation = reservationService.findById(reservationId);
        
        if (!reservation.getMemberId().equals(memberId) || !"CONFIRMED".equals(reservation.getStatus())) {
            return "redirect:/"; // 권한 없거나 결제 안됨
        }
        
        model.addAttribute("reservation", reservation);
        return "reservation/ticket";
    }

    @PostMapping("/api/reservation/{reservationId}/cancel")
    @ResponseBody
    public ApiResponse<String> cancel(@PathVariable Long reservationId,
                                       HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        
        // 1. 결제 환불 및 쿠폰 복구 (Phase 3 엣지 케이스 처리)
        // 이 로직은 결제가 완료된(CONFIRMED) 예약에 대해서만 수행됩니다.
        paymentService.refund(reservationId, "사용자 본인 취소");
        
        // 2. 예약 상태 변경 및 좌석 반환
        reservationService.cancel(reservationId, memberId);
        
        return ApiResponse.success("예약이 취소되었습니다.");
    }

    @PostMapping("/api/reservations/{reservationId}/cancel")
    @ResponseBody
    public ApiResponse<String> cancelAlias(@PathVariable Long reservationId,
                                            HttpServletRequest request) {
        return cancel(reservationId, request);
    }

    @PostMapping("/api/reservation/create")
    @ResponseBody
    public ApiResponse<Map<String, Object>> create(@RequestBody Map<String, Object> body,
                                                    HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");

        Object scheduleIdRaw = body.get("scheduleId");
        Object seatIdsRaw = body.get("seatIds");
        if (scheduleIdRaw == null || seatIdsRaw == null) {
            return ApiResponse.error("scheduleId와 seatIds는 필수입니다.");
        }
        Long scheduleId = Long.valueOf(scheduleIdRaw.toString());
        @SuppressWarnings("unchecked")
        List<Object> seatIdsObj = (List<Object>) seatIdsRaw;
        List<Long> seatIds = seatIdsObj.stream()
                .map(v -> ((Number) v).longValue())
                .collect(java.util.stream.Collectors.toList());
        int totalAmount = body.get("totalAmount") != null
                ? ((Number) body.get("totalAmount")).intValue() : 0;

        Reservation reservation = reservationService.create(memberId, scheduleId, seatIds, totalAmount);

        Map<String, Object> data = new HashMap<>();
        data.put("reservationId", reservation.getReservationId());
        data.put("reservationNo", reservation.getReservationNo());
        return ApiResponse.success(data);
    }
}
