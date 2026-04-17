package com.ticketlegacy.repository;

import com.ticketlegacy.domain.VenueSection;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface VenueSectionMapper {
    int insert(VenueSection section);
    List<VenueSection> findByVenueId(@Param("venueId") Long venueId);
    VenueSection findById(@Param("sectionId") Long sectionId);
    int deleteById(@Param("sectionId") Long sectionId);
    int deleteByVenueId(@Param("venueId") Long venueId);
}
