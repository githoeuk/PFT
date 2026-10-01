<script setup lang="ts">
import { Database, RefreshCw } from '@lucide/vue'
import { useErpStore } from '@/stores/erp'

const store = useErpStore()
</script>

<template>
  <main class="storage-gate">
    <Database :size="32" aria-hidden="true" />
    <h1>{{ store.loading ? '데이터를 불러오는 중입니다' : '데이터를 불러오지 못했습니다' }}</h1>
    <p v-if="store.loadError" role="alert">{{ store.loadError }}</p>
    <p v-if="!store.loading">
      앱을 삭제하거나 데이터를 초기화하지 마세요. 저장소를 다시 확인해 주세요.
    </p>
    <details v-if="store.loadErrorDetail">
      <summary>오류 정보</summary>
      <p>{{ store.loadErrorDetail }}</p>
    </details>
    <button
      class="button button-primary"
      type="button"
      :disabled="store.loading"
      @click="store.hydrate()"
    >
      <RefreshCw :size="18" />{{ store.loading ? '불러오는 중...' : '다시 불러오기' }}
    </button>
  </main>
</template>
