package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Wishlist;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface WishlistMapper {
    int insert(@Param("memberId") Long memberId, @Param("performanceId") Long performanceId);
    int delete(@Param("memberId") Long memberId, @Param("performanceId") Long performanceId);
    int checkWish(@Param("memberId") Long memberId, @Param("performanceId") Long performanceId);
    
    List<Wishlist> findByMemberId(@Param("memberId") Long memberId);
    int countByPerformanceId(@Param("performanceId") Long performanceId);
}
