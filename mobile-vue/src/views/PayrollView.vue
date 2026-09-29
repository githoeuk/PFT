<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import {
  CalendarDays,
  ChevronDown,
  ChevronUp,
  CircleCheck,
  CircleDollarSign,
  ClipboardCheck,
  Pencil,
  Save,
  Users,
  X,
} from '@lucide/vue'

import { calculateWorkedDays, sumLaborCost } from '@/services/attendanceService'
import {
  hasPayrollAmountMismatch,
  validatePayrollSettlement,
} from '@/services/payrollSettlementService'
import { useErpStore } from '@/stores/erp'
import type { AttendanceRecord, PayrollSettlementStatus } from '@/types/erp'
import { payrollSettlementStatusLabels, workerRoleLabels } from '@/utils/erpLabels'
import { formatCurrency, todayIso } from '@/utils/formatters'

interface SettlementForm {
  status: PayrollSettlementStatus
  paidDate: string
  note: string
}

const store = useErpStore()

const selectedMonth = ref(todayIso().slice(0, 7))
const expandedWorkerIds = ref<string[]>([])
const editingWorkerId = ref('')
const settlementError = ref('')
const settlementMessage = ref('')
const settlementForm = ref<SettlementForm>({
  status: 'unpaid',
  paidDate: todayIso(),
  note: '',
})

const isWorkerExpanded = (workerId: string): boolean => expandedWorkerIds.value.includes(workerId)

const toggleWorkerDetails = (workerId: string) => {
  expandedWorkerIds.value = isWorkerExpanded(workerId)
    ? expandedWorkerIds.value.filter((id) => id !== workerId)
    : [...expandedWorkerIds.value, workerId]
}

const closeSettlementEditor = () => {
  editingWorkerId.value = ''
  settlementError.value = ''
}

const openSettlementEditor = (workerId: string) => {
  if (editingWorkerId.value === workerId) {
    closeSettlementEditor()
    return
  }

  const settlement = store.payrollSettlementFor(selectedMonth.value, workerId)

  editingWorkerId.value = workerId
  settlementError.value = ''
  settlementMessage.value = ''
  settlementForm.value = {
    status: settlement?.status ?? 'unpaid',
    paidDate: settlement?.paidDate || todayIso(),
    note: settlement?.note ?? '',
  }
}

const savePayrollSettlement = (workerId: string, laborCost: number) => {
  if (!selectedMonth.value) {
    settlementError.value = '정산 월을 선택해야 합니다'
    return
  }

  const error = validatePayrollSettlement(
    settlementForm.value.status,
    settlementForm.value.paidDate,
  )

  if (error) {
    settlementError.value = error
    return
  }

  store.upsertPayrollSettlement({
    month: selectedMonth.value,
    workerId,
    status: settlementForm.value.status,
    settledAmount: laborCost,
    paidDate: settlementForm.value.status === 'paid' ? settlementForm.value.paidDate : '',
    note: settlementForm.value.note.trim(),
  })

  closeSettlementEditor()
  settlementMessage.value = '지급 정보를 저장했습니다'
}

watch(selectedMonth, () => {
  expandedWorkerIds.value = []
  editingWorkerId.value = ''
  settlementError.value = ''
  settlementMessage.value = ''
})

const monthRecords = computed(() => {
  if (!selectedMonth.value) {
    return []
  }

  return store.attendanceRecords.filter((record) => record.date.startsWith(selectedMonth.value))
})

const workedRecords = computed(() =>
  monthRecords.value.filter(
    (record) => record.status === 'present' || record.status === 'half_day',
  ),
)

const workerCount = computed(
  () => new Set(workedRecords.value.map((record) => record.workerId)).size,
)

const workedDays = computed(() => calculateWorkedDays(workedRecords.value))

