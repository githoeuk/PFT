package com.example.demo.domain.attendance.dto;


import com.example.demo.domain.attendance.AttendanceStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

// 관리자 수기 출석 생성
public record AttendanceManualCreateRequest(
        @NotNull(message = "직원 ID는 필수입니다.")
        Long employeeId,

        @NotNull(message = "작업 일정 ID는 필수입니다.")
        Long scheduleId,

        @NotNull(message = "출석 상태는 필수입니다.")
        AttendanceStatus status,

        LocalDateTime checkedInAt,
        LocalDateTime checkedOutAt,

        @NotBlank(message = "수기 처리 사유는 필수입니다.")
        @Size(max = 500, message = "수기 처리 사유는 500자 이하여야 합니다.")
        String reason,

        @NotBlank(message = "관리자 비밀번호는 필수입니다.")
        String adminPassword
){
}
