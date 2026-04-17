<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>Sales report</h3>
            <p>Commercial view by performance, combining confirmation volume and expected payable amount.</p>
        </div>
        <a class="btn btn-outline-secondary btn-sm" href="/partner/promoter/dashboard">Back</a>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>Performance</th>
                <th>Window</th>
                <th>Confirmed</th>
                <th>Cancelled</th>
                <th>Gross sales</th>
                <th>Settlement</th>
            </tr>
            </thead>
            <tbody>
            <c:choose>
                <c:when test="${empty salesRows}">
                    <tr><td colspan="6" class="text-center text-muted">No sales data yet.</td></tr>
                </c:when>
                <c:otherwise>
                    <c:forEach var="row" items="${salesRows}">
                        <tr>
                            <td>
                                <strong>${row.performance_title}</strong>
                                <div class="portal-meta">${row.venue_name} | ${row.status}</div>
                            </td>
                            <td>${row.first_show_date} - ${row.last_show_date}</td>
                            <td>${row.confirmed_reservations}</td>
                            <td>${row.cancelled_reservations}</td>
                            <td>${row.gross_sales}</td>
                            <td>${row.settlement_amount}</td>
                        </tr>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
            </tbody>
        </table>
    </div>
</section>