const totalLaborCost = computed(() => sumLaborCost(monthRecords.value))
const payrollRows = computed(() => {
  const recordsByWorker = new Map<string, AttendanceRecord[]>()

  for (const record of workedRecords.value) {
    const records = recordsByWorker.get(record.workerId) ?? []
    records.push(record)
    recordsByWorker.set(record.workerId, records)
  }

  return Array.from(recordsByWorker.entries())
    .map(([workerId, records]) => {
      const worker = store.workers.find((candidate) => candidate.id === workerId)

      const settlement = store.payrollSettlementFor(selectedMonth.value, workerId)

      const recordsBySite = new Map<string, AttendanceRecord[]>()

      for (const record of records) {
        const siteRecords = recordsBySite.get(record.siteId) ?? []
        siteRecords.push(record)
        recordsBySite.set(record.siteId, siteRecords)
      }

      const siteRows = Array.from(recordsBySite.entries())
        .map(([siteId, siteRecords]) => {
          const site = store.sites.find((candidate) => candidate.id === siteId)
          const siteDailyRates = siteRecords.map((record) => record.dailyRate)
          const minimumSiteRate = Math.min(...siteDailyRates)
          const maximumSiteRate = Math.max(...siteDailyRates)

          return {
            siteId,
            siteExists: Boolean(site),
            siteName: site?.name ?? '삭제된 현장',
            roles: [
              ...new Set(siteRecords.map((record) => workerRoleLabels[record.workRole])),
            ].join(', '),
            workedDays: calculateWorkedDays(siteRecords),
            overtimeHours: siteRecords.reduce((total, record) => total + record.overtimeHours, 0),
            dailyRateText:
              minimumSiteRate === maximumSiteRate
                ? formatCurrency(minimumSiteRate)
                : `${formatCurrency(minimumSiteRate)} ~ ${formatCurrency(maximumSiteRate)}`,
            laborCost: sumLaborCost(siteRecords),
          }
        })
        .sort((a, b) => a.siteName.localeCompare(b.siteName, 'ko-KR'))

      const siteNames = [
        ...new Set(
          records.map(
            (record) =>
              store.sites.find((site) => site.id === record.siteId)?.name ?? '삭제된 현장',
          ),
        ),
      ]

      const roles = [...new Set(records.map((record) => workerRoleLabels[record.workRole]))]

      const dailyRates = records.map((record) => record.dailyRate)
      const minimumDailyRate = Math.min(...dailyRates)
      const maximumDailyRate = Math.max(...dailyRates)
      const laborCost = sumLaborCost(records)
      const settlementStatus = settlement?.status ?? 'unpaid'
      const settledAmount = settlement?.settledAmount ?? 0

      return {
        workerId,
        workerExists: Boolean(worker),
        workerName: worker?.name ?? '삭제된 근로자',
        team: worker?.team || '미지정',
        siteNames: siteNames.join(', '),
        roles: roles.join(', '),
        workedDays: calculateWorkedDays(records),
        overtimeHours: records.reduce((total, record) => total + record.overtimeHours, 0),
        dailyRateText:
          minimumDailyRate === maximumDailyRate
            ? formatCurrency(minimumDailyRate)
            : `${formatCurrency(minimumDailyRate)} ~ ${formatCurrency(maximumDailyRate)}`,
        laborCost,
        settlementStatus,
        settledAmount,
        paidDate: settlement?.paidDate ?? '',
        settlementNote: settlement?.note ?? '',
        amountMismatch: hasPayrollAmountMismatch(settlementStatus, settledAmount, laborCost),
        siteRows,
      }
    })
    .sort((a, b) => a.workerName.localeCompare(b.workerName, 'ko-KR'))
})
</script>

