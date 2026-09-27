package com.example.demo.domain.attendance.controller;

import com.example.demo.domain.attendance.dto.AttendanceCheckRequest;
import com.example.demo.domain.attendance.dto.AttendanceCheckResponse;
import com.example.demo.domain.attendance.dto.AttendanceRecordResponse;
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
@RequestMapping("/api/v1/employee/attendance")
public class AttendanceController {

    private final AttendanceService attendanceService;

    @PostMapping("/check-in")
    public ApiResponse<AttendanceCheckResponse> checkIn(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody AttendanceCheckRequest request
    ) {
        return ApiResponse.success(attendanceService.checkIn(userDetails.getUserId(), request));
    }

    @GetMapping
    public ApiResponse<List<AttendanceRecordResponse>> findMyAttendance(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate startDate,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate endDate
    ) {
        return ApiResponse.success(
                attendanceService.findMyAttendance(
                        userDetails.getUserId(),
                        startDate,
                        endDate
                )
        );
    }

    @PostMapping("/check-out")
    public ApiResponse<AttendanceCheckResponse> checkOut(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody AttendanceCheckRequest request
    ) {
        return ApiResponse.success(attendanceService.checkOut(userDetails.getUserId(), request));
    }

}
