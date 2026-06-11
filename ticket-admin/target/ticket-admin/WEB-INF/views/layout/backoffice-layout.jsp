<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="tiles" uri="http://tiles.apache.org/tags-tiles" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TicketLegacy Backoffice</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css" rel="stylesheet">
    <link href="<c:url value='/css/common.css'/>" rel="stylesheet">
    <link href="<c:url value='/css/portal.css'/>" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <script src="<c:url value='/js/common.js'/>"></script>
</head>
<body class="portal-shell backoffice-shell">
<div class="portal-app">
    <aside class="portal-sidebar">
        <tiles:insertAttribute name="sidebar" />
    </aside>
    <div class="portal-main">
        <header class="portal-topbar">
            <div>
                <p class="portal-kicker">백오피스</p>
                <h1 class="portal-title">TicketLegacy HQ</h1>
            </div>
            <div class="portal-actions">
                <span class="portal-chip">
                    <c:choose>
                        <c:when test="${loginRole == 'SUPER_ADMIN'}">최고관리자</c:when>
                        <c:when test="${loginRole == 'STAFF'}">스태프</c:when>
                        <c:otherwise>${loginRole}</c:otherwise>
                    </c:choose>
                </span>
                <span class="text-muted small">${loginEmail}</span>
                <a class="btn btn-outline-secondary btn-sm" href="http://localhost:8080/" target="_blank">공개 사이트</a>
                <a class="btn btn-dark btn-sm" href="#" id="btnLogout">로그아웃</a>
            </div>
        </header>
        <main class="portal-content">
            <tiles:insertAttribute name="content" />
        </main>
    </div>
</div>
</body>
</html>
