package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Schedule;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface ScheduleMapper {
    Schedule findById(@Param("scheduleId") Long scheduleId);
    List<Schedule> findByPerformanceId(@Param("performanceId") Long performanceId);
    int insert(Schedule schedule);
    int decreaseAvailableSeats(@Param("scheduleId") Long scheduleId,
                               @Param("count") int count);
    int increaseAvailableSeats(@Param("scheduleId") Long scheduleId,
                               @Param("count") int count);
    int updateAvailableSeats(@Param("scheduleId") Long scheduleId,
                             @Param("count") int count);

    // 공연장별 회차 전체 조회 (performance JOIN으로 venue_id 필터)
    List<Schedule> findByVenueId(@Param("venueId") Long venueId);

    // 공연장별 예정 회차 (show_date >= TODAY, limit)
    List<Schedule> findUpcomingByVenueId(@Param("venueId") Long venueId, @Param("limit") int limit);

    // scheduleId로 삭제
    int deleteById(@Param("scheduleId") Long scheduleId);
}
