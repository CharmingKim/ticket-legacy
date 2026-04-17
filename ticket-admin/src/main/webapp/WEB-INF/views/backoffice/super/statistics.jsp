<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<div class="p-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h4 class="mb-0"><i class="bi bi-bar-chart-line-fill text-warning me-2"></i>시스템 통계</h4>
    <small class="text-muted">데이터 기준: 실시간</small>
  </div>

  <!-- KPI 카드 행 -->
  <div class="row g-3 mb-4" id="kpiCards">
    <div class="col-md-3"><div class="card border-0 shadow-sm text-center p-3">
      <div class="fs-1 fw-bold text-primary" id="kpi-users">-</div>
      <div class="text-muted small">활성 사용자</div>
      <div class="text-success small mt-1" id="kpi-new-users">오늘 신규: -명</div>
    </div></div>
    <div class="col-md-3"><div class="card border-0 shadow-sm text-center p-3">
      <div class="fs-1 fw-bold text-success" id="kpi-today-rev">-</div>
      <div class="text-muted small">오늘 매출</div>
      <div class="text-info small mt-1" id="kpi-month-rev">이번달: -원</div>
    </div></div>
    <div class="col-md-3"><div class="card border-0 shadow-sm text-center p-3">
      <div class="fs-1 fw-bold text-warning" id="kpi-today-rsv">-</div>
      <div class="text-muted small">오늘 예약</div>
      <div class="text-danger small mt-1" id="kpi-pending-rsv">미결제 대기: -건</div>
    </div></div>
    <div class="col-md-3"><div class="card border-0 shadow-sm text-center p-3">
      <div class="fs-1 fw-bold text-info" id="kpi-on-sale">-</div>
      <div class="text-muted small">판매중 공연</div>
      <div class="text-warning small mt-1" id="kpi-holds">현재 좌석홀드: -석</div>
    </div></div>
  </div>

  <!-- 차트 행 1 -->
  <div class="row g-3 mb-4">
    <div class="col-md-8">
      <div class="card border-0 shadow-sm p-3">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h6 class="mb-0">일별 예약 트렌드</h6>
          <select class="form-select form-select-sm w-auto" id="trendDays" onchange="loadDailyTrend()">
            <option value="7">최근 7일</option>
            <option value="14">최근 14일</option>
            <option value="30">최근 30일</option>
          </select>
        </div>
        <canvas id="chartDailyTrend" height="100"></canvas>
      </div>
    </div>
    <div class="col-md-4">
      <div class="card border-0 shadow-sm p-3">
        <h6 class="mb-2">카테고리별 공연</h6>
        <canvas id="chartCategory" height="200"></canvas>
      </div>
    </div>
  </div>

  <!-- 차트 행 2 -->
  <div class="row g-3 mb-4">
    <div class="col-md-6">
      <div class="card border-0 shadow-sm p-3">
        <h6 class="mb-2">월별 매출 추이</h6>
        <canvas id="chartMonthly" height="120"></canvas>
      </div>
    </div>
    <div class="col-md-6">
      <div class="card border-0 shadow-sm p-3">
        <h6 class="mb-2">시간대별 예약 트래픽</h6>
        <canvas id="chartHourly" height="120"></canvas>
      </div>
    </div>
  </div>

  <!-- 랭킹 행 -->
  <div class="row g-3">
    <div class="col-md-6">
      <div class="card border-0 shadow-sm p-3">
        <h6 class="mb-2"><i class="bi bi-trophy text-warning me-1"></i>TOP 기획사 매출</h6>
        <table class="table table-sm table-hover" id="topPromoterTable">
          <thead class="table-light"><tr><th>#</th><th>기획사</th><th>공연수</th><th>매출</th><th>수수료(10%)</th></tr></thead>
          <tbody id="topPromoterTbody"></tbody>
        </table>
      </div>
    </div>
    <div class="col-md-6">
      <div class="card border-0 shadow-sm p-3">
        <h6 class="mb-2"><i class="bi bi-star-fill text-warning me-1"></i>TOP 공연 매출</h6>
        <table class="table table-sm table-hover">
          <thead class="table-light"><tr><th>#</th><th>공연명</th><th>카테고리</th><th>예약수</th><th>매출</th></tr></thead>
          <tbody id="topPerfTbody"></tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
<script>
var chartDailyTrend, chartCategory, chartMonthly, chartHourly;

$(document).ready(function() {
  loadAllStats();
  loadDailyTrend();
});

function loadAllStats() {
  $.get('/backoffice/super/api/analytics/all')
    .done(function(data) {
      renderKpi(data.kpi);
      renderDailyTrend(data.dailyTrend);
      renderCategory(data.categoryDist);
      renderMonthly(data.monthlyRevenue);
      renderTopPromoters(data.topPromoters);
      renderTopPerformances(data.topPerformances);
    })
    .fail(function() { showError('통계 데이터를 불러오지 못했습니다.'); });

  $.get('/backoffice/super/api/analytics/hourly-traffic')
    .done(function(data) { renderHourly(data); });
}

function loadDailyTrend() {
  var days = $('#trendDays').val();
  $.get('/backoffice/super/api/analytics/daily-trend', { days: days })
    .done(function(data) { renderDailyTrend(data); });
}

