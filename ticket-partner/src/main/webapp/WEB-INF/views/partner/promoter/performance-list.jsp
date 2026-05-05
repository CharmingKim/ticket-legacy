<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-panel mb-4">
    <div class="portal-section-title">
        <div>
            <h3>공연 관리</h3>
            <p>공연 초안을 작성하고 심사를 요청합니다.</p>
        </div>
        <div class="d-flex gap-2">
            <select id="approvalStatusFilter" class="form-select form-select-sm">
                <option value="">전체 상태</option>
                <option value="DRAFT">초안</option>
                <option value="REVIEW">심사 중</option>
                <option value="APPROVED">승인</option>
                <option value="REJECTED">반려</option>
                <option value="PUBLISHED">게시</option>
            </select>
            <a class="btn btn-primary btn-sm" href="/partner/promoter/performances/new">공연 등록</a>
        </div>
    </div>
    <div class="portal-table-wrap">
        <table class="table portal-table">
            <thead>
            <tr>
                <th>공연</th>
                <th>상태</th>
                <th>예매 오픈</th>
                <th>일정 관리</th>
                <th>좌석 관리</th>
                <th>관리</th>
            </tr>
            </thead>
            <tbody id="performanceRows"></tbody>
        </table>
    </div>
</section>

<script>
var STATUS_KO = { DRAFT:'초안', REVIEW:'심사 중', APPROVED:'승인', REJECTED:'반려', PUBLISHED:'게시' };

function loadPromoterPerformances() {
    $.get('/partner/promoter/api/performances', {
        approvalStatus: $('#approvalStatusFilter').val()
    }).done(function(response) {
        var rows = (response.list || []).map(function(item) {
            var canSubmit = item.approvalStatus === 'DRAFT' || item.approvalStatus === 'REJECTED';
            var statusLabel = STATUS_KO[item.approvalStatus] || item.approvalStatus;
            var submitBtn = canSubmit
                ? '<button class="btn btn-primary btn-sm" onclick="submitReview(' + item.performanceId + ')">심사 요청</button>'
                : '';
            return '<tr>' +
                '<td><strong>' + item.title + '</strong>' +
                    '<div class="portal-meta">' + item.category + ' · ' + (item.venueName || '-') + '</div></td>' +
                '<td><span class="badge-status badge-' + item.approvalStatus + '">' + statusLabel + '</span></td>' +
                '<td>' + (item.ticketOpenAt || '-') + '</td>' +
                '<td><button class="btn btn-outline-secondary btn-sm" onclick="addQuickSchedule(' + item.performanceId + ')">일정 추가</button></td>' +
                '<td>' +
                  '<div class="d-flex flex-column gap-1">' +
                    '<button class="btn btn-outline-info btn-sm" onclick="openSeatGradeModal(' + item.performanceId + ', ' + item.venueId + ')">등급/가격 설정</button>' +
                    '<button class="btn btn-outline-secondary btn-sm" onclick="generateSeats(' + item.performanceId + ')">좌석 생성</button>' +
                  '</div>' +
                '</td>' +
                '<td class="d-flex gap-2">' + submitBtn + '</td>' +
                '</tr>';
        }).join('');
        $('#performanceRows').html(rows || '<tr><td colspan="6" class="text-center text-muted">등록된 공연이 없습니다.</td></tr>');
    });
}

function submitReview(performanceId) {
    $.post('/partner/promoter/api/performances/' + performanceId + '/submit')
        .done(function(result) {
            Swal.fire({ icon: 'success', text: result.message });
            loadPromoterPerformances();
        })
        .fail(function(xhr) {
            Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
        });
}

function generateSeats(performanceId) {
    $.post('/partner/promoter/api/performances/' + performanceId + '/seats')
        .done(function(result) {
            Swal.fire({ icon: 'success', text: result.message });
        })
        .fail(function(xhr) {
            Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
        });
}

function addQuickSchedule(performanceId) {
    Swal.fire({
        title: '공연 일정 추가',
        html: '<input id="scheduleDate" type="date" class="swal2-input"><input id="scheduleTime" type="time" class="swal2-input">',
        focusConfirm: false,
        preConfirm: function() {
            return {
                showDate: document.getElementById('scheduleDate').value,
                showTime: document.getElementById('scheduleTime').value
            };
        }
    }).then(function(result) {
        if (!result.isConfirmed) return;
        $.ajax({
            url: '/partner/promoter/api/performances/' + performanceId + '/schedules',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify(result.value)
        }).done(function(payload) {
            Swal.fire({ icon: 'success', text: payload.message });
        }).fail(function(xhr) {
            Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
        });
    });
}

