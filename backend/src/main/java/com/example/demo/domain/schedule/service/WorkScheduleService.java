package com.example.demo.domain.schedule.service;

import com.example.demo.domain.schedule.WorkSchedule;
import com.example.demo.domain.schedule.WorkScheduleRepository;
import com.example.demo.domain.schedule.dto.WorkScheduleCreateRequest;
import com.example.demo.domain.schedule.dto.WorkScheduleResponse;
import com.example.demo.domain.schedule.dto.WorkScheduleUpdateRequest;
import com.example.demo.domain.worksite.WorkSite;
import com.example.demo.domain.worksite.WorkSiteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.util.List;


@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class WorkScheduleService {

    private final WorkScheduleRepository workScheduleRepository;
    private final WorkSiteRepository workSiteRepository;
    private final Clock clock;

    @Transactional
    public WorkScheduleResponse create(WorkScheduleCreateRequest request) {

        WorkSite workSite = findActiveWorkSite(request.workSiteId());

        validateTimeRange(request.startTime(),request.endTime());
        validateNotPastWorkDate(request.workDate());

        if (workScheduleRepository.existsByWorkSite_IdAndWorkDate(
                request.workSiteId(),
                request.workDate()
        )) {
            throw new IllegalArgumentException("해당 날짜에 이미 등록된 근무일정입니다.");
        }
        WorkSchedule workSchedule = WorkSchedule.builder()
                .workSite(workSite)
                .workDate(request.workDate())
                .startTime(request.startTime())
                .endTime(request.endTime())
                .lateGraceMinutes(request.lateGraceMinutes())
                .earlyLeaveGraceMinutes(request.earlyLeaveGraceMinutes())
                .build();

        WorkSchedule savedWorkSchedule = workScheduleRepository.save(workSchedule);
        return WorkScheduleResponse.from(savedWorkSchedule);
    }

    public List<WorkScheduleResponse> findByWorkSite(Long workSiteId) {
        findActiveWorkSite(workSiteId);

        return workScheduleRepository.findByWorkSite_Id(workSiteId)
                .stream()
                .map(WorkScheduleResponse::from)
                .toList();
    }

    public WorkScheduleResponse findById(Long scheduleId) {
        WorkSchedule schedule = workScheduleRepository.findById(scheduleId)
                .orElseThrow(() -> new IllegalArgumentException("해당 ID의 근무일정을 찾을 수 없습니다."));
        return WorkScheduleResponse.from(schedule);
    }

    @Transactional
    public WorkScheduleResponse update(Long scheduleId, WorkScheduleUpdateRequest request) {
        WorkSchedule schedule = workScheduleRepository.findById(scheduleId)
                .orElseThrow((() -> new IllegalArgumentException("작업 일정을 찾을 수 없습니다.")));

        validateTimeRange(request.startTime(), request.endTime());

        validateNotPastWorkDate(request.workDate());

        if (workScheduleRepository.existsByWorkSite_IdAndWorkDateAndIdNot(
                schedule.getWorkSite().getId(),
                request.workDate(),
                scheduleId
        )){
            throw new IllegalArgumentException("해당 날짜에 이미 등록된 작업 일정이 있습니다.");
        }

        schedule.update(
                request.workDate(),
                request.startTime(),
                request.endTime(),
                request.lateGraceMinutes(),
                request.earlyLeaveGraceMinutes()
        );
        return WorkScheduleResponse.from(schedule);
    }

    private void validateNotPastWorkDate(LocalDate workDate){

        LocalDate today = LocalDate.now(clock);

        if (workDate.isBefore(today)){
            throw new IllegalArgumentException("과거 날짜로 작업 일정을 등록하거나 수정할 수 없습니다.");
        }
    }

    private WorkSite findActiveWorkSite(Long workSiteId) {
        return workSiteRepository.findByIdAndActiveTrue(workSiteId)
                .orElseThrow(() -> new IllegalArgumentException("해당 ID의 활성화된 작업장을 찾을 수 없습니다."));
    }

    private void validateTimeRange(java.time.LocalTime startTime, java.time.LocalTime endTime) {
        if (!startTime.isBefore(endTime)) {
            throw new IllegalArgumentException("시작 시간은 종료 시간보다 이전이어야 합니다.");
        }
    }

}
