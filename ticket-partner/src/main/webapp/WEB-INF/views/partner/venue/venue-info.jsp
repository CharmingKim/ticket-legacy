<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-panel mb-4">
    <div class="portal-section-title">
        <div>
            <h3>Venue setup</h3>
            <p>Maintain sections, regenerate seat template, and manage stage configurations.</p>
        </div>
        <button class="btn btn-outline-secondary btn-sm" onclick="reloadVenueData()">Refresh</button>
    </div>
    <div class="portal-note mb-4">
        Any section or stage change affects downstream seat generation for promoter-managed performances.
    </div>

    <div class="row g-4">
        <div class="col-lg-7">
            <div class="portal-form">
                <h5 class="mb-3">Add section</h5>
                <div class="row g-2">
                    <div class="col-md-4"><input id="sectionName" class="form-control" placeholder="Section name" /></div>
                    <div class="col-md-3">
                        <select id="sectionType" class="form-select">
                            <option value="FLOOR">Floor</option>
                            <option value="BALCONY">Balcony</option>
                            <option value="VIP_BOX">VIP Box</option>
                            <option value="STANDING">Standing</option>
                            <option value="PREMIUM">Premium</option>
                        </select>
                    </div>
                    <div class="col-md-2"><input id="totalRows" type="number" class="form-control" value="1" min="1" /></div>
                    <div class="col-md-2"><input id="seatsPerRow" type="number" class="form-control" value="1" min="1" /></div>
                    <div class="col-md-1"><button class="btn btn-primary w-100" onclick="createSection()">Add</button></div>
                </div>
            </div>
            <div class="portal-table-wrap mt-3">
                <table class="table portal-table">
                    <thead>
                    <tr>
                        <th>Section</th>
                        <th>Type</th>
                        <th>Rows</th>
                        <th>Seats</th>
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
                            <td><button class="btn btn-outline-danger btn-sm" onclick="removeSection(${section.sectionId})">Remove</button></td>
                        </tr>
                    </c:forEach>
                    </tbody>
                </table>
            </div>
        </div>

        <div class="col-lg-5">
            <div class="portal-form mb-3">
                <h5 class="mb-3">Seat template</h5>
                <p class="portal-meta">Regenerate the venue template when seating geometry changes.</p>
                <button class="btn btn-warning" onclick="generateTemplate()">Regenerate template</button>
            </div>
            <div class="portal-form">
                <h5 class="mb-3">Stage configuration</h5>
                <div class="row g-2">
                    <div class="col-md-5"><input id="configName" class="form-control" placeholder="Configuration name" /></div>
                    <div class="col-md-5"><input id="configDescription" class="form-control" placeholder="Description" /></div>
                    <div class="col-md-2"><button class="btn btn-primary w-100" onclick="createStageConfig()">Add</button></div>
                </div>
                <div class="portal-table-wrap mt-3">
                    <table class="table portal-table">
                        <thead>
                        <tr>
                            <th>Name</th>
                            <th>Description</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody id="stageConfigRows">
                        <c:forEach var="config" items="${stageConfigs}">
                            <tr>
                                <td>${config.configName}</td>
                                <td>${config.description}</td>
                                <td><button class="btn btn-outline-danger btn-sm" onclick="removeStageConfig(${config.configId})">Remove</button></td>
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
const venueId = ${venue.venueId};

function reloadVenueData() {
    $.get('/partner/venue/api/venues/' + venueId + '/sections').done(function(sections) {
        const rows = (sections || []).map(function(section) {
            return `
                <tr>
                    <td>${section.sectionName}</td>
                    <td>${section.sectionType}</td>
                    <td>${section.totalRows}</td>
                    <td>${section.seatsPerRow}</td>
                    <td><button class="btn btn-outline-danger btn-sm" onclick="removeSection(${section.sectionId})">Remove</button></td>
                </tr>`;
        }).join('');
        $('#sectionRows').html(rows || '<tr><td colspan="5" class="text-center text-muted">No sections.</td></tr>');
    });

    $.get('/partner/venue/api/venues/' + venueId + '/stage-configs').done(function(configs) {
        const rows = (configs || []).map(function(config) {
            return `
                <tr>
                    <td>${config.configName}</td>
                    <td>${config.description || ''}</td>
                    <td><button class="btn btn-outline-danger btn-sm" onclick="removeStageConfig(${config.configId})">Remove</button></td>
                </tr>`;
        }).join('');
        $('#stageConfigRows').html(rows || '<tr><td colspan="3" class="text-center text-muted">No stage configs.</td></tr>');
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
        Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
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
        Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
    });
}

function generateTemplate() {
    $.post('/partner/venue/api/venues/' + venueId + '/template')
        .done(function(result) {
            Swal.fire({ icon: 'success', text: result.message });
        }).fail(function(xhr) {
            Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
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
        Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
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
        Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
    });
}
</script>
