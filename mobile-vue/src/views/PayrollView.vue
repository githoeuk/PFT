<script setup lang="ts">
import { computed, ref } from 'vue'
import {
  CalendarDays,
  CircleDollarSign,
  ClipboardCheck,
  Users,
} from '@lucide/vue'

import { calculateWorkedDays, sumLaborCost } from '@/services/attendanceService'
import { useErpStore } from '@/stores/erp'
import { formatCurrency, todayIso } from '@/utils/formatters'

const store = useErpStore()

const selectedMonth = ref(todayIso().slice(0, 7))

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
</template>
