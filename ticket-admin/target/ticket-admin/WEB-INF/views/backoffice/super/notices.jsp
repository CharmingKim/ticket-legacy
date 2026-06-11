<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<div class="p-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h4 class="mb-0"><i class="bi bi-megaphone-fill text-primary me-2"></i>공지사항 관리</h4>
    <button class="btn btn-primary btn-sm" onclick="showCreateModal()">
      <i class="bi bi-plus-circle me-1"></i>공지 등록
    </button>
  </div>

  <div class="row g-2 mb-3">
    <div class="col-auto">
      <select class="form-select form-select-sm" id="filterType" onchange="loadNotices()">
        <option value="">전체</option>
        <option value="SYSTEM">시스템</option>
        <option value="EVENT">이벤트</option>
        <option value="MAINTENANCE">점검</option>
      </select>
    </div>
  </div>

  <div class="card border-0 shadow-sm">
    <div class="card-body p-0">
      <table class="table table-hover mb-0">
        <thead class="table-light">
          <tr><th>ID</th><th>제목</th><th>타입</th><th>대상</th><th>고정</th><th>조회수</th><th>등록일</th><th>관리</th></tr>
        </thead>
        <tbody id="noticeTbody"></tbody>
      </table>
    </div>
  </div>
  <div id="noticePaging" class="mt-3 d-flex justify-content-center gap-2"></div>

  <!-- 등록/수정 모달 -->
  <div class="modal fade" id="noticeModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
      <div class="modal-content">
        <div class="modal-header bg-primary text-white">
          <h5 class="modal-title" id="noticeModalTitle">공지사항 등록</h5>
          <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <input type="hidden" id="editNoticeId">
          <div class="mb-2">
            <label class="form-label">제목 *</label>
            <input type="text" class="form-control" id="noticeTitle">
          </div>
          <div class="mb-2">
            <label class="form-label">내용 *</label>
            <textarea class="form-control" id="noticeContent" rows="6"></textarea>
          </div>
          <div class="row g-2">
            <div class="col-md-4">
              <label class="form-label">유형</label>
              <select class="form-select" id="noticeType">
                <option value="SYSTEM">시스템</option>
                <option value="EVENT">이벤트</option>
                <option value="PERFORMANCE">공연</option>
                <option value="MAINTENANCE">점검</option>
              </select>
            </div>
            <div class="col-md-4">
              <label class="form-label">대상</label>
              <select class="form-select" id="noticeTarget">
                <option value="ALL">전체</option>
                <option value="USER">일반 사용자</option>
                <option value="PROMOTER">기획사</option>
                <option value="VENUE_MANAGER">공연장 담당자</option>
              </select>
            </div>
            <div class="col-md-4 d-flex align-items-end">
              <div class="form-check">
                <input class="form-check-input" type="checkbox" id="noticePinned">
                <label class="form-check-label" for="noticePinned">상단 고정</label>
              </div>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
          <button class="btn btn-primary" onclick="saveNotice()">저장</button>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
var noticePage = 1;
$(document).ready(function() { loadNotices(); });

function loadNotices(page) {
  noticePage = page || 1;
  $.get('/backoffice/super/api/notices', { noticeType: $('#filterType').val(), page: noticePage })
    .done(function(data) {
      var rows = '';
      (data.list || []).forEach(function(n) {
        var typeBadge = {SYSTEM:'secondary',EVENT:'success',MAINTENANCE:'danger',PERFORMANCE:'info'}[n.noticeType] || 'secondary';
        rows += '<tr>' +
          '<td>' + n.noticeId + '</td>' +
          '<td><b>' + n.title + '</b></td>' +
          '<td><span class="badge bg-' + typeBadge + '">' + n.noticeType + '</span></td>' +
          '<td>' + n.targetRole + '</td>' +
          '<td>' + (n.pinned ? '<i class="bi bi-pin-fill text-danger"></i>' : '-') + '</td>' +
          '<td>' + n.viewCount + '</td>' +
          '<td class="small">' + fmtDate(n.createdAt) + '</td>' +
          '<td>' +
            '<button class="btn btn-xs btn-outline-secondary me-1" onclick="editNotice(' + n.noticeId + ')">수정</button>' +
            '<button class="btn btn-xs btn-outline-danger" onclick="deleteNotice(' + n.noticeId + ')">삭제</button>' +
          '</td></tr>';
      });
      $('#noticeTbody').html(rows || '<tr><td colspan="8" class="text-center text-muted">공지사항이 없습니다.</td></tr>');
      renderPaging(data.total, noticePage, 20, loadNotices, '#noticePaging');
    });
}

