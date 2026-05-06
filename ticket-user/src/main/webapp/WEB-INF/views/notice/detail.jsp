<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<div class="container py-5" style="max-width: 900px;">
    <div class="mb-4">
        <a href="${pageContext.request.contextPath}/notice/list" class="text-decoration-none text-muted">
            <i class="bi bi-chevron-left"></i> 목록으로 돌아가기
        </a>
    </div>

    <div class="card border-0 shadow-sm" style="border-radius: var(--radius-md);">
        <div class="card-header bg-white p-4 border-bottom">
            <div class="mb-2">
                <span class="badge ${notice.noticeType == 'SYSTEM' ? 'bg-danger' : (notice.noticeType == 'EVENT' ? 'bg-primary' : 'bg-secondary')}">
                    ${notice.noticeType}
                </span>
            </div>
            <h3 class="fw-800 mb-3">${notice.title}</h3>
            <div class="d-flex text-muted font-size-sm">
                <div class="me-4"><i class="bi bi-calendar3 me-1"></i> ${tl:fmt(notice.createdAt, "yyyy.MM.dd HH:mm")}</div>
                <div><i class="bi bi-eye me-1"></i> ${notice.viewCount}</div>
            </div>
        </div>
        <div class="card-body p-4 p-md-5">
            <div class="notice-content" style="line-height: 1.8; font-size: 1.05rem;">
                ${notice.content}
            </div>
        </div>
    </div>
</div>

<style>
.notice-content img { max-width: 100%; height: auto; }
</style>
