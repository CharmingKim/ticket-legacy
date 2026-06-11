<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>

<div class="tl-seat-wrap">
    <div class="container py-4">

        <!-- Page Header -->
        <div class="d-flex align-items-center gap-3 mb-4">
            <a href="javascript:history.back()" class="tl-btn-ghost btn-sm">
                <i class="bi bi-arrow-left me-1"></i>뒤로
            </a>
            <div>
                <h4 class="fw-700 mb-0" style="font-size:1.1rem" id="perfTitle">좌석 선택</h4>
                <p class="text-muted mb-0" style="font-size:.85rem" id="scheduleInfo">
                    일정 정보 로딩 중...
                </p>
            </div>
        </div>

        <div class="row g-4">

            <!-- Seat Map -->
            <div class="col-lg-8">
                <!-- Stage -->
                <div class="tl-stage">
                    <i class="bi bi-lightning-charge-fill me-2"></i>STAGE
                </div>

                <!-- Hold Timer -->
                <div id="holdTimer" class="tl-hold-timer mb-3" style="display:none">
                    <i class="bi bi-clock"></i>
                    <span>선점 유지 시간: <strong id="timerText">10:00</strong></span>
                </div>

                <!-- Seat Grid (섹션별) -->
                <div id="seatMapContainer">
                    <div class="text-center py-5">
                        <div class="tl-spinner"></div>
                        <p class="text-muted mt-3">좌석 정보 로딩 중...</p>
                    </div>
                </div>

                <!-- Legend -->
                <div class="tl-seat-legend">
                    <div class="tl-legend-item">
                        <div class="tl-legend-box" style="background:var(--gray-200)"></div> 선택 가능
                    </div>
                    <div class="tl-legend-item">
                        <div class="tl-legend-box" style="background:var(--primary)"></div> 내가 선택
                    </div>
                    <div class="tl-legend-item">
                        <div class="tl-legend-box" style="background:var(--gray-400)"></div> 선점됨
                    </div>
                    <div class="tl-legend-item">
                        <div class="tl-legend-box" style="background:var(--gray-300)"></div> 예매 완료
                    </div>
                </div>
            </div>

            <!-- Summary Panel -->
            <div class="col-lg-4">
                <div class="tl-seat-summary">
                    <h5><i class="bi bi-ticket me-2 text-primary"></i>선택한 좌석</h5>

                    <div id="selectedList">
                        <p class="text-muted text-center py-3" style="font-size:.88rem">
                            좌석을 선택해주세요
                        </p>
                    </div>

                    <div class="tl-confirm-section" id="priceSection" style="display:none">
                        <div class="tl-confirm-row">
                            <span class="label">선택 좌석</span>
                            <span class="value" id="selectedCount">0석</span>
                        </div>
                        <div class="tl-confirm-row">
                            <span class="label fw-700">합계</span>
                            <span class="tl-total-price" id="totalPrice">0원</span>
                        </div>
                    </div>

                    <button id="confirmBtn" class="tl-auth-btn mt-3" disabled>
                        <i class="bi bi-arrow-right-circle me-2"></i>예매 확인
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
const scheduleId = '${scheduleId}';
const ctx = '${pageContext.request.contextPath}';
const selectedSeats = {}; // seatId → {seatId, label, price, grade}
let holdTimerInterval = null;
let minExpiry = null;

$(function() {
    loadSeats();
    setInterval(loadSeats, 15000); // 15초마다 갱신
});

function loadSeats() {
    api.get(ctx + '/api/seats/' + scheduleId)
        .done(function(res) {
            if (res.success) renderSeatMap(res.data);
        })
        .fail(function(xhr) {
            if (xhr.status !== 401 && xhr.status !== 403) {
                $('#seatMapContainer').html(
                    '<p class="text-danger text-center py-4">좌석 정보를 불러올 수 없습니다.</p>');
            }
        });
}

