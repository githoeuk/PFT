package com.example.demo.domain.attendance.dto;

import com.example.demo.domain.attendance.AttendanceRecord;
import com.example.demo.domain.attendance.AttendanceStatus;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record AttendanceRecordResponse(
        Long id,
        Long employeeId,
        String employeeName,
        Long scheduleId,
        Long workSiteId,
        String workSiteName,
        LocalDate workDate,
        LocalDateTime checkedInAt,
        LocalDateTime checkedOutAt,
        AttendanceStatus status,
        boolean manualAdjusted,
        String latestReason,
        String latestAdjustedByName
) {

    public static AttendanceRecordResponse from(AttendanceRecord record) {
        return from(record, null, null);
    }

    public static AttendanceRecordResponse from(
            AttendanceRecord record,
            String latestReason
    ) {
        return from(record, latestReason, null);
    }

    public static AttendanceRecordResponse from(
            AttendanceRecord record,
            String latestReason,
            String latestAdjustedByName
    ) {
        return new AttendanceRecordResponse(
                record.getId(),
                record.getEmployee().getId(),
                record.getEmployee().getName(),
                record.getSchedule().getId(),
                record.getSchedule().getWorkSite().getId(),
                record.getSchedule().getWorkSite().getName(),
                record.getSchedule().getWorkDate(),
                record.getCheckedInAt(),
                record.getCheckedOutAt(),
                record.getStatus(),
                record.isManualAdjusted(),
                latestReason,
                latestAdjustedByName
        );
    }

}