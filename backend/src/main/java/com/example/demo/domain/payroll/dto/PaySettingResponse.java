package com.example.demo.domain.payroll.dto;

import com.example.demo.domain.payroll.EmployeeProjectPaySetting;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record PaySettingResponse(
        Long id,
        Long employeeId,
        String employeeName,
        Long workSiteId,
        String workSiteName,
        BigDecimal dailyWage,
        BigDecimal taxRate,
        BigDecimal taxAmount,
        BigDecimal netDailyWage,
        boolean active,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static PaySettingResponse from(EmployeeProjectPaySetting paySetting) {
        return new PaySettingResponse(
                paySetting.getId(),
                paySetting.getEmployee().getId(),
                paySetting.getEmployee().getName(),
                paySetting.getWorkSite().getId(),
                paySetting.getWorkSite().getName(),
                paySetting.getDailyWage(),
                paySetting.getTaxRate(),
                paySetting.calculateTaxAmount(),
                paySetting.calculateNetDailyWage(),
                paySetting.isActive(),
                paySetting.getCreatedAt(),
                paySetting.getUpdatedAt()
        );
    }
}
