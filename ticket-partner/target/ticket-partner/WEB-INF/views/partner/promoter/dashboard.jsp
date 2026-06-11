<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<div class="portal-grid stats-4 mb-4">
    <div class="portal-stat">
        <span class="value metric-accent-partner">${summary.totalPerformances}</span>
        <span class="label">총 공연 수</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.reviewCount}</span>
        <span class="label">심사 중</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.confirmedReservations}</span>
        <span class="label">확정 예매</span>
    </div>
    <div class="portal-stat">
        <span class="value">${summary.grossSales}</span>
        <span class="label">총 매출</span>
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
                <a class="btn btn-primary btn-sm" href="/partner/promoter/performances">공연 관리</a>
                <a class="btn btn-outline-secondary btn-sm" href="/partner/promoter/settlement">정산</a>
            </div>
        </div>
        <div class="portal-note mb-4">
            승인 현황, 판매 실적, 정산 내역을 한눈에 확인하세요.
        </div>
        <div class="portal-table-wrap">
            <table class="table portal-table">
                <thead>
                <tr>
                    <th>공연명</th>
                    <th>상태</th>
                    <th>공연장</th>
                    <th>공연 기간</th>
                </tr>
                </thead>
                <tbody>
                <c:choose>
                    <c:when test="${empty recentPerformances}">
                        <tr><td colspan="4" class="text-center text-muted">등록된 공연이 없습니다.</td></tr>
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
                                <td>${performance.startDate} ~ ${performance.endDate}</td>
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
                <h3>판매 요약</h3>
                <p>현재 운영 중인 공연의 핵심 실적</p>
            </div>
            <a class="btn btn-outline-secondary btn-sm" href="/partner/promoter/sales-report">상세 보기</a>
        </div>
        <div class="portal-list">
            <c:choose>
                <c:when test="${empty salesRows}">
                    <div class="portal-empty">확정 예매가 발생하면 실적이 표시됩니다.</div>
                </c:when>
                <c:otherwise>
                    <c:forEach var="row" items="${salesRows}">
                        <div class="portal-list-item">
                            <strong>${row.performance_title}</strong>
                            <div class="portal-meta">
                                확정 ${row.confirmed_reservations}건 | 매출 ${row.gross_sales}원 | 정산 ${row.settlement_amount}원
                            </div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>
    </section>
</div>
