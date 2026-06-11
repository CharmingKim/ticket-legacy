<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<div class="portal-grid stats-4 mb-4">
    <div class="portal-stat">
        <span class="value metric-accent-backoffice">${summary.todayReservations}</span>
        <span class="label">오늘 예약</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.todayConfirmedReservations}</span>
        <span class="label">오늘 확정</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.cancelledReservations}</span>
        <span class="label">취소/환불</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.totalMembers}</span>
        <span class="label">전체 회원</span>
    </div>
</div>

<div class="portal-grid columns-2">
    <section class="portal-panel">
        <div class="portal-section-title">
            <div>
                <h3>고객지원 대시보드</h3>
                <p>예약 조회, 회원 상태 변경, 문의 처리를 빠르게 진행하세요.</p>
            </div>
            <div class="d-flex gap-2">
                <a class="btn btn-primary btn-sm" href="/backoffice/staff/reservation-search">예약 조회</a>
                <a class="btn btn-outline-secondary btn-sm" href="/backoffice/staff/member-search">회원 조회</a>
            </div>
        </div>
        <div class="portal-note">
            스태프는 운영 복구 및 고객지원을 담당합니다. 승인·정산 등 관리 기능은 최고관리자 포털에서 처리됩니다.
        </div>
    </section>

    <section class="portal-panel">
        <div class="portal-section-title">
            <div>
                <h3>최근 예약</h3>
                <p>최신 예약 현황</p>
            </div>
        </div>
        <div class="portal-list">
            <c:choose>
                <c:when test="${empty recentReservations}">
                    <div class="portal-empty">최근 예약 없음</div>
                </c:when>
                <c:otherwise>
                    <c:forEach var="reservation" items="${recentReservations}">
                        <div class="portal-list-item">
                            <strong>${reservation.reservationNo}</strong>
                            <div class="portal-meta">${reservation.performanceTitle} | ${reservation.memberName} | ${reservation.status}</div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
    </section>
</div>

