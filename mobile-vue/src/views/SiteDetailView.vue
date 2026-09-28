<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import {
  ArrowLeft,
  BriefcaseBusiness,
  CalendarDays,
  ClipboardCheck,
  Pencil,
  Plus,
  Trash2,
  Users,
  X,
} from '@lucide/vue'
import { useRoute } from 'vue-router'

import { calculateWorkedDays, sumLaborCost } from '@/services/attendanceService'
import { useErpStore } from '@/stores/erp'
import type { SiteWorkerAssignment, WorkerRole } from '@/types/erp'
import {
  attendanceStatusLabels,
  siteStatusLabels,
  workerRoleLabels,
  workerRoleOptions,
} from '@/utils/erpLabels'
import { formatCurrency, formatDate } from '@/utils/formatters'

const route = useRoute()
const store = useErpStore()

const siteId = computed(() => String(route.params.siteId ?? ''))
const site = computed(() => store.sites.find((candidate) => candidate.id === siteId.value))
const records = computed(() =>
  store.attendanceRecords
    .filter((record) => record.siteId === siteId.value)
    .sort((left, right) => right.date.localeCompare(left.date)),
)
const workedRecords = computed(() =>
  records.value.filter((record) => record.status === 'present' || record.status === 'half_day'),
)
const assignments = computed(() => store.assignmentsForSite(siteId.value))
const assignmentRows = computed(() =>
  assignments.value
    .map((assignment) => {
      const worker = store.workers.find((candidate) => candidate.id === assignment.workerId)
      if (!worker) return undefined
      const workerRecords = workedRecords.value.filter(
        (record) => record.workerId === assignment.workerId,
      )
      return {
        assignment,
        worker,
        workedDays: calculateWorkedDays(workerRecords),
        laborCost: sumLaborCost(workerRecords),
      }
    })
    .filter((item) => item !== undefined)
    .sort((left, right) => left.worker.name.localeCompare(right.worker.name, 'ko')),
)
const availableWorkers = computed(() => {
  const assignedWorkerIds = new Set(assignments.value.map((assignment) => assignment.workerId))
  return store.activeWorkers.filter((worker) => !assignedWorkerIds.has(worker.id))
})
const painterCount = computed(
  () => assignments.value.filter((assignment) => assignment.workRole === 'painter').length,
)
const totalWorkedDays = computed(() => calculateWorkedDays(workedRecords.value))
const totalLaborCost = computed(() => sumLaborCost(records.value))

const editorOpen = ref(false)
const editingAssignmentId = ref('')
const assignmentForm = reactive({
  workerId: '',
  workRole: 'painter' as WorkerRole,
  dailyRate: 0,
})

function applyWorkerDefaults() {
  const worker = store.workers.find((candidate) => candidate.id === assignmentForm.workerId)
  if (!worker) return
  assignmentForm.workRole = worker.role
  assignmentForm.dailyRate = worker.dailyRate
}

function openAssignmentEditor(assignment?: SiteWorkerAssignment) {
  editorOpen.value = true
  editingAssignmentId.value = assignment?.id ?? ''
  if (assignment) {
    assignmentForm.workerId = assignment.workerId
    assignmentForm.workRole = assignment.workRole
    assignmentForm.dailyRate = assignment.dailyRate
    return
  }

  assignmentForm.workerId = availableWorkers.value[0]?.id ?? ''
  assignmentForm.workRole = 'painter'
  assignmentForm.dailyRate = 0
  applyWorkerDefaults()
}

function closeAssignmentEditor() {
  editorOpen.value = false
  editingAssignmentId.value = ''
}

function saveAssignment() {
  if (!site.value || !assignmentForm.workerId || assignmentForm.dailyRate < 0) return
  store.upsertSiteWorkerAssignment({
    siteId: site.value.id,
    workerId: assignmentForm.workerId,
    workRole: assignmentForm.workRole,
    dailyRate: Number(assignmentForm.dailyRate) || 0,
  })
  closeAssignmentEditor()
}

function removeAssignment(assignment: SiteWorkerAssignment) {
  const worker = store.workers.find((candidate) => candidate.id === assignment.workerId)
  if (!window.confirm(`${worker?.name ?? '근로자'}의 현장 배정을 해제하시겠습니까?`)) return
  store.removeSiteWorkerAssignment(assignment.id)
  if (editingAssignmentId.value === assignment.id) closeAssignmentEditor()
}
</script>

