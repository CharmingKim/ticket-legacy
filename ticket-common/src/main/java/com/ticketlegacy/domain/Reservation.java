package com.ticketlegacy.domain;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class Reservation {
    private Long reservationId;
    private String reservationNo;
    private Long scheduleId;
    private Long memberId;
    private int totalAmount;
    private int seatCount;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime confirmedAt;
    private LocalDateTime cancelledAt;
    private List<ReservationSeat> seats;
    private String performanceTitle;
    private String venue;
    private String memberName;
    private String memberEmail;
    private String memberPhone;
    private LocalDate showDate;
    private LocalTime showTime;
    private String paymentStatus;
    private String paymentMethod;
    private LocalDateTime checkedInAt;

    public LocalDateTime getScheduleDatetime() {
        return (showDate != null && showTime != null) ? showDate.atTime(showTime) : null;
    }
}
