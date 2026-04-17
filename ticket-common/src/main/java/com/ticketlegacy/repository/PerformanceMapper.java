package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Performance;
import com.ticketlegacy.domain.Schedule;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface PerformanceMapper {
    List<Performance> findAll(@Param("category") String category,
                              @Param("status") String status,
                              @Param("keyword") String keyword,
                              @Param("offset") int offset,
                              @Param("limit") int limit);
    int countAll(@Param("category") String category,
                 @Param("status") String status,
                 @Param("keyword") String keyword);
    Performance findById(@Param("performanceId") Long performanceId);
    Performance findByApiPerfId(@Param("apiPerfId") String apiPerfId);
    int insert(Performance performance);
    int update(Performance performance);
    List<Schedule> findSchedules(@Param("performanceId") Long performanceId);

    /** 기획사 소유 공연 목록 (승인 상태 필터) */
    List<Performance> findByPromoterIdAndApprovalStatus(
            @Param("promoterId") Long promoterId,
            @Param("approvalStatus") String approvalStatus,
            @Param("offset") int offset,
            @Param("limit") int limit);

    int countByPromoterIdAndApprovalStatus(
            @Param("promoterId") Long promoterId,
            @Param("approvalStatus") String approvalStatus);

    /** 전체 공연 목록 (SUPER_ADMIN용, 승인 상태 필터 포함) */
    List<Performance> findAllByApprovalStatus(
            @Param("approvalStatus") String approvalStatus,
            @Param("offset") int offset,
            @Param("limit") int limit);

    int countAllByApprovalStatus(@Param("approvalStatus") String approvalStatus);

    /** 승인 상태 변경 */
    int updateApprovalStatus(
            @Param("performanceId") Long performanceId,
            @Param("approvalStatus") String approvalStatus,
            @Param("approvalNote") String approvalNote,
            @Param("reviewedBy") Long reviewedBy);

    /**
     * [스케줄러] APPROVED + ticket_open_at <= NOW() → PUBLISHED + ON_SALE 자동 전환
     * @return 전환된 공연 수
     */
    int autoPublishApproved();

    /**
     * [스케줄러] end_date 지난 공연 → ENDED 자동 전환
     * @return 전환된 공연 수
     */
    int autoEndExpired();
}
