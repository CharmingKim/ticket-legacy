package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter @NoArgsConstructor
public class VenueSection {
    private Long sectionId;
    private Long venueId;
    private String sectionName;   // 예) A구역, 스탠딩, VIP석
    private String sectionType;   // FLOOR, BALCONY, VIP_BOX, STANDING, PREMIUM
    private int totalRows;
    private int seatsPerRow;
    private int displayOrder;     // 화면 표시 순서
    // join 결과
    private String venueName;
    private int templateCount;    // 생성된 템플릿 좌석 수
}
