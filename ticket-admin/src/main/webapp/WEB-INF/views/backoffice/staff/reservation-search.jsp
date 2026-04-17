<%@ page contentType="text/html;charset=UTF-8" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>Reservation search</h3>
            <p>Find reservations by code, guest, email, or show title and cancel them when recovery is needed.</p>
        </div>
        <div class="d-flex gap-2">
            <input id="reservationKeyword" class="form-control form-control-sm" placeholder="Search keyword" />
            <select id="reservationStatus" class="form-select form-select-sm">
                <option value="">All statuses</option>
                <option value="PENDING">Pending</option>
                <option value="CONFIRMED">Confirmed</option>
                <option value="CANCELLED">Cancelled</option>
                <option value="REFUNDED">Refunded</option>
            </select>
            <button class="btn btn-primary btn-sm" onclick="loadReservations()">Search</button>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>Reservation</th>
                <th>Guest</th>
                <th>Show</th>
                <th>Status</th>
                <th>Amount</th>
                <th></th>
            </tr>
            </thead>
            <tbody id="reservationResults"></tbody>
        </table>
    </div>
</section>

<script>
function loadReservations() {
    $.get('/backoffice/staff/api/reservations', {
        keyword: $('#reservationKeyword').val(),
        status: $('#reservationStatus').val()
    }).done(function(response) {
        const rows = (response.list || []).map(function(item) {
            const cancelAction = (item.status === 'PENDING' || item.status === 'CONFIRMED')
                ? `<button class="btn btn-outline-danger btn-sm" onclick="cancelReservation(${item.reservationId})">Cancel</button>`
                : '';
            return `
                <tr>
                    <td><strong>${item.reservationNo}</strong><div class="portal-meta">${item.createdAt || ''}</div></td>
                    <td>${item.memberName}<div class="portal-meta">${item.memberEmail}</div></td>
                    <td>${item.performanceTitle}<div class="portal-meta">${item.showDate} ${item.showTime}</div></td>
                    <td>${item.status}</td>
                    <td>${item.totalAmount}</td>
                    <td>${cancelAction}</td>
                </tr>`;
        }).join('');
        $('#reservationResults').html(rows || '<tr><td colspan="6" class="text-center text-muted">No matches found.</td></tr>');
    });
}

function cancelReservation(reservationId) {
    $.post('/backoffice/staff/api/reservations/' + reservationId + '/cancel')
        .done(function(result) {
            Swal.fire({ icon: 'success', text: result.message });
            loadReservations();
        }).fail(function(xhr) {
            Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
        });
}
</script>
