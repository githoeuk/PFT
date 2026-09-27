package com.example.demo.domain.beacon.service;

import com.example.demo.domain.beacon.Beacon;
import com.example.demo.domain.beacon.BeaconRepository;
import com.example.demo.domain.beacon.dto.BeaconCreateRequest;
import com.example.demo.domain.beacon.dto.BeaconResponse;
import com.example.demo.domain.beacon.dto.BeaconUpdateRequest;
import com.example.demo.domain.worksite.WorkSite;
import com.example.demo.domain.worksite.WorkSiteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BeaconService {

    private final BeaconRepository beaconRepository;
    private final WorkSiteRepository workSiteRepository;

    @Transactional
    public BeaconResponse create(BeaconCreateRequest request){
        WorkSite workSite = findActiveWorkSite(request.workSiteId());

        if (beaconRepository.existsByUuidAndMajorAndMinor(
                request.uuid(),
                request.major(),
                request.minor()
        )){
            throw new IllegalArgumentException("이미 등록된 비콘입니다.");
        }
        Beacon beacon = Beacon.builder()
                .workSite(workSite)
                .uuid(request.uuid())
                .major(request.major())
                .minor(request.minor())
                .name(request.name())
                .rssiThreshold(request.rssiThreshold())
                .active(true)
                .build();

        Beacon savedBeacon = beaconRepository.save(beacon);
        return BeaconResponse.from(savedBeacon);
    }

    @Transactional
    public BeaconResponse update(Long beaconId, BeaconUpdateRequest request){
        Beacon beacon = findActiveBeacon(beaconId);
        WorkSite workSite = findActiveWorkSite(request.workSiteId());

        if (beaconRepository.existsByUuidAndMajorAndMinorAndIdNot(
                request.uuid(),
                request.major(),
                request.minor(),
                beaconId
        )){
            throw new IllegalArgumentException("이미 등록된 비콘입니다.");
        }
        beacon.update(
                workSite,
                request.uuid(),
                request.major(),
                request.minor(),
                request.name(),
                request.rssiThreshold()
        );

        return BeaconResponse.from(beacon);
    }

    @Transactional
    public void deactivate(Long beaconId){
        Beacon beacon = findActiveBeacon(beaconId);
        beacon.deactivate();
    }

    public Beacon findActiveBeaconByIdentifier(String uuid,Integer major,Integer minor){
        return beaconRepository.findByUuidAndMajorAndMinorAndActiveTrue(uuid,major,minor)
                .orElseThrow(() -> new IllegalArgumentException("등록된 비콘을 찾을 수 없습니다."));
    }

    public void validateBeaconInRange(Beacon beacon,Integer rssi){
        if (!beacon.isInRange(rssi)){
            throw new IllegalArgumentException("비콘이 범위 내에 없습니다.");
        }
    }

    public List<BeaconResponse> findByWorkSite(Long workSiteId){
        findActiveWorkSite(workSiteId);
        return beaconRepository.findByWorkSite_IdAndActiveTrueOrderByCreatedAtDesc(workSiteId)
                .stream()
                .map(BeaconResponse::from)
                .toList();
    }

    private Beacon findActiveBeacon(Long beaconId){
        return beaconRepository.findByIdAndActiveTrue(beaconId)
                .orElseThrow(()-> new IllegalArgumentException("비콘을 찾을 수 없습니다."));
    }

    private WorkSite findActiveWorkSite(Long workSiteId){
        return workSiteRepository.findByIdAndActiveTrue(workSiteId)
                .orElseThrow(()-> new IllegalArgumentException("작업 현장을 찾을 수 없습니다."));
    }

}


