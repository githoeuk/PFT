<script setup lang="ts">
import { nextTick, reactive, ref } from 'vue'
import { ChevronRight, MapPinned, Pencil, Plus, X } from '@lucide/vue'

import { useErpStore } from '@/stores/erp'
import type { NewSite, Site, SiteStatus } from '@/types/erp'
import { siteStatusLabels } from '@/utils/erpLabels'
import { formatDate, todayIso } from '@/utils/formatters'

const store = useErpStore()
const showForm = ref(false)
const editingSiteId = ref<string | null>(null)
const editorPanel = ref<HTMLFormElement | null>(null)

const blankForm = (): NewSite => ({
  name: '',
  client: '',
  address: '',
  startDate: todayIso(),
  endDate: '',
  status: 'active',
})
const form = reactive<NewSite>(blankForm())

function showEditor() {
  showForm.value = true
  void nextTick(() => editorPanel.value?.scrollIntoView({ behavior: 'smooth', block: 'start' }))
}

function openCreateForm() {
  editingSiteId.value = null
  Object.assign(form, blankForm())
  showEditor()
}

function openEditForm(site: Site) {
  editingSiteId.value = site.id
  Object.assign(form, {
    name: site.name,
    client: site.client,
    address: site.address,
    startDate: site.startDate,
    endDate: site.endDate,
    status: site.status,
  })
  showEditor()
}

function resetForm() {
  Object.assign(form, blankForm())
  editingSiteId.value = null
  showForm.value = false
}

function submit() {
  if (!form.name.trim()) return
  const input: NewSite = {
    ...form,
    name: form.name.trim(),
    client: form.client.trim(),
    address: form.address.trim(),
  }

  if (editingSiteId.value) store.updateSite(editingSiteId.value, input)
  else store.addSite(input)
  resetForm()
}
</script>

<template>
  <section class="page-heading">
    <div>
      <p class="eyebrow">공사 관리</p>
      <h1>현장 관리</h1>
      <p>전체 현장 {{ store.sites.length }}개</p>
    </div>
    <button class="button button-primary" type="button" @click="openCreateForm">
      <Plus :size="18" /> 현장 등록
    </button>
  </section>

  <form v-if="showForm" ref="editorPanel" class="editor-panel" @submit.prevent="submit">
    <div class="section-heading editor-heading">
      <div>
        <h2>{{ editingSiteId ? '현장 정보 수정' : '새 현장 등록' }}</h2>
        <p>{{ editingSiteId ? '등록된 현장 정보를 변경합니다' : '외벽 도장 공사 기본 정보' }}</p>
      </div>
      <button class="icon-button" type="button" title="닫기" @click="resetForm">
        <X :size="19" />
      </button>
    </div>
    <div class="form-grid">
      <label
        ><span>현장명</span><input v-model="form.name" required placeholder="공사명 또는 건물명"
      /></label>
      <label
        ><span>발주처</span><input v-model="form.client" placeholder="발주처 또는 시공사"
      /></label>
      <label class="span-2"
        ><span>주소</span><input v-model="form.address" placeholder="현장 주소"
      /></label>
      <label><span>착공일</span><input v-model="form.startDate" type="date" /></label>
      <label><span>종료일</span><input v-model="form.endDate" type="date" /></label>
      <label
        ><span>상태</span>
        <select v-model="form.status">
          <option value="active">진행 중</option>
          <option value="on_hold">보류</option>
          <option value="completed">완료</option>
        </select>
      </label>
    </div>
    <div class="form-actions">
      <button class="button button-ghost" type="button" @click="resetForm">취소</button>
      <button class="button button-primary" type="submit">
        {{ editingSiteId ? '수정 저장' : '현장 저장' }}
      </button>
    </div>
  </form>

  <section class="content-section table-section">
    <div v-if="store.sites.length" class="data-table-wrap">
      <table class="data-table management-table">
        <thead>
          <tr>
            <th>현장</th>
            <th>발주처</th>
            <th>공사 기간</th>
            <th>상태</th>
            <th aria-label="관리"></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="site in store.sites" :key="site.id">
            <td data-label="현장">
              <strong>{{ site.name }}</strong
              ><small>{{ site.address || '주소 없음' }}</small>
            </td>
            <td data-label="발주처">{{ site.client || '-' }}</td>
            <td data-label="공사 기간">
              {{ formatDate(site.startDate) }} - {{ formatDate(site.endDate) }}
            </td>
            <td data-label="상태">
              <select
                class="status-select"
                :value="site.status"
                @change="
                  store.updateSiteStatus(
                    site.id,
                    ($event.target as HTMLSelectElement).value as SiteStatus,
                  )
                "
              >
                <option v-for="(label, value) in siteStatusLabels" :key="value" :value="value">
                  {{ label }}
                </option>
              </select>
            </td>
            <td class="table-actions-cell" data-label="관리">
              <div class="table-actions">
                <button
                  class="icon-button"
                  type="button"
                  title="현장 수정"
                  @click="openEditForm(site)"
                >
                  <Pencil :size="17" />
                </button>
                <RouterLink class="icon-button" :to="`/sites/${site.id}`" title="현장 상세 보기">
                  <ChevronRight :size="18" />
                </RouterLink>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <div v-else class="empty-state">
      <MapPinned :size="28" /><strong>등록된 현장이 없습니다</strong
      ><button class="button button-secondary" type="button" @click="openCreateForm">
        첫 현장 등록
      </button>
    </div>
  </section>
</template>
