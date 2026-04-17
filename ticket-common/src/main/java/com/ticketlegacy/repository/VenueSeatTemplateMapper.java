package com.ticketlegacy.repository;

import com.ticketlegacy.domain.VenueSeatTemplate;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface VenueSeatTemplateMapper {
    int insertBatch(@Param("templates") List<VenueSeatTemplate> templates);
    List<VenueSeatTemplate> findByVenueId(@Param("venueId") Long venueId);
    int countByVenueId(@Param("venueId") Long venueId);
    int deleteByVenueId(@Param("venueId") Long venueId);
    int deleteBySectionId(@Param("sectionId") Long sectionId);
}
