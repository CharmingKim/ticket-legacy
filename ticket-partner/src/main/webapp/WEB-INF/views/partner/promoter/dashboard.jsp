<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<div class="portal-grid stats-4 mb-4">
    <div class="portal-stat">
        <span class="value metric-accent-partner">${summary.totalPerformances}</span>
        <span class="label">Total performances</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.reviewCount}</span>
        <span class="label">Under review</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.confirmedReservations}</span>
        <span class="label">Confirmed reservations</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.grossSales}</span>
        <span class="label">Gross sales</span>
    </div>
</div>

<div class="portal-grid columns-2">
    <section class="portal-panel">
        <div class="portal-section-title">
            <div>
                <h3>${promoter.companyName}</h3>
                <p>${promoter.representative} | ${promoter.contactEmail}</p>
            </div>
            <div class="d-flex gap-2">
                <a class="btn btn-primary btn-sm" href="/partner/promoter/performances">Manage performances</a>
                <a class="btn btn-outline-secondary btn-sm" href="/partner/promoter/settlement">Settlement</a>
            </div>
        </div>
        <div class="portal-note mb-4">
            Your portal is organized around approval flow, sales visibility, and settlement readiness.
        </div>
        <div class="portal-table-wrap">
            <table class="table portal-table">
                <thead>
                <tr>
                    <th>Performance</th>
                    <th>Status</th>
                    <th>Venue</th>
                    <th>Period</th>
                </tr>
                </thead>
                <tbody>
                <c:choose>
                    <c:when test="${empty recentPerformances}">
                        <tr><td colspan="4" class="text-center text-muted">No performances yet.</td></tr>
                    </c:when>
                    <c:otherwise>
                        <c:forEach var="performance" items="${recentPerformances}">
                            <tr>
                                <td>
                                    <strong>${performance.title}</strong>
                                    <div class="portal-meta">${performance.category}</div>
                                </td>
                                <td><span class="badge-status badge-${performance.approvalStatus}">${performance.approvalStatus}</span></td>
                                <td>${performance.venueName}</td>
                                <td>${performance.startDate} - ${performance.endDate}</td>
                            </tr>
                        </c:forEach>
                    </c:otherwise>
                </c:choose>
                </tbody>
            </table>
        </div>
    </section>

    <section class="portal-panel">
        <div class="portal-section-title">
            <div>
                <h3>Sales snapshot</h3>
                <p>Top lines across currently managed performances</p>
            </div>
            <a class="btn btn-outline-secondary btn-sm" href="/partner/promoter/sales-report">Open report</a>
        </div>
        <div class="portal-list">
            <c:choose>
                <c:when test="${empty salesRows}">
                    <div class="portal-empty">Sales data will appear after confirmed bookings start coming in.</div>
                </c:when>
                <c:otherwise>
                    <c:forEach var="row" items="${salesRows}">
                        <div class="portal-list-item">
                            <strong>${row.performance_title}</strong>
                            <div class="portal-meta">
                                Confirmed ${row.confirmed_reservations} | Sales ${row.gross_sales} | Settlement ${row.settlement_amount}
                            </div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
    </section>
</div>

