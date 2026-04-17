<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<div class="p-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h4 class="mb-0"><i class="bi bi-speedometer2 text-primary me-2"></i>HQ 대시보드</h4>
    <small class="text-muted">실시간 운영 현황</small>
  </div>

  <!-- KPI 카드 -->
  <div class="row g-3 mb-4">
    <div class="col-md-3">
      <div class="card border-0 shadow-sm text-center p-3 h-100">
        <div class="fs-1 fw-bold text-warning" id="kpi-pending-promoters">-</div>
        <div class="text-muted small">기획사 승인 대기</div>
      </div>
    </div>
    <div class="col-md-3">
      <div class="card border-0 shadow-sm text-center p-3 h-100">
        <div class="fs-1 fw-bold text-danger" id="kpi-review-perf">-</div>
        <div class="text-muted small">공연 심사 대기</div>
      </div>
    </div>
    <div class="col-md-3">
      <div class="card border-0 shadow-sm text-center p-3 h-100">
        <div class="fs-1 fw-bold text-success" id="kpi-today-rsv">-</div>
        <div class="text-muted small">오늘 예약 수</div>
      </div>
    </div>
    <div class="col-md-3">
      <div class="card border-0 shadow-sm text-center p-3 h-100">
        <div class="fs-1 fw-bold text-primary" id="kpi-total-members">-</div>
        <div class="text-muted small">전체 회원 수</div>
      </div>
    </div>
  </div>

  <!-- 빠른 링크 -->
  <div class="d-flex flex-wrap gap-2 mb-4">
    <a href="/backoffice/super/settlement" class="btn btn-outline-primary btn-sm">
      <i class="bi bi-cash-stack me-1"></i>정산 관리
    </a>
    <a href="/backoffice/super/statistics" class="btn btn-outline-warning btn-sm">
      <i class="bi bi-bar-chart-line me-1"></i>통계
    </a>
    <a href="/backoffice/super/coupons" class="btn btn-outline-success btn-sm">
      <i class="bi bi-ticket-perforated me-1"></i>쿠폰 관리
    </a>
    <a href="/backoffice/super/notices" class="btn btn-outline-info btn-sm">
      <i class="bi bi-megaphone me-1"></i>공지 관리
    </a>
  </div>

  <!-- 탭 영역 -->
  <div class="card border-0 shadow-sm">
    <div class="card-header bg-white border-bottom">
      <ul class="nav nav-tabs card-header-tabs" id="dashTabs">
        <li class="nav-item">
          <button class="nav-link active" onclick="switchTab(this, 'tabPromoters')">기획사</button>
        </li>
        <li class="nav-item">
          <button class="nav-link" onclick="switchTab(this, 'tabVenueManagers')">공연장담당자</button>
        </li>
        <li class="nav-item">
          <button class="nav-link" onclick="switchTab(this, 'tabPerformances')">공연 심사</button>
        </li>
        <li class="nav-item">
          <button class="nav-link" onclick="switchTab(this, 'tabVenues')">공연장</button>
        </li>
        <li class="nav-item">
          <button class="nav-link" onclick="switchTab(this, 'tabReservations')">최근 예약</button>
        </li>
      </ul>
    </div>
    <div class="card-body p-0">

      <!-- 기획사 탭 -->
      <div id="tabPromoters" class="tab-pane p-3">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h6 class="mb-0">기획사 목록 (승인 대기 우선)</h6>
        </div>
        <table class="table table-sm table-hover mb-0">
          <thead class="table-light"><tr><th>ID</th><th>회사명</th><th>대표자</th><th>상태</th><th>등록일</th><th>관리</th></tr></thead>
          <tbody id="promoterTbody"><tr><td colspan="6" class="text-center text-muted py-3">로딩 중...</td></tr></tbody>
        </table>
      </div>

      <!-- 공연장담당자 탭 -->
      <div id="tabVenueManagers" class="tab-pane p-3" style="display:none">
        <h6 class="mb-2">공연장 담당자 목록</h6>
        <table class="table table-sm table-hover mb-0">
          <thead class="table-light"><tr><th>ID</th><th>이름</th><th>공연장</th><th>상태</th><th>등록일</th><th>관리</th></tr></thead>
          <tbody id="venueManagerTbody"><tr><td colspan="6" class="text-center text-muted py-3">로딩 중...</td></tr></tbody>
        </table>
      </div>

      <!-- 공연 심사 탭 -->
      <div id="tabPerformances" class="tab-pane p-3" style="display:none">
        <h6 class="mb-2">공연 심사 대기 목록</h6>
        <table class="table table-sm table-hover mb-0">
          <thead class="table-light"><tr><th>ID</th><th>공연명</th><th>기획사</th><th>카테고리</th><th>신청일</th><th>관리</th></tr></thead>
          <tbody id="performanceTbody"><tr><td colspan="6" class="text-center text-muted py-3">로딩 중...</td></tr></tbody>
        </table>
      </div>

      <!-- 공연장 탭 -->
      <div id="tabVenues" class="tab-pane p-3" style="display:none">
        <h6 class="mb-2">공연장 목록</h6>
        <table class="table table-sm table-hover mb-0">
          <thead class="table-light"><tr><th>ID</th><th>공연장명</th><th>위치</th><th>총 좌석</th><th>상태</th></tr></thead>
          <tbody id="venueTbody"><tr><td colspan="5" class="text-center text-muted py-3">로딩 중...</td></tr></tbody>
        </table>
      </div>

      <!-- 최근 예약 탭 -->
      <div id="tabReservations" class="tab-pane p-3" style="display:none">
        <h6 class="mb-2">최근 예약 내역</h6>
        <div id="recentReservationList"></div>
      </div>

    </div>
  </div>