<template>
  <template v-if="site">
    <section class="page-heading">
      <div>
        <RouterLink class="back-link" to="/sites"><ArrowLeft :size="15" /> 현장 목록</RouterLink>
        <h1>{{ site.name }}</h1>
        <p>{{ site.address || '주소 없음' }}</p>
      </div>
      <RouterLink
        class="button button-primary"
        :to="{ path: '/attendance', query: { site: site.id } }"
      >
        <ClipboardCheck :size="18" /> 출석 입력
      </RouterLink>
    </section>

    <section class="detail-meta" aria-label="현장 기본 정보">
      <dl>
        <div><dt>발주처</dt><dd>{{ site.client || '-' }}</dd></div>
        <div>
          <dt>공사 기간</dt>
          <dd>{{ formatDate(site.startDate) }} - {{ formatDate(site.endDate) }}</dd>
        </div>
        <div><dt>상태</dt><dd>{{ siteStatusLabels[site.status] }}</dd></div>
      </dl>
    </section>

    <section class="metric-grid detail-metrics" aria-label="현장 인력 요약">
      <article class="metric-item">
        <span class="metric-icon green"><Users :size="20" /></span>
        <div><small>현재 배정 인원</small><strong>{{ assignments.length }}</strong></div>
      </article>
      <article class="metric-item">
        <span class="metric-icon blue"><BriefcaseBusiness :size="20" /></span>
        <div><small>배정 도장공</small><strong>{{ painterCount }}</strong></div>
      </article>
      <article class="metric-item">
        <span class="metric-icon amber"><CalendarDays :size="20" /></span>
        <div><small>누적 작업일</small><strong>{{ totalWorkedDays }}</strong></div>
      </article>
      <article class="metric-item">
        <span class="metric-icon red"><ClipboardCheck :size="20" /></span>
        <div>
          <small>누적 인건비</small
          ><strong class="money-value">{{ formatCurrency(totalLaborCost) }}</strong>
        </div>
      </article>
    </section>

    <section class="content-section table-section detail-section">
      <div class="section-heading">
        <div><h2>현장 근로자 배정</h2><p>현장에서 적용할 직책과 일급</p></div>
        <button
          class="button button-secondary"
          type="button"
          :disabled="editorOpen || !availableWorkers.length"
          @click="openAssignmentEditor()"
        >
          <Plus :size="17" /> 근로자 배정
        </button>
      </div>

      <form v-if="editorOpen" class="assignment-editor" @submit.prevent="saveAssignment">
        <div class="form-grid assignment-form-grid">
          <label>
            <span>근로자</span>
            <select
              v-model="assignmentForm.workerId"
              required
              :disabled="Boolean(editingAssignmentId)"
              @change="applyWorkerDefaults"
            >
              <option value="" disabled>근로자 선택</option>
              <option
                v-for="worker in editingAssignmentId
                  ? store.workers.filter((item) => item.id === assignmentForm.workerId)
                  : availableWorkers"
                :key="worker.id"
                :value="worker.id"
              >
                {{ worker.name }} · {{ worker.team || '소속 없음' }}
              </option>
            </select>
          </label>
          <label>
            <span>현장 직책</span>
            <select v-model="assignmentForm.workRole">
              <option v-for="option in workerRoleOptions" :key="option.value" :value="option.value">
                {{ option.label }}
              </option>
            </select>
          </label>
          <label>
            <span>현장 일급</span>
            <input
              v-model.number="assignmentForm.dailyRate"
              type="number"
              min="0"
              step="1000"
              required
            />
          </label>
        </div>
        <div class="form-actions">
          <button class="button button-ghost" type="button" @click="closeAssignmentEditor">
            <X :size="17" /> 취소
          </button>
          <button class="button button-primary" type="submit" :disabled="!assignmentForm.workerId">
            {{ editingAssignmentId ? '배정 수정' : '배정 저장' }}
          </button>
        </div>
      </form>

      <div v-if="assignmentRows.length" class="data-table-wrap">
        <table class="data-table management-table">
          <thead>
            <tr>
              <th>근로자</th><th>현장 직책</th><th>현장 일급</th><th>누적 작업일</th
              ><th>누적 인건비</th><th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in assignmentRows" :key="item.assignment.id">
              <td data-label="근로자">
                <strong>{{ item.worker.name }}</strong
                ><small>{{ item.worker.team || '미지정' }}</small>
              </td>
              <td data-label="현장 직책">{{ workerRoleLabels[item.assignment.workRole] }}</td>
              <td data-label="현장 일급">{{ formatCurrency(item.assignment.dailyRate) }}</td>
              <td data-label="누적 작업일">{{ item.workedDays }}일</td>
              <td data-label="누적 인건비">{{ formatCurrency(item.laborCost) }}</td>
              <td class="table-actions-cell" data-label="관리">
                <div class="table-actions">
                  <button
                    class="icon-button"
                    type="button"
                    title="배정 수정"
                    @click="openAssignmentEditor(item.assignment)"
                  ><Pencil :size="16" /></button>
                  <button
                    class="icon-button danger-button"
                    type="button"
                    title="배정 해제"
                    @click="removeAssignment(item.assignment)"
                  ><Trash2 :size="16" /></button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-else-if="!editorOpen" class="empty-state">
        <Users :size="28" /><strong>배정된 근로자가 없습니다</strong>
      </div>
    </section>

    <section class="content-section table-section detail-section">
      <div class="section-heading">
        <div><h2>최근 출석 기록</h2><p>현장에 저장된 작업 이력</p></div>
      </div>
      <div v-if="records.length" class="data-table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>날짜</th><th>근로자</th><th>작업 직책</th><th>상태</th><th>시간</th
              ><th>적용 일급</th><th>인건비</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="record in records.slice(0, 30)" :key="record.id">
              <td>{{ formatDate(record.date) }}</td>
              <td>
                {{ store.workers.find((worker) => worker.id === record.workerId)?.name || '삭제된 근로자' }}
              </td>
              <td>{{ workerRoleLabels[record.workRole] }}</td>
              <td>{{ attendanceStatusLabels[record.status] }}</td>
              <td>{{ record.startTime || '-' }} - {{ record.endTime || '-' }}</td>
              <td>{{ formatCurrency(record.dailyRate) }}</td>
              <td>{{ formatCurrency(sumLaborCost([record])) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-else class="empty-state">
        <ClipboardCheck :size="28" /><strong>출석 기록이 없습니다</strong>
      </div>
    </section>
  </template>

  <section v-else class="content-section empty-state detail-not-found">
    <strong>현장을 찾을 수 없습니다</strong>
    <RouterLink class="button button-secondary" to="/sites">현장 목록으로</RouterLink>
  </section>
</template>
