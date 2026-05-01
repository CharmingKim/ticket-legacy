<%@ page contentType="text/html;charset=UTF-8" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>회원 관리</h3>
            <p>전체 역할(일반회원, 파트너, 스태프)의 계정을 검색합니다.</p>
        </div>
        <div class="d-flex gap-2 flex-wrap">
            <input id="adminMemberKeyword" class="form-control form-control-sm" placeholder="이름, 이메일, 전화번호" />
            <select id="adminMemberRole" class="form-select form-select-sm">
                <option value="">전체 역할</option>
                <option value="USER">일반회원</option>
                <option value="PROMOTER">기획사</option>
                <option value="VENUE_MANAGER">공연장담당자</option>
                <option value="STAFF">스태프</option>
                <option value="SUPER_ADMIN">최고관리자</option>
            </select>
            <select id="adminMemberStatus" class="form-select form-select-sm">
                <option value="">전체 상태</option>
                <option value="ACTIVE">활성</option>
                <option value="SUSPENDED">정지</option>
                <option value="DORMANT">휴면</option>
                <option value="WITHDRAWN">탈퇴</option>
                <option value="PENDING_APPROVAL">승인대기</option>
            </select>
            <button class="btn btn-primary btn-sm" onclick="loadAdminMembers()">검색</button>
            <button class="btn btn-success btn-sm" data-bs-toggle="modal" data-bs-target="#createPromoterModal">
                <i class="bi bi-plus-lg"></i> 기획사 추가
            </button>
            <button class="btn btn-outline-success btn-sm" data-bs-toggle="modal" data-bs-target="#createVmModal">
                <i class="bi bi-plus-lg"></i> 공연장담당자 추가
            </button>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>이름</th>
                <th>이메일</th>
                <th>역할</th>
                <th>상태</th>
                <th></th>
            </tr>
            </thead>
            <tbody id="adminMemberRows"></tbody>
        </table>
    </div>
</section>

<!-- 기획사 생성 모달 -->
<div class="modal fade" id="createPromoterModal" tabindex="-1">
  <div class="modal-dialog"><div class="modal-content">
    <div class="modal-header"><h5 class="modal-title">기획사 계정 생성</h5>
      <button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
    <div class="modal-body">
      <div class="mb-2"><label class="form-label small">이메일 *</label>
        <input id="pp_email" type="email" class="form-control form-control-sm" /></div>
      <div class="mb-2"><label class="form-label small">비밀번호 *</label>
        <input id="pp_password" type="password" class="form-control form-control-sm" /></div>
      <div class="mb-2"><label class="form-label small">담당자 이름 *</label>
        <input id="pp_name" class="form-control form-control-sm" /></div>
      <div class="mb-2"><label class="form-label small">전화번호</label>
        <input id="pp_phone" class="form-control form-control-sm" placeholder="010-0000-0000" /></div>
      <hr/>
      <div class="mb-2"><label class="form-label small">회사명 *</label>
        <input id="pp_companyName" class="form-control form-control-sm" /></div>
      <div class="mb-2"><label class="form-label small">사업자등록번호</label>
        <input id="pp_businessRegNo" class="form-control form-control-sm" placeholder="000-00-00000" /></div>
      <div class="mb-2"><label class="form-label small">대표자</label>
        <input id="pp_representative" class="form-control form-control-sm" /></div>
      <div class="small text-muted">생성 후 기획사 탭 또는 목록에서 승인이 필요합니다.</div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-secondary btn-sm" data-bs-dismiss="modal">취소</button>
      <button class="btn btn-primary btn-sm" onclick="submitCreatePromoter()">생성</button>
    </div>
  </div></div>
</div>

<!-- 공연장 담당자 생성 모달 -->
<div class="modal fade" id="createVmModal" tabindex="-1">
  <div class="modal-dialog"><div class="modal-content">
    <div class="modal-header"><h5 class="modal-title">공연장 담당자 계정 생성</h5>
      <button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
    <div class="modal-body">
      <div class="mb-2"><label class="form-label small">이메일 *</label>
        <input id="vm_email" type="email" class="form-control form-control-sm" /></div>
      <div class="mb-2"><label class="form-label small">비밀번호 *</label>
        <input id="vm_password" type="password" class="form-control form-control-sm" /></div>
      <div class="mb-2"><label class="form-label small">이름 *</label>
        <input id="vm_name" class="form-control form-control-sm" /></div>
      <div class="mb-2"><label class="form-label small">전화번호</label>
        <input id="vm_phone" class="form-control form-control-sm" /></div>
      <hr/>
      <div class="mb-2"><label class="form-label small">담당 공연장 *</label>
        <select id="vm_venueId" class="form-select form-select-sm"><option value="">선택</option></select></div>
      <div class="mb-2"><label class="form-label small">부서</label>
        <input id="vm_department" class="form-control form-control-sm" /></div>
      <div class="mb-2"><label class="form-label small">직책</label>
        <input id="vm_position" class="form-control form-control-sm" /></div>
    </div>
    <div class="modal-footer">
      <button class="btn btn-secondary btn-sm" data-bs-dismiss="modal">취소</button>
      <button class="btn btn-primary btn-sm" onclick="submitCreateVm()">생성</button>
    </div>
  </div></div>
