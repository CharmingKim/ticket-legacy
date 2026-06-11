<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<div class="tl-auth-wrap" style="align-items:flex-start;padding-top:60px">
    <div class="tl-auth-card" style="max-width:520px">

        <!-- Logo -->
        <div class="tl-auth-logo">
            <div class="icon"><i class="bi bi-ticket-perforated-fill"></i></div>
            <div class="name">TicketLegacy</div>
        </div>

        <h2 class="tl-auth-title">회원가입</h2>
        <p class="tl-auth-sub">TicketLegacy와 함께 공연을 즐겨보세요</p>

        <form id="joinForm">
            <div class="tl-form-group">
                <label class="tl-form-label">이름</label>
                <input type="text" id="name" name="name" class="tl-form-control"
                       placeholder="이름 입력" required />
            </div>
            <div class="tl-form-group">
                <label class="tl-form-label">이메일</label>
                <input type="email" id="email" name="email" class="tl-form-control"
                       placeholder="email@example.com" required />
            </div>
            <div class="tl-form-group">
                <label class="tl-form-label">비밀번호</label>
                <input type="password" id="password" name="password" class="tl-form-control"
                       placeholder="8자 이상 입력" minlength="8" required />
            </div>
            <div class="tl-form-group">
                <label class="tl-form-label">비밀번호 확인</label>
                <input type="password" id="passwordConfirm" class="tl-form-control"
                       placeholder="비밀번호 재입력" required />
            </div>
            <div class="tl-form-group">
                <label class="tl-form-label">전화번호 (선택)</label>
                <input type="tel" id="phone" name="phone" class="tl-form-control"
                       placeholder="010-0000-0000" />
            </div>

            <button type="submit" class="tl-auth-btn mt-2" id="joinBtn">
                회원가입
            </button>
        </form>

        <div class="tl-auth-footer">
            이미 계정이 있으신가요?
            <a href="${pageContext.request.contextPath}/member/login">로그인</a>
        </div>
    </div>
</div>

<script>
const ctx = '${pageContext.request.contextPath}';

$('#joinForm').on('submit', function(e) {
    e.preventDefault();

    const pw  = $('#password').val();
    const pw2 = $('#passwordConfirm').val();
    if (pw !== pw2) { toast.error('비밀번호가 일치하지 않습니다.'); return; }

    const $btn = $('#joinBtn');
    $btn.prop('disabled', true).text('처리 중...');

    api.post(ctx + '/api/member/join', {
        name:     $('#name').val().trim(),
        email:    $('#email').val().trim(),
        password: pw,
        phone:    $('#phone').val().trim() || null
    })
    .done(function(res) {
        if (res.success) {
            toast.success('회원가입이 완료되었습니다!');
            setTimeout(() => { location.href = ctx + '/member/login'; }, 1500);
        } else {
            toast.error(res.message || '회원가입에 실패했습니다.');
            $btn.prop('disabled', false).text('회원가입');
        }
    })
    .fail(function(xhr) {
        const msg = xhr.responseJSON?.message || '회원가입 중 오류가 발생했습니다.';
        toast.error(msg);
        $btn.prop('disabled', false).text('회원가입');
    });
});
</script>
