package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.Wishlist;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.service.WishlistService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.List;

@Controller
public class WishlistController {

    @Autowired
    private WishlistService wishlistService;

    @PostMapping("/api/wishlist/{performanceId}")
    @ResponseBody
    public ApiResponse<Boolean> toggleWish(@PathVariable Long performanceId, HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) {
            return ApiResponse.error("로그인이 필요합니다.");
        }
        boolean isWished = wishlistService.toggleWish(memberId, performanceId);
        return ApiResponse.success(isWished);
    }

    @GetMapping("/api/wishlist/check/{performanceId}")
    @ResponseBody
    public ApiResponse<Boolean> checkWish(@PathVariable Long performanceId, HttpServletRequest request) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) {
            return ApiResponse.success(false);
        }
        return ApiResponse.success(wishlistService.isWished(memberId, performanceId));
    }

    @GetMapping("/member/wishlist")
    public String wishlistPage(HttpServletRequest request, Model model) {
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) {
            return "redirect:/member/login";
        }
        List<Wishlist> list = wishlistService.getWishlist(memberId);
        model.addAttribute("wishlist", list);
        return "member/wishlist";
    }
}
