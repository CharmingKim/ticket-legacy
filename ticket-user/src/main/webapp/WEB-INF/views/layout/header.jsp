<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<header class="tl-header">
    <nav class="navbar navbar-expand-lg">
        <div class="container">
            <!-- Logo -->
            <a class="navbar-brand tl-logo" href="${pageContext.request.contextPath}/">
                <span class="tl-logo-icon"><i class="bi bi-ticket-perforated-fill"></i></span>
                <span class="tl-logo-text">TicketLegacy</span>
            </a>

            <!-- Mobile toggle -->
            <button class="navbar-toggler" type="button"
                    data-bs-toggle="collapse" data-bs-target="#navbarMain"
                    aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>

            <div class="collapse navbar-collapse" id="navbarMain">
                <!-- Nav links -->
                <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                    <li class="nav-item">
                        <a class="nav-link" href="${pageContext.request.contextPath}/performance/list">
                            <i class="bi bi-grid-3x3-gap me-1"></i>공연 목록
                        </a>
                    </li>
                </ul>

                <!-- Right side -->
                <div class="d-flex align-items-center gap-2">
                    <c:choose>
                        <c:when test="${not empty sessionScope.loginMemberId or not empty loginMemberId}">
                            <a href="${pageContext.request.contextPath}/member/mypage"
                               class="btn tl-btn-ghost btn-sm">
                                <i class="bi bi-person-circle me-1"></i>마이페이지
                            </a>
                            <a href="${pageContext.request.contextPath}/reservation/history"
                               class="btn tl-btn-ghost btn-sm">
                                <i class="bi bi-ticket me-1"></i>예매 내역
                            </a>
                            <a href="${pageContext.request.contextPath}/member/logout"
                               class="btn tl-btn-outline btn-sm" id="logoutBtn">
                                로그아웃
                            </a>
                        </c:when>
                        <c:otherwise>
                            <a href="${pageContext.request.contextPath}/member/login"
                               class="btn tl-btn-ghost btn-sm">로그인</a>
                            <a href="${pageContext.request.contextPath}/member/join"
                               class="btn tl-btn-primary btn-sm">회원가입</a>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>
    </nav>
</header>
