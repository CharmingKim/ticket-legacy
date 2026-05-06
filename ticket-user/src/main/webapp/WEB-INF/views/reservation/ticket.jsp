<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="tl" uri="http://ticketlegacy.com/tl" %>

<section class="tl-section">
    <div class="container d-flex justify-content-center">
        <div class="card border-0 shadow" style="border-radius: 16px; max-width: 400px; width: 100%; overflow: hidden;">
            <div class="bg-primary text-white text-center p-4">
                <div class="fw-800" style="font-size: 1.5rem; letter-spacing: -1px;">E-TICKET</div>
                <div class="opacity-75 mt-1" style="font-size: 0.9rem;">본 모바일 티켓으로 바로 입장 가능합니다.</div>
            </div>
            
            <div class="card-body p-4 bg-white">
                <div class="text-center mb-4">
                    <h4 class="fw-800 mb-1 text-dark">${reservation.performanceTitle}</h4>
                    <p class="text-muted mb-0" style="font-size: 0.95rem;">${reservation.venue}</p>
                </div>
                
                <div class="d-flex justify-content-center mb-4">
                    <div id="qrcode" class="p-2 border" style="border-radius: 12px; background: #fff;"></div>
                </div>
                
                <div class="text-center mb-4">
                    <div class="text-muted" style="font-size: 0.8rem;">예매 번호</div>
                    <div class="fw-700" style="font-size: 1.2rem; letter-spacing: 2px;">${reservation.reservationNo}</div>
                </div>
                
                <hr style="border-style: dashed;">
                
                <div class="row text-center mt-4">
                    <div class="col-6 border-end">
                        <div class="text-muted" style="font-size: 0.8rem;">일시</div>
                        <div class="fw-700">${tl:fmt(reservation.showDate, "yyyy.MM.dd")}</div>
                        <div class="fw-700">${reservation.showTime}</div>
                    </div>
                    <div class="col-6">
                        <div class="text-muted" style="font-size: 0.8rem;">예매자</div>
                        <div class="fw-700">${reservation.memberName}</div>
                        <div class="fw-700" style="font-size: 0.9rem;">${reservation.seatCount}매</div>
                    </div>
                </div>
                
                <div class="mt-4 p-3 bg-light" style="border-radius: 8px;">
                    <div class="text-muted mb-2" style="font-size: 0.8rem;">좌석 정보</div>
                    <c:forEach var="seat" items="${reservation.seats}">
                        <div class="fw-600 text-dark" style="font-size: 0.95rem;">
                            <span class="badge bg-secondary me-2">${seat.grade}</span> ${seat.section}구역 ${seat.seatRow}열 ${seat.seatNumber}번
                        </div>
                    </c:forEach>
                </div>
            </div>
            
            <div class="bg-dark text-white text-center p-3" style="font-size: 0.8rem;">
                입장 시 이 화면을 진행 요원에게 보여주세요.<br>
                화면 캡처본은 입장이 제한될 수 있습니다.
            </div>
        </div>
    </div>
</section>

<!-- qrcode.js -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
<script>
$(function() {
    // QR Code 생성 로직: 입장 검증을 위해 예매 번호와 ID가 포함된 정보
    const qrData = JSON.stringify({
        rsv_id: '${reservation.reservationId}',
        rsv_no: '${reservation.reservationNo}',
        member: '${reservation.memberId}'
    });
    
    new QRCode(document.getElementById("qrcode"), {
        text: qrData,
        width: 180,
        height: 180,
        colorDark : "#000000",
        colorLight : "#ffffff",
        correctLevel : QRCode.CorrectLevel.H
    });
});
</script>
