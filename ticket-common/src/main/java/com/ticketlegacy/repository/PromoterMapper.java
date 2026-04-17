package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Promoter;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface PromoterMapper {
    Promoter findById(@Param("promoterId") Long promoterId);
    Promoter findByMemberId(@Param("memberId") Long memberId);
    List<Promoter> findByStatus(@Param("status") String status,
                                 @Param("offset") int offset,
                                 @Param("limit") int limit);
    int countByStatus(@Param("status") String status);
    List<Promoter> findAll(@Param("offset") int offset, @Param("limit") int limit);
    int countAll();
    int insert(Promoter promoter);
    int updateApproval(@Param("promoterId") Long promoterId,
                       @Param("approvalStatus") String approvalStatus,
                       @Param("approvedBy") Long approvedBy,
                       @Param("rejectReason") String rejectReason);
}
