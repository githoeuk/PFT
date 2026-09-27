package com.example.demo.domain.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PasswordResetRequest (
        @NotBlank(message = "아이디는 필수입니다.")
        String loginId,

        @NotBlank(message = "이름은 필수입니다.")
        String name,

        @NotBlank(message = "휴대폰 번호는 필수입니다.")
        String phone,

        @NotBlank(message = "새 비밀번호는 필수입니다.")
        @Size(min = 8, max = 50, message = "새 비밀번호는 8자 이상 50자 이하여야 합니다.")
        String newPassword,

        @NotBlank(message = "새 비밀번호 확인은 필수입니다.")
        String newPasswordConfirm
){
}
