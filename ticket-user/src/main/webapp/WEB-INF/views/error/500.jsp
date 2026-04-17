<%@ page contentType="text/html;charset=UTF-8" language="java" isErrorPage="true" %>
<div class="tl-error-wrap">
    <div>
        <div class="tl-error-code">500</div>
        <h2 class="tl-error-title">서버 오류가 발생했습니다</h2>
        <p class="tl-error-desc">
            ${not empty message ? message : '예기치 않은 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'}
        </p>
        <a href="${pageContext.request.contextPath}/" class="tl-btn-primary">
            <i class="bi bi-house me-2"></i>홈으로 돌아가기
        </a>
    </div>
</div>
