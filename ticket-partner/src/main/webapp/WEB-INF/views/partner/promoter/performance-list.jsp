<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-panel mb-4">
    <div class="portal-section-title">
        <div>
            <h3>Performance pipeline</h3>
            <p>Create drafts, build seat plans, and send items to review.</p>
        </div>
        <div class="d-flex gap-2">
            <select id="approvalStatusFilter" class="form-select form-select-sm">
                <option value="">All statuses</option>
                <option value="DRAFT">Draft</option>
                <option value="REVIEW">Review</option>
                <option value="APPROVED">Approved</option>
                <option value="REJECTED">Rejected</option>
                <option value="PUBLISHED">Published</option>
            </select>
            <a class="btn btn-primary btn-sm" href="/partner/promoter/performances/new">New draft</a>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>Performance</th>
                <th>Status</th>
                <th>Open at</th>
                <th>Schedules</th>
                <th>Seat plan</th>
                <th>Actions</th>
            </tr>
            </thead>
            <tbody id="performanceRows"></tbody>
        </table>
    </div>
</section>

<script>
function loadPromoterPerformances() {
    $.get('/partner/promoter/api/performances', {
        approvalStatus: $('#approvalStatusFilter').val()
    }).done(function(response) {
        const rows = (response.list || []).map(function(item) {
            const canSubmit = item.approvalStatus === 'DRAFT' || item.approvalStatus === 'REJECTED';
            return `
                <tr>
                    <td>
                        <strong>${item.title}</strong>
                        <div class="portal-meta">${item.category} · ${item.venueName || '-'}</div>
                    </td>
                    <td><span class="badge-status badge-${item.approvalStatus}">${item.approvalStatus}</span></td>
                    <td>${item.ticketOpenAt || '-'}</td>
                    <td>
                        <button class="btn btn-outline-secondary btn-sm" onclick="addQuickSchedule(${item.performanceId})">Add schedule</button>
                    </td>
                    <td>
                        <button class="btn btn-outline-secondary btn-sm" onclick="generateSeats(${item.performanceId})">Generate seats</button>
                    </td>
                    <td class="d-flex gap-2">
                        ${canSubmit ? `<button class="btn btn-primary btn-sm" onclick="submitReview(${item.performanceId})">Submit review</button>` : ''}
                    </td>
                </tr>`;
        }).join('');
        $('#performanceRows').html(rows || '<tr><td colspan="6" class="text-center text-muted">No performances found.</td></tr>');
    });
}

function submitReview(performanceId) {
    $.post('/partner/promoter/api/performances/' + performanceId + '/submit')
        .done(function(result) {
            Swal.fire({ icon: 'success', text: result.message });
            loadPromoterPerformances();
        })
        .fail(function(xhr) {
            Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
        });
}

function generateSeats(performanceId) {
    $.post('/partner/promoter/api/performances/' + performanceId + '/seats')
        .done(function(result) {
            Swal.fire({ icon: 'success', text: result.message });
        })
        .fail(function(xhr) {
            Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
        });
}

function addQuickSchedule(performanceId) {
    Swal.fire({
        title: 'Add schedule',
        html: `
            <input id="scheduleDate" type="date" class="swal2-input">
            <input id="scheduleTime" type="time" class="swal2-input">
        `,
        focusConfirm: false,
        preConfirm: function() {
            return {
                showDate: document.getElementById('scheduleDate').value,
                showTime: document.getElementById('scheduleTime').value
            };
        }
    }).then(function(result) {
        if (!result.isConfirmed) {
            return;
        }
        $.ajax({
            url: '/partner/promoter/api/performances/' + performanceId + '/schedules',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify(result.value)
        }).done(function(payload) {
            Swal.fire({ icon: 'success', text: payload.message });
        }).fail(function(xhr) {
            Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
        });
    });
}

$('#approvalStatusFilter').on('change', loadPromoterPerformances);
$(loadPromoterPerformances);
</script>
