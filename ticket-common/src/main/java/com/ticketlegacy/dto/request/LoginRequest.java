package com.ticketlegacy.dto.request;

import lombok.*;
import javax.validation.constraints.*;

@Getter @Setter @NoArgsConstructor
public class LoginRequest {
    @NotBlank @Email private String email;
    @NotBlank private String password;
}
