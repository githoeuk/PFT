package com.example.demo.domain.attendance.dto;

import com.example.demo.domain.attendance.AttendanceStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

// 수기 수정
public record AttendanceManualUpdateRequest(
        @NotNull
        AttendanceStatus status,

        LocalDateTime checkedInAt,

        LocalDateTime checkedOutAt,

        @NotBlank
        @Size(max = 500)
        String reason,

        @NotBlank(message = "관리자 비밀번호는 필수입니다.")
        String adminPassword
) {


}
