<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>Settlement oversight</h3>
            <p>Review monthly partner payout exposure across the marketplace.</p>
        </div>
        <div class="d-flex gap-2">
            <select id="settlementPromoter" class="form-select form-select-sm">
                <option value="">All promoters</option>
                <c:forEach var="promoter" items="${promoters}">
                    <option value="${promoter.promoterId}">${promoter.companyName}</option>
                </c:forEach>
            </select>
            <input id="settlementMonth" type="month" class="form-control form-control-sm" value="${defaultYearMonth}" />
            <button class="btn btn-primary btn-sm" onclick="loadSettlementReport()">Load</button>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>Month</th>
                <th>Promoter</th>
                <th>Performance</th>
                <th>Gross</th>
                <th>Fee</th>
                <th>Payable</th>
            </tr>
            </thead>
            <tbody id="settlementReportRows"></tbody>
        </table>
    </div>
</section>

<script>
function loadSettlementReport() {
    $.get('/backoffice/super/api/settlement', {
        promoterId: $('#settlementPromoter').val(),
        yearMonth: $('#settlementMonth').val()
    }).done(function(result) {
        const rows = (result.rows || []).map(function(item) {
            return `
                <tr>
                    <td>${item.year_month}</td>
                    <td>${item.promoter_company_name || 'Direct'}</td>
                    <td><strong>${item.performance_title}</strong><div class="portal-meta">${item.venue_name}</div></td>
                    <td>${item.gross_sales}</td>
                    <td>${item.platform_fee}</td>
                    <td>${item.payable_amount}</td>
                </tr>`;
        }).join('');
        $('#settlementReportRows').html(rows || '<tr><td colspan="6" class="text-center text-muted">No settlement rows.</td></tr>');
    });
}

$(loadSettlementReport);
</script>