</div>

<script>
var ROLE_KO      = { USER:'일반회원', PROMOTER:'기획사', VENUE_MANAGER:'공연장담당자', STAFF:'스태프', SUPER_ADMIN:'최고관리자' };
var STATUS_KO    = { ACTIVE:'활성', SUSPENDED:'정지', DORMANT:'휴면', WITHDRAWN:'탈퇴', PENDING_APPROVAL:'승인대기' };
var STATUS_CLASS = { ACTIVE:'text-success fw-semibold', SUSPENDED:'text-danger fw-semibold', DORMANT:'text-secondary', WITHDRAWN:'text-muted text-decoration-line-through', PENDING_APPROVAL:'text-warning fw-semibold' };

function formatDate(iso) {
    if (!iso) return '';
    return iso.substring(0, 10);
}

function buildStatusCell(item) {
    var label = STATUS_KO[item.status] || item.status;
    var cls   = STATUS_CLASS[item.status] || '';
    var html  = '<span class="' + cls + '">' + label + '</span>';
    if (item.status === 'WITHDRAWN' && item.withdrawnAt) {
        html += '<div class="portal-meta">탈퇴일 ' + formatDate(item.withdrawnAt) + '</div>';
    }
    if (item.status === 'DORMANT' && item.lastLoginAt) {
        html += '<div class="portal-meta">마지막 로그인 ' + formatDate(item.lastLoginAt) + '</div>';
    }
    return html;
}

/* 현재 상태 → 어드민이 선택 가능한 다음 상태 목록 (DORMANT는 시스템 자동전환이므로 제외) */
var FSM_TRANSITIONS = {
    PENDING_APPROVAL: [['ACTIVE','활성(승인)'],   ['SUSPENDED','즉시 정지']],
    ACTIVE:           [['SUSPENDED','정지'],       ['DORMANT','휴면 처리'],   ['WITHDRAWN','강제 탈퇴']],
    SUSPENDED:        [['ACTIVE','정지 해제'],     ['WITHDRAWN','강제 탈퇴']],
    DORMANT:          [['ACTIVE','재활성화']],
    WITHDRAWN:        []
};

function buildStatusSelect(memberId, currentStatus) {
    var options = FSM_TRANSITIONS[currentStatus] || [];
    if (options.length === 0) {
        return '<span class="text-muted small">변경 불가</span>';
    }
    var html = '<select class="form-select form-select-sm" onchange="updateAdminMemberStatus(' + memberId + ', this.value, \'' + currentStatus + '\')">' +
               '<option value="" disabled selected hidden>상태변경</option>';
    options.forEach(function(pair) {
        html += '<option value="' + pair[0] + '">' + pair[1] + '</option>';
    });
    return html + '</select>';
}

function loadAdminMembers() {
    $.get('/backoffice/super/api/members', {
        keyword: $('#adminMemberKeyword').val(),
        role: $('#adminMemberRole').val(),
        status: $('#adminMemberStatus').val()
    }).done(function(response) {
        var list = (response.data && response.data.content) || [];
        var rows = list.map(function(item) {
            var rowClass = item.status === 'WITHDRAWN' ? ' class="text-muted"' : '';
            return '<tr' + rowClass + '>' +
                '<td>' + (item.name || '-') + '<div class="portal-meta">' + (item.phone || '') + '</div></td>' +
                '<td>' + item.email + '</td>' +
                '<td>' + (ROLE_KO[item.role] || item.role) + '</td>' +
                '<td>' + buildStatusCell(item) + '</td>' +
                '<td>' + buildStatusSelect(item.memberId, item.status) + '</td>' +
                '</tr>';
        }).join('');
        $('#adminMemberRows').html(rows || '<tr><td colspan="5" class="text-center text-muted">검색 결과 없음</td></tr>');
    });
}

