package com.example.demo.domain.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record FindLoginIdRequest(

        @NotBlank(message = "이름은 필수입니다.")
        String name,

        @NotBlank(message = "휴대폰 번호는 필수입니다.")
        String phone
) {
}
