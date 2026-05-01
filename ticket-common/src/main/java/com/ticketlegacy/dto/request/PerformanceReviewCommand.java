package com.ticketlegacy.dto.request;

import lombok.Getter;
import lombok.NoArgsConstructor;

import javax.validation.constraints.Size;

@Getter
@NoArgsConstructor
public class PerformanceReviewCommand {

    @Size(max = 1000, message = "메모는 1000자 이내로 입력해주세요.")
    private String note;
}
