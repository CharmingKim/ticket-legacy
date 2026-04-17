package com.ticketlegacy.dto.request;

import lombok.*;
import javax.validation.constraints.NotNull;

@Getter @Setter @NoArgsConstructor
public class SeatHoldRequest {
    @NotNull(message = "회차 ID는 필수입니다")
    private Long scheduleId;
    @NotNull(message = "좌석 ID는 필수입니다")
    private Long seatId;
}
