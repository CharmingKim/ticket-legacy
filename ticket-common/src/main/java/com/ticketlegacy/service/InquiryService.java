package com.ticketlegacy.service;

import com.ticketlegacy.domain.Inquiry;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.repository.InquiryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class InquiryService {

    @Autowired
    private InquiryMapper inquiryMapper;

    @Transactional
    public void writeInquiry(Inquiry inquiry) {
        inquiryMapper.insert(inquiry);
    }

    public Inquiry getInquiry(Long inquiryId, Long memberId) {
        Inquiry inquiry = inquiryMapper.findById(inquiryId);
        if (inquiry == null) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "문의 내역을 찾을 수 없습니다.");
        }
        if (!inquiry.getMemberId().equals(memberId)) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "접근 권한이 없습니다.");
        }
        return inquiry;
    }

    public List<Inquiry> getMyInquiries(Long memberId, int page, int size) {
        return inquiryMapper.findByMemberId(memberId, (page - 1) * size, size);
    }

    public int getMyInquiryCount(Long memberId) {
        return inquiryMapper.countByMemberId(memberId);
    }

    @Transactional
    public void deleteInquiry(Long inquiryId, Long memberId) {
        Inquiry inquiry = getInquiry(inquiryId, memberId);
        inquiryMapper.delete(inquiryId);
    }
}
