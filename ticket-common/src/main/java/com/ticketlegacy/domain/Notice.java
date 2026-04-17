package com.ticketlegacy.domain;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class Notice {
    private Long noticeId;
    private String title;
    private String content;
    private String noticeType;      // SYSTEM | EVENT | PERFORMANCE | MAINTENANCE
    private String targetRole;      // ALL | USER | PROMOTER | VENUE_MANAGER
    private boolean isPinned;
    private boolean isActive;
    private Long authorMemberId;
    private int viewCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // 조인 필드
    private String authorName;
}
