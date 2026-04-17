<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>Schedule calendar</h3>
            <p>Shared venue view across all performances connected to this house.</p>
        </div>
        <button class="btn btn-outline-secondary btn-sm" onclick="reloadSchedules()">Refresh</button>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>Date</th>
                <th>Time</th>
                <th>Performance</th>
                <th>Approval</th>
                <th>Available seats</th>
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
        const rows = (schedules || []).map(function(schedule) {
            return `
                <tr>
                    <td>${schedule.showDate}</td>
                    <td>${schedule.showTime}</td>
                    <td>${schedule.performanceTitle}</td>
                    <td>${schedule.approvalStatus}</td>
                    <td>${schedule.availableSeats}</td>
                </tr>`;
        }).join('');
        $('#calendarRows').html(rows || '<tr><td colspan="5" class="text-center text-muted">No schedules.</td></tr>');
    });
}
</script>
