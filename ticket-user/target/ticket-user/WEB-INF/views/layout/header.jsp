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
                            공연
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="${pageContext.request.contextPath}/member/wishlist">
                            찜 목록
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="${pageContext.request.contextPath}/notice/list">
                            공지사항
                        </a>
                    </li>
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" id="supportDropdown" role="button" data-bs-toggle="dropdown">
                            고객센터
                        </a>
                        <ul class="dropdown-menu border-0 shadow-sm">
                            <li><a class="dropdown-item" href="${pageContext.request.contextPath}/support/faq">FAQ</a></li>
                            <li><a class="dropdown-item" href="${pageContext.request.contextPath}/inquiry/list">1:1 문의</a></li>
                        </ul>
                    </li>
                </ul>

                <!-- Integrated Search -->
                <div class="d-flex align-items-center position-relative me-3" style="max-width: 250px; flex-grow: 1;">
                    <div class="input-group input-group-sm tl-search-group w-100">
                        <span class="input-group-text border-0 bg-light" style="border-radius: 20px 0 0 20px;"><i class="bi bi-search"></i></span>
                        <input type="text" id="globalSearchInput" class="form-control border-0 bg-light px-2" 
                               placeholder="공연명 검색" autocomplete="off" style="border-radius: 0 20px 20px 0;">
                    </div>
                    <!-- Suggestion Box -->
                    <div id="searchSuggestionBox" class="position-absolute top-100 start-0 w-100 mt-1 shadow-lg bg-white rounded-3 overflow-hidden d-none" 
                         style="z-index: 1100; border: 1px solid var(--gray-200);">
                        <div id="suggestionList" class="list-group list-group-flush">
                            <!-- JS will inject items here -->
                        </div>
                    </div>
                </div>

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

<script>
$(function() {
    const ctx = '${pageContext.request.contextPath}';
    const $searchInput = $('#globalSearchInput');
    const $suggestBox = $('#searchSuggestionBox');
    const $suggestList = $('#suggestionList');
    let suggestTimer = null;

    $searchInput.on('input', function() {
        const q = $(this).val().trim();
        clearTimeout(suggestTimer);

        if (q.length < 2) {
            $suggestBox.addClass('d-none');
            return;
        }

        suggestTimer = setTimeout(() => {
            $.get(ctx + '/api/search/suggest?q=' + encodeURIComponent(q))
            .done(function(res) {
                if (res.success && res.data.length > 0) {
                    $suggestList.empty();
                    res.data.forEach(title => {
                        $suggestList.append(`<a href="\${ctx}/performance/list?q=\${encodeURIComponent(title)}" class="list-group-item list-group-item-action py-2 small border-0">\${title}</a>`);
                    });
                    $suggestBox.removeClass('d-none');
                } else {
                    $suggestBox.addClass('d-none');
                }
            });
        }, 200);
    });

    $(document).on('click', function(e) {
        if (!$(e.target).closest('.tl-search-group, #searchSuggestionBox').length) {
            $suggestBox.addClass('d-none');
        }
    });

    $searchInput.on('keypress', function(e) {
        if (e.which === 13) {
            const q = $(this).val().trim();
            if (q) location.href = ctx + '/performance/list?q=' + encodeURIComponent(q);
        }
    });
});
</script>
