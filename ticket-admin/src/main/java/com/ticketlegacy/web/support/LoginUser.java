package com.ticketlegacy.web.support;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class LoginUser {
    private final Long   memberId;
    private final String email;
    private final String role;
    private final Long   promoterId;
    private final Long   venueId;
}
