package com.example.demo.domain.payroll.service;

import com.example.demo.domain.payroll.EmployeeProjectPaySetting;
import com.example.demo.domain.payroll.EmployeeProjectPaySettingRepository;
import com.example.demo.domain.payroll.dto.PaySettingCreateRequest;
import com.example.demo.domain.payroll.dto.PaySettingResponse;
import com.example.demo.domain.payroll.dto.PaySettingUpdateRequest;
import com.example.demo.domain.user.User;
import com.example.demo.domain.user.UserRepository;
import com.example.demo.domain.user.UserRole;
import com.example.demo.domain.worksite.WorkSite;
import com.example.demo.domain.worksite.WorkSiteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class EmployeeProjectPaySettingService {

    private static final BigDecimal DEFAULT_TAX_RATE = BigDecimal.valueOf(0).setScale(2);

    private final EmployeeProjectPaySettingRepository paySettingRepository;
    private final UserRepository userRepository;
    private final WorkSiteRepository workSiteRepository;

    @Transactional
    public PaySettingResponse create(PaySettingCreateRequest request) {
        User employee = findActiveEmployee(request.employeeId());
        WorkSite workSite = findActiveWorkSite(request.workSiteId());

        if (paySettingRepository.existsByEmployee_IdAndWorkSite_IdAndActiveTrue(
                employee.getId(),
                workSite.getId()
        )) {
            throw new IllegalArgumentException("이미 등록된 직원별 프로젝트 급여 설정입니다.");
        }

        EmployeeProjectPaySetting paySetting = EmployeeProjectPaySetting.builder()
                .employee(employee)
                .workSite(workSite)
                .dailyWage(request.dailyWage())
                .taxRate(resolveTaxRate(request.taxRate()))
                .active(true)
                .build();

        return PaySettingResponse.from(paySettingRepository.save(paySetting));
    }

    public List<PaySettingResponse> findByWorkSite(Long workSiteId) {
        findActiveWorkSite(workSiteId);

        return paySettingRepository.findByWorkSite_IdAndActiveTrueOrderByCreatedAtDesc(workSiteId)
                .stream()
                .map(PaySettingResponse::from)
                .toList();
    }

    public List<PaySettingResponse> findByEmployee(Long employeeId) {
        findActiveEmployee(employeeId);

        return paySettingRepository.findByEmployee_IdAndActiveTrueOrderByCreatedAtDesc(employeeId)
                .stream()
                .map(PaySettingResponse::from)
                .toList();
    }

    public PaySettingResponse findByEmployeeAndWorkSite(Long employeeId, Long workSiteId) {
        findActiveEmployee(employeeId);
        findActiveWorkSite(workSiteId);

        EmployeeProjectPaySetting paySetting = paySettingRepository
                .findByEmployee_IdAndWorkSite_IdAndActiveTrue(employeeId, workSiteId)
                .orElseThrow(() -> new IllegalArgumentException("직원별 프로젝트 급여 설정을 찾을 수 없습니다."));

        return PaySettingResponse.from(paySetting);
    }

    @Transactional
    public PaySettingResponse update(Long paySettingId, PaySettingUpdateRequest request) {
        EmployeeProjectPaySetting paySetting = findActivePaySetting(paySettingId);

        paySetting.update(
                request.dailyWage(),
                resolveTaxRate(request.taxRate())
        );

        return PaySettingResponse.from(paySetting);
    }

    @Transactional
    public void deactivate(Long paySettingId) {
        EmployeeProjectPaySetting paySetting = findActivePaySetting(paySettingId);
        paySetting.deactivate();
    }

    private EmployeeProjectPaySetting findActivePaySetting(Long paySettingId) {
        return paySettingRepository.findByIdAndActiveTrue(paySettingId)
                .orElseThrow(() -> new IllegalArgumentException("직원별 프로젝트 급여 설정을 찾을 수 없습니다."));
    }

    private User findActiveEmployee(Long employeeId) {
        User employee = userRepository.findByIdAndActiveTrue(employeeId)
                .orElseThrow(() -> new IllegalArgumentException("직원을 찾을 수 없습니다."));

        if (employee.getRole() != UserRole.EMPLOYEE) {
            throw new IllegalArgumentException("직원 계정만 급여 설정을 등록할 수 있습니다.");
        }

        return employee;
    }

    private WorkSite findActiveWorkSite(Long workSiteId) {
        return workSiteRepository.findByIdAndActiveTrue(workSiteId)
                .orElseThrow(() -> new IllegalArgumentException("작업 현장을 찾을 수 없습니다."));
    }

    private BigDecimal resolveTaxRate(BigDecimal taxRate) {
        if (taxRate == null) {
            return DEFAULT_TAX_RATE;
        }
        return taxRate.setScale(2);
    }

}
