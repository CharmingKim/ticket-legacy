package com.ticketlegacy.dto.request;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

import javax.validation.constraints.Max;
import javax.validation.constraints.Min;

@Getter @Setter @NoArgsConstructor
public class MemberSearchQuery {

    private String role;
    private String status;
    private String keyword;

    @Min(1)
    private int page = 1;

    @Min(1) @Max(100)
    private int size = 20;

    public int getOffset() {
        return (page - 1) * size;
    }
}
