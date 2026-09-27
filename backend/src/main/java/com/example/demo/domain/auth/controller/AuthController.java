package com.example.demo.domain.auth.controller;

import com.example.demo.domain.auth.dto.*;
import com.example.demo.domain.auth.service.AuthService;
import com.example.demo.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    // 로그인 후 accessToken, refreshToken 발급
    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(
            @Valid @RequestBody LoginRequest request) {
        return ApiResponse.success(authService.login(request));
    }

    // refreshToken 검증 후 accessToken 재발급
    @PostMapping("/refresh")
    public ApiResponse<TokenRefreshResponse> refresh(
            @Valid @RequestBody TokenRefreshRequest request
    ) {
        return ApiResponse.success(authService.refresh(request));
    }

    // 로그아웃 후 refreshToken 삭제
    @PostMapping("/logout")
    public ApiResponse<Void> logout(
            @Valid @RequestBody LogoutRequest request
    ){
        authService.logout(request);
        return ApiResponse.success(null);
    }

    // 이름과 휴대폰 번호로 아이디 찾기
    @PostMapping("/login-id/find")
    public ApiResponse<FindLoginIdResponse> findLoginId(
            @Valid @RequestBody FindLoginIdRequest request
    ){
        return ApiResponse.success(authService.findLoginId(request));
    }

    // 아이디, 이름, 휴대폰 번호 확인 후 비밀번호 재설정
    @PostMapping("/password/reset")
    public ApiResponse<Void> resetPassword(
            @Valid @RequestBody PasswordResetRequest request
    ){
        authService.resetPassword(request);
        return ApiResponse.success(null);
    }
}
