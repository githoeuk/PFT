<script setup lang="ts">
import { computed, nextTick, reactive, ref } from 'vue'
import { ChevronRight, Pencil, Plus, Trash2, Users, X } from '@lucide/vue'

import {
  formatWorkerBankAccount,
  hasWorkerBankAccount,
  validateWorkerBankAccount,
} from '@/services/workerBankAccountService'
import { useErpStore } from '@/stores/erp'
import type { NewWorker, Worker } from '@/types/erp'
import { workerRoleLabels } from '@/utils/erpLabels'
import { formatCurrency } from '@/utils/formatters'

const store = useErpStore()
const showForm = ref(false)
const editingWorkerId = ref<string | null>(null)
const editorPanel = ref<HTMLFormElement | null>(null)
const formError = ref('')
const accountMessage = ref('')

const blankForm = (): NewWorker => ({
  name: '',
  phone: '',
  team: '',
  role: 'painter',
  dailyRate: 0,
  bankName: '',
  accountNumber: '',
  accountHolder: '',
  active: true,
})
const form = reactive<NewWorker>(blankForm())
const editingWorkerHasBankAccount = computed(() => {
  const worker = store.workers.find((candidate) => candidate.id === editingWorkerId.value)
  return worker ? hasWorkerBankAccount(worker) : false
})

function showEditor() {
  showForm.value = true
  void nextTick(() => editorPanel.value?.scrollIntoView({ behavior: 'smooth', block: 'start' }))
}

function openCreateForm() {
  editingWorkerId.value = null
  Object.assign(form, blankForm())
  formError.value = ''
  accountMessage.value = ''
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
    bankName: worker.bankName,
    accountNumber: worker.accountNumber,
    accountHolder: worker.accountHolder,
    active: worker.active,
  })
  formError.value = ''
  accountMessage.value = ''
  showEditor()
}

function resetForm() {
  Object.assign(form, blankForm())
  editingWorkerId.value = null
  showForm.value = false
  formError.value = ''
  accountMessage.value = ''
}

async function submit() {
  if (!form.name.trim() || store.saving) return
  const input: NewWorker = {
    ...form,
    name: form.name.trim(),
    phone: form.phone.trim(),
    team: form.team.trim(),
    dailyRate: Number(form.dailyRate),
    bankName: form.bankName.trim(),
    accountNumber: form.accountNumber.trim(),
    accountHolder: form.accountHolder.trim(),
  }

  const accountError = validateWorkerBankAccount(input)
  if (accountError) {
    formError.value = accountError
    return
  }

  try {
    if (editingWorkerId.value) await store.updateWorker(editingWorkerId.value, input)
    else await store.addWorker(input)
    resetForm()
  } catch {
    formError.value = store.storageError
  }
}

async function deleteBankAccount() {
  if (!editingWorkerId.value || store.saving) return

  const worker = store.workers.find((candidate) => candidate.id === editingWorkerId.value)
  if (!worker || !hasWorkerBankAccount(worker)) return
  if (!window.confirm(`${worker.name}의 계좌정보를 삭제하시겠습니까?`)) return

  try {
    await store.clearWorkerBankAccount(worker.id)
  } catch {
    formError.value = store.storageError
    return
  }
  form.bankName = ''
  form.accountNumber = ''
  form.accountHolder = ''
  formError.value = ''
  accountMessage.value = '계좌정보를 삭제했습니다'
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
      <div class="form-section-heading span-2">
        <strong>급여 계좌</strong>
        <small>임금 지급에 사용하는 근로자 본인 명의 계좌</small>
      </div>
      <label><span>은행명</span><input v-model="form.bankName" placeholder="예: 국민은행" /></label>
      <label
        ><span>예금주</span><input v-model="form.accountHolder" placeholder="근로자 본인 이름"
      /></label>
      <label class="span-2"
        ><span>계좌번호</span
        ><input
          v-model="form.accountNumber"
          inputmode="numeric"
          autocomplete="off"
          pattern="[0-9-]*"
          placeholder="숫자와 하이픈만 입력"
      /></label>
    </div>
    <p v-if="formError" class="form-message form-message-error">{{ formError }}</p>
    <p v-if="accountMessage" class="form-message">{{ accountMessage }}</p>
    <div class="form-actions form-actions-split">
      <button
        v-if="editingWorkerHasBankAccount"
        class="button button-secondary danger-button"
        type="button"
        @click="deleteBankAccount"
      >
        <Trash2 :size="16" /> 계좌정보 삭제
      </button>
      <div>
        <button class="button button-ghost" type="button" @click="resetForm">취소</button
        ><button class="button button-primary" type="submit">
          {{ editingWorkerId ? '수정 저장' : '근로자 저장' }}
        </button>
      </div>
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
            <th>급여 계좌</th>
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
            <td data-label="급여 계좌">
              <span>{{ formatWorkerBankAccount(worker) }}</span>
              <small v-if="worker.accountHolder">예금주 {{ worker.accountHolder }}</small>
            </td>
            <td data-label="상태">
              <button
                class="toggle-button"
                :class="{ active: worker.active }"
                type="button"
                :disabled="store.saving"
                @click="store.toggleWorker(worker.id).catch(() => undefined)"
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
