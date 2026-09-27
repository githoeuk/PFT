package com.example.demo.domain.user.controller;

import com.example.demo.domain.user.dto.MyPageUpdateRequest;
import com.example.demo.domain.user.dto.PasswordChangeRequest;
import com.example.demo.domain.user.dto.UserResponse;
import com.example.demo.domain.user.service.UserService;
import com.example.demo.global.common.response.ApiResponse;
import com.example.demo.global.security.CustomUserDetails;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/me")
public class MyPageController {

    private final UserService userService;

    @GetMapping
    public ApiResponse<UserResponse> findMyPage(
            @AuthenticationPrincipal CustomUserDetails userDetails
    ) {
        return ApiResponse.success(userService.findMyPage(userDetails.getUserId()));
    }

    @PatchMapping
    public ApiResponse<UserResponse> updateMyPage(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody MyPageUpdateRequest request
    ){
        return ApiResponse.success(userService.updateMyPage(userDetails.getUserId(), request));
    }

    @PatchMapping("/password")
    public ApiResponse<Void> changePassword(
            @AuthenticationPrincipal CustomUserDetails userDetails,
            @Valid @RequestBody PasswordChangeRequest request
    ) {
        userService.changePassword(userDetails.getUserId(), request);
        return ApiResponse.success(null);
    }
}
