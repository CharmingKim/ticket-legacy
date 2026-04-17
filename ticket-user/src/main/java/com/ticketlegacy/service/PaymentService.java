package com.ticketlegacy.service;

import com.ticketlegacy.domain.Payment;
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
            discountAmount = couponService.validateAndCalculateDiscount(request.getCouponCode(), request.getAmount());
            request.setAmount(Math.max(0, request.getAmount() - discountAmount));
        }

        Payment payment = new Payment();
        payment.setReservationId(request.getReservationId());
        payment.setIdempotencyKey(idempotencyKey);
        payment.setAmount(request.getAmount());
        payment.setMethod(request.getMethod());
        paymentMapper.insert(payment);

        boolean pgSuccess = simulatePgPayment(request);
        String hashKey = "schedule:" + request.getScheduleId() + ":seat_status";

        if (pgSuccess) {
            String pgTxId = "PG-" + System.currentTimeMillis();
            try {
                paymentMapper.updateCompleted(payment.getPaymentId(), pgTxId);
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
                        payment.getPaymentId(), request.getReservationId(), request.getAmount());
                payment.setStatus("COMPLETED");
                payment.setPgTransactionId(pgTxId);
            } catch (Exception e) {
                log.error("결제 확정 중 DB 오류 — PG 취소 시도: pgTxId={}", pgTxId, e);
                throw new PaymentFailedException("결제 확정 실패", e);
            }
        } else {
            paymentMapper.updateFailed(payment.getPaymentId(), "PG사 결제 거절");
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
