package com.example.demo.domain.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminAccountUpdateRequest(
        @NotBlank
        @Size(max = 50)
        String name,

        @Size(max = 30)
        String phone
) {
}
