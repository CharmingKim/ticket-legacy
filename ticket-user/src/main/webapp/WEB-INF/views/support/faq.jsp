<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<div class="container py-5" style="max-width: 900px;">
    <div class="text-center mb-5">
        <h2 class="fw-800">자주 묻는 질문 (FAQ)</h2>
        <p class="text-muted">도움이 필요하신가요? 가장 많이 하시는 질문들을 모았습니다.</p>
    </div>

    <!-- Category Tabs -->
    <ul class="nav nav-tabs justify-content-center border-0 mb-4 gap-2">
        <li class="nav-item">
            <a class="nav-link rounded-pill px-4 ${empty currentCategory ? 'bg-dark text-white active' : 'bg-light text-dark'}" 
               href="?category=">전체</a>
        </li>
        <li class="nav-item">
            <a class="nav-link rounded-pill px-4 ${currentCategory == 'PAYMENT' ? 'bg-dark text-white active' : 'bg-light text-dark'}" 
               href="?category=PAYMENT">결제/환불</a>
        </li>
        <li class="nav-item">
            <a class="nav-link rounded-pill px-4 ${currentCategory == 'TICKET' ? 'bg-dark text-white active' : 'bg-light text-dark'}" 
               href="?category=TICKET">티켓/입장</a>
        </li>
        <li class="nav-item">
            <a class="nav-link rounded-pill px-4 ${currentCategory == 'ACCOUNT' ? 'bg-dark text-white active' : 'bg-light text-dark'}" 
               href="?category=ACCOUNT">회원정보</a>
        </li>
        <li class="nav-item">
            <a class="nav-link rounded-pill px-4 ${currentCategory == 'OTHER' ? 'bg-dark text-white active' : 'bg-light text-dark'}" 
               href="?category=OTHER">기타</a>
        </li>
    </ul>

    <!-- FAQ Accordion -->
    <div class="accordion accordion-flush shadow-sm" id="faqAccordion" style="border-radius: var(--radius-md); overflow: hidden;">
        <c:choose>
            <c:when test="${not empty faqs}">
                <c:forEach var="f" items="${faqs}" varStatus="status">
                    <div class="accordion-item border-bottom">
                        <h2 class="accordion-header">
                            <button class="accordion-button collapsed py-4 fw-600" type="button" 
                                    data-bs-toggle="collapse" data-bs-target="#faq-content-${f.faqId}">
                                <span class="text-primary me-3 fw-800">Q.</span> ${f.question}
                            </button>
                        </h2>
                        <div id="faq-content-${f.faqId}" class="accordion-collapse collapse" data-bs-parent="#faqAccordion">
                            <div class="accordion-body bg-light py-4 ps-5">
                                <div class="d-flex gap-3">
                                    <span class="text-danger fw-800">A.</span>
                                    <div style="line-height: 1.8; color: var(--gray-700); white-space: pre-wrap;">${f.answer}</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </c:forEach>
            </c:when>
            <c:otherwise>
                <div class="text-center py-5 bg-white">
                    <p class="text-muted mb-0">등록된 질문이 없습니다.</p>
                </div>
            </c:otherwise>
        </c:choose>
    </div>

    <!-- Contact CTA -->
    <div class="mt-5 p-4 bg-light text-center" style="border-radius: var(--radius-md);">
        <p class="mb-3 fw-600">찾으시는 답변이 없으신가요?</p>
        <a href="${pageContext.request.contextPath}/inquiry/list" class="tl-btn-outline">
            <i class="bi bi-headset me-2"></i>1:1 문의하기
        </a>
    </div>
</div>

<style>
.accordion-button:not(.collapsed) {
    background-color: transparent;
    color: var(--primary);
    box-shadow: none;
}
.accordion-button:focus {
    box-shadow: none;
}
</style>
