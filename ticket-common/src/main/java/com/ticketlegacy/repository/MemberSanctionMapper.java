package com.ticketlegacy.repository;

import com.ticketlegacy.domain.MemberSanction;
import org.apache.ibatis.annotations.Param;

import java.util.List;

public interface MemberSanctionMapper {
    void insert(MemberSanction sanction);
    List<MemberSanction> findByMemberId(@Param("memberId") Long memberId);
}
