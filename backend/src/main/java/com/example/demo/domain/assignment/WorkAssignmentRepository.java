package com.example.demo.domain.assignment;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface WorkAssignmentRepository extends JpaRepository<WorkAssignment, Long> {
    Optional<WorkAssignment> findBySchedule_IdAndEmployee_Id(
            Long scheduleId,
            Long employeeId
    );

    List<WorkAssignment> findByEmployee_IdAndSchedule_WorkDate(
            Long employeeId,
            LocalDate workDate
    );

}
