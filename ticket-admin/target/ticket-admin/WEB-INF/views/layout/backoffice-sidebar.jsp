<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="uri" value="${pageContext.request.requestURI}" />
<div class="sidebar-brand">
    <span class="sidebar-badge">HQ</span>
    <h2>백오피스</h2>
    <p>운영 지원 시스템</p>
</div>

<c:if test="${loginRole == 'SUPER_ADMIN'}">
    <nav class="sidebar-nav">
        <a class="sidebar-link ${uri.contains('/backoffice/super/dashboard') ? 'active' : ''}" href="/backoffice/super/dashboard">
            <i class="bi bi-speedometer2 me-1"></i>대시보드
        </a>
        <a class="sidebar-link ${uri.contains('/backoffice/super/member-list') ? 'active' : ''}" href="/backoffice/super/member-list">
            <i class="bi bi-people me-1"></i>회원 관리
        </a>
        <a class="sidebar-link ${uri.contains('/backoffice/super/settlement') ? 'active' : ''}" href="/backoffice/super/settlement">
            <i class="bi bi-cash-stack me-1"></i>정산 관리
        </a>
        <a class="sidebar-link ${uri.contains('/backoffice/super/coupons') ? 'active' : ''}" href="/backoffice/super/coupons">
            <i class="bi bi-ticket-perforated me-1"></i>쿠폰 관리
        </a>
        <a class="sidebar-link ${uri.contains('/backoffice/super/notices') ? 'active' : ''}" href="/backoffice/super/notices">
            <i class="bi bi-megaphone me-1"></i>공지 관리
        </a>
        <a class="sidebar-link ${uri.contains('/backoffice/super/statistics') ? 'active' : ''}" href="/backoffice/super/statistics">
            <i class="bi bi-bar-chart-line me-1"></i>통계
        </a>
    </nav>
</c:if>

<c:if test="${loginRole == 'STAFF'}">
    <nav class="sidebar-nav">
        <a class="sidebar-link ${uri.contains('/backoffice/staff/dashboard') ? 'active' : ''}" href="/backoffice/staff/dashboard">
            <i class="bi bi-layout-text-window me-1"></i>스태프 대시보드
        </a>
        <a class="sidebar-link ${uri.contains('/backoffice/staff/reservation-search') ? 'active' : ''}" href="/backoffice/staff/reservation-search">
            <i class="bi bi-search me-1"></i>예약 검색
        </a>
        <a class="sidebar-link ${uri.contains('/backoffice/staff/member-search') ? 'active' : ''}" href="/backoffice/staff/member-search">
            <i class="bi bi-person-search me-1"></i>회원 검색
        </a>
    </nav>
</c:if>

<div class="sidebar-footer">
    <span class="text-white-50 small">${loginName}</span>
    <button id="btnLogout" class="btn btn-outline-light btn-sm w-100 mt-1">로그아웃</button>
</div>
