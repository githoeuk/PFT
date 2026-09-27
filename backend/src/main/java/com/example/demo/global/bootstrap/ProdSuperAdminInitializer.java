package com.example.demo.global.bootstrap;

import com.example.demo.domain.user.User;
import com.example.demo.domain.user.UserRepository;
import com.example.demo.domain.user.UserRole;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Slf4j
@Component
@Profile("prod")
@RequiredArgsConstructor
public class ProdSuperAdminInitializer implements ApplicationRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.bootstrap.super-admin.login-id:}")
    private String loginId;

    @Value("${app.bootstrap.super-admin.password:}")
    private String password;

    @Value("${app.bootstrap.super-admin.name:Super Admin}")
    private String name;

    @Value("${app.bootstrap.super-admin.phone:}")
    private String phone;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (userRepository.count() > 0) {
            return;
        }

        if (!StringUtils.hasText(loginId) || !StringUtils.hasText(password)) {
            log.warn("SUPER_ADMIN bootstrap skipped. SUPER_ADMIN_LOGIN_ID and SUPER_ADMIN_PASSWORD are required.");
            return;
        }

        User superAdmin = User.builder()
                .loginId(loginId)
                .password(passwordEncoder.encode(password))
                .name(name)
                .phone(StringUtils.hasText(phone) ? phone : null)
                .role(UserRole.SUPER_ADMIN)
                .active(true)
                .build();

        userRepository.save(superAdmin);
        log.info("Initial SUPER_ADMIN account created. loginId={}", loginId);
    }
}
