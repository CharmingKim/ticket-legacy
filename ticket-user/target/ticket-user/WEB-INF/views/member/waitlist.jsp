<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<div class="container py-5">
    <div class="mb-4">
        <h3 class="fw-800">예매 대기 내역</h3>
        <p class="text-muted">매진된 공연의 취소표 알림 신청 목록입니다.</p>
    </div>

    <c:choose>
        <c:when test="${not empty waitlist}">
            <div class="card border-0 shadow-sm" style="border-radius: var(--radius-md);">
                <div class="table-responsive">
                    <table class="table mb-0 tl-table">
                        <thead class="bg-light">
                            <tr>
                                <th class="ps-4">상태</th>
                                <th>공연 정보</th>
                                <th>공연 일시</th>
                                <th>신청일</th>
                                <th class="pe-4 text-center">작업</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="w" items="${waitlist}">
                                <tr>
                                    <td class="ps-4">
                                        <c:choose>
                                            <c:when test="${w.status == 'WAITING'}">
                                                <span class="badge bg-warning text-dark px-3">대기중</span>
                                            </c:when>
                                            <c:when test="${w.status == 'NOTIFIED'}">
                                                <span class="badge bg-success px-3">알림완료</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="badge bg-secondary px-3">${w.status}</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </td>
                                    <td class="fw-700 text-dark">${w.performanceTitle}</td>
                                    <td class="text-muted">
                                        ${tl:fmt(w.showDate, "yyyy.MM.dd")} ${w.showTime}
                                    </td>
                                    <td class="text-muted small">
                                        ${tl:fmt(w.createdAt, "yyyy.MM.dd")}
                                    </td>
                                    <td class="pe-4 text-center">
                                        <c:if test="${w.status == 'WAITING'}">
                                            <button class="btn btn-outline-danger btn-sm px-3 btn-cancel-wait" data-sid="${w.scheduleId}">
                                                취소
                                            </button>
                                        </c:if>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </div>
        </c:when>
        <c:otherwise>
            <div class="text-center py-5">
                <i class="bi bi-bell-slash" style="font-size:3.5rem;color:var(--gray-300)"></i>
                <p class="mt-3 text-muted">신청하신 예매 대기 내역이 없습니다.</p>
                <a href="${pageContext.request.contextPath}/performance/list" class="tl-btn-primary mt-2">
                    <i class="bi bi-search me-2"></i>공연 둘러보기
                </a>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<script>
$(function() {
    $('.btn-cancel-wait').on('click', function() {
        if (!confirm('예매 대기를 취소하시겠습니까?')) return;
        const sid = $(this).data('sid');
        const $row = $(this).closest('tr');
        
        api.delete('${pageContext.request.contextPath}/api/waitlist/' + sid)
        .done(function(res) {
            if (res.success) {
                toast.success('취소되었습니다.');
                $row.fadeOut(300, function() {
                    $(this).remove();
                    if ($('tbody tr').length === 0) location.reload();
                });
            } else {
                toast.error(res.message);
            }
        });
    });
});
</script>
