package com.example.demo.domain.attendance;

import com.example.demo.domain.attendance.dto.AttendanceSearchCondition;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface AttendanceRecordRepository extends JpaRepository<AttendanceRecord, Long> {

    Optional<AttendanceRecord> findByEmployee_IdAndSchedule_Id(
            Long employeeId,
            Long scheduleId
    );

    boolean existsByEmployee_IdAndSchedule_Id(
            Long employeeId,
            Long scheduleId
    );

    // 직원 본인 출석 내역 조회용
    @Query("""
            select ar
            from AttendanceRecord ar
            join fetch ar.employee e
            join fetch ar.schedule s
            join fetch s.workSite ws
            where e.id = :employeeId
              and (:startDate is null or s.workDate >= :startDate)
              and (:endDate is null or s.workDate <= :endDate)
            order by s.workDate desc, ar.createdAt desc
            """)
    List<AttendanceRecord> searchMyAttendance(
            @Param("employeeId") Long employeeId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    // 관리자 출석 현황 검색용
    @Query("""
            select ar
            from AttendanceRecord ar
            join fetch ar.employee e
            join fetch ar.schedule s
            join fetch s.workSite ws
            where (:#{#condition.employeeId()} is null or e.id = :#{#condition.employeeId()})
              and (:#{#condition.workSiteId()} is null or ws.id = :#{#condition.workSiteId()})
              and (:#{#condition.startDate()} is null or s.workDate >= :#{#condition.startDate()})
              and (:#{#condition.endDate()} is null or s.workDate <= :#{#condition.endDate()})
              and (:#{#condition.status()} is null or ar.status = :#{#condition.status()})
            order by s.workDate desc, e.name asc, ar.createdAt desc
            """)
    List<AttendanceRecord> searchForAdmin(
            @Param("condition") AttendanceSearchCondition condition
    );
}
