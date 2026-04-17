package com.ticketlegacy.service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ticketlegacy.domain.Reservation;
import com.ticketlegacy.domain.ReservationSeat;
import com.ticketlegacy.domain.SeatInventory;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.repository.ReservationMapper;
import com.ticketlegacy.repository.SeatInventoryMapper;

@Service
public class ReservationService {
    private static final Logger log = LoggerFactory.getLogger(ReservationService.class);

    @Autowired private ReservationMapper reservationMapper;
    @Autowired private SeatInventoryMapper seatInventoryMapper;
    @Autowired private com.ticketlegacy.repository.ScheduleMapper scheduleMapper;

    /** 예약 생성 (PENDING 상태) */
    @Transactional
    public Reservation createReservation(Long scheduleId, Long memberId, List<SeatInventory> heldSeats) {
        int totalAmount = heldSeats.stream().mapToInt(SeatInventory::getPrice).sum();
        String reservationNo = generateReservationNo();

        Reservation reservation = new Reservation();
        reservation.setReservationNo(reservationNo);
        reservation.setScheduleId(scheduleId);
        reservation.setMemberId(memberId);
        reservation.setTotalAmount(totalAmount);
        reservation.setSeatCount(heldSeats.size());
        reservationMapper.insert(reservation);

        List<ReservationSeat> seats = heldSeats.stream().map(inv -> {
            ReservationSeat rs = new ReservationSeat();
            rs.setReservationId(reservation.getReservationId());
            rs.setSeatId(inv.getSeatId());
            rs.setPrice(inv.getPrice());
            return rs;
        }).collect(Collectors.toList());
        reservationMapper.insertSeats(seats);

        log.info("예약 생성: reservationNo={}, memberId={}, seats={}", reservationNo, memberId, heldSeats.size());
        return reservation;
    }

    public Reservation findById(Long reservationId) {
        Reservation r = reservationMapper.findById(reservationId);
        if (r == null) throw new BusinessException(ErrorCode.RESERVATION_NOT_FOUND);
        return r;
    }

    public List<Reservation> findByMemberId(Long memberId, int page, int size) {
        return reservationMapper.findByMemberId(memberId, (page - 1) * size, size);
    }

    public List<Reservation> findByMember(Long memberId, int page, int size) {
        return findByMemberId(memberId, page, size);
    }

    public List<Reservation> findByMemberWithStatus(Long memberId, String status, int page, int size) {
        return reservationMapper.findByMemberIdAndStatus(memberId, status, (page - 1) * size, size);
    }

    public int countByMemberWithStatus(Long memberId, String status) {
        return reservationMapper.countByMemberIdAndStatus(memberId, status);
    }

    @Transactional
    public void cancel(Long reservationId, Long memberId) {
        Reservation reservation = findById(reservationId);
        if (!reservation.getMemberId().equals(memberId)) {
            throw new BusinessException(ErrorCode.AUTH_FORBIDDEN);
        }
        if (!"PENDING".equals(reservation.getStatus()) && !"CONFIRMED".equals(reservation.getStatus())) {
            throw new BusinessException(ErrorCode.RESERVATION_CANCEL_FAILED, "취소할 수 없는 상태입니다.");
        }

        // 1. 예약 상태 CANCELLED
        reservationMapper.updateStatus(reservationId, "CANCELLED");

        // 2. 좌석 인벤토리 RESERVED → AVAILABLE 복구
        List<Long> seatIds = reservation.getSeats().stream()
                .map(com.ticketlegacy.domain.ReservationSeat::getSeatId)
                .collect(Collectors.toList());

        if (!seatIds.isEmpty()) {
            seatInventoryMapper.releaseReservedSeats(reservation.getScheduleId(), seatIds);

            // 3. schedule available_seats 복구
            scheduleMapper.increaseAvailableSeats(reservation.getScheduleId(), seatIds.size());

            // 4. Redis에서 해당 좌석 RESERVED 상태 제거 → 다른 사람이 선점 가능
            String hashKey = "schedule:" + reservation.getScheduleId() + ":seat_status";
            for (Long seatId : seatIds) {
                try {
                    redisTemplate.opsForHash().delete(hashKey, String.valueOf(seatId));
                } catch (Exception e) {
                    log.warn("취소 후 Redis 좌석 상태 제거 실패: seatId={}, {}", seatId, e.getMessage());
                }
            }
        }

        log.info("예약 취소 완료: reservationId={}, 복구 좌석 수={}", reservationId, seatIds.size());
    }

