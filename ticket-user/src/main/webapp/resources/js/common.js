/* =========================================================
   TicketLegacy – Common JS (jQuery required)
   ES5 compatible (Eclipse/STS validator safe)
   ========================================================= */

/* ── AJAX helper ─────────────────────────────────────── */
var api = {
    get: function(url, data) {
        return $.ajax({ method: 'GET', url: url, data: data, dataType: 'json' });
    },
    post: function(url, data) {
        return $.ajax({
            method: 'POST',
            url: url,
            dataType: 'json',
            contentType: 'application/json',
            data: JSON.stringify(data)
        });
    },
    del: function(url) {
        return $.ajax({ method: 'DELETE', url: url, dataType: 'json' });
    }
};

/* ── Toast ───────────────────────────────────────────── */
var toast = (function() {
    var container = null;

    function getContainer() {
        if (!container) {
            container = $('<div class="tl-toast-container"></div>').appendTo('body');
        }
        return container;
    }

    function show(msg, type, duration) {
        type     = type     || 'success';
        duration = duration || 3500;

        var icons  = { success: 'bi-check-circle-fill', error: 'bi-x-circle-fill', warning: 'bi-exclamation-triangle-fill' };
        var colors = { success: '#22c55e',              error: '#ef4444',           warning: '#f59e0b' };

        var iconClass  = icons[type]  || icons.success;
        var iconColor  = colors[type] || colors.success;

        var el = $(
            '<div class="tl-toast ' + type + '">' +
            '  <i class="bi ' + iconClass + '" style="color:' + iconColor + ';font-size:1.1rem;flex-shrink:0"></i>' +
            '  <span>' + msg + '</span>' +
            '</div>'
        ).appendTo(getContainer());

        setTimeout(function() {
            el.fadeOut(300, function() { el.remove(); });
        }, duration);
    }

    return {
        success: function(msg) { show(msg, 'success'); },
        error:   function(msg) { show(msg, 'error');   },
        warning: function(msg) { show(msg, 'warning'); }
    };
})();

/* ── AJAX error handler ──────────────────────────────── */
$(document).ajaxError(function(event, xhr) {
    if (xhr.status === 401) {
        toast.error('로그인이 필요합니다.');
        setTimeout(function() { location.href = '/member/login'; }, 1200);
    } else if (xhr.status === 403) {
        toast.error('접근 권한이 없습니다.');
    } else if (xhr.status === 409) {
        var msg = (xhr.responseJSON && xhr.responseJSON.message)
                  ? xhr.responseJSON.message
                  : '이미 처리된 요청입니다.';
        toast.error(msg);
    } else if (xhr.status >= 500) {
        toast.error('서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
    }
});

/* ── Logout ──────────────────────────────────────────── */
$(document).on('click', '#logoutBtn', function(e) {
    e.preventDefault();
    api.post('/api/member/logout', {}).always(function() {
        location.href = '/';
    });
});

/* ── Util ────────────────────────────────────────────── */
var util = {
    formatNumber: function(n) {
        return Number(n).toLocaleString('ko-KR');
    },
    formatDate: function(dateStr) {
        if (!dateStr) return '';
        var d = new Date(dateStr);
        return d.toLocaleDateString('ko-KR', { year: 'numeric', month: '2-digit', day: '2-digit' });
    },
    formatDateTime: function(dateStr) {
        if (!dateStr) return '';
        var d = new Date(dateStr);
        return d.toLocaleString('ko-KR', {
            year: 'numeric', month: '2-digit', day: '2-digit',
            hour: '2-digit', minute: '2-digit'
        });
    }
};
