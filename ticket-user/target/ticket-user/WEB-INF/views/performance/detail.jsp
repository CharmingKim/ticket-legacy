<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<!-- Detail Hero -->
<section class="tl-detail-hero">
    <div class="container">
        <div class="row g-4 align-items-start">

            <!-- Poster -->
            <div class="col-md-3">
                <c:choose>
                    <c:when test="${not empty performance.posterUrl}">
                        <img src="${performance.posterUrl}" alt="${performance.title}" class="tl-detail-poster" />
                    </c:when>
                    <c:otherwise>
                        <div class="tl-detail-poster-placeholder">
                            <i class="bi bi-music-note-beamed"></i>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>

            <!-- Info -->
            <div class="col-md-9">
                <span class="tl-card-badge badge-${performance.genre != null ? performance.genre.toString().toLowerCase() : 'musical'} mb-3">
                    ${performance.genre}
                </span>
                <div class="d-flex align-items-center gap-3">
                    <h1 class="tl-detail-title mb-0">${performance.title}</h1>
                    <button id="btnWish" class="btn btn-outline-danger border-0 bg-transparent p-0" 
                            data-pid="${performance.performanceId}" style="transition: transform 0.2s;">
                        <i class="bi bi-heart" style="font-size: 2rem;"></i>
                    </button>
                </div>

                <c:if test="${not empty performance.venueName}">
                    <div class="tl-detail-meta">
                        <i class="bi bi-geo-alt-fill"></i>
                        <span>${performance.venueName}</span>
                    </div>
                </c:if>
                <c:if test="${not empty performance.startDate}">
                    <div class="tl-detail-meta">
                        <i class="bi bi-calendar3"></i>
                        <span>
                            ${tl:fmt(performance.startDate, "yyyy.MM.dd")}
                            <c:if test="${not empty performance.endDate}">
                                ~ ${tl:fmt(performance.endDate, "yyyy.MM.dd")}
                            </c:if>
                        </span>
                    </div>
                </c:if>
                <c:if test="${not empty performance.runningTime}">
                    <div class="tl-detail-meta">
                        <i class="bi bi-clock"></i>
                        <span>공연 시간: ${performance.runningTime}분</span>
                    </div>
                </c:if>
                <c:if test="${not empty performance.ageLimit}">
                    <div class="tl-detail-meta">
                        <i class="bi bi-person-check"></i>
                        <span>관람 연령: ${performance.ageLimit}</span>
                    </div>
                </c:if>
            </div>
        </div>
    </div>
</section>

