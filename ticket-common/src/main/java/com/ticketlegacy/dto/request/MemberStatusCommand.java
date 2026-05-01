package com.ticketlegacy.dto.request;

import com.ticketlegacy.domain.enums.MemberStatus;
import lombok.Getter;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;

@Getter @NoArgsConstructor
public class MemberStatusCommand {

    @NotNull(message = "변경할 상태값은 필수입니다.")
    private MemberStatus status;

    @Size(max = 500, message = "사유는 500자 이내로 입력해주세요.")
    private String reason;
}
