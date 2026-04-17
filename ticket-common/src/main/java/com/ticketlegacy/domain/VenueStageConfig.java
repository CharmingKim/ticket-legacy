package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.util.List;

@Getter @Setter @NoArgsConstructor
public class VenueStageConfig {
    private Long configId;
    private Long venueId;
    private String configName;
    private String description;
    private boolean defaultConfig;
    // join
    private String venueName;
    private List<VenueStageSection> sections; // 구역별 설정 목록
}
