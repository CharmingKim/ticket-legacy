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
                <span class="value">${not empty schedule.venue ? schedule.venue : '장소 미정'}</span>
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
                        <option value="${c.couponCode}"
                                data-discount-type="${c.discountType}"
                                data-discount-value="${c.discountValue}"
                                data-max-discount="${c.maxDiscount}"
                                data-min-amount="${c.minAmount}"
                                <c:if test="${c.minAmount > totalAmount}">disabled</c:if>>
                            ${c.couponName} (${c.discountText} 할인<c:if test="${c.minAmount > 0}">, 최소 <fmt:formatNumber value="${c.minAmount}" type="number"/>원~</c:if>)<c:if test="${c.minAmount > totalAmount}"> — 사용 불가</c:if>
                        </option>
                    </c:forEach>
                </select>
            </div>
        </c:if>

        <!-- Payment Method -->
        <div class="tl-confirm-section">
            <div class="fw-700 mb-3" style="font-size:.95rem">결제수단</div>
            <div class="d-flex gap-2">
                <label class="tl-pay-method flex-fill">
                    <input type="radio" name="paymentMethod" value="CARD" checked>
                    <i class="bi bi-credit-card-2-front me-2"></i>신용카드
                </label>
                <label class="tl-pay-method flex-fill">
                    <input type="radio" name="paymentMethod" value="BANK_TRANSFER">
                    <i class="bi bi-bank me-2"></i>계좌이체
                </label>
            </div>
        </div>

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

let selectedCouponCode = null;

function calcDiscount(opt, base) {
    const type = opt.data('discount-type');
    const val  = parseInt(opt.data('discount-value') || 0);
    const max  = parseInt(opt.data('max-discount')   || 0);
    if (!type || !val) return 0;
    if (type === 'PERCENT') {
        const d = Math.round(base * val / 100);
        return max > 0 ? Math.min(d, max) : d;
    }
    return Math.min(val, base);
}

$('#couponSelect').on('change', function() {
    const opt          = $(this).find(':selected');
    selectedCouponCode = $(this).val() || null;
    discountAmt        = selectedCouponCode ? calcDiscount(opt, baseAmount) : 0;
    const finalAmt     = Math.max(0, baseAmount - discountAmt);

    if (discountAmt > 0) {
        $('#discountRow').show();
        $('#discountAmt').text(discountAmt.toLocaleString());
    } else {
        $('#discountRow').hide();
    }
    $('#finalAmount').text(finalAmt.toLocaleString() + '원');
});

function restorePayBtn() {
    $('#payBtn').prop('disabled', false).html('<i class="bi bi-credit-card me-2"></i>결제하기');
}

$('#payBtn').on('click', function() {
    const $btn = $(this);
    const seatIdList = seatIds.split(',').map(Number);
    const finalAmt   = Math.max(0, baseAmount - discountAmt);
    const method     = $('input[name="paymentMethod"]:checked').val();

    if (!method) { toast.warning('결제수단을 선택해주세요.'); return; }

    $btn.prop('disabled', true).html('<span class="tl-spinner" style="width:20px;height:20px;border-width:2px"></span>');

    // Step 1: 예약 생성 (PENDING)
    api.post(ctx + '/api/reservation/create', {
        scheduleId:  parseInt(scheduleId),
        seatIds:     seatIdList,
        totalAmount: baseAmount
    })
    .done(function(res) {
        if (!res.success || !res.data || !res.data.reservationId) {
            toast.error(res.message || '예약 생성에 실패했습니다.');
            restorePayBtn();
            return;
        }
        const reservationId = res.data.reservationId;

        // Step 2: 결제 처리 (CONFIRMED)
        // amount는 표시용일 뿐 — 서버가 reservation.totalAmount 기준으로 재계산
        api.post(ctx + '/api/payment/process', {
            reservationId: reservationId,
            scheduleId:    parseInt(scheduleId),
            seatIds:       seatIdList,
            method:        method,
            amount:        baseAmount,
            couponCode:    selectedCouponCode
        })
        .done(function(res2) {
            if (res2.success) {
                toast.success('결제가 완료되었습니다!');
                setTimeout(() => { location.href = ctx + '/reservation/history'; }, 1500);
            } else {
                toast.error(res2.message || '결제에 실패했습니다.');
                restorePayBtn();
            }
        })
        .fail(function(xhr) {
            const msg = (xhr.responseJSON && xhr.responseJSON.message) || '결제 처리 중 오류가 발생했습니다.';
            toast.error(msg);
            restorePayBtn();
        });
    })
    .fail(function(xhr) {
        const msg = (xhr.responseJSON && xhr.responseJSON.message) || '예약 생성 중 오류가 발생했습니다.';
        toast.error(msg);
        restorePayBtn();
    });
});
</script>
