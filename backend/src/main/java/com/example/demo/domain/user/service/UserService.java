package com.example.demo.domain.user.service;

import com.example.demo.domain.user.User;
import com.example.demo.domain.user.UserRepository;
import com.example.demo.domain.user.UserRole;
import com.example.demo.domain.user.dto.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private static final String TEMP_PASSWORD_CHARS =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    private static final int TEMP_PASSWORD_LENGTH = 10;
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    // 직원 생성
    @Transactional
    public EmployeeCreateResponse createEmployee(EmployeeCreateRequest request) {

        if (userRepository.existsByLoginId(request.loginId())){
            throw new IllegalArgumentException("이미 사용 중인 아이디입니다.");
        }

        String temporaryPassword = generateTemporaryPassword();
        String encodedPassword = passwordEncoder.encode(temporaryPassword);

        User employee = User.builder()
                .loginId(request.loginId())
                .password(encodedPassword)
                .name(request.name())
                .phone(request.phone())
                .role(UserRole.EMPLOYEE)
                .active(true)
                .build();

        User savedEmployee = userRepository.save(employee);

        return new EmployeeCreateResponse(
                UserResponse.from(savedEmployee),
                temporaryPassword
        );
    }

    public List<UserResponse> findAllEmployees(){
        return userRepository.findByRoleAndActiveTrueOrderByCreatedAtDesc(UserRole.EMPLOYEE)
                .stream()
                .map(UserResponse::from)
                .toList();
    }

    // id로 찾기
    public UserResponse findEmployeeById(Long employeeId){
        User employee = findActiveEmployee(employeeId);
        return UserResponse.from(employee);
    }

    @Transactional
    public UserResponse updateEmployee(Long employeeId, EmployeeUpdateRequest request) {
        User employee = findActiveEmployee(employeeId);

        employee.update(
                request.name(),
                request.phone()
        );

        return UserResponse.from(employee);
    }

    @Transactional
    public void deactivateEmployee(Long employeeId){
        User employee = findActiveEmployee(employeeId);
        employee.deactivate();
    }

    @Transactional
    public EmployeePasswordResetResponse resetEmployeePassword(Long employeeId){
        User employee = findActiveEmployee(employeeId);

        String temporaryPassword = generateTemporaryPassword();
        String encodedPassword = passwordEncoder.encode(temporaryPassword);

        employee.changePassword(encodedPassword);

        return new EmployeePasswordResetResponse(temporaryPassword);
    }

    // 관리자 계정 생성
    @Transactional
    public AdminAccountCreateResponse createAdmin(AdminAccountCreateRequest request) {

        if (userRepository.existsByLoginId(request.loginId())) {
            throw new IllegalArgumentException("이미 사용 중인 아이디입니다.");
        }

        String temporaryPassword = generateTemporaryPassword();
        String encodedPassword = passwordEncoder.encode(temporaryPassword);

        User admin = User.builder()
                .loginId(request.loginId())
                .password(encodedPassword)
                .name(request.name())
                .phone(request.phone())
                .role(UserRole.ADMIN)
                .active(true)
                .build();

        User savedAdmin = userRepository.save(admin);

        return new AdminAccountCreateResponse(
                UserResponse.from(savedAdmin),
                temporaryPassword
        );
    }

    // 관리자 계정 목록 조회
    public List<UserResponse> findAllAdmins() {
        return userRepository.findByRoleAndActiveTrueOrderByCreatedAtDesc(UserRole.ADMIN)
                .stream()
                .map(UserResponse::from)
                .toList();
    }

    // 관리자 계정 단건 조회
    public UserResponse findAdminById(Long adminId) {
        User admin = findActiveAdminAccount(adminId);
        return UserResponse.from(admin);
    }

    // 관리자 계정 이름/전화번호 수정
    @Transactional
    public UserResponse updateAdmin(Long adminId, AdminAccountUpdateRequest request) {
        User admin = findActiveAdminAccount(adminId);

        admin.update(
                request.name(),
                request.phone()
        );

        return UserResponse.from(admin);
    }

    // 관리자 계정 비밀번호 초기화
    @Transactional
    public AdminAccountPasswordResetResponse resetAdminPassword(Long adminId) {
        User admin = findActiveAdminAccount(adminId);

        String temporaryPassword = generateTemporaryPassword();
        String encodedPassword = passwordEncoder.encode(temporaryPassword);

        admin.changePassword(encodedPassword);

        return new AdminAccountPasswordResetResponse(temporaryPassword);
    }

    // 관리자 계정 비활성화
    @Transactional
    public void deactivateAdmin(Long adminId) {
        User admin = findActiveAdminAccount(adminId);
        admin.deactivate();
    }

    public UserResponse findActiveById(Long userId){
        User user = findActiveUser(userId);
        return UserResponse.from(user);
    }

    // 내 정보 조회
    public UserResponse findMyPage(Long userId){
        User user = findActiveUser(userId);
        return UserResponse.from(user);
    }

    // 사용자의 이름/전화번호 수정
    @Transactional
    public UserResponse updateMyPage(Long userId, MyPageUpdateRequest request) {
        User user = findActiveUser(userId);

        user.update(
                request.name(),
                request.phone()
        );
        return UserResponse.from(user);
    }

    // 비밀번호 변경
    @Transactional
    public void changePassword(Long userId, PasswordChangeRequest request){
        User user = findActiveUser(userId);

        if (!passwordEncoder.matches(request.currentPassword(), user.getPassword())){
            throw new IllegalArgumentException("현재 비밀번호가 일치하지 않습니다.");
        }

        if (request.currentPassword().equals(request.newPassword())){
            throw new IllegalArgumentException("새 비밀번호는 현재 비밀번호와 달라야 합니다.");
        }

        String encodedNewPassword = passwordEncoder.encode(request.newPassword());
        user.changePassword(encodedNewPassword);
    }

    @Transactional
    public void deactivate(Long userId){
        User user = findActiveUser(userId);
        user.deactivate();
    }

    private User findActiveEmployee(Long employeeId){
        return userRepository.findByIdAndRoleAndActiveTrue(employeeId, UserRole.EMPLOYEE)
                .orElseThrow(() -> new IllegalArgumentException("직원을 찾을 수 없습니다."));
    }

    private User findActiveAdminAccount(Long adminId) {
        return userRepository.findByIdAndRoleAndActiveTrue(adminId, UserRole.ADMIN)
                .orElseThrow(() -> new IllegalArgumentException("관리자 계정을 찾을 수 없습니다."));
    }

    private User findActiveUser(Long userId){
        return userRepository.findByIdAndActiveTrue(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
    }

    private String generateTemporaryPassword(){
        StringBuilder password = new StringBuilder();

        for (int i = 0; i <TEMP_PASSWORD_LENGTH; i++){
            int index = SECURE_RANDOM.nextInt(TEMP_PASSWORD_CHARS.length());
            password.append(TEMP_PASSWORD_CHARS.charAt(index));
        }

        return password.toString();
    }
}
