package com.example.demo.domain.auth.service;

import com.example.demo.domain.auth.RefreshToken;
import com.example.demo.domain.auth.RefreshTokenRepository;
import com.example.demo.domain.auth.dto.*;
import com.example.demo.domain.user.User;
import com.example.demo.domain.user.UserRepository;
import com.example.demo.domain.user.dto.UserResponse;
import com.example.demo.global.security.JwtProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;
    private final RefreshTokenRepository refreshTokenRepository;

    @Transactional
    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByLoginIdAndActiveTrue(request.loginId())
                .orElseThrow(() -> new IllegalArgumentException("아이디 또는 비밀번호가 일치하지 않습니다."));

        if (!passwordEncoder.matches(request.password(), user.getPassword())) {
            throw new IllegalArgumentException("아이디 또는 비밀번호가 일치하지 않습니다.");
        }

        String accessToken = jwtProvider.createAccessToken(user);
        String refreshToken = jwtProvider.createRefreshToken(user);

        LocalDateTime refreshTokenExpiresAt = LocalDateTime.now()
                .plusSeconds(jwtProvider.getRefreshTokenExpirationMs() / 1000);

        refreshTokenRepository.findByUser_Id(user.getId())
                .ifPresentOrElse(
                        savedRefreshToken -> savedRefreshToken.rotate(refreshToken, refreshTokenExpiresAt),
                        () -> refreshTokenRepository.save(
                                RefreshToken.builder()
                                        .user(user)
                                        .token(refreshToken)
                                        .expiresAt(refreshTokenExpiresAt)
                                        .build()
                        )
                );

        return new LoginResponse(
                accessToken,
                refreshToken,
                UserResponse.from(user)
        );
    }

    @Transactional
    public TokenRefreshResponse refresh(TokenRefreshRequest request) {
        String refreshTokenValue = request.refreshToken();

        if (!jwtProvider.validateToken(refreshTokenValue)) {
            throw new IllegalArgumentException("유효하지 않은 refreshToken입니다.");
        }

        RefreshToken refreshToken = refreshTokenRepository.findByToken(refreshTokenValue)
                .orElseThrow(() -> new IllegalArgumentException("등록되지 않은 refreshToken입니다."));

        if (refreshToken.isExpired(LocalDateTime.now())) {
            refreshTokenRepository.delete(refreshToken);
            throw new IllegalArgumentException("만료된 refreshToken입니다.");
        }

        User user = userRepository.findByIdAndActiveTrue(refreshToken.getUser().getId())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));

        String accessToken = jwtProvider.createAccessToken(user);

        return new TokenRefreshResponse(accessToken);
    }

    @Transactional
    public void logout(LogoutRequest request) {
        refreshTokenRepository.findByToken(request.refreshToken())
                .ifPresent(refreshTokenRepository::delete);
    }

    public FindLoginIdResponse findLoginId(FindLoginIdRequest request) {
        User user = userRepository.findByNameAndPhoneAndActiveTrue(
                        request.name(),
                        request.phone()
                )
                .orElseThrow(() -> new IllegalArgumentException("일치하는 사용자 정보를 찾을 수 없습니다."));
        return new FindLoginIdResponse(user.getLoginId());
    }

    @Transactional
    public void resetPassword(PasswordResetRequest request) {
        if (!request.newPassword().equals(request.newPasswordConfirm())) {
            throw new IllegalArgumentException("새 비밀번호와 비밀번호 확인이 일치하지 않습니다.");
        }

        User user = userRepository.findByLoginIdAndNameAndPhoneAndActiveTrue(
                        request.loginId(),
                        request.name(),
                        request.phone()
                )
                .orElseThrow(() -> new IllegalArgumentException("일치하는 사용자 정보를 찾을 수 없습니다."));

        String encodedPassword = passwordEncoder.encode(request.newPassword());
        user.changePassword(encodedPassword);

        refreshTokenRepository.deleteByUser_Id(user.getId());
    }
}
