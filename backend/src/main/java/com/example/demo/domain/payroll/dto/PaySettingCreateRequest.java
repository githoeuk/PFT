package com.example.demo.domain.payroll.dto;

import jakarta.validation.constraints.*;

import java.math.BigDecimal;

public record PaySettingCreateRequest(
        @NotNull
        Long employeeId,

        @NotNull
        Long workSiteId,

        @NotNull
        @Positive
        @Digits(integer = 12, fraction = 0)
        BigDecimal dailyWage,

        @DecimalMin("0.00")
        @DecimalMax("100.00")
        @Digits(integer = 3, fraction = 2)
        BigDecimal taxRate
) {
}
