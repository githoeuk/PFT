package com.example.demo.domain.attendance.dto;

import com.example.demo.domain.attendance.AttendanceStatus;

import java.time.LocalDate;

public record AttendanceSearchCondition(
        Long employeeId,
        Long workSiteId,
        LocalDate startDate,
        LocalDate endDate,
        AttendanceStatus status
) {
}