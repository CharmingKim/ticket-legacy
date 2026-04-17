package com.ticketlegacy.web.advice;

import com.ticketlegacy.dto.response.ApiResponse;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import javax.servlet.http.HttpServletRequest;

@ControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(BusinessException.class)
    @ResponseBody
    public ResponseEntity<ApiResponse<?>> handleBusinessException(BusinessException e) {
        log.warn("[BIZ_ERROR] code={}, message={}", e.getErrorCode().getCode(), e.getMessage());
        return ResponseEntity
                .status(e.getErrorCode().getHttpStatus())
                .body(ApiResponse.error(e.getErrorCode()));
    }

    @ExceptionHandler(BindException.class)
    @ResponseBody
    public ResponseEntity<ApiResponse<?>> handleValidation(BindException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
                .map(err -> err.getField() + ": " + err.getDefaultMessage())
                .reduce((a, b) -> a + ", " + b).orElse("입력값 오류");
        log.warn("[VALIDATION_ERROR] {}", message);
        return ResponseEntity.badRequest().body(ApiResponse.error(message));
    }

    @ExceptionHandler(DuplicateKeyException.class)
    @ResponseBody
    public ResponseEntity<ApiResponse<?>> handleDuplicateKey(DuplicateKeyException e) {
        String msg = e.getMessage() != null ? e.getMessage() : "";
        log.warn("[DUPLICATE_KEY] {}", msg);
        if (msg.contains("uq_venue_section")) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("이미 존재하는 구역명입니다."));
        }
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiResponse.error(ErrorCode.INVALID_INPUT));
    }

    @ExceptionHandler(DataAccessException.class)
    public Object handleDbError(DataAccessException e, HttpServletRequest request) {
        log.error("[DB_ERROR] URI={}", request.getRequestURI(), e);
        if (isAjax(request)) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(ApiResponse.error(ErrorCode.INTERNAL_ERROR));
        }
        ModelAndView mav = new ModelAndView("error/503");
        mav.addObject("message", "일시적인 서비스 장애입니다. 잠시 후 다시 시도해주세요.");
        return mav;
    }

    @ExceptionHandler({IllegalStateException.class, IllegalArgumentException.class})
    @ResponseBody
    public ResponseEntity<ApiResponse<?>> handleIllegalState(RuntimeException e, HttpServletRequest request) {
        log.warn("[BAD_REQUEST] URI={}, Message={}", request.getRequestURI(), e.getMessage());
        return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public Object handleException(Exception e, HttpServletRequest request) {
        log.error("[UNHANDLED_ERROR] URI={}", request.getRequestURI(), e);
        if (isAjax(request)) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error(e.getMessage() != null ? e.getMessage() : ErrorCode.INTERNAL_ERROR.getMessage()));
        }
        ModelAndView mav = new ModelAndView("error/500");
        mav.addObject("message", "예기치 않은 오류가 발생했습니다.");
        return mav;
    }

    private boolean isAjax(HttpServletRequest request) {
        String accept = request.getHeader("Accept");
        String xRequested = request.getHeader("X-Requested-With");
        return "XMLHttpRequest".equals(xRequested)
                || (accept != null && accept.contains("application/json"));
    }
}
