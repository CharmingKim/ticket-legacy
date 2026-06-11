<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<section class="tl-section">
    <div class="container" style="max-width: 800px;">
        <div class="mb-4 d-flex justify-content-between align-items-center">
            <div>
                <h3 class="fw-800 mb-1">예매 상세 내역</h3>
                <p class="text-muted mb-0">예매 번호: <span class="fw-600">${reservation.reservationNo}</span></p>
            </div>
            <c:if test="${reservation.status == 'CONFIRMED'}">
                <a href="${pageContext.request.contextPath}/reservation/ticket/${reservation.reservationId}" class="tl-btn-primary">
                    <i class="bi bi-qr-code-scan me-2"></i>전자티켓 보기
                </a>
            </c:if>
        </div>

        <div class="card border-0 shadow-sm mb-4" style="border-radius: var(--radius-md);">
            <div class="card-body p-4">
                <h5 class="fw-700 border-bottom pb-3 mb-3">공연 정보</h5>
                <div class="row align-items-center">
                    <div class="col-12 col-md-8">
                        <h4 class="fw-800 text-primary mb-2">${reservation.performanceTitle}</h4>
                        <div class="tl-detail-meta mb-1">
                            <i class="bi bi-geo-alt-fill text-muted me-2"></i>
                            <span>${reservation.venue}</span>
                        </div>
                        <div class="tl-detail-meta mb-1">
                            <i class="bi bi-calendar3 text-muted me-2"></i>
                            <span class="fw-600">${tl:fmt(reservation.showDate, "yyyy.MM.dd")} ${reservation.showTime}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="card border-0 shadow-sm mb-4" style="border-radius: var(--radius-md);">
            <div class="card-body p-4">
                <h5 class="fw-700 border-bottom pb-3 mb-3">좌석 정보</h5>
                <ul class="list-group list-group-flush">
                    <c:forEach var="seat" items="${reservation.seats}">
                        <li class="list-group-item px-0 d-flex justify-content-between align-items-center border-0">
                            <div>
                                <span class="badge bg-secondary me-2">${seat.grade}</span>
                                <span class="fw-600">${seat.section}구역 ${seat.seatRow}열 ${seat.seatNumber}번</span>
                            </div>
                            <span class="fw-700"><fmt:formatNumber value="${seat.price}" type="number" />원</span>
                        </li>
                    </c:forEach>
                </ul>
            </div>
        </div>

        <div class="card border-0 shadow-sm mb-4" style="border-radius: var(--radius-md);">
            <div class="card-body p-4">
                <h5 class="fw-700 border-bottom pb-3 mb-3">결제 정보</h5>
                <div class="d-flex justify-content-between mb-2">
                    <span class="text-muted">결제 수단</span>
                    <span class="fw-600">${reservation.paymentMethod != null ? reservation.paymentMethod : '결제 대기'}</span>
                </div>
                <div class="d-flex justify-content-between mb-2">
                    <span class="text-muted">상태</span>
                    <c:choose>
                        <c:when test="${reservation.status == 'CONFIRMED'}"><span class="text-success fw-600">결제 완료</span></c:when>
                        <c:when test="${reservation.status == 'PENDING'}"><span class="text-warning fw-600">결제 대기</span></c:when>
                        <c:when test="${reservation.status == 'CANCELLED'}"><span class="text-danger fw-600">취소됨</span></c:when>
                    </c:choose>
                </div>
                <hr>
                <div class="d-flex justify-content-between align-items-center">
                    <span class="fw-700" style="font-size: 1.1rem;">총 결제 금액</span>
                    <span class="fw-800 text-primary" style="font-size: 1.3rem;"><fmt:formatNumber value="${reservation.totalAmount}" type="number" />원</span>
                </div>
            </div>
        </div>

        <!-- Refund Policy -->
        <div class="card border-0 shadow-sm mb-4 bg-light" style="border-radius: var(--radius-md);">
            <div class="card-body p-4">
                <h5 class="fw-700 text-danger mb-3"><i class="bi bi-info-circle-fill me-2"></i>취소 및 환불 규정</h5>
                <ul class="mb-0 text-muted" style="font-size: 0.9rem;">
                    <li>관람일 10일 전까지: <strong class="text-dark">전액 환불</strong></li>
                    <li>관람일 7~9일 전까지: <strong class="text-dark">결제 금액의 10% 수수료 공제 후 환불</strong></li>
                    <li>관람일 3~6일 전까지: <strong class="text-dark">결제 금액의 20% 수수료 공제 후 환불</strong></li>
                    <li>관람일 1~2일 전까지: <strong class="text-dark">결제 금액의 30% 수수료 공제 후 환불</strong></li>
                    <li>공연 당일 및 이후: <strong class="text-danger">취소 및 환불 불가</strong></li>
                </ul>
                <c:if test="${reservation.status == 'CONFIRMED'}">
                    <div class="mt-4 text-center">
                        <button class="btn btn-outline-danger w-100" id="cancelBtn" style="padding: 12px; font-weight: 600;">
                            예매 취소
                        </button>
                    </div>
                </c:if>
            </div>
        </div>
        
        <div class="text-center mt-4">
            <a href="${pageContext.request.contextPath}/reservation/history" class="tl-btn-outline" style="padding: 12px 30px;">목록으로</a>
        </div>
    </div>
</section>

<script>
$(function() {
    $('#cancelBtn').on('click', function() {
        if (!confirm('정말로 이 예매를 취소하시겠습니까?\n취소 시점에 따라 수수료가 부과될 수 있습니다.')) return;
        
        api.post('${pageContext.request.contextPath}/api/reservation/${reservation.reservationId}/cancel', {})
        .done(function(res) {
            if (res.success) {
                toast.success('예매가 취소되었습니다.');
                setTimeout(() => location.reload(), 1500);
            } else {
                toast.error(res.message);
            }
        });
    });
});
</script>
