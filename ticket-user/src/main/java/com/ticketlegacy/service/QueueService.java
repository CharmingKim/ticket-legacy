package com.ticketlegacy.service;

import com.ticketlegacy.dto.response.QueuePositionResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.Set;

@Service
public class QueueService {
    private static final Logger log = LoggerFactory.getLogger(QueueService.class);
    private static final int MAX_CONCURRENT = 500;
    public static final String ACTIVE_SCHEDULES_KEY = "queue:active_schedules";

    @Autowired private StringRedisTemplate redisTemplate;

    public QueuePositionResponse enterQueue(Long scheduleId, Long memberId) {
        String queueKey = "queue:" + scheduleId;
        String passKey = "queue:pass:" + scheduleId;
        String memberStr = String.valueOf(memberId);

        Boolean alreadyPassed = redisTemplate.opsForSet().isMember(passKey, memberStr);
        if (Boolean.TRUE.equals(alreadyPassed)) {
            return QueuePositionResponse.passed();
        }

        redisTemplate.opsForSet().add(ACTIVE_SCHEDULES_KEY, String.valueOf(scheduleId));

        double score = System.currentTimeMillis();
        redisTemplate.opsForZSet().add(queueKey, memberStr, score);
        Long rank = redisTemplate.opsForZSet().rank(queueKey, memberStr);
        long position = (rank != null) ? rank + 1 : 0;

        log.info("대기열 진입: scheduleId={}, memberId={}, position={}", scheduleId, memberId, position);
        return new QueuePositionResponse(position, position * 3, false);
    }

    public QueuePositionResponse getPosition(Long scheduleId, Long memberId) {
        String passKey = "queue:pass:" + scheduleId;
        String memberStr = String.valueOf(memberId);

        Boolean passed = redisTemplate.opsForSet().isMember(passKey, memberStr);
        if (Boolean.TRUE.equals(passed)) return QueuePositionResponse.passed();

        Long rank = redisTemplate.opsForZSet().rank("queue:" + scheduleId, memberStr);
        if (rank == null) return new QueuePositionResponse(-1, 0, false);
        return new QueuePositionResponse(rank + 1, (rank + 1) * 3, false);
    }

    @Scheduled(fixedRate = 3000)
    public void processQueues() {
        try {
            Set<String> activeSchedules = redisTemplate.opsForSet().members(ACTIVE_SCHEDULES_KEY);
            if (activeSchedules == null || activeSchedules.isEmpty()) return;

            for (String scheduleIdStr : activeSchedules) {
                String queueKey = "queue:" + scheduleIdStr;
                String counterKey = "queue:counter:" + scheduleIdStr;
                String passKey = "queue:pass:" + scheduleIdStr;

                Long queueSize = redisTemplate.opsForZSet().size(queueKey);
                if (queueSize == null || queueSize == 0) continue;

                String countStr = redisTemplate.opsForValue().get(counterKey);
                long currentCount = (countStr != null) ? Long.parseLong(countStr) : 0;
                int slots = (int) (MAX_CONCURRENT - currentCount);
                if (slots <= 0) continue;

                Set<String> nextElements = redisTemplate.opsForZSet().range(queueKey, 0, slots - 1);
                if (nextElements == null || nextElements.isEmpty()) continue;

                for (String memberId : nextElements) {
                    redisTemplate.opsForSet().add(passKey, memberId);
                    redisTemplate.opsForZSet().remove(queueKey, memberId);
                    redisTemplate.opsForValue().increment(counterKey);
                }
                log.debug("대기열 처리: scheduleId={}, 대기인원={}, 신규통과={}명", scheduleIdStr, queueSize, nextElements.size());
            }
        } catch (Exception e) {
            log.warn("대기열 처리 중 오류: {}", e.getMessage());
        }
    }

    public boolean hasPassed(Long scheduleId, Long memberId) {
        try {
            Boolean result = redisTemplate.opsForSet()
                    .isMember("queue:pass:" + scheduleId, String.valueOf(memberId));
            return Boolean.TRUE.equals(result);
        } catch (Exception e) {
            log.warn("Redis 대기열 확인 실패 — 통과 처리: {}", e.getMessage());
            return true;
        }
    }
}
