package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.Performance;
import com.ticketlegacy.domain.Schedule;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.service.PerformanceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Controller
public class PerformanceController {

    @Autowired private PerformanceService performanceService;

    @GetMapping({"/", "/performance/list"})
    public String list(@RequestParam(defaultValue = "") String category,
                       @RequestParam(defaultValue = "") String status,
                       @RequestParam(defaultValue = "") String keyword,
                       @RequestParam(defaultValue = "1") int page,
                       Model model) {
        int size = 12;
        List<Performance> list  = performanceService.findAll(category, status, keyword, page, size);
        int total      = performanceService.countAll(category, status, keyword);
        int totalPages = (int) Math.ceil((double) total / size);

        model.addAttribute("performances", list);
        model.addAttribute("currentPage",  page);
        model.addAttribute("totalPages",   totalPages);
        model.addAttribute("category",     category);
        model.addAttribute("keyword",      keyword);
        return "performance/list";
    }

    @GetMapping("/performance/detail/{id}")
    public String detail(@PathVariable("id") Long performanceId, Model model) {
        Performance perf = performanceService.findById(performanceId);
        List<Schedule> schedules = performanceService.findSchedules(performanceId);
        model.addAttribute("performance", perf);
        model.addAttribute("schedules", schedules);
        return "performance/detail";
    }

    @GetMapping("/api/performances/{id}/schedules")
    @ResponseBody
    public ApiResponse<List<Schedule>> getSchedules(@PathVariable("id") Long performanceId) {
        return ApiResponse.success(performanceService.findSchedules(performanceId));
    }
}
