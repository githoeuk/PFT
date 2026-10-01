<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { ClipboardCheck, Save } from '@lucide/vue'
import { useRoute } from 'vue-router'

import { calculateLaborCost } from '@/services/attendanceService'
import { useErpStore } from '@/stores/erp'
import type { AttendanceInput, AttendanceStatus, WorkerRole } from '@/types/erp'
import { attendanceStatusOptions, workerRoleOptions } from '@/utils/erpLabels'
import { formatCurrency, todayIso } from '@/utils/formatters'

interface AttendanceDraft {
  status: AttendanceStatus | ''
  workRole: WorkerRole
  startTime: string
  endTime: string
  overtimeHours: number
  dailyRate: number
  note: string
}

const store = useErpStore()
const route = useRoute()
const selectedDate = ref(todayIso())
const requestedSiteId = typeof route.query.site === 'string' ? route.query.site : ''
const selectedSiteId = ref(
  store.activeSites.some((site) => site.id === requestedSiteId)
    ? requestedSiteId
    : (store.activeSites[0]?.id ?? ''),
)
const savedMessage = ref('')
const drafts = reactive<Record<string, AttendanceDraft>>({})

const selectedAssignments = computed(() => store.assignmentsForSite(selectedSiteId.value))
const existingRecords = computed(() =>
  selectedSiteId.value ? store.attendanceFor(selectedDate.value, selectedSiteId.value) : [],
)
const attendanceWorkers = computed(() => {
  const workerIds = new Set(
    selectedAssignments.value
      .filter((assignment) =>
        store.workers.some((worker) => worker.id === assignment.workerId && worker.active),
      )
      .map((assignment) => assignment.workerId),
  )
  for (const record of existingRecords.value) workerIds.add(record.workerId)

  return store.workers.filter((worker) => workerIds.has(worker.id))
})
const selectedCount = computed(
  () => Object.values(drafts).filter((draft) => draft.status !== '').length,
)
const estimatedTotal = computed(() =>
  attendanceWorkers.value.reduce((total, worker) => {
    const draft = drafts[worker.id]
    if (!draft?.status) return total
    return (
      total +
      calculateLaborCost({
        status: draft.status,
        dailyRate: Number(draft.dailyRate) || 0,
        overtimeHours: Number(draft.overtimeHours) || 0,
      })
    )
  }, 0),
)

function loadDrafts() {
  for (const key of Object.keys(drafts)) delete drafts[key]

  for (const worker of attendanceWorkers.value) {
    const record = existingRecords.value.find((candidate) => candidate.workerId === worker.id)
    const assignment = selectedAssignments.value.find(
      (candidate) => candidate.workerId === worker.id,
    )
    drafts[worker.id] = {
      status: record?.status ?? '',
      workRole: record?.workRole ?? assignment?.workRole ?? worker.role,
      startTime: record?.startTime ?? '',
      endTime: record?.endTime ?? '',
      overtimeHours: record?.overtimeHours ?? 0,
      dailyRate: record?.dailyRate ?? assignment?.dailyRate ?? worker.dailyRate,
      note: record?.note ?? '',
    }
  }
}

async function saveAll() {
  if (!selectedSiteId.value || store.saving) return
  savedMessage.value = ''
  const inputs: AttendanceInput[] = []
  for (const worker of attendanceWorkers.value) {
    const draft = drafts[worker.id]
    if (!draft?.status) continue
    inputs.push({
      date: selectedDate.value,
      siteId: selectedSiteId.value,
      workerId: worker.id,
      workRole: draft.workRole,
      status: draft.status,
      startTime: draft.startTime,
      endTime: draft.endTime,
      overtimeHours: Number(draft.overtimeHours) || 0,
      dailyRate: Number(draft.dailyRate) || 0,
      note: draft.note.trim(),
    })
  }
  try {
    await store.saveAttendanceRecords(inputs)
    savedMessage.value = `${inputs.length}건을 저장했습니다`
    window.setTimeout(() => (savedMessage.value = ''), 2500)
  } catch {
    // Keep the drafts open; the shared storage banner reports the failure.
    return
  }
}

watch(
  [
    selectedDate,
    selectedSiteId,
    () =>
      store.siteWorkerAssignments
        .map(
          (assignment) =>
            `${assignment.id}:${assignment.workerId}:${assignment.workRole}:${assignment.dailyRate}`,
        )
        .join('|'),
    () => store.workers.map((worker) => `${worker.id}:${worker.active}`).join('|'),
  ],
  loadDrafts,
  { immediate: true },
)
</script>

