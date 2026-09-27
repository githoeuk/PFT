package com.example.demo.domain.attendance.dto;

import com.example.demo.domain.attendance.AttendanceAdjustment;
import com.example.demo.domain.attendance.AttendanceStatus;

import java.time.LocalDateTime;

// 수기 수정
public record AttendanceAdjustmentResponse (
        Long id,
        Long attendanceRecordId,
        Long adjustedByUserId,
        String adjustedByName,
        AttendanceStatus beforeStatus,
        AttendanceStatus afterStatus,
        LocalDateTime beforeCheckedInAt,
        LocalDateTime afterCheckedInAt,
        LocalDateTime beforeCheckedOutAt,
        LocalDateTime afterCheckedOutAt,
        String reason,
        LocalDateTime createdAt
){
    public static AttendanceAdjustmentResponse from(AttendanceAdjustment adjustment){
        return new AttendanceAdjustmentResponse(
                adjustment.getId(),
                adjustment.getAttendanceRecord().getId(),
                adjustment.getAdjustedBy().getId(),
                adjustment.getAdjustedBy().getName(),
                adjustment.getBeforeStatus(),
                adjustment.getAfterStatus(),
                adjustment.getBeforeCheckedInAt(),
                adjustment.getAfterCheckedInAt(),
                adjustment.getBeforeCheckedOutAt(),
                adjustment.getAfterCheckedOutAt(),
                adjustment.getReason(),
                adjustment.getCreatedAt()
        );
    }
}
