package com.ticketlegacy.repository;

import com.ticketlegacy.domain.Venue;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface VenueMapper {
    int insert(Venue venue);
    int update(Venue venue);
    Venue findById(@Param("venueId") Long venueId);
    Venue findByApiId(@Param("apiFacilityId") String apiFacilityId);
    List<Venue> findAll();
}
