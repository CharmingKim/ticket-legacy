package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
public class Venue {
    private Long venueId;
    private String apiFacilityId; // KOPIS 공연장 ID (mt10id)
    private String name;
    private String address;
    private Integer seatScale;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
