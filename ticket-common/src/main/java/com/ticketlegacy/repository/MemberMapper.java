package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Member;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface MemberMapper {
    Member findByEmail(@Param("email") String email);
    Member findById(@Param("memberId") Long memberId);
    int insert(Member member);
    int updateLastLogin(@Param("memberId") Long memberId);
    int existsByEmail(@Param("email") String email);
    int updateStatus(@Param("memberId") Long memberId, @Param("status") String status);
    int countAll();

    List<Member> findAll(@Param("role") String role,
                         @Param("status") String status,
                         @Param("keyword") String keyword,
                         @Param("offset") int offset,
                         @Param("limit") int limit);

    int countFiltered(@Param("role") String role,
                      @Param("status") String status,
                      @Param("keyword") String keyword);
}
