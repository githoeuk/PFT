package com.example.demo.domain.user.dto;

public record AdminAccountCreateResponse(
        UserResponse admin,
        String temporaryPassword
) {
}
