<script setup lang="ts">
import { computed } from 'vue'
import { CalendarDays, CircleDollarSign, ClipboardCheck, MapPinned, Users } from '@lucide/vue'

import { sumLaborCost } from '@/services/attendanceService'
import { useErpStore } from '@/stores/erp'
import { formatCurrency, formatDate, todayIso } from '@/utils/formatters'

const store = useErpStore()
const today = todayIso()

const presentToday = computed(
  () => store.todayRecords.filter((record) => record.status === 'present').length,
)
const todaysLaborCost = computed(() => sumLaborCost(store.todayRecords))
</script>

<template>
  <section class="page-heading">
    <div>
      <p class="eyebrow">현황</p>
      <h1>대시보드</h1>
      <p>{{ formatDate(today) }}</p>
    </div>
    <RouterLink class="button button-primary" to="/attendance">
      <ClipboardCheck :size="18" />
      출석 입력
    </RouterLink>
  </section>

  <section class="metric-grid" aria-label="주요 지표">
    <article class="metric-item">
      <span class="metric-icon green"><MapPinned :size="20" /></span>
      <div>
        <small>진행 현장</small><strong>{{ store.activeSites.length }}</strong>
      </div>
    </article>
    <article class="metric-item">
      <span class="metric-icon blue"><Users :size="20" /></span>
      <div>
        <small>활동 인원</small><strong>{{ store.activeWorkers.length }}</strong>
      </div>
    </article>
    <article class="metric-item">
      <span class="metric-icon amber"><CalendarDays :size="20" /></span>
      <div>
        <small>오늘 출근</small><strong>{{ presentToday }}</strong>
      </div>
    </article>
    <article class="metric-item">
      <span class="metric-icon red"><CircleDollarSign :size="20" /></span>
      <div>
        <small>이번 달 인건비</small>
        <strong class="money-value">{{ formatCurrency(store.currentMonthLaborCost) }}</strong>
      </div>
    </article>
  </section>

  <section class="dashboard-grid">
    <div class="content-section">
      <div class="section-heading">
        <div>
          <h2>진행 중인 현장</h2>
          <p>현재 진행 중인 외벽 도장 공사</p>
        </div>
        <RouterLink class="text-link" to="/sites">전체 보기</RouterLink>
      </div>

      <div v-if="store.activeSites.length" class="site-list">
        <article v-for="site in store.activeSites.slice(0, 5)" :key="site.id" class="site-row">
          <span class="site-initial">{{ site.name.slice(0, 1).toUpperCase() }}</span>
          <div class="site-main">
            <strong>{{ site.name }}</strong
            ><small>{{ site.address || '주소 없음' }}</small>
          </div>
          <div class="site-client">
            <small>발주처</small><span>{{ site.client || '-' }}</span>
          </div>
          <div class="site-date">
            <small>종료일</small><span>{{ formatDate(site.endDate) }}</span>
          </div>
        </article>
      </div>
      <div v-else class="empty-state">
        <MapPinned :size="28" />
        <strong>진행 중인 현장이 없습니다</strong>
        <RouterLink class="button button-secondary" to="/sites">첫 현장 등록</RouterLink>
      </div>
    </div>

    <aside class="content-section daily-summary">
      <div class="section-heading">
        <div>
          <h2>오늘</h2>
          <p>출석 요약</p>
        </div>
      </div>
      <dl>
        <div>
          <dt>기록</dt>
          <dd>{{ store.todayRecords.length }}</dd>
        </div>
        <div>
          <dt>출근</dt>
          <dd>{{ presentToday }}</dd>
        </div>
        <div>
          <dt>예상 인건비</dt>
          <dd>{{ formatCurrency(todaysLaborCost) }}</dd>
        </div>
      </dl>
      <RouterLink class="button button-secondary button-full" to="/attendance">
        출석 관리 열기
      </RouterLink>
    </aside>
  </section>
</template>
