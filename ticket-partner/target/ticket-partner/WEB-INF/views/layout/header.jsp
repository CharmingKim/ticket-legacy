<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
  <div class="container">
    <a class="navbar-brand fw-bold" href="/">TicketLegacy</a>
    <button class="navbar-toggler" data-bs-toggle="collapse" data-bs-target="#nav"><span class="navbar-toggler-icon"></span></button>
    <div class="collapse navbar-collapse" id="nav">
      <ul class="navbar-nav me-auto">
        <li class="nav-item"><a class="nav-link" href="/performance/list">Performances</a></li>
        <c:if test="${loginRole == 'USER' and not empty loginMemberId}">
          <li class="nav-item"><a class="nav-link" href="/reservation/history"><i class="bi bi-ticket me-1"></i>예매내역</a></li>
          <li class="nav-item"><a class="nav-link" href="/member/mypage"><i class="bi bi-person-circle me-1"></i>마이페이지</a></li>
        </c:if>
        <c:if test="${loginRole == 'SUPER_ADMIN'}">
          <li class="nav-item"><a class="nav-link text-warning fw-bold" href="/backoffice/super/dashboard">
            <i class="bi bi-shield-fill-check"></i> Super Admin</a></li>
        </c:if>
        <c:if test="${loginRole == 'STAFF'}">
          <li class="nav-item"><a class="nav-link text-warning fw-bold" href="/backoffice/staff/dashboard">
            <i class="bi bi-briefcase-fill"></i> Staff Desk</a></li>
        </c:if>
        <c:if test="${loginRole == 'ADMIN'}">
          <li class="nav-item"><a class="nav-link text-warning" href="/admin/dashboard">Admin</a></li>
        </c:if>
        <c:if test="${loginRole == 'PROMOTER'}">
          <li class="nav-item"><a class="nav-link text-info fw-bold" href="/partner/promoter/dashboard">
            <i class="bi bi-building"></i> Promoter Portal</a></li>
        </c:if>
        <c:if test="${loginRole == 'VENUE_MANAGER'}">
          <li class="nav-item"><a class="nav-link text-success fw-bold" href="/partner/venue/dashboard">
            <i class="bi bi-geo-alt-fill"></i> Venue Portal</a></li>
        </c:if>
      </ul>
      <ul class="navbar-nav align-items-center">
        <c:choose>
          <c:when test="${not empty loginMemberId}">
            <li class="nav-item me-2">
              <c:choose>
                <c:when test="${loginRole == 'SUPER_ADMIN'}"><span class="badge bg-warning text-dark">SUPER_ADMIN</span></c:when>
                <c:when test="${loginRole == 'STAFF'}"><span class="badge bg-warning text-dark">STAFF</span></c:when>
                <c:when test="${loginRole == 'PROMOTER'}"><span class="badge bg-info text-dark">PROMOTER</span></c:when>
                <c:when test="${loginRole == 'VENUE_MANAGER'}"><span class="badge bg-success">VENUE_MANAGER</span></c:when>
                <c:when test="${loginRole == 'ADMIN'}"><span class="badge bg-secondary">ADMIN</span></c:when>
              </c:choose>
            </li>
            <li class="nav-item"><span class="nav-link text-white-50 small">${loginEmail}</span></li>
            <li class="nav-item"><a class="nav-link" href="#" id="btnLogout">Logout</a></li>
          </c:when>
          <c:otherwise>
            <li class="nav-item"><a class="nav-link" href="/member/login">Login</a></li>
            <li class="nav-item"><a class="nav-link" href="/member/join">Join</a></li>
          </c:otherwise>
        </c:choose>
      </ul>
    </div>
  </div>
</nav>