function renderKpi(kpi) {
  if (!kpi) return;
  $('#kpi-users').text(fmt(kpi.active_users));
  $('#kpi-new-users').text('오늘 신규: ' + fmt(kpi.new_users_today) + '명');
  $('#kpi-today-rev').text(fmtWon(kpi.today_revenue));
  $('#kpi-month-rev').text('이번달: ' + fmtWon(kpi.month_revenue));
  $('#kpi-today-rsv').text(fmt(kpi.today_reservations));
  $('#kpi-pending-rsv').text('미결제 대기: ' + fmt(kpi.pending_reservations) + '건');
  $('#kpi-on-sale').text(fmt(kpi.on_sale_performances));
  $('#kpi-holds').text('현재 좌석홀드: ' + fmt(kpi.active_holds) + '석');
}

function renderDailyTrend(rows) {
  var labels = rows.map(function(r) { return r.dt; });
  var confirmed = rows.map(function(r) { return r.confirmed_count; });
  var cancelled = rows.map(function(r) { return r.cancelled_count; });
  var revenue = rows.map(function(r) { return r.daily_revenue; });
  if (chartDailyTrend) chartDailyTrend.destroy();
  chartDailyTrend = new Chart($('#chartDailyTrend')[0].getContext('2d'), {
    data: {
      labels: labels,
      datasets: [
        { type:'bar', label:'확정 예약', data: confirmed, backgroundColor:'rgba(25,135,84,0.7)', yAxisID:'y' },
        { type:'bar', label:'취소', data: cancelled, backgroundColor:'rgba(220,53,69,0.5)', yAxisID:'y' },
        { type:'line', label:'매출(원)', data: revenue, borderColor:'#0d6efd', backgroundColor:'transparent',
          yAxisID:'y2', tension:0.3, pointRadius:3 }
      ]
    },
    options: { responsive:true, scales: {
      y:  { type:'linear', position:'left',  title:{display:true,text:'예약 수'} },
      y2: { type:'linear', position:'right', title:{display:true,text:'매출(원)'}, grid:{drawOnChartArea:false} }
    }}
  });
}

function renderCategory(rows) {
  if (chartCategory) chartCategory.destroy();
  chartCategory = new Chart($('#chartCategory')[0].getContext('2d'), {
    type: 'doughnut',
    data: {
      labels: rows.map(function(r) { return r.category; }),
      datasets: [{ data: rows.map(function(r) { return r.total_count; }),
        backgroundColor:['#0d6efd','#198754','#ffc107','#dc3545','#6f42c1','#0dcaf0'] }]
    },
    options: { plugins: { legend: { position:'right' }}}
  });
}

function renderMonthly(rows) {
  if (chartMonthly) chartMonthly.destroy();
  chartMonthly = new Chart($('#chartMonthly')[0].getContext('2d'), {
    type: 'bar',
    data: {
      labels: rows.map(function(r) { return r.year_month; }),
      datasets: [{ label:'월 매출(원)', data: rows.map(function(r) { return r.total_revenue; }),
        backgroundColor:'rgba(13,110,253,0.7)', borderRadius:4 }]
    },
    options: { responsive:true }
  });
}

function renderHourly(rows) {
  if (chartHourly) chartHourly.destroy();
  var hours = Array.from({length:24}, function(_, i) { return i + '시'; });
  var counts = new Array(24).fill(0);
  rows.forEach(function(r) { counts[r.hour_of_day] = r.reservation_count; });
  chartHourly = new Chart($('#chartHourly')[0].getContext('2d'), {
    type: 'bar',
    data: {
      labels: hours,
      datasets: [{ label:'예약 건수', data: counts, backgroundColor:'rgba(255,193,7,0.7)', borderRadius:3 }]
    },
    options: { responsive:true, plugins:{ legend:{display:false} } }
  });
}

function renderTopPromoters(rows) {
  var html = '';
  rows.forEach(function(r, i) {
    html += '<tr><td>' + (i+1) + '</td><td>' + r.company_name + '</td><td>' + r.performance_count +
            '</td><td class="fw-bold text-success">' + fmtWon(r.total_revenue) +
            '</td><td class="text-danger">' + fmtWon(r.platform_fee) + '</td></tr>';
  });
  $('#topPromoterTbody').html(html || '<tr><td colspan="5" class="text-center text-muted">데이터 없음</td></tr>');
}

function renderTopPerformances(rows) {
  var html = '';
  rows.forEach(function(r, i) {
    html += '<tr><td>' + (i+1) + '</td><td class="fw-bold">' + r.title + '</td><td>' + r.category +
            '</td><td>' + r.reservation_count + '</td><td class="text-success fw-bold">' + fmtWon(r.total_revenue) + '</td></tr>';
  });
  $('#topPerfTbody').html(html || '<tr><td colspan="5" class="text-center text-muted">데이터 없음</td></tr>');
}

function fmt(v) { return v != null ? Number(v).toLocaleString() : '0'; }
function fmtWon(v) { return (v != null ? Number(v).toLocaleString() : '0') + '원'; }
function showError(msg) { console.error(msg); }
</script>
