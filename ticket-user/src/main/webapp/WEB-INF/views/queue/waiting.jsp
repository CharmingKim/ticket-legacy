<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<div class="tl-queue-wrap">
    <div class="tl-queue-card">

        <div class="tl-queue-icon">
            <i class="bi bi-hourglass-split"></i>
        </div>

        <h1 class="tl-queue-title">잠시만 기다려주세요</h1>
        <p class="tl-queue-desc">
            많은 분들이 동시에 접속 중입니다.<br>
            순서가 되면 자동으로 이동됩니다.
        </p>

        <div class="tl-queue-number" id="queuePosition">-</div>
        <div class="tl-queue-label">현재 대기 순번</div>

        <div class="tl-queue-progress mb-2">
            <div class="tl-queue-bar" id="queueBar" style="width:5%"></div>
        </div>

        <div class="tl-queue-eta" id="queueEta">예상 대기 시간 계산 중...</div>

        <div style="margin-top:40px;opacity:.5;font-size:.8rem">
            이 페이지를 닫지 마세요. 순서가 되면 자동으로 이동됩니다.
        </div>
    </div>
</div>

<script>
const ctx        = '${pageContext.request.contextPath}';
const scheduleId = '${param.scheduleId}';
let entered      = false;
let pollInterval = null;

$(function() {
    if (!scheduleId) {
        $('#queuePosition').text('오류');
        $('#queueEta').text('잘못된 접근입니다.');
        return;
    }
    enterQueue();
});

function enterQueue() {
    api.post(ctx + '/api/queue/enter', { scheduleId: parseInt(scheduleId) })
        .done(function(res) {
            if (res.success) {
                entered = true;
                if (res.data && res.data.passed) {
                    proceed();
                    return;
                }
                updateUI(res.data);
                startPolling();
            }
        })
        .fail(function() {
            $('#queueEta').text('대기열 진입에 실패했습니다. 새로고침해주세요.');
        });
}

function startPolling() {
    pollInterval = setInterval(checkPosition, 3000);
}

function checkPosition() {
    api.get(ctx + '/api/queue/position', { scheduleId: scheduleId })
        .done(function(res) {
            if (!res.success) return;
            const data = res.data;
            if (data && data.passed) {
                clearInterval(pollInterval);
                proceed();
                return;
            }
            updateUI(data);
        });
}

function updateUI(data) {
    if (!data) return;
    const pos = data.position || 0;
    const eta = data.estimatedWaitSeconds || 0;

    $('#queuePosition').text(pos.toLocaleString());

    if (eta > 0) {
        const min = Math.floor(eta / 60);
        const sec = eta % 60;
        if (min > 0) {
            $('#queueEta').text('예상 대기 시간: 약 ' + min + '분 ' + sec + '초');
        } else {
            $('#queueEta').text('예상 대기 시간: 약 ' + sec + '초');
        }
    } else {
        $('#queueEta').text('거의 다 됐습니다!');
    }

    // Progress bar (max 100명 기준 표시)
    const progress = Math.max(5, Math.min(95, Math.round((1 / Math.max(1, pos)) * 100)));
    $('#queueBar').css('width', progress + '%');
}

function proceed() {
    $('#queuePosition').text('입장!');
    $('#queueEta').html('<i class="bi bi-arrow-right-circle me-2"></i>좌석 선택 페이지로 이동합니다...');
    $('#queueBar').css('width', '100%');
    setTimeout(() => {
        location.href = ctx + '/seat/select/' + scheduleId;
    }, 1500);
}
</script>
