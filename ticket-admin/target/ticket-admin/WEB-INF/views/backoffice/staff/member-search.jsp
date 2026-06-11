<%@ page contentType="text/html;charset=UTF-8" %>
<section class="portal-panel">
    <div class="portal-section-title">
        <div>
            <h3>회원 조회</h3>
            <p>역할, 상태, 키워드로 회원을 검색하고 계정 상태를 변경합니다.</p>
        </div>
        <div class="d-flex gap-2">
            <input id="memberKeyword" class="form-control form-control-sm" placeholder="이름, 이메일, 전화번호" />
            <select id="memberRole" class="form-select form-select-sm">
                <option value="">전체 역할</option>
                <option value="USER">일반회원</option>
                <option value="PROMOTER">기획사</option>
                <option value="VENUE_MANAGER">공연장담당자</option>
                <option value="STAFF">스태프</option>
            </select>
            <select id="memberStatus" class="form-select form-select-sm">
                <option value="">전체 상태</option>
                <option value="ACTIVE">활성</option>
                <option value="SUSPENDED">정지</option>
                <option value="DORMANT">휴면</option>
                <option value="WITHDRAWN">탈퇴</option>
                <option value="PENDING_APPROVAL">승인대기</option>
            </select>
            <button class="btn btn-primary btn-sm" onclick="loadMembers()">검색</button>
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
                <th>상태변경</th>
            </tr>
            </thead>
            <tbody id="memberResults"></tbody>
        </table>
    </div>
</section>

<script>
var ROLE_KO   = { USER:'일반회원', PROMOTER:'기획사', VENUE_MANAGER:'공연장담당자', STAFF:'스태프', SUPER_ADMIN:'최고관리자' };
var STATUS_KO = { ACTIVE:'활성', SUSPENDED:'정지', DORMANT:'휴면', WITHDRAWN:'탈퇴', PENDING_APPROVAL:'승인대기' };

var FSM_TRANSITIONS = {
    PENDING_APPROVAL: [['ACTIVE','활성(승인)'],   ['SUSPENDED','즉시 정지']],
    ACTIVE:           [['SUSPENDED','정지'],       ['DORMANT','휴면 처리'],   ['WITHDRAWN','강제 탈퇴']],
    SUSPENDED:        [['ACTIVE','정지 해제'],     ['WITHDRAWN','강제 탈퇴']],
    DORMANT:          [['ACTIVE','재활성화']],
    WITHDRAWN:        []
};

function buildStatusSelect(memberId, currentStatus) {
    var options = FSM_TRANSITIONS[currentStatus] || [];
    if (options.length === 0) return '<span class="text-muted small">변경 불가</span>';
    var html = '<select class="form-select form-select-sm" onchange="updateMemberStatus(' + memberId + ', this.value)">' +
               '<option value="" disabled selected hidden>상태변경</option>';
    options.forEach(function(pair) {
        html += '<option value="' + pair[0] + '">' + pair[1] + '</option>';
    });
    return html + '</select>';
}

function loadMembers() {
    $.get('/backoffice/staff/api/members', {
        keyword: $('#memberKeyword').val(),
        role: $('#memberRole').val(),
        status: $('#memberStatus').val()
    }).done(function(response) {
        var list = (response.data && response.data.content) || [];
        var rows = list.map(function(item) {
            return '<tr>' +
                '<td>' + (item.name || '-') + '<div class="portal-meta">' + (item.phone || '') + '</div></td>' +
                '<td>' + item.email + '</td>' +
                '<td>' + (ROLE_KO[item.role] || item.role) + '</td>' +
                '<td>' + (STATUS_KO[item.status] || item.status) + '</td>' +
                '<td>' + buildStatusSelect(item.memberId, item.status) + '</td>' +
                '</tr>';
        }).join('');
        $('#memberResults').html(rows || '<tr><td colspan="5" class="text-center text-muted">검색 결과 없음</td></tr>');
    });
}

function updateMemberStatus(memberId, status) {
    if (!status) return;
    var needsReason = (status === 'WITHDRAWN' || status === 'SUSPENDED');
    var isWithdrawn = (status === 'WITHDRAWN');
    if (needsReason) {
        Swal.fire({
            icon: isWithdrawn ? 'warning' : 'question',
            title: isWithdrawn ? '강제 탈퇴 처리' : '정지 처리',
            html: (isWithdrawn ? '탈퇴 처리는 <b>되돌릴 수 없습니다</b>.<br>' : '') + '처리 사유를 입력해주세요.',
            input: 'textarea', inputPlaceholder: '사유 입력 (최대 500자)',
            inputAttributes: { maxlength: 500 },
            showCancelButton: true,
            confirmButtonColor: isWithdrawn ? '#d33' : '#f0ad4e',
            confirmButtonText: isWithdrawn ? '탈퇴 처리' : '정지 처리',
            cancelButtonText: '취소',
            preConfirm: function(reason) {
                if (!reason || !reason.trim()) { Swal.showValidationMessage('사유는 필수입니다.'); return false; }
                return reason.trim();
            }
        }).then(function(result) {
            if (result.isConfirmed) doStatusChange(memberId, status, result.value);
            else loadMembers();
        });
        return;
    }
    doStatusChange(memberId, status, null);
}

function doStatusChange(memberId, status, reason) {
    $.ajax({
        url: '/backoffice/staff/api/members/' + memberId + '/status',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ status: status, reason: reason })
    }).done(function(result) {
        Swal.fire({ icon: 'success', text: result.message || '상태가 변경되었습니다.', timer: 1500, showConfirmButton: false });
        loadMembers();
    }).fail(function(xhr) {
        var msg = (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText;
        Swal.fire({ icon: 'error', text: msg });
        loadMembers();
    });
}
</script>