<!-- Main Content -->
<section class="tl-section">
    <div class="container">
        <div class="row g-4">

            <!-- Left: Description + Grades -->
            <div class="col-lg-7">
                <!-- Description -->
                <c:if test="${not empty performance.description}">
                    <div class="tl-detail-section">
                        <h5>공연 소개</h5>
                        <p style="font-size:.92rem;line-height:1.8;color:var(--gray-700)">
                            ${performance.description}
                        </p>
                    </div>
                </c:if>

                <!-- Seat Grades -->
                <c:if test="${not empty seatGrades}">
                    <div class="tl-detail-section">
                        <h5>좌석 등급 / 가격</h5>
                        <div class="d-flex flex-column gap-2">
                            <c:forEach var="g" items="${seatGrades}">
                                <div class="d-flex align-items-center justify-content-between
                                            p-3" style="border:1px solid var(--gray-200);border-radius:var(--radius-sm)">
                                    <div class="d-flex align-items-center gap-3">
                                        <div style="width:12px;height:12px;border-radius:50%;
                                                    background:var(--primary);flex-shrink:0"></div>
                                        <span class="fw-600">${g.grade}</span>
                                        <c:if test="${not empty g.sectionName}">
                                            <span class="text-muted" style="font-size:.82rem">(${g.sectionName})</span>
                                        </c:if>
                                    </div>
                                    <span class="fw-700" style="color:var(--primary)">
                                        <fmt:formatNumber value="${g.price}" type="number" />원
                                    </span>
                                </div>
                            </c:forEach>
                        </div>
                    </div>
                </c:if>

                <!-- Reviews -->
                <div class="tl-detail-section mt-4">
                    <h5 class="d-flex align-items-center gap-2">
                        <span>관람평</span>
                        <span class="badge bg-primary rounded-pill" id="reviewCountBadge" style="font-size: 0.8rem;">0</span>
                    </h5>
                    
                    <!-- Review Form -->
                    <c:if test="${not empty loginMemberId}">
                        <div class="card shadow-sm border-0 mb-4" style="border-radius: var(--radius-md);">
                            <div class="card-body bg-light p-3" style="border-radius: var(--radius-md);">
                                <form id="reviewForm">
                                    <div class="d-flex align-items-center mb-2">
                                        <label class="me-2 fw-600" style="font-size: 0.9rem;">별점</label>
                                        <select id="reviewRating" class="form-select form-select-sm w-auto d-inline-block">
                                            <option value="5">★★★★★ (5점)</option>
                                            <option value="4">★★★★☆ (4점)</option>
                                            <option value="3">★★★☆☆ (3점)</option>
                                            <option value="2">★★☆☆☆ (2점)</option>
                                            <option value="1">★☆☆☆☆ (1점)</option>
                                        </select>
                                    </div>
                                    <div class="input-group">
                                        <input type="text" id="reviewContent" class="form-control" placeholder="공연은 어떠셨나요? 실관람평을 남겨주세요." required />
                                        <button class="btn btn-primary" type="submit" style="background-color: var(--primary); border-color: var(--primary);">등록</button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </c:if>
                    <c:if test="${empty loginMemberId}">
                        <div class="alert alert-light text-center border p-3 mb-4" style="border-radius: var(--radius-md);">
                            관람평을 작성하려면 <a href="${pageContext.request.contextPath}/member/login" class="fw-bold text-primary">로그인</a>이 필요합니다.
                        </div>
                    </c:if>

                    <!-- Review List -->
                    <div id="reviewList" class="d-flex flex-column gap-3">
                        <!-- Ajax populated -->
                    </div>
                    
                    <!-- Review Pagination -->
                    <div id="reviewPagination" class="mt-4 text-center"></div>
                </div>
            </div>

            <!-- Right: Schedule Selection -->
            <div class="col-lg-5">
                <div class="tl-detail-section" style="position:sticky;top:88px">
                    <h5>일정 선택</h5>

                    <c:choose>
                        <c:when test="${not empty schedules}">
                            <div id="scheduleList">
                                <c:forEach var="s" items="${schedules}">
                                    <div class="tl-schedule-item" data-schedule-id="${s.scheduleId}" data-date="${s.startDatetime}">
                                        <div>
                                            <div class="tl-schedule-date">
                                                ${tl:fmt(s.startDatetime, "yyyy.MM.dd (E)")}
                                            </div>
                                            <div class="tl-schedule-time">
                                                ${tl:fmt(s.startDatetime, "HH:mm")}
                                            </div>
                                        </div>
                                        <c:choose>
                                            <c:when test="${performance.status == 'UPCOMING'}">
                                                <span class="tl-schedule-avail avail-soon">오픈 예정</span>
                                            </c:when>
                                            <c:when test="${performance.status == 'ENDED' || s.status == 'ENDED'}">
                                                <span class="tl-schedule-avail avail-end">공연 종료</span>
                                            </c:when>
                                            <c:when test="${s.availableSeats > 20}">
                                                <span class="tl-schedule-avail avail-ok">여유 있음</span>
                                            </c:when>
                                            <c:when test="${s.availableSeats > 0}">
                                                <span class="tl-schedule-avail avail-few">잔여 ${s.availableSeats}석</span>
                                            </c:when>
                                            <c:otherwise>
                                                <span class="tl-schedule-avail avail-none">매진</span>
                                                <div class="mt-1"><button class="btn btn-link btn-sm p-0 text-decoration-none btn-waitlist-trigger" 
                                                        style="font-size:.75rem" data-sid="${s.scheduleId}">대기 신청</button></div>
                                            </c:otherwise>
                                        </c:choose>
                                    </div>
                                </c:forEach>
                            </div>
                            <button id="bookBtn" class="tl-auth-btn mt-4" disabled>
                                일정을 선택해주세요
                            </button>
                        </c:when>
                        <c:otherwise>
                            <p class="text-muted text-center py-3">등록된 일정이 없습니다.</p>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>
    </div>
</section>