</div>

<script>
var tabLoaded = {};

$(document).ready(function() {
  loadSuperDashboard();
  loadTabData('tabPromoters');
});

function switchTab(btn, tabId) {
  // 탭 버튼 active 전환
  document.querySelectorAll('#dashTabs .nav-link').forEach(function(el) {
    el.classList.remove('active');
  });
  btn.classList.add('active');

  // 탭 패널 전환
  document.querySelectorAll('.tab-pane').forEach(function(el) {
    el.style.display = 'none';
  });
  document.getElementById(tabId).style.display = '';

  // 탭별 데이터 로드 (최초 1회)
  if (!tabLoaded[tabId]) {
    loadTabData(tabId);
  }
}

function loadSuperDashboard() {
  $.get('/backoffice/super/api/dashboard/summary').done(function(summary) {
    $('#kpi-pending-promoters').text(summary.pendingPromoters || 0);
    $('#kpi-review-perf').text(summary.reviewPerformances || 0);
    $('#kpi-today-rsv').text(summary.todayReservations || 0);
    $('#kpi-total-members').text((summary.totalMembers || 0).toLocaleString());
  });
}

function loadTabData(tabId) {
  tabLoaded[tabId] = true;
  if (tabId === 'tabPromoters') {
    $.get('/backoffice/super/api/dashboard/promoters').done(function(rows) {
      var html = '';
      (rows || []).forEach(function(p) {
        var statusBadge = p.status === 'PENDING' ? 'bg-warning text-dark' :
                          p.status === 'APPROVED' ? 'bg-success' : 'bg-secondary';
        html += '<tr>' +
          '<td>' + p.promoterId + '</td>' +
          '<td><b>' + p.companyName + '</b></td>' +
          '<td>' + (p.representativeName || '-') + '</td>' +
          '<td><span class="badge ' + statusBadge + '">' + p.status + '</span></td>' +
          '<td class="small">' + (p.createdAt || '').substring(0,10) + '</td>' +
          '<td>' +
            (p.status === 'PENDING'
              ? '<button class="btn btn-xs btn-success me-1" onclick="approvePromoter(' + p.promoterId + ')">승인</button>' +
                '<button class="btn btn-xs btn-danger" onclick="rejectPromoter(' + p.promoterId + ')">거절</button>'
              : '-') +
          '</td></tr>';
      });
      $('#promoterTbody').html(html || '<tr><td colspan="6" class="text-center text-muted">데이터 없음</td></tr>');
    });
  } else if (tabId === 'tabVenueManagers') {
    $.get('/backoffice/super/api/dashboard/venue-managers').done(function(rows) {
      var html = '';
      (rows || []).forEach(function(v) {
        var statusBadge = v.status === 'PENDING' ? 'bg-warning text-dark' :
                          v.status === 'APPROVED' ? 'bg-success' : 'bg-secondary';
        html += '<tr>' +
          '<td>' + v.venueManagerId + '</td>' +
          '<td>' + (v.memberName || '-') + '</td>' +
          '<td>' + (v.venueName || '-') + '</td>' +
          '<td><span class="badge ' + statusBadge + '">' + v.status + '</span></td>' +
          '<td class="small">' + (v.createdAt || '').substring(0,10) + '</td>' +
          '<td>' +
            (v.status === 'PENDING'
              ? '<button class="btn btn-xs btn-success me-1" onclick="approveVenueManager(' + v.venueManagerId + ')">승인</button>' +
                '<button class="btn btn-xs btn-danger" onclick="rejectVenueManager(' + v.venueManagerId + ')">거절</button>'
              : '-') +
          '</td></tr>';
      });
      $('#venueManagerTbody').html(html || '<tr><td colspan="6" class="text-center text-muted">데이터 없음</td></tr>');
    });
  } else if (tabId === 'tabPerformances') {
    $.get('/backoffice/super/api/dashboard/review-performances').done(function(rows) {
      var html = '';
      (rows || []).forEach(function(p) {
        html += '<tr>' +
          '<td>' + p.performanceId + '</td>' +
          '<td><b>' + p.title + '</b></td>' +
          '<td>' + (p.promoterCompanyName || '-') + '</td>' +
          '<td>' + (p.category || '-') + '</td>' +
          '<td class="small">' + (p.createdAt || '').substring(0,10) + '</td>' +
          '<td>' +
            '<button class="btn btn-xs btn-success me-1" onclick="approvePerf(' + p.performanceId + ')">승인</button>' +
            '<button class="btn btn-xs btn-danger" onclick="rejectPerf(' + p.performanceId + ')">반려</button>' +
          '</td></tr>';
      });
      $('#performanceTbody').html(html || '<tr><td colspan="6" class="text-center text-muted">심사 대기 공연 없음</td></tr>');
    });
  } else if (tabId === 'tabVenues') {
    $.get('/backoffice/super/api/dashboard/venues').done(function(rows) {
      var html = '';
      (rows || []).forEach(function(v) {
        html += '<tr>' +
          '<td>' + v.venueId + '</td>' +
          '<td><b>' + (v.name || '-') + '</b></td>' +
          '<td>' + (v.address || '-') + '</td>' +
          '<td>' + (v.seatScale || '-') + '</td>' +
          '<td><span class="badge bg-success">운영중</span></td>' +
          '</tr>';
      });
      $('#venueTbody').html(html || '<tr><td colspan="5" class="text-center text-muted">데이터 없음</td></tr>');
    });
  } else if (tabId === 'tabReservations') {
    $.get('/backoffice/super/api/dashboard/recent-reservations').done(function(rows) {
      var html = (rows || []).map(function(item) {
        return '<div class="portal-list-item border-bottom py-2">' +
          '<strong>' + item.reservationNo + '</strong>' +
          '<div class="text-muted small">' + item.performanceTitle + ' | ' + item.memberName + ' | ' +
          '<span class="badge bg-secondary">' + item.status + '</span></div>' +
          '</div>';
      }).join('');
      $('#recentReservationList').html(html || '<div class="text-center text-muted py-3">최근 예약 없음</div>');
    });
  }
}

