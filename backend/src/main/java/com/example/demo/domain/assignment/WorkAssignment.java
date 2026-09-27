package com.example.demo.domain.assignment;

import com.example.demo.domain.schedule.WorkSchedule;
import com.example.demo.domain.user.User;
import com.example.demo.global.common.entity.BaseTimeEntity;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Entity
@Table(
        name = "work_assignments",
        indexes = {
                @Index(name = "idx_work_assignments_schedule_employee", columnList = "schedule_id, employee_id")
        },
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_work_assignments_schedule_employee", columnNames = {"schedule_id", "employee_id"})
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class WorkAssignment extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "schedule_id", nullable = false)
    private WorkSchedule schedule;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "employee_id", nullable = false)
    private User employee;

    @Builder
    private WorkAssignment(WorkSchedule schedule, User employee) {
        this.schedule = schedule;
        this.employee = employee;
    }
}
