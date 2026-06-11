<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<div class="container py-5">
    <div class="d-flex justify-content-between align-items-end mb-4">
        <div>
            <h3 class="fw-800" style="letter-spacing:-.5px">찜한 공연</h3>
            <p class="text-muted mb-0">관심 있는 공연을 모아보세요.</p>
        </div>
    </div>

    <c:choose>
        <c:when test="${not empty wishlist}">
            <div class="row row-cols-2 row-cols-md-3 row-cols-lg-4 g-4">
                <c:forEach var="w" items="${wishlist}">
                    <div class="col" id="wish-item-${w.performanceId}">
                        <div class="card h-100 border-0 shadow-sm tl-perf-card">
                            <div class="position-relative">
                                <a href="${pageContext.request.contextPath}/performance/detail/${w.performanceId}">
                                    <c:choose>
                                        <c:when test="${not empty w.posterUrl}">
                                            <img src="${w.posterUrl}" class="card-img-top tl-perf-img" alt="${w.performanceTitle}">
                                        </c:when>
                                        <c:otherwise>
                                            <div class="tl-perf-img bg-light d-flex align-items-center justify-content-center text-muted">
                                                <i class="bi bi-image" style="font-size:2rem"></i>
                                            </div>
                                        </c:otherwise>
                                    </c:choose>
                                </a>
                                <!-- 하트 버튼 -->
                                <button class="btn-wish position-absolute top-0 end-0 m-2 border-0 bg-transparent" 
                                        data-pid="${w.performanceId}" style="z-index:10;">
                                    <i class="bi bi-heart-fill text-danger" style="font-size: 1.5rem; text-shadow: 0 0 5px rgba(0,0,0,0.5);"></i>
                                </button>
                            </div>
                            <div class="card-body p-3">
                                <a href="${pageContext.request.contextPath}/performance/detail/${w.performanceId}" class="text-decoration-none text-dark">
                                    <h6 class="fw-700 tl-text-truncate mb-1">${w.performanceTitle}</h6>
                                </a>
                                <p class="text-muted mb-0" style="font-size:.85rem">${w.venueName}</p>
                                <p class="text-muted mb-0" style="font-size:.8rem">
                                    ${tl:fmt(w.startDate, "yyyy.MM.dd")} ~ ${tl:fmt(w.endDate, "yyyy.MM.dd")}
                                </p>
                            </div>
                        </div>
                    </div>
                </c:forEach>
            </div>
        </c:when>
        <c:otherwise>
            <div class="text-center py-5">
                <i class="bi bi-heart" style="font-size:3.5rem;color:var(--gray-300)"></i>
                <p class="mt-3 text-muted">찜한 공연이 없습니다.</p>
                <a href="${pageContext.request.contextPath}/performance/list" class="tl-btn-primary mt-2">
                    <i class="bi bi-search me-2"></i>공연 둘러보기
                </a>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<script>
$(function() {
    $('.btn-wish').on('click', function(e) {
        e.preventDefault();
        const pid = $(this).data('pid');
        const $btn = $(this);
        
        api.post('${pageContext.request.contextPath}/api/wishlist/' + pid, {})
        .done(function(res) {
            if (res.success) {
                if (!res.data) {
                    // Removed
                    toast.success("찜 목록에서 삭제되었습니다.");
                    $('#wish-item-' + pid).fadeOut(300, function() {
                        $(this).remove();
                        // If empty, reload to show empty state
                        if ($('.tl-perf-card').length === 0) {
                            location.reload();
                        }
                    });
                }
            } else {
                toast.error(res.message);
            }
        });
    });
});
</script>
