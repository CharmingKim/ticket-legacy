<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>정산 관리</h3>
            <p>파트너별 월간 정산 현황을 검토합니다.</p>
        </div>
        <div class="d-flex gap-2">
            <select id="settlementPromoter" class="form-select form-select-sm">
                <option value="">전체 기획사</option>
                <c:forEach var="promoter" items="${promoters}">
                    <option value="${promoter.promoterId}">${promoter.companyName}</option>
                </c:forEach>
            </select>
            <input id="settlementMonth" type="month" class="form-control form-control-sm" value="${defaultYearMonth}" />
            <button class="btn btn-primary btn-sm" onclick="loadSettlementReport()">조회</button>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>월</th>
                <th>기획사</th>
                <th>공연</th>
                <th>총 매출</th>
                <th>수수료</th>
                <th>지급 예정액</th>
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
        var rows = (result.rows || []).map(function(item) {
            return '<tr>' +
                '<td>' + item.year_month + '</td>' +
                '<td>' + (item.promoter_company_name || '직접') + '</td>' +
                '<td><strong>' + item.performance_title + '</strong>' +
                    '<div class="portal-meta">' + item.venue_name + '</div></td>' +
                '<td>' + item.gross_sales + '원</td>' +
                '<td>' + item.platform_fee + '원</td>' +
                '<td>' + item.payable_amount + '원</td>' +
                '</tr>';
        }).join('');
        $('#settlementReportRows').html(rows || '<tr><td colspan="6" class="text-center text-muted">정산 내역이 없습니다.</td></tr>');
    });
}

$(loadSettlementReport);
</script>
