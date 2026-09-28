<script setup lang="ts">
import { computed } from 'vue'
import { ArrowLeft, BriefcaseBusiness, CalendarDays, ClipboardCheck, Users } from '@lucide/vue'
import { useRoute } from 'vue-router'

import { calculateWorkedDays, sumLaborCost } from '@/services/attendanceService'
import { useErpStore } from '@/stores/erp'
import { attendanceStatusLabels, siteStatusLabels, workerRoleLabels } from '@/utils/erpLabels'
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

const crew = computed(() => {
  const workerIds = [...new Set(workedRecords.value.map((record) => record.workerId))]

  return workerIds
    .map((workerId) => {
      const worker = store.workers.find((candidate) => candidate.id === workerId)
      const workerRecords = workedRecords.value.filter((record) => record.workerId === workerId)
      const latestRecord = workerRecords[0]
      if (!worker || !latestRecord) return undefined

      return {
        worker,
        latestRole: latestRecord.workRole,
        lastDate: latestRecord.date,
        workedDays: calculateWorkedDays(workerRecords),
        laborCost: sumLaborCost(workerRecords),
      }
    })
    .filter((item) => item !== undefined)
})

const painterCount = computed(
  () => crew.value.filter((item) => item.latestRole === 'painter').length,
)
const totalWorkedDays = computed(() => calculateWorkedDays(workedRecords.value))
const totalLaborCost = computed(() => sumLaborCost(records.value))
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
        <div>
          <dt>발주처</dt>
          <dd>{{ site.client || '-' }}</dd>
        </div>
        <div>
          <dt>공사 기간</dt>
          <dd>{{ formatDate(site.startDate) }} - {{ formatDate(site.endDate) }}</dd>
        </div>
        <div>
          <dt>상태</dt>
          <dd>{{ siteStatusLabels[site.status] }}</dd>
        </div>
      </dl>
    </section>

    <section class="metric-grid detail-metrics" aria-label="현장 인력 요약">
      <article class="metric-item">
        <span class="metric-icon green"><Users :size="20" /></span>
        <div>
          <small>누적 투입 인원</small><strong>{{ crew.length }}</strong>
        </div>
      </article>
      <article class="metric-item">
        <span class="metric-icon blue"><BriefcaseBusiness :size="20" /></span>
        <div>
          <small>도장공</small><strong>{{ painterCount }}</strong>
        </div>
      </article>
      <article class="metric-item">
        <span class="metric-icon amber"><CalendarDays :size="20" /></span>
        <div>
          <small>누적 작업일</small><strong>{{ totalWorkedDays }}</strong>
        </div>
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
        <div>
          <h2>투입 근로자</h2>
          <p>최근 작업 직책 기준</p>
        </div>
      </div>
      <div v-if="crew.length" class="data-table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>근로자</th>
              <th>최근 직책</th>
              <th>작업일</th>
              <th>최근 작업</th>
              <th>인건비</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in crew" :key="item.worker.id">
              <td>
                <strong>{{ item.worker.name }}</strong
                ><small>{{ item.worker.team || '미지정' }}</small>
              </td>
              <td>{{ workerRoleLabels[item.latestRole] }}</td>
              <td>{{ item.workedDays }}일</td>
              <td>{{ formatDate(item.lastDate) }}</td>
              <td>{{ formatCurrency(item.laborCost) }}</td>
              <td class="table-action-cell">
                <RouterLink class="text-link" :to="`/workers/${item.worker.id}`"
                  >이력 보기</RouterLink
                >
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-else class="empty-state">
        <Users :size="28" /><strong>투입된 근로자 기록이 없습니다</strong>
      </div>
    </section>

    <section class="content-section table-section detail-section">
      <div class="section-heading">
        <div>
          <h2>최근 출석 기록</h2>
          <p>현장에 저장된 작업 이력</p>
        </div>
      </div>
      <div v-if="records.length" class="data-table-wrap">
        <table class="data-table">
          <thead>
            <tr>
              <th>날짜</th>
              <th>근로자</th>
              <th>작업 직책</th>
              <th>상태</th>
              <th>시간</th>
              <th>인건비</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="record in records.slice(0, 30)" :key="record.id">
              <td>{{ formatDate(record.date) }}</td>
              <td>
                {{
                  store.workers.find((worker) => worker.id === record.workerId)?.name ||
                  '삭제된 근로자'
                }}
              </td>
              <td>{{ workerRoleLabels[record.workRole] }}</td>
              <td>{{ attendanceStatusLabels[record.status] }}</td>
              <td>{{ record.startTime || '-' }} - {{ record.endTime || '-' }}</td>
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
