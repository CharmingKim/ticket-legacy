package com.ticketlegacy.repository;

import com.ticketlegacy.domain.PerformanceSeatGrade;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface PerformanceSeatGradeMapper {
    int insertBatch(@Param("grades") List<PerformanceSeatGrade> grades);
    List<PerformanceSeatGrade> findByPerformanceId(@Param("performanceId") Long performanceId);
    int deleteByPerformanceId(@Param("performanceId") Long performanceId);
}
