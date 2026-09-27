package com.example.demo.domain.payroll;

import com.example.demo.domain.user.User;
import com.example.demo.domain.worksite.WorkSite;
import com.example.demo.global.common.entity.BaseTimeEntity;
import jakarta.persistence.*;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.math.RoundingMode;

@Getter
@Entity
@Table(
        name = "employee_project_pay_setting",
        indexes = {
                @Index(name = "idx_pay_settings_employee_work_site", columnList = "employee_id, work_site_id")
        },
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_pay_settings_employee_work_site",
                        columnNames = {"employee_id", "work_site_id"}
                )
        }
)
@NoArgsConstructor(access = lombok.AccessLevel.PROTECTED)
public class EmployeeProjectPaySetting extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "employee_id", nullable = false)
    private User employee;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "work_site_id", nullable = false)
    private WorkSite workSite;

    @Column(name = "daily_wage", nullable = false, precision = 12, scale = 0)
    private BigDecimal dailyWage;

    @Column(name = "tax_rate", nullable = false, precision = 5, scale = 2)
    private BigDecimal taxRate;

    @Column(nullable = false)
    private boolean active;

    @Builder
    public EmployeeProjectPaySetting(
            User employee,
            WorkSite workSite,
            BigDecimal taxRate,
            BigDecimal dailyWage,
            Boolean active
    ) {
        this.employee = employee;
        this.workSite = workSite;
        this.dailyWage = dailyWage;
        this.taxRate = taxRate;
        this.active = active == null || active;
    }

    public void update(BigDecimal dailyWage,BigDecimal taxRate){
        this.dailyWage = dailyWage;
        this.taxRate = taxRate;
    }

    public void deactivate() {
        this.active = false;
    }

    public BigDecimal calculateTaxAmount(){
        return dailyWage
                .multiply(taxRate)
                .divide(BigDecimal.valueOf(100),0, RoundingMode.DOWN);
    }

    public BigDecimal calculateNetDailyWage(){
        return dailyWage.subtract(calculateTaxAmount());
    }
}
