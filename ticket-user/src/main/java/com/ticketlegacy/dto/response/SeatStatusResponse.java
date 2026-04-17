package com.ticketlegacy.dto.response;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class SeatStatusResponse {
    private Long seatId;
    private String section;
    private String seatRow;
    private int seatNumber;
    private String grade;
    private int price;
    private String status; // AVAILABLE, MY_HOLD, HELD, RESERVED
    private Long expiresAt; // MY_HOLD일 때만 세팅 (ms timestamp)
}
