<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>정산 미리보기</h3>
            <p>공연별·월별 정산 예정 금액을 미리 확인합니다.</p>
        </div>
        <div class="d-flex gap-2">
            <input id="yearMonth" type="month" class="form-control form-control-sm" value="${defaultYearMonth}" />
            <button class="btn btn-primary btn-sm" onclick="loadSettlement()">조회</button>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>월</th>
                <th>공연</th>
                <th>확정</th>
                <th>취소</th>
                <th>총 매출</th>
                <th>플랫폼 수수료</th>
                <th>지급 예정액</th>
            </tr>
            </thead>
            <tbody id="settlementRows">
            <c:forEach var="row" items="${rows}">
                <tr>
                    <td>${row.year_month}</td>
                    <td><strong>${row.performance_title}</strong><div class="portal-meta">${row.venue_name}</div></td>
                    <td>${row.confirmed_reservations}건</td>
                    <td>${row.cancelled_reservations}건</td>
                    <td>${row.gross_sales}원</td>
                    <td>${row.platform_fee}원</td>
                    <td>${row.payable_amount}원</td>
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
            var rows = (result.rows || []).map(function(item) {
                return '<tr>' +
                    '<td>' + item.year_month + '</td>' +
                    '<td><strong>' + item.performance_title + '</strong>' +
                        '<div class="portal-meta">' + item.venue_name + '</div></td>' +
                    '<td>' + item.confirmed_reservations + '건</td>' +
                    '<td>' + item.cancelled_reservations + '건</td>' +
                    '<td>' + item.gross_sales + '원</td>' +
                    '<td>' + item.platform_fee + '원</td>' +
                    '<td>' + item.payable_amount + '원</td>' +
                    '</tr>';
            }).join('');
            $('#settlementRows').html(rows || '<tr><td colspan="7" class="text-center text-muted">선택한 월의 정산 내역이 없습니다.</td></tr>');
        });
}
</script>
