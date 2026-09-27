package com.example.demo.domain.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
    @NotBlank String loginId,
    @NotBlank String password
) {
}