package com.ticketlegacy.web.controller;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ticketlegacy.domain.Performance;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.service.PerformanceSearchService;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
public class SearchController {

    @Autowired
    private PerformanceSearchService searchService;
    
    @Autowired
    private StringRedisTemplate redisTemplate;

    private static final String TRENDING_KEY = "search:trending";

    @Autowired
    private com.ticketlegacy.repository.PerformanceMapper performanceMapper;

    @GetMapping("/api/search")
    public ApiResponse<List<Map<String, Object>>> search(
            @RequestParam String q,
            @RequestParam(defaultValue = "1") int page) {
        
        // 실시간 인기 검색어 점수 증가
        if (q != null && !q.trim().isEmpty()) {
            redisTemplate.opsForZSet().incrementScore(TRENDING_KEY, q.trim(), 1);
        }
        
        return ApiResponse.success(searchService.search(q, page, 10));
    }

    @GetMapping("/api/search/trending")
    public ApiResponse<List<String>> getTrending() {
        Set<String> trending = redisTemplate.opsForZSet().reverseRange(TRENDING_KEY, 0, 9);
        return ApiResponse.success(new java.util.ArrayList<>(trending));
    }

    @GetMapping("/api/search/suggest")
    public ApiResponse<List<String>> suggest(@RequestParam String q) {
        if (q == null || q.trim().length() < 2) {
            return ApiResponse.success(List.of());
        }
        return ApiResponse.success(searchService.suggest(q));
    }

    @GetMapping("/api/search/reindex")
    public ApiResponse<String> reindex() {
        // 모든 공연 정보를 조회하여 ES에 인덱싱 (findAll 인자 9개에 맞춰 수정)
        searchService.reindexAll(performanceMapper.findAll(null, null, null, null, null, null, null, 0, 1000));
        return ApiResponse.success("전체 인덱싱이 완료되었습니다.");
    }
}
