<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<div class="p-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h4 class="mb-0"><i class="bi bi-ticket-perforated-fill text-warning me-2"></i>쿠폰 관리</h4>
    <button class="btn btn-warning btn-sm" onclick="showCreateModal()">
      <i class="bi bi-plus-circle me-1"></i>쿠폰 템플릿 생성
    </button>
  </div>

  <!-- 필터 -->
  <div class="row g-2 mb-3">
    <div class="col-auto">
      <select class="form-select form-select-sm" id="filterActive" onchange="loadTemplates()">
        <option value="">전체</option>
        <option value="true" selected>활성</option>
        <option value="false">비활성</option>
      </select>
    </div>
  </div>

  <!-- 쿠폰 템플릿 목록 -->
  <div class="card border-0 shadow-sm mb-4">
    <div class="card-body p-0">
      <table class="table table-hover mb-0">
        <thead class="table-light">
          <tr>
            <th>ID</th><th>쿠폰명</th><th>타입</th><th>할인</th>
            <th>기획사</th><th>발행/전체</th><th>유효기간</th><th>상태</th><th>관리</th>
          </tr>
        </thead>
        <tbody id="templateTbody"></tbody>
      </table>
    </div>
  </div>

  <!-- 생성 모달 -->
  <div class="modal fade" id="createModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
      <div class="modal-content">
        <div class="modal-header bg-warning text-dark">
          <h5 class="modal-title">쿠폰 템플릿 생성</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <div class="row g-2">
            <div class="col-md-6">
              <label class="form-label">쿠폰명 *</label>
              <input type="text" class="form-control" id="tplName" placeholder="예: 얼리버드 30% 할인">
            </div>
            <div class="col-md-6">
              <label class="form-label">코드 접두어 *</label>
              <input type="text" class="form-control" id="tplPrefix" placeholder="예: EARLY2026" style="text-transform:uppercase">
            </div>
            <div class="col-md-4">
              <label class="form-label">할인 타입 *</label>
              <select class="form-select" id="tplDiscountType" onchange="toggleMaxDiscount()">
                <option value="FIXED">정액(원)</option>
                <option value="PERCENT">정률(%)</option>
              </select>
            </div>
            <div class="col-md-4">
              <label class="form-label">할인 값 *</label>
              <input type="number" class="form-control" id="tplDiscountValue" min="1">
            </div>
            <div class="col-md-4" id="maxDiscountGroup" style="display:none">
              <label class="form-label">최대 할인 금액(원)</label>
              <input type="number" class="form-control" id="tplMaxDiscount" min="0">
            </div>
            <div class="col-md-4">
              <label class="form-label">최소 결제 금액(원)</label>
              <input type="number" class="form-control" id="tplMinAmount" value="0" min="0">
            </div>
            <div class="col-md-4">
              <label class="form-label">발행 수량 *</label>
              <input type="number" class="form-control" id="tplQty" value="100" min="1">
            </div>
            <div class="col-md-4">
              <label class="form-label">기획사 한정 (선택)</label>
              <select class="form-select" id="tplPromoter">
                <option value="">전체 공통</option>
                <c:forEach var="p" items="${promoters}">
                  <option value="${p.promoterId}">${p.companyName}</option>
                </c:forEach>
              </select>
            </div>
            <div class="col-md-6">
              <label class="form-label">유효 시작일 *</label>
              <input type="datetime-local" class="form-control" id="tplValidFrom">
            </div>
            <div class="col-md-6">
              <label class="form-label">유효 종료일 *</label>
              <input type="datetime-local" class="form-control" id="tplValidUntil">
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
          <button class="btn btn-warning" onclick="createTemplate()">생성</button>
        </div>
      </div>
    </div>
  </div>

  <!-- 발급 모달 -->
  <div class="modal fade" id="issueModal" tabindex="-1">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header"><h5 class="modal-title">쿠폰 발급</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <input type="hidden" id="issueTemplateId">
          <label class="form-label">회원 ID (memberId)</label>
          <input type="number" class="form-control" id="issueMemberId" placeholder="발급할 회원의 ID 입력">
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" data-bs-dismiss="modal">취소</button>
          <button class="btn btn-primary" onclick="issueCoupon()">발급</button>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
$(document).ready(function() { loadTemplates(); });

