package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.Inquiry;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.service.InquiryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;

@Controller
public class InquiryController {

    @Autowired
    private InquiryService inquiryService;

    @GetMapping("/inquiry/list")
    public String list(@RequestParam(defaultValue = "1") int page,
                       HttpServletRequest request, Model model) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) return "redirect:/member/login";

        int size = 10;
        List<Inquiry> list = inquiryService.getMyInquiries(memberId, page, size);
        int total = inquiryService.getMyInquiryCount(memberId);

        model.addAttribute("inquiries", list);
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", (int) Math.ceil((double) total / size));
        return "inquiry/list";
    }

    @GetMapping("/inquiry/write")
    public String writeForm(HttpServletRequest request) {
        if (request.getAttribute("loginMemberId") == null) return "redirect:/member/login";
        return "inquiry/write";
    }

    @PostMapping("/api/inquiry")
    @ResponseBody
    public ApiResponse<String> write(@RequestBody Map<String, String> payload, HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) return ApiResponse.error("로그인이 필요합니다.");

        Inquiry inquiry = new Inquiry();
        inquiry.setMemberId(memberId);
        inquiry.setCategory(payload.get("category"));
        inquiry.setTitle(payload.get("title"));
        inquiry.setContent(payload.get("content"));

        inquiryService.writeInquiry(inquiry);
        return ApiResponse.success("문의가 등록되었습니다.");
    }

    @GetMapping("/inquiry/detail/{id}")
    public String detail(@PathVariable Long id, HttpServletRequest request, Model model) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) return "redirect:/member/login";

        Inquiry inquiry = inquiryService.getInquiry(id, memberId);
        model.addAttribute("inquiry", inquiry);
        return "inquiry/detail";
    }

    @DeleteMapping("/api/inquiry/{id}")
    @ResponseBody
    public ApiResponse<String> delete(@PathVariable Long id, HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) return ApiResponse.error("로그인이 필요합니다.");

        inquiryService.deleteInquiry(id, memberId);
        return ApiResponse.success("삭제되었습니다.");
    }
}
