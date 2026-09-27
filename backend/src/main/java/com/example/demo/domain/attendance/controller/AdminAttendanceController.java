package com.example.demo.domain.attendance.controller;

import com.example.demo.domain.attendance.AttendanceStatus;
import com.example.demo.domain.attendance.dto.*;
import com.example.demo.domain.attendance.service.AttendanceService;
import com.example.demo.global.common.response.ApiResponse;
import com.example.demo.global.security.CustomUserDetails;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/admin/attendance")
public class AdminAttendanceController {

    private final AttendanceService attendanceService;

    @GetMapping
    public ApiResponse<List<AttendanceRecordResponse>> searchForAdmin(
            @RequestParam(required = false) Long employeeId,
            @RequestParam(required = false) Long workSiteId,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate startDate,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate endDate,
            @RequestParam(required = false) AttendanceStatus status
    ) {
        AttendanceSearchCondition condition = new AttendanceSearchCondition(
                employeeId,
                workSiteId,
                startDate,
                endDate,
                status
        );

        return ApiResponse.success(attendanceService.searchForAdmin(condition));
    }

    // 관리자 수기 출석 수정
    @PatchMapping("/{attendanceRecordId}")
    public ApiResponse<AttendanceRecordResponse> manualUpdateAttendance(
            @PathVariable Long attendanceRecordId,
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody AttendanceManualUpdateRequest request
            ){
        return ApiResponse.success(
                attendanceService.manualUpdateAttendance(
                        attendanceRecordId,
                        userDetails.getUserId(),
                        request
                )
        );
    }

    // 관리자 수기 출석 생성
    @PostMapping("/manual-records")
    public ApiResponse<AttendanceRecordResponse> manualCreateAttendance(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody AttendanceManualCreateRequest request
    ) {
        return ApiResponse.success(
                attendanceService.manualCreateAttendance(
                        userDetails.getUserId(),
                        request
                )
        );
    }

    // 관리자 결석 처리
    @PostMapping("/absences")
    public ApiResponse<AttendanceRecordResponse> createAbsence(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody AttendanceAbsenceCreateRequest request
            ){
        return ApiResponse.success(
                attendanceService.createAbsence(
                        userDetails.getUserId(),
                        request
                )
        );
    }

    @GetMapping("/{attendanceRecordId}/adjustments")
    public ApiResponse<List<AttendanceAdjustmentResponse>> findAdjustments(
            @PathVariable Long attendanceRecordId
    ){
        return ApiResponse.success(attendanceService.findAdjustments(attendanceRecordId));
    }
}
