<%@ page contentType="text/html;charset=UTF-8" language="java" isErrorPage="true" %>
<div class="tl-error-wrap">
    <div>
        <div class="tl-error-code">503</div>
        <h2 class="tl-error-title">서비스 일시 중단</h2>
        <p class="tl-error-desc">
            ${not empty message ? message : '일시적인 서비스 장애입니다. 잠시 후 다시 시도해주세요.'}
        </p>
        <a href="${pageContext.request.contextPath}/" class="tl-btn-primary">
            <i class="bi bi-arrow-clockwise me-2"></i>새로고침
        </a>
    </div>
</div>
