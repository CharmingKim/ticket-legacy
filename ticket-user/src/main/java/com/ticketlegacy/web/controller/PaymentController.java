package com.ticketlegacy.web.controller;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import com.ticketlegacy.domain.Payment;
import com.ticketlegacy.dto.request.PaymentRequest;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.service.PaymentService;
import com.ticketlegacy.service.ReservationService;

@Controller
public class PaymentController {
    private static final Logger log = LoggerFactory.getLogger(PaymentController.class);

    @Autowired private PaymentService paymentService;
    @Autowired private ReservationService reservationService;

    @PostMapping("/api/payment/process")
    @ResponseBody
    public ApiResponse<Payment> processPayment(@RequestBody @Valid PaymentRequest request,
                                                HttpServletRequest httpRequest) {
        Long memberId = (Long) httpRequest.getAttribute("loginMemberId");
        try {
            Payment payment = paymentService.processPayment(request, memberId);
            return ApiResponse.success(payment);
        } catch (BusinessException ex) {
            cancelOrphanReservation(request.getReservationId(), ex.getMessage());
            throw ex;
        }
    }

    private void cancelOrphanReservation(Long reservationId, String reason) {
        if (reservationId == null) return;
        try {
            reservationService.cancelOrphan(reservationId);
            log.info("결제 실패로 PENDING 예약 자동 취소: reservationId={}, reason={}", reservationId, reason);
        } catch (Exception cleanupEx) {
            log.warn("PENDING 예약 자동 취소 실패: reservationId={}, err={}", reservationId, cleanupEx.getMessage());
        }
    }
}
