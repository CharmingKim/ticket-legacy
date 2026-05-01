<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>공연 일정</h3>
            <p>이 공연장에 연결된 전체 공연 일정을 확인합니다.</p>
        </div>
        <button class="btn btn-outline-secondary btn-sm" onclick="reloadSchedules()">새로고침</button>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>날짜</th>
                <th>시간</th>
                <th>공연</th>
                <th>승인 상태</th>
                <th>잔여 좌석</th>
            </tr>
            </thead>
            <tbody id="calendarRows">
            <c:forEach var="schedule" items="${schedules}">
                <tr>
                    <td>${schedule.showDate}</td>
                    <td>${schedule.showTime}</td>
                    <td>${schedule.performanceTitle}</td>
                    <td>${schedule.approvalStatus}</td>
                    <td>${schedule.availableSeats}</td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </div>
</section>

<script>
function reloadSchedules() {
    $.get('/partner/venue/api/schedules/calendar').done(function(schedules) {
        var rows = (schedules || []).map(function(s) {
            return '<tr>' +
                '<td>' + s.showDate + '</td>' +
                '<td>' + s.showTime + '</td>' +
                '<td>' + s.performanceTitle + '</td>' +
                '<td>' + s.approvalStatus + '</td>' +
                '<td>' + s.availableSeats + '</td>' +
                '</tr>';
        }).join('');
        $('#calendarRows').html(rows || '<tr><td colspan="5" class="text-center text-muted">등록된 일정이 없습니다.</td></tr>');
    });
}
</script>
