package com.ticketlegacy.service;

import com.ticketlegacy.domain.Member;
import com.ticketlegacy.domain.VenueManager;
import com.ticketlegacy.domain.enums.VenueManagerApprovalStatus;
import com.ticketlegacy.dto.request.RegisterVenueManagerCommand;
import com.ticketlegacy.dto.request.VenueManagerSearchQuery;
import com.ticketlegacy.dto.response.PageResponse;
import com.ticketlegacy.dto.response.VenueManagerSummaryDto;
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
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class VenueManagerService {

    private final VenueManagerMapper     venueManagerMapper;
    private final MemberMapper           memberMapper;
    private final BCryptPasswordEncoder  passwordEncoder;

    // ──────────────────────────────────────────
    // 공연장 담당자 가입 신청
    // ──────────────────────────────────────────

    @Transactional
    public void registerVenueManager(RegisterVenueManagerCommand command) {
        if (memberMapper.existsByEmail(command.getEmail()) > 0) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_DUPLICATE);
        }

        Member member = new Member();
        member.setEmail(command.getEmail());
        member.setPassword(passwordEncoder.encode(command.getPassword()));
        member.setName(command.getName());
        member.setPhone(command.getPhone());
        member.setRole("VENUE_MANAGER");
        member.setStatus("PENDING_APPROVAL");
        memberMapper.insert(member);

        VenueManager vm = new VenueManager();
        vm.setMemberId(member.getMemberId());
        vm.setVenueId(command.getVenueId());
        vm.setDepartment(command.getDepartment());
        vm.setPosition(command.getPosition());
        vm.setApprovalStatus(VenueManagerApprovalStatus.PENDING.name());
        venueManagerMapper.insert(vm);

        log.info("공연장 담당자 가입 신청: email={}, venueId={}", command.getEmail(), command.getVenueId());
    }

    // ──────────────────────────────────────────
    // SUPER_ADMIN: 담당자 승인/반려
    // ──────────────────────────────────────────

    @Transactional
    public void approveVenueManager(Long managerId, Long adminMemberId) {
        VenueManager vm = getOrThrow(managerId);
        VenueManagerApprovalStatus current = parseStatus(vm.getApprovalStatus());
        validateTransition(current, VenueManagerApprovalStatus.APPROVED);

        venueManagerMapper.updateApproval(managerId, VenueManagerApprovalStatus.APPROVED.name(), adminMemberId);
        memberMapper.updateStatus(vm.getMemberId(), "ACTIVE");
        log.info("공연장 담당자 승인: managerId={}, {} → APPROVED", managerId, current);
    }

    @Transactional
    public void rejectVenueManager(Long managerId, Long adminMemberId) {
        VenueManager vm = getOrThrow(managerId);
        VenueManagerApprovalStatus current = parseStatus(vm.getApprovalStatus());
        validateTransition(current, VenueManagerApprovalStatus.REJECTED);

        venueManagerMapper.updateApproval(managerId, VenueManagerApprovalStatus.REJECTED.name(), adminMemberId);
        memberMapper.updateStatus(vm.getMemberId(), "DORMANT");
        log.info("공연장 담당자 반려: managerId={}, {} → REJECTED", managerId, current);
    }

    // ──────────────────────────────────────────
    // 조회 (typed API)
    // ──────────────────────────────────────────

    public PageResponse<VenueManagerSummaryDto> searchVenueManagers(VenueManagerSearchQuery query) {
        String status = (query.getStatus() == null || query.getStatus().isBlank()) ? null : query.getStatus();
        List<VenueManager> rows;
        int total;
        if (status == null) {
            rows  = venueManagerMapper.findAll(query.getOffset(), query.getSize());
            total = venueManagerMapper.countAll();
        } else {
            rows  = venueManagerMapper.findByStatus(status, query.getOffset(), query.getSize());
            total = venueManagerMapper.countByStatus(status);
        }
        List<VenueManagerSummaryDto> content = rows.stream()
                .map(VenueManagerSummaryDto::from)
                .collect(Collectors.toList());
        return PageResponse.of(content, total, query.getPage(), query.getSize());
    }

    public int countByStatus(String status) {
        return venueManagerMapper.countByStatus(status);
    }

    // ──────────────────────────────────────────
    // 검증 (Partner 포털에서 사용 — 변경 없음)
    // ──────────────────────────────────────────

    public Long getVenueIdByMemberId(Long memberId) {
        VenueManager vm = venueManagerMapper.findByMemberId(memberId);
        if (vm == null) throw new BusinessException(ErrorCode.VENUE_MANAGER_NOT_FOUND);
        if (!VenueManagerApprovalStatus.APPROVED.name().equals(vm.getApprovalStatus())) {
            throw new BusinessException(ErrorCode.VENUE_MANAGER_NOT_APPROVED);
        }
        return vm.getVenueId();
    }

    public VenueManager getByMemberId(Long memberId) {
        VenueManager vm = venueManagerMapper.findByMemberId(memberId);
        if (vm == null) throw new BusinessException(ErrorCode.VENUE_MANAGER_NOT_FOUND);
        return vm;
    }

    public void verifyVenueOwnership(Long memberId, Long venueId) {
        Long myVenueId = getVenueIdByMemberId(memberId);
        if (!myVenueId.equals(venueId)) {
            throw new BusinessException(ErrorCode.VENUE_MANAGER_FORBIDDEN);
        }
    }

    // ──────────────────────────────────────────
    // internal
    // ──────────────────────────────────────────

    private VenueManager getOrThrow(Long managerId) {
        VenueManager vm = venueManagerMapper.findById(managerId);
        if (vm == null) throw new BusinessException(ErrorCode.VENUE_MANAGER_NOT_FOUND);
        return vm;
    }

    private VenueManagerApprovalStatus parseStatus(String raw) {
        try {
            return VenueManagerApprovalStatus.valueOf(raw);
        } catch (IllegalArgumentException e) {
            throw new BusinessException(ErrorCode.INTERNAL_ERROR, "알 수 없는 공연장 담당자 상태: " + raw);
        }
    }

    private void validateTransition(VenueManagerApprovalStatus current, VenueManagerApprovalStatus next) {
        if (!current.canTransitionTo(next)) {
            throw new BusinessException(ErrorCode.VENUE_MANAGER_STATUS_INVALID_TRANSITION,
                    current.name() + " → " + next.name());
        }
    }
}
