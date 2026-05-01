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
import com.ticketlegacy.service.CouponService;
import com.ticketlegacy.service.ReservationService;

@Controller
public class ReservationController {

    @Autowired private ReservationService reservationService;
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

        model.addAttribute("schedule", schedule);
        model.addAttribute("seats", seats);
        model.addAttribute("totalAmount", totalAmount);
        model.addAttribute("coupons", coupons);
        model.addAttribute("scheduleId", scheduleId);
        model.addAttribute("seatIds", seatIds);
        return "reservation/confirm";
    }

    @GetMapping("/reservation/history")
    public String historyPage(@RequestParam(defaultValue = "1") int page,
                               HttpServletRequest request, Model model) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        List<Reservation> list = reservationService.findByMemberId(memberId, page, 10);
        model.addAttribute("reservations", list);
        model.addAttribute("currentPage", page);
        return "reservation/history";
    }

    @PostMapping("/api/reservation/{reservationId}/cancel")
    @ResponseBody
    public ApiResponse<String> cancel(@PathVariable Long reservationId,
                                       HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
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
