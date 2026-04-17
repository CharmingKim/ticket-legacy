package com.ticketlegacy.web.controller;

import com.ticketlegacy.dto.request.SeatHoldRequest;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.dto.response.SeatHoldResult;
import com.ticketlegacy.dto.response.SeatStatusResponse;
import com.ticketlegacy.service.SeatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import java.util.List;

@Controller
public class SeatController {

    @Autowired private SeatService seatService;

    @GetMapping("/seat/select/{scheduleId}")
    public String selectPage(@PathVariable Long scheduleId, Model model) {
        model.addAttribute("scheduleId", scheduleId);
        return "seat/select";
    }

    @GetMapping("/api/seats/{scheduleId}")
    @ResponseBody
    public ApiResponse<List<SeatStatusResponse>> getSeatStatus(@PathVariable Long scheduleId,
                                                                HttpServletRequest httpRequest) {
        Long memberId = (Long) httpRequest.getAttribute("loginMemberId");
        return ApiResponse.success(seatService.getSeatStatus(scheduleId, memberId));
    }

    @PostMapping("/api/seats/hold")
    @ResponseBody
    public ApiResponse<SeatHoldResult> holdSeat(@RequestBody @Valid SeatHoldRequest request,
                                                 HttpServletRequest httpRequest) {
        Long memberId = (Long) httpRequest.getAttribute("loginMemberId");
        SeatHoldResult result = seatService.holdSeat(
                request.getScheduleId(), request.getSeatId(), memberId);
        return ApiResponse.success(result);
    }

    @DeleteMapping("/api/seats/hold/{scheduleId}/{seatId}")
    @ResponseBody
    public ApiResponse<Void> releaseSeat(@PathVariable Long scheduleId,
                                          @PathVariable Long seatId,
                                          HttpServletRequest httpRequest) {
        Long memberId = (Long) httpRequest.getAttribute("loginMemberId");
        seatService.releaseSeat(scheduleId, seatId, memberId);
        return ApiResponse.success(null);
    }

    @PostMapping("/api/seats/hold/release-all")
    @ResponseBody
    public ApiResponse<Void> releaseAll(@RequestBody java.util.Map<String, Object> body,
                                         HttpServletRequest httpRequest) {
        Long memberId = (Long) httpRequest.getAttribute("loginMemberId");
        if (memberId == null) return ApiResponse.success(null);

        Object scheduleIdRaw = body.get("scheduleId");
        Object seatIdsRaw = body.get("seatIds");
        if (scheduleIdRaw == null || seatIdsRaw == null) return ApiResponse.success(null);

        Long scheduleId = Long.valueOf(scheduleIdRaw.toString());
        @SuppressWarnings("unchecked")
        java.util.List<Object> seatIdsObj = (java.util.List<Object>) seatIdsRaw;

        for (Object v : seatIdsObj) {
            Long seatId = ((Number) v).longValue();
            seatService.releaseSeat(scheduleId, seatId, memberId);
        }
        return ApiResponse.success(null);
    }
}
