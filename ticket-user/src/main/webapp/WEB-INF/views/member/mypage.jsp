<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<!-- Mypage Header -->
<section class="tl-mypage-header">
    <div class="container">
        <div class="d-flex align-items-center gap-4">
            <div class="tl-avatar">
                ${not empty member.name ? member.name.substring(0,1) : 'U'}
            </div>
            <div>
                <div class="tl-mypage-name">${member.name}</div>
                <div class="tl-mypage-email">${member.email}</div>
                <div class="mt-2">
                    <span class="tl-badge tl-badge-primary">${member.role}</span>
                </div>
            </div>
        </div>
    </div>
</section>

<section class="tl-section">
    <div class="container">
        <div class="row g-4">

            <!-- Left: Profile Info -->
            <div class="col-md-4">
                <div class="tl-info-card">
                    <h6><i class="bi bi-person me-2"></i>내 정보</h6>
                    <div class="tl-confirm-row">
                        <span class="label">이름</span>
                        <span class="value">${member.name}</span>
                    </div>
                    <div class="tl-confirm-row">
                        <span class="label">이메일</span>
                        <span class="value" style="font-size:.85rem">${member.email}</span>
                    </div>
                    <c:if test="${not empty member.phone}">
                        <div class="tl-confirm-row">
                            <span class="label">전화번호</span>
                            <span class="value">${member.phone}</span>
                        </div>
                    </c:if>
                    <div class="tl-confirm-row">
                        <span class="label">가입일</span>
                        <span class="value">
                            <c:if test="${not empty member.createdAt}">
                                ${tl:fmt(member.createdAt, "yyyy.MM.dd")}
                            </c:if>
                        </span>
                    </div>
                </div>

                <div class="d-flex gap-2">
                    <a href="${pageContext.request.contextPath}/reservation/history"
                       class="tl-btn-primary btn-sm w-100 justify-content-center" style="padding:10px">
                        <i class="bi bi-ticket me-2"></i>예매 내역
                    </a>
                </div>
            </div>

            <!-- Right: Coupons -->
            <div class="col-md-8">
                <div class="tl-info-card">
                    <h6><i class="bi bi-tag me-2"></i>보유 쿠폰</h6>
                    <c:choose>
                        <c:when test="${not empty coupons}">
                            <c:forEach var="c" items="${coupons}">
                                <div class="tl-coupon-item">
                                    <div class="tl-coupon-icon">
                                        <i class="bi bi-gift"></i>
                                    </div>
                                    <div>
                                        <div class="tl-coupon-name">${c.couponName}</div>
                                        <div class="tl-coupon-meta">
                                            <c:if test="${not empty c.expiryDate}">
                                                만료: ${tl:fmt(c.expiryDate, "yyyy.MM.dd")}
                                            </c:if>
                                        </div>
                                    </div>
                                    <div class="tl-coupon-discount">
                                        <fmt:formatNumber value="${c.discountAmount}" type="number" />원 할인
                                    </div>
                                </div>
                            </c:forEach>
                        </c:when>
                        <c:otherwise>
                            <div class="text-center py-4">
                                <i class="bi bi-tag" style="font-size:2rem;color:var(--gray-300)"></i>
                                <p class="text-muted mt-2" style="font-size:.88rem">보유한 쿠폰이 없습니다.</p>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </div>

                <!-- Recent reservations -->
                <div class="tl-info-card">
                    <h6><i class="bi bi-clock-history me-2"></i>최근 예매</h6>
                    <c:choose>
                        <c:when test="${not empty recentReservations}">
                            <c:forEach var="r" items="${recentReservations}" end="4">
                                <div class="d-flex align-items-center justify-content-between py-2"
                                     style="border-bottom:1px solid var(--gray-100)">
                                    <div>
                                        <div class="fw-600" style="font-size:.9rem">${r.performanceTitle}</div>
                                        <div class="text-muted" style="font-size:.8rem">
                                            <c:if test="${not empty r.scheduleDatetime}">
                                                ${tl:fmt(r.scheduleDatetime, "yyyy.MM.dd HH:mm")}
                                            </c:if>
                                        </div>
                                    </div>
                                    <c:choose>
                                        <c:when test="${r.status == 'CONFIRMED'}">
                                            <span class="tl-badge tl-badge-success">완료</span>
                                        </c:when>
                                        <c:when test="${r.status == 'CANCELLED'}">
                                            <span class="tl-badge tl-badge-danger">취소</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="tl-badge tl-badge-warning">${r.status}</span>
                                        </c:otherwise>
                                    </c:choose>
                                </div>
                            </c:forEach>
                            <div class="text-center mt-3">
                                <a href="${pageContext.request.contextPath}/reservation/history"
                                   class="tl-btn-ghost btn-sm" style="font-size:.83rem">
                                    전체 보기 <i class="bi bi-arrow-right ms-1"></i>
                                </a>
                            </div>
                        </c:when>
                        <c:otherwise>
                            <p class="text-muted text-center py-3" style="font-size:.88rem">
                                예매 내역이 없습니다.
                            </p>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>
    </div>
</section>
