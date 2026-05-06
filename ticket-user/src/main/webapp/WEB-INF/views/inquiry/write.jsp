<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<div class="container py-5" style="max-width: 700px;">
    <div class="mb-4">
        <h3 class="fw-800 text-center">1:1 문의 작성</h3>
    </div>

    <div class="card border-0 shadow-sm" style="border-radius: var(--radius-md);">
        <div class="card-body p-4 p-md-5">
            <form id="inquiryForm">
                <div class="mb-3">
                    <label class="form-label fw-600">문의 카테고리</label>
                    <select id="category" class="form-select tl-form-control" required>
                        <option value="GENERAL">일반 문의</option>
                        <option value="PAYMENT">결제 관련</option>
                        <option value="REFUND">취소/환불</option>
                        <option value="TICKET">티켓/입장</option>
                        <option value="ACCOUNT">계정 관련</option>
                        <option value="OTHER">기타</option>
                    </select>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-600">제목</label>
                    <input type="text" id="title" class="tl-form-control" placeholder="제목을 입력하세요" required>
                </div>
                <div class="mb-4">
                    <label class="form-label fw-600">문의 내용</label>
                    <textarea id="content" class="tl-form-control" rows="10" placeholder="자세한 내용을 입력해 주세요. (결제 번호, 공연명 등을 기재하시면 빠른 처리가 가능합니다.)" required></textarea>
                </div>
                <div class="d-grid gap-2 d-md-flex justify-content-md-end">
                    <a href="${pageContext.request.contextPath}/inquiry/list" class="btn btn-light px-4">취소</a>
                    <button type="submit" class="tl-btn-primary px-5">등록하기</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
$(function() {
    $('#inquiryForm').on('submit', function(e) {
        e.preventDefault();
        
        api.post('${pageContext.request.contextPath}/api/inquiry', {
            category: $('#category').val(),
            title: $('#title').val(),
            content: $('#content').val()
        }).done(function(res) {
            if (res.success) {
                toast.success('문의가 등록되었습니다.');
                setTimeout(() => location.href = '${pageContext.request.contextPath}/inquiry/list', 1500);
            } else {
                toast.error(res.message);
            }
        });
    });
});
</script>
