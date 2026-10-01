<script setup lang="ts">
import { ref } from 'vue'
import { MapPinned, Wallet } from '@lucide/vue'
import SiteCostPanel from '@/components/payroll/SiteCostPanel.vue'
import WorkerPayrollPanel from '@/components/payroll/WorkerPayrollPanel.vue'
import { todayIso } from '@/utils/formatters'

const selectedMonth = ref(todayIso().slice(0, 7))
const activeTab = ref<'sites' | 'workers'>('sites')

function switchTab(event: KeyboardEvent) {
  if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return
  event.preventDefault()
  activeTab.value =
    event.key === 'Home'
      ? 'sites'
      : event.key === 'End'
        ? 'workers'
        : activeTab.value === 'sites'
          ? 'workers'
          : 'sites'
  document.getElementById(`payroll-tab-${activeTab.value}`)?.focus()
}
</script>

<template>
  <section class="page-heading">
    <div>
      <p class="eyebrow">월별 정산</p>
      <h1>정산 관리</h1>
    </div>
    <label class="payroll-month">
      <span>정산 월</span>
      <input v-model="selectedMonth" type="month" required />
    </label>
  </section>

  <div class="payroll-tabs" role="tablist" aria-label="정산 구분" @keydown="switchTab">
    <button
      id="payroll-tab-sites"
      role="tab"
      type="button"
      :aria-selected="activeTab === 'sites'"
      aria-controls="payroll-panel-sites"
      :tabindex="activeTab === 'sites' ? 0 : -1"
      @click="activeTab = 'sites'"
    >
      <MapPinned :size="18" />현장 원가
    </button>
    <button
      id="payroll-tab-workers"
      role="tab"
      type="button"
      :aria-selected="activeTab === 'workers'"
      aria-controls="payroll-panel-workers"
      :tabindex="activeTab === 'workers' ? 0 : -1"
      @click="activeTab = 'workers'"
    >
      <Wallet :size="18" />근로자 임금 지급
    </button>
  </div>

  <p v-if="!selectedMonth" class="form-message form-message-error" role="alert">
    정산 월을 선택해 주세요.
  </p>
  <div
    id="payroll-panel-sites"
    v-show="activeTab === 'sites'"
    role="tabpanel"
    aria-labelledby="payroll-tab-sites"
  >
    <SiteCostPanel :month="selectedMonth" @update:month="selectedMonth = $event" />
  </div>
  <div
    id="payroll-panel-workers"
    v-show="activeTab === 'workers'"
    role="tabpanel"
    aria-labelledby="payroll-tab-workers"
  >
    <WorkerPayrollPanel :month="selectedMonth" />
  </div>
</template>
