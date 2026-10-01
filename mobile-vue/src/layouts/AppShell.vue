<script setup lang="ts">
import { useErpStore } from '@/stores/erp'

import {
  CircleDollarSign,
  ClipboardCheck,
  Database,
  DatabaseBackup,
  HardHat,
  LayoutDashboard,
  MapPinned,
  Users,
} from '@lucide/vue'

const store = useErpStore()

const navigation = [
  { to: '/', label: '대시보드', icon: LayoutDashboard },
  { to: '/attendance', label: '출석 관리', icon: ClipboardCheck },
  { to: '/sites', label: '현장 관리', icon: MapPinned },
  { to: '/workers', label: '근로자 관리', icon: Users },
  { to: '/payroll', label: '정산 관리', icon: CircleDollarSign },
  { to: '/data', label: '데이터 관리', icon: DatabaseBackup },
]
</script>

<template>
  <div class="app-shell">
    <aside class="sidebar">
      <div class="brand">
        <span class="brand-mark"><HardHat :size="22" /></span>
        <span>
          <strong>PFT</strong>
          <small>외벽 도장 현장 관리</small>
        </span>
      </div>

      <nav class="primary-nav" aria-label="기본 메뉴" :inert="store.saving">
        <RouterLink v-for="item in navigation" :key="item.to" :to="item.to">
          <component :is="item.icon" :size="19" />
          <span>{{ item.label }}</span>
        </RouterLink>
      </nav>

      <div class="storage-status">
        <Database :size="17" />
        <span>
          <strong>{{
            store.storageMode === 'sqlite' ? 'SQLite 저장소' : '브라우저 미리보기'
          }}</strong>
          <small>{{
            store.saving ? '저장 중...' : store.storageError || '이 기기에 저장됨'
          }}</small>
        </span>
      </div>
    </aside>

    <div class="workspace">
      <header class="topbar">
        <strong class="topbar-brand">태광페인트</strong>
      </header>

      <p v-if="store.storageError" class="storage-notice storage-notice-error" role="alert">
        {{ store.storageError }}
      </p>
      <p v-if="store.saving" class="storage-notice" role="status">
        저장 중입니다. 완료될 때까지 앱을 닫지 마세요.
      </p>
      <main class="page-container" :inert="store.saving" :aria-busy="store.saving">
        <slot />
      </main>
    </div>

    <nav class="mobile-nav" aria-label="모바일 메뉴" :inert="store.saving">
      <RouterLink v-for="item in navigation" :key="item.to" :to="item.to">
        <component :is="item.icon" :size="20" />
        <span>{{ item.label }}</span>
      </RouterLink>
    </nav>
  </div>
</template>
