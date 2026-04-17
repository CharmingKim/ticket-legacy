<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<div class="container py-5">
    <div class="tl-confirm-box">

        <!-- Title -->
        <div class="text-center mb-4">
            <div style="width:56px;height:56px;background:var(--primary-light);border-radius:50%;
                        display:flex;align-items:center;justify-content:center;margin:0 auto 16px">
                <i class="bi bi-ticket-perforated" style="font-size:1.5rem;color:var(--primary)"></i>
            </div>
            <h3 class="fw-800" style="letter-spacing:-.5px">예매 확인</h3>
            <p class="text-muted" style="font-size:.9rem">아래 내용을 확인하고 결제를 진행해주세요</p>
        </div>

        <!-- Performance Info -->
        <div class="tl-confirm-section" style="border-top:none;padding-top:0">
            <div class="tl-confirm-row">
                <span class="label">공연명</span>
                <span class="value" id="perfName">
                    ${not empty schedule.performanceTitle ? schedule.performanceTitle : '공연 정보'}
                </span>
            </div>
            <div class="tl-confirm-row">
                <span class="label">일정</span>
                <span class="value" id="scheduleTime">
                    <c:if test="${not empty schedule.startDatetime}">
                        ${tl:fmt(schedule.startDatetime, "yyyy년 MM월 dd일 HH:mm")}
                    </c:if>
                </span>
            </div>
            <div class="tl-confirm-row">
                <span class="label">장소</span>
                <span class="value">${not empty schedule.venueName ? schedule.venueName : '장소 미정'}</span>
            </div>
        </div>

        <!-- Seat Info -->
        <div class="tl-confirm-section">
            <div class="fw-700 mb-3" style="font-size:.95rem">선택 좌석</div>
            <div id="seatDetails">
                <c:forEach var="seat" items="${seats}">
                    <div class="tl-confirm-row">
                        <span class="label">${seat.section} ${seat.seatRow}${seat.seatNumber}</span>
                        <span class="value">${seat.grade} — <fmt:formatNumber value="${seat.price}" type="number" />원</span>
                    </div>
                </c:forEach>
            </div>
        </div>

        <!-- Coupon -->
        <c:if test="${not empty coupons}">
            <div class="tl-confirm-section">
                <div class="fw-700 mb-3" style="font-size:.95rem">쿠폰 선택 (선택)</div>
                <select id="couponSelect" class="tl-form-control">
                    <option value="">쿠폰 없음</option>
                    <c:forEach var="c" items="${coupons}">
                        <option value="${c.couponId}" data-discount="${c.discountAmount}">
                            ${c.couponName} (${c.discountAmount}원 할인)
                        </option>
                    </c:forEach>
                </select>
            </div>
        </c:if>

        <!-- Price Summary -->
        <div class="tl-confirm-section">
            <div class="tl-confirm-row">
                <span class="label">좌석 금액</span>
                <span class="value" id="baseAmount">
                    <fmt:formatNumber value="${totalAmount}" type="number" />원
                </span>
            </div>
            <div class="tl-confirm-row" id="discountRow" style="display:none">
                <span class="label" style="color:var(--success)">쿠폰 할인</span>
                <span class="value" style="color:var(--success)">- <span id="discountAmt">0</span>원</span>
            </div>
            <div class="tl-confirm-row mt-2 pt-2" style="border-top:1px solid var(--gray-200)">
                <span class="label fw-700">최종 결제 금액</span>
                <span class="tl-confirm-total" id="finalAmount">
                    <fmt:formatNumber value="${totalAmount}" type="number" />원
                </span>
            </div>
        </div>

        <!-- Actions -->
        <div class="d-flex gap-3 mt-4">
            <a href="javascript:history.back()" class="tl-btn-outline w-100 justify-content-center" style="padding:13px">
                <i class="bi bi-arrow-left me-2"></i>좌석 재선택
            </a>
            <button id="payBtn" class="tl-auth-btn w-100">
                <i class="bi bi-credit-card me-2"></i>결제하기
            </button>
        </div>

        <p class="text-center text-muted mt-3" style="font-size:.78rem">
            <i class="bi bi-shield-check me-1"></i>
            결제 정보는 안전하게 처리됩니다
        </p>
    </div>
</div>

<script>
const ctx         = '${pageContext.request.contextPath}';
const scheduleId  = '${scheduleId}';
const seatIds     = '${seatIds}';
let baseAmount    = ${totalAmount != null ? totalAmount : 0};
let discountAmt   = 0;
let selectedCouponId = null;

$('#couponSelect').on('change', function() {
    const opt = $(this).find(':selected');
    discountAmt      = parseInt(opt.data('discount') || 0);
    selectedCouponId = $(this).val() || null;
    const final      = Math.max(0, baseAmount - discountAmt);

    if (discountAmt > 0) {
        $('#discountRow').show();
        $('#discountAmt').text(discountAmt.toLocaleString());
    } else {
        $('#discountRow').hide();
    }
    $('#finalAmount').text(final.toLocaleString() + '원');
});

$('#payBtn').on('click', function() {
    $(this).prop('disabled', true).html('<span class="tl-spinner" style="width:20px;height:20px;border-width:2px"></span>');

    const payload = {
        scheduleId:  parseInt(scheduleId),
        seatIds:     seatIds.split(',').map(Number),
        couponId:    selectedCouponId ? parseInt(selectedCouponId) : null
    };

    api.post(ctx + '/api/payment/process', payload)
        .done(function(res) {
            if (res.success) {
                toast.success('결제가 완료되었습니다!');
                setTimeout(() => { location.href = ctx + '/reservation/history'; }, 1500);
            } else {
                toast.error(res.message || '결제에 실패했습니다.');
                $('#payBtn').prop('disabled', false).html('<i class="bi bi-credit-card me-2"></i>결제하기');
            }
        })
        .fail(function(xhr) {
            const msg = xhr.responseJSON?.message || '결제 처리 중 오류가 발생했습니다.';
            toast.error(msg);
            $('#payBtn').prop('disabled', false).html('<i class="bi bi-credit-card me-2"></i>결제하기');
        });
});
</script>
