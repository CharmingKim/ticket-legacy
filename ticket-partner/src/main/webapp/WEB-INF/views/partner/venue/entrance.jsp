<%@ page contentType="text/html;charset=UTF-8" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>입장 관리</h3>
            <p>확정 예매를 조회하고 입장 확인을 처리합니다.</p>
        </div>
        <div class="d-flex gap-2">
            <input id="showDate" type="date" class="form-control form-control-sm" value="${today}" />
            <input id="keyword" class="form-control form-control-sm" placeholder="예매번호, 고객명, 전화번호, 공연명" />
            <button class="btn btn-primary btn-sm" onclick="loadEntranceRows()">검색</button>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>예매번호</th>
                <th>고객</th>
                <th>공연</th>
                <th>일정</th>
                <th>좌석</th>
                <th>입장 처리</th>
            </tr>
            </thead>
            <tbody id="entranceRows"></tbody>
        </table>
    </div>
</section>

<script>
function loadEntranceRows() {
    $.get('/partner/venue/api/entrance', {
        showDate: $('#showDate').val(),
        keyword: $('#keyword').val()
    }).done(function(rows) {
        var html = (rows || []).map(function(row) {
            var checkedIn = row.checked_in_at ? '입장 완료: ' + row.checked_in_at : '';
            var action = row.checked_in_at
                ? '<span class="badge text-bg-success">입장 완료</span>'
                : '<button class="btn btn-primary btn-sm" onclick="checkIn(\'' + row.reservation_no + '\')">입장 확인</button>';
            return '<tr>' +
                '<td><strong>' + row.reservation_no + '</strong><div class="portal-meta">' + checkedIn + '</div></td>' +
                '<td>' + row.member_name + '<div class="portal-meta">' + row.member_phone + '</div></td>' +
                '<td>' + row.performance_title + '</td>' +
                '<td>' + row.show_date + ' ' + row.show_time + '</td>' +
                '<td>' + (row.seat_summary || '-') + '</td>' +
                '<td>' + action + '</td>' +
                '</tr>';
        }).join('');
        $('#entranceRows').html(html || '<tr><td colspan="6" class="text-center text-muted">확정 예매가 없습니다.</td></tr>');
    });
}

function checkIn(reservationNo) {
    $.ajax({
        url: '/partner/venue/api/entrance/check-in',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ reservationNo: reservationNo })
    }).done(function(result) {
        Swal.fire({ icon: 'success', text: result.message });
        loadEntranceRows();
    }).fail(function(xhr) {
        Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
    });
}

$(loadEntranceRows);
</script>
