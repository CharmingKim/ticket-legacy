package com.ticketlegacy.repository;

import com.ticketlegacy.domain.PerformanceReview;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface ReviewMapper {
    List<PerformanceReview> findByPerformanceId(@Param("performanceId") Long performanceId, @Param("offset") int offset, @Param("limit") int limit);
    int countByPerformanceId(@Param("performanceId") Long performanceId);
    int insert(PerformanceReview review);
    int delete(@Param("reviewId") Long reviewId, @Param("memberId") Long memberId);
    int update(@Param("reviewId") Long reviewId, @Param("memberId") Long memberId, @Param("rating") int rating, @Param("content") String content);
    Double getAverageRating(@Param("performanceId") Long performanceId);
    
    List<PerformanceReview> findByMemberId(@Param("memberId") Long memberId, @Param("offset") int offset, @Param("limit") int limit);
    int countByMemberId(@Param("memberId") Long memberId);
}
