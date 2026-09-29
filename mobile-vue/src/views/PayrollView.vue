<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  CalendarDays,
  CircleDollarSign,
  ClipboardCheck,
  Users,
  ChevronDown,
  ChevronUp,
} from '@lucide/vue'
import { calculateWorkedDays, sumLaborCost } from '@/services/attendanceService'
import { useErpStore } from '@/stores/erp'
import { formatCurrency, todayIso } from '@/utils/formatters'
import type { AttendanceRecord } from '@/types/erp'
import { workerRoleLabels } from '@/utils/erpLabels'

const store = useErpStore()

const selectedMonth = ref(todayIso().slice(0, 7))

const expandedWorkerIds = ref<string[]>([])

const isWorkerExpanded = (workerId: string): boolean =>
  expandedWorkerIds.value.includes(workerId)

const toggleWorkerDetails = (workerId: string) => {
  expandedWorkerIds.value = isWorkerExpanded(workerId)
    ? expandedWorkerIds.value.filter((id) => id !== workerId)
    : [...expandedWorkerIds.value, workerId]
}

const monthRecords = computed(() => {
  if (!selectedMonth.value) {
    return []
  }

  return store.attendanceRecords.filter((record) =>
    record.date.startsWith(selectedMonth.value),
  )
})

const workedRecords = computed(() =>
  monthRecords.value.filter(
    (record) =>
      record.status === 'present' || record.status === 'half_day',
  ),
)

const workerCount = computed(
  () => new Set(workedRecords.value.map((record) => record.workerId)).size,
)

const workedDays = computed(() =>
  calculateWorkedDays(workedRecords.value),
)

const totalLaborCost = computed(() =>
  sumLaborCost(monthRecords.value),
)
const payrollRows = computed(() => {
  const recordsByWorker = new Map<string, AttendanceRecord[]>()

  for (const record of workedRecords.value) {
    const records = recordsByWorker.get(record.workerId) ?? []
    records.push(record)
    recordsByWorker.set(record.workerId, records)
  }

  return Array.from(recordsByWorker.entries())
    .map(([workerId, records]) => {
      const worker = store.workers.find(
        (candidate) => candidate.id === workerId,
      )

      const recordsBySite = new Map<string, AttendanceRecord[]>()

      for (const record of records) {
        const siteRecords = recordsBySite.get(record.siteId) ?? []
        siteRecords.push(record)
        recordsBySite.set(record.siteId, siteRecords)
      }

      const siteRows = Array.from(recordsBySite.entries())
        .map(([siteId, siteRecords]) => {
          const site = store.sites.find(
            (candidate) => candidate.id === siteId,
          )
          const siteDailyRates = siteRecords.map(
            (record) => record.dailyRate,
          )
          const minimumSiteRate = Math.min(...siteDailyRates)
          const maximumSiteRate = Math.max(...siteDailyRates)

          return {
            siteId,
            siteExists: Boolean(site),
            siteName: site?.name ?? '삭제된 현장',
            roles: [
              ...new Set(
                siteRecords.map(
                  (record) => workerRoleLabels[record.workRole],
                ),
              ),
            ].join(', '),
            workedDays: calculateWorkedDays(siteRecords),
            overtimeHours: siteRecords.reduce(
              (total, record) => total + record.overtimeHours,
              0,
            ),
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
              store.sites.find((site) => site.id === record.siteId)?.name ??
              '삭제된 현장',
          ),
        ),
      ]

      const roles = [
        ...new Set(
          records.map((record) => workerRoleLabels[record.workRole]),
        ),
      ]

      const dailyRates = records.map((record) => record.dailyRate)
      const minimumDailyRate = Math.min(...dailyRates)
      const maximumDailyRate = Math.max(...dailyRates)

      return {
        workerId,
        workerExists: Boolean(worker),
        workerName: worker?.name ?? '삭제된 근로자',
        team: worker?.team || '미지정',
        siteNames: siteNames.join(', '),
        roles: roles.join(', '),
        workedDays: calculateWorkedDays(records),
        overtimeHours: records.reduce(
          (total, record) => total + record.overtimeHours,
          0,
        ),
        dailyRateText:
          minimumDailyRate === maximumDailyRate
            ? formatCurrency(minimumDailyRate)
            : `${formatCurrency(minimumDailyRate)} ~ ${formatCurrency(maximumDailyRate)}`,
        laborCost: sumLaborCost(records),
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
          <th aria-label="현장별 정산 보기"></th>
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
            </td>
            <td class="table-action-cell">
              <button
                class="icon-button"
                type="button"
                :title="
            isWorkerExpanded(row.workerId)
              ? '현장별 정산 접기'
              : '현장별 정산 펼치기'
          "
                :aria-expanded="isWorkerExpanded(row.workerId)"
                @click="toggleWorkerDetails(row.workerId)"
              >
                <ChevronUp
                  v-if="isWorkerExpanded(row.workerId)"
                  :size="17"
                />
                <ChevronDown v-else :size="17" />
              </button>
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
              <RouterLink
                v-if="site.siteExists"
                class="text-link"
                :to="`/sites/${site.siteId}`"
              >
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
