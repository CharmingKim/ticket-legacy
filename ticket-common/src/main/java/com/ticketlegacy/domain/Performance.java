package com.ticketlegacy.domain;

import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor
public class Performance {
    private Long performanceId;
    private String apiPerfId;
    private String title;
    private String category;
    // JSP alias: genre → category
    private String ageLimit;       // 관람 연령 제한 (ex. "전체", "15세 이상")
    private Integer runningTime;   // 공연 시간 (분)
    private Integer minPrice;      // 최저 좌석 가격 (표시용)
    private Long venueId;
    private String venueName;
    private String description;
    private String posterUrl;
    private int totalSeats;
    private LocalDateTime ticketOpenAt;
    private LocalDate startDate;
    private LocalDate endDate;
    private String status;           // UPCOMING / ON_SALE / SOLD_OUT / ENDED
    private Long stageConfigId;
    // ── 3계층 추가 필드 ──
    private Long promoterId;         // 등록 기획사 ID (NULL = 슈퍼어드민 직접 등록)
    private String approvalStatus;   // DRAFT / REVIEW / APPROVED / REJECTED / PUBLISHED
    private String approvalNote;     // 반려 사유 또는 승인 메모
    private Long reviewedBy;         // 검토한 SUPER_ADMIN member_id
    private LocalDateTime reviewedAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // 조인 조회용 (기획사명)
    private String promoterCompanyName;

    // JSP alias getter: genre → category
    public String getGenre() { return category; }
    public void setGenre(String genre) { this.category = genre; }
}
