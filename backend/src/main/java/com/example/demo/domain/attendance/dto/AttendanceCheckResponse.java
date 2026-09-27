package com.example.demo.domain.attendance.dto;

import com.example.demo.domain.attendance.AttendanceStatus;
import java.time.LocalDateTime;

public record AttendanceCheckResponse(
        Long recordId,
        AttendanceStatus status,
        LocalDateTime checkedInAt,
        LocalDateTime checkedOutAt,
        String siteName
) {
}
