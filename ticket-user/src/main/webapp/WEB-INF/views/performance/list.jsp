<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<!-- Hero -->
<section class="tl-hero">
    <div class="container">
        <h1 class="tl-hero-title">지금 뜨는 공연</h1>
        <p class="tl-hero-sub">콘서트, 뮤지컬, 연극, 클래식 — 모든 공연을 한 곳에서</p>
    </div>
</section>

<!-- List -->
<section class="tl-section">
    <div class="container">

        <!-- Filter -->
        <div class="tl-filter-bar d-flex align-items-center flex-wrap gap-2">
            <span class="fw-600 me-2" style="font-size:.9rem;color:var(--gray-600)">장르</span>
            <button class="tl-filter-btn active" data-genre="">전체</button>
            <button class="tl-filter-btn" data-genre="CONCERT">콘서트</button>
            <button class="tl-filter-btn" data-genre="MUSICAL">뮤지컬</button>
            <button class="tl-filter-btn" data-genre="PLAY">연극</button>
            <button class="tl-filter-btn" data-genre="CLASSIC">클래식</button>

            <div class="ms-auto">
                <input type="text" id="searchInput" class="tl-form-control" style="width:220px"
                       placeholder="공연명 검색..." value="${param.keyword}">
            </div>
        </div>

        <!-- Grid -->
        <div class="row g-4" id="perfGrid">
            <c:forEach var="p" items="${performances}">
                <div class="col-6 col-md-4 col-lg-3">
                    <a href="${pageContext.request.contextPath}/performance/detail/${p.performanceId}" class="tl-card">
                        <c:choose>
                            <c:when test="${not empty p.posterUrl}">
                                <img src="${p.posterUrl}" alt="${p.title}" class="tl-card-img" loading="lazy" />
                            </c:when>
                            <c:otherwise>
                                <div class="tl-card-img-placeholder">
                                    <i class="bi bi-music-note-beamed"></i>
                                </div>
                            </c:otherwise>
                        </c:choose>
                        <div class="tl-card-body">
                            <span class="tl-card-badge badge-${p.genre != null ? p.genre.toString().toLowerCase() : 'musical'}">
                                ${p.genre}
                            </span>
                            <div class="tl-card-title">${p.title}</div>
                            <div class="tl-card-meta">
                                <i class="bi bi-geo-alt"></i>
                                <span>${not empty p.venueName ? p.venueName : '미정'}</span>
                            </div>
                            <c:if test="${not empty p.startDate}">
                                <div class="tl-card-meta">
                                    <i class="bi bi-calendar3"></i>
                                    <span>${tl:fmt(p.startDate, "yyyy.MM.dd")}</span>
                                </div>
                            </c:if>
                            <div class="tl-card-price">
                                <c:choose>
                                    <c:when test="${p.minPrice > 0}">
                                        <fmt:formatNumber value="${p.minPrice}" type="number" />원~
                                    </c:when>
                                    <c:otherwise>가격 미정</c:otherwise>
                                </c:choose>
                            </div>
                        </div>
                    </a>
                </div>
            </c:forEach>

            <c:if test="${empty performances}">
                <div class="col-12 text-center py-5">
                    <i class="bi bi-search" style="font-size:3rem;color:var(--gray-400)"></i>
                    <p class="mt-3 text-muted">검색 결과가 없습니다.</p>
                </div>
            </c:if>
        </div>

        <!-- Pagination -->
        <c:if test="${totalPages > 1}">
            <div class="tl-pagination">
                <c:if test="${currentPage > 1}">
                    <a href="?page=${currentPage-1}&genre=${param.genre}&keyword=${param.keyword}"
                       class="tl-page-btn"><i class="bi bi-chevron-left"></i></a>
                </c:if>
                <c:forEach begin="1" end="${totalPages}" var="i">
                    <a href="?page=${i}&genre=${param.genre}&keyword=${param.keyword}"
                       class="tl-page-btn ${i == currentPage ? 'active' : ''}">${i}</a>
                </c:forEach>
                <c:if test="${currentPage < totalPages}">
                    <a href="?page=${currentPage+1}&genre=${param.genre}&keyword=${param.keyword}"
                       class="tl-page-btn"><i class="bi bi-chevron-right"></i></a>
                </c:if>
            </div>
        </c:if>

    </div>
</section>

<script>
$(function() {
    // Genre filter
    $('.tl-filter-btn').on('click', function() {
        const genre = $(this).data('genre');
        const keyword = $('#searchInput').val();
        location.href = '?page=1&genre=' + genre + '&keyword=' + encodeURIComponent(keyword);
    });

    // Search on Enter
    $('#searchInput').on('keydown', function(e) {
        if (e.key === 'Enter') {
            location.href = '?page=1&genre=${param.genre}&keyword=' + encodeURIComponent($(this).val());
        }
    });

    // Active genre highlight
    const currentGenre = '${param.genre}';
    if (currentGenre) {
        $('.tl-filter-btn').removeClass('active');
        $('[data-genre="' + currentGenre + '"]').addClass('active');
    }
});
</script>
