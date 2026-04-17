<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<section class="portal-form">
    <div class="portal-section-title">
        <div>
            <h3>Create performance draft</h3>
            <p>Build the commercial record first, then move into schedules, seat grades, and launch preparation.</p>
        </div>
        <a class="btn btn-outline-secondary btn-sm" href="/partner/promoter/performances">Back to list</a>
    </div>

    <div class="row g-3">
        <div class="col-md-8">
            <label class="form-label">Title</label>
            <input id="title" class="form-control" />
        </div>
        <div class="col-md-4">
            <label class="form-label">Category</label>
            <select id="category" class="form-select">
                <option value="CONCERT">Concert</option>
                <option value="MUSICAL">Musical</option>
                <option value="PLAY">Play</option>
                <option value="SPORTS">Sports</option>
            </select>
        </div>
        <div class="col-md-6">
            <label class="form-label">Venue</label>
            <select id="venueId" class="form-select">
                <option value="">Choose venue</option>
                <c:forEach var="venue" items="${venues}">
                    <option value="${venue.venueId}">${venue.name}</option>
                </c:forEach>
            </select>
        </div>
        <div class="col-md-6">
            <label class="form-label">Venue label</label>
            <input id="venueName" class="form-control" placeholder="Optional override" />
        </div>
        <div class="col-md-6">
            <label class="form-label">Start date</label>
            <input id="startDate" type="date" class="form-control" />
        </div>
        <div class="col-md-6">
            <label class="form-label">End date</label>
            <input id="endDate" type="date" class="form-control" />
        </div>
        <div class="col-md-6">
            <label class="form-label">Ticket open at</label>
            <input id="ticketOpenAt" type="datetime-local" class="form-control" />
        </div>
        <div class="col-md-6">
            <label class="form-label">Poster URL</label>
            <input id="posterUrl" class="form-control" />
        </div>
        <div class="col-12">
            <label class="form-label">Description</label>
            <textarea id="description" class="form-control" rows="6"></textarea>
        </div>
    </div>

    <div class="d-flex justify-content-end gap-2 mt-4">
        <a class="btn btn-outline-secondary" href="/partner/promoter/performances">Cancel</a>
        <button class="btn btn-primary" onclick="createPerformanceDraft()">Create draft</button>
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
            title: 'Draft created',
            text: result.message
        }).then(function() {
            location.href = '/partner/promoter/performances';
        });
    }).fail(function(xhr) {
        Swal.fire({ icon: 'error', text: xhr.responseJSON?.message || xhr.statusText });
    });
}
</script>
