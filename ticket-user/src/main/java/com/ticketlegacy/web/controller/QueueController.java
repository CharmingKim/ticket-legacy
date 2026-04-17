package com.ticketlegacy.web.controller;

import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.dto.response.QueuePositionResponse;
import com.ticketlegacy.service.QueueService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;

@Controller
public class QueueController {

    @Autowired private QueueService queueService;

    @GetMapping("/queue/waiting")
    public String waitingPage(@RequestParam Long scheduleId, Model model) {
        model.addAttribute("scheduleId", scheduleId);
        return "queue/waiting";
    }

    @PostMapping("/api/queue/enter")
    @ResponseBody
    public ApiResponse<QueuePositionResponse> enter(@RequestParam Long scheduleId,
                                                     HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        return ApiResponse.success(queueService.enterQueue(scheduleId, memberId));
    }

    @GetMapping("/api/queue/position")
    @ResponseBody
    public ApiResponse<QueuePositionResponse> position(@RequestParam Long scheduleId,
                                                        HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        return ApiResponse.success(queueService.getPosition(scheduleId, memberId));
    }
}
