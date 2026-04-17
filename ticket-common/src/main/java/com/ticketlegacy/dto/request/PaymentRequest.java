package com.ticketlegacy.dto.request;

import lombok.*;
import javax.validation.constraints.*;
import java.util.List;

@Getter @Setter @NoArgsConstructor
public class PaymentRequest {
    @NotNull private Long reservationId;
    @NotNull private Long scheduleId;
    @NotEmpty private List<Long> seatIds;
    @NotBlank private String method; // CARD, BANK_TRANSFER
    @Min(1) private int amount;
    private String couponCode; // optional — null if no coupon applied
}