<script>
$(function() {
    let selectedScheduleId = null;

    $('.tl-schedule-item').on('click', function() {
        const $this = $(this);
        if ($this.find('.avail-none').length) { toast.warning('매진된 일정입니다.'); return; }
        if ($this.find('.avail-soon').length) { toast.warning('아직 예매 오픈 전입니다.'); return; }
        if ($this.find('.avail-end').length)  { toast.warning('종료된 공연입니다.'); return; }

        $('.tl-schedule-item').removeClass('selected');
        $this.addClass('selected');
        selectedScheduleId = $this.data('schedule-id');

        const dateText = $this.find('.tl-schedule-date').text();
        const timeText = $this.find('.tl-schedule-time').text();
        $('#bookBtn')
            .prop('disabled', false)
            .text(dateText + ' ' + timeText + ' — 예매하기');
    });

    $('#bookBtn').on('click', function() {
        if (!selectedScheduleId) return;
        location.href = '${pageContext.request.contextPath}/seat/select/' + selectedScheduleId;
    });

    $(document).on('click', '.btn-waitlist-trigger', function(e) {
        e.stopPropagation();
        const sid = $(this).data('sid');
        if (!sid) return;

        if (!confirm('취소표 발생 시 알림을 받으시겠습니까?\n예매 대기 신청을 진행합니다.')) return;

        api.post('${pageContext.request.contextPath}/api/waitlist/' + sid, {})
        .done(function(res) {
            if (res.success) {
                toast.success(res.message);
            } else {
                toast.error(res.message);
            }
        });
    });

    // --- Reviews Logic ---
    const performanceId = '${performance.performanceId}';
    let currentReviewPage = 1;

    function loadReviews(page) {
        currentReviewPage = page;
        api.get(ctx + '/api/reviews/' + performanceId + '?page=' + page)
            .done(function(res) {
                if (res.success) {
                    const data = res.data;
                    $('#reviewCountBadge').text(data.total);
                    
                    const $list = $('#reviewList');
                    $list.empty();
                    
                    if (data.list.length === 0) {
                        $list.append('<div class="text-center text-muted py-4"><i class="bi bi-chat-square-text" style="font-size:2rem;color:var(--gray-300);"></i><p class="mt-2">아직 작성된 관람평이 없습니다.</p></div>');
                    } else {
                        data.list.forEach(function(r) {
                            const stars = '★'.repeat(r.rating) + '☆'.repeat(5 - r.rating);
                            const html = `
                                <div class="card border-0 shadow-sm" style="border-radius: var(--radius-sm);">
                                    <div class="card-body p-3">
                                        <div class="d-flex justify-content-between mb-2">
                                            <div>
                                                <span class="fw-bold me-2">\${r.memberName}</span>
                                                <span class="text-warning" style="font-size: 0.9rem;">\${stars}</span>
                                            </div>
                                            <span class="text-muted" style="font-size: 0.8rem;">\${r.createdAt.substring(0, 10)}</span>
                                        </div>
                                        <p class="mb-0" style="font-size: 0.95rem; color: var(--gray-800);">\${r.content}</p>
                                    </div>
                                </div>
                            `;
                            $list.append(html);
                        });
                    }

                    // Pagination
                    const $pag = $('#reviewPagination');
                    $pag.empty();
                    if (data.totalPages > 1) {
                        let pagHtml = '<div class="tl-pagination justify-content-center mt-3">';
                        for (let i = 1; i <= data.totalPages; i++) {
                            pagHtml += `<a href="javascript:void(0)" class="tl-page-btn \${i === page ? 'active' : ''}" onclick="loadReviews(\${i})">\${i}</a>`;
                        }
                        pagHtml += '</div>';
                        $pag.append(pagHtml);
                    }
                }
            });
    }

    $('#reviewForm').on('submit', function(e) {
        e.preventDefault();
        const rating = $('#reviewRating').val();
        const content = $('#reviewContent').val().trim();
        if (!content) return;

        api.post(ctx + '/api/reviews/' + performanceId, {
            rating: parseInt(rating),
            content: content
        })
        .done(function(res) {
            if (res.success) {
                toast.success(res.message || '등록되었습니다.');
                $('#reviewContent').val('');
                loadReviews(1);
            } else {
                toast.error(res.message);
            }
        })
        .fail(function(xhr) {
            toast.error(xhr.responseJSON?.message || '오류가 발생했습니다.');
        });
    });

    // ──────────────────────────────────────────
    // 찜하기 (Wishlist) 연동
    // ──────────────────────────────────────────
    const $btnWish = $('#btnWish');
    const pid = $btnWish.data('pid');
    const ctx = '${pageContext.request.contextPath}';

    if (pid) {
        // 초기 찜 여부 확인
        api.get(ctx + '/api/wishlist/check/' + pid)
        .done(function(res) {
            if (res.success && res.data) {
                $btnWish.find('i').removeClass('bi-heart').addClass('bi-heart-fill');
            }
        });

        $btnWish.on('click', function() {
            $btnWish.css('transform', 'scale(1.2)');
            setTimeout(() => $btnWish.css('transform', 'scale(1)'), 200);

            api.post(ctx + '/api/wishlist/' + pid, {})
            .done(function(res) {
                if (res.success) {
                    if (res.data) {
                        $btnWish.find('i').removeClass('bi-heart').addClass('bi-heart-fill');
                        toast.success('찜 목록에 추가되었습니다.');
                    } else {
                        $btnWish.find('i').removeClass('bi-heart-fill').addClass('bi-heart');
                        toast.success('찜 목록에서 삭제되었습니다.');
                    }
                } else {
                    toast.error(res.message);
                }
            });
        });
    }

    // Initial Load
    loadReviews(1);
});
</script>
