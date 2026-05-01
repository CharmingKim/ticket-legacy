package com.ticketlegacy.web.controller;

import com.ticketlegacy.service.PortalDashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.Map;

/**
 * SUPER_ADMIN 정산 API.
 * 대시보드 endpoint 들은 BackofficeSuperController 에 통합 (merged PENDING+APPROVED 로직 유지).
 * 본 컨트롤러는 정산만 담당.
 */
@Controller
@RequiredArgsConstructor
@RequestMapping("/backoffice/super")
public class BackofficeSuperAnalyticsController {

    private final PortalDashboardService portalDashboardService;

    @GetMapping("/api/settlement/report")
    @ResponseBody
    public ResponseEntity<?> settlementReport(@RequestParam(required = false) Long promoterId,
                                              @RequestParam(required = false) String yearMonth) {
        return ResponseEntity.ok(Map.of(
                "yearMonth", yearMonth == null || yearMonth.isBlank()
                        ? portalDashboardService.defaultYearMonth()
                        : yearMonth,
                "rows", portalDashboardService.getSettlementRows(promoterId, yearMonth)
        ));
    }
}
