package com.example.demo.domain.schedule.dto;

import com.example.demo.domain.schedule.WorkSchedule;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

public record WorkScheduleResponse (
        Long id,
        Long workSiteId,
        String workSiteName,
        LocalDate workDate,
        LocalTime startTime,
        LocalTime endTime,
        Integer lateGraceMinutes,
        Integer earlyLeaveGraceMinutes,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
){
    public static WorkScheduleResponse from(WorkSchedule workSchedule) {
        return new WorkScheduleResponse(
                workSchedule.getId(),
                workSchedule.getWorkSite().getId(),
                workSchedule.getWorkSite().getName(),
                workSchedule.getWorkDate(),
                workSchedule.getStartTime(),
                workSchedule.getEndTime(),
                workSchedule.getLateGraceMinutes(),
                workSchedule.getEarlyLeaveGraceMinutes(),
                workSchedule.getCreatedAt(),
                workSchedule.getUpdatedAt()
        );
    }

}
