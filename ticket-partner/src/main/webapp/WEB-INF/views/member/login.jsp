<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<style>
.partner-login-wrap {
    min-height: calc(100vh - 120px);
    display: flex;
    align-items: center;
    justify-content: center;
}
.partner-login-card {
    width: 100%;
    max-width: 420px;
    background: #fff;
    border-radius: 12px;
    box-shadow: 0 4px 24px rgba(0,0,0,.10);
    padding: 40px 36px;
}
.partner-login-badge {
    display: inline-block;
    background: linear-gradient(135deg, #1a1035, #0a2647);
    color: #fff;
    font-size: .75rem;
    font-weight: 600;
    letter-spacing: .08em;
    padding: 4px 12px;
    border-radius: 20px;
    margin-bottom: 16px;
}
.partner-login-title {
    font-size: 1.5rem;
    font-weight: 700;
    color: #1a1035;
    margin-bottom: 6px;
}
.partner-login-sub {
    font-size: .875rem;
    color: #6b7280;
    margin-bottom: 28px;
}
.partner-login-card .form-label { font-weight: 500; font-size: .875rem; color: #374151; }
.partner-login-card .form-control {
    border-radius: 8px;
    border: 1.5px solid #e5e7eb;
    padding: 10px 14px;
    font-size: .95rem;
    transition: border-color .2s;
}
.partner-login-card .form-control:focus {
    border-color: #6c63ff;
    box-shadow: 0 0 0 3px rgba(108,99,255,.12);
}
.btn-partner-login {
    background: linear-gradient(135deg, #1a1035, #0a2647);
    color: #fff;
    border: none;
    border-radius: 8px;
    padding: 12px;
    font-size: .95rem;
    font-weight: 600;
    width: 100%;
    margin-top: 8px;
    transition: opacity .2s;
}
.btn-partner-login:hover { opacity: .88; color: #fff; }
.btn-partner-login:disabled { opacity: .6; }
</style>

<div class="partner-login-wrap">
    <div class="partner-login-card">
        <div class="partner-login-badge"><i class="bi bi-building me-1"></i>PARTNER PORTAL</div>
        <div class="partner-login-title">파트너 로그인</div>
        <div class="partner-login-sub">기획사 · 공연장 관리자 전용 포털입니다</div>

        <form id="loginForm" autocomplete="off">
            <div class="mb-3">
                <label class="form-label">이메일</label>
                <input type="email" id="loginEmail" class="form-control"
                       placeholder="partner@example.com" autocomplete="email" required>
            </div>
            <div class="mb-4">
                <label class="form-label">비밀번호</label>
                <input type="password" id="loginPassword" class="form-control"
                       placeholder="비밀번호 입력" autocomplete="current-password" required>
            </div>
            <button type="submit" id="btnLogin" class="btn-partner-login">
                <i class="bi bi-box-arrow-in-right me-2"></i>로그인
            </button>
        </form>
    </div>
</div>

<script>
const ctx = '${pageContext.request.contextPath}';

$('#loginForm').on('submit', function(e) {
    e.preventDefault();
    const $btn = $('#btnLogin');
    $btn.prop('disabled', true).text('로그인 중...');

    api.post(ctx + '/partner/api/login', {
        email:    $('#loginEmail').val().trim(),
        password: $('#loginPassword').val()
    })
    .done(function(res) {
        if (res.success) {
            location.href = res.data?.redirectUrl || ctx + '/partner/promoter/dashboard';
        } else {
            Swal.fire({ icon: 'error', title: '로그인 실패', text: res.message || '이메일 또는 비밀번호를 확인해주세요.', confirmButtonColor: '#1a1035' });
            $btn.prop('disabled', false).html('<i class="bi bi-box-arrow-in-right me-2"></i>로그인');
        }
    })
    .fail(function(xhr) {
        const msg = xhr.responseJSON?.message || '이메일 또는 비밀번호를 확인해주세요.';
        Swal.fire({ icon: 'error', title: '로그인 실패', text: msg, confirmButtonColor: '#1a1035' });
        $btn.prop('disabled', false).html('<i class="bi bi-box-arrow-in-right me-2"></i>로그인');
    });
});

$('#loginPassword').on('keypress', function(e) {
    if (e.which === 13) $('#loginForm').submit();
});
</script>
