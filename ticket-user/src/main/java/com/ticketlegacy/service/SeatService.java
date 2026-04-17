package com.ticketlegacy.service;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Service;

import com.ticketlegacy.domain.Schedule;
import com.ticketlegacy.domain.SeatInventory;
import com.ticketlegacy.dto.response.SeatHoldResult;
import com.ticketlegacy.dto.response.SeatStatusResponse;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.exception.SeatAlreadyHeldException;
import com.ticketlegacy.repository.ScheduleMapper;
import com.ticketlegacy.repository.SeatInventoryMapper;

@Service
public class SeatService {
    private static final Logger log = LoggerFactory.getLogger(SeatService.class);
    private static final int HOLD_MINUTES = 10;

    @Autowired private SeatInventoryMapper seatInventoryMapper;
    @Autowired private ScheduleMapper scheduleMapper;
    @Autowired private StringRedisTemplate redisTemplate;

    private static final String HOLD_SCRIPT =
            "local hashKey = KEYS[1] " +
            "local seatId = ARGV[1] " +
            "local memberId = ARGV[2] " +
            "local expiresAt = tonumber(ARGV[3]) " +
            "local now = tonumber(ARGV[4]) " +
            "local existing = redis.call('HGET', hashKey, seatId) " +
            "if existing == 'RESERVED' then return 0 end " +
            "if existing then " +
            "   local colonIndex = string.find(existing, ':') " +
            "   if colonIndex then " +
            "       local existingHolder = string.sub(existing, 1, colonIndex - 1) " +
            "       local existingExpires = tonumber(string.sub(existing, colonIndex + 1)) " +
            "       if existingExpires and existingExpires > now then " +
            "           if existingHolder ~= memberId then return 0 end " +
            "       end " +
            "   end " +
            "end " +
            "redis.call('HSET', hashKey, seatId, memberId .. ':' .. expiresAt) " +
            "return 1";

    public List<SeatStatusResponse> getSeatStatus(Long scheduleId, Long memberId) {
        List<SeatInventory> inventories = seatInventoryMapper.findByScheduleId(scheduleId);
        String hashKey = "schedule:" + scheduleId + ":seat_status";

        Map<Object, Object> tempMap;
        try {
            tempMap = redisTemplate.opsForHash().entries(hashKey);
            if (tempMap == null) tempMap = Collections.emptyMap();
        } catch (Exception e) {
            log.warn("Redis 해시 조회 실패: {}", e.getMessage());
            tempMap = Collections.emptyMap();
        }
        final Map<Object, Object> redisState = tempMap;
        long now = System.currentTimeMillis();

        return inventories.stream()
                .filter(inv -> "PUBLIC".equals(inv.getHoldType()) || inv.getHoldType() == null)
                .map(inv -> {
                    SeatStatusResponse resp = new SeatStatusResponse();
                    resp.setSeatId(inv.getSeatId());
                    resp.setSection(inv.getSection());
                    resp.setSeatRow(inv.getSeatRow());
                    resp.setSeatNumber(inv.getSeatNumber());
                    resp.setGrade(inv.getGrade());
                    resp.setPrice(inv.getPrice());

                    String seatIdStr = String.valueOf(inv.getSeatId());
                    Object redisValObj = redisState.get(seatIdStr);

                    if (redisValObj != null) {
                        String redisVal = redisValObj.toString();
                        if ("RESERVED".equals(redisVal)) {
                            resp.setStatus("RESERVED");
                        } else if (redisVal.contains(":")) {
                            String[] parts = redisVal.split(":");
                            long expiresAt = Long.parseLong(parts[1]);
                            if (expiresAt > now) {
                                if (memberId != null && parts[0].equals(String.valueOf(memberId))) {
                                    resp.setStatus("MY_HOLD");
                                    resp.setExpiresAt(expiresAt);
                                } else {
                                    resp.setStatus("HELD");
                                }
                            } else {
                                resp.setStatus("AVAILABLE");
                            }
                        }
                    } else {
                        resp.setStatus(inv.getStatus());
                    }
                    return resp;
                }).collect(Collectors.toList());
    }

    public SeatHoldResult holdSeat(Long scheduleId, Long seatId, Long memberId) {
        SeatInventory inv = seatInventoryMapper.findBySeatInSchedule(scheduleId, seatId);
        if (inv != null && inv.getHoldType() != null && !"PUBLIC".equals(inv.getHoldType())) {
            throw new SeatAlreadyHeldException("선점할 수 없는 좌석입니다. (" + inv.getHoldType() + ")");
        }

        Schedule schedule = scheduleMapper.findById(scheduleId);
        if (schedule != null && schedule.getMaxSeatsPerOrder() > 0) {
            long myHoldCount = countMyHolds(scheduleId, memberId);
            if (myHoldCount >= schedule.getMaxSeatsPerOrder()) {
                throw new BusinessException(ErrorCode.INVALID_INPUT,
                        "1인당 최대 " + schedule.getMaxSeatsPerOrder() + "석까지만 예매 가능합니다.");
            }
        }

        String hashKey = "schedule:" + scheduleId + ":seat_status";
        long now = System.currentTimeMillis();
        long expiresAt = now + (HOLD_MINUTES * 60 * 1000L);

        try {
            DefaultRedisScript<Long> script = new DefaultRedisScript<>(HOLD_SCRIPT, Long.class);
            Long result = redisTemplate.execute(script, Collections.singletonList(hashKey),
                    String.valueOf(seatId), String.valueOf(memberId),
                    String.valueOf(expiresAt), String.valueOf(now));

            if (result == null || result == 0) {
                throw new SeatAlreadyHeldException("이미 다른 사용자가 선점하거나 예매된 좌석입니다.");
            }
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.error("Redis 락 스크립트 실행 실패: {}", e.getMessage());
            throw new RuntimeException("좌석 시스템 장애가 발생했습니다.");
        }

        log.info("좌석 선점: scheduleId={}, seatId={}, memberId={}", scheduleId, seatId, memberId);
        return SeatHoldResult.success(seatId, expiresAt);
    }

    private long countMyHolds(Long scheduleId, Long memberId) {
        String hashKey = "schedule:" + scheduleId + ":seat_status";
        long now = System.currentTimeMillis();
        try {
            Map<Object, Object> state = redisTemplate.opsForHash().entries(hashKey);
            if (state == null) return 0;
            String memberPrefix = memberId + ":";
            return state.values().stream()
                    .filter(v -> {
                        String s = v.toString();
                        if (!s.startsWith(memberPrefix)) return false;
                        try {
                            long exp = Long.parseLong(s.substring(memberPrefix.length()));
                            return exp > now;
                        } catch (Exception e) { return false; }
                    }).count();
        } catch (Exception e) {
            return 0;
        }
    }

    public void releaseSeat(Long scheduleId, Long seatId, Long memberId) {
        String hashKey = "schedule:" + scheduleId + ":seat_status";
        try {
            Object val = redisTemplate.opsForHash().get(hashKey, String.valueOf(seatId));
            if (val != null && val.toString().startsWith(memberId + ":")) {
                redisTemplate.opsForHash().delete(hashKey, String.valueOf(seatId));
            }
        } catch (Exception e) {
            log.warn("Redis 선점 해제 오류: {}", e.getMessage());
        }
    }

    public int releaseExpiredHolds() {
        return seatInventoryMapper.releaseExpiredHolds();
    }
}
