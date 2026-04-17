package com.ticketlegacy.service;

import com.ticketlegacy.domain.Performance;
import com.ticketlegacy.domain.Schedule;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.repository.PerformanceMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PerformanceService {
    @Autowired private PerformanceMapper performanceMapper;

    public List<Performance> findAll(String category, String status, String keyword, int page, int size) {
        return performanceMapper.findAll(category, status, keyword, (page - 1) * size, size);
    }
    public List<Performance> findAll(String category, String status, int page, int size) {
        return findAll(category, status, null, page, size);
    }
    public int countAll(String category, String status, String keyword) {
        return performanceMapper.countAll(category, status, keyword);
    }
    public int countAll(String category, String status) {
        return countAll(category, status, null);
    }
    public Performance findById(Long id) {
        Performance p = performanceMapper.findById(id);
        if (p == null) throw new BusinessException(ErrorCode.PERFORMANCE_NOT_FOUND);
        return p;
    }
    public List<Schedule> findSchedules(Long performanceId) {
        return performanceMapper.findSchedules(performanceId);
    }
}
