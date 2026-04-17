package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Reservation;
import com.ticketlegacy.domain.ReservationSeat;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface ReservationMapper {

    // ── 기본 CRUD ──────────────────────────────────
    int insert(Reservation reservation);
    int insertSeats(@Param("seats") List<ReservationSeat> seats);

    Reservation findById(@Param("reservationId") Long reservationId);
    Reservation findByReservationNo(@Param("reservationNo") String reservationNo);

    List<Reservation> findByMemberId(@Param("memberId") Long memberId,
                                     @Param("offset") int offset,
                                     @Param("limit") int limit);

    /** 상태 필터 + 페이징 (마이페이지 AJAX용) */
    List<Reservation> findByMemberIdAndStatus(@Param("memberId") Long memberId,
                                              @Param("status") String status,
                                              @Param("offset") int offset,
                                              @Param("limit") int limit);

    int countByMemberIdAndStatus(@Param("memberId") Long memberId,
                                 @Param("status") String status);

    /** 회원 전체 예약 내역 (페이징 없이, CS 조회용) */
    List<Reservation> findAllByMemberId(@Param("memberId") Long memberId);

    int updateStatus(@Param("reservationId") Long reservationId,
                     @Param("status") String status);
    int updateConfirmed(@Param("reservationId") Long reservationId);

    // ── 통계 카운트 ─────────────────────────────────
    /** 오늘 생성된 예약 수 */
    int countToday();

    /** 오늘 CONFIRMED 처리된 예약 수 */
    int countConfirmedToday();

    /** 특정 status 예약 수 */
    int countByStatus(@Param("status") String status);

    // ── 검색 (CS/백오피스 용) ───────────────────────
    /**
     * 키워드 복합 검색 (예약번호 / 회원이름 / 이메일 / 공연명)
     */
    List<Reservation> searchByKeyword(@Param("keyword") String keyword,
                                      @Param("status") String status,
                                      @Param("offset") int offset,
                                      @Param("limit") int limit);

    int countByKeyword(@Param("keyword") String keyword,
                       @Param("status") String status);
}