function loadTemplates() {
  var isActive = $('#filterActive').val();
  $.get('/backoffice/super/api/coupons/templates', isActive ? {isActive: isActive} : {})
    .done(function(data) {
      var rows = '';
      (data || []).forEach(function(t) {
        var discStr = t.discountType === 'PERCENT'
          ? t.discountValue + '%' + (t.maxDiscount ? ' (최대 ' + t.maxDiscount.toLocaleString() + '원)' : '')
          : t.discountValue.toLocaleString() + '원';
        rows += '<tr>' +
          '<td>' + t.templateId + '</td>' +
          '<td><b>' + t.name + '</b><br><small class="text-muted">' + t.codePrefix + '-XXXX</small></td>' +
          '<td><span class="badge bg-' + (t.discountType==='PERCENT'?'info':'success') + '">' + t.discountType + '</span></td>' +
          '<td>' + discStr + '</td>' +
          '<td>' + (t.promoterCompanyName || '<span class="text-muted">공통</span>') + '</td>' +
          '<td>' + t.issuedCount + ' / ' + t.totalQuantity + '</td>' +
          '<td class="small">' + fmtDt(t.validFrom) + '<br>~ ' + fmtDt(t.validUntil) + '</td>' +
          '<td><span class="badge bg-' + (t.active?'success':'secondary') + '">' + (t.active?'활성':'비활성') + '</span></td>' +
          '<td><button class="btn btn-xs btn-outline-primary me-1" onclick="openIssueModal(' + t.templateId + ')">발급</button>' +
              (t.active ? '<button class="btn btn-xs btn-outline-danger" onclick="deactivate(' + t.templateId + ')">비활성화</button>' : '') +
          '</td></tr>';
      });
      $('#templateTbody').html(rows || '<tr><td colspan="9" class="text-center text-muted">데이터 없음</td></tr>');
    });
}

function showCreateModal() { new bootstrap.Modal($('#createModal')[0]).show(); }
function openIssueModal(id) { $('#issueTemplateId').val(id); new bootstrap.Modal($('#issueModal')[0]).show(); }

function toggleMaxDiscount() {
  $('#maxDiscountGroup').toggle($('#tplDiscountType').val() === 'PERCENT');
}

function createTemplate() {
  var body = {
    name: $('#tplName').val(), codePrefix: $('#tplPrefix').val().toUpperCase(),
    discountType: $('#tplDiscountType').val(), discountValue: parseInt($('#tplDiscountValue').val()),
    minAmount: parseInt($('#tplMinAmount').val()) || 0,
    totalQuantity: parseInt($('#tplQty').val()) || 100,
    validFrom: $('#tplValidFrom').val(),
    validUntil: $('#tplValidUntil').val()
  };
  if ($('#tplPromoter').val()) body.promoterId = parseInt($('#tplPromoter').val());
  if ($('#tplMaxDiscount').val()) body.maxDiscount = parseInt($('#tplMaxDiscount').val());
  if (!body.name || !body.codePrefix || !body.discountValue) return Swal.fire('입력 오류', '필수 항목을 모두 입력하세요.', 'warning');
  $.ajax({ url:'/backoffice/super/api/coupons/templates', type:'POST', contentType:'application/json',
    data: JSON.stringify(body) })
    .done(function(r) {
      Swal.fire('성공', r.message, 'success').then(function() { bootstrap.Modal.getInstance($('#createModal')[0]).hide(); loadTemplates(); });
    })
    .fail(function(xhr) { Swal.fire('오류', xhr.responseJSON?.message || '생성 실패', 'error'); });
}

function issueCoupon() {
  var tplId = $('#issueTemplateId').val();
  var memberId = $('#issueMemberId').val();
  if (!memberId) return Swal.fire('입력 오류', '회원 ID를 입력하세요.', 'warning');
  $.ajax({ url:'/backoffice/super/api/coupons/templates/' + tplId + '/issue', type:'POST',
    contentType:'application/json', data: JSON.stringify({memberId: parseInt(memberId)}) })
    .done(function(r) {
      Swal.fire('발급 완료', '쿠폰 코드: <b>' + r.couponCode + '</b>', 'success');
      bootstrap.Modal.getInstance($('#issueModal')[0]).hide();
      loadTemplates();
    })
    .fail(function(xhr) { Swal.fire('오류', xhr.responseJSON?.message || '발급 실패', 'error'); });
}

function deactivate(id) {
  Swal.fire({title:'비활성화', text:'이 쿠폰 템플릿을 비활성화하시겠습니까?', icon:'warning',
    showCancelButton:true, confirmButtonText:'비활성화', cancelButtonText:'취소'})
    .then(function(r) {
      if (!r.isConfirmed) return;
      $.post('/backoffice/super/api/coupons/templates/' + id + '/deactivate')
        .done(function(r) { Swal.fire('완료', r.message, 'success'); loadTemplates(); });
    });
}

function fmtDt(dt) {
  if (!dt) return '-';
  if (Array.isArray(dt)) {
    var y = dt[0], m = String(dt[1]).padStart(2,'0'), d = String(dt[2]).padStart(2,'0');
    var h = dt[3] != null ? String(dt[3]).padStart(2,'0') : '00';
    var mi = dt[4] != null ? String(dt[4]).padStart(2,'0') : '00';
    return y + '-' + m + '-' + d + ' ' + h + ':' + mi;
  }
  return String(dt).substring(0, 16).replace('T', ' ');
}
</script>