function renderSeatMap(seats) {
    if (!seats || !seats.length) {
        $('#seatMapContainer').html('<p class="text-muted text-center py-4">등록된 좌석이 없습니다.</p>');
        return;
    }

    // Group by section
    const sections = {};
    seats.forEach(s => {
        const key = s.section || '일반';
        if (!sections[key]) sections[key] = [];
        sections[key].push(s);
    });

    let html = '';
    for (const [sec, seatList] of Object.entries(sections)) {
        html += `<div class="mb-4">
            <div class="d-flex align-items-center gap-2 mb-2">
                <span style="font-size:.85rem;font-weight:700;color:var(--gray-600)">\${sec} 구역</span>
            </div>
            <div class="tl-seat-grid">`;

        // Group by row
        const rows = {};
        seatList.forEach(s => {
            const r = s.seatRow || 'A';
            if (!rows[r]) rows[r] = [];
            rows[r].push(s);
        });

        for (const [row, rowSeats] of Object.entries(rows)) {
            rowSeats.sort((a, b) => a.seatNumber - b.seatNumber);
            rowSeats.forEach(s => {
                const cls = getSeatClass(s);
                const label = row + s.seatNumber;
                html += `<button class="tl-seat \${cls}"
                    data-seat-id="\${s.seatId}"
                    data-label="\${label}"
                    data-price="\${s.price}"
                    data-grade="\${s.grade}"
                    data-status="\${s.status}"
                    data-expires="\${s.expiresAt || ''}"
                    title="\${label} (\${s.grade}) ₩\${(s.price||0).toLocaleString()}"
                    >\${label}</button>`;
            });
            html += '<div style="width:100%;height:0"></div>'; // row break
        }

        html += '</div></div>';
    }

    $('#seatMapContainer').html(html);

    // Server-side MY_HOLD 좌석을 클라이언트 state 로 복원 (페이지 재진입 시)
    seats.filter(s => s.status === 'MY_HOLD').forEach(s => {
        const idStr = String(s.seatId);
        if (!selectedSeats[idStr]) {
            selectedSeats[idStr] = {
                seatId:    idStr,
                label:     (s.seatRow || 'A') + s.seatNumber,
                price:     s.price,
                grade:     s.grade,
                expiresAt: s.expiresAt
            };
        }
    });

    // Re-mark already selected seats
    for (const seatId of Object.keys(selectedSeats)) {
        $('[data-seat-id="' + seatId + '"]').addClass('my-hold');
    }
    updateSummary();

    // Start hold timer if any holds
    const myHolds = seats.filter(s => s.status === 'MY_HOLD');
    if (myHolds.length && !holdTimerInterval) {
        minExpiry = Math.min(...myHolds.map(s => s.expiresAt));
        startTimer();
    }
}

function getSeatClass(s) {
    if (selectedSeats[s.seatId]) return 'my-hold';
    switch (s.status) {
        case 'AVAILABLE': return 'available';
        case 'MY_HOLD':   return 'my-hold';
        case 'HELD':      return 'held';
        case 'RESERVED':  return 'reserved';
        default:          return 'available';
    }
}

