package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter @NoArgsConstructor
public class VenueSeatTemplate {
    private Long templateId;
    private Long venueId;
    private Long sectionId;
    private String seatRow;
    private int seatNumber;
    private String seatType; // NORMAL, ACCESSIBLE, OBSTRUCTED, AISLE
    // join 결과
    private String sectionName;
}