<template>
  <section class="page-heading attendance-heading">
    <div>
      <p class="eyebrow">일일 기록</p>
      <h1>출석 관리</h1>
      <p>현장 배정 기준 출석 및 최종 일급 확인</p>
    </div>
    <button
      class="button button-primary"
      type="button"
      :disabled="store.saving || !selectedSiteId || selectedCount === 0"
      @click="saveAll"
    >
      <Save :size="18" /> 저장
    </button>
  </section>

  <section class="attendance-toolbar">
    <label><span>날짜</span><input v-model="selectedDate" type="date" /></label>
    <label>
      <span>현장</span>
      <select v-model="selectedSiteId">
        <option value="" disabled>현장 선택</option>
        <option v-for="site in store.activeSites" :key="site.id" :value="site.id">
          {{ site.name }}
        </option>
      </select>
    </label>
    <div class="toolbar-summary">
      <span
        ><small>선택 인원</small><strong>{{ selectedCount }}</strong></span
      >
      <span
        ><small>예상 인건비</small><strong>{{ formatCurrency(estimatedTotal) }}</strong></span
      >
    </div>
  </section>

  <section v-if="selectedSiteId && attendanceWorkers.length" class="attendance-section">
    <div class="attendance-grid attendance-grid-head" aria-hidden="true">
      <span>근로자</span><span>상태</span><span>작업 직책</span><span>출근</span><span>퇴근</span
      ><span>연장</span><span>적용 일급</span><span>비고</span><span>인건비</span>
    </div>
    <div
      v-for="worker in attendanceWorkers"
      :key="worker.id"
      class="attendance-grid attendance-row"
    >
      <div class="worker-cell">
        <strong>{{ worker.name }}</strong
        ><small>{{ worker.team || '미지정' }}</small>
      </div>
      <label>
        <span class="mobile-label">상태</span>
        <select v-model="drafts[worker.id]!.status">
          <option value="">미기록</option>
          <option
            v-for="option in attendanceStatusOptions"
            :key="option.value"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </select>
      </label>
      <label>
        <span class="mobile-label">작업 직책</span>
        <select v-model="drafts[worker.id]!.workRole">
          <option v-for="option in workerRoleOptions" :key="option.value" :value="option.value">
            {{ option.label }}
          </option>
        </select>
      </label>
      <label>
        <span class="mobile-label">출근</span>
        <input v-model="drafts[worker.id]!.startTime" type="time" />
      </label>
      <label>
        <span class="mobile-label">퇴근</span>
        <input v-model="drafts[worker.id]!.endTime" type="time" />
      </label>
      <label>
        <span class="mobile-label">연장</span>
        <input
          v-model.number="drafts[worker.id]!.overtimeHours"
          type="number"
          min="0"
          max="12"
          step="0.5"
        />
      </label>
      <label>
        <span class="mobile-label">적용 일급</span>
        <input v-model.number="drafts[worker.id]!.dailyRate" type="number" min="0" step="1000" />
      </label>
      <label>
        <span class="mobile-label">비고</span>
        <input v-model="drafts[worker.id]!.note" placeholder="비고 입력" />
      </label>
      <strong class="row-cost">{{
        drafts[worker.id]!.status
          ? formatCurrency(
              calculateLaborCost({
                status: drafts[worker.id]!.status as AttendanceStatus,
                dailyRate: Number(drafts[worker.id]!.dailyRate) || 0,
                overtimeHours: Number(drafts[worker.id]!.overtimeHours) || 0,
              }),
            )
          : '-'
      }}</strong>
    </div>
    <div class="attendance-footer">
      <span v-if="savedMessage" class="save-message">
        <ClipboardCheck :size="17" />{{ savedMessage }}
      </span>
      <span v-else></span>
      <button
        class="button button-primary"
        type="button"
        :disabled="store.saving || !selectedSiteId || selectedCount === 0"
        @click="saveAll"
      >
        <Save :size="18" /> 저장
      </button>
    </div>
  </section>

  <section v-else class="content-section empty-state">
    <ClipboardCheck :size="30" />
    <strong>{{
      selectedSiteId ? '이 현장에 배정된 근로자가 없습니다' : '출석 등록 준비가 필요합니다'
    }}</strong>
    <div class="empty-actions">
      <RouterLink v-if="!store.activeSites.length" class="button button-secondary" to="/sites">
        현장 등록
      </RouterLink>
      <RouterLink
        v-else-if="selectedSiteId"
        class="button button-secondary"
        :to="`/sites/${selectedSiteId}`"
      >
        현장 근로자 배정
      </RouterLink>
      <RouterLink v-if="!store.activeWorkers.length" class="button button-secondary" to="/workers">
        근로자 등록
      </RouterLink>
    </div>
  </section>
</template>
