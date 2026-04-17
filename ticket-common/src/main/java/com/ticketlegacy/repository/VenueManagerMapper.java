package com.ticketlegacy.repository;

import com.ticketlegacy.domain.VenueManager;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface VenueManagerMapper {
    VenueManager findById(@Param("managerId") Long managerId);
    VenueManager findByMemberId(@Param("memberId") Long memberId);
    List<VenueManager> findByStatus(@Param("status") String status,
                                     @Param("offset") int offset,
                                     @Param("limit") int limit);
    int countByStatus(@Param("status") String status);
    int insert(VenueManager venueManager);
    int updateApproval(@Param("managerId") Long managerId,
                       @Param("approvalStatus") String approvalStatus,
                       @Param("approvedBy") Long approvedBy);
}
