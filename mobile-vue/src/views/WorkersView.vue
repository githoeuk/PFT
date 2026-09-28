<script setup lang="ts">
import { nextTick, reactive, ref } from 'vue'
import { ChevronRight, Pencil, Plus, Users, X } from '@lucide/vue'

import { useErpStore } from '@/stores/erp'
import type { NewWorker, Worker } from '@/types/erp'
import { workerRoleLabels } from '@/utils/erpLabels'
import { formatCurrency } from '@/utils/formatters'

const store = useErpStore()
const showForm = ref(false)
const editingWorkerId = ref<string | null>(null)
const editorPanel = ref<HTMLFormElement | null>(null)

const blankForm = (): NewWorker => ({
  name: '',
  phone: '',
  team: '',
  role: 'painter',
  dailyRate: 0,
  active: true,
})
const form = reactive<NewWorker>(blankForm())

function showEditor() {
  showForm.value = true
  void nextTick(() => editorPanel.value?.scrollIntoView({ behavior: 'smooth', block: 'start' }))
}

function openCreateForm() {
  editingWorkerId.value = null
  Object.assign(form, blankForm())
  showEditor()
}

function openEditForm(worker: Worker) {
  editingWorkerId.value = worker.id
  Object.assign(form, {
    name: worker.name,
    phone: worker.phone,
    team: worker.team,
    role: worker.role,
    dailyRate: worker.dailyRate,
    active: worker.active,
  })
  showEditor()
}

function resetForm() {
  Object.assign(form, blankForm())
  editingWorkerId.value = null
  showForm.value = false
}

function submit() {
  if (!form.name.trim()) return
  const input: NewWorker = {
    ...form,
    name: form.name.trim(),
    phone: form.phone.trim(),
    team: form.team.trim(),
    dailyRate: Number(form.dailyRate),
  }

  if (editingWorkerId.value) store.updateWorker(editingWorkerId.value, input)
  else store.addWorker(input)
  resetForm()
}
</script>

<template>
  <section class="page-heading">
    <div>
      <p class="eyebrow">인력 관리</p>
      <h1>근로자 관리</h1>
      <p>활동 근로자 {{ store.activeWorkers.length }}명</p>
    </div>
    <button class="button button-primary" type="button" @click="openCreateForm">
      <Plus :size="18" /> 근로자 등록
    </button>
  </section>

  <form v-if="showForm" ref="editorPanel" class="editor-panel" @submit.prevent="submit">
    <div class="section-heading editor-heading">
      <div>
        <h2>{{ editingWorkerId ? '근로자 정보 수정' : '새 근로자 등록' }}</h2>
        <p>{{ editingWorkerId ? '등록된 근로자 정보를 변경합니다' : '근로자 정보 및 일당' }}</p>
      </div>
      <button class="icon-button" type="button" title="닫기" @click="resetForm">
        <X :size="19" />
      </button>
    </div>
    <div class="form-grid">
      <label
        ><span>이름</span><input v-model="form.name" required placeholder="근로자 이름"
      /></label>
      <label
        ><span>연락처</span><input v-model="form.phone" inputmode="tel" placeholder="010-0000-0000"
      /></label>
      <label><span>소속 팀</span><input v-model="form.team" placeholder="팀 이름" /></label>
      <label
        ><span>직책</span>
        <select v-model="form.role">
          <option v-for="(label, value) in workerRoleLabels" :key="value" :value="value">
            {{ label }}
          </option>
        </select>
      </label>
      <label
        ><span>일당 (원)</span
        ><input v-model.number="form.dailyRate" type="number" min="0" step="1000"
      /></label>
    </div>
    <div class="form-actions">
      <button class="button button-ghost" type="button" @click="resetForm">취소</button
      ><button class="button button-primary" type="submit">
        {{ editingWorkerId ? '수정 저장' : '근로자 저장' }}
      </button>
    </div>
  </form>

  <section class="content-section table-section">
    <div v-if="store.workers.length" class="data-table-wrap">
      <table class="data-table management-table">
        <thead>
          <tr>
            <th>근로자</th>
            <th>소속 / 직책</th>
            <th>일당</th>
            <th>상태</th>
            <th aria-label="관리"></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="worker in store.workers" :key="worker.id">
            <td data-label="근로자">
              <strong>{{ worker.name }}</strong
              ><small>{{ worker.phone || '연락처 없음' }}</small>
            </td>
            <td data-label="소속 / 직책">
              {{ worker.team || '미지정' }} / {{ workerRoleLabels[worker.role] }}
            </td>
            <td data-label="일당">{{ formatCurrency(worker.dailyRate) }}</td>
            <td data-label="상태">
              <button
                class="toggle-button"
                :class="{ active: worker.active }"
                type="button"
                @click="store.toggleWorker(worker.id)"
              >
                <i></i>{{ worker.active ? '활동' : '비활동' }}
              </button>
            </td>
            <td class="table-actions-cell" data-label="관리">
              <div class="table-actions">
                <button
                  class="icon-button"
                  type="button"
                  title="근로자 수정"
                  @click="openEditForm(worker)"
                >
                  <Pencil :size="17" />
                </button>
                <RouterLink
                  class="icon-button"
                  :to="`/workers/${worker.id}`"
                  title="근로자 상세 보기"
                >
                  <ChevronRight :size="18" />
                </RouterLink>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <div v-else class="empty-state">
      <Users :size="28" /><strong>등록된 근로자가 없습니다</strong
      ><button class="button button-secondary" type="button" @click="openCreateForm">
        첫 근로자 등록
      </button>
    </div>
  </section>
</template>
