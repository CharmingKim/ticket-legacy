<%@ page contentType="text/html;charset=UTF-8" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>예약 조회</h3>
            <p>예약번호, 회원명, 이메일, 공연명으로 예약을 검색하고 필요시 취소 처리합니다.</p>
        </div>
        <div class="d-flex gap-2">
            <input id="reservationKeyword" class="form-control form-control-sm" placeholder="검색어 입력" />
            <select id="reservationStatus" class="form-select form-select-sm">
                <option value="">전체 상태</option>
                <option value="PENDING">대기중</option>
                <option value="CONFIRMED">확정</option>
                <option value="CANCELLED">취소</option>
                <option value="REFUNDED">환불</option>
            </select>
            <button class="btn btn-primary btn-sm" onclick="loadReservations()">검색</button>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>예약번호</th>
                <th>예약자</th>
                <th>공연</th>
                <th>상태</th>
                <th>결제금액</th>
                <th></th>
            </tr>
            </thead>
            <tbody id="reservationResults"></tbody>
        </table>
    </div>
</section>

<script>
var STATUS_KO = { PENDING:'대기중', CONFIRMED:'확정', CANCELLED:'취소', REFUNDED:'환불' };

function loadReservations() {
    $.get('/backoffice/staff/api/reservations', {
        keyword: $('#reservationKeyword').val(),
        status: $('#reservationStatus').val()
    }).done(function(response) {
        var rows = (response.list || []).map(function(item) {
            var cancelAction = (item.status === 'PENDING' || item.status === 'CONFIRMED')
                ? '<button class="btn btn-outline-danger btn-sm" onclick="cancelReservation(' + item.reservationId + ')">취소</button>'
                : '';
            return '<tr>' +
                '<td><strong>' + item.reservationNo + '</strong>' +
                    '<div class="portal-meta">' + (item.createdAt || '') + '</div></td>' +
                '<td>' + item.memberName + '<div class="portal-meta">' + item.memberEmail + '</div></td>' +
                '<td>' + item.performanceTitle +
                    '<div class="portal-meta">' + item.showDate + ' ' + item.showTime + '</div></td>' +
                '<td>' + (STATUS_KO[item.status] || item.status) + '</td>' +
                '<td>' + Number(item.totalAmount || 0).toLocaleString() + '원</td>' +
                '<td>' + cancelAction + '</td>' +
                '</tr>';
        }).join('');
        $('#reservationResults').html(rows || '<tr><td colspan="6" class="text-center text-muted">검색 결과 없음</td></tr>');
    });
}

function cancelReservation(reservationId) {
    Swal.fire({ title:'취소 확인', text:'이 예약을 취소하시겠습니까?', icon:'warning',
        showCancelButton:true, confirmButtonText:'취소 처리', cancelButtonText:'닫기', confirmButtonColor:'#dc3545'
    }).then(function(r) {
        if (!r.isConfirmed) return;
        $.post('/backoffice/staff/api/reservations/' + reservationId + '/cancel')
            .done(function(result) {
                Swal.fire({ icon: 'success', text: result.message });
                loadReservations();
            }).fail(function(xhr) {
                Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
            });
    });
}
</script>
