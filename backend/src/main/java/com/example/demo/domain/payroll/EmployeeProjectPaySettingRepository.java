package com.example.demo.domain.payroll;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EmployeeProjectPaySettingRepository
        extends JpaRepository<EmployeeProjectPaySetting, Long> {

    Optional<EmployeeProjectPaySetting> findByEmployee_IdAndWorkSite_IdAndActiveTrue(
            Long employeeId,
            Long workSiteId
    );

    boolean existsByEmployee_IdAndWorkSite_IdAndActiveTrue(
            Long employeeId,
            Long workSiteId
    );

    List<EmployeeProjectPaySetting> findByWorkSite_IdAndActiveTrueOrderByCreatedAtDesc(
        Long workSiteId
    );

    List<EmployeeProjectPaySetting> findByEmployee_IdAndActiveTrueOrderByCreatedAtDesc(
            Long employeeId
    );

    Optional<EmployeeProjectPaySetting> findByIdAndActiveTrue(Long id);
}
