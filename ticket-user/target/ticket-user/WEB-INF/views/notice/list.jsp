<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<div class="container py-5">
    <div class="mb-5 text-center">
        <h2 class="fw-800">공지사항</h2>
        <p class="text-muted">TicketLegacy의 새로운 소식과 안내를 확인하세요.</p>
    </div>

    <!-- Type Filter -->
    <div class="d-flex justify-content-center gap-2 mb-4">
        <a href="?type=" class="btn ${empty currentType ? 'btn-dark' : 'btn-outline-dark'} px-4 rounded-pill">전체</a>
        <a href="?type=SYSTEM" class="btn ${currentType == 'SYSTEM' ? 'btn-dark' : 'btn-outline-dark'} px-4 rounded-pill">시스템</a>
        <a href="?type=EVENT" class="btn ${currentType == 'EVENT' ? 'btn-dark' : 'btn-outline-dark'} px-4 rounded-pill">이벤트</a>
        <a href="?type=NOTICE" class="btn ${currentType == 'NOTICE' ? 'btn-dark' : 'btn-outline-dark'} px-4 rounded-pill">안내</a>
    </div>

    <div class="card border-0 shadow-sm" style="border-radius: var(--radius-md);">
        <div class="table-responsive">
            <table class="table mb-0 tl-table">
                <thead class="bg-light">
                    <tr>
                        <th class="ps-4" style="width: 100px;">구분</th>
                        <th>제목</th>
                        <th style="width: 150px;">등록일</th>
                        <th class="pe-4" style="width: 100px;">조회수</th>
                    </tr>
                </thead>
                <tbody>
                    <c:choose>
                        <c:when test="${not empty notices}">
                            <c:forEach var="n" items="${notices}">
                                <tr onclick="location.href='${pageContext.request.contextPath}/notice/detail/${n.noticeId}'" style="cursor: pointer;">
                                    <td class="ps-4">
                                        <span class="badge ${n.noticeType == 'SYSTEM' ? 'bg-danger' : (n.noticeType == 'EVENT' ? 'bg-primary' : 'bg-secondary')}">
                                            ${n.noticeType}
                                        </span>
                                    </td>
                                    <td class="fw-600 text-dark">${n.title}</td>
                                    <td>${tl:fmt(n.createdAt, "yyyy.MM.dd")}</td>
                                    <td class="pe-4 text-muted">${n.viewCount}</td>
                                </tr>
                            </c:forEach>
                        </c:when>
                        <c:otherwise>
                            <tr>
                                <td colspan="4" class="text-center py-5 text-muted">
                                    공지사항이 없습니다.
                                </td>
                            </tr>
                        </c:otherwise>
                    </c:choose>
                </tbody>
            </table>
        </div>
    </div>

    <!-- Pagination -->
    <c:if test="${totalPages > 1}">
        <nav class="mt-4">
            <ul class="pagination justify-content-center">
                <c:forEach var="i" begin="1" end="${totalPages}">
                    <li class="page-item ${currentPage == i ? 'active' : ''}">
                        <a class="page-link" href="?page=${i}&type=${currentType}">${i}</a>
                    </li>
                </c:forEach>
            </ul>
        </nav>
    </c:if>
</div>
