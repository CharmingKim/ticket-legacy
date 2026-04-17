package com.ticketlegacy.service;

import com.ticketlegacy.domain.Member;
import com.ticketlegacy.domain.VenueManager;
import com.ticketlegacy.exception.BusinessException;
import com.ticketlegacy.exception.ErrorCode;
import com.ticketlegacy.repository.MemberMapper;
import com.ticketlegacy.repository.VenueManagerMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class VenueManagerService {

    private final VenueManagerMapper    venueManagerMapper;
    private final MemberMapper          memberMapper;
    private final BCryptPasswordEncoder passwordEncoder;

    // ──────────────────────────────────────────
    // 공연장 담당자 가입 신청
    // ──────────────────────────────────────────

    @Transactional
    public void registerVenueManager(Map<String, Object> body) {
        String email   = (String) body.get("email");
        Long   venueId = ((Number) body.get("venueId")).longValue();

        if (memberMapper.existsByEmail(email) > 0) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_DUPLICATE);
        }

        Member member = new Member();
        member.setEmail(email);
        member.setPassword(passwordEncoder.encode((String) body.get("password")));
        member.setName((String) body.get("name"));
        member.setPhone((String) body.get("phone"));
        member.setRole("VENUE_MANAGER");
        member.setStatus("PENDING_APPROVAL");
        memberMapper.insert(member);

        VenueManager vm = new VenueManager();
        vm.setMemberId(member.getMemberId());
        vm.setVenueId(venueId);
        vm.setDepartment((String) body.get("department"));
        vm.setPosition((String) body.get("position"));
        vm.setApprovalStatus("PENDING");
        venueManagerMapper.insert(vm);

        log.info("공연장 담당자 가입 신청: email={}, venueId={}", email, venueId);
    }

    // ──────────────────────────────────────────
    // SUPER_ADMIN: 담당자 승인/반려
    // ──────────────────────────────────────────

    @Transactional
    public void approveVenueManager(Long managerId, Long adminMemberId) {
        VenueManager vm = getOrThrow(managerId);
        if (!"PENDING".equals(vm.getApprovalStatus())) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "승인 대기 상태만 승인 가능합니다.");
        }
        venueManagerMapper.updateApproval(managerId, "APPROVED", adminMemberId);
        memberMapper.updateStatus(vm.getMemberId(), "ACTIVE");
        log.info("공연장 담당자 승인: managerId={}", managerId);
    }

    @Transactional
    public void rejectVenueManager(Long managerId, Long adminMemberId) {
        VenueManager vm = getOrThrow(managerId);
        venueManagerMapper.updateApproval(managerId, "REJECTED", adminMemberId);
        memberMapper.updateStatus(vm.getMemberId(), "DORMANT");
        log.info("공연장 담당자 반려: managerId={}", managerId);
    }

    // ──────────────────────────────────────────
    // 조회 / 검증
    // ──────────────────────────────────────────

    public List<VenueManager> findByStatus(String status, int page, int size) {
        int offset = (page - 1) * size;
        return venueManagerMapper.findByStatus(status, offset, size);
    }

    public int countByStatus(String status) {
        return venueManagerMapper.countByStatus(status);
    }

    /**
     * memberId로 담당 venueId 반환 (APPROVED 상태만).
     */
    public Long getVenueIdByMemberId(Long memberId) {
        VenueManager vm = venueManagerMapper.findByMemberId(memberId);
        if (vm == null) throw new BusinessException(ErrorCode.VENUE_MANAGER_NOT_FOUND);
        if (!"APPROVED".equals(vm.getApprovalStatus())) {
            throw new BusinessException(ErrorCode.VENUE_MANAGER_NOT_APPROVED);
        }
        return vm.getVenueId();
    }

    public VenueManager getByMemberId(Long memberId) {
        VenueManager vm = venueManagerMapper.findByMemberId(memberId);
        if (vm == null) throw new BusinessException(ErrorCode.VENUE_MANAGER_NOT_FOUND);
        return vm;
    }

    /**
     * memberId가 해당 venueId의 담당자인지 검증.
     */
    public void verifyVenueOwnership(Long memberId, Long venueId) {
        Long myVenueId = getVenueIdByMemberId(memberId);
        if (!myVenueId.equals(venueId)) {
            throw new BusinessException(ErrorCode.VENUE_MANAGER_FORBIDDEN);
        }
    }

    /**
     * 섹션이 공연 좌석에 사용 중이면 예외 발생.
     * (섹션 삭제 전 호출)
     */
    public void assertSectionNotInUse(Long sectionId) {
        // seat 테이블에서 해당 섹션 사용 여부 확인은 현재 구조상
        // seatMapper.findByPerformanceId 로 직접 확인하기 어려우므로
        // VenueAdminService.deleteSection 내부에서 처리하도록 위임
        // 추후 SeatMapper에 countBySectionId 추가 시 여기서 직접 처리
    }

    private VenueManager getOrThrow(Long managerId) {
        VenueManager vm = venueManagerMapper.findById(managerId);
        if (vm == null) throw new BusinessException(ErrorCode.VENUE_MANAGER_NOT_FOUND);
        return vm;
    }
}