$(document).on('click', '.tl-seat', function() {
    const $btn   = $(this);
    const status = $btn.data('status');
    const seatId = String($btn.data('seat-id'));

    if (status === 'HELD' || status === 'RESERVED') {
        toast.warning('선택할 수 없는 좌석입니다.');
        return;
    }

    if (status === 'MY_HOLD' || selectedSeats[seatId]) {
        // 선점 해제
        api.del(ctx + '/api/seats/hold/' + scheduleId + '/' + seatId)
            .done(function(res) {
                if (res.success) {
                    delete selectedSeats[seatId];
                    $btn.removeClass('my-hold').addClass('available').data('status', 'AVAILABLE');
                    updateSummary();
                    toast.success('좌석 선점이 해제되었습니다.');
                }
            });
        return;
    }

    // 좌석 선점
    api.post(ctx + '/api/seats/hold', { scheduleId: parseInt(scheduleId), seatId: parseInt(seatId) })
        .done(function(res) {
            if (res.success) {
                const label = $btn.data('label');
                const price = $btn.data('price');
                const grade = $btn.data('grade');
                selectedSeats[seatId] = { seatId, label, price, grade, expiresAt: res.data.expiresAt };
                $btn.removeClass('available').addClass('my-hold').data('status', 'MY_HOLD');
                updateSummary();

                // Timer
                if (!holdTimerInterval) {
                    minExpiry = res.data.expiresAt;
                    startTimer();
                } else {
                    minExpiry = Math.min(minExpiry, res.data.expiresAt);
                }
                toast.success(label + ' 좌석이 선점되었습니다. (10분 유지)');
            }
        })
        .fail(function(xhr) {
            const msg = xhr.responseJSON?.message || '좌석 선점에 실패했습니다.';
            toast.error(msg);
        });
});

function updateSummary() {
    const list = Object.values(selectedSeats);
    if (!list.length) {
        $('#selectedList').html('<p class="text-muted text-center py-3" style="font-size:.88rem">좌석을 선택해주세요</p>');
        $('#priceSection').hide();
        $('#confirmBtn').prop('disabled', true);
        return;
    }

    let html = '';
    let total = 0;
    list.forEach(s => {
        total += (s.price || 0);
        html += `<div class="tl-selected-seat">
            <div>
                <div class="seat-label">\${s.label}</div>
                <div style="font-size:.78rem;color:var(--text-muted)">\${s.grade}</div>
            </div>
            <div class="d-flex align-items-center gap-2">
                <span style="font-weight:700;font-size:.9rem">\${(s.price||0).toLocaleString()}원</span>
                <button class="remove-btn" data-seat-id="\${s.seatId}" title="제거">
                    <i class="bi bi-x"></i>
                </button>
            </div>
        </div>`;
    });

    $('#selectedList').html(html);
    $('#selectedCount').text(list.length + '석');
    $('#totalPrice').text(total.toLocaleString() + '원');
    $('#priceSection').show();
    $('#confirmBtn').prop('disabled', false);
}

$(document).on('click', '.remove-btn', function(e) {
    e.stopPropagation();
    const seatId = String($(this).data('seat-id'));
    api.del(ctx + '/api/seats/hold/' + scheduleId + '/' + seatId)
        .done(function(res) {
            if (res.success) {
                delete selectedSeats[seatId];
                $('[data-seat-id="' + seatId + '"]').removeClass('my-hold').addClass('available').data('status', 'AVAILABLE');
                updateSummary();
            }
        });
});

$('#confirmBtn').on('click', function() {
    const seatIds = Object.keys(selectedSeats).join(',');
    location.href = ctx + '/reservation/confirm?scheduleId=' + scheduleId + '&seatIds=' + seatIds;
});

function startTimer() {
    $('#holdTimer').show();
    holdTimerInterval = setInterval(function() {
        const remaining = Math.floor((minExpiry - Date.now()) / 1000);
        if (remaining <= 0) {
            clearInterval(holdTimerInterval);
            holdTimerInterval = null;
            $('#holdTimer').addClass('expired').find('#timerText').text('만료됨');
            toast.warning('좌석 선점 시간이 만료되었습니다. 다시 선택해주세요.');
            for (const id of Object.keys(selectedSeats)) {
                $('[data-seat-id="' + id + '"]').removeClass('my-hold').addClass('available').data('status', 'AVAILABLE');
            }
            Object.keys(selectedSeats).forEach(k => delete selectedSeats[k]);
            updateSummary();
            return;
        }
        const m = Math.floor(remaining / 60);
        const s = remaining % 60;
        $('#timerText').text(m + ':' + String(s).padStart(2, '0'));
    }, 1000);
}
</script>
