<%@ page contentType="text/html;charset=UTF-8" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>Member administration</h3>
            <p>Search every account across consumer, partner, and staff roles.</p>
        </div>
        <div class="d-flex gap-2">
            <input id="adminMemberKeyword" class="form-control form-control-sm" placeholder="Name, email, phone" />
            <select id="adminMemberRole" class="form-select form-select-sm">
                <option value="">All roles</option>
                <option value="USER">User</option>
                <option value="PROMOTER">Promoter</option>
                <option value="VENUE_MANAGER">Venue manager</option>
                <option value="STAFF">Staff</option>
                <option value="SUPER_ADMIN">Super admin</option>
            </select>
            <select id="adminMemberStatus" class="form-select form-select-sm">
                <option value="">All statuses</option>
                <option value="ACTIVE">Active</option>
                <option value="DORMANT">Dormant</option>
                <option value="WITHDRAWN">Withdrawn</option>
                <option value="PENDING_APPROVAL">Pending approval</option>
            </select>
            <button class="btn btn-primary btn-sm" onclick="loadAdminMembers()">Search</button>
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
                <th></th>
            </tr>
            </thead>
            <tbody id="adminMemberRows"></tbody>
        </table>
    </div>
</section>

<script>
function loadAdminMembers() {
    $.get('/backoffice/super/api/members', {
        keyword: $('#adminMemberKeyword').val(),
        role: $('#adminMemberRole').val(),
        status: $('#adminMemberStatus').val()
    }).done(function(response) {
        const rows = (response.list || []).map(function(item) {
            return `
                <tr>
                    <td>${item.name}<div class="portal-meta">${item.phone || ''}</div></td>
                    <td>${item.email}</td>
                    <td>${item.role}</td>
                    <td>${item.status}</td>
                    <td>
                        <select class="form-select form-select-sm" onchange="updateAdminMemberStatus(${item.memberId}, this.value)">
                            <option value="">Change</option>
                            <option value="ACTIVE">Active</option>
                            <option value="DORMANT">Dormant</option>
                            <option value="WITHDRAWN">Withdrawn</option>
                            <option value="PENDING_APPROVAL">Pending approval</option>
                        </select>
                    </td>
                </tr>`;
        }).join('');
        $('#adminMemberRows').html(rows || '<tr><td colspan="5" class="text-center text-muted">No members found.</td></tr>');
    });
}

function updateAdminMemberStatus(memberId, status) {
    if (!status) {
        return;
    }
    $.ajax({
        url: '/backoffice/super/api/members/' + memberId + '/status',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ status: status })
    }).done(function(result) {
        Swal.fire({ icon: 'success', text: result.message });
        loadAdminMembers();
    }).fail(function(xhr) {
        Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
    });
}

$(loadAdminMembers);
</script>
