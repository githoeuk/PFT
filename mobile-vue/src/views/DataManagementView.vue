<script setup lang="ts">
import { computed, ref } from 'vue'
import { Capacitor } from '@capacitor/core'
import {
  ArchiveRestore,
  DatabaseBackup,
  Download,
  FileJson,
  Share2,
  ShieldAlert,
} from '@lucide/vue'

import { canShareBackupFile, saveBackupFile, shareBackupFile } from '@/services/backupFileService'
import {
  createErpBackup,
  parseErpBackup,
  serializeErpBackup,
  type ErpBackupFile,
} from '@/services/erpBackupService'
import { useErpStore } from '@/stores/erp'
import { formatDate } from '@/utils/formatters'

const store = useErpStore()
const fileInput = ref<HTMLInputElement>()
const pendingBackup = ref<ErpBackupFile>()
const pendingFileName = ref('')
const message = ref('')
const errorMessage = ref('')
const exporting = ref<'save' | 'share' | null>(null)
const restoring = ref(false)
const shareSupported = canShareBackupFile()
const saveLabel = Capacitor.getPlatform() === 'android' ? '휴대폰에 저장' : '파일로 저장'

const currentCounts = computed(() => ({
  sites: store.sites.length,
  workers: store.workers.length,
  attendance: store.attendanceRecords.length,
  settlements: store.payrollSettlements.length,
  expenses: store.siteExpenses.length,
}))

const backupCounts = computed(() => {
  const data = pendingBackup.value?.data
  return data
    ? {
        sites: data.sites.length,
        workers: data.workers.length,
        attendance: data.attendanceRecords.length,
        settlements: data.payrollSettlements.length,
        expenses: data.siteExpenses.length,
      }
    : undefined
})

const backupFileName = (): string => {
  const stamp = new Date().toISOString().replace(/:/g, '').replace('T', '-')
  return `taekwang-pft-backup-${stamp}.json`
}

async function exportBackup(action: 'save' | 'share'): Promise<void> {
  if (exporting.value || restoring.value) return
  exporting.value = action
  message.value = ''
  errorMessage.value = ''

  try {
    const backup = createErpBackup(store.exportData())
    const contents = serializeErpBackup(backup)
    if (action === 'save') {
      const result = await saveBackupFile(backupFileName(), contents)
      message.value = {
        saved: '선택한 위치에 백업 파일을 저장했습니다.',
        downloaded: '백업 파일 다운로드를 시작했습니다.',
        cancelled: '백업 파일 저장을 취소했습니다.',
      }[result]
    } else {
      const result = await shareBackupFile(backupFileName(), contents)
      message.value = {
        opened: '공유 앱을 열었습니다. 해당 앱에서 전송 또는 저장을 완료해 주세요.',
        dismissed: '공유 화면을 닫았습니다.',
        cancelled: '백업 파일 공유를 취소했습니다.',
      }[result]
    }
  } catch (error) {
    console.error('Failed to export backup', error)
    errorMessage.value =
      action === 'save'
        ? '백업 파일을 저장하지 못했습니다. 저장 위치와 여유 공간을 확인해 주세요.'
        : '백업 파일을 공유하지 못했습니다. 다시 시도하거나 파일로 저장해 주세요.'
  } finally {
    exporting.value = null
  }
}

function chooseRestoreFile(): void {
  fileInput.value?.click()
}

async function readRestoreFile(event: Event): Promise<void> {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''
  pendingBackup.value = undefined
  pendingFileName.value = ''
  message.value = ''
  errorMessage.value = ''

  if (!file) return

  try {
    pendingBackup.value = parseErpBackup(await file.text())
    pendingFileName.value = file.name
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '백업 파일을 읽지 못했습니다.'
  }
}

async function restoreBackup(): Promise<void> {
  if (!pendingBackup.value) return

  restoring.value = true
  message.value = ''
  errorMessage.value = ''

  try {
    await store.restoreData(pendingBackup.value.data)
    pendingBackup.value = undefined
    pendingFileName.value = ''
    message.value = '백업 데이터를 복원했습니다.'
  } catch (error) {
    console.error('Failed to restore backup', error)
    errorMessage.value = '데이터를 복원하지 못했습니다. 기존 데이터는 유지됩니다.'
  } finally {
    restoring.value = false
  }
}
</script>

