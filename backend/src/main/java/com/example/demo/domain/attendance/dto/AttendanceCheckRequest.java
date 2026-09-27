package com.example.demo.domain.attendance.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record AttendanceCheckRequest(
        @NotBlank String beaconUuid,
        @NotNull Integer beaconMajor,
        @NotNull Integer beaconMinor,
        @NotNull Integer rssi,
        @NotBlank String deviceId,
        BigDecimal latitude,
        BigDecimal longitude
) {
}
