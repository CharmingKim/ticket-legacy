package com.ticketlegacy.repository;

import com.ticketlegacy.domain.PerformanceSectionOverride;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface PerformanceSectionOverrideMapper {
    int upsert(PerformanceSectionOverride override);
    List<PerformanceSectionOverride> findByPerformanceId(@Param("performanceId") Long performanceId);
    int deleteByPerformanceId(@Param("performanceId") Long performanceId);
    int deleteBySectionAndPerformance(@Param("performanceId") Long performanceId,
                                       @Param("sectionId") Long sectionId);
}
