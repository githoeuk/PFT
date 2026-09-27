package com.example.demo.domain.beacon.controller;

import com.example.demo.domain.beacon.dto.BeaconCreateRequest;
import com.example.demo.domain.beacon.dto.BeaconResponse;
import com.example.demo.domain.beacon.dto.BeaconUpdateRequest;
import com.example.demo.domain.beacon.service.BeaconService;
import com.example.demo.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/admin/beacons")
public class BeaconController {

    private final BeaconService  beaconService;

    // 비콘 생성
    @PostMapping
    public ApiResponse<BeaconResponse> create(
            @Valid @RequestBody BeaconCreateRequest request
            ){
        return ApiResponse.success(beaconService.create(request));
    }

    // 작업 현장별 비콘 목록 조회
    @GetMapping("/work-sites/{workSiteId}")
    public ApiResponse<List<BeaconResponse>> findByWorkSite(
            @PathVariable Long workSiteId
    ){
        return ApiResponse.success(beaconService.findByWorkSite(workSiteId));
    }

    // 비콘 정보 수정
    @PatchMapping("/{beaconId}")
    public ApiResponse<BeaconResponse> update(
            @PathVariable Long beaconId,
            @Valid @RequestBody BeaconUpdateRequest request
    ) {
        return ApiResponse.success(beaconService.update(beaconId, request));
    }

    @DeleteMapping("/{beaconId}")
    public ApiResponse<Void> deactivate(
            @PathVariable Long beaconId
    ){
        beaconService.deactivate(beaconId);
        return ApiResponse.success(null);
    }

}