    @Transactional
    public void cancelByOperator(Long reservationId) {
        Reservation reservation = findById(reservationId);
        if (!"PENDING".equals(reservation.getStatus()) && !"CONFIRMED".equals(reservation.getStatus())) {
            throw new BusinessException(ErrorCode.RESERVATION_CANCEL_FAILED, "Only pending or confirmed reservations can be cancelled.");
        }

        reservationMapper.updateStatus(reservationId, "CANCELLED");

        List<Long> seatIds = reservation.getSeats().stream()
                .map(com.ticketlegacy.domain.ReservationSeat::getSeatId)
                .collect(Collectors.toList());

        if (!seatIds.isEmpty()) {
            seatInventoryMapper.releaseReservedSeats(reservation.getScheduleId(), seatIds);
            scheduleMapper.increaseAvailableSeats(reservation.getScheduleId(), seatIds.size());

            String hashKey = "schedule:" + reservation.getScheduleId() + ":seat_status";
            for (Long seatId : seatIds) {
                try {
                    redisTemplate.opsForHash().delete(hashKey, String.valueOf(seatId));
                } catch (Exception e) {
                    log.warn("Staff cancellation cleanup failed for seatId={}: {}", seatId, e.getMessage());
                }
            }
        }

        log.info("Operator cancellation completed: reservationId={}, restoredSeats={}",
                reservationId, seatIds.size());
    }

    // Redis 없는 프로젝트(ticket-admin)에서도 컴파일·구동 가능하도록 required=false.
    // ticket-user에서는 RedisConfig가 StringRedisTemplate 빈을 등록하므로 정상 주입됨.
    // Redis가 null일 때 좌석 상태 정리 실패는 이미 try-catch로 graceful degradation 처리.
    @Autowired(required = false) private StringRedisTemplate redisTemplate;

    @Transactional
    public Reservation create(Long memberId, Long scheduleId, List<Long> seatIds, int totalAmount) {
        if (redisTemplate == null) {
            throw new BusinessException(ErrorCode.AUTH_FORBIDDEN, "Redis가 설정되지 않아 좌석 선점 검증을 수행할 수 없습니다.");
        }
        String hashKey = "schedule:" + scheduleId + ":seat_status";
        long now = System.currentTimeMillis();

        // [중요] DB가 아니라 Redis 100% 기반 선점이므로 여기서 락 유효성을 검증해야 합니다.
        for (Long seatId : seatIds) {
            Object val = redisTemplate.opsForHash().get(hashKey, String.valueOf(seatId));
            if (val == null || "RESERVED".equals(val.toString())) {
                throw new BusinessException(ErrorCode.AUTH_FORBIDDEN, "선점되지 않았거나 이미 예약된 좌석입니다.");
            }
            String valStr = val.toString();
            if (!valStr.startsWith(memberId + ":")) {
                throw new BusinessException(ErrorCode.AUTH_FORBIDDEN, "본인이 선점한 좌석이 아닙니다.");
            }
            long expiresAt = Long.parseLong(valStr.split(":")[1]);
            if (expiresAt < now) {
                throw new BusinessException(ErrorCode.AUTH_FORBIDDEN, "좌석 선점 시간이 만료되었습니다.");
            }
        }

        List<SeatInventory> heldSeats = seatInventoryMapper.findByScheduleAndSeatIds(scheduleId, seatIds);
        return createReservation(scheduleId, memberId, heldSeats);
    }

    private String generateReservationNo() {
        String date = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String uid = UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase();
        return "TL-" + date + "-" + uid;
    }
}
