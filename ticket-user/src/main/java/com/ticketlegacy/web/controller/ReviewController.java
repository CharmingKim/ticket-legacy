package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.PerformanceReview;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.service.ReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import javax.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/reviews")
public class ReviewController {

    @Autowired private ReviewService reviewService;

    @GetMapping("/{performanceId}")
    public ApiResponse<Map<String, Object>> getReviews(
            @PathVariable Long performanceId,
            @RequestParam(defaultValue = "1") int page) {
        
        int size = 5;
        List<PerformanceReview> list = reviewService.findByPerformanceId(performanceId, page, size);
        int total = reviewService.countByPerformanceId(performanceId);
        Double avgRating = reviewService.getAverageRating(performanceId);
        
        return ApiResponse.success(Map.of(
            "list", list,
            "total", total,
            "avgRating", avgRating != null ? avgRating : 0.0,
            "page", page,
            "totalPages", (int) Math.ceil((double) total / size)
        ));
    }

    @PostMapping("/{performanceId}")
    public ApiResponse<String> addReview(
            @PathVariable Long performanceId,
            @RequestBody Map<String, Object> payload,
            HttpServletRequest request) {
        
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) {
            return ApiResponse.error("로그인이 필요합니다.");
        }
        
        int rating = Integer.parseInt(payload.getOrDefault("rating", "5").toString());
        String content = (String) payload.getOrDefault("content", "");
        
        if (content.trim().isEmpty()) {
            return ApiResponse.error("내용을 입력해주세요.");
        }

        reviewService.addReview(performanceId, memberId, rating, content);
        return ApiResponse.success("관람평이 등록되었습니다.");
    }

    @PutMapping("/{reviewId}")
    public ApiResponse<String> updateReview(
            @PathVariable Long reviewId,
            @RequestBody Map<String, Object> payload,
            HttpServletRequest request) {
        
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) {
            return ApiResponse.error("로그인이 필요합니다.");
        }
        
        int rating = Integer.parseInt(payload.getOrDefault("rating", "5").toString());
        String content = (String) payload.getOrDefault("content", "");
        
        reviewService.updateReview(reviewId, memberId, rating, content);
        return ApiResponse.success("수정되었습니다.");
    }

    @DeleteMapping("/{reviewId}")
    public ApiResponse<String> deleteReview(
            @PathVariable Long reviewId,
            HttpServletRequest request) {
        
        Long memberId = (Long) request.getAttribute("loginMemberId");
        if (memberId == null) {
            return ApiResponse.error("로그인이 필요합니다.");
        }
        
        reviewService.deleteReview(reviewId, memberId);
        return ApiResponse.success("삭제되었습니다.");
    }
}
