package com.ticketlegacy.service;

import com.ticketlegacy.domain.*;
import com.ticketlegacy.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminPerformanceService {

    private final PerformanceMapper performanceMapper;
    private final ScheduleMapper scheduleMapper;
    private final SeatMapper seatMapper;
    private final SeatInventoryMapper seatInventoryMapper;
    private final VenueSeatTemplateMapper venueSeatTemplateMapper;
    private final VenueSectionMapper venueSectionMapper;
    private final VenueStageConfigMapper venueStageConfigMapper;
    private final VenueStageSectionMapper venueStageSectionMapper;
    private final PerformanceSeatGradeMapper performanceSeatGradeMapper;
    private final PerformanceSectionOverrideMapper performanceSectionOverrideMapper;

    // ─────────────────────────────────────────────────
    // 회차(Schedule) 관리
    // ─────────────────────────────────────────────────

    public List<Schedule> findSchedulesByPerformanceId(Long performanceId) {
        return scheduleMapper.findByPerformanceId(performanceId);
    }

    @Transactional
    public Schedule createSchedule(Long performanceId, LocalDate showDate, LocalTime showTime) {
        Schedule s = new Schedule();
        s.setPerformanceId(performanceId);
        s.setShowDate(showDate);
        s.setShowTime(showTime);
        scheduleMapper.insert(s);
        log.info("회차 등록: scheduleId={}, performanceId={}, date={}", s.getScheduleId(), performanceId, showDate);
        return s;
    }

    // ─────────────────────────────────────────────────
    // 공연별 구역 오버라이드 조회
    // ─────────────────────────────────────────────────

    public List<PerformanceSectionOverride> findSectionOverrides(Long performanceId) {
        return performanceSectionOverrideMapper.findByPerformanceId(performanceId);
    }

    // ─────────────────────────────────────────────────
    // 공연별 등급/가격 설정
    // ─────────────────────────────────────────────────

    @Transactional
    public void savePerformanceSeatGrades(Long performanceId, List<PerformanceSeatGrade> grades) {
        performanceSeatGradeMapper.deleteByPerformanceId(performanceId);
        if (!grades.isEmpty()) {
            grades.forEach(g -> g.setPerformanceId(performanceId));
            performanceSeatGradeMapper.insertBatch(grades);
        }
        log.info("공연 등급/가격 설정: performanceId={}, {}구역", performanceId, grades.size());
    }

    // ─────────────────────────────────────────────────
    // 공연별 구역 오버라이드 설정
    // ─────────────────────────────────────────────────

    @Transactional
    public void savePerformanceSectionOverride(Long performanceId, PerformanceSectionOverride override) {
        override.setPerformanceId(performanceId);
        performanceSectionOverrideMapper.upsert(override);
        log.info("구역 오버라이드 저장: performanceId={}, sectionId={}, active={}",
                performanceId, override.getSectionId(), override.isActive());
    }

    @Transactional
    public void deletePerformanceSectionOverride(Long performanceId, Long sectionId) {
        performanceSectionOverrideMapper.deleteBySectionAndPerformance(performanceId, sectionId);
    }

    // ─────────────────────────────────────────────────
    // 핵심: 무대구성 기반 공연 좌석 생성 알고리즘
    //
    // 우선순위:
    //   1. performance_section_override (공연별 최종 결정)
    //   2. venue_stage_section (무대구성 프리셋)
    //   3. venue_section 기본값 (아무 설정 없으면)
    // ─────────────────────────────────────────────────

    @Transactional
    public int deleteSeats(Long performanceId) {
        int deleted = seatMapper.deleteByPerformanceId(performanceId);
        log.info("공연 좌석 전체 삭제: performanceId={}, {}석 삭제됨", performanceId, deleted);
        return deleted;
    }

    @Transactional
    public int generateSeats(Long performanceId) {
        Performance perf = performanceMapper.findById(performanceId);
        if (perf == null) throw new IllegalArgumentException("공연을 찾을 수 없습니다: " + performanceId);
        if (perf.getVenueId() == null) throw new IllegalStateException("공연에 공연장이 연결되지 않았습니다.");

        List<Seat> existing = seatMapper.findByPerformanceId(performanceId);
        if (!existing.isEmpty())
            throw new IllegalStateException("이미 " + existing.size() + "개의 좌석이 존재합니다. 삭제 후 재생성하세요.");

        // venue_section 전체 로드
        List<VenueSection> allSections = venueSectionMapper.findByVenueId(perf.getVenueId());
        if (allSections.isEmpty())
            throw new IllegalStateException("공연장에 구역이 등록되지 않았습니다.");

        // 등급/가격 확인 — 미설정 시 구역명 기반 자동 생성
        List<PerformanceSeatGrade> gradeList = performanceSeatGradeMapper.findByPerformanceId(performanceId);
        if (gradeList.isEmpty()) {
            gradeList = autoCreateGrades(performanceId, allSections);
            log.info("등급/가격 자동 생성: performanceId={}, {}구역", performanceId, gradeList.size());
        }
        Map<Long, PerformanceSeatGrade> gradeMap = gradeList.stream()
                .collect(Collectors.toMap(PerformanceSeatGrade::getSectionId, g -> g));

        // 무대구성 프리셋 로드 (stage_config_id 없으면 디폴트 사용)
        Long configId = perf.getStageConfigId();
        Map<Long, VenueStageSection> stageSectionMap = new HashMap<>();
        if (configId != null) {
            venueStageSectionMapper.findByConfigId(configId)
                    .forEach(ss -> stageSectionMap.put(ss.getSectionId(), ss));
        }

        // 공연별 오버라이드 로드
        Map<Long, PerformanceSectionOverride> overrideMap = new HashMap<>();
        performanceSectionOverrideMapper.findByPerformanceId(performanceId)
                .forEach(o -> overrideMap.put(o.getSectionId(), o));

        // venue_seat_template 로드 (section_id → templates)
        List<VenueSeatTemplate> allTemplates = venueSeatTemplateMapper.findByVenueId(perf.getVenueId());
        Map<Long, List<VenueSeatTemplate>> templatesBySectionId = allTemplates.stream()
                .collect(Collectors.groupingBy(VenueSeatTemplate::getSectionId));

        // ── 핵심 알고리즘 ──
        List<Seat> seats = new ArrayList<>();

        for (VenueSection section : allSections) {
            Long sectionId = section.getSectionId();
            PerformanceSeatGrade grade = gradeMap.get(sectionId);
            if (grade == null) continue; // 등급 미설정 구역 스킵

            // 1. 공연별 오버라이드 우선 적용
            PerformanceSectionOverride override = overrideMap.get(sectionId);
            if (override != null && !override.isActive()) {
                log.debug("공연 오버라이드로 KILL: sectionId={}", sectionId);
                continue; // 이 공연에서 해당 구역 전체 제거
            }

            // 2. 무대구성 프리셋 적용
            VenueStageSection stageSection = stageSectionMap.get(sectionId);
            if (stageSection != null && !stageSection.isActive()) {
                // 무대구성에서 KILL인데 공연 오버라이드가 명시적으로 active=true라면 복원
                if (override == null || !override.isActive()) {
                    log.debug("무대구성으로 KILL: sectionId={}", sectionId);
                    continue;
                }
            }

            // 3. 실제 사용할 행 수 / 열 수 결정 (우선순위: 공연오버라이드 > 무대구성 > 기본값)
            int effectiveRows = section.getTotalRows();
            int effectiveSeatsPerRow = section.getSeatsPerRow();

            if (stageSection != null) {
                if (stageSection.getCustomRows() != null) effectiveRows = stageSection.getCustomRows();
                if (stageSection.getCustomSeatsPerRow() != null) effectiveSeatsPerRow = stageSection.getCustomSeatsPerRow();
            }
            if (override != null) {
                if (override.getCustomRows() != null) effectiveRows = override.getCustomRows();
                if (override.getCustomSeatsPerRow() != null) effectiveSeatsPerRow = override.getCustomSeatsPerRow();
            }

            // 4. 좌석 생성
            List<VenueSeatTemplate> templates = templatesBySectionId.getOrDefault(sectionId, Collections.emptyList());

            if (templates.isEmpty()) {
                // 템플릿 없으면 행×열 기반으로 직접 생성
                seats.addAll(generateSeatsDirectly(perf.getPerformanceId(), section.getSectionName(),
                        grade, effectiveRows, effectiveSeatsPerRow));
            } else {
                // 템플릿 기반 생성 (effectiveRows/Cols 범위 내에서만)
                seats.addAll(generateSeatsFromTemplates(perf.getPerformanceId(), section.getSectionName(),
                        grade, templates, effectiveRows, effectiveSeatsPerRow));
            }
        }

        if (seats.isEmpty()) throw new IllegalStateException("생성할 좌석이 없습니다. 등급/가격 및 무대구성 설정을 확인하세요.");

        seatMapper.insertBatch(seats);
        perf.setTotalSeats(seats.size());
        performanceMapper.update(perf);
        log.info("공연 좌석 생성 완료: performanceId={}, 총{}석", performanceId, seats.size());
        return seats.size();
    }

    /** 템플릿 기반 좌석 생성 — effectiveRows/Cols 범위 이내의 템플릿만 사용 */
    private List<Seat> generateSeatsFromTemplates(Long performanceId, String sectionName,
                                                   PerformanceSeatGrade grade,
                                                   List<VenueSeatTemplate> templates,
                                                   int effectiveRows, int effectiveSeatsPerRow) {
        List<Seat> seats = new ArrayList<>();
        for (VenueSeatTemplate t : templates) {
            // 행/열 범위 초과 템플릿은 KILL (무대 때문에 제거된 영역)
            try {
                int row = Integer.parseInt(t.getSeatRow());
                if (row > effectiveRows) continue;
            } catch (NumberFormatException ignored) { /* ST 같은 특수 행은 통과 */ }
            if (t.getSeatNumber() > effectiveSeatsPerRow) continue;

            Seat seat = new Seat();
            seat.setPerformanceId(performanceId);
            seat.setSection(sectionName);
            seat.setSeatRow(t.getSeatRow());
            seat.setSeatNumber(t.getSeatNumber());
            seat.setGrade(grade.getGrade());
            seat.setPrice(grade.getPrice());
            seats.add(seat);
        }
        return seats;
    }

    /** 등급/가격 미설정 시 구역명 기반 자동 생성 */
    private List<PerformanceSeatGrade> autoCreateGrades(Long performanceId, List<VenueSection> sections) {
        Map<String, String[]> defaults = new java.util.LinkedHashMap<>();
        defaults.put("VIP석",  new String[]{"VIP", "150000"});
        defaults.put("VIP",    new String[]{"VIP", "130000"});
        defaults.put("R석",    new String[]{"R",   "110000"});
        defaults.put("S석",    new String[]{"S",   "85000"});
        defaults.put("A석",    new String[]{"A",   "60000"});
        defaults.put("스탠딩", new String[]{"A",   "55000"});

        List<PerformanceSeatGrade> grades = new ArrayList<>();
        for (VenueSection s : sections) {
            String[] def = defaults.getOrDefault(s.getSectionName(), new String[]{"S", "80000"});
            PerformanceSeatGrade g = new PerformanceSeatGrade();
            g.setPerformanceId(performanceId);
            g.setSectionId(s.getSectionId());
            g.setGrade(def[0]);
            g.setPrice(Integer.parseInt(def[1]));
            grades.add(g);
        }
        performanceSeatGradeMapper.insertBatch(grades);
        return grades;
    }

    /** 템플릿 없을 때 직접 행×열 생성 */
    private List<Seat> generateSeatsDirectly(Long performanceId, String sectionName,
                                              PerformanceSeatGrade grade,
                                              int rows, int seatsPerRow) {
        List<Seat> seats = new ArrayList<>();
        for (int r = 1; r <= rows; r++) {
            for (int n = 1; n <= seatsPerRow; n++) {
                Seat seat = new Seat();
                seat.setPerformanceId(performanceId);
                seat.setSection(sectionName);
                seat.setSeatRow(String.valueOf(r));
                seat.setSeatNumber(n);
                seat.setGrade(grade.getGrade());
                seat.setPrice(grade.getPrice());
                seats.add(seat);
            }
        }
        return seats;
    }

    // ─────────────────────────────────────────────────
    // 회차 인벤토리 활성화
    // ─────────────────────────────────────────────────

    @Transactional
    public void generateScheduleInventories(Long scheduleId) {
        List<SeatInventory> existing = seatInventoryMapper.findByScheduleId(scheduleId);
        if (!existing.isEmpty())
            throw new IllegalStateException("이미 " + existing.size() + "개의 인벤토리가 활성화되어 있습니다.");

        Schedule schedule = scheduleMapper.findById(scheduleId);
        if (schedule == null) throw new IllegalArgumentException("회차를 찾을 수 없습니다: " + scheduleId);

        List<Seat> seats = seatMapper.findByPerformanceId(schedule.getPerformanceId());
        if (seats.isEmpty())
            throw new IllegalStateException("공연 좌석이 없습니다. 먼저 좌석을 생성하세요.");

        List<SeatInventory> inventories = seats.stream().map(seat -> {
            SeatInventory inv = new SeatInventory();
            inv.setScheduleId(scheduleId);
            inv.setSeatId(seat.getSeatId());
            inv.setStatus("AVAILABLE");
            inv.setHoldType("PUBLIC");
            return inv;
        }).collect(Collectors.toList());

        seatInventoryMapper.insertBatch(inventories);
        scheduleMapper.updateAvailableSeats(scheduleId, inventories.size());
        log.info("인벤토리 활성화: scheduleId={}, {}석", scheduleId, inventories.size());
    }

    // ─────────────────────────────────────────────────
    // 관리자 hold_type 변경 (KILL/COMP/ADMIN 처리)
    // ─────────────────────────────────────────────────

    @Transactional
    public void updateHoldType(Long scheduleId, List<Long> seatIds, String holdType) {
        seatInventoryMapper.updateHoldType(scheduleId, seatIds, holdType);
        // available_seats 재계산
        int publicCount = seatInventoryMapper.countPublicAvailable(scheduleId);
        scheduleMapper.updateAvailableSeats(scheduleId, publicCount);
        log.info("hold_type 변경: scheduleId={}, {}석 → {}", scheduleId, seatIds.size(), holdType);
    }
}
