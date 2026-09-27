package com.example.demo.domain.user.controller;

import com.example.demo.domain.user.dto.*;
import com.example.demo.domain.user.service.UserService;
import com.example.demo.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/admin/employees")
public class AdminEmployeeController {

    private final UserService userService;

    // 직원 생성 + 임시 비밀번호 발급
    @PostMapping
    public ApiResponse<EmployeeCreateResponse> create(
            @Valid @RequestBody EmployeeCreateRequest request
    ) {
        return ApiResponse.success(userService.createEmployee(request));
    }

    // 직원 목록 조회
    @GetMapping
    public ApiResponse<List<UserResponse>> findAll(){
        return ApiResponse.success(userService.findAllEmployees());
    }

    // 직원 단건 조회
    @GetMapping("/{employeeId}")
    public ApiResponse<UserResponse> findById(
            @PathVariable Long employeeId
    ){
        return ApiResponse.success(userService.findEmployeeById(employeeId));
    }

    // 직원 이름/전화번호 수정
    @PatchMapping("/{employeeId}")
    public ApiResponse<UserResponse> update(
            @PathVariable Long employeeId,
            @Valid @RequestBody EmployeeUpdateRequest request
    ){
        return ApiResponse.success(userService.updateEmployee(employeeId, request));
    }

    // 직원 비밀번호 초기화
    @PatchMapping("/{employeeId}/password/reset")
    public ApiResponse<EmployeePasswordResetResponse> resetPassword(
            @PathVariable Long employeeId
    ){
        return ApiResponse.success(userService.resetEmployeePassword(employeeId));
    }

    // 직원 비활성화
    @DeleteMapping("/{employeeId}")
    public ApiResponse<Void> deactivate(
            @PathVariable Long employeeId
    ){
        userService.deactivateEmployee(employeeId);
        return ApiResponse.success(null);
    }

}
