package com.ticketlegacy.web.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.ticketlegacy.domain.Performance;
import com.ticketlegacy.domain.PerformanceSeatGrade;
import com.ticketlegacy.domain.Schedule;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.repository.PerformanceSeatGradeMapper;
import com.ticketlegacy.service.PerformanceService;

@Controller
public class PerformanceController {

    @Autowired private PerformanceService performanceService;
    @Autowired private com.ticketlegacy.service.PerformanceSearchService searchService;
    @Autowired private PerformanceSeatGradeMapper seatGradeMapper;

    /** 메인 페이지: 랭킹 및 주요 공연 위주 */
    @GetMapping("/")
    public String main(Model model) {
        // 상단 실시간 랭킹 5위까지
        List<Performance> topRanking = performanceService.getTopRanking(5);
        model.addAttribute("topRanking", topRanking);
        
        // 최신 공연 12개
        List<Performance> latest = performanceService.findAll("", "", "", "", "", null, null, 1, 12);
        model.addAttribute("performances", latest);
        
        return "performance/list"; // TODO: 추후 메인 전용 jsp(home.jsp)로 변경 가능
    }

    /** 공연 목록 및 검색 페이지 */
    @GetMapping("/performance/list")
    public String list(@RequestParam(value = "q", required = false) String q,
                       @RequestParam(defaultValue = "") String genre,
                       @RequestParam(defaultValue = "") String status,
                       @RequestParam(defaultValue = "") String keyword,
                       @RequestParam(defaultValue = "") String startDate,
                       @RequestParam(defaultValue = "") String endDate,
                       @RequestParam(required = false) Integer minPrice,
                       @RequestParam(required = false) Integer maxPrice,
                       @RequestParam(defaultValue = "relevance") String sort,
                       @RequestParam(defaultValue = "1") int page,
                       Model model) {
        
        // 검색어(q 또는 keyword)가 있으면 Elasticsearch 사용
        String searchKeyword = (q != null && !q.isEmpty()) ? q : keyword;
        
        int size = 12;
        List<Performance> list;
        int total;

        if (searchKeyword != null && !searchKeyword.isEmpty()) {
            // Elasticsearch 검색 수행 — ES 미연결 시 DB 검색으로 자동 fallback
            List<java.util.Map<String, Object>> esResults = searchService.search(searchKeyword, page, size, sort);
            if (!esResults.isEmpty()) {
                list = new java.util.ArrayList<>();
                for (java.util.Map<String, Object> hit : esResults) {
                    Long id = Long.valueOf(hit.get("performanceId").toString());
                    Performance p = performanceService.findById(id);
                    if (p != null) {
                        p.setDisplayTitle(hit.containsKey("displayTitle") ? (String) hit.get("displayTitle") : p.getTitle());
                        list.add(p);
                    }
                }
                total = list.size();
            } else {
                // ES 미연결 또는 결과 없음 → DB 검색
                list = performanceService.findAll(genre, status, searchKeyword, startDate, endDate, minPrice, maxPrice, page, size);
                total = performanceService.countAll(genre, status, searchKeyword, startDate, endDate, minPrice, maxPrice);
            }
        } else {
            // 일반 DB 목록 조회
            list = performanceService.findAll(genre, status, searchKeyword, startDate, endDate, minPrice, maxPrice, page, size);
            total = performanceService.countAll(genre, status, searchKeyword, startDate, endDate, minPrice, maxPrice);
        }

        int totalPages = (int) Math.ceil((double) total / size);

        model.addAttribute("performances", list);
        model.addAttribute("currentPage",  page);
        model.addAttribute("totalPages",   totalPages);
        model.addAttribute("genre",        genre);
        model.addAttribute("keyword",      searchKeyword);
        model.addAttribute("startDate",    startDate);
        model.addAttribute("endDate",      endDate);
        model.addAttribute("minPrice",     minPrice);
        model.addAttribute("maxPrice",     maxPrice);
        model.addAttribute("sort",         sort);
        return "performance/list";
    }

    @GetMapping("/performance/detail/{id}")
    public String detail(@PathVariable("id") Long performanceId, Model model) {
        Performance perf = performanceService.findById(performanceId);
        List<Schedule> schedules = performanceService.findSchedules(performanceId);
        List<PerformanceSeatGrade> seatGrades = seatGradeMapper.findByPerformanceId(performanceId);
        model.addAttribute("performance", perf);
        model.addAttribute("schedules", schedules);
        model.addAttribute("seatGrades", seatGrades);
        return "performance/detail";
    }

    @GetMapping("/api/performances/{id}/schedules")
    @ResponseBody
    public ApiResponse<List<Schedule>> getSchedules(@PathVariable("id") Long performanceId) {
        return ApiResponse.success(performanceService.findSchedules(performanceId));
    }
}