function approvePromoter(id) {
  Swal.fire({title:'승인', text:'이 기획사를 승인하시겠습니까?', icon:'question',
    showCancelButton:true, confirmButtonText:'승인', cancelButtonText:'취소', confirmButtonColor:'#198754'})
    .then(function(r) {
      if (!r.isConfirmed) return;
      $.post('/backoffice/super/api/promoters/' + id + '/approve')
        .done(function(res) { Swal.fire('완료', res.message || '승인되었습니다.', 'success'); tabLoaded['tabPromoters']=false; loadTabData('tabPromoters'); loadSuperDashboard(); })
        .fail(function(xhr) { Swal.fire('오류', xhr.responseJSON?.message || '처리 실패', 'error'); });
    });
}

function rejectPromoter(id) {
  Swal.fire({title:'거절', input:'text', inputLabel:'거절 사유', icon:'warning',
    showCancelButton:true, confirmButtonText:'거절', cancelButtonText:'취소', confirmButtonColor:'#dc3545'})
    .then(function(r) {
      if (!r.isConfirmed) return;
      $.ajax({ url:'/backoffice/super/api/promoters/' + id + '/reject', type:'POST',
        contentType:'application/json', data: JSON.stringify({reason: r.value}) })
        .done(function(res) { Swal.fire('완료', res.message || '거절되었습니다.', 'success'); tabLoaded['tabPromoters']=false; loadTabData('tabPromoters'); loadSuperDashboard(); })
        .fail(function(xhr) { Swal.fire('오류', xhr.responseJSON?.message || '처리 실패', 'error'); });
    });
}

