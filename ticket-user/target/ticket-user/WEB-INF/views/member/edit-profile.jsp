<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<section class="tl-section">
    <div class="container" style="max-width: 500px;">
        <div class="card border-0 shadow-sm" style="border-radius: var(--radius-md);">
            <div class="card-body p-5">
                <h3 class="fw-800 text-center mb-4"><i class="bi bi-person-lines-fill me-2"></i>회원 정보 수정</h3>
                
                <form id="editProfileForm">
                    <div class="mb-3">
                        <label class="form-label fw-600" style="font-size: 0.9rem;">이메일 (변경 불가)</label>
                        <input type="text" class="tl-form-control bg-light" value="${loginMember.email}" readonly disabled />
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-600" style="font-size: 0.9rem;">이름</label>
                        <input type="text" id="name" class="tl-form-control" value="${loginMember.name}" required />
                    </div>
                    <div class="mb-4">
                        <label class="form-label fw-600" style="font-size: 0.9rem;">전화번호</label>
                        <input type="text" id="phone" class="tl-form-control" value="${loginMember.phone}" placeholder="010-0000-0000" />
                    </div>

                    <div class="d-flex gap-2">
                        <a href="${pageContext.request.contextPath}/member/mypage" class="tl-btn-outline w-50 text-center" style="padding: 12px; font-size: 1.05rem;">취소</a>
                        <button type="submit" class="tl-btn-primary w-50" style="padding: 12px; font-size: 1.05rem;">저장</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</section>

<script>
$(function() {
    $('#editProfileForm').on('submit', function(e) {
        e.preventDefault();
        
        api.post('${pageContext.request.contextPath}/api/member/update', {
            name: $('#name').val().trim(),
            phone: $('#phone').val().trim()
        })
        .done(function(res) {
            if (res.success) {
                toast.success(res.message);
                setTimeout(function() {
                    location.href = '${pageContext.request.contextPath}/member/mypage';
                }, 1000);
            } else {
                toast.error(res.message);
            }
        });
    });
});
</script>
