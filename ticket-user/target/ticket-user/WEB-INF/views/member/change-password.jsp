<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<section class="tl-section">
    <div class="container" style="max-width: 500px;">
        <div class="card border-0 shadow-sm" style="border-radius: var(--radius-md);">
            <div class="card-body p-5">
                <h3 class="fw-800 text-center mb-4"><i class="bi bi-shield-lock me-2"></i>비밀번호 변경</h3>
                <p class="text-center text-muted mb-4" style="font-size: 0.9rem;">
                    안전한 계정 사용을 위해 주기적으로 비밀번호를 변경해 주세요.
                </p>

                <form id="changePasswordForm">
                    <div class="mb-3">
                        <label class="form-label fw-600" style="font-size: 0.9rem;">현재 비밀번호</label>
                        <input type="password" id="currentPassword" class="tl-form-control" placeholder="현재 비밀번호를 입력하세요" required />
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-600" style="font-size: 0.9rem;">새 비밀번호</label>
                        <input type="password" id="newPassword" class="tl-form-control" placeholder="영문, 숫자, 특수문자 조합 8자 이상" required />
                        <div id="pwdStrength" class="form-text" style="font-size: 0.8rem;"></div>
                    </div>
                    <div class="mb-4">
                        <label class="form-label fw-600" style="font-size: 0.9rem;">새 비밀번호 확인</label>
                        <input type="password" id="newPasswordConfirm" class="tl-form-control" placeholder="새 비밀번호를 다시 입력하세요" required />
                        <div id="pwdMatch" class="form-text" style="font-size: 0.8rem;"></div>
                    </div>

                    <button type="submit" class="tl-btn-primary w-100" style="padding: 12px; font-size: 1.05rem;" id="submitBtn" disabled>
                        비밀번호 변경
                    </button>
                </form>
            </div>
        </div>
    </div>
</section>

<script>
$(function() {
    const $newPwd = $('#newPassword');
    const $newPwdConfirm = $('#newPasswordConfirm');
    const $btn = $('#submitBtn');
    
    function validate() {
        let valid = true;
        const val1 = $newPwd.val();
        const val2 = $newPwdConfirm.val();
        
        // Strength
        if (val1.length === 0) {
            $('#pwdStrength').text('');
            valid = false;
        } else if (val1.length < 8) {
            $('#pwdStrength').text('8자 이상 입력해주세요.').css('color', 'var(--danger)');
            valid = false;
        } else {
            $('#pwdStrength').text('사용 가능한 비밀번호입니다.').css('color', 'var(--success)');
        }
        
        // Match
        if (val2.length === 0) {
            $('#pwdMatch').text('');
            valid = false;
        } else if (val1 !== val2) {
            $('#pwdMatch').text('비밀번호가 일치하지 않습니다.').css('color', 'var(--danger)');
            valid = false;
        } else {
            $('#pwdMatch').text('비밀번호가 일치합니다.').css('color', 'var(--success)');
        }
        
        if ($('#currentPassword').val().length === 0) valid = false;
        
        $btn.prop('disabled', !valid);
    }

    $('#currentPassword, #newPassword, #newPasswordConfirm').on('input', validate);

    $('#changePasswordForm').on('submit', function(e) {
        e.preventDefault();
        
        api.post('${pageContext.request.contextPath}/api/member/change-password', {
            currentPassword: $('#currentPassword').val(),
            newPassword: $newPwd.val()
        })
        .done(function(res) {
            if (res.success) {
                toast.success(res.message);
                setTimeout(function() {
                    location.href = '${pageContext.request.contextPath}/member/login';
                }, 1500);
            } else {
                toast.error(res.message);
            }
        });
    });
});
</script>
