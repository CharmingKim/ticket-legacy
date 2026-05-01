package com.ticketlegacy.dto.response;

import com.ticketlegacy.exception.ErrorCode;
import lombok.Getter;
import lombok.AllArgsConstructor;

import java.util.List;

@Getter @AllArgsConstructor
public class ApiResponse<T> {

    private boolean success;
    private String  message;
    private T       data;
    private String  errorCode;

    // ── 성공 ──────────────────────────────────────
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(true, "OK", data, null);
    }

    /** data 없이 메시지만 반환하는 void 작업용 */
    public static <T> ApiResponse<T> successMessage(String message) {
        return new ApiResponse<>(true, message, null, null);
    }

    // ── 실패 ──────────────────────────────────────
    public static <T> ApiResponse<T> error(ErrorCode code) {
        return new ApiResponse<>(false, code.getMessage(), null, code.getCode());
    }

    /** 자유 메시지 에러 — errorCode는 COMMON_002(INVALID_INPUT)로 고정 */
    public static <T> ApiResponse<T> error(String message) {
        return new ApiResponse<>(false, message, null, ErrorCode.INVALID_INPUT.getCode());
    }

    /** @Valid 실패 시 필드별 오류 목록 반환 */
    public static <T> ApiResponse<T> validationError(List<ValidationError> errors) {
        String summary = errors.stream()
                .map(e -> e.getField() + ": " + e.getMessage())
                .reduce((a, b) -> a + ", " + b).orElse("입력값 오류");
        return new ApiResponse<>(false, summary, null, ErrorCode.INVALID_INPUT.getCode());
    }

    // ── 내부 클래스 ───────────────────────────────
    @Getter @AllArgsConstructor
    public static class ValidationError {
        private final String field;
        private final String message;
    }
}
