package com.ticketlegacy.repository;

import com.ticketlegacy.domain.VenueStageSection;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface VenueStageSectionMapper {
    int insert(VenueStageSection section);
    int upsert(VenueStageSection section);
    List<VenueStageSection> findByConfigId(@Param("configId") Long configId);
    int deleteByConfigId(@Param("configId") Long configId);
    int deleteBySectionId(@Param("sectionId") Long sectionId);
}
