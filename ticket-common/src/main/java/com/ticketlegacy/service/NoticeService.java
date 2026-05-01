package com.ticketlegacy.service;

import com.ticketlegacy.domain.Notice;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.repository.NoticeMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
public class NoticeService {

    @Autowired private NoticeMapper noticeMapper;

    @Transactional
    public Notice create(Notice notice) {
        noticeMapper.insert(notice);
        return notice;
    }

    @Transactional
    public Notice findById(Long noticeId) {
        Notice n = noticeMapper.findById(noticeId);
        if (n == null) throw new BusinessException(ErrorCode.INVALID_INPUT, "공지사항을 찾을 수 없습니다.");
        noticeMapper.incrementViewCount(noticeId);
        return n;
    }

    public List<Notice> findActiveForRole(String role) {
        return noticeMapper.findActive(role, 20);
    }

    public List<Notice> findAll(String noticeType, int page) {
        return noticeMapper.findAll(noticeType, (page - 1) * 20, 20);
    }

    public int countAll(String noticeType) {
        return noticeMapper.countAll(noticeType);
    }

    @Transactional
    public void update(Notice notice) {
        noticeMapper.update(notice);
    }

    @Transactional
    public void deactivate(Long noticeId) {
        noticeMapper.deactivate(noticeId);
    }
}