// ─────────────────────────────────────────────────────────
// 좌석 등급/가격 설정 모달 로직
// ─────────────────────────────────────────────────────────
var currentSeatGradePerfId = null;

function openSeatGradeModal(performanceId, venueId) {
    currentSeatGradePerfId = performanceId;
    
    $.when(
        $.get('/partner/promoter/api/venues/' + venueId + '/sections'),
        $.get('/partner/promoter/api/performances/' + performanceId + '/seat-grades')
    ).done(function(sectionsRes, gradesRes) {
        var sections = sectionsRes[0] || [];
        var grades = gradesRes[0] || [];
        
        // sectionId를 키로 하여 기존 설정값 매핑
        var gradeMap = {};
        grades.forEach(function(g) {
            gradeMap[g.sectionId] = g;
        });
        
        var html = '';
        if (sections.length === 0) {
            html = '<tr><td colspan="4" class="text-center text-muted">공연장에 등록된 구역이 없습니다.</td></tr>';
        } else {
            sections.forEach(function(sec) {
                var existing = gradeMap[sec.sectionId] || { grade: '', price: '' };
                html += '<tr>' +
                    '<td><input type="hidden" class="sg-section-id" value="' + sec.sectionId + '">' + sec.sectionName + '</td>' +
                    '<td>' + sec.sectionType + ' (' + sec.totalRows + '행)</td>' +
                    '<td><input type="text" class="form-control form-control-sm sg-grade" placeholder="VIP, R, S..." value="' + existing.grade + '"></td>' +
                    '<td><input type="number" class="form-control form-control-sm sg-price" placeholder="가격(원)" value="' + existing.price + '"></td>' +
                '</tr>';
            });
        }
        $('#seatGradeRows').html(html);
        new bootstrap.Modal(document.getElementById('seatGradeModal')).show();
    }).fail(function() {
        Swal.fire('오류', '구역 및 등급 정보를 불러오지 못했습니다.', 'error');
    });
}

function saveSeatGrades() {
    var grades = [];
    var hasError = false;
    
    $('#seatGradeRows tr').each(function() {
        var sectionId = $(this).find('.sg-section-id').val();
        if (!sectionId) return; // empty row
        
        var grade = $(this).find('.sg-grade').val().trim();
        var priceStr = $(this).find('.sg-price').val().trim();
        
        if (grade || priceStr) { // 둘 중 하나라도 입력했으면 둘 다 필수
            if (!grade || !priceStr) {
                hasError = true;
                return false; // break each
            }
            grades.push({
                sectionId: Number(sectionId),
                grade: grade,
                price: Number(priceStr)
            });
        }
    });
    
    if (hasError) {
        Swal.fire('경고', '등급과 가격은 함께 입력되어야 합니다.', 'warning');
        return;
    }
    
    $.ajax({
        url: '/partner/promoter/api/performances/' + currentSeatGradePerfId + '/seat-grades',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({ grades: grades })
    }).done(function(res) {
        Swal.fire('완료', res.message, 'success');
        bootstrap.Modal.getInstance(document.getElementById('seatGradeModal')).hide();
    }).fail(function(xhr) {
        Swal.fire('오류', xhr.responseJSON?.message || '저장 실패', 'error');
    });
}

$('#approvalStatusFilter').on('change', loadPromoterPerformances);
$(loadPromoterPerformances);
</script>

<!-- 좌석 등급/가격 설정 모달 -->
<div class="modal fade" id="seatGradeModal" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered modal-lg">
    <div class="modal-content">
      <div class="modal-header bg-light">
        <h5 class="modal-title fs-6 fw-bold"><i class="bi bi-tags me-2"></i>좌석 등급 및 가격 설정</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <div class="alert alert-info small py-2 mb-3">
          공연장의 각 구역별로 적용할 티켓 등급(VIP, R, S 등)과 가격을 설정합니다. <br>
          설정하지 않은 구역은 빈칸으로 두시면 해당 구역 좌석은 생성되지 않습니다.
        </div>
        <div style="max-height: 400px; overflow-y: auto;">
            <table class="table table-bordered table-sm align-middle small text-center mb-0">
                <thead class="table-light">
                    <tr>
                        <th width="25%">구역명</th>
                        <th width="25%">타입</th>
                        <th width="25%">등급 명칭 (예: VIP)</th>
                        <th width="25%">가격 (원)</th>
                    </tr>
                </thead>
                <tbody id="seatGradeRows">
                    <!-- JS 렌더링 -->
                </tbody>
            </table>
        </div>
      </div>
      <div class="modal-footer border-top-0">
        <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">취소</button>
        <button type="button" class="btn btn-primary btn-sm" onclick="saveSeatGrades()">저장하기</button>
      </div>
    </div>
  </div>
</div>
