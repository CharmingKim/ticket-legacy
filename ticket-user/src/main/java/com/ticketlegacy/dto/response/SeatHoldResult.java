package com.ticketlegacy.dto.response;

import lombok.*;

@Getter @AllArgsConstructor
public class SeatHoldResult {
    private Long seatId;
    private Long expiresAt;
    private boolean held;

    public static SeatHoldResult success(Long seatId, long expiresAtMs) {
        return new SeatHoldResult(seatId, expiresAtMs, true);
    }
}
