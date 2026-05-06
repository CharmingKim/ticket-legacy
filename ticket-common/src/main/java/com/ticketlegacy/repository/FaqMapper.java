package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Faq;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface FaqMapper {
    List<Faq> findActive(@Param("category") String category);
    List<String> findAllCategories();
    
    // For admin
    int insert(Faq faq);
    int update(Faq faq);
    int delete(@Param("faqId") Long faqId);
}
