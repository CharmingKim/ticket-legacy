package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Notice;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface NoticeMapper {
    int insert(Notice notice);
    Notice findById(@Param("noticeId") Long noticeId);
    List<Notice> findActive(@Param("targetRole") String targetRole,
                            @Param("limit") int limit);
    List<Notice> findAll(@Param("noticeType") String noticeType,
                         @Param("offset") int offset,
                         @Param("limit") int limit);
    int countAll(@Param("noticeType") String noticeType);
    int update(Notice notice);
    int incrementViewCount(@Param("noticeId") Long noticeId);
    int deactivate(@Param("noticeId") Long noticeId);
}
