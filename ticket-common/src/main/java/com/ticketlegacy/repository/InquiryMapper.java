package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Inquiry;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface InquiryMapper {
    int insert(Inquiry inquiry);
    Inquiry findById(@Param("inquiryId") Long inquiryId);
    List<Inquiry> findByMemberId(@Param("memberId") Long memberId, @Param("offset") int offset, @Param("limit") int limit);
    int countByMemberId(@Param("memberId") Long memberId);
    
    // For admin
    int updateAnswer(Inquiry inquiry);
    int delete(@Param("inquiryId") Long inquiryId);
}
