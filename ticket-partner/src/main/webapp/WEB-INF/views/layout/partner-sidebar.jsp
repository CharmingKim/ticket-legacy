<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="uri" value="${pageContext.request.requestURI}" />

<div class="sidebar-header">
    <div class="sidebar-logo">
        <div class="sidebar-logo-icon">🎫</div>
        <span class="sidebar-logo-text">TL Partner</span>
    </div>
    <p class="sidebar-tagline">B2B Partner Portal</p>
    <div class="sidebar-role-chip">
        <i class="bi bi-shield-check"></i>
        ${loginRole}
    </div>
</div>

<c:if test="${loginRole == 'PROMOTER'}">
    <div class="sidebar-nav-section">
        <p class="sidebar-nav-label">Promoter</p>
        <nav class="sidebar-nav">
            <a class="sidebar-link ${uri.contains('/partner/promoter/dashboard') ? 'active' : ''}"
               href="/partner/promoter/dashboard">
                <i class="bi bi-speedometer2"></i>Overview
            </a>
            <a class="sidebar-link ${uri.contains('/partner/promoter/performance') ? 'active' : ''}"
               href="/partner/promoter/performances">
                <i class="bi bi-music-note-list"></i>Performances
            </a>
            <a class="sidebar-link ${uri.contains('/partner/promoter/sales-report') ? 'active' : ''}"
               href="/partner/promoter/sales-report">
                <i class="bi bi-graph-up-arrow"></i>Sales Report
            </a>
            <a class="sidebar-link ${uri.contains('/partner/promoter/settlement') ? 'active' : ''}"
               href="/partner/promoter/settlement">
                <i class="bi bi-cash-stack"></i>Settlement
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
        <p class="sidebar-nav-label">Venue Manager</p>
        <nav class="sidebar-nav">
            <a class="sidebar-link ${uri.contains('/partner/venue/dashboard') ? 'active' : ''}"
               href="/partner/venue/dashboard">
                <i class="bi bi-speedometer2"></i>Overview
            </a>
            <a class="sidebar-link ${uri.contains('/partner/venue/venue-info') ? 'active' : ''}"
               href="/partner/venue/venue-info">
                <i class="bi bi-building"></i>Venue Setup
            </a>
            <a class="sidebar-link ${uri.contains('/partner/venue/schedule-calendar') ? 'active' : ''}"
               href="/partner/venue/schedule-calendar">
                <i class="bi bi-calendar3"></i>Schedule Calendar
            </a>
            <a class="sidebar-link ${uri.contains('/partner/venue/entrance') ? 'active' : ''}"
               href="/partner/venue/entrance">
                <i class="bi bi-door-open"></i>Entrance Desk
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
