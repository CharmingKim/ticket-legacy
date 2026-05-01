package com.ticketlegacy.dto.response;

import com.ticketlegacy.domain.Performance;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
public class PerformanceSummaryDto {

    private final Long          performanceId;
    private final String        title;
    private final String        category;
    private final String        venueName;
    private final String        posterUrl;
    private final Integer       minPrice;
    private final Integer       runningTime;
    private final LocalDate     startDate;
    private final LocalDate     endDate;
    private final LocalDateTime ticketOpenAt;
    private final String        status;
    private final String        approvalStatus;
    private final String        approvalNote;
    private final Long          promoterId;
    private final String        promoterCompanyName;
    private final LocalDateTime createdAt;
    private final LocalDateTime reviewedAt;

    private PerformanceSummaryDto(Performance p) {
        this.performanceId       = p.getPerformanceId();
        this.title               = p.getTitle();
        this.category            = p.getCategory();
        this.venueName           = p.getVenueName();
        this.posterUrl           = p.getPosterUrl();
        this.minPrice            = p.getMinPrice();
        this.runningTime         = p.getRunningTime();
        this.startDate           = p.getStartDate();
        this.endDate             = p.getEndDate();
        this.ticketOpenAt        = p.getTicketOpenAt();
        this.status              = p.getStatus();
        this.approvalStatus      = p.getApprovalStatus();
        this.approvalNote        = p.getApprovalNote();
        this.promoterId          = p.getPromoterId();
        this.promoterCompanyName = p.getPromoterCompanyName();
        this.createdAt           = p.getCreatedAt();
        this.reviewedAt          = p.getReviewedAt();
    }

    public static PerformanceSummaryDto from(Performance p) {
        return new PerformanceSummaryDto(p);
    }
}
