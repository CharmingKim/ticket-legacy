package com.ticketlegacy.repository;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;
import java.util.Map;

/**
 * 대시보드/통계 전용 쿼리 매퍼 (SELECT ONLY)
 * 집계 쿼리를 PortalQueryMapper와 분리해 관리
 */
@Mapper
public interface AnalyticsMapper {

    /** 최근 7일 일별 예약/매출 트렌드 */
    List<Map<String, Object>> findDailyReservationTrend(@Param("days") int days);

    /** 카테고리별 공연 분포 */
    List<Map<String, Object>> findPerformanceCategoryStats();

    /** 월별 매출 집계 (최근 12개월) */
    List<Map<String, Object>> findMonthlyRevenueTrend(@Param("months") int months);

    /** 시간대별 예약 분포 */
    List<Map<String, Object>> findReservationByHour();

    /** TOP 10 기획사 매출 */
    List<Map<String, Object>> findTopPromotersByRevenue(@Param("limit") int limit);

    /** TOP 10 공연 매출 */
    List<Map<String, Object>> findTopPerformancesByRevenue(@Param("limit") int limit);

    /** 좌석 등급별 판매 비율 */
    List<Map<String, Object>> findSeatGradeSalesDistribution();

    /** 전체 플랫폼 KPI 요약 */
    Map<String, Object> findPlatformKpiSummary();
}
