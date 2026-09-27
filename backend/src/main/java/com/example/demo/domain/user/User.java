package com.example.demo.domain.user;

import com.example.demo.global.common.entity.BaseTimeEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Entity
@Table(
        name = "users",
        indexes = {
                @Index(name = "idx_users_login_id", columnList = "login_id")
        },
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_users_login_id", columnNames = "login_id")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "login_id", nullable = false, length = 50)
    private String loginId;

    @Column(nullable = false, length = 255)
    private String password;

    @Column(nullable = false, length = 50)
    private String name;

    @Column(length = 30)
    private String phone;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private UserRole role;

    @Column(nullable = false)
    private boolean active;

    public void deactivate() {
        this.active = false;
    }

    public void update(String name, String phone) {
        this.name = name;
        this.phone = phone;
    }

    public void changePassword(String encodedPassword) {
        this.password = encodedPassword;
    }

    @Builder
    private User(String loginId, String password, String name, String phone, UserRole role, Boolean active) {
        this.loginId = loginId;
        this.password = password;
        this.name = name;
        this.phone = phone;
        this.role = role;
        this.active = active == null || active;
    }

}
