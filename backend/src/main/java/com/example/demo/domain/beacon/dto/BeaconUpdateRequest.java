package com.example.demo.domain.beacon.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record BeaconUpdateRequest(
        @NotBlank(message = "비콘 이름은 필수입니다.")
        @Size(max = 100, message = "비콘 이름은 100자 이하여야 합니다.")
        String name,

        @NotNull(message = "RSSI 기준값은 필수입니다.")
        Integer rssiThreshold,

        @NotNull(message = "작업 현장 ID는 필수입니다.")
        Long workSiteId,

        @NotBlank(message = "비콘 UUID는 필수입니다.")
        @Size(max = 36, message = "비콘 UUID는 36자 이하여야 합니다.")
        String uuid,

        @NotNull(message = "비콘 major는 필수입니다.")
        Integer major,

        @NotNull(message = "비콘 minor는 필수입니다.")
        Integer minor
) {
}
