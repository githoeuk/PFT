package com.example.demo.domain.worksite.controller;

import com.example.demo.domain.worksite.dto.WorkSiteCreateRequest;
import com.example.demo.domain.worksite.dto.WorkSiteResponse;
import com.example.demo.domain.worksite.dto.WorkSiteUpdateRequest;
import com.example.demo.domain.worksite.service.WorkSiteService;
import com.example.demo.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/admin/work-sites")
public class WorkSiteController {

    private final WorkSiteService workSiteService;

    @PostMapping
    public ApiResponse<WorkSiteResponse> create(
            @Valid @RequestBody WorkSiteCreateRequest request
    ) {
        return ApiResponse.success(workSiteService.create(request));
    }

    @GetMapping
    public ApiResponse<List<WorkSiteResponse>> findAllActive() {
        return ApiResponse.success(workSiteService.findAllActive());
    }

    @GetMapping("/{workSiteId}")
    public ApiResponse<WorkSiteResponse> findActiveById(
            @PathVariable Long workSiteId) {
        return ApiResponse.success(workSiteService.findActiveById(workSiteId));
    }

    @PatchMapping("/{workSiteId}")
    public ApiResponse<WorkSiteResponse> update(
            @PathVariable Long workSiteId,
            @Valid @RequestBody WorkSiteUpdateRequest request
    ) {
        return ApiResponse.success(workSiteService.update(workSiteId, request));
    }

    @DeleteMapping("/{workSiteId}")
    public ApiResponse<Void> deactivate(
            @PathVariable Long workSiteId
    ) {
        workSiteService.deactivate(workSiteId);
        return ApiResponse.success(null);
    }

}
