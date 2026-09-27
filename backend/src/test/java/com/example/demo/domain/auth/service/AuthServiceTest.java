package com.example.demo.domain.auth.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.example.demo.domain.auth.dto.LoginRequest;
import com.example.demo.domain.auth.dto.LoginResponse;
import com.example.demo.domain.user.UserRole;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@ActiveProfiles("test")
@SpringBootTest
@Transactional
class AuthServiceTest {

    @Autowired
    private AuthService authService;

    @Test
    void login_withValidCredentials_returnsAccessTokenAndUser() {
        LoginResponse response = authService.login(new LoginRequest("employee01", "password"));

        assertNotNull(response.accessToken());
        assertEquals("employee01", response.user().loginId());
        assertEquals(UserRole.EMPLOYEE, response.user().role());
    }
}
