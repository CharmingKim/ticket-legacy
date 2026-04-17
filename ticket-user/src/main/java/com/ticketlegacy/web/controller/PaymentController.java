package com.ticketlegacy.web.controller;

import com.ticketlegacy.domain.Payment;
import com.ticketlegacy.dto.request.PaymentRequest;
import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.service.PaymentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;

@Controller
public class PaymentController {

    @Autowired private PaymentService paymentService;

    @PostMapping("/api/payment/process")
    @ResponseBody
    public ApiResponse<Payment> processPayment(@RequestBody @Valid PaymentRequest request,
                                                HttpServletRequest httpRequest) {
        Long memberId = (Long) httpRequest.getAttribute("loginMemberId");
        Payment payment = paymentService.processPayment(request, memberId);
        return ApiResponse.success(payment);
    }
}
