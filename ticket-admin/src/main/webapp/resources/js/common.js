// TicketLegacy Admin Portal Common JS
const api = {
    get:   (url)       => $.ajax({ url, type: 'GET',    dataType: 'json' }),
    post:  (url, data) => $.ajax({ url, type: 'POST',   contentType: 'application/json', data: JSON.stringify(data), dataType: 'json' }),
    patch: (url, data) => $.ajax({ url, type: 'PATCH',  contentType: 'application/json', data: JSON.stringify(data), dataType: 'json' }),
    del:   (url)       => $.ajax({ url, type: 'DELETE', dataType: 'json' })
};

const toast = {
    success: (msg) => Swal.fire({ toast: true, position: 'top-end', icon: 'success', title: msg, showConfirmButton: false, timer: 2500 }),
    error:   (msg) => Swal.fire({ toast: true, position: 'top-end', icon: 'error',   title: msg, showConfirmButton: false, timer: 3000 }),
    info:    (msg) => Swal.fire({ toast: true, position: 'top-end', icon: 'info',    title: msg, showConfirmButton: false, timer: 2500 })
};

$(document).ready(function() {
    $('#btnLogout').on('click', function(e) {
        e.preventDefault();
        api.post('/admin/api/logout', {}).always(() => { location.href = '/admin/login'; });
    });
});
