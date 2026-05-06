package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
public class Waitlist {
    private Long id;
    private Long scheduleId;
    private Long memberId;
    private String status; // WAITING|NOTIFIED|EXPIRED|CANCELLED
    private LocalDateTime createdAt;
    private LocalDateTime notifiedAt;
    
    // Join fields
    private String performanceTitle;
    private LocalDateTime showDate;
    private String showTime;
}
