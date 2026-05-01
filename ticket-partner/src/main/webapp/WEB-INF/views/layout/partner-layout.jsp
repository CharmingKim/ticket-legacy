<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="tiles" uri="http://tiles.apache.org/tags-tiles" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TicketLegacy Partner</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css" rel="stylesheet">
    <link href="<c:url value='/css/portal.css'/>" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="<c:url value='/js/common.js'/>"></script>
</head>
<body class="portal-shell partner-shell">
<div class="portal-app">

    <!-- ── Sidebar ── -->
    <aside class="portal-sidebar">
        <tiles:insertAttribute name="sidebar" />
    </aside>

    <!-- ── Main ── -->
    <div class="portal-main">
        <header class="portal-topbar">
            <div class="topbar-left">
                <p class="portal-kicker">파트너 포털</p>
                <h1>TicketLegacy</h1>
            </div>
            <div class="topbar-right">
                <span class="badge bg-light text-dark border fw-semibold" style="font-size:11px;letter-spacing:.04em">
                    <c:choose>
                        <c:when test="${loginRole == 'PROMOTER'}">기획사</c:when>
                        <c:when test="${loginRole == 'VENUE_MANAGER'}">공연장 담당자</c:when>
                        <c:otherwise>${loginRole}</c:otherwise>
                    </c:choose>
                </span>
                <span class="text-secondary small d-none d-md-inline">${loginEmail}</span>
                <button class="btn btn-sm btn-outline-secondary" id="btnLogout">
                    <i class="bi bi-box-arrow-right me-1"></i>로그아웃
                </button>
            </div>
        </header>

        <main class="portal-content">
            <tiles:insertAttribute name="content" />
        </main>
    </div>
</div>

<script>
$(function() {
    $('#btnLogout').on('click', function() {
        $.post('/partner/api/logout').always(function() {
            document.cookie = 'PARTNER_TOKEN=; Max-Age=0; path=/';
            location.href = '/partner/login';
        });
    });
});
</script>
</body>
</html>
