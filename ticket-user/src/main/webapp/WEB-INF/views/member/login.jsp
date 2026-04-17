<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<div class="tl-auth-wrap">
    <div class="tl-auth-card">

        <!-- Logo -->
        <div class="tl-auth-logo">
            <div class="icon"><i class="bi bi-ticket-perforated-fill"></i></div>
            <div class="name">TicketLegacy</div>
        </div>

        <h2 class="tl-auth-title">로그인</h2>
        <p class="tl-auth-sub">계속하려면 로그인해주세요</p>

        <c:if test="${not empty error}">
            <div style="background:#fee2e2;border:1px solid #fca5a5;border-radius:var(--radius-sm);
                        padding:12px 14px;margin-bottom:20px;font-size:.88rem;color:#dc2626">
                <i class="bi bi-exclamation-circle me-2"></i>${error}
            </div>
        </c:if>

        <form id="loginForm">
            <div class="tl-form-group">
                <label class="tl-form-label" for="email">이메일</label>
                <input type="email" id="email" class="tl-form-control"
                       placeholder="email@example.com" autocomplete="email" required />
            </div>
            <div class="tl-form-group">
                <label class="tl-form-label" for="password">비밀번호</label>
                <input type="password" id="password" class="tl-form-control"
                       placeholder="비밀번호 입력" autocomplete="current-password" required />
            </div>

            <button type="submit" class="tl-auth-btn" id="loginBtn">
                로그인
            </button>
        </form>

        <div class="tl-auth-footer">
            계정이 없으신가요?
            <a href="${pageContext.request.contextPath}/member/join">회원가입</a>
        </div>
    </div>
</div>

<script>
const ctx = '${pageContext.request.contextPath}';
const redirectUrl = '${not empty param.redirect ? param.redirect : "/"}';

$('#loginForm').on('submit', function(e) {
    e.preventDefault();
    const $btn = $('#loginBtn');
    $btn.prop('disabled', true).text('로그인 중...');

    api.post(ctx + '/api/member/login', {
        email:    $('#email').val().trim(),
        password: $('#password').val()
    })
    .done(function(res) {
        if (res.success) {
            location.href = redirectUrl;
        } else {
            toast.error(res.message || '로그인에 실패했습니다.');
            $btn.prop('disabled', false).text('로그인');
        }
    })
    .fail(function(xhr) {
        const msg = xhr.responseJSON?.message || '이메일 또는 비밀번호를 확인해주세요.';
        toast.error(msg);
        $btn.prop('disabled', false).text('로그인');
    });
});
</script>