<template>
  <section class="page-heading">
    <div>
      <p class="eyebrow">월별 정산</p>
      <h1>인건비 정산</h1>
      <p>근로자별 작업일과 지급 금액을 확인합니다</p>
    </div>
  </section>

  <section class="attendance-toolbar">
    <label>
      <span>정산 월</span>
      <input v-model="selectedMonth" type="month" />
    </label>
  </section>

  <section class="metric-grid">
    <article class="metric-item">
      <span class="metric-icon green">
        <ClipboardCheck :size="20" />
      </span>
      <div>
        <small>출석 기록</small>
        <strong>{{ monthRecords.length }}</strong>
      </div>
    </article>

    <article class="metric-item">
      <span class="metric-icon blue">
        <Users :size="20" />
      </span>
      <div>
        <small>작업 근로자</small>
        <strong>{{ workerCount }}</strong>
      </div>
    </article>

    <article class="metric-item">
      <span class="metric-icon amber">
        <CalendarDays :size="20" />
      </span>
      <div>
        <small>총 작업일</small>
        <strong>{{ workedDays }}</strong>
      </div>
    </article>

    <article class="metric-item">
      <span class="metric-icon red">
        <CircleDollarSign :size="20" />
      </span>
      <div>
        <small>총 인건비</small>
        <strong class="money-value">
          {{ formatCurrency(totalLaborCost) }}
        </strong>
      </div>
    </article>
  </section>

  <section class="content-section table-section">
    <div class="section-heading">
      <div>
        <h2>근로자별 정산</h2>
        <p>{{ selectedMonth || '선택된 월 없음' }} 출석 기록 기준</p>
      </div>
      <span v-if="settlementMessage" class="save-message">
        <CircleCheck :size="16" />
        {{ settlementMessage }}
      </span>
    </div>

    <div v-if="payrollRows.length" class="data-table-wrap">
      <table class="data-table">
        <thead>
          <tr>
            <th>근로자</th>
            <th>작업 현장</th>
            <th>작업 직책</th>
            <th>작업일</th>
            <th>연장시간</th>
            <th>적용 일급</th>
            <th>지급액</th>
            <th>지급 상태</th>
            <th aria-label="정산 관리"></th>
          </tr>
        </thead>

        <tbody>
          <template v-for="row in payrollRows" :key="row.workerId">
            <tr>
              <td>
                <RouterLink
                  v-if="row.workerExists"
                  class="text-link"
                  :to="`/workers/${row.workerId}`"
                >
                  {{ row.workerName }}
                </RouterLink>
                <strong v-else>{{ row.workerName }}</strong>
                <small>{{ row.team }}</small>
              </td>
              <td>{{ row.siteNames }}</td>
              <td>{{ row.roles }}</td>
              <td>{{ row.workedDays }}일</td>
              <td>{{ row.overtimeHours }}시간</td>
              <td>{{ row.dailyRateText }}</td>
              <td>
                <strong>{{ formatCurrency(row.laborCost) }}</strong>
                <small v-if="row.amountMismatch" class="payroll-warning">
                  지급 후 계산 금액 변경됨
                </small>
              </td>
              <td>
                <span class="payroll-status" :class="{ paid: row.settlementStatus === 'paid' }">
                  {{ payrollSettlementStatusLabels[row.settlementStatus] }}
                </span>
                <small v-if="row.settlementStatus === 'paid'">
                  {{ row.paidDate }} ·
                  {{ formatCurrency(row.settledAmount) }}
                </small>
                <small v-if="row.settlementNote" class="payroll-note">
                  {{ row.settlementNote }}
                </small>
              </td>
              <td class="table-actions-cell">
                <div class="table-actions">
                  <button
                    class="icon-button"
                    :class="{
                      'active-icon-button': editingWorkerId === row.workerId,
                    }"
                    type="button"
                    title="지급 정보 수정"
                    @click="openSettlementEditor(row.workerId)"
                  >
                    <Pencil :size="16" />
                  </button>
                  <button
                    class="icon-button"
                    type="button"
                    :title="
                      isWorkerExpanded(row.workerId) ? '현장별 정산 접기' : '현장별 정산 펼치기'
                    "
                    :aria-expanded="isWorkerExpanded(row.workerId)"
                    @click="toggleWorkerDetails(row.workerId)"
                  >
                    <ChevronUp v-if="isWorkerExpanded(row.workerId)" :size="17" />
                    <ChevronDown v-else :size="17" />
                  </button>
                </div>
              </td>
            </tr>

            <tr v-if="editingWorkerId === row.workerId" class="payroll-editor-row">
              <td colspan="9">
                <form
                  class="payroll-editor"
                  @submit.prevent="savePayrollSettlement(row.workerId, row.laborCost)"
                >
                  <div class="payroll-editor-heading">
                    <div>
                      <strong>{{ row.workerName }} 지급 관리</strong>
                      <small> 현재 계산 금액 {{ formatCurrency(row.laborCost) }} </small>
                    </div>
                  </div>

                  <div class="payroll-editor-fields">
                    <label>
                      <span>지급 상태</span>
                      <select v-model="settlementForm.status">
                        <option value="unpaid">미지급</option>
                        <option value="paid">지급 완료</option>
                      </select>
                    </label>

                    <label v-if="settlementForm.status === 'paid'">
                      <span>지급일</span>
                      <input v-model="settlementForm.paidDate" type="date" required />
                    </label>

                    <label class="payroll-editor-note">
                      <span>지급 메모</span>
                      <input
                        v-model="settlementForm.note"
                        type="text"
                        maxlength="120"
                        placeholder="계좌 이체, 현금 지급 등"
                      />
                    </label>

                    <div class="payroll-editor-actions">
                      <button
                        class="button button-secondary"
                        type="button"
                        @click="closeSettlementEditor"
                      >
                        <X :size="15" />
                        취소
                      </button>
                      <button class="button button-primary" type="submit">
                        <Save :size="15" />
                        저장
                      </button>
                    </div>
                  </div>

                  <p v-if="settlementError" class="payroll-form-error">
                    {{ settlementError }}
                  </p>
                </form>
              </td>
            </tr>

            <tr
              v-for="site in row.siteRows"
              v-show="isWorkerExpanded(row.workerId)"
              :key="`${row.workerId}-${site.siteId}`"
              class="payroll-site-row"
            >
              <td><small>현장별 내역</small></td>
              <td>
                <RouterLink v-if="site.siteExists" class="text-link" :to="`/sites/${site.siteId}`">
                  {{ site.siteName }}
                </RouterLink>
                <strong v-else>{{ site.siteName }}</strong>
              </td>
              <td>{{ site.roles }}</td>
              <td>{{ site.workedDays }}일</td>
              <td>{{ site.overtimeHours }}시간</td>
              <td>{{ site.dailyRateText }}</td>
              <td>{{ formatCurrency(site.laborCost) }}</td>
              <td></td>
              <td></td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>

    <div v-else class="empty-state">
      <Users :size="28" />
      <strong>선택한 월의 작업 기록이 없습니다</strong>
    </div>
  </section>
</template>
