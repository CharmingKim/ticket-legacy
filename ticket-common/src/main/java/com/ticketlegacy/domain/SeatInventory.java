package com.ticketlegacy.domain;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor
public class SeatInventory {
    private Long inventoryId;
    private Long scheduleId;
    private Long seatId;
    private String status;
    private String holdType;  // PUBLIC, KILL, COMP, SPONSOR, ADMIN
    private Long heldBy;
    private LocalDateTime heldUntil;
    private int version;
    // JOIN 결과 (seat)
    private String section;
    private String seatRow;
    private int seatNumber;
    private String grade;
    private int price;
}
