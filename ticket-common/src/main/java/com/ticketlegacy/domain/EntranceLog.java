package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
public class EntranceLog {
    private Long entranceLogId;
    private Long reservationId;
    private Long scheduleId;
    private Long venueId;
    private Long memberId;
    private Long checkedInBy;
    private String note;
    private LocalDateTime checkedInAt;
    private LocalDateTime createdAt;

    private String reservationNo;
    private String performanceTitle;
    private String memberName;
    private String memberPhone;
    private LocalDate showDate;
    private LocalTime showTime;
}
