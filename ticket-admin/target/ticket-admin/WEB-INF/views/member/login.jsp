<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<style>
.admin-login-wrap {
    min-height: calc(100vh - 120px);
    display: flex;
    align-items: center;
    justify-content: center;
    background: #f8f9fa;
}
.admin-login-card {
    width: 100%;
    max-width: 420px;
    background: #fff;
    border-radius: 12px;
    box-shadow: 0 4px 24px rgba(0,0,0,.10);
    padding: 40px 36px;
}
.admin-login-badge {
    display: inline-block;
    background: #1e293b;
    color: #fff;
    font-size: .75rem;
    font-weight: 600;
    letter-spacing: .08em;
    padding: 4px 12px;
    border-radius: 20px;
    margin-bottom: 16px;
}
.admin-login-title {
    font-size: 1.5rem;
    font-weight: 700;
    color: #1e293b;
    margin-bottom: 6px;
}
.admin-login-sub {
    font-size: .875rem;
    color: #6b7280;
    margin-bottom: 28px;
}
.admin-login-card .form-label { font-weight: 500; font-size: .875rem; color: #374151; }
.admin-login-card .form-control {
    border-radius: 8px;
    border: 1.5px solid #e5e7eb;
    padding: 10px 14px;
    font-size: .95rem;
    transition: border-color .2s;
}
.admin-login-card .form-control:focus {
    border-color: #6c63ff;
    box-shadow: 0 0 0 3px rgba(108,99,255,.12);
}
.btn-admin-login {
    background: #1e293b;
    color: #fff;
    border: none;
    border-radius: 8px;
    padding: 12px;
    font-size: .95rem;
    font-weight: 600;
    width: 100%;
    margin-top: 8px;
    transition: background .2s;
}
.btn-admin-login:hover { background: #0f172a; color: #fff; }
.btn-admin-login:disabled { opacity: .6; }
</style>

<div class="admin-login-wrap">
    <div class="admin-login-card">
        <div class="admin-login-badge"><i class="bi bi-shield-lock me-1"></i>BACKOFFICE</div>
        <div class="admin-login-title">관리자 로그인</div>
        <div class="admin-login-sub">내부 스태프 · 슈퍼어드민 전용 시스템입니다</div>

        <form id="loginForm" autocomplete="off">
            <div class="mb-3">
                <label class="form-label">이메일</label>
                <input type="email" id="loginEmail" class="form-control"
                       placeholder="admin@ticketlegacy.com" autocomplete="email" required>
            </div>
            <div class="mb-4">
                <label class="form-label">비밀번호</label>
                <input type="password" id="loginPassword" class="form-control"
                       placeholder="비밀번호 입력" autocomplete="current-password" required>
            </div>
            <button type="submit" id="btnLogin" class="btn-admin-login">
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

    api.post(ctx + '/admin/api/login', {
        email:    $('#loginEmail').val().trim(),
        password: $('#loginPassword').val()
    })
    .done(function(res) {
        if (res.success) {
            location.href = res.data?.redirectUrl || ctx + '/backoffice/super/dashboard';
        } else {
            Swal.fire({ icon: 'error', title: '로그인 실패', text: res.message || '이메일 또는 비밀번호를 확인해주세요.', confirmButtonColor: '#1e293b' });
            $btn.prop('disabled', false).html('<i class="bi bi-box-arrow-in-right me-2"></i>로그인');
        }
    })
    .fail(function(xhr) {
        const msg = xhr.responseJSON?.message || '이메일 또는 비밀번호를 확인해주세요.';
        Swal.fire({ icon: 'error', title: '로그인 실패', text: msg, confirmButtonColor: '#1e293b' });
        $btn.prop('disabled', false).html('<i class="bi bi-box-arrow-in-right me-2"></i>로그인');
    });
});

$('#loginPassword').on('keypress', function(e) {
    if (e.which === 13) $('#loginForm').submit();
});
</script>
