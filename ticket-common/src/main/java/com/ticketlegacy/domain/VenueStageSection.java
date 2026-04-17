package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter @NoArgsConstructor
public class VenueStageSection {
    private Long id;
    private Long configId;
    private Long sectionId;
    private boolean active;
    private Integer customRows;           // null이면 venue_section 기본값
    private Integer customSeatsPerRow;    // null이면 venue_section 기본값
    // join
    private String sectionName;
    private String sectionType;
    private int defaultRows;              // venue_section.total_rows
    private int defaultSeatsPerRow;       // venue_section.seats_per_row

    /** 실제 사용될 행 수 (override 없으면 venue_section 기본값) */
    public int effectiveRows() {
        return customRows != null ? customRows : defaultRows;
    }

    /** 실제 사용될 열 수 */
    public int effectiveSeatsPerRow() {
        return customSeatsPerRow != null ? customSeatsPerRow : defaultSeatsPerRow;
    }
}
