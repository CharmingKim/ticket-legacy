<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="uri" value="${pageContext.request.requestURI}" />

<div class="sidebar-header">
    <div class="sidebar-logo">
        <div class="sidebar-logo-icon">🎫</div>
        <span class="sidebar-logo-text">TL 파트너</span>
    </div>
    <p class="sidebar-tagline">파트너 포털</p>
    <div class="sidebar-role-chip">
        <i class="bi bi-shield-check"></i>
        <c:choose>
            <c:when test="${loginRole == 'PROMOTER'}">기획사</c:when>
            <c:when test="${loginRole == 'VENUE_MANAGER'}">공연장 담당자</c:when>
            <c:otherwise>${loginRole}</c:otherwise>
        </c:choose>
    </div>
</div>

<c:if test="${loginRole == 'PROMOTER'}">
    <div class="sidebar-nav-section">
        <p class="sidebar-nav-label">기획사</p>
        <nav class="sidebar-nav">
            <a class="sidebar-link ${uri.contains('/partner/promoter/dashboard') ? 'active' : ''}"
               href="/partner/promoter/dashboard">
                <i class="bi bi-speedometer2"></i>대시보드
            </a>
            <a class="sidebar-link ${uri.contains('/partner/promoter/performance') ? 'active' : ''}"
               href="/partner/promoter/performances">
                <i class="bi bi-music-note-list"></i>공연 관리
            </a>
            <a class="sidebar-link ${uri.contains('/partner/promoter/sales-report') ? 'active' : ''}"
               href="/partner/promoter/sales-report">
                <i class="bi bi-graph-up-arrow"></i>판매 현황
            </a>
            <a class="sidebar-link ${uri.contains('/partner/promoter/settlement') ? 'active' : ''}"
               href="/partner/promoter/settlement">
                <i class="bi bi-cash-stack"></i>정산
            </a>
            <a class="sidebar-link ${uri.contains('/partner/promoter/notices') ? 'active' : ''}"
               href="/partner/promoter/notices">
                <i class="bi bi-megaphone"></i>공지사항
            </a>
        </nav>
    </div>
</c:if>

<c:if test="${loginRole == 'VENUE_MANAGER'}">
    <div class="sidebar-nav-section">
        <p class="sidebar-nav-label">공연장 담당자</p>
        <nav class="sidebar-nav">
            <a class="sidebar-link ${uri.contains('/partner/venue/dashboard') ? 'active' : ''}"
               href="/partner/venue/dashboard">
                <i class="bi bi-speedometer2"></i>대시보드
            </a>
            <a class="sidebar-link ${uri.contains('/partner/venue/venue-info') ? 'active' : ''}"
               href="/partner/venue/venue-info">
                <i class="bi bi-building"></i>공연장 설정
            </a>
            <a class="sidebar-link ${uri.contains('/partner/venue/schedule-calendar') ? 'active' : ''}"
               href="/partner/venue/schedule-calendar">
                <i class="bi bi-calendar3"></i>공연 일정
            </a>
            <a class="sidebar-link ${uri.contains('/partner/venue/entrance') ? 'active' : ''}"
               href="/partner/venue/entrance">
                <i class="bi bi-door-open"></i>입장 관리
            </a>
        </nav>
    </div>
</c:if>

<div class="sidebar-footer">
    <div class="sidebar-user">
        <div class="sidebar-user-avatar">
            ${empty loginEmail ? '?' : loginEmail.substring(0,1).toUpperCase()}
        </div>
        <div class="sidebar-user-info">
            <div class="sidebar-user-email">${loginEmail}</div>
        </div>
    </div>
</div>
