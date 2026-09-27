package com.example.demo.domain.payroll.controller;

import com.example.demo.domain.payroll.dto.PaySettingCreateRequest;
import com.example.demo.domain.payroll.dto.PaySettingResponse;
import com.example.demo.domain.payroll.dto.PaySettingUpdateRequest;
import com.example.demo.domain.payroll.service.EmployeeProjectPaySettingService;
import com.example.demo.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/admin/pay-settings")
public class PaySettingController {

    private final EmployeeProjectPaySettingService paySettingService;

    // 직원 + 현장 + 일급 + 세율 등록
    @PostMapping
    public ApiResponse<PaySettingResponse> create(
            @Valid @RequestBody PaySettingCreateRequest request
    ) {
        return ApiResponse.success(paySettingService.create(request));
    }

    // 특정 현장에 등록된 직원별 급여 설정 목록 조회
    @GetMapping("/work-sites/{workSiteId}")
    public ApiResponse<List<PaySettingResponse>> findByWorkSite(
            @PathVariable Long workSiteId
    ) {
        return ApiResponse.success(paySettingService.findByWorkSite(workSiteId));
    }

    // 특정 직원의 현장별 급여 설정 목록 조회
    @GetMapping("/employees/{employeeId}")
    public ApiResponse<List<PaySettingResponse>> findByEmployee(
            @PathVariable Long employeeId
    ) {
        return ApiResponse.success(paySettingService.findByEmployee(employeeId));
    }

    // 직원 + 현장 기준 단건 조회
    @GetMapping("/employees/{employeeId}/work-sites/{workSiteId}")
    public ApiResponse<PaySettingResponse> findByEmployeeAndWorkSite(
            @PathVariable Long employeeId,
            @PathVariable Long workSiteId
    ) {
        return ApiResponse.success(
                paySettingService.findByEmployeeAndWorkSite(employeeId, workSiteId)
        );
    }

    // 일급 / 세율 수정
    @PatchMapping("/{paySettingId}")
    public ApiResponse<PaySettingResponse> update(
            @PathVariable Long paySettingId,
            @Valid @RequestBody PaySettingUpdateRequest request
    ) {
        return ApiResponse.success(paySettingService.update(paySettingId, request));
    }

    // 급여 설정 비활성화 처리
    @DeleteMapping("/{paySettingId}")
    public ApiResponse<Void> deactivate(
            @PathVariable Long paySettingId
    ) {
        paySettingService.deactivate(paySettingId);
        return ApiResponse.success(null);
    }
}
