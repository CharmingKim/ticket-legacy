package com.ticketlegacy.domain;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PerformanceReview {
    private Long reviewId;
    private Long performanceId;
    private Long memberId;
    private String memberName; // JOIN으로 가져올 작성자 이름
    private int rating;
    private String content;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
