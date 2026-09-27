package com.example.demo.domain.worksite.dto;

import com.example.demo.domain.worksite.WorkSite;
import java.time.LocalDateTime;

public record WorkSiteResponse(
        Long id,
        String name,
        String address,
        String description,
        boolean active,
        LocalDateTime createdTime,
        LocalDateTime updatedAt
) {

    public static WorkSiteResponse from(WorkSite workSite) {
        return new WorkSiteResponse(
                workSite.getId(),
                workSite.getName(),
                workSite.getAddress(),
                workSite.getDescription(),
                workSite.isActive(),
                workSite.getCreatedAt(),
                workSite.getUpdatedAt()
        );
    }
}