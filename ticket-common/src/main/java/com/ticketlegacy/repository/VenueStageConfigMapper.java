package com.ticketlegacy.repository;

import com.ticketlegacy.domain.VenueStageConfig;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface VenueStageConfigMapper {
    int insert(VenueStageConfig config);
    List<VenueStageConfig> findByVenueId(@Param("venueId") Long venueId);
    VenueStageConfig findById(@Param("configId") Long configId);
    VenueStageConfig findDefaultByVenueId(@Param("venueId") Long venueId);
    int deleteById(@Param("configId") Long configId);
}
