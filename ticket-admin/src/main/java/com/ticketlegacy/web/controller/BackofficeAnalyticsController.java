package com.ticketlegacy.web.controller;

import com.ticketlegacy.repository.AnalyticsMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 백오피스 — 시스템 통계 API 컨트롤러.
 * URL: /backoffice/super/api/analytics/**
 * security-context.xml: /backoffice/super/** → hasRole('SUPER_ADMIN')
 *
 * 차트/KPI 데이터 제공 전용 (SELECT ONLY, 사이드 이펙트 없음)
 */
@Controller
@RequestMapping("/backoffice/super/api/analytics")
public class BackofficeAnalyticsController {

    @Autowired private AnalyticsMapper analyticsMapper;

    /** 플랫폼 KPI 요약 (대시보드 상단 카드) */
    @GetMapping("/kpi")
    @ResponseBody
    public ResponseEntity<?> kpiSummary() {
        return ResponseEntity.ok(analyticsMapper.findPlatformKpiSummary());
    }

    /** 최근 7일 일별 예약 트렌드 (선 그래프) */
    @GetMapping("/daily-trend")
    @ResponseBody
    public ResponseEntity<?> dailyTrend(
            @RequestParam(defaultValue = "7") int days) {
        return ResponseEntity.ok(analyticsMapper.findDailyReservationTrend(days));
    }

    /** 월별 매출 트렌드 (막대 그래프) */
    @GetMapping("/monthly-revenue")
    @ResponseBody
    public ResponseEntity<?> monthlyRevenue(
            @RequestParam(defaultValue = "12") int months) {
        return ResponseEntity.ok(analyticsMapper.findMonthlyRevenueTrend(months));
    }

    /** 카테고리별 공연 분포 (도넛 차트) */
    @GetMapping("/category-dist")
    @ResponseBody
    public ResponseEntity<?> categoryDist() {
        return ResponseEntity.ok(analyticsMapper.findPerformanceCategoryStats());
    }

    /** 시간대별 예약 트래픽 */
    @GetMapping("/hourly-traffic")
    @ResponseBody
    public ResponseEntity<?> hourlyTraffic() {
        return ResponseEntity.ok(analyticsMapper.findReservationByHour());
    }

    /** TOP 기획사 매출 */
    @GetMapping("/top-promoters")
    @ResponseBody
    public ResponseEntity<?> topPromoters(
            @RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(analyticsMapper.findTopPromotersByRevenue(limit));
    }

    /** TOP 공연 매출 */
    @GetMapping("/top-performances")
    @ResponseBody
    public ResponseEntity<?> topPerformances(
            @RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(analyticsMapper.findTopPerformancesByRevenue(limit));
    }

    /** 좌석 등급별 판매 분포 */
    @GetMapping("/seat-grade-dist")
    @ResponseBody
    public ResponseEntity<?> seatGradeDist() {
        return ResponseEntity.ok(analyticsMapper.findSeatGradeSalesDistribution());
    }

    /** 종합 통계 한 번에 조회 */
    @GetMapping("/all")
    @ResponseBody
    public ResponseEntity<?> allStats() {
        return ResponseEntity.ok(Map.of(
            "kpi",            analyticsMapper.findPlatformKpiSummary(),
            "dailyTrend",     analyticsMapper.findDailyReservationTrend(7),
            "monthlyRevenue", analyticsMapper.findMonthlyRevenueTrend(12),
            "categoryDist",   analyticsMapper.findPerformanceCategoryStats(),
            "topPromoters",   analyticsMapper.findTopPromotersByRevenue(5),
            "topPerformances",analyticsMapper.findTopPerformancesByRevenue(5)
        ));
    }
}
