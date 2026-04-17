package com.ticketlegacy.domain;

import lombok.*;

@Getter @Setter @NoArgsConstructor
public class ReservationSeat {
    private Long id;
    private Long reservationId;
    private Long seatId;
    private int price;
    private String section;
    private String seatRow;
    private int seatNumber;
    private String grade;
}
