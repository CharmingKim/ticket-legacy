<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<div class="container py-5">
    <div class="mb-4 d-flex align-items-center gap-3">
        <a href="${pageContext.request.contextPath}/member/mypage"
           class="btn btn-light btn-sm border" style="padding:6px 14px">
            <i class="bi bi-chevron-left"></i>
        </a>
        <div>
            <h3 class="fw-800 mb-0" style="letter-spacing:-.5px">보유 쿠폰</h3>
            <p class="text-muted mb-0" style="font-size:.88rem">사용 가능한 쿠폰 목록입니다.</p>
        </div>
    </div>

    <c:choose>
        <c:when test="${not empty coupons}">
            <div class="row g-3">
                <c:forEach var="c" items="${coupons}">
                    <div class="col-md-6 col-lg-4">
                        <div class="tl-coupon-card">
                            <!-- 쿠폰 헤더 (할인 정보) -->
                            <div class="tl-coupon-header">
                                <div class="tl-coupon-discount">${c.discountText} 할인</div>
                                <div class="tl-coupon-name">${c.couponName}</div>
                            </div>

                            <!-- 쿠폰 디테일 -->
                            <div class="tl-coupon-body">
                                <div class="tl-coupon-row">
                                    <span class="tl-coupon-label"><i class="bi bi-tag me-1"></i>쿠폰 코드</span>
                                    <span class="tl-coupon-code" id="code-${c.couponId}">${c.couponCode}</span>
                                    <button class="btn-copy ms-1" onclick="copyCode('${c.couponCode}', this)"
                                            title="복사">
                                        <i class="bi bi-copy"></i>
                                    </button>
                                </div>
                                <c:if test="${c.minAmount > 0}">
                                    <div class="tl-coupon-row">
                                        <span class="tl-coupon-label"><i class="bi bi-info-circle me-1"></i>최소 결제</span>
                                        <span><fmt:formatNumber value="${c.minAmount}" type="number"/>원 이상</span>
                                    </div>
                                </c:if>
                                <c:if test="${c.maxDiscount != null && c.maxDiscount > 0}">
                                    <div class="tl-coupon-row">
                                        <span class="tl-coupon-label"><i class="bi bi-arrow-down-circle me-1"></i>최대 할인</span>
                                        <span><fmt:formatNumber value="${c.maxDiscount}" type="number"/>원</span>
                                    </div>
                                </c:if>
                                <div class="tl-coupon-row">
                                    <span class="tl-coupon-label"><i class="bi bi-calendar3 me-1"></i>만료일</span>
                                    <span class="tl-coupon-expiry">
                                        ${tl:fmt(c.expiresAt, "yyyy.MM.dd HH:mm")}
                                    </span>
                                </div>
                            </div>

                            <!-- 쿠폰 푸터 -->
                            <div class="tl-coupon-footer">
                                <span class="tl-badge tl-badge-success">사용 가능</span>
                                <a href="${pageContext.request.contextPath}/performance/list"
                                   class="tl-coupon-use-btn">
                                    공연 예매하기 <i class="bi bi-arrow-right ms-1"></i>
                                </a>
                            </div>
                        </div>
                    </div>
                </c:forEach>
            </div>
        </c:when>
        <c:otherwise>
            <div class="text-center py-5">
                <div style="width:72px;height:72px;background:var(--gray-100);border-radius:50%;
                            display:flex;align-items:center;justify-content:center;margin:0 auto 20px">
                    <i class="bi bi-ticket-perforated" style="font-size:2rem;color:var(--gray-400)"></i>
                </div>
                <p class="text-muted mb-3">보유 중인 쿠폰이 없습니다.</p>
                <a href="${pageContext.request.contextPath}/performance/list"
                   class="tl-btn-primary">
                    <i class="bi bi-search me-2"></i>공연 둘러보기
                </a>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<style>
.tl-coupon-card {
    border: 1px solid var(--gray-200);
    border-radius: var(--radius-md);
    overflow: hidden;
    background: #fff;
    box-shadow: 0 2px 8px rgba(0,0,0,.06);
    transition: transform .15s, box-shadow .15s;
}
.tl-coupon-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(0,0,0,.1);
}
.tl-coupon-header {
    background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%);
    padding: 20px 20px 18px;
    color: #fff;
    position: relative;
}
.tl-coupon-header::after {
    content: '';
    position: absolute;
    bottom: -12px; left: 0; right: 0;
    height: 24px;
    background: #fff;
    border-radius: 50% 50% 0 0 / 24px 24px 0 0;
}
.tl-coupon-discount {
    font-size: 1.6rem;
    font-weight: 800;
    letter-spacing: -.5px;
    line-height: 1.2;
}
.tl-coupon-name {
    font-size: .85rem;
    opacity: .88;
    margin-top: 6px;
    line-height: 1.45;
    min-height: 2.47rem; /* 2줄 고정 높이 (.85rem × 1.45 × 2) */
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}
.tl-coupon-body {
    padding: 24px 20px 12px;
    display: flex;
    flex-direction: column;
    gap: 8px;
}
.tl-coupon-row {
    display: flex;
    align-items: center;
    font-size: .83rem;
    color: var(--text-secondary);
    gap: 4px;
}
.tl-coupon-label {
    color: var(--text-muted);
    min-width: 80px;
    flex-shrink: 0;
}
.tl-coupon-code {
    font-family: 'Courier New', monospace;
    font-size: .8rem;
    font-weight: 700;
    color: var(--primary);
    background: var(--primary-light);
    padding: 2px 8px;
    border-radius: 4px;
    letter-spacing: .5px;
}
.tl-coupon-expiry {
    color: var(--danger, #dc3545);
    font-weight: 600;
}
.btn-copy {
    background: none;
    border: none;
    padding: 2px 4px;
    color: var(--text-muted);
    cursor: pointer;
    font-size: .8rem;
    border-radius: 4px;
    transition: color .15s, background .15s;
}
.btn-copy:hover { color: var(--primary); background: var(--primary-light); }
.tl-coupon-footer {
    padding: 12px 20px 16px;
    border-top: 1px dashed var(--gray-200);
    display: flex;
    align-items: center;
    justify-content: space-between;
}
.tl-coupon-use-btn {
    font-size: .82rem;
    font-weight: 600;
    color: var(--primary);
    text-decoration: none;
    transition: opacity .15s;
}
.tl-coupon-use-btn:hover { opacity: .75; }
</style>

<script>
function copyCode(code, btn) {
    navigator.clipboard.writeText(code).then(() => {
        const orig = btn.innerHTML;
        btn.innerHTML = '<i class="bi bi-check-lg" style="color:var(--success)"></i>';
        setTimeout(() => { btn.innerHTML = orig; }, 1500);
    }).catch(() => {
        toast && toast.error('복사에 실패했습니다.');
    });
}
</script>
