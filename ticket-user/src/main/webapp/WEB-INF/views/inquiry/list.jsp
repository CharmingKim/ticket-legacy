<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<div class="container py-5">
    <div class="d-flex justify-content-between align-items-end mb-4">
        <div>
            <h3 class="fw-800">1:1 문의</h3>
            <p class="text-muted mb-0">궁금한 점이나 불편한 사항을 남겨주시면 빠르게 답변해 드리겠습니다.</p>
        </div>
        <a href="${pageContext.request.contextPath}/inquiry/write" class="tl-btn-primary">
            <i class="bi bi-pencil-square me-2"></i>문의하기
        </a>
    </div>

    <div class="card border-0 shadow-sm" style="border-radius: var(--radius-md);">
        <div class="table-responsive">
            <table class="table mb-0 tl-table">
                <thead class="bg-light">
                    <tr>
                        <th class="ps-4" style="width: 120px;">상태</th>
                        <th style="width: 150px;">카테고리</th>
                        <th>제목</th>
                        <th class="pe-4" style="width: 150px;">등록일</th>
                    </tr>
                </thead>
                <tbody>
                    <c:choose>
                        <c:when test="${not empty inquiries}">
                            <c:forEach var="i" items="${inquiries}">
                                <tr onclick="location.href='${pageContext.request.contextPath}/inquiry/detail/${i.inquiryId}'" style="cursor: pointer;">
                                    <td class="ps-4">
                                        <span class="badge ${i.status == 'PENDING' ? 'bg-warning text-dark' : (i.status == 'ANSWERED' ? 'bg-success' : 'bg-secondary')}">
                                            ${i.status == 'PENDING' ? '답변대기' : (i.status == 'ANSWERED' ? '답변완료' : '종료')}
                                        </span>
                                    </td>
                                    <td class="text-muted">${i.category}</td>
                                    <td class="fw-600 text-dark">${i.title}</td>
                                    <td class="pe-4 text-muted">${tl:fmt(i.createdAt, "yyyy.MM.dd")}</td>
                                </tr>
                            </c:forEach>
                        </c:when>
                        <c:otherwise>
                            <tr>
                                <td colspan="4" class="text-center py-5 text-muted">
                                    문의 내역이 없습니다.
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
                <c:forEach var="p" begin="1" end="${totalPages}">
                    <li class="page-item ${currentPage == p ? 'active' : ''}">
                        <a class="page-link" href="?page=${p}">${p}</a>
                    </li>
                </c:forEach>
            </ul>
        </nav>
    </c:if>
</div>
