<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>판매 현황</h3>
            <p>공연별 확정 수량 및 정산 예정 금액을 한눈에 확인합니다.</p>
        </div>
        <a class="btn btn-outline-secondary btn-sm" href="/partner/promoter/dashboard">대시보드</a>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>공연</th>
                <th>공연 기간</th>
                <th>확정</th>
                <th>취소</th>
                <th>총 매출</th>
                <th>정산 예정액</th>
            </tr>
            </thead>
            <tbody>
            <c:choose>
                <c:when test="${empty salesRows}">
                    <tr><td colspan="6" class="text-center text-muted">판매 데이터가 없습니다.</td></tr>
                </c:when>
                <c:otherwise>
                    <c:forEach var="row" items="${salesRows}">
                        <tr>
                            <td>
                                <strong>${row.performance_title}</strong>
                                <div class="portal-meta">${row.venue_name} | ${row.status}</div>
                            </td>
                            <td>${row.first_show_date} ~ ${row.last_show_date}</td>
                            <td>${row.confirmed_reservations}건</td>
                            <td>${row.cancelled_reservations}건</td>
                            <td>${row.gross_sales}원</td>
                            <td>${row.settlement_amount}원</td>
                        </tr>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
            </tbody>
        </table>
    </div>
</section>
