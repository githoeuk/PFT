package com.example.demo.domain.user.dto;

public record EmployeeCreateResponse (
        UserResponse employee,
        String temporaryPassword
) {
}
