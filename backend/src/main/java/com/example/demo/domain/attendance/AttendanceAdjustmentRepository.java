package com.example.demo.domain.attendance;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface AttendanceAdjustmentRepository extends JpaRepository<AttendanceAdjustment, Long> {

    @Query("""
            select  aa
            from AttendanceAdjustment  aa
            join fetch aa.attendanceRecord ar
            join  fetch aa.adjustedBy u
            where ar.id = :attendanceRecordId
            order by aa.createdAt desc
            """)
    List<AttendanceAdjustment> findByAttendanceRecordIdWithDetails(
            @Param("attendanceRecordId") Long attendanceRecordId
    );

    Optional<AttendanceAdjustment> findFirstByAttendanceRecord_IdOrderByCreatedAtDesc(
            Long attendanceRecordId
    );

}
