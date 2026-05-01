<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-panel mb-4">
    <div class="portal-section-title">
        <div>
            <h3>공연 관리</h3>
            <p>공연 초안을 작성하고 심사를 요청합니다.</p>
        </div>
        <div class="d-flex gap-2">
            <select id="approvalStatusFilter" class="form-select form-select-sm">
                <option value="">전체 상태</option>
                <option value="DRAFT">초안</option>
                <option value="REVIEW">심사 중</option>
                <option value="APPROVED">승인</option>
                <option value="REJECTED">반려</option>
                <option value="PUBLISHED">게시</option>
            </select>
            <a class="btn btn-primary btn-sm" href="/partner/promoter/performances/new">공연 등록</a>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>공연</th>
                <th>상태</th>
                <th>예매 오픈</th>
                <th>일정</th>
                <th>좌석</th>
                <th>관리</th>
            </tr>
            </thead>
            <tbody id="performanceRows"></tbody>
        </table>
    </div>
</section>

<script>
var STATUS_KO = { DRAFT:'초안', REVIEW:'심사 중', APPROVED:'승인', REJECTED:'반려', PUBLISHED:'게시' };

function loadPromoterPerformances() {
    $.get('/partner/promoter/api/performances', {
        approvalStatus: $('#approvalStatusFilter').val()
    }).done(function(response) {
        var rows = (response.list || []).map(function(item) {
            var canSubmit = item.approvalStatus === 'DRAFT' || item.approvalStatus === 'REJECTED';
            var statusLabel = STATUS_KO[item.approvalStatus] || item.approvalStatus;
            var submitBtn = canSubmit
                ? '<button class="btn btn-primary btn-sm" onclick="submitReview(' + item.performanceId + ')">심사 요청</button>'
                : '';
            return '<tr>' +
                '<td><strong>' + item.title + '</strong>' +
                    '<div class="portal-meta">' + item.category + ' · ' + (item.venueName || '-') + '</div></td>' +
                '<td><span class="badge-status badge-' + item.approvalStatus + '">' + statusLabel + '</span></td>' +
                '<td>' + (item.ticketOpenAt || '-') + '</td>' +
                '<td><button class="btn btn-outline-secondary btn-sm" onclick="addQuickSchedule(' + item.performanceId + ')">일정 추가</button></td>' +
                '<td><button class="btn btn-outline-secondary btn-sm" onclick="generateSeats(' + item.performanceId + ')">좌석 생성</button></td>' +
                '<td class="d-flex gap-2">' + submitBtn + '</td>' +
                '</tr>';
        }).join('');
        $('#performanceRows').html(rows || '<tr><td colspan="6" class="text-center text-muted">등록된 공연이 없습니다.</td></tr>');
    });
}

function submitReview(performanceId) {
    $.post('/partner/promoter/api/performances/' + performanceId + '/submit')
        .done(function(result) {
            Swal.fire({ icon: 'success', text: result.message });
            loadPromoterPerformances();
        })
        .fail(function(xhr) {
            Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
        });
}

function generateSeats(performanceId) {
    $.post('/partner/promoter/api/performances/' + performanceId + '/seats')
        .done(function(result) {
            Swal.fire({ icon: 'success', text: result.message });
        })
        .fail(function(xhr) {
            Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
        });
}

function addQuickSchedule(performanceId) {
    Swal.fire({
        title: '공연 일정 추가',
        html: '<input id="scheduleDate" type="date" class="swal2-input"><input id="scheduleTime" type="time" class="swal2-input">',
        focusConfirm: false,
        preConfirm: function() {
            return {
                showDate: document.getElementById('scheduleDate').value,
                showTime: document.getElementById('scheduleTime').value
            };
        }
    }).then(function(result) {
        if (!result.isConfirmed) return;
        $.ajax({
            url: '/partner/promoter/api/performances/' + performanceId + '/schedules',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify(result.value)
        }).done(function(payload) {
            Swal.fire({ icon: 'success', text: payload.message });
        }).fail(function(xhr) {
            Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
        });
    });
}

$('#approvalStatusFilter').on('change', loadPromoterPerformances);
$(loadPromoterPerformances);
</script>
