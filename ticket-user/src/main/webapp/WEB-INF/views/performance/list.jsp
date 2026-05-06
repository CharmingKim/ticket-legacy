<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<style>
.tl-highlight {
    font-style: normal;
    color: var(--primary);
    background-color: rgba(var(--primary-rgb), 0.1);
    font-weight: 700;
    padding: 0 2px;
    border-radius: 2px;
}
</style>

<!-- Hero -->
<section class="tl-hero" style="background: linear-gradient(135deg, var(--primary-dark), var(--primary)); position: relative; overflow: hidden;">
    <!-- Background Decor -->
    <div style="position: absolute; top: -50%; right: -10%; width: 500px; height: 500px; background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0) 70%); border-radius: 50%;"></div>
    
    <div class="container position-relative" style="z-index: 1;">
        <h1 class="tl-hero-title fw-800 mb-3" style="font-size: 3rem; letter-spacing: -1px; text-shadow: 0 4px 12px rgba(0,0,0,0.1);">지금 뜨는 공연</h1>
        <p class="tl-hero-sub opacity-75" style="font-size: 1.1rem;">콘서트, 뮤지컬, 연극, 클래식 — 모든 공연을 한 곳에서</p>
    </div>
</section>

<!-- Ranking (only main page) -->
<c:if test="${not empty topRanking}">
    <section class="tl-section bg-light" style="padding: 40px 0;">
        <div class="container">
            <h3 class="fw-800 mb-4 d-flex align-items-center">
                <i class="bi bi-trophy-fill text-warning me-2" style="font-size: 1.5rem;"></i>
                실시간 예매 랭킹
            </h3>
            <div class="row g-4 flex-nowrap overflow-auto" style="scrollbar-width: none;">
                <c:forEach var="rp" items="${topRanking}" varStatus="status">
                    <div class="col-10 col-sm-6 col-md-4 col-lg-3" style="min-width: 250px;">
                        <a href="${pageContext.request.contextPath}/performance/detail/${rp.performanceId}" class="tl-card position-relative shadow-sm" style="border: none; transition: transform 0.3s ease, box-shadow 0.3s ease;">
                            <!-- 랭킹 배지 -->
                            <div class="position-absolute top-0 start-0 m-3 d-flex align-items-center justify-content-center fw-800"
                                 style="width: 36px; height: 36px; background: rgba(0,0,0,0.8); color: #fff; border-radius: 8px; z-index: 2; font-size: 1.1rem; box-shadow: 0 4px 8px rgba(0,0,0,0.2);">
                                ${status.count}
                            </div>
                            
                            <c:choose>
                                <c:when test="${not empty rp.posterUrl}">
                                    <img src="${rp.posterUrl}" alt="${rp.title}" class="tl-card-img" loading="lazy" style="height: 320px; object-fit: cover;" />
                                </c:when>
                                <c:otherwise>
                                    <div class="tl-card-img-placeholder" style="height: 320px;">
                                        <i class="bi bi-music-note-beamed"></i>
                                    </div>
                                </c:otherwise>
                            </c:choose>
                            <div class="tl-card-body" style="background: #fff;">
                                <span class="tl-card-badge badge-${rp.genre != null ? rp.genre.toString().toLowerCase() : 'musical'} mb-2">
                                    ${rp.genre}
                                </span>
                                <div class="tl-card-title fw-700" style="font-size: 1.1rem;">${rp.title}</div>
                                <div class="tl-card-meta mt-1">
                                    <i class="bi bi-calendar3 text-primary"></i>
                                    <span>${tl:fmt(rp.startDate, "yyyy.MM.dd")} - ${tl:fmt(rp.endDate, "yyyy.MM.dd")}</span>
                                </div>
                            </div>
                        </a>
                    </div>
                </c:forEach>
            </div>
        </div>
    </section>
</c:if>

