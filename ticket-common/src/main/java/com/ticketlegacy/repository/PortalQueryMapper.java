package com.ticketlegacy.repository;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

@Mapper
public interface PortalQueryMapper {
    Map<String, Object> findPromoterFinancialSummary(@Param("promoterId") Long promoterId);
    List<Map<String, Object>> findPromoterSalesRows(@Param("promoterId") Long promoterId);
    List<Map<String, Object>> findSettlementRows(@Param("promoterId") Long promoterId,
                                                 @Param("yearMonth") String yearMonth);
    List<Map<String, Object>> findEntranceCandidates(@Param("venueId") Long venueId,
                                                     @Param("showDate") String showDate,
                                                     @Param("keyword") String keyword);
}
