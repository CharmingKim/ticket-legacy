<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<div class="portal-grid stats-4 mb-4">
    <div class="portal-stat">
        <span class="value">${summary.totalSections}</span>
        <span class="label">Sections configured</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.totalSchedules}</span>
        <span class="label">Schedules in venue</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.upcomingSchedules}</span>
        <span class="label">Upcoming schedules</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.checkedInToday}</span>
        <span class="label">Today check-ins</span>
    </div>
</div>

<div class="portal-grid columns-2">
    <section class="portal-panel">
        <div class="portal-section-title">
            <div>
                <h3>${venue.name}</h3>
                <p>${venue.address}</p>
            </div>
            <a class="btn btn-outline-secondary btn-sm" href="/partner/venue/venue-info">Venue setup</a>
        </div>
        <div class="portal-note">
            Venue operations are split into setup, schedule visibility, and day-of-show entrance control.
        </div>
    </section>

    <section class="portal-panel">
        <div class="portal-section-title">
            <div>
                <h3>Upcoming schedules</h3>
                <p>The next entries are ready for entrance and floor coordination.</p>
            </div>
            <a class="btn btn-outline-secondary btn-sm" href="/partner/venue/schedule-calendar">Open calendar</a>
        </div>
        <div class="portal-list">
            <c:choose>
                <c:when test="${empty upcomingSchedules}">
                    <div class="portal-empty">No scheduled shows are currently linked to this venue.</div>
                </c:when>
                <c:otherwise>
                    <c:forEach var="schedule" items="${upcomingSchedules}">
                        <div class="portal-list-item">
                            <strong>${schedule.performanceTitle}</strong>
                            <div class="portal-meta">${schedule.showDate} ${schedule.showTime} | ${schedule.status}</div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
    </section>
</div>

