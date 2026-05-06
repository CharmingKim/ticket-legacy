package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Member;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface MemberMapper {
    Member findByEmail(@Param("email") String email);
    Member findById(@Param("memberId") Long memberId);
    Member findByProvider(@Param("provider") String provider, @Param("providerId") String providerId);
    int insert(Member member);
    int updateLastLogin(@Param("memberId") Long memberId);
    int existsByEmail(@Param("email") String email);
    int updateStatus(@Param("memberId") Long memberId, @Param("status") String status);
    int updatePassword(@Param("memberId") Long memberId, @Param("password") String password);
    int updateProfile(@Param("memberId") Long memberId, @Param("name") String name, @Param("phone") String phone);
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
