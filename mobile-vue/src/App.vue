<script setup lang="ts">
import { ref } from 'vue'
import { RouterView } from 'vue-router'

import PinLock from '@/components/PinLock.vue'
import StorageGate from '@/components/StorageGate.vue'
import AppShell from '@/layouts/AppShell.vue'
import { isPinConfigured } from '@/services/pinSecurity'
import { useErpStore } from '@/stores/erp'

const pinConfigured = ref(isPinConfigured())
const unlocked = ref(false)
const store = useErpStore()
</script>

<template>
  <PinLock v-if="!unlocked" :configured="pinConfigured" @unlocked="unlocked = true" />
  <StorageGate v-else-if="!store.hydrated" />
  <AppShell v-else>
    <RouterView />
  </AppShell>
</template>
