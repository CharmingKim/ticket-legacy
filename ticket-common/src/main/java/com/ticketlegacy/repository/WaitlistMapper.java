package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Waitlist;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface WaitlistMapper {
    int insert(@Param("scheduleId") Long scheduleId, @Param("memberId") Long memberId);
    int delete(@Param("scheduleId") Long scheduleId, @Param("memberId") Long memberId);
    int countByScheduleAndMember(@Param("scheduleId") Long scheduleId, @Param("memberId") Long memberId);
    
    List<Waitlist> findByMemberId(@Param("memberId") Long memberId);
    List<Waitlist> findWaitingByScheduleId(@Param("scheduleId") Long scheduleId);
    
    int updateStatus(@Param("id") Long id, @Param("status") String status);
    int setNotified(@Param("id") Long id);
}
