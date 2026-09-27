package com.example.demo.domain.attendance.service;

import com.example.demo.domain.attendance.*;
import com.example.demo.domain.attendance.dto.*;
import com.example.demo.domain.beacon.Beacon;
import com.example.demo.domain.beacon.BeaconRepository;
import com.example.demo.domain.schedule.WorkSchedule;
import com.example.demo.domain.schedule.WorkScheduleRepository;
import com.example.demo.domain.user.User;
import com.example.demo.domain.user.UserRepository;
import com.example.demo.domain.user.UserRole;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AttendanceService {

    private final UserRepository userRepository;
    private final BeaconRepository beaconRepository;
    private final WorkScheduleRepository workScheduleRepository;
    private final AttendanceAdjustmentRepository attendanceAdjustmentRepository;
    private final AttendanceRecordRepository attendanceRecordRepository;
    private final Clock clock;
    private final PasswordEncoder passwordEncoder;

    // 출근 처리
    @Transactional
    public AttendanceCheckResponse checkIn(Long employeeId, AttendanceCheckRequest request) {
        User employee = findActiveEmployee(employeeId);
        Beacon beacon = findBeaconInRange(request);
        WorkSchedule schedule = findTodaySchedule(beacon);

        if (attendanceRecordRepository.existsByEmployee_IdAndSchedule_Id(employee.getId(), schedule.getId())) {
            throw new IllegalStateException("이미 출근 처리된 작업입니다.");
        }

        LocalDateTime now = LocalDateTime.now(clock);
        AttendanceStatus status = judgeCheckInStatus(schedule, now);

        AttendanceRecord attendanceRecord = AttendanceRecord.createCheckIn(
                employee,
                schedule,
                status,
                now,
                beacon,
                request.rssi(),
                request.deviceId(),
                request.latitude(),
                request.longitude()
        );

        AttendanceRecord savedRecord = attendanceRecordRepository.save(attendanceRecord);
        return toResponse(savedRecord);
    }

    // 퇴근 처리
    @Transactional
    public AttendanceCheckResponse checkOut(Long employeeId, AttendanceCheckRequest request) {
        User employee = findActiveEmployee(employeeId);
        Beacon beacon = findBeaconInRange(request);
        WorkSchedule schedule = findTodaySchedule(beacon);

        AttendanceRecord attendanceRecord = attendanceRecordRepository
                .findByEmployee_IdAndSchedule_Id(employee.getId(), schedule.getId())
                .orElseThrow(() -> new IllegalStateException("출근 기록이 없어 퇴근 처리할 수 없습니다."));

        if (attendanceRecord.getCheckedOutAt() != null) {
            throw new IllegalStateException("이미 퇴근 처리된 작업입니다.");
        }

        LocalDateTime now = LocalDateTime.now(clock);
        AttendanceStatus status = judgeCheckOutStatus(attendanceRecord.getStatus(), schedule, now);

        attendanceRecord.checkOut(
                status,
                now,
                beacon,
                request.rssi(),
                request.latitude(),
                request.longitude()
        );

        return toResponse(attendanceRecord);
    }

    // 직원 본인 출석 내역 조회
    public List<AttendanceRecordResponse> findMyAttendance(
            Long employeeId,
            LocalDate startDate,
            LocalDate endDate
    ) {
        findActiveEmployee(employeeId);

        return attendanceRecordRepository.searchMyAttendance(
                        employeeId,
                        startDate,
                        endDate
                )
                .stream()
                .map(AttendanceRecordResponse::from)
                .toList();
    }

    // 관리자 출석 현황 조회
    public List<AttendanceRecordResponse> searchForAdmin(
            AttendanceSearchCondition condition
    ) {
        return attendanceRecordRepository.searchForAdmin(condition)
                .stream()
                .map(this::toAdminAttendanceRecordResponse)
                .toList();
    }

    // 관리자 수기 출석 수정
    @Transactional
    public AttendanceRecordResponse manualUpdateAttendance(
            Long attendanceRecordId,
            Long adminId,
            AttendanceManualUpdateRequest request
    ) {
        User admin = findActiveAdmin(adminId);
        verifyAdminPassword(admin, request.adminPassword());

        AttendanceRecord attendanceRecord = attendanceRecordRepository.findById(attendanceRecordId)
                .orElseThrow(() -> new IllegalArgumentException("출석 기록을 찾을 수 없습니다."));

        validateManualAttendance(
                request.status(),
                request.checkedInAt(),
                request.checkedOutAt()
        );

        AttendanceAdjustment adjustment = AttendanceAdjustment.builder()
                .attendanceRecord(attendanceRecord)
                .adjustedBy(admin)
                .beforeStatus(attendanceRecord.getStatus())
                .afterStatus(request.status())
                .beforeCheckedInAt(attendanceRecord.getCheckedInAt())
                .afterCheckedInAt(request.checkedInAt())
                .beforeCheckedOutAt(attendanceRecord.getCheckedOutAt())
                .afterCheckedOutAt(request.checkedOutAt())
                .reason(request.reason())
                .build();

        attendanceRecord.manualUpdate(
                request.status(),
                request.checkedInAt(),
                request.checkedOutAt()
        );

        attendanceAdjustmentRepository.save(adjustment);

        return AttendanceRecordResponse.from(
                attendanceRecord,
                adjustment.getReason(),
                adjustment.getAdjustedBy().getName()
                );
    }

    // 관리자 수기 출석 생성
    @Transactional
    public AttendanceRecordResponse manualCreateAttendance(
            Long adminId,
            AttendanceManualCreateRequest request
    ){
        User admin = findActiveAdmin(adminId);
        User employee = findActiveEmployee(request.employeeId());
        verifyAdminPassword(admin, request.adminPassword());

        WorkSchedule schedule = workScheduleRepository.findById(request.scheduleId())
                .orElseThrow(() -> new IllegalArgumentException("작업 일정을 찾을 수 없습니다."));

        if (attendanceRecordRepository.existsByEmployee_IdAndSchedule_Id(
                employee.getId(),
                schedule.getId()
        )){
            throw new IllegalStateException("이미 출석 기록이 존재합니다.");
        }

        validateManualAttendance(
                request.status(),
                request.checkedInAt(),
                request.checkedOutAt()
        );

        AttendanceRecord attendanceRecord = AttendanceRecord.createManual(
                employee,
                schedule,
                request.status(),
                request.checkedInAt(),
                request.checkedOutAt()
        );

        AttendanceRecord savedRecord = attendanceRecordRepository.save(attendanceRecord);

        AttendanceAdjustment adjustment = AttendanceAdjustment.builder()
                .attendanceRecord(savedRecord)
                .adjustedBy(admin)
                .beforeStatus(null)
                .afterStatus(request.status())
                .beforeCheckedInAt(null)
                .afterCheckedInAt(request.checkedInAt())
                .beforeCheckedOutAt(null)
                .afterCheckedOutAt(request.checkedOutAt())
                .reason(request.reason())
                .build();

        attendanceAdjustmentRepository.save(adjustment);

        return AttendanceRecordResponse.from(
                savedRecord,
                adjustment.getReason(),
                adjustment.getAdjustedBy().getName()
        );
    }

    // 관리자 결석 처리
    @Transactional
    public AttendanceRecordResponse createAbsence(
            Long adminId,
            AttendanceAbsenceCreateRequest request
    ) {
      AttendanceManualCreateRequest manualRequest = new AttendanceManualCreateRequest(
              request.employeeId(),
              request.scheduleId(),
              AttendanceStatus.ABSENT,
              null,
              null,
              request.reason(),
              request.adminPassword()
      );

      return manualCreateAttendance(adminId, manualRequest);
    }

    // 이력 조회
    public List<AttendanceAdjustmentResponse> findAdjustments(Long attendanceRecordId) {
        if (!attendanceRecordRepository.existsById(attendanceRecordId)) {
            throw new IllegalArgumentException("출석 기록을 찾을 수 없습니다.");
        }
        return attendanceAdjustmentRepository
                .findByAttendanceRecordIdWithDetails(attendanceRecordId)
                .stream()
                .map(AttendanceAdjustmentResponse::from)
                .toList();
    }


    // 활성 관리자 조회
    private User findActiveAdmin(Long adminId) {
        User admin = userRepository.findByIdAndActiveTrue(adminId)
                .orElseThrow(() -> new IllegalArgumentException("관리자를 찾을 수 없습니다."));

        if (admin.getRole() != UserRole.ADMIN && admin.getRole() != UserRole.SUPER_ADMIN) {
            throw new IllegalArgumentException("관리자만 처리할 수 있습니다.");
        }

        return admin;
    }

    private void verifyAdminPassword(User admin, String rawPassword){
        if (!passwordEncoder.matches(rawPassword,admin.getPassword())){
            throw new IllegalArgumentException("관리자 비밀번호가 일치하지 않습니다");
        }
    }

    // 수기 입력 시간 검증
    private void validateManualAttendance(
            AttendanceStatus status,
            LocalDateTime checkedInAt,
            LocalDateTime checkedOutAt
    ) {
        if (status == AttendanceStatus.ABSENT) {
            if (checkedInAt != null || checkedOutAt != null) {
                throw new IllegalArgumentException("결석 상태에는 출근/퇴근 시간을 입력할 수 없습니다.");
            }
            return;
        }

        if (checkedInAt == null){
            throw new IllegalArgumentException("결석이 아닌 상태에는 출근 시간이 필요합니다.");
        }

        if (checkedOutAt != null && checkedInAt.isAfter(checkedOutAt)){
            throw new IllegalArgumentException("출근 시간이 퇴근 시간보다 이후일 수 없습니다.");
        }

    }

    // 활성 직원 조회
    private User findActiveEmployee(Long employeeId) {
        User employee = userRepository.findByIdAndActiveTrue(employeeId)
                .orElseThrow(() -> new IllegalArgumentException("활성화된 직원을 찾을 수 없습니다."));

        if (employee.getRole() != UserRole.EMPLOYEE) {
            throw new IllegalArgumentException("직원 계정만 출퇴근 처리할 수 있습니다.");
        }

        return employee;
    }

    // 출석 가능 범위 내 비콘 조회
    private Beacon findBeaconInRange(AttendanceCheckRequest request) {
        Beacon beacon = beaconRepository.findByUuidAndMajorAndMinorAndActiveTrue(
                        request.beaconUuid(),
                        request.beaconMajor(),
                        request.beaconMinor()
                )
                .orElseThrow(() -> new IllegalArgumentException("등록된 비콘을 찾을 수 없습니다."));

        if (request.rssi() < beacon.getRssiThreshold()) {
            throw new IllegalArgumentException("출석 가능한 비콘 범위 안에 있지 않습니다.");
        }

        return beacon;
    }

    // 오늘 작업 일정 조회
    private WorkSchedule findTodaySchedule(Beacon beacon) {
        LocalDate today = LocalDate.now(clock);
        List<WorkSchedule> schedules = workScheduleRepository.findByWorkSite_IdAndWorkDate(
                beacon.getWorkSite().getId(),
                today
        );

        if (schedules.isEmpty()) {
            throw new IllegalStateException("오늘 등록된 작업 일정이 없습니다.");
        }

        if (schedules.size() > 1) {
            throw new IllegalStateException("같은 현장에 오늘 작업 일정이 여러 개 등록되어 있습니다.");
        }

        return schedules.get(0);
    }

    // 출근 상태 판단
    private AttendanceStatus judgeCheckInStatus(WorkSchedule schedule, LocalDateTime checkedInAt) {
        LocalDateTime lateLimit = LocalDateTime.of(schedule.getWorkDate(), schedule.getStartTime())
                .plusMinutes(schedule.getLateGraceMinutes());

        if (checkedInAt.isAfter(lateLimit)) {
            return AttendanceStatus.LATE;
        }

        return AttendanceStatus.NORMAL;
    }

    // 조퇴 여부 판단
    private AttendanceStatus judgeCheckOutStatus(
            AttendanceStatus currentStatus,
            WorkSchedule schedule,
            LocalDateTime checkedOutAt
    ) {
        LocalDateTime earlyLeaveLimit = LocalDateTime.of(schedule.getWorkDate(), schedule.getEndTime())
                .minusMinutes(schedule.getEarlyLeaveGraceMinutes());

        if (!checkedOutAt.isBefore(earlyLeaveLimit)) {
            return currentStatus;
        }

        if (currentStatus == AttendanceStatus.LATE) {
            return AttendanceStatus.LATE_AND_EARLY_LEAVE;
        }

        return AttendanceStatus.EARLY_LEAVE;
    }

    // 관리자 출석 현황 조회?
    private AttendanceRecordResponse toAdminAttendanceRecordResponse(AttendanceRecord record) {
        return attendanceAdjustmentRepository
                .findFirstByAttendanceRecord_IdOrderByCreatedAtDesc(record.getId())
                .map(adjustment -> AttendanceRecordResponse.from(
                        record,
                        adjustment.getReason(),
                        adjustment.getAdjustedBy().getName()
                ))
                .orElseGet(() -> AttendanceRecordResponse.from(record));
    }

    // 출근/퇴근 응답 변환
    private AttendanceCheckResponse toResponse(AttendanceRecord attendanceRecord) {
        return new AttendanceCheckResponse(
                attendanceRecord.getId(),
                attendanceRecord.getStatus(),
                attendanceRecord.getCheckedInAt(),
                attendanceRecord.getCheckedOutAt(),
                attendanceRecord.getSchedule().getWorkSite().getName()
        );
    }
}
