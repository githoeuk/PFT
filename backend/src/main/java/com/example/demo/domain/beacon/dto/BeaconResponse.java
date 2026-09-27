package com.example.demo.domain.beacon.dto;

import com.example.demo.domain.beacon.Beacon;

import java.time.LocalDateTime;

public record BeaconResponse(
        Long id,
        Long workSiteId,
        String workSiteName,
        String uuid,
        Integer major,
        Integer minor,
        String name,
        Integer rssiThreshold,
        boolean active,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {

    public static BeaconResponse from(Beacon beacon) {
        return new BeaconResponse(
                beacon.getId(),
                beacon.getWorkSite().getId(),
                beacon.getWorkSite().getName(),
                beacon.getUuid(),
                beacon.getMajor(),
                beacon.getMinor(),
                beacon.getName(),
                beacon.getRssiThreshold(),
                beacon.isActive(),
                beacon.getCreatedAt(),
                beacon.getUpdatedAt()
        );
    }
}