<!-- List -->
<section class="tl-section">
    <div class="container">

        <!-- Filter -->
        <form id="filterForm" action="${pageContext.request.contextPath}/performance/list" method="get" class="mb-4">
            <input type="hidden" name="genre" id="genreInput" value="${param.genre}">
            <div class="row g-3 align-items-end">
                <div class="col-12 d-flex align-items-center flex-wrap gap-2">
                    <span class="fw-600 me-2" style="font-size:.9rem;color:var(--gray-600)">장르</span>
                    <button type="button" class="tl-filter-btn active" data-genre="">전체</button>
                    <button type="button" class="tl-filter-btn" data-genre="CONCERT">콘서트</button>
                    <button type="button" class="tl-filter-btn" data-genre="MUSICAL">뮤지컬</button>
                    <button type="button" class="tl-filter-btn" data-genre="SPORTS">스포츠</button>
                    <button type="button" class="tl-filter-btn" data-genre="EXHIBITION">전시/행사</button>
                    <button type="button" class="tl-filter-btn" data-genre="CLASSIC_DANCE">클래식/무용</button>
                    <button type="button" class="tl-filter-btn" data-genre="KIDS_FAMILY">아동/가족</button>
                    <button type="button" class="tl-filter-btn" data-genre="PLAY">연극</button>
                    <button type="button" class="tl-filter-btn" data-genre="LEISURE_CAMPING">레저/캠핑</button>
                </div>

                <div class="col-12 col-md-3">
                    <label class="form-label mb-1" style="font-size:0.8rem">공연명 검색</label>
                    <input type="text" name="keyword" class="tl-form-control" placeholder="공연명 또는 장소..." value="${param.keyword}">
                </div>
                <div class="col-12 col-md-2">
                    <label class="form-label mb-1" style="font-size:0.8rem">시작일</label>
                    <input type="date" name="startDate" class="tl-form-control" value="${param.startDate}">
                </div>
                <div class="col-12 col-md-2">
                    <label class="form-label mb-1" style="font-size:0.8rem">종료일</label>
                    <input type="date" name="endDate" class="tl-form-control" value="${param.endDate}">
                </div>
                <div class="col-12 col-md-3">
                    <label class="form-label mb-1" style="font-size:0.8rem">가격대(최소~최대)</label>
                    <div class="d-flex align-items-center gap-1">
                        <input type="number" name="minPrice" class="tl-form-control text-end" placeholder="0" value="${param.minPrice}">
                        <span>~</span>
                        <input type="number" name="maxPrice" class="tl-form-control text-end" placeholder="무제한" value="${param.maxPrice}">
                    </div>
                </div>
                <div class="col-12 col-md-2 text-md-end text-center">
                    <button type="submit" class="tl-btn tl-btn-primary w-100">검색 적용</button>
                </div>
            </div>
            
            <!-- 정렬 및 추가 필터 -->
            <div class="d-flex justify-content-between align-items-center mt-3 pt-3 border-top">
                <div class="tl-sort-group d-flex gap-3">
                    <input type="hidden" name="sort" id="sortInput" value="${sort}">
                    <a href="javascript:void(0)" class="tl-sort-link ${sort == 'relevance' ? 'active' : ''}" data-sort="relevance">정확도순</a>
                    <a href="javascript:void(0)" class="tl-sort-link ${sort == 'date_asc' ? 'active' : ''}" data-sort="date_asc">일시순</a>
                    <a href="javascript:void(0)" class="tl-sort-link ${sort == 'price_asc' ? 'active' : ''}" data-sort="price_asc">저가순</a>
                    <a href="javascript:void(0)" class="tl-sort-link ${sort == 'price_desc' ? 'active' : ''}" data-sort="price_desc">고가순</a>
                </div>
                <div class="text-muted small">
                    총 <span class="fw-700 text-primary">${performances.size()}</span>건의 검색 결과
                </div>
            </div>
        </form>

        <div class="row">
            <!-- Left: Sidebar (인기/최근 검색어) -->
            <div class="col-lg-3 d-none d-lg-block">
                <div class="card border-0 shadow-sm mb-4">
                    <div class="card-body">
                        <h6 class="fw-800 mb-3"><i class="bi bi-fire text-danger me-2"></i>인기 검색어</h6>
                        <ul class="list-unstyled mb-0" id="trendingList">
                            <li class="py-1 text-muted small">로딩 중...</li>
                        </ul>
                    </div>
                </div>
                
                <div class="card border-0 shadow-sm">
                    <div class="card-body">
                        <h6 class="fw-800 mb-3"><i class="bi bi-clock-history text-primary me-2"></i>최근 검색어</h6>
                        <ul class="list-unstyled mb-0" id="recentList">
                            <li class="py-1 text-muted small">내역이 없습니다.</li>
                        </ul>
                    </div>
                </div>
            </div>

            <!-- Right: Content Grid -->
            <div class="col-lg-9">
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
                            <div class="tl-card-title">
                                <c:choose>
                                    <c:when test="${not empty p.displayTitle}">${p.displayTitle}</c:when>
                                    <c:otherwise>${p.title}</c:otherwise>
                                </c:choose>
                            </div>
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
                    <button type="button" class="btn btn-outline-primary btn-sm mt-2" onclick="location.href='${pageContext.request.contextPath}/performance/list'">전체 목록 보기</button>
                </div>
            </c:if>
        </div>
    </div> <!-- .col-lg-9 close -->
