<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<section class="tl-section">
    <div class="container" style="max-width: 600px;">
        <div class="card border-0 shadow-sm" style="border-radius: var(--radius-md);">
            <div class="card-body p-5">
                <h3 class="fw-800 text-center mb-4 text-danger"><i class="bi bi-exclamation-triangle-fill me-2"></i>회원 탈퇴</h3>
                
                <div class="alert alert-danger" style="border-radius: var(--radius-sm); font-size: 0.95rem;">
                    <strong>주의사항</strong>
                    <ul class="mb-0 mt-2 ps-3">
                        <li>탈퇴 시 보유 중인 쿠폰과 예매 대기 내역은 모두 소멸됩니다.</li>
                        <li>결제 완료된 예매 내역이 있는 경우 탈퇴가 불가능합니다. 먼저 예매를 취소해주세요.</li>
                        <li>탈퇴 후 동일한 이메일로 재가입이 제한될 수 있습니다.</li>
                    </ul>
                </div>

                <form id="withdrawForm" class="mt-4">
                    <div class="mb-3">
                        <label class="form-label fw-600" style="font-size: 0.9rem;">탈퇴 사유</label>
                        <select id="reason" class="form-select" required style="border-radius: var(--radius-sm);">
                            <option value="">선택해주세요</option>
                            <option value="NO_LONGER_USE">더 이상 서비스를 이용하지 않음</option>
                            <option value="UNSATISFIED">서비스 불만족</option>
                            <option value="TOO_MANY_ERRORS">잦은 오류 및 버그</option>
                            <option value="EXPENSIVE">티켓 가격 및 수수료 부담</option>
                            <option value="OTHER">기타</option>
                        </select>
                    </div>
                    
                    <div class="mb-4">
                        <label class="form-label fw-600" style="font-size: 0.9rem;">비밀번호 확인</label>
                        <input type="password" id="password" class="tl-form-control" placeholder="본인 확인을 위해 비밀번호를 입력해주세요" required />
                    </div>

                    <div class="form-check mb-4">
                        <input class="form-check-input" type="checkbox" id="agreeWithdraw" required>
                        <label class="form-check-label text-muted" for="agreeWithdraw" style="font-size: 0.9rem;">
                            안내사항을 모두 확인하였으며, 이에 동의합니다.
                        </label>
                    </div>

                    <div class="d-flex gap-2">
                        <a href="${pageContext.request.contextPath}/member/mypage" class="tl-btn-outline w-50 text-center" style="padding: 12px; font-size: 1.05rem;">취소</a>
                        <button type="submit" class="btn btn-danger w-50" style="padding: 12px; font-size: 1.05rem; border-radius: var(--radius-sm);">회원 탈퇴</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</section>

<script>
$(function() {
    $('#withdrawForm').on('submit', function(e) {
        e.preventDefault();
        
        if (!confirm('정말로 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다.')) {
            return;
        }
        
        api.post('${pageContext.request.contextPath}/api/member/withdraw', {
            password: $('#password').val(),
            reason: $('#reason').val()
        })
        .done(function(res) {
            if (res.success) {
                toast.success(res.message);
                setTimeout(function() {
                    location.href = '${pageContext.request.contextPath}/';
                }, 1500);
            } else {
                toast.error(res.message);
            }
        });
    });
});
</script>
