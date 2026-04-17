package com.ticketlegacy.util;

import org.apache.commons.codec.digest.DigestUtils;
import java.util.List;
import java.util.stream.Collectors;

public class IdempotencyKeyGenerator {

    private IdempotencyKeyGenerator() {}

    /**
     * memberId + scheduleId + 정렬된 seatIds → SHA-256 해시
     * 동일 조합이면 항상 동일 키 생성
     */
    public static String generate(Long memberId, Long scheduleId, List<Long> seatIds) {
        String raw = memberId + ":" + scheduleId + ":" +
                seatIds.stream().sorted().map(String::valueOf)
                        .collect(Collectors.joining(","));
        return DigestUtils.sha256Hex(raw);
    }
}
