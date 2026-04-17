package com.ticketlegacy.dto.response;

import lombok.*;

@Getter @AllArgsConstructor
public class QueuePositionResponse {
    private long position;
    private long estimatedWaitSeconds;
    private boolean passed;

    public static QueuePositionResponse passed() {
        return new QueuePositionResponse(0, 0, true);
    }
}
