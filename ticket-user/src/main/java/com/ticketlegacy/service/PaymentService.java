package com.ticketlegacy.service;

import com.ticketlegacy.domain.Payment;
import com.ticketlegacy.domain.Reservation;
import com.ticketlegacy.dto.request.PaymentRequest;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.exception.PaymentFailedException;
import com.ticketlegacy.repository.*;
import com.ticketlegacy.util.IdempotencyKeyGenerator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PaymentService {
    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);

    @Autowired private PaymentMapper paymentMapper;
    @Autowired private SeatInventoryMapper seatInventoryMapper;
    @Autowired private ReservationMapper reservationMapper;
    @Autowired private ScheduleMapper scheduleMapper;
    @Autowired private StringRedisTemplate redisTemplate;
    @Autowired private CouponService couponService;

    @Transactional(isolation = Isolation.REPEATABLE_READ, rollbackFor = Exception.class)
    public Payment processPayment(PaymentRequest request, Long memberId) {
        Reservation reservation = reservationMapper.findById(request.getReservationId());
        if (reservation == null) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "예약을 찾을 수 없습니다.");
        }
        if (!memberId.equals(reservation.getMemberId())) {
            throw new BusinessException(ErrorCode.AUTH_FORBIDDEN, "본인 예약만 결제할 수 있습니다.");
        }
        if (!"PENDING".equals(reservation.getStatus())) {
            throw new BusinessException(ErrorCode.INVALID_INPUT,
                    "결제 가능한 예약 상태가 아닙니다. (현재: " + reservation.getStatus() + ")");
        }
        int baseAmount = reservation.getTotalAmount();

        String idempotencyKey = IdempotencyKeyGenerator.generate(
                memberId, request.getScheduleId(), request.getSeatIds());

        Payment existing = paymentMapper.findByIdempotencyKey(idempotencyKey);
        if (existing != null) {
            if ("COMPLETED".equals(existing.getStatus())) {
                log.info("중복 결제 요청 차단: idempotencyKey={}", idempotencyKey);
                return existing;
            }
            if ("FAILED".equals(existing.getStatus())) {
                log.info("실패 결제 재시도: idempotencyKey={}", idempotencyKey);
            }
        }

        int discountAmount = 0;
        if (request.getCouponCode() != null && !request.getCouponCode().isBlank()) {
            discountAmount = couponService.validateAndCalculateDiscount(request.getCouponCode(), baseAmount);
        }
        int finalAmount = Math.max(0, baseAmount - discountAmount);
        request.setAmount(finalAmount);

        Payment payment = new Payment();
        payment.setReservationId(request.getReservationId());
        payment.setMemberId(memberId);
        payment.setIdempotencyKey(idempotencyKey);
        payment.setAmount(baseAmount);
        payment.setDiscountAmount(discountAmount);
        payment.setFinalAmount(finalAmount);
        payment.setMethod(request.getMethod());
        payment.setStatus("PENDING");
        paymentMapper.insert(payment);

        boolean pgSuccess = simulatePgPayment(request);
        String hashKey = "schedule:" + request.getScheduleId() + ":seat_status";

        if (pgSuccess) {
            String pgTxId = "PG-" + System.currentTimeMillis();
            try {
                paymentMapper.updateCompleted(payment.getId(), pgTxId);
                seatInventoryMapper.updateToReserved(request.getScheduleId(), request.getSeatIds(), memberId);
                reservationMapper.updateConfirmed(request.getReservationId());
                scheduleMapper.decreaseAvailableSeats(request.getScheduleId(), request.getSeatIds().size());

                if (request.getCouponCode() != null && !request.getCouponCode().isBlank()) {
                    try {
                        couponService.useCoupon(request.getCouponCode(), request.getReservationId());
                    } catch (Exception e) {
                        log.warn("쿠폰 사용 처리 실패 (결제는 완료): couponCode={}, err={}", request.getCouponCode(), e.getMessage());
                    }
                }

                for (Long seatId : request.getSeatIds()) {
                    try { redisTemplate.opsForHash().put(hashKey, String.valueOf(seatId), "RESERVED"); }
                    catch (Exception e) { log.warn("Redis 결제 확정 상태 반영 실패: {}", e.getMessage()); }
                }

                log.info("결제 완료: paymentId={}, reservationId={}, amount={}",
                        payment.getId(), request.getReservationId(), finalAmount);
                payment.setStatus("COMPLETED");
                payment.setPgTransactionId(pgTxId);
            } catch (Exception e) {
                log.error("결제 확정 중 DB 오류 — PG 취소 시도: pgTxId={}", pgTxId, e);
                throw new PaymentFailedException("결제 확정 실패", e);
            }
        } else {
            paymentMapper.updateFailed(payment.getId(), "PG사 결제 거절");
            reservationMapper.updateStatus(request.getReservationId(), "CANCELLED");
            for (Long seatId : request.getSeatIds()) {
                try { redisTemplate.opsForHash().delete(hashKey, String.valueOf(seatId)); }
                catch (Exception e) { /* ignore */ }
            }
            throw new PaymentFailedException("PG사 결제 거절");
        }
        return payment;
    }

    private boolean simulatePgPayment(PaymentRequest request) {
        return true;
    }
}
