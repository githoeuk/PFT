package com.example.demo.domain.payroll.service;


import com.example.demo.domain.payroll.dto.PaySettingResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

@ActiveProfiles("test")
@SpringBootTest
@Transactional
class EmployeeProjectPaySettingServiceTest {

    @Autowired
    private EmployeeProjectPaySettingService paySettingService;

    @Test
    void findByEmployeeAndWorkSite_returnsCalculatedPaySetting(){
        PaySettingResponse response = paySettingService.findByEmployeeAndWorkSite(2L,1L);

        assertEquals(BigDecimal.valueOf(150000),response.dailyWage());
        assertEquals(new BigDecimal("3.30"),response.taxRate());
        assertEquals(BigDecimal.valueOf(4950),response.taxAmount());
        assertEquals(BigDecimal.valueOf(145050),response.netDailyWage());
    }
}
