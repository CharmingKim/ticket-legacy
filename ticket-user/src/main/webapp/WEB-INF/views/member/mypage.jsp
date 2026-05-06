<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<!-- Mypage Header -->
<section class="tl-mypage-header mb-0">
    <div class="container">
        <div class="row align-items-center">
            <div class="col-md-6">
                <div class="d-flex align-items-center gap-4">
                    <div class="tl-avatar" style="width: 100px; height: 100px; font-size: 2.5rem; background: linear-gradient(135deg, var(--primary), var(--secondary));">
                        ${not empty member.name ? member.name.substring(0,1) : 'U'}
                    </div>
                    <div>
                        <div class="tl-mypage-name h2 mb-1 fw-800">${member.name}</div>
                        <div class="tl-mypage-email text-muted mb-2">${member.email}</div>
                        <span class="badge rounded-pill bg-white text-dark shadow-sm px-3 py-2 border">
                            <i class="bi bi-award-fill text-warning me-1"></i> ${member.role}
                        </span>
                    </div>
                </div>
            </div>
            <div class="col-md-6 mt-4 mt-md-0">
                <div class="row g-2 text-center">
                    <div class="col-3">
                        <div class="bg-white p-3 rounded-4 shadow-sm border h-100">
                            <div class="text-muted small mb-1">예매</div>
                            <div class="fw-800 h4 mb-0 text-primary">${resCount}</div>
                        </div>
                    </div>
                    <div class="col-3">
                        <div class="bg-white p-3 rounded-4 shadow-sm border h-100">
                            <div class="text-muted small mb-1">쿠폰</div>
                            <div class="fw-800 h4 mb-0 text-success">${couponCount}</div>
                        </div>
                    </div>
                    <div class="col-3">
                        <div class="bg-white p-3 rounded-4 shadow-sm border h-100">
                            <div class="text-muted small mb-1">찜</div>
                            <div class="fw-800 h4 mb-0 text-danger">${wishCount}</div>
                        </div>
                    </div>
                    <div class="col-3">
                        <div class="bg-white p-3 rounded-4 shadow-sm border h-100">
                            <div class="text-muted small mb-1">리뷰</div>
                            <div class="fw-800 h4 mb-0 text-info">${reviewCount}</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>

