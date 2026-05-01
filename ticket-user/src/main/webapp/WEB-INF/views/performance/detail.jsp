<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<!-- Detail Hero -->
<section class="tl-detail-hero">
    <div class="container">
        <div class="row g-4 align-items-start">

            <!-- Poster -->
            <div class="col-md-3">
                <c:choose>
                    <c:when test="${not empty performance.posterUrl}">
                        <img src="${performance.posterUrl}" alt="${performance.title}" class="tl-detail-poster" />
                    </c:when>
                    <c:otherwise>
                        <div class="tl-detail-poster-placeholder">
                            <i class="bi bi-music-note-beamed"></i>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>

            <!-- Info -->
            <div class="col-md-9">
                <span class="tl-card-badge badge-${performance.genre != null ? performance.genre.toString().toLowerCase() : 'musical'} mb-3">
                    ${performance.genre}
                </span>
                <h1 class="tl-detail-title">${performance.title}</h1>

                <c:if test="${not empty performance.venueName}">
                    <div class="tl-detail-meta">
                        <i class="bi bi-geo-alt-fill"></i>
                        <span>${performance.venueName}</span>
                    </div>
                </c:if>
                <c:if test="${not empty performance.startDate}">
                    <div class="tl-detail-meta">
                        <i class="bi bi-calendar3"></i>
                        <span>
                            ${tl:fmt(performance.startDate, "yyyy.MM.dd")}
                            <c:if test="${not empty performance.endDate}">
                                ~ ${tl:fmt(performance.endDate, "yyyy.MM.dd")}
                            </c:if>
                        </span>
                    </div>
                </c:if>
                <c:if test="${not empty performance.runningTime}">
                    <div class="tl-detail-meta">
                        <i class="bi bi-clock"></i>
                        <span>공연 시간: ${performance.runningTime}분</span>
                    </div>
                </c:if>
                <c:if test="${not empty performance.ageLimit}">
                    <div class="tl-detail-meta">
                        <i class="bi bi-person-check"></i>
                        <span>관람 연령: ${performance.ageLimit}</span>
                    </div>
                </c:if>
            </div>
        </div>
    </div>
</section>

<!-- Main Content -->
<section class="tl-section">
    <div class="container">
        <div class="row g-4">

            <!-- Left: Description + Grades -->
            <div class="col-lg-7">
                <!-- Description -->
                <c:if test="${not empty performance.description}">
                    <div class="tl-detail-section">
                        <h5>공연 소개</h5>
                        <p style="font-size:.92rem;line-height:1.8;color:var(--gray-700)">
                            ${performance.description}
                        </p>
                    </div>
                </c:if>

                <!-- Seat Grades -->
                <c:if test="${not empty seatGrades}">
                    <div class="tl-detail-section">
                        <h5>좌석 등급 / 가격</h5>
                        <div class="d-flex flex-column gap-2">
                            <c:forEach var="g" items="${seatGrades}">
                                <div class="d-flex align-items-center justify-content-between
                                            p-3" style="border:1px solid var(--gray-200);border-radius:var(--radius-sm)">
                                    <div class="d-flex align-items-center gap-3">
                                        <div style="width:12px;height:12px;border-radius:50%;
                                                    background:var(--primary);flex-shrink:0"></div>
                                        <span class="fw-600">${g.gradeName}</span>
                                    </div>
                                    <span class="fw-700" style="color:var(--primary)">
                                        <fmt:formatNumber value="${g.price}" type="number" />원
                                    </span>
                                </div>
                            </c:forEach>
                        </div>
                    </div>
                </c:if>
            </div>

            <!-- Right: Schedule Selection -->
            <div class="col-lg-5">
                <div class="tl-detail-section" style="position:sticky;top:88px">
                    <h5>일정 선택</h5>

                    <c:choose>
                        <c:when test="${not empty schedules}">
                            <div id="scheduleList">
                                <c:forEach var="s" items="${schedules}">
                                    <div class="tl-schedule-item" data-schedule-id="${s.scheduleId}" data-date="${s.startDatetime}">
                                        <div>
                                            <div class="tl-schedule-date">
                                                ${tl:fmt(s.startDatetime, "yyyy.MM.dd (E)")}
                                            </div>
                                            <div class="tl-schedule-time">
                                                ${tl:fmt(s.startDatetime, "HH:mm")}
                                            </div>
                                        </div>
                                        <c:choose>
                                            <c:when test="${performance.status == 'UPCOMING'}">
                                                <span class="tl-schedule-avail avail-soon">오픈 예정</span>
                                            </c:when>
                                            <c:when test="${performance.status == 'ENDED' || s.status == 'ENDED'}">
                                                <span class="tl-schedule-avail avail-end">공연 종료</span>
                                            </c:when>
                                            <c:when test="${s.availableSeats > 20}">
                                                <span class="tl-schedule-avail avail-ok">여유 있음</span>
                                            </c:when>
                                            <c:when test="${s.availableSeats > 0}">
                                                <span class="tl-schedule-avail avail-few">잔여 ${s.availableSeats}석</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="tl-schedule-avail avail-none">매진</span>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>
                                </c:forEach>
                            </div>
                            <button id="bookBtn" class="tl-auth-btn mt-4" disabled>
                                일정을 선택해주세요
                            </button>
                        </c:when>
                        <c:otherwise>
                            <p class="text-muted text-center py-3">등록된 일정이 없습니다.</p>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>
    </div>
</section>

<script>
$(function() {
    let selectedScheduleId = null;

    $('.tl-schedule-item').on('click', function() {
        const $this = $(this);
        if ($this.find('.avail-none').length) { toast.warning('매진된 일정입니다.'); return; }
        if ($this.find('.avail-soon').length) { toast.warning('아직 예매 오픈 전입니다.'); return; }
        if ($this.find('.avail-end').length)  { toast.warning('종료된 공연입니다.'); return; }

        $('.tl-schedule-item').removeClass('selected');
        $this.addClass('selected');
        selectedScheduleId = $this.data('schedule-id');

        const dateText = $this.find('.tl-schedule-date').text();
        const timeText = $this.find('.tl-schedule-time').text();
        $('#bookBtn')
            .prop('disabled', false)
            .text(dateText + ' ' + timeText + ' — 예매하기');
    });

    $('#bookBtn').on('click', function() {
        if (!selectedScheduleId) return;
        location.href = '${pageContext.request.contextPath}/seat/select/' + selectedScheduleId;
    });
});
</script>
