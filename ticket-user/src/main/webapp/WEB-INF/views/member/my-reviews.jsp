<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<div class="container py-5">
    <div class="mb-4">
        <h3 class="fw-800">내가 작성한 관람평</h3>
        <p class="text-muted">직접 관람하고 남겨주신 소중한 리뷰들입니다.</p>
    </div>

    <c:choose>
        <c:when test="${not empty reviews}">
            <div class="d-flex flex-column gap-4">
                <c:forEach var="r" items="${reviews}">
                    <div class="card border-0 shadow-sm" style="border-radius: var(--radius-md);" id="review-card-${r.reviewId}">
                        <div class="card-body p-4">
                            <div class="d-flex justify-content-between align-items-start mb-3">
                                <div>
                                    <h5 class="fw-700 mb-1">${r.performanceTitle}</h5>
                                    <div class="tl-rating-stars text-warning">
                                        <c:forEach begin="1" end="${r.rating}">
                                            <i class="bi bi-star-fill"></i>
                                        </c:forEach>
                                        <c:forEach begin="${r.rating + 1}" end="5">
                                            <i class="bi bi-star"></i>
                                        </c:forEach>
                                        <span class="ms-2 text-dark fw-600">${r.rating}점</span>
                                    </div>
                                </div>
                                <div class="text-muted small">
                                    ${tl:fmt(r.createdAt, "yyyy.MM.dd HH:mm")}
                                </div>
                            </div>
                            <p class="card-text text-gray-700 mb-4" id="review-content-${r.reviewId}">${r.content}</p>
                            <div class="d-flex justify-content-end gap-2">
                                <button class="btn btn-outline-secondary btn-sm px-3 btn-edit" 
                                        data-id="${r.reviewId}" data-rating="${r.rating}" data-content="${r.content}">
                                    수정
                                </button>
                                <button class="btn btn-outline-danger btn-sm px-3 btn-delete" data-id="${r.reviewId}">
                                    삭제
                                </button>
                            </div>
                        </div>
                    </div>
                </c:forEach>
            </div>

            <!-- Pagination -->
            <c:if test="${totalPages > 1}">
                <nav class="mt-5">
                    <ul class="pagination justify-content-center">
                        <c:forEach var="i" begin="1" end="${totalPages}">
                            <li class="page-item ${currentPage == i ? 'active' : ''}">
                                <a class="page-link" href="?page=${i}">${i}</a>
                            </li>
                        </c:forEach>
                    </ul>
                </nav>
            </c:if>
        </c:when>
        <c:otherwise>
            <div class="text-center py-5">
                <i class="bi bi-chat-left-dots" style="font-size:3.5rem;color:var(--gray-300)"></i>
                <p class="mt-3 text-muted">작성한 관람평이 없습니다.</p>
                <a href="${pageContext.request.contextPath}/reservation/history" class="tl-btn-primary mt-2">
                    <i class="bi bi-ticket me-2"></i>예매 내역 확인
                </a>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<!-- Edit Modal -->
<div class="modal fade" id="editReviewModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-0 shadow">
            <div class="modal-header border-0 pb-0">
                <h5 class="fw-800">관람평 수정</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-4">
                <input type="hidden" id="editReviewId">
                <div class="mb-3">
                    <label class="form-label fw-600">별점</label>
                    <select id="editRating" class="form-select">
                        <option value="5">★★★★★ (5점)</option>
                        <option value="4">★★★★☆ (4점)</option>
                        <option value="3">★★★☆☆ (3점)</option>
                        <option value="2">★★☆☆☆ (2점)</option>
                        <option value="1">★☆☆☆☆ (1점)</option>
                    </select>
                </div>
                <div class="mb-0">
                    <label class="form-label fw-600">내용</label>
                    <textarea id="editContent" class="form-control" rows="5"></textarea>
                </div>
            </div>
            <div class="modal-footer border-0 pt-0">
                <button type="button" class="btn btn-light px-4" data-bs-dismiss="modal">취소</button>
                <button type="button" class="btn btn-primary px-4" id="btnSaveReview">저장</button>
            </div>
        </div>
    </div>
</div>

<script>
$(function() {
    const ctx = '${pageContext.request.contextPath}';
    const editModal = new bootstrap.Modal(document.getElementById('editReviewModal'));

    $('.btn-edit').on('click', function() {
        const id = $(this).data('id');
        const rating = $(this).data('rating');
        const content = $(this).data('content');
        
        $('#editReviewId').val(id);
        $('#editRating').val(rating);
        $('#editContent').val(content);
        
        editModal.show();
    });

    $('#btnSaveReview').on('click', function() {
        const id = $('#editReviewId').val();
        const rating = $('#editRating').val();
        const content = $('#editContent').val();
        
        api.put(ctx + '/api/reviews/' + id, {
            rating: rating,
            content: content
        }).done(function(res) {
            if (res.success) {
                toast.success('수정되었습니다.');
                editModal.hide();
                location.reload();
            } else {
                toast.error(res.message);
            }
        });
    });

    $('.btn-delete').on('click', function() {
        if (!confirm('정말 삭제하시겠습니까?')) return;
        const id = $(this).data('id');
        
        api.delete(ctx + '/api/reviews/' + id)
        .done(function(res) {
            if (res.success) {
                toast.success('삭제되었습니다.');
                $('#review-card-' + id).fadeOut(300, function() {
                    $(this).remove();
                    if ($('.card').length === 0) location.reload();
                });
            } else {
                toast.error(res.message);
            }
        });
    });
});
</script>
