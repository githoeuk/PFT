package com.example.demo.domain.schedule.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.time.LocalTime;

public record WorkScheduleCreateRequest(
        @NotNull
        Long workSiteId,

        @NotNull
        LocalDate workDate,

        @NotNull
        LocalTime startTime,

        @NotNull
        LocalTime endTime,

        @NotNull
        @Min(0)
        Integer lateGraceMinutes,

        @NotNull
        @Min(0)
        Integer earlyLeaveGraceMinutes
) {
}
