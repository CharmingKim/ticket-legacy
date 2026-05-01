<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-form">
    <div class="portal-section-title">
        <div>
            <h3>공연 등록</h3>
            <p>공연 기본 정보를 입력하고 초안을 등록합니다.</p>
        </div>
        <a class="btn btn-outline-secondary btn-sm" href="/partner/promoter/performances">목록으로</a>
    </div>

    <div class="row g-3">
        <div class="col-md-8">
            <label class="form-label">공연명</label>
            <input id="title" class="form-control" />
        </div>
        <div class="col-md-4">
            <label class="form-label">카테고리</label>
            <select id="category" class="form-select">
                <option value="CONCERT">콘서트</option>
                <option value="MUSICAL">뮤지컬</option>
                <option value="PLAY">연극</option>
                <option value="SPORTS">스포츠</option>
            </select>
        </div>
        <div class="col-md-6">
            <label class="form-label">공연장</label>
            <select id="venueId" class="form-select">
                <option value="">공연장 선택</option>
                <c:forEach var="venue" items="${venues}">
                    <option value="${venue.venueId}">${venue.name}</option>
                </c:forEach>
            </select>
        </div>
        <div class="col-md-6">
            <label class="form-label">공연장 표시명</label>
            <input id="venueName" class="form-control" placeholder="별도 표시명 (선택)" />
        </div>
        <div class="col-md-6">
            <label class="form-label">공연 시작일</label>
            <input id="startDate" type="date" class="form-control" />
        </div>
        <div class="col-md-6">
            <label class="form-label">공연 종료일</label>
            <input id="endDate" type="date" class="form-control" />
        </div>
        <div class="col-md-6">
            <label class="form-label">예매 오픈 일시</label>
            <input id="ticketOpenAt" type="datetime-local" class="form-control" />
        </div>
        <div class="col-md-6">
            <label class="form-label">포스터 URL</label>
            <input id="posterUrl" class="form-control" />
        </div>
        <div class="col-12">
            <label class="form-label">공연 설명</label>
            <textarea id="description" class="form-control" rows="6"></textarea>
        </div>
    </div>

    <div class="d-flex justify-content-end gap-2 mt-4">
        <a class="btn btn-outline-secondary" href="/partner/promoter/performances">취소</a>
        <button class="btn btn-primary" onclick="createPerformanceDraft()">초안 등록</button>
    </div>
</section>

<script>
function createPerformanceDraft() {
    const payload = {
        title: $('#title').val(),
        category: $('#category').val(),
        venueId: $('#venueId').val() ? Number($('#venueId').val()) : null,
        venueName: $('#venueName').val() || $('#venueId option:selected').text(),
        startDate: $('#startDate').val(),
        endDate: $('#endDate').val(),
        ticketOpenAt: $('#ticketOpenAt').val(),
        posterUrl: $('#posterUrl').val(),
        description: $('#description').val()
    };

    $.ajax({
        url: '/partner/promoter/api/performances',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify(payload)
    }).done(function(result) {
        Swal.fire({
            icon: 'success',
            title: '초안 등록 완료',
            text: result.message
        }).then(function() {
            location.href = '/partner/promoter/performances';
        });
    }).fail(function(xhr) {
        Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
    });
}
</script>
