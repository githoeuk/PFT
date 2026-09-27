package com.example.demo.domain.user.dto;

import com.example.demo.domain.user.User;
import com.example.demo.domain.user.UserRole;

public record UserResponse(
        Long id,
        String loginId,
        String name,
        String phone,
        UserRole role,
        boolean active
) {
    public static UserResponse from (User user) {
        return new UserResponse(
                user.getId(),
                user.getLoginId(),
                user.getName(),
                user.getPhone(),
                user.getRole(),
                user.isActive()
        );
    }

}
