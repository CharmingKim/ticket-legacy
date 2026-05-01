package com.ticketlegacy.domain;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class Member {
    private Long memberId;
    private String email;
    @JsonIgnore
    private String password;
    private String name;
    private String phone;
    private String role;   // MemberRole: USER, STAFF, SUPER_ADMIN, PROMOTER, VENUE_MANAGER
    private String status; // MemberStatus: PENDING_APPROVAL, ACTIVE, SUSPENDED, DORMANT, WITHDRAWN
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime lastLoginAt;
    private LocalDateTime withdrawnAt;
}
