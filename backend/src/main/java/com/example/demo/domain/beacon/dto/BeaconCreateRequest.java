package com.example.demo.domain.beacon.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record BeaconCreateRequest(
        @NotNull
        Long workSiteId,

        @NotBlank
        @Size(max = 36)
        String uuid,

        @NotNull
        Integer major,

        @NotNull
        Integer minor,

        @NotBlank
        @Size(max = 100)
        String name,

        @NotNull
        Integer rssiThreshold
) {

}
