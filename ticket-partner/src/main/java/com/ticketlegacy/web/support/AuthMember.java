package com.ticketlegacy.web.support;

import java.lang.annotation.*;

/**
 * 컨트롤러 메서드 파라미터에 선언하면 현재 로그인 사용자의 memberId를 주입.
 * 예: public ResponseEntity<?> myMethod(@AuthMember Long memberId)
 */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface AuthMember {
}
