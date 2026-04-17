package com.ticketlegacy.domain;

import lombok.*;

@Getter @Setter @NoArgsConstructor
public class Seat {
    private Long seatId;
    private Long performanceId;
    private String section;
    private String seatRow;
    private int seatNumber;
    private String grade;
    private int price;
}