</div> <!-- .row close (sidebar + content) -->

        <!-- Pagination -->
        <c:if test="${totalPages > 1}">
            <div class="tl-pagination">
                <c:if test="${currentPage > 1}">
                    <a href="?page=${currentPage-1}&genre=${param.genre}&keyword=${param.keyword}&startDate=${param.startDate}&endDate=${param.endDate}&minPrice=${param.minPrice}&maxPrice=${param.maxPrice}"
                       class="tl-page-btn"><i class="bi bi-chevron-left"></i></a>
                </c:if>
                <c:forEach begin="1" end="${totalPages}" var="i">
                    <a href="?page=${i}&genre=${param.genre}&keyword=${param.keyword}&startDate=${param.startDate}&endDate=${param.endDate}&minPrice=${param.minPrice}&maxPrice=${param.maxPrice}"
                       class="tl-page-btn ${i == currentPage ? 'active' : ''}">${i}</a>
                </c:forEach>
                <c:if test="${currentPage < totalPages}">
                    <a href="?page=${currentPage+1}&genre=${param.genre}&keyword=${param.keyword}&startDate=${param.startDate}&endDate=${param.endDate}&minPrice=${param.minPrice}&maxPrice=${param.maxPrice}"
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
        $('#genreInput').val(genre);
        $('#filterForm').submit();
    });

    // Active genre highlight
    const currentGenre = '${param.genre}';
    if (currentGenre) {
        $('.tl-filter-btn').removeClass('active');
        $('[data-genre="' + currentGenre + '"]').addClass('active');
    }
    // Sort click
    $('.tl-sort-link').on('click', function() {
        $('#sortInput').val($(this).data('sort'));
        $('#filterForm').submit();
    });

    // Trending Keywords Load
    $.get('${pageContext.request.contextPath}/api/search/trending').done(function(res) {
        if (res.success && res.data.length > 0) {
            const $list = $('#trendingList').empty();
            res.data.forEach((kw, i) => {
                $list.append(`
                    <li class="py-1 d-flex align-items-center">
                        <span class="badge bg-light text-dark me-2" style="width:20px">\${i+1}</span>
                        <a href="?q=\${encodeURIComponent(kw)}" class="text-decoration-none text-dark small hover-primary">\${kw}</a>
                    </li>
                `);
            });
        }
    });

    // Recent Keywords (Local Storage)
    const currentQ = '${param.q}' || '${param.keyword}';
    if (currentQ) {
        let recent = JSON.parse(localStorage.getItem('recent_searches') || '[]');
        recent = recent.filter(k => k !== currentQ);
        recent.unshift(currentQ);
        localStorage.setItem('recent_searches', JSON.stringify(recent.slice(0, 5)));
    }

    const recent = JSON.parse(localStorage.getItem('recent_searches') || '[]');
    if (recent.length > 0) {
        const $list = $('#recentList').empty();
        recent.forEach(kw => {
            $list.append(`
                <li class="py-1">
                    <a href="?q=\${encodeURIComponent(kw)}" class="text-decoration-none text-muted small hover-primary"><i class="bi bi-search me-2"></i>\${kw}</a>
                </li>
            `);
        });
    }
});
</script>

<style>
.tl-sort-link { color: var(--gray-600); text-decoration: none; font-size: 0.9rem; font-weight: 500; }
.tl-sort-link.active { color: var(--primary); font-weight: 700; border-bottom: 2px solid var(--primary); }
.hover-primary:hover { color: var(--primary) !important; }
</style>
