package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Seat;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface SeatMapper {
    /** 좌석 단건 등록 */
    int insert(Seat seat);
    
    /** 
     * 공연별 템플릿 좌석 일괄(Batch) 등록
     * MyBatis의 foreach를 활용하여 단일 쿼리로 수천 건 Insert
     */
    int insertBatch(@Param("seats") List<Seat> seats);
    
    /** 공연의 전체 템플릿 좌석 조회 (회차 인벤토리 생성 시 사용) */
    List<Seat> findByPerformanceId(@Param("performanceId") Long performanceId);

    /** 공연의 전체 템플릿 좌석 삭제 */
    int deleteByPerformanceId(@Param("performanceId") Long performanceId);
}