function approveVenueManager(id) {
  $.post('/backoffice/super/api/venue-managers/' + id + '/approve')
    .done(function(res) { Swal.fire('완료', res.message || '승인되었습니다.', 'success'); tabLoaded['tabVenueManagers']=false; loadTabData('tabVenueManagers'); loadSuperDashboard(); })
    .fail(function(xhr) { Swal.fire('오류', xhr.responseJSON?.message || '처리 실패', 'error'); });
}

function rejectVenueManager(id) {
  $.ajax({ url:'/backoffice/super/api/venue-managers/' + id + '/reject', type:'POST' })
    .done(function(res) { Swal.fire('완료', res.message || '거절되었습니다.', 'success'); tabLoaded['tabVenueManagers']=false; loadTabData('tabVenueManagers'); loadSuperDashboard(); });
}

function approvePerf(id) {
  $.post('/backoffice/super/api/performances/' + id + '/approve')
    .done(function(res) { Swal.fire('완료', res.message || '승인되었습니다.', 'success'); tabLoaded['tabPerformances']=false; loadTabData('tabPerformances'); loadSuperDashboard(); })
    .fail(function(xhr) { Swal.fire('오류', xhr.responseJSON?.message || '처리 실패', 'error'); });
}

function rejectPerf(id) {
  Swal.fire({title:'반려', input:'text', inputLabel:'반려 사유', icon:'warning',
    showCancelButton:true, confirmButtonText:'반려', cancelButtonText:'취소', confirmButtonColor:'#dc3545'})
    .then(function(r) {
      if (!r.isConfirmed) return;
      $.ajax({ url:'/backoffice/super/api/performances/' + id + '/reject', type:'POST',
        contentType:'application/json', data: JSON.stringify({reason: r.value}) })
        .done(function(res) { Swal.fire('완료', res.message || '반려되었습니다.', 'success'); tabLoaded['tabPerformances']=false; loadTabData('tabPerformances'); loadSuperDashboard(); })
        .fail(function(xhr) { Swal.fire('오류', xhr.responseJSON?.message || '처리 실패', 'error'); });
    });
}
</script>