function updateAdminMemberStatus(memberId, status, currentStatus) {
    if (!status) return;
    var needsReason = (status === 'WITHDRAWN' || status === 'SUSPENDED');
    var isWithdrawn = (status === 'WITHDRAWN');

    if (needsReason) {
        Swal.fire({
            icon: isWithdrawn ? 'warning' : 'question',
            title: isWithdrawn ? '강제 탈퇴 처리' : '정지 처리',
            html: (isWithdrawn ? '탈퇴 처리는 <b>되돌릴 수 없습니다</b>.<br>' : '') + '처리 사유를 입력해주세요.',
            input: 'textarea',
            inputPlaceholder: '사유 입력 (최대 500자)',
            inputAttributes: { maxlength: 500 },
            showCancelButton: true,
            confirmButtonColor: isWithdrawn ? '#d33' : '#f0ad4e',
            confirmButtonText: isWithdrawn ? '탈퇴 처리' : '정지 처리',
            cancelButtonText: '취소',
            preConfirm: function(reason) {
                if (!reason || !reason.trim()) {
                    Swal.showValidationMessage('사유는 필수입니다.');
                    return false;
                }
                return reason.trim();
            }
        }).then(function(result) {
            if (result.isConfirmed) doStatusChange(memberId, status, result.value);
            else loadAdminMembers();
        });
        return;
    }
    doStatusChange(memberId, status, null);
}

function doStatusChange(memberId, status, reason) {
    $.ajax({
        url: '/backoffice/super/api/members/' + memberId + '/status',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ status: status, reason: reason })
    }).done(function(result) {
        Swal.fire({ icon: 'success', text: result.message, timer: 1500, showConfirmButton: false });
        loadAdminMembers();
    }).fail(function(xhr) {
        var msg = (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText;
        Swal.fire({ icon: 'error', text: msg });
        loadAdminMembers();
    });
}

function loadVenueOptions() {
    $.get('/backoffice/super/api/venues').done(function(list) {
        var opts = '<option value="">선택</option>';
        (list || []).forEach(function(v) {
            opts += '<option value="' + v.venueId + '">' + v.name + '</option>';
        });
        $('#vm_venueId').html(opts);
    });
}

function submitCreatePromoter() {
    const body = {
        email: $('#pp_email').val().trim(),
        password: $('#pp_password').val(),
        name: $('#pp_name').val().trim(),
        phone: $('#pp_phone').val().trim(),
        companyName: $('#pp_companyName').val().trim(),
        businessRegNo: $('#pp_businessRegNo').val().trim(),
        representative: $('#pp_representative').val().trim()
    };
    if (!body.email || !body.password || !body.name || !body.companyName) {
        Swal.fire({ icon: 'warning', text: '필수 항목(이메일/비밀번호/이름/회사명)을 입력해주세요.' });
        return;
    }
    $.ajax({
        url: '/backoffice/super/api/promoters',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify(body)
    }).done(function(r) {
        Swal.fire({ icon: 'success', text: r.message });
        bootstrap.Modal.getInstance(document.getElementById('createPromoterModal')).hide();
        ['pp_email','pp_password','pp_name','pp_phone','pp_companyName','pp_businessRegNo','pp_representative'].forEach(id => $('#'+id).val(''));
        loadAdminMembers();
    }).fail(function(xhr) {
        Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
    });
}

function submitCreateVm() {
    const venueId = $('#vm_venueId').val();
    const body = {
        email: $('#vm_email').val().trim(),
        password: $('#vm_password').val(),
        name: $('#vm_name').val().trim(),
        phone: $('#vm_phone').val().trim(),
        venueId: venueId ? Number(venueId) : null,
        department: $('#vm_department').val().trim(),
        position: $('#vm_position').val().trim()
    };
    if (!body.email || !body.password || !body.name || !body.venueId) {
        Swal.fire({ icon: 'warning', text: '필수 항목을 입력해주세요.' });
        return;
    }
    $.ajax({
        url: '/backoffice/super/api/venue-managers',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify(body)
    }).done(function(r) {
        Swal.fire({ icon: 'success', text: r.message });
        bootstrap.Modal.getInstance(document.getElementById('createVmModal')).hide();
        ['vm_email','vm_password','vm_name','vm_phone','vm_department','vm_position'].forEach(id => $('#'+id).val(''));
        $('#vm_venueId').val('');
        loadAdminMembers();
    }).fail(function(xhr) {
        Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
    });
}

$(function() {
    loadAdminMembers();
    loadVenueOptions();
});
</script>
