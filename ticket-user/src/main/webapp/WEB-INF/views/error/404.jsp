<%@ page contentType="text/html;charset=UTF-8" language="java" isErrorPage="true" %>
<div class="tl-error-wrap">
    <div>
        <div class="tl-error-code">404</div>
        <h2 class="tl-error-title">페이지를 찾을 수 없습니다</h2>
        <p class="tl-error-desc">요청하신 페이지가 존재하지 않거나 이동되었습니다.</p>
        <a href="${pageContext.request.contextPath}/" class="tl-btn-primary">
            <i class="bi bi-house me-2"></i>홈으로 돌아가기
        </a>
    </div>
</div>
