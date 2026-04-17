package com.ticketlegacy.exception;

public class PaymentFailedException extends BusinessException {
    public PaymentFailedException() { super(ErrorCode.PAYMENT_FAILED); }
    public PaymentFailedException(String detail) { super(ErrorCode.PAYMENT_FAILED, detail); }
    public PaymentFailedException(String detail, Throwable cause) {
        super(ErrorCode.PAYMENT_FAILED, detail);
    }
}
