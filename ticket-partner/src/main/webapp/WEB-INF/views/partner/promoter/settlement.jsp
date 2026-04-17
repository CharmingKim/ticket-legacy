<%@ page contentType="text/html;charset=UTF-8" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>Settlement preview</h3>
            <p>Preview payable amount by performance and month before finance closes the period.</p>
        </div>
        <div class="d-flex gap-2">
            <input id="yearMonth" type="month" class="form-control form-control-sm" value="${defaultYearMonth}" />
            <button class="btn btn-primary btn-sm" onclick="loadSettlement()">Load</button>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>Month</th>
                <th>Performance</th>
                <th>Confirmed</th>
                <th>Cancelled</th>
                <th>Gross</th>
                <th>Platform fee</th>
                <th>Payable</th>
            </tr>
            </thead>
            <tbody id="settlementRows">
            <c:forEach var="row" items="${rows}">
                <tr>
                    <td>${row.year_month}</td>
                    <td><strong>${row.performance_title}</strong><div class="portal-meta">${row.venue_name}</div></td>
                    <td>${row.confirmed_reservations}</td>
                    <td>${row.cancelled_reservations}</td>
                    <td>${row.gross_sales}</td>
                    <td>${row.platform_fee}</td>
                    <td>${row.payable_amount}</td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </div>
</section>

<script>
function loadSettlement() {
    $.get('/partner/promoter/api/settlement', { yearMonth: $('#yearMonth').val() })
        .done(function(result) {
            const rows = (result.rows || []).map(function(item) {
                return `
                    <tr>
                        <td>${item.year_month}</td>
                        <td><strong>${item.performance_title}</strong><div class="portal-meta">${item.venue_name}</div></td>
                        <td>${item.confirmed_reservations}</td>
                        <td>${item.cancelled_reservations}</td>
                        <td>${item.gross_sales}</td>
                        <td>${item.platform_fee}</td>
                        <td>${item.payable_amount}</td>
                    </tr>`;
            }).join('');
            $('#settlementRows').html(rows || '<tr><td colspan="7" class="text-center text-muted">No rows for the selected month.</td></tr>');
        });
}
</script>
