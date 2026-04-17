package com.ticketlegacy.service;

import com.ticketlegacy.domain.EntranceLog;
import com.ticketlegacy.domain.Reservation;
import com.ticketlegacy.domain.Schedule;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.repository.EntranceLogMapper;
import com.ticketlegacy.repository.ReservationMapper;
import com.ticketlegacy.repository.ScheduleMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class EntranceService {

    private final ReservationMapper reservationMapper;
    private final ScheduleMapper scheduleMapper;
    private final EntranceLogMapper entranceLogMapper;

    @Transactional
    public EntranceLog checkIn(Long venueId, String reservationNo, Long operatorMemberId, String note) {
        Reservation reservation = reservationMapper.findByReservationNo(reservationNo);
        if (reservation == null) {
            throw new BusinessException(ErrorCode.RESERVATION_NOT_FOUND);
        }
        if (!"CONFIRMED".equals(reservation.getStatus())) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "Only confirmed reservations can be checked in.");
        }

        Schedule schedule = scheduleMapper.findById(reservation.getScheduleId());
        if (schedule == null) {
            throw new BusinessException(ErrorCode.SCHEDULE_NOT_FOUND);
        }
        if (!venueId.equals(schedule.getVenueId())) {
            throw new BusinessException(ErrorCode.VENUE_MANAGER_FORBIDDEN);
        }

        EntranceLog existing = entranceLogMapper.findByReservationId(reservation.getReservationId());
        if (existing != null) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "This reservation has already been checked in.");
        }

        EntranceLog logEntry = new EntranceLog();
        logEntry.setReservationId(reservation.getReservationId());
        logEntry.setScheduleId(reservation.getScheduleId());
        logEntry.setVenueId(venueId);
        logEntry.setMemberId(reservation.getMemberId());
        logEntry.setCheckedInBy(operatorMemberId);
        logEntry.setNote(note);
        entranceLogMapper.insert(logEntry);

        log.info("Entrance check-in completed: reservationNo={}, venueId={}, operator={}",
                reservationNo, venueId, operatorMemberId);
        return entranceLogMapper.findByReservationId(reservation.getReservationId());
    }
}
