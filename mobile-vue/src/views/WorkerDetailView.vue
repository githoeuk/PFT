<script setup lang="ts">
import { computed } from 'vue'
import {
  ArrowLeft,
  BriefcaseBusiness,
  CalendarDays,
  CircleDollarSign,
  MapPinned,
} from '@lucide/vue'
import { useRoute } from 'vue-router'

import { calculateWorkedDays, sumLaborCost } from '@/services/attendanceService'
import { useErpStore } from '@/stores/erp'
import { attendanceStatusLabels, workerRoleLabels } from '@/utils/erpLabels'
import { formatCurrency, formatDate } from '@/utils/formatters'

const route = useRoute()
const store = useErpStore()

const workerId = computed(() => String(route.params.workerId ?? ''))
const worker = computed(() => store.workers.find((candidate) => candidate.id === workerId.value))
const records = computed(() =>
  store.attendanceRecords
    .filter((record) => record.workerId === workerId.value)
    .sort((left, right) => right.date.localeCompare(left.date)),
)
const workedRecords = computed(() =>
  records.value.filter((record) => record.status === 'present' || record.status === 'half_day'),
)
const workedDays = computed(() => calculateWorkedDays(records.value))
const siteCount = computed(() => new Set(workedRecords.value.map((record) => record.siteId)).size)
const totalLaborCost = computed(() => sumLaborCost(records.value))
const lastWorkDate = computed(() => workedRecords.value[0]?.date ?? '')

const siteHistory = computed(() => {
  const siteIds = [...new Set(workedRecords.value.map((record) => record.siteId))]

  return siteIds
    .map((siteId) => {
      const site = store.sites.find((candidate) => candidate.id === siteId)
      const siteRecords = workedRecords.value.filter((record) => record.siteId === siteId)
      const latestRecord = siteRecords[0]
      if (!site || !latestRecord) return undefined

      return {
        site,
        latestRole: latestRecord.workRole,
        lastDate: latestRecord.date,
        workedDays: calculateWorkedDays(siteRecords),
        laborCost: sumLaborCost(siteRecords),
      }
    })
    .filter((item) => item !== undefined)
})
</script>

<template>
  <template v-if="worker">
    <section class="page-heading">
      <div>
        <RouterLink class="back-link" to="/workers"
          ><ArrowLeft :size="15" /> 근로자 목록</RouterLink
        >
        <h1>{{ worker.name }}</h1>
        <p>{{ worker.team || '소속 팀 미지정' }}</p>
      </div>
      <span class="record-state" :class="{ active: worker.active }">{{
        worker.active ? '활동' : '비활동'
      }}</span>
    </section>

    <section class="detail-meta" aria-label="근로자 기본 정보">
      <dl>
        <div>
          <dt>기본 직책</dt>
          <dd>{{ workerRoleLabels[worker.role] }}</dd>
        </div>
        <div>
          <dt>연락처</dt>
          <dd>{{ worker.phone || '연락처 없음' }}</dd>
        </div>
        <div>
          <dt>현재 일당</dt>
          <dd>{{ formatCurrency(worker.dailyRate) }}</dd>
        </div>
      </dl>
    </section>

    <section class="metric-grid detail-metrics" aria-label="근로자 작업 요약">
      <article class="metric-item">
        <span class="metric-icon green"><CalendarDays :size="20" /></span>
        <div>
          <small>누적 작업일</small><strong>{{ workedDays }}</strong>
        </div>
      </article>
      <article class="metric-item">
        <span class="metric-icon blue"><MapPinned :size="20" /></span>
        <div>
          <small>작업 현장</small><strong>{{ siteCount }}</strong>
        </div>
      </article>
      <article class="metric-item">
        <span class="metric-icon amber"><BriefcaseBusiness :size="20" /></span>
        <div>
          <small>최근 작업일</small
          ><strong class="metric-date">{{ formatDate(lastWorkDate) }}</strong>
        </div>
      </article>
      <article class="metric-item">
        <span class="metric-icon red"><CircleDollarSign :size="20" /></span>
        <div>
          <small>누적 인건비</small
          ><strong class="money-value">{{ formatCurrency(totalLaborCost) }}</strong>
        </div>
      </article>
    </section>

    <section class="content-section table-section detail-section">
      <div class="section-heading">
        <div>
          <h2>현장별 작업 이력</h2>
          <p>실제 출석 기록 기준</p>
        </div>
      </div>
      <div v-if="siteHistory.length" class="data-table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>현장</th>
              <th>최근 직책</th>
              <th>작업일</th>
              <th>최근 작업</th>
              <th>인건비</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in siteHistory" :key="item.site.id">
              <td>
                <strong>{{ item.site.name }}</strong
                ><small>{{ item.site.address || '주소 없음' }}</small>
              </td>
              <td>{{ workerRoleLabels[item.latestRole] }}</td>
              <td>{{ item.workedDays }}일</td>
              <td>{{ formatDate(item.lastDate) }}</td>
              <td>{{ formatCurrency(item.laborCost) }}</td>
              <td class="table-action-cell">
                <RouterLink class="text-link" :to="`/sites/${item.site.id}`">현장 보기</RouterLink>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-else class="empty-state">
        <MapPinned :size="28" /><strong>작업한 현장 기록이 없습니다</strong>
      </div>
    </section>

    <section class="content-section table-section detail-section">
      <div class="section-heading">
        <div>
          <h2>전체 작업 기록</h2>
          <p>날짜별 직책과 출석 내역</p>
        </div>
      </div>
      <div v-if="records.length" class="data-table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>날짜</th>
              <th>현장</th>
              <th>작업 직책</th>
              <th>상태</th>
              <th>시간</th>
              <th>연장</th>
              <th>인건비</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="record in records" :key="record.id">
              <td>{{ formatDate(record.date) }}</td>
              <td>
                {{ store.sites.find((site) => site.id === record.siteId)?.name || '삭제된 현장' }}
              </td>
              <td>{{ workerRoleLabels[record.workRole] }}</td>
              <td>{{ attendanceStatusLabels[record.status] }}</td>
              <td>{{ record.startTime || '-' }} - {{ record.endTime || '-' }}</td>
              <td>{{ record.overtimeHours }}시간</td>
              <td>{{ formatCurrency(sumLaborCost([record])) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-else class="empty-state">
        <CalendarDays :size="28" /><strong>작업 기록이 없습니다</strong>
      </div>
    </section>
  </template>

  <section v-else class="content-section empty-state detail-not-found">
    <strong>근로자를 찾을 수 없습니다</strong>
    <RouterLink class="button button-secondary" to="/workers">근로자 목록으로</RouterLink>
  </section>
</template>
