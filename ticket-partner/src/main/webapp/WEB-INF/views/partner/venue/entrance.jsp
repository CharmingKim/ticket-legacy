<%@ page contentType="text/html;charset=UTF-8" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>Entrance desk</h3>
            <p>Search confirmed reservations and register check-ins for day-of-show operations.</p>
        </div>
        <div class="d-flex gap-2">
            <input id="showDate" type="date" class="form-control form-control-sm" value="${today}" />
            <input id="keyword" class="form-control form-control-sm" placeholder="Reservation no, guest, phone, title" />
            <button class="btn btn-primary btn-sm" onclick="loadEntranceRows()">Search</button>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>Reservation</th>
                <th>Guest</th>
                <th>Performance</th>
                <th>Schedule</th>
                <th>Seats</th>
                <th>Check-in</th>
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
        const html = (rows || []).map(function(row) {
            const checkedIn = row.checked_in_at ? `Checked in at ${row.checked_in_at}` : '';
            const action = row.checked_in_at
                ? '<span class="badge text-bg-success">Checked in</span>'
                : `<button class="btn btn-primary btn-sm" onclick="checkIn('${row.reservation_no}')">Check in</button>`;
            return `
                <tr>
                    <td><strong>${row.reservation_no}</strong><div class="portal-meta">${checkedIn}</div></td>
                    <td>${row.member_name}<div class="portal-meta">${row.member_phone}</div></td>
                    <td>${row.performance_title}</td>
                    <td>${row.show_date} ${row.show_time}</td>
                    <td>${row.seat_summary || '-'}</td>
                    <td>${action}</td>
                </tr>`;
        }).join('');
        $('#entranceRows').html(html || '<tr><td colspan="6" class="text-center text-muted">No confirmed reservations found.</td></tr>');
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
        Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
    });
}

$(loadEntranceRows);
</script>