function showCreateModal() {
  $('#editNoticeId').val(''); $('#noticeTitle').val(''); $('#noticeContent').val('');
  $('#noticeType').val('SYSTEM'); $('#noticeTarget').val('ALL'); $('#noticePinned').prop('checked',false);
  $('#noticeModalTitle').text('공지사항 등록');
  new bootstrap.Modal($('#noticeModal')[0]).show();
}

function editNotice(id) {
  $.get('/backoffice/super/api/notices', { page: 1, noticeType:'' }).done(function(data) {
    var n = (data.list||[]).find(function(x){ return x.noticeId == id; });
    if (!n) return;
    $('#editNoticeId').val(n.noticeId); $('#noticeTitle').val(n.title); $('#noticeContent').val(n.content);
    $('#noticeType').val(n.noticeType); $('#noticeTarget').val(n.targetRole); $('#noticePinned').prop('checked', n.pinned);
    $('#noticeModalTitle').text('공지사항 수정');
    new bootstrap.Modal($('#noticeModal')[0]).show();
  });
}

function saveNotice() {
  var id = $('#editNoticeId').val();
  var body = { title: $('#noticeTitle').val(), content: $('#noticeContent').val(),
    noticeType: $('#noticeType').val(), targetRole: $('#noticeTarget').val(),
    isPinned: $('#noticePinned').is(':checked') };
  if (!body.title || !body.content) return Swal.fire('입력 오류', '제목과 내용을 입력하세요.', 'warning');
  var url = id ? '/backoffice/super/api/notices/' + id : '/backoffice/super/api/notices';
  var method = id ? 'PATCH' : 'POST';
  $.ajax({ url:url, type:method, contentType:'application/json', data:JSON.stringify(body) })
    .done(function(r) {
      Swal.fire('완료', r.message, 'success');
      bootstrap.Modal.getInstance($('#noticeModal')[0]).hide(); loadNotices();
    }).fail(function(xhr) { Swal.fire('오류', xhr.responseJSON?.message || '저장 실패', 'error'); });
}

function deleteNotice(id) {
  Swal.fire({title:'삭제', text:'이 공지사항을 삭제하시겠습니까?', icon:'warning',
    showCancelButton:true, confirmButtonText:'삭제', cancelButtonText:'취소', confirmButtonColor:'#dc3545'})
    .then(function(r) {
      if (!r.isConfirmed) return;
      $.ajax({ url:'/backoffice/super/api/notices/' + id, type:'DELETE' })
        .done(function(r) { Swal.fire('완료', r.message, 'success'); loadNotices(); });
    });
}

// LocalDateTime이 배열([2026,4,17,...]) 또는 문자열("2026-04-17T...")로 올 수 있음
function fmtDate(val) {
  if (!val) return '-';
  if (Array.isArray(val)) {
    var y = val[0], m = String(val[1]).padStart(2,'0'), d = String(val[2]).padStart(2,'0');
    return y + '-' + m + '-' + d;
  }
  return String(val).substring(0, 10);
}

function renderPaging(total, page, size, callback, target) {
  var pages = Math.ceil(total / size);
  if (pages <= 1) { $(target).html(''); return; }
  var html = '';
  for (var i = 1; i <= pages; i++) {
    html += '<button class="btn btn-sm ' + (i===page?'btn-primary':'btn-outline-secondary') + '" onclick="' +
            callback.name + '(' + i + ')">' + i + '</button>';
  }
  $(target).html(html);
}
</script>
