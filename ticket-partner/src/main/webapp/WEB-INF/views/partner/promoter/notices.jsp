<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<style>
.notice-badge { font-size: .72rem; padding: 2px 8px; border-radius: 10px; }
.badge-SYSTEM { background:#6c757d; color:#fff; }
.badge-EVENT  { background:#0d6efd; color:#fff; }
.badge-PERFORMANCE { background:#198754; color:#fff; }
.badge-MAINTENANCE { background:#dc3545; color:#fff; }
.notice-pin { color:#f59e0b; margin-right:4px; }
.notice-row { cursor:pointer; transition:background .15s; }
.notice-row:hover { background:#f8f9fa; }
.notice-detail { display:none; padding:1rem 1.25rem; background:#f8f9fa; border-top:1px solid #dee2e6; }
</style>

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h4 class="mb-0 fw-bold">공지사항</h4>
        <small class="text-muted">플랫폼 운영팀에서 발송한 공지를 확인하세요</small>
    </div>
    <div>
        <select id="typeFilter" class="form-select form-select-sm" style="width:160px;" onchange="filterType()">
            <option value="">전체 유형</option>
            <option value="SYSTEM">시스템</option>
            <option value="EVENT">이벤트</option>
            <option value="PERFORMANCE">공연</option>
            <option value="MAINTENANCE">점검</option>
        </select>
    </div>
</div>

<!-- 공지 목록 -->
<div class="card shadow-sm">
    <div class="card-body p-0">
        <c:choose>
            <c:when test="${empty notices}">
                <div class="text-center py-5 text-muted">
                    <i class="bi bi-inbox fs-1 d-block mb-2"></i>
                    등록된 공지사항이 없습니다.
                </div>
            </c:when>
            <c:otherwise>
                <div id="noticeList">
                <c:forEach var="n" items="${notices}">
                <div class="notice-item" data-type="${n.noticeType}">
                    <div class="notice-row d-flex align-items-center px-4 py-3 border-bottom"
                         onclick="toggleDetail(this)">
                        <div class="flex-grow-1">
                            <c:if test="${n.pinned}">
                                <i class="bi bi-pin-fill notice-pin"></i>
                            </c:if>
                            <span class="notice-badge badge-${n.noticeType}">${n.noticeType}</span>
                            <span class="ms-2 fw-semibold">${n.title}</span>
                        </div>
                        <div class="text-muted small me-3">
                            <i class="bi bi-eye me-1"></i>${n.viewCount}
                        </div>
                        <div class="text-muted small">
                            ${fn:substring(n.createdAt, 0, 10)}
                        </div>
                        <i class="bi bi-chevron-down ms-3 toggle-icon"></i>
                    </div>
                    <div class="notice-detail">
                        <div class="mb-2 text-muted small">
                            작성자: <strong>${n.authorName}</strong> &nbsp;|&nbsp;
                            대상: <strong>${n.targetRole}</strong> &nbsp;|&nbsp;
                            ${fn:substring(n.createdAt, 0, 16)}
                        </div>
                        <div style="white-space:pre-wrap;">${n.content}</div>
                    </div>
                </div>
                </c:forEach>
                </div>
            </c:otherwise>
        </c:choose>
    </div>
</div>

<script>
function toggleDetail(row) {
    const item = row.closest('.notice-item');
    const detail = item.querySelector('.notice-detail');
    const icon   = row.querySelector('.toggle-icon');
    const isOpen = detail.style.display === 'block';
    detail.style.display = isOpen ? 'none' : 'block';
    icon.className = isOpen ? 'bi bi-chevron-down ms-3 toggle-icon'
                            : 'bi bi-chevron-up ms-3 toggle-icon';
}

function filterType() {
    const type = document.getElementById('typeFilter').value;
    document.querySelectorAll('.notice-item').forEach(item => {
        item.style.display = (!type || item.dataset.type === type) ? '' : 'none';
    });
}
</script>
