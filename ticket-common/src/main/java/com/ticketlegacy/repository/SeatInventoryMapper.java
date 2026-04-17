package com.ticketlegacy.repository;

import com.ticketlegacy.domain.SeatInventory;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface SeatInventoryMapper {
    /** 회차별 전체 좌석 + 상태 조회 */
    List<SeatInventory> findByScheduleId(@Param("scheduleId") Long scheduleId);

    /** 좌석 선점: AVAILABLE → HELD */
    int holdSeat(@Param("scheduleId") Long scheduleId,
                 @Param("seatId") Long seatId,
                 @Param("memberId") Long memberId,
                 @Param("holdUntil") LocalDateTime holdUntil);

    /** 여러 개의 판매 대상 좌석 상태를 한 번에 생성합니다 */
    int insertBatch(@Param("inventories") List<SeatInventory> inventories);

    /** 선점 해제: 본인 건만 */
    int releaseSeat(@Param("scheduleId") Long scheduleId,
                    @Param("seatId") Long seatId,
                    @Param("memberId") Long memberId);

    /** 결제 확정: HELD → RESERVED */
    int updateToReserved(@Param("scheduleId") Long scheduleId,
                         @Param("seatIds") List<Long> seatIds,
                         @Param("memberId") Long memberId);

    /** 만료 선점 일괄 해제 */
    int releaseExpiredHolds();
    
    
    /** 예약 생성 시 선점된 좌석들의 인벤토리를 한 번에 조회 */
    List<SeatInventory> findByScheduleAndSeatIds(@Param("scheduleId") Long scheduleId,
                                                  @Param("seatIds") List<Long> seatIds);

    /** 예약 취소 시 RESERVED → AVAILABLE 복구 */
    int releaseReservedSeats(@Param("scheduleId") Long scheduleId,
                              @Param("seatIds") List<Long> seatIds);

    /** 관리자 hold_type 변경 (KILL/COMP/ADMIN 처리) */
    int updateHoldType(@Param("scheduleId") Long scheduleId,
                       @Param("seatIds") List<Long> seatIds,
                       @Param("holdType") String holdType);

    /** PUBLIC+AVAILABLE 좌석 수 (잔여석 재계산용) */
    int countPublicAvailable(@Param("scheduleId") Long scheduleId);

    /** 회차별 RESERVED 좌석 수 */
    int countReservedByScheduleId(@Param("scheduleId") Long scheduleId);

    /** 단일 좌석 인벤토리 조회 (holdType 검증용) */
    SeatInventory findBySeatInSchedule(@Param("scheduleId") Long scheduleId,
                                        @Param("seatId") Long seatId);
}
