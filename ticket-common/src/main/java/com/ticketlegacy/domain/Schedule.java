package com.ticketlegacy.domain;

import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Getter @Setter @NoArgsConstructor
public class Schedule {
    private Long scheduleId;
    private Long performanceId;
    private Long venueId;
    private LocalDate showDate;
    private LocalTime showTime;
    private int availableSeats;
    private String status;
    private int maxSeatsPerOrder;  // 1인당 최대 예매 수 (기본 4)
    private String performanceTitle;
    private String venue;
    private String performanceStatus;
    private String approvalStatus;

    // JSP alias: startDatetime → showDate + showTime 조합
    public LocalDateTime getStartDatetime() {
        if (showDate == null) return null;
        return showTime != null ? showDate.atTime(showTime) : showDate.atStartOfDay();
    }
}
