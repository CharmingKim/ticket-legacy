<%@ page contentType="text/html;charset=UTF-8" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>Member search</h3>
            <p>Filter by role, status, or keyword and update account status when support actions are required.</p>
        </div>
        <div class="d-flex gap-2">
            <input id="memberKeyword" class="form-control form-control-sm" placeholder="Name, email, phone" />
            <select id="memberRole" class="form-select form-select-sm">
                <option value="">All roles</option>
                <option value="USER">User</option>
                <option value="PROMOTER">Promoter</option>
                <option value="VENUE_MANAGER">Venue manager</option>
                <option value="STAFF">Staff</option>
            </select>
            <select id="memberStatus" class="form-select form-select-sm">
                <option value="">All statuses</option>
                <option value="ACTIVE">Active</option>
                <option value="DORMANT">Dormant</option>
                <option value="WITHDRAWN">Withdrawn</option>
                <option value="PENDING_APPROVAL">Pending approval</option>
            </select>
            <button class="btn btn-primary btn-sm" onclick="loadMembers()">Search</button>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th>Status</th>
                <th>Change status</th>
            </tr>
            </thead>
            <tbody id="memberResults"></tbody>
        </table>
    </div>
</section>

<script>
function loadMembers() {
    $.get('/backoffice/staff/api/members', {
        keyword: $('#memberKeyword').val(),
        role: $('#memberRole').val(),
        status: $('#memberStatus').val()
    }).done(function(response) {
        const rows = (response.list || []).map(function(item) {
            return `
                <tr>
                    <td>${item.name}<div class="portal-meta">${item.phone || ''}</div></td>
                    <td>${item.email}</td>
                    <td>${item.role}</td>
                    <td>${item.status}</td>
                    <td>
                        <select class="form-select form-select-sm" onchange="updateMemberStatus(${item.memberId}, this.value)">
                            <option value="">Choose</option>
                            <option value="ACTIVE">Active</option>
                            <option value="DORMANT">Dormant</option>
                            <option value="WITHDRAWN">Withdrawn</option>
                        </select>
                    </td>
                </tr>`;
        }).join('');
        $('#memberResults').html(rows || '<tr><td colspan="5" class="text-center text-muted">No members found.</td></tr>');
    });
}

function updateMemberStatus(memberId, status) {
    if (!status) {
        return;
    }
    $.ajax({
        url: '/backoffice/staff/api/members/' + memberId + '/status',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ status: status })
    }).done(function(result) {
        Swal.fire({ icon: 'success', text: result.message });
        loadMembers();
    }).fail(function(xhr) {
        Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
    });
}
</script>
