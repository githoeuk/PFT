package com.example.demo.domain.auth.dto;

import com.example.demo.domain.user.dto.UserResponse;

public record LoginResponse (

        String accessToken,
        String refreshToken,
        UserResponse user
){
}
