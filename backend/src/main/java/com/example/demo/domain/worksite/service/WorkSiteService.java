package com.example.demo.domain.worksite.service;

import com.example.demo.domain.worksite.WorkSite;
import com.example.demo.domain.worksite.WorkSiteRepository;
import com.example.demo.domain.worksite.dto.WorkSiteCreateRequest;
import com.example.demo.domain.worksite.dto.WorkSiteResponse;
import com.example.demo.domain.worksite.dto.WorkSiteUpdateRequest;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class WorkSiteService {

    private final WorkSiteRepository workSiteRepository;

    @Transactional
    public WorkSiteResponse create(WorkSiteCreateRequest request) {
        if (workSiteRepository.existsByName(request.name())) {
            throw new IllegalArgumentException("이미 등록된 작업 현장 이름입니다.");
        }

        WorkSite workSite = WorkSite.builder()
                .name(request.name())
                .address(request.address())
                .description(request.description())
                .active(true)
                .build();

        WorkSite savedWorkSite = workSiteRepository.save(workSite);
        return WorkSiteResponse.from(savedWorkSite);
    }

    public List<WorkSiteResponse> findAllActive(){
        return workSiteRepository.findByActiveTrueOrderByCreatedAtDesc()
                .stream()
                .map(WorkSiteResponse::from)
                .toList();
    }

    public WorkSiteResponse findActiveById(Long workSiteId){
        WorkSite workSite = findActiveWorkSite(workSiteId);
        return WorkSiteResponse.from(workSite);
    }

    @Transactional
    public WorkSiteResponse update(Long workSiteId, WorkSiteUpdateRequest request) {
        WorkSite workSite = findActiveWorkSite(workSiteId);

        workSite.update(
                request.name(),
                request.address(),
                request.description()
        );

        return WorkSiteResponse.from(workSite);
    }


    @Transactional
    public void deactivate(Long workSiteId){
        WorkSite workSite = findActiveWorkSite(workSiteId);
        workSite.deactivate();
    }

    private WorkSite findActiveWorkSite(Long workSiteId){
        return workSiteRepository.findByIdAndActiveTrue(workSiteId)
                .orElseThrow(() -> new IllegalArgumentException("작업 현장을 찾을 수 없습니다."));
    }
}
