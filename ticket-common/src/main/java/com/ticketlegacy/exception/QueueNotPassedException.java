package com.ticketlegacy.exception;

public class QueueNotPassedException extends BusinessException {
    public QueueNotPassedException() { super(ErrorCode.QUEUE_NOT_PASSED); }
}
