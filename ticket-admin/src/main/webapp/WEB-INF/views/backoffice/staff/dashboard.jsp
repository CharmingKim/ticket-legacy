<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<div class="portal-grid stats-4 mb-4">
    <div class="portal-stat">
        <span class="value metric-accent-backoffice">${summary.todayReservations}</span>
        <span class="label">Today reservations</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.todayConfirmedReservations}</span>
        <span class="label">Today confirmed</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.cancelledReservations}</span>
        <span class="label">Cancelled / refunded</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.totalMembers}</span>
        <span class="label">Members in system</span>
    </div>
</div>

<div class="portal-grid columns-2">
    <section class="portal-panel">
        <div class="portal-section-title">
            <div>
                <h3>Support desk focus</h3>
                <p>Search reservations, update member status, and resolve issues quickly.</p>
            </div>
            <div class="d-flex gap-2">
                <a class="btn btn-primary btn-sm" href="/backoffice/staff/reservation-search">Reservation search</a>
                <a class="btn btn-outline-secondary btn-sm" href="/backoffice/staff/member-search">Member search</a>
            </div>
        </div>
        <div class="portal-note">
            Staff handles operational recovery and support, while approval and commercial governance stay in the super admin portal.
        </div>
    </section>

    <section class="portal-panel">
        <div class="portal-section-title">
            <div>
                <h3>Recent reservations</h3>
                <p>Latest traffic entering the system</p>
            </div>
        </div>
        <div class="portal-list">
            <c:choose>
                <c:when test="${empty recentReservations}">
                    <div class="portal-empty">No reservations yet.</div>
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

