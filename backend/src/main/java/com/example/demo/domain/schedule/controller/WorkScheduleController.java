package com.example.demo.domain.schedule.controller;

import com.example.demo.domain.schedule.dto.WorkScheduleCreateRequest;
import com.example.demo.domain.schedule.dto.WorkScheduleResponse;
import com.example.demo.domain.schedule.dto.WorkScheduleUpdateRequest;
import com.example.demo.domain.schedule.service.WorkScheduleService;
import com.example.demo.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/admin/work-schedules")
public class WorkScheduleController {

    private final WorkScheduleService workScheduleService;

    // 작업 생성
    @PostMapping
    public ApiResponse<WorkScheduleResponse> create(
            @Valid @RequestBody WorkScheduleCreateRequest request
            ) {
        return ApiResponse.success(workScheduleService.create(request));
    }

    // 작업 일정 단건 조회
    @GetMapping("/{scheduleId}")
    public ApiResponse<WorkScheduleResponse> findById(
            @PathVariable Long scheduleId
    ) {
        return ApiResponse.success(workScheduleService.findById(scheduleId));
    }

    // 작업 현장별 일정 목록 조회
    @GetMapping("/work-sites/{workSiteId}")
    public ApiResponse<List<WorkScheduleResponse>> findByWorkSite(
            @PathVariable Long workSiteId
    ) {
        return ApiResponse.success(workScheduleService.findByWorkSite(workSiteId));
    }

    // 작업 수정
    @PatchMapping("/{scheduleId}")
    public ApiResponse<WorkScheduleResponse> update(
            @PathVariable Long scheduleId,
            @Valid @RequestBody WorkScheduleUpdateRequest request
    ){
        return ApiResponse.success(workScheduleService.update(scheduleId, request));
    }

}
