<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<div class="container py-5" style="max-width: 800px;">
    <div class="mb-4 d-flex justify-content-between align-items-center">
        <a href="${pageContext.request.contextPath}/inquiry/list" class="text-decoration-none text-muted">
            <i class="bi bi-chevron-left"></i> 목록으로
        </a>
        <c:if test="${inquiry.status == 'PENDING'}">
            <button class="btn btn-outline-danger btn-sm" id="btnDelete">삭제</button>
        </c:if>
    </div>

    <div class="card border-0 shadow-sm mb-4" style="border-radius: var(--radius-md);">
        <div class="card-body p-4 p-md-5">
            <div class="d-flex justify-content-between align-items-start mb-4">
                <div>
                    <span class="badge bg-light text-dark mb-2 border">${inquiry.category}</span>
                    <h3 class="fw-800">${inquiry.title}</h3>
                    <div class="text-muted small">${tl:fmt(inquiry.createdAt, "yyyy.MM.dd HH:mm")}</div>
                </div>
                <span class="badge ${inquiry.status == 'PENDING' ? 'bg-warning text-dark' : 'bg-success'}">
                    ${inquiry.status == 'PENDING' ? '답변대기' : '답변완료'}
                </span>
            </div>
            <div class="inquiry-content py-3 mb-4 border-top border-bottom" style="line-height: 1.8; white-space: pre-wrap;">${inquiry.content}</div>
        </div>
    </div>

    <c:if test="${not empty inquiry.answer}">
        <div class="card border-0 shadow-sm bg-light" style="border-radius: var(--radius-md);">
            <div class="card-body p-4 p-md-5">
                <div class="d-flex align-items-center gap-2 mb-3">
                    <div class="bg-dark text-white rounded-circle d-flex align-items-center justify-content-center" style="width:32px;height:32px;">
                        <i class="bi bi-info-circle"></i>
                    </div>
                    <h5 class="fw-700 mb-0">운영자 답변</h5>
                    <span class="text-muted small ms-2">${tl:fmt(inquiry.answeredAt, "yyyy.MM.dd HH:mm")}</span>
                </div>
                <div class="answer-content py-2" style="line-height: 1.8; white-space: pre-wrap;">${inquiry.answer}</div>
            </div>
        </div>
    </c:if>
</div>

<script>
$(function() {
    $('#btnDelete').on('click', function() {
        if (!confirm('문의를 삭제하시겠습니까?')) return;
        
        api.delete('${pageContext.request.contextPath}/api/inquiry/${inquiry.inquiryId}')
        .done(function(res) {
            if (res.success) {
                toast.success('삭제되었습니다.');
                location.href = '${pageContext.request.contextPath}/inquiry/list';
            } else {
                toast.error(res.message);
            }
        });
    });
});
</script>
