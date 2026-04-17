package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter @NoArgsConstructor
public class PerformanceSectionOverride {
    private Long overrideId;
    private Long performanceId;
    private Long sectionId;
    private boolean active;
    private Integer customRows;
    private Integer customSeatsPerRow;
    private String note;
    // join
    private String sectionName;
    private String sectionType;
}
