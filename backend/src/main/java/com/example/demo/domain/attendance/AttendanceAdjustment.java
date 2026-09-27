package com.example.demo.domain.attendance;

import com.example.demo.domain.user.User;
import com.example.demo.global.common.entity.BaseTimeEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@Entity
@Table(
        name = "attendance_adjustments",
        indexes = {
                @Index(name = "idx_attendance_adjustments_record", columnList = "attendance_record_id")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class AttendanceAdjustment extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "attendance_record_id", nullable = false)
    private AttendanceRecord attendanceRecord;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "adjusted_by_user_id", nullable = false)
    private User adjustedBy;

    @Enumerated(EnumType.STRING)
    @Column(name = "before_status", length = 30)
    private AttendanceStatus beforeStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "after_status", nullable = false, length = 30)
    private AttendanceStatus afterStatus;

    @Column(name = "before_checked_in_at")
    private LocalDateTime beforeCheckedInAt;

    @Column(name = "after_checked_in_at")
    private LocalDateTime afterCheckedInAt;

    @Column(name = "before_checked_out_at")
    private LocalDateTime beforeCheckedOutAt;

    @Column(name = "after_checked_out_at")
    private LocalDateTime afterCheckedOutAt;

    @Column(nullable = false, length = 500)
    private String reason;

    @Builder
    private AttendanceAdjustment(
            AttendanceRecord attendanceRecord,
            User adjustedBy,
            AttendanceStatus beforeStatus,
            AttendanceStatus afterStatus,
            LocalDateTime beforeCheckedInAt,
            LocalDateTime afterCheckedInAt,
            LocalDateTime beforeCheckedOutAt,
            LocalDateTime afterCheckedOutAt,
            String reason
    ) {
        this.attendanceRecord = attendanceRecord;
        this.adjustedBy = adjustedBy;
        this.beforeStatus = beforeStatus;
        this.afterStatus = afterStatus;
        this.beforeCheckedInAt = beforeCheckedInAt;
        this.afterCheckedInAt = afterCheckedInAt;
        this.beforeCheckedOutAt = beforeCheckedOutAt;
        this.afterCheckedOutAt = afterCheckedOutAt;
        this.reason = reason;
    }
}
