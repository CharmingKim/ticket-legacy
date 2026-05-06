package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.PerformanceReview;
import com.ticketlegacy.service.ReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

import javax.servlet.http.HttpServletRequest;
import java.util.List;

@Controller
public class MemberReviewController {

    @Autowired private ReviewService reviewService;

    @GetMapping("/member/my-reviews")
    public String myReviews(@RequestParam(defaultValue = "1") int page,
                            HttpServletRequest request, Model model) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) {
            return "redirect:/member/login";
        }
        
        int size = 10;
        List<PerformanceReview> list = reviewService.findByMemberId(memberId, page, size);
        int total = reviewService.countByMemberId(memberId);
        
        model.addAttribute("reviews", list);
        model.addAttribute("total", total);
        model.addAttribute("currentPage", page);
        model.addAttribute("totalPages", (int) Math.ceil((double) total / size));
        
        return "member/my-reviews";
    }
}