<section class="tl-section bg-light" style="min-height: 500px;">
    <div class="container">
        <div class="row g-4">
            <!-- Sidebar Navigation -->
            <div class="col-lg-3">
                <div class="card border-0 shadow-sm mb-4 overflow-hidden rounded-4">
                    <div class="list-group list-group-flush tl-list-group">
                        <div class="list-group-item bg-dark text-white fw-700 py-3">나의 활동</div>
                        <a href="${pageContext.request.contextPath}/reservation/history" class="list-group-item list-group-item-action py-3">
                            <i class="bi bi-ticket me-2"></i> 예매 내역
                        </a>
                        <a href="${pageContext.request.contextPath}/member/coupons" class="list-group-item list-group-item-action py-3">
                            <i class="bi bi-gift me-2"></i> 보유 쿠폰
                            <c:if test="${couponCount > 0}">
                                <span class="badge bg-success rounded-pill float-end">${couponCount}</span>
                            </c:if>
                        </a>
                        <div class="list-group-item bg-dark text-white fw-700 py-3">계정 설정</div>
                        <a href="${pageContext.request.contextPath}/member/edit" class="list-group-item list-group-item-action py-3">
                            <i class="bi bi-person-lines-fill me-2"></i> 회원정보 수정
                        </a>
                        <a href="${pageContext.request.contextPath}/member/change-password" class="list-group-item list-group-item-action py-3">
                            <i class="bi bi-shield-lock me-2"></i> 비밀번호 변경
                        </a>
                        <a href="${pageContext.request.contextPath}/member/withdraw" class="list-group-item list-group-item-action py-3 text-danger">
                            <i class="bi bi-person-x me-2"></i> 회원 탈퇴
                        </a>
                    </div>
                </div>

                <div class="card border-0 shadow-sm rounded-4 overflow-hidden">
                    <div class="list-group list-group-flush tl-list-group">
                        <div class="list-group-item bg-dark text-white fw-700 py-3">고객센터</div>
                        <a href="${pageContext.request.contextPath}/inquiry/list" class="list-group-item list-group-item-action py-3">
                            <i class="bi bi-chat-dots me-2"></i> 1:1 문의 내역
                        </a>
                        <a href="${pageContext.request.contextPath}/support/faq" class="list-group-item list-group-item-action py-3">
                            <i class="bi bi-question-circle me-2"></i> 자주 묻는 질문
                        </a>
                    </div>
                </div>
            </div>

            <!-- Content Area -->
            <div class="col-lg-9">
                <!-- Recent Reservations -->
                <div class="card border-0 shadow-sm rounded-4 mb-4">
                    <div class="card-header bg-white border-0 py-3 d-flex justify-content-between align-items-center">
                        <h5 class="fw-800 mb-0">최근 예매 내역</h5>
                        <a href="${pageContext.request.contextPath}/reservation/history" class="text-decoration-none small text-primary">전체보기 <i class="bi bi-chevron-right"></i></a>
                    </div>
                    <div class="card-body p-0">
                        <c:choose>
                            <c:when test="${not empty recentReservations}">
                                <div class="table-responsive">
                                    <table class="table table-hover mb-0 tl-table">
                                        <tbody class="border-top-0">
                                            <c:forEach var="r" items="${recentReservations}">
                                                <tr onclick="location.href='${pageContext.request.contextPath}/reservation/detail/${r.reservationId}'" style="cursor: pointer;">
                                                    <td class="ps-4">
                                                        <div class="fw-700 text-dark">${r.performanceTitle}</div>
                                                        <div class="text-muted small">${tl:fmt(r.scheduleDatetime, "yyyy.MM.dd HH:mm")}</div>
                                                    </td>
                                                    <td class="text-center">
                                                        <c:choose>
                                                            <c:when test="${r.status == 'CONFIRMED'}">
                                                                <span class="badge bg-success-soft text-success px-3">완료</span>
                                                            </c:when>
                                                            <c:when test="${r.status == 'CANCELLED'}">
                                                                <span class="badge bg-danger-soft text-danger px-3">취소</span>
                                                            </c:when>
                                                            <c:when test="${r.status == 'REFUNDED'}">
                                                                <span class="badge bg-secondary-soft text-secondary px-3">환불</span>
                                                            </c:when>
                                                            <c:otherwise>
                                                                <span class="badge bg-warning-soft text-warning px-3">${r.status}</span>
                                                            </c:otherwise>
                                                        </c:choose>
                                                    </td>
                                                    <td class="pe-4 text-end">
                                                        <span class="fw-700"><fmt:formatNumber value="${r.totalAmount}" type="number" />원</span>
                                                    </td>
                                                </tr>
                                            </c:forEach>
                                        </tbody>
                                    </table>
                                </div>
                            </c:when>
                            <c:otherwise>
                                <div class="text-center py-5 text-muted">예매 내역이 없습니다.</div>
                            </c:otherwise>
                        </c:choose>
                    </div>
                </div>

                <div class="row g-4">
                    <!-- My Wishlist (Snippet) -->
                    <div class="col-md-6">
                        <div class="card border-0 shadow-sm rounded-4 h-100">
                            <div class="card-header bg-white border-0 py-3 d-flex justify-content-between align-items-center">
                                <h5 class="fw-800 mb-0">찜한 공연</h5>
                                <a href="${pageContext.request.contextPath}/member/wishlist" class="text-decoration-none small text-primary">더보기 <i class="bi bi-chevron-right"></i></a>
                            </div>
                            <div class="card-body py-2">
                                <p class="text-muted small">총 ${wishCount}개의 관심 공연이 있습니다.</p>
                                <div class="d-flex flex-column gap-2">
                                    <a href="${pageContext.request.contextPath}/member/wishlist" class="btn btn-light btn-sm text-start py-2 border-0">
                                        <i class="bi bi-heart-fill text-danger me-2"></i> 나의 찜 목록 바로가기
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- My Reviews (Snippet) -->
                    <div class="col-md-6">
                        <div class="card border-0 shadow-sm rounded-4 h-100">
                            <div class="card-header bg-white border-0 py-3 d-flex justify-content-between align-items-center">
                                <h5 class="fw-800 mb-0">나의 리뷰</h5>
                                <a href="${pageContext.request.contextPath}/member/my-reviews" class="text-decoration-none small text-primary">더보기 <i class="bi bi-chevron-right"></i></a>
                            </div>
                            <div class="card-body py-2">
                                <p class="text-muted small">총 ${reviewCount}개의 관람평을 작성하셨습니다.</p>
                                <div class="d-flex flex-column gap-2">
                                    <a href="${pageContext.request.contextPath}/member/my-reviews" class="btn btn-light btn-sm text-start py-2 border-0">
                                        <i class="bi bi-chat-left-quote-fill text-primary me-2"></i> 나의 리뷰 관리 바로가기
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>

<style>
.bg-success-soft { background-color: rgba(25, 135, 84, 0.1); }
.bg-danger-soft { background-color: rgba(220, 53, 69, 0.1); }
.bg-warning-soft { background-color: rgba(255, 193, 7, 0.1); }
.bg-secondary-soft { background-color: rgba(108, 117, 125, 0.12); }
.tl-list-group .list-group-item { border-left: 0; border-right: 0; }
.tl-list-group .list-group-item:first-child { border-top: 0; }
.tl-list-group .list-group-item-action:hover { background-color: #f8f9fa; color: var(--primary); }
</style>
