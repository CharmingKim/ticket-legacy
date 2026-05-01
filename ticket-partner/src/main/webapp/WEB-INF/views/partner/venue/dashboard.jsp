<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<div class="portal-grid stats-4 mb-4">
    <div class="portal-stat">
        <span class="value">${summary.totalSections}</span>
        <span class="label">구역 수</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.totalSchedules}</span>
        <span class="label">총 공연 일정</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.upcomingSchedules}</span>
        <span class="label">예정된 공연</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.checkedInToday}</span>
        <span class="label">오늘 입장</span>
    </div>
</div>

<div class="portal-grid columns-2">
    <section class="portal-panel">
        <div class="portal-section-title">
            <div>
                <h3>${venue.name}</h3>
                <p>${venue.address}</p>
            </div>
            <a class="btn btn-outline-secondary btn-sm" href="/partner/venue/venue-info">공연장 설정</a>
        </div>
        <div class="portal-note">
            공연장 구역 설정, 공연 일정 확인, 입장 관리를 진행합니다.
        </div>
    </section>

    <section class="portal-panel">
        <div class="portal-section-title">
            <div>
                <h3>예정 공연 일정</h3>
                <p>입장 및 현장 운영이 필요한 공연 일정입니다.</p>
            </div>
            <a class="btn btn-outline-secondary btn-sm" href="/partner/venue/schedule-calendar">일정 보기</a>
        </div>
        <div class="portal-list">
            <c:choose>
                <c:when test="${empty upcomingSchedules}">
                    <div class="portal-empty">등록된 공연 일정이 없습니다.</div>
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
