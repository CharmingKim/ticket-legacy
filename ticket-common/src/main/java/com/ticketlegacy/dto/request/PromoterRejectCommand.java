package com.ticketlegacy.dto.request;

import lombok.Getter;
import lombok.NoArgsConstructor;

import javax.validation.constraints.Size;

@Getter
@NoArgsConstructor
public class PromoterRejectCommand {

    @Size(max = 500, message = "반려 사유는 500자 이내로 입력해주세요.")
    private String reason;
}
