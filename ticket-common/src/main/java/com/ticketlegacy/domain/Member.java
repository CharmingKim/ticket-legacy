package com.ticketlegacy.domain;

import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class Member {
    private Long memberId;
    private String email;
    private String password;
    private String name;
    private String phone;
    private String role;       // USER, ADMIN
    private String status;     // ACTIVE, DORMANT, WITHDRAWN
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime lastLoginAt;
}
