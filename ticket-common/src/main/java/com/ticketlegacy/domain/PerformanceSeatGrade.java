package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter @NoArgsConstructor
public class PerformanceSeatGrade {
    private Long gradeId;
    private Long performanceId;
    private Long sectionId;
    private String grade;  // VIP, R, S, A
    private int price;
    // join 결과
    private String sectionName;
    private String sectionType;
    private int totalRows;
    private int seatsPerRow;
}
