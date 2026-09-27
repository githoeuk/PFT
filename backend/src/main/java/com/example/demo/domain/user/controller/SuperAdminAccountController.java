package com.example.demo.domain.user.controller;

import com.example.demo.domain.user.dto.AdminAccountCreateRequest;
import com.example.demo.domain.user.dto.AdminAccountCreateResponse;
import com.example.demo.domain.user.dto.AdminAccountPasswordResetResponse;
import com.example.demo.domain.user.dto.AdminAccountUpdateRequest;
import com.example.demo.domain.user.dto.UserResponse;
import com.example.demo.domain.user.service.UserService;
import com.example.demo.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/super-admin/admins")
public class SuperAdminAccountController {

    private final UserService userService;

    // 관리자 계정 생성 + 임시 비밀번호 발급
    @PostMapping
    public ApiResponse<AdminAccountCreateResponse> create(
            @Valid @RequestBody AdminAccountCreateRequest request
    ) {
        return ApiResponse.success(userService.createAdmin(request));
    }

    // 관리자 계정 목록 조회
    @GetMapping
    public ApiResponse<List<UserResponse>> findAll() {
        return ApiResponse.success(userService.findAllAdmins());
    }

    // 관리자 계정 단건 조회
    @GetMapping("/{adminId}")
    public ApiResponse<UserResponse> findById(
            @PathVariable Long adminId
    ) {
        return ApiResponse.success(userService.findAdminById(adminId));
    }

    // 관리자 계정 이름/전화번호 수정
    @PatchMapping("/{adminId}")
    public ApiResponse<UserResponse> update(
            @PathVariable Long adminId,
            @Valid @RequestBody AdminAccountUpdateRequest request
    ) {
        return ApiResponse.success(userService.updateAdmin(adminId, request));
    }

    // 관리자 계정 비밀번호 초기화
    @PatchMapping("/{adminId}/password/reset")
    public ApiResponse<AdminAccountPasswordResetResponse> resetPassword(
            @PathVariable Long adminId
    ) {
        return ApiResponse.success(userService.resetAdminPassword(adminId));
    }

    // 관리자 계정 비활성화
    @DeleteMapping("/{adminId}")
    public ApiResponse<Void> deactivate(
            @PathVariable Long adminId
    ) {
        userService.deactivateAdmin(adminId);
        return ApiResponse.success(null);
    }
}
