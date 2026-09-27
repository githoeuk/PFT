package com.example.demo.domain.schedule;

import com.example.demo.domain.worksite.WorkSite;
import com.example.demo.global.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.LocalTime;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Entity
@Table(
        name = "work_schedules",
        indexes = {
                @Index(name = "idx_work_schedules_site_date", columnList = "work_site_id, work_date")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class WorkSchedule extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "work_site_id", nullable = false)
    private WorkSite workSite;

    @Column(name = "work_date", nullable = false)
    private LocalDate workDate;

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(name = "late_grace_minutes", nullable = false)
    private Integer lateGraceMinutes;

    @Column(name = "early_leave_grace_minutes", nullable = false)
    private Integer earlyLeaveGraceMinutes;

    @Builder
    private WorkSchedule(
            WorkSite workSite,
            LocalDate workDate,
            LocalTime startTime,
            LocalTime endTime,
            Integer lateGraceMinutes,
            Integer earlyLeaveGraceMinutes
    ) {
        this.workSite = workSite;
        this.workDate = workDate;
        this.startTime = startTime;
        this.endTime = endTime;
        this.lateGraceMinutes = lateGraceMinutes;
        this.earlyLeaveGraceMinutes = earlyLeaveGraceMinutes;
    }

    public void update(
            LocalDate workDate,
            LocalTime startTime,
            LocalTime endTime,
            Integer lateGraceMinutes,
            Integer earlyLeaveGraceMinutes
    ){
        this.workDate = workDate;
        this.startTime = startTime;
        this.endTime = endTime;
        this.lateGraceMinutes = lateGraceMinutes;
        this.earlyLeaveGraceMinutes = earlyLeaveGraceMinutes;
    }
}
