package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
public class Wishlist {
    private Long id;
    private Long memberId;
    private Long performanceId;
    private LocalDateTime createdAt;
    
    // For joining with performance
    private String performanceTitle;
    private String posterUrl;
    private String venueName;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
}
