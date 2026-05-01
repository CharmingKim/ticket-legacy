package com.ticketlegacy.repository;

import com.ticketlegacy.domain.MemberStatusHistory;
import org.apache.ibatis.annotations.Param;

import java.util.List;

public interface MemberStatusHistoryMapper {
    void insert(MemberStatusHistory history);
    List<MemberStatusHistory> findByMemberId(@Param("memberId") Long memberId);
}
