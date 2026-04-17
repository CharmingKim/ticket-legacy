<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<div class="container py-5">
    <div class="mb-4">
        <h3 class="fw-800" style="letter-spacing:-.5px">예매 내역</h3>
        <p class="text-muted">나의 공연 예매 기록입니다.</p>
    </div>

    <c:choose>
        <c:when test="${not empty reservations}">
            <div class="table-responsive" style="border:1px solid var(--gray-200);border-radius:var(--radius-md);overflow:hidden">
                <table class="tl-table">
                    <thead>
                        <tr>
                            <th>공연명</th>
                            <th>일정</th>
                            <th>좌석</th>
                            <th>금액</th>
                            <th>상태</th>
                            <th>예매일</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="r" items="${reservations}">
                            <tr>
                                <td>
                                    <div class="fw-600">${r.performanceTitle}</div>
                                    <div class="text-muted" style="font-size:.8rem">${r.venueName}</div>
                                </td>
                                <td>
                                    <c:if test="${not empty r.scheduleDatetime}">
                                        ${tl:fmt(r.scheduleDatetime, "yyyy.MM.dd HH:mm")}
                                    </c:if>
                                </td>
                                <td>
                                    <span class="tl-badge tl-badge-muted">${r.seatLabel}</span>
                                </td>
                                <td class="fw-700">
                                    <fmt:formatNumber value="${r.finalAmount}" type="number" />원
                                </td>
                                <td>
                                    <c:choose>
                                        <c:when test="${r.status == 'CONFIRMED'}">
                                            <span class="tl-badge tl-badge-success">예매 완료</span>
                                        </c:when>
                                        <c:when test="${r.status == 'PENDING'}">
                                            <span class="tl-badge tl-badge-warning">대기 중</span>
                                        </c:when>
                                        <c:when test="${r.status == 'CANCELLED'}">
                                            <span class="tl-badge tl-badge-danger">취소됨</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="tl-badge tl-badge-muted">${r.status}</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>
                                <td style="font-size:.85rem;color:var(--text-muted)">
                                    <c:if test="${not empty r.createdAt}">
                                        ${tl:fmt(r.createdAt, "yyyy.MM.dd")}
                                    </c:if>
                                </td>
                                <td>
                                    <c:if test="${r.status == 'CONFIRMED'}">
                                        <button class="btn-cancel tl-btn-outline btn-sm"
                                                data-reservation-id="${r.reservationId}"
                                                style="font-size:.78rem;padding:4px 12px">
                                            취소
                                        </button>
                                    </c:if>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:when>
        <c:otherwise>
            <div class="text-center py-5">
                <i class="bi bi-ticket" style="font-size:3.5rem;color:var(--gray-300)"></i>
                <p class="mt-3 text-muted">예매 내역이 없습니다.</p>
                <a href="${pageContext.request.contextPath}/performance/list" class="tl-btn-primary mt-2">
                    <i class="bi bi-search me-2"></i>공연 둘러보기
                </a>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<script>
const ctx = '${pageContext.request.contextPath}';

$(document).on('click', '.btn-cancel', function() {
    const reservationId = $(this).data('reservation-id');
    if (!confirm('예매를 취소하시겠습니까? 취소 후에는 되돌릴 수 없습니다.')) return;

    api.post(ctx + '/api/reservations/' + reservationId + '/cancel', {})
        .done(function(res) {
            if (res.success) {
                toast.success('예매가 취소되었습니다.');
                setTimeout(() => location.reload(), 1500);
            } else {
                toast.error(res.message || '취소에 실패했습니다.');
            }
        });
});
</script>
