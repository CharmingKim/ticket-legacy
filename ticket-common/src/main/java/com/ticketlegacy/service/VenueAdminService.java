package com.ticketlegacy.service;

import com.ticketlegacy.domain.Venue;
import com.ticketlegacy.domain.VenueSection;
import com.ticketlegacy.domain.VenueSeatTemplate;
import com.ticketlegacy.repository.VenueMapper;
import com.ticketlegacy.repository.VenueSectionMapper;
import com.ticketlegacy.repository.VenueSeatTemplateMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class VenueAdminService {

    private final VenueMapper venueMapper;
    private final VenueSectionMapper venueSectionMapper;
    private final VenueSeatTemplateMapper venueSeatTemplateMapper;

    /** 공연장 등록 */
    @Transactional
    public Venue createVenue(String name, String address, Integer seatScale) {
        Venue venue = new Venue();
        venue.setName(name);
        venue.setAddress(address);
        venue.setSeatScale(seatScale);
        venueMapper.insert(venue);
        log.info("공연장 등록: venueId={}, name={}", venue.getVenueId(), name);
        return venue;
    }

    /** 공연장 전체 목록 */
    public List<Venue> findAllVenues() {
        return venueMapper.findAll();
    }

    /** 공연장 단건 조회 */
    public Venue findVenueById(Long venueId) {
        Venue v = venueMapper.findById(venueId);
        if (v == null) throw new IllegalArgumentException("공연장을 찾을 수 없습니다: venueId=" + venueId);
        return v;
    }

    /** 구역 목록 조회 (템플릿 좌석 수 포함) */
    public List<VenueSection> findSectionsByVenueId(Long venueId) {
        return venueSectionMapper.findByVenueId(venueId);
    }

    /** 구역 등록 */
    @Transactional
    public VenueSection addSection(Long venueId, String sectionName, String sectionType,
                                    int totalRows, int seatsPerRow, int displayOrder) {
        VenueSection section = new VenueSection();
        section.setVenueId(venueId);
        section.setSectionName(sectionName);
        section.setSectionType(sectionType);
        section.setTotalRows(totalRows);
        section.setSeatsPerRow(seatsPerRow);
        section.setDisplayOrder(displayOrder);
        venueSectionMapper.insert(section);
        log.info("구역 등록: sectionId={}, venueId={}, name={}", section.getSectionId(), venueId, sectionName);
        return section;
    }

    /** 구역 삭제 (해당 구역 템플릿 좌석도 함께 삭제) */
    @Transactional
    public void deleteSection(Long sectionId) {
        venueSeatTemplateMapper.deleteBySectionId(sectionId);
        venueSectionMapper.deleteById(sectionId);
        log.info("구역 삭제: sectionId={}", sectionId);
    }

    /**
     * 공연장 좌석 템플릿 자동 생성
     * venue_section 설정(행 수 × 좌석 수)을 기반으로 venue_seat_template 레코드를 일괄 생성.
     * 기존 템플릿이 있으면 전체 재생성(삭제 후 재삽입).
     */
    @Transactional
    public int generateTemplate(Long venueId) {
        List<VenueSection> sections = venueSectionMapper.findByVenueId(venueId);
        if (sections.isEmpty()) {
            throw new IllegalStateException("구역이 등록되지 않은 공연장입니다. 먼저 구역을 추가해주세요.");
        }

        // 기존 템플릿 전체 삭제 후 재생성
        venueSeatTemplateMapper.deleteByVenueId(venueId);

        List<VenueSeatTemplate> templates = new ArrayList<>();
        for (VenueSection section : sections) {
            if ("STANDING".equals(section.getSectionType())) {
                // 스탠딩 구역은 좌석 번호 없이 단일 레코드
                VenueSeatTemplate t = new VenueSeatTemplate();
                t.setVenueId(venueId);
                t.setSectionId(section.getSectionId());
                t.setSeatRow("ST");
                t.setSeatNumber(1);
                t.setSeatType("NORMAL");
                templates.add(t);
            } else {
                for (int row = 1; row <= section.getTotalRows(); row++) {
                    for (int num = 1; num <= section.getSeatsPerRow(); num++) {
                        VenueSeatTemplate t = new VenueSeatTemplate();
                        t.setVenueId(venueId);
                        t.setSectionId(section.getSectionId());
                        t.setSeatRow(String.valueOf(row));
                        t.setSeatNumber(num);
                        // 맨 앞줄 첫 번째/마지막 좌석은 장애인석으로 지정 (실무 관례)
                        if (row == 1 && (num == 1 || num == section.getSeatsPerRow())) {
                            t.setSeatType("ACCESSIBLE");
                        } else {
                            t.setSeatType("NORMAL");
                        }
                        templates.add(t);
                    }
                }
            }
        }

        if (!templates.isEmpty()) {
            venueSeatTemplateMapper.insertBatch(templates);
        }
        log.info("좌석 템플릿 생성 완료: venueId={}, 총 {}석", venueId, templates.size());
        return templates.size();
    }

    /** 공연장별 템플릿 좌석 수 조회 */
    public int getTemplateCount(Long venueId) {
        return venueSeatTemplateMapper.countByVenueId(venueId);
    }
}
