package com.example.demo.domain.attendance;

import com.example.demo.domain.beacon.Beacon;
import com.example.demo.domain.schedule.WorkSchedule;
import com.example.demo.domain.user.User;
import com.example.demo.global.common.entity.BaseTimeEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Getter
@Entity
@Table(
        name = "attendance_records",
        indexes = {
                @Index(name = "idx_attendance_records_employee_schedule", columnList = "employee_id, schedule_id")
        },
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_attendance_records_employee_schedule", columnNames = {"employee_id", "schedule_id"})
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class AttendanceRecord extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "employee_id", nullable = false)
    private User employee;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "schedule_id", nullable = false)
    private WorkSchedule schedule;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private AttendanceStatus status;

    @Column(name = "checked_in_at")
    private LocalDateTime checkedInAt;

    @Column(name = "checked_out_at")
    private LocalDateTime checkedOutAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "check_in_beacon_id")
    private Beacon checkInBeacon;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "check_out_beacon_id")
    private Beacon checkOutBeacon;

    @Column(name = "check_in_rssi")
    private Integer checkInRssi;

    @Column(name = "check_out_rssi")
    private Integer checkOutRssi;

    @Column(name = "device_id", length = 100)
    private String deviceId;

    @Column(name = "check_in_latitude", precision = 10, scale = 7)
    private BigDecimal checkInLatitude;

    @Column(name = "check_in_longitude", precision = 10, scale = 7)
    private BigDecimal checkInLongitude;

    @Column(name = "check_out_latitude", precision = 10, scale = 7)
    private BigDecimal checkOutLatitude;

    @Column(name = "check_out_longitude", precision = 10, scale = 7)
    private BigDecimal checkOutLongitude;

    @Column(name = "manual_adjusted", nullable = false)
    private boolean manualAdjusted;

    @Builder
    private AttendanceRecord(
            User employee,
            WorkSchedule schedule,
            AttendanceStatus status,
            LocalDateTime checkedInAt,
            LocalDateTime checkedOutAt,
            Beacon checkInBeacon,
            Beacon checkOutBeacon,
            Integer checkInRssi,
            Integer checkOutRssi,
            String deviceId,
            BigDecimal checkInLatitude,
            BigDecimal checkInLongitude,
            BigDecimal checkOutLatitude,
            BigDecimal checkOutLongitude,
            Boolean manualAdjusted
    ) {
        this.employee = employee;
        this.schedule = schedule;
        this.status = status == null ? AttendanceStatus.NORMAL : status;
        this.checkedInAt = checkedInAt;
        this.checkedOutAt = checkedOutAt;
        this.checkInBeacon = checkInBeacon;
        this.checkOutBeacon = checkOutBeacon;
        this.checkInRssi = checkInRssi;
        this.checkOutRssi = checkOutRssi;
        this.deviceId = deviceId;
        this.checkInLatitude = checkInLatitude;
        this.checkInLongitude = checkInLongitude;
        this.checkOutLatitude = checkOutLatitude;
        this.checkOutLongitude = checkOutLongitude;
        this.manualAdjusted = manualAdjusted != null && manualAdjusted;
    }

    public static AttendanceRecord createCheckIn(
            User employee,
            WorkSchedule schedule,
            AttendanceStatus status,
            LocalDateTime checkedInAt,
            Beacon checkInBeacon,
            Integer checkInRssi,
            String deviceId,
            BigDecimal checkInLatitude,
            BigDecimal checkInLongitude
    ) {
        return AttendanceRecord.builder()
                .employee(employee)
                .schedule(schedule)
                .status(status)
                .checkedInAt(checkedInAt)
                .checkInBeacon(checkInBeacon)
                .checkInRssi(checkInRssi)
                .deviceId(deviceId)
                .checkInLatitude(checkInLatitude)
                .checkInLongitude(checkInLongitude)
                .manualAdjusted(false)
                .build();
    }

    public void checkOut(
            AttendanceStatus status,
            LocalDateTime checkedOutAt,
            Beacon checkOutBeacon,
            Integer checkOutRssi,
            BigDecimal checkOutLatitude,
            BigDecimal checkOutLongitude
    ) {
        this.status = status;
        this.checkedOutAt = checkedOutAt;
        this.checkOutBeacon = checkOutBeacon;
        this.checkOutRssi = checkOutRssi;
        this.checkOutLatitude = checkOutLatitude;
        this.checkOutLongitude = checkOutLongitude;
    }

    public static AttendanceRecord createManual(
            User employee,
            WorkSchedule schedule,
            AttendanceStatus status,
            LocalDateTime checkedInAt,
            LocalDateTime checkedOutAt
    ) {
        return AttendanceRecord.builder()
                .employee(employee)
                .schedule(schedule)
                .status(status)
                .checkedInAt(checkedInAt)
                .checkedOutAt(checkedOutAt)
                .manualAdjusted(true)
                .build();

    }

    public void manualUpdate(
            AttendanceStatus status,
            LocalDateTime checkedInAt,
            LocalDateTime checkedOutAt
    ) {
        this.status = status;
        this.checkedInAt = checkedInAt;
        this.checkedOutAt = checkedOutAt;
        this.manualAdjusted = true;
    }
}
