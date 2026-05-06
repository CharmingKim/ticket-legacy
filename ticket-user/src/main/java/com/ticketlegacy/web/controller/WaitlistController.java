package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.Waitlist;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.service.WaitlistService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.List;

@Controller
public class WaitlistController {

    @Autowired
    private WaitlistService waitlistService;

    @PostMapping("/api/waitlist/{scheduleId}")
    @ResponseBody
    public ApiResponse<String> add(@PathVariable Long scheduleId, HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) return ApiResponse.error("로그인이 필요합니다.");
        
        waitlistService.addWaitlist(scheduleId, memberId);
        return ApiResponse.success("예매 대기 신청이 완료되었습니다. 취소표 발생 시 알림을 보내드립니다.");
    }

    @DeleteMapping("/api/waitlist/{scheduleId}")
    @ResponseBody
    public ApiResponse<String> remove(@PathVariable Long scheduleId, HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) return ApiResponse.error("로그인이 필요합니다.");
        
        waitlistService.removeWaitlist(scheduleId, memberId);
        return ApiResponse.success("예매 대기가 취소되었습니다.");
    }

    @GetMapping("/member/waitlist")
    public String myWaitlist(HttpServletRequest request, Model model) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) return "redirect:/member/login";
        
        List<Waitlist> list = waitlistService.getMyWaitlist(memberId);
        model.addAttribute("waitlist", list);
        return "member/waitlist";
    }
}