<template>
  <section class="page-heading">
    <div>
      <p class="eyebrow">로컬 저장소</p>
      <h1>데이터 관리</h1>
      <p>앱 업데이트와 휴대폰 교체에 대비해 데이터를 백업하고 복원합니다.</p>
    </div>
  </section>

  <section class="backup-summary backup-summary-with-expenses" aria-label="현재 저장 데이터">
    <div>
      <small>현장</small><strong>{{ currentCounts.sites }}</strong>
    </div>
    <div>
      <small>근로자</small><strong>{{ currentCounts.workers }}</strong>
    </div>
    <div>
      <small>출석 기록</small><strong>{{ currentCounts.attendance }}</strong>
    </div>
    <div>
      <small>정산 기록</small><strong>{{ currentCounts.settlements }}</strong>
    </div>
    <div>
      <small>경비 기록</small><strong>{{ currentCounts.expenses }}</strong>
    </div>
  </section>

  <p v-if="message" class="backup-message" role="status">{{ message }}</p>
  <p v-if="errorMessage" class="backup-message error" role="alert">{{ errorMessage }}</p>

  <section class="data-management-grid">
    <article class="content-section backup-panel">
      <div class="backup-panel-heading">
        <span class="metric-icon green"><DatabaseBackup :size="21" /></span>
        <div>
          <h2>백업 파일 내보내기</h2>
          <p>현재 데이터를 하나의 JSON 파일로 저장합니다.</p>
        </div>
      </div>
      <ul class="backup-details">
        <li>현장, 근로자, 출석, 현장 배정, 지급 정보, 기타 경비 포함</li>
      </ul>
      <div class="backup-export-actions" :aria-busy="exporting !== null">
        <button
          class="button button-primary"
          type="button"
          :disabled="exporting !== null || restoring"
          @click="exportBackup('save')"
        >
          <Download :size="17" />
          {{ exporting === 'save' ? '저장 중...' : saveLabel }}
        </button>
        <button
          class="button button-secondary"
          type="button"
          :disabled="exporting !== null || restoring || !shareSupported"
          :title="shareSupported ? '백업 파일 공유' : '이 브라우저는 파일 공유를 지원하지 않습니다'"
          @click="exportBackup('share')"
        >
          <Share2 :size="17" />
          {{ exporting === 'share' ? '공유 중...' : '공유하기' }}
        </button>
      </div>
    </article>

    <article class="content-section backup-panel">
      <div class="backup-panel-heading">
        <span class="metric-icon amber"><ArchiveRestore :size="21" /></span>
        <div>
          <h2>백업 파일 복원</h2>
          <p>선택한 백업으로 현재 데이터를 교체합니다.</p>
        </div>
      </div>
      <input
        ref="fileInput"
        class="visually-hidden"
        type="file"
        accept="application/json,.json"
        @change="readRestoreFile"
      />
      <button
        class="button button-secondary restore-file-button"
        type="button"
        :disabled="exporting !== null || restoring"
        @click="chooseRestoreFile"
      >
        <FileJson :size="17" />
        백업 파일 선택
      </button>

      <div v-if="pendingBackup && backupCounts" class="restore-preview">
        <strong>{{ pendingFileName }}</strong>
        <small>백업 일시 {{ formatDate(pendingBackup.exportedAt.slice(0, 10)) }}</small>
        <dl>
          <div>
            <dt>현장</dt>
            <dd>{{ backupCounts.sites }}</dd>
          </div>
          <div>
            <dt>근로자</dt>
            <dd>{{ backupCounts.workers }}</dd>
          </div>
          <div>
            <dt>출석</dt>
            <dd>{{ backupCounts.attendance }}</dd>
          </div>
          <div>
            <dt>정산</dt>
            <dd>{{ backupCounts.settlements }}</dd>
          </div>
          <div>
            <dt>경비</dt>
            <dd>{{ backupCounts.expenses }}</dd>
          </div>
        </dl>
        <p>복원하면 현재 저장된 데이터가 이 백업 내용으로 교체됩니다.</p>
        <button
          class="button danger-button"
          type="button"
          :disabled="restoring || exporting !== null"
          @click="restoreBackup"
        >
          <ArchiveRestore :size="17" />
          {{ restoring ? '복원하는 중...' : '이 백업으로 복원' }}
        </button>
      </div>
    </article>
  </section>

  <aside class="backup-warning">
    <ShieldAlert :size="19" />
    <p>
      백업 파일에는 연락처와 계좌정보가 포함됩니다. 앱을 삭제하기 전에 파일이 휴대폰 외부나
      클라우드에 저장되었는지 확인하고, 타인에게 전달하지 마세요.
    </p>
  </aside>
</template>
