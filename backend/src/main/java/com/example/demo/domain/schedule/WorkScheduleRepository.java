package com.example.demo.domain.schedule;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface WorkScheduleRepository extends JpaRepository<WorkSchedule, Long> {

    boolean existsByWorkSite_IdAndWorkDateAndIdNot(
            Long workSiteId,
            LocalDate workDate,
            Long scheduleId
    );

    List<WorkSchedule> findByWorkSite_IdAndWorkDate(
            Long workSiteId,
            LocalDate workDate
    );

    Optional<WorkSchedule> findByIdAndWorkSite_Id(Long id, Long workSiteId);

    boolean existsByWorkSite_IdAndWorkDate(Long id, LocalDate workDate);

    List<WorkSchedule> findByWorkSite_Id(Long workSiteId);
}
