package com.example.demo.domain.attendance.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

// 결석 처리
public record AttendanceAbsenceCreateRequest(
        @NotNull
        Long employeeId,

        @NotNull
        Long scheduleId,

        @NotBlank
        @Size(max = 500)
        String reason,

        @NotBlank(message = "관리자 비밀번호는 필수입니다.")
        String adminPassword
) {
}
