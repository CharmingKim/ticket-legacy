package com.ticketlegacy.exception;

public class SeatAlreadyHeldException extends BusinessException {
    public SeatAlreadyHeldException() { super(ErrorCode.SEAT_ALREADY_HELD); }
    public SeatAlreadyHeldException(String detail) { super(ErrorCode.SEAT_ALREADY_HELD, detail); }
}
