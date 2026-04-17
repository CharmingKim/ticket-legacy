package com.ticketlegacy.dto.response;

import com.ticketlegacy.exception.ErrorCode;
import lombok.*;

@Getter @AllArgsConstructor
public class ApiResponse<T> {
    private boolean success;
    private String message;
    private T data;
    private String errorCode;

    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(true, "OK", data, null);
    }
    public static <T> ApiResponse<T> error(ErrorCode code) {
        return new ApiResponse<>(false, code.getMessage(), null, code.getCode());
    }
    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, message, null, "UNKNOWN");
    }
}
