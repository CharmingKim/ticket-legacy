package com.ticketlegacy.service;

import com.ticketlegacy.domain.Faq;
import com.ticketlegacy.repository.FaqMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class FaqService {

    @Autowired
    private FaqMapper faqMapper;

    public List<Faq> getActiveFaqs(String category) {
        return faqMapper.findActive(category);
    }

    public List<String> getCategories() {
        return faqMapper.findAllCategories();
    }
}
