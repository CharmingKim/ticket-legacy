<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-panel mb-4">
    <div class="portal-section-title">
        <div>
            <h3>공연장 설정</h3>
            <p>구역 구성, 좌석 템플릿 재생성, 무대 설정을 관리합니다.</p>
        </div>
        <button class="btn btn-outline-secondary btn-sm" onclick="reloadVenueData()">새로고침</button>
    </div>
    <div class="portal-note mb-4">
        구역 또는 무대 변경 시 기획사의 좌석 생성에 영향을 미칩니다.
    </div>

    <div class="row g-4">
        <div class="col-lg-7">
            <div class="portal-form">
                <h5 class="mb-3">구역 추가</h5>
                <div class="row g-2">
                    <div class="col-md-4"><input id="sectionName" class="form-control" placeholder="구역명" /></div>
                    <div class="col-md-3">
                        <select id="sectionType" class="form-select">
                            <option value="FLOOR">1층</option>
                            <option value="BALCONY">2층</option>
                            <option value="VIP_BOX">VIP 박스</option>
                            <option value="STANDING">스탠딩</option>
                            <option value="PREMIUM">프리미엄</option>
                        </select>
                    </div>
                    <div class="col-md-2"><input id="totalRows" type="number" class="form-control" value="1" min="1" /></div>
                    <div class="col-md-2"><input id="seatsPerRow" type="number" class="form-control" value="1" min="1" /></div>
                    <div class="col-md-1"><button class="btn btn-primary w-100" onclick="createSection()">추가</button></div>
                </div>
            </div>
            <div class="portal-table-wrap mt-3">
                <table class="table portal-table">
                    <thead>
                    <tr>
                        <th>구역명</th>
                        <th>유형</th>
                        <th>열</th>
                        <th>열당 좌석</th>
                        <th></th>
                    </tr>
                    </thead>
                    <tbody id="sectionRows">
                    <c:forEach var="section" items="${sections}">
                        <tr>
                            <td>${section.sectionName}</td>
                            <td>${section.sectionType}</td>
                            <td>${section.totalRows}</td>
                            <td>${section.seatsPerRow}</td>
                            <td><button class="btn btn-outline-danger btn-sm" onclick="removeSection(${section.sectionId})">삭제</button></td>
                        </tr>
                    </c:forEach>
                    </tbody>
                </table>
            </div>
        </div>

        <div class="col-lg-5">
            <div class="portal-form mb-3">
                <h5 class="mb-3">좌석 템플릿</h5>
                <p class="portal-meta">좌석 구성이 변경된 경우 템플릿을 재생성합니다.</p>
                <button class="btn btn-warning" onclick="generateTemplate()">템플릿 재생성</button>
            </div>
            <div class="portal-form">
                <h5 class="mb-3">무대 설정</h5>
                <div class="row g-2">
                    <div class="col-md-5"><input id="configName" class="form-control" placeholder="설정명" /></div>
                    <div class="col-md-5"><input id="configDescription" class="form-control" placeholder="설명" /></div>
                    <div class="col-md-2"><button class="btn btn-primary w-100" onclick="createStageConfig()">추가</button></div>
                </div>
                <div class="portal-table-wrap mt-3">
                    <table class="table portal-table">
                        <thead>
                        <tr>
                            <th>설정명</th>
                            <th>설명</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody id="stageConfigRows">
                        <c:forEach var="config" items="${stageConfigs}">
                            <tr>
                                <td>${config.configName}</td>
                                <td>${config.description}</td>
                                <td><button class="btn btn-outline-danger btn-sm" onclick="removeStageConfig(${config.configId})">삭제</button></td>
                            </tr>
                        </c:forEach>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</section>

<script>
var venueId = ${venue.venueId};

function reloadVenueData() {
    $.get('/partner/venue/api/venues/' + venueId + '/sections').done(function(sections) {
        var rows = (sections || []).map(function(s) {
            return '<tr>' +
                '<td>' + s.sectionName + '</td>' +
                '<td>' + s.sectionType + '</td>' +
                '<td>' + s.totalRows + '</td>' +
                '<td>' + s.seatsPerRow + '</td>' +
                '<td><button class="btn btn-outline-danger btn-sm" onclick="removeSection(' + s.sectionId + ')">삭제</button></td>' +
                '</tr>';
        }).join('');
        $('#sectionRows').html(rows || '<tr><td colspan="5" class="text-center text-muted">등록된 구역이 없습니다.</td></tr>');
    });

    $.get('/partner/venue/api/venues/' + venueId + '/stage-configs').done(function(configs) {
        var rows = (configs || []).map(function(c) {
            return '<tr>' +
                '<td>' + c.configName + '</td>' +
                '<td>' + (c.description || '') + '</td>' +
                '<td><button class="btn btn-outline-danger btn-sm" onclick="removeStageConfig(' + c.configId + ')">삭제</button></td>' +
                '</tr>';
        }).join('');
        $('#stageConfigRows').html(rows || '<tr><td colspan="3" class="text-center text-muted">등록된 무대 설정이 없습니다.</td></tr>');
    });
}

function createSection() {
    $.ajax({
        url: '/partner/venue/api/venues/' + venueId + '/sections',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({
            sectionName: $('#sectionName').val(),
            sectionType: $('#sectionType').val(),
            totalRows: Number($('#totalRows').val()),
            seatsPerRow: Number($('#seatsPerRow').val())
        })
    }).done(function(result) {
        Swal.fire({ icon: 'success', text: result.message });
        reloadVenueData();
    }).fail(function(xhr) {
        Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
    });
}

function removeSection(sectionId) {
    $.ajax({
        url: '/partner/venue/api/venues/' + venueId + '/sections/' + sectionId,
        type: 'DELETE'
    }).done(function(result) {
        Swal.fire({ icon: 'success', text: result.message });
        reloadVenueData();
    }).fail(function(xhr) {
        Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
    });
}

function generateTemplate() {
    $.post('/partner/venue/api/venues/' + venueId + '/template')
        .done(function(result) {
            Swal.fire({ icon: 'success', text: result.message });
        }).fail(function(xhr) {
            Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
        });
}

function createStageConfig() {
    $.ajax({
        url: '/partner/venue/api/venues/' + venueId + '/stage-configs',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify({
            configName: $('#configName').val(),
            description: $('#configDescription').val()
        })
    }).done(function(result) {
        Swal.fire({ icon: 'success', text: result.message });
        reloadVenueData();
    }).fail(function(xhr) {
        Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
    });
}

function removeStageConfig(configId) {
    $.ajax({
        url: '/partner/venue/api/venues/' + venueId + '/stage-configs/' + configId,
        type: 'DELETE'
    }).done(function(result) {
        Swal.fire({ icon: 'success', text: result.message });
        reloadVenueData();
    }).fail(function(xhr) {
        Swal.fire({ icon: 'error', text: (xhr.responseJSON && xhr.responseJSON.message) || xhr.statusText });
    });
}
</script>
