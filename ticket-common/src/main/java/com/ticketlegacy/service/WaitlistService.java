package com.ticketlegacy.service;

import com.ticketlegacy.domain.Waitlist;
import com.ticketlegacy.repository.WaitlistMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class WaitlistService {

    @Autowired
    private WaitlistMapper waitlistMapper;

    @Transactional
    public void addWaitlist(Long scheduleId, Long memberId) {
        if (waitlistMapper.countByScheduleAndMember(scheduleId, memberId) == 0) {
            waitlistMapper.insert(scheduleId, memberId);
        }
    }

    @Transactional
    public void removeWaitlist(Long scheduleId, Long memberId) {
        waitlistMapper.delete(scheduleId, memberId);
    }

    public boolean isWaiting(Long scheduleId, Long memberId) {
        if (memberId == null) return false;
        return waitlistMapper.countByScheduleAndMember(scheduleId, memberId) > 0;
    }

    public List<Waitlist> getMyWaitlist(Long memberId) {
        return waitlistMapper.findByMemberId(memberId);
    }
    
    // 알림 서비스 연동용 (좌석 취소 시 호출 가능)
    public void notifyNextInLine(Long scheduleId) {
        List<Waitlist> waiting = waitlistMapper.findWaitingByScheduleId(scheduleId);
        if (!waiting.isEmpty()) {
            Waitlist next = waiting.get(0);
            waitlistMapper.setNotified(next.getId());
            // TODO: 실제 알림 발송 (Email, SMS, Push 등)
        }
    }
}
