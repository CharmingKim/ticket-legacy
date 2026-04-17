package com.ticketlegacy.dto.request;

import lombok.*;
import javax.validation.constraints.*;

@Getter @Setter @NoArgsConstructor
public class MemberJoinRequest {
    @NotBlank @Email private String email;
    @NotBlank @Size(min = 4, max = 20) private String password;
    @NotBlank private String name;
    private String phone;
}
