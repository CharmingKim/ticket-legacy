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
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

@Service
public class PaymentService {
    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);

    @Autowired private PaymentMapper paymentMapper;
    @Autowired private SeatInventoryMapper seatInventoryMapper;
    @Autowired private ReservationMapper reservationMapper;
    @Autowired private ScheduleMapper scheduleMapper;
    @Autowired private StringRedisTemplate redisTemplate;
    @Autowired private CouponService couponService;

    /** PortOne REST API 키 — root-context.xml 또는 application.properties에 portone.imp-key 로 설정 */
    @Value("${portone.imp-key:}")
    private String portoneImpKey;

    /** PortOne REST API 시크릿 — root-context.xml 또는 application.properties에 portone.imp-secret 으로 설정 */
    @Value("${portone.imp-secret:}")
    private String portoneImpSecret;

    private final RestTemplate restTemplate = new RestTemplate();

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
        
        // 결제 금액 위변조 검증 방어 (Phase 2)
        if (request.getAmount() != finalAmount) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, 
                    "결제 요청 금액이 위변조되었습니다. (요청: " + request.getAmount() + "원, 정상: " + finalAmount + "원)");
        }

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

        boolean pgSuccess = verifyPortOnePayment(request, finalAmount);
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

    /**
     * PortOne(아임포트) 결제 무결성 검증
     *
     * <p><b>샌드박스 모드</b>: portone.imp-key / portone.imp-secret 가 설정되지 않은 경우.
     *    impUid 가 존재하면 결제 성공으로 간주합니다. 개발/테스트 환경용.
     * <p><b>프로덕션 모드</b>: API 키가 설정된 경우 PortOne REST API 를 호출하여 실제 결제 금액을 검증합니다.
     */
    @SuppressWarnings("unchecked")
    private boolean verifyPortOnePayment(PaymentRequest request, int expectedAmount) {
        String impUid = request.getImpUid();

        // 0원 결제 (전액 쿠폰 등) — PG 연동 불필요
        if (expectedAmount <= 0) {
            log.info("0원 결제 — PG 검증 생략: reservationId={}", request.getReservationId());
            return true;
        }

        if (impUid == null || impUid.isBlank()) {
            log.warn("PortOne imp_uid 가 전달되지 않았습니다. reservationId={}", request.getReservationId());
            return false;
        }

        // ── 샌드박스 모드 (API 키 미설정 시 자동 활성화) ──────────────────────────
        boolean sandboxMode = portoneImpKey == null || portoneImpKey.isBlank()
                           || portoneImpSecret == null || portoneImpSecret.isBlank();
        if (sandboxMode) {
            log.warn("[SANDBOX] PortOne API 키 미설정 — 결제 검증 생략. impUid={}, amount={}", impUid, expectedAmount);
            log.warn("[SANDBOX] 프로덕션 전 root-context.xml 에 portone.imp-key / portone.imp-secret 을 설정하세요.");
            return true;
        }

        // ── 프로덕션 모드 — PortOne REST API 검증 ────────────────────────────────
        try {
            // 1) 액세스 토큰 발급
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            java.util.Map<String, String> authReq = java.util.Map.of(
                "imp_key",    portoneImpKey,
                "imp_secret", portoneImpSecret
            );
            HttpEntity<java.util.Map<String, String>> entity = new HttpEntity<>(authReq, headers);
            ResponseEntity<java.util.Map> authRes = restTemplate.postForEntity(
                "https://api.iamport.kr/users/getToken", entity, java.util.Map.class
            );
            String token = (String) ((java.util.Map<?, ?>) authRes.getBody().get("response")).get("access_token");

            // 2) 결제 상세 조회 및 금액 검증
            HttpHeaders getHeaders = new HttpHeaders();
            getHeaders.setBearerAuth(token);
            HttpEntity<Void> getEntity = new HttpEntity<>(getHeaders);
            ResponseEntity<java.util.Map> payRes = restTemplate.exchange(
                "https://api.iamport.kr/payments/" + impUid,
                HttpMethod.GET, getEntity, java.util.Map.class
            );
            java.util.Map<String, Object> responseNode =
                (java.util.Map<String, Object>) payRes.getBody().get("response");
            Integer pgAmount = (Integer) responseNode.get("amount");
            String pgStatus  = (String)  responseNode.get("status");

            if ("paid".equals(pgStatus) && expectedAmount == pgAmount) {
                log.info("포트원 결제 검증 성공: impUid={}, amount={}", impUid, pgAmount);
                return true;
            }
            log.warn("포트원 결제 불일치: impUid={}, pgAmount={}, expectedAmount={}, pgStatus={}",
                     impUid, pgAmount, expectedAmount, pgStatus);
            return false;

        } catch (Exception e) {
            log.error("포트원 REST API 호출 실패: impUid={}, err={}", impUid, e.getMessage());
            return false; // 프로덕션 모드에서 검증 실패 시 결제 거절
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public void refund(Long reservationId, String reason) {
        Payment payment = paymentMapper.findByReservationId(reservationId);
        if (payment == null) {
            log.info("환불할 결제 내역이 없습니다 (reservationId={}). PENDING 예약 취소일 수 있습니다.", reservationId);
            return; // 결제된 내역이 없으면 (예: 아직 PENDING 상태에서 취소) 그냥 넘어감
        }

        if (!"COMPLETED".equals(payment.getStatus())) {
            log.warn("결제가 완료 상태가 아니어서 환불할 수 없습니다: paymentId={}, status={}", payment.getId(), payment.getStatus());
            return;
        }

        Reservation reservation = reservationMapper.findById(reservationId);
        int refundAmount = calculateRefundAmount(reservation, payment.getFinalAmount());

        if (refundAmount <= 0) {
            throw new BusinessException(ErrorCode.RESERVATION_CANCEL_FAILED, "환불 가능한 금액이 없습니다. (수수료 100% 또는 관람일 지남)");
        }

        // 실제 PG사 환불 API 호출 모사
        log.info("PG 결제 환불 시뮬레이션: paymentId={}, 원래결제액={}, 환불진행액={}, 사유={}", 
                 payment.getId(), payment.getFinalAmount(), refundAmount, reason);

        // 환불 금액이 기존 결제 금액보다 적으면 부분 취소지만 현재 모델에서는 전액 취소 후 환불 처리로 간주
        paymentMapper.updateRefunded(payment.getId(), reason);
        log.info("결제 환불 완료: paymentId={}, reservationId={}, refundAmount={}", payment.getId(), reservationId, refundAmount);

        // 쿠폰을 사용했던 결제라면 쿠폰 복구 (단, 수수료가 발생하지 않은 100% 환불의 경우에만 복구하는 것이 일반적)
        if ((payment.getCouponId() != null || payment.getDiscountAmount() > 0) && refundAmount == payment.getFinalAmount()) {
            couponService.restoreCoupon(reservationId);
        }
    }

    /**
     * 관람일 기준 취소 수수료 계산 (Phase 1-5)
     * 관람일 10일 전: 전액 환불
     * 관람일 7~9일 전: 10% 수수료
     * 관람일 3~6일 전: 20% 수수료
     * 관람일 1~2일 전: 30% 수수료
     * 공연 당일 및 이후: 환불 불가 (0 반환)
     */
    private int calculateRefundAmount(Reservation reservation, int finalAmount) {
        if (reservation.getShowDate() == null) {
            // 날짜 정보가 없으면 전액 환불
            return finalAmount;
        }
        
        java.time.LocalDate today = java.time.LocalDate.now();
        java.time.LocalDate showDate = reservation.getShowDate();
        
        long daysBetween = java.time.temporal.ChronoUnit.DAYS.between(today, showDate);
        
        if (daysBetween >= 10) {
            return finalAmount; // 0% 수수료
        } else if (daysBetween >= 7) {
            return (int) (finalAmount * 0.9); // 10% 수수료
        } else if (daysBetween >= 3) {
            return (int) (finalAmount * 0.8); // 20% 수수료
        } else if (daysBetween >= 1) {
            return (int) (finalAmount * 0.7); // 30% 수수료
        } else {
            return 0; // 당일 이후 환불 불가
        }
    }
}
