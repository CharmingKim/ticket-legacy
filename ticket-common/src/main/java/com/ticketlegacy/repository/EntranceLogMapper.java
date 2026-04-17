package com.ticketlegacy.repository;

import com.ticketlegacy.domain.EntranceLog;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.util.List;

@Mapper
public interface EntranceLogMapper {
    int insert(EntranceLog entranceLog);
    EntranceLog findByReservationId(@Param("reservationId") Long reservationId);
    int countByVenueIdAndDate(@Param("venueId") Long venueId,
                              @Param("targetDate") LocalDate targetDate);
    List<EntranceLog> findByScheduleId(@Param("scheduleId") Long scheduleId);
}
