package com.example.demo.domain.user;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    // loginId를 통해 사용자 조회
    Optional<User> findByLoginId(String loginId);

    // loginId가 존재하는지 확인
    boolean existsByLoginId(String loginId);

    Optional<User> findByIdAndActiveTrue(Long id);

    Optional<User> findByLoginIdAndActiveTrue(String loginId);

    List<User> findByRoleAndActiveTrueOrderByCreatedAtDesc(UserRole role);

    Optional<User> findByIdAndRoleAndActiveTrue(Long id, UserRole role);

    // 이름 + 휴대폰 번호로 활성 사용자 찾기
    Optional<User> findByNameAndPhoneAndActiveTrue(String name, String phone);

    Optional<User> findByLoginIdAndNameAndPhoneAndActiveTrue(
            String loginId,
            String name,
            String phone
    );
}
