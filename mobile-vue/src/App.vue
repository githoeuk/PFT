<script setup lang="ts">
import { ref } from 'vue'
import { RouterView } from 'vue-router'

import PinLock from '@/components/PinLock.vue'
import AppShell from '@/layouts/AppShell.vue'
import { isPinConfigured } from '@/services/pinSecurity'

const pinConfigured = ref(isPinConfigured())
const unlocked = ref(false)
</script>

<template>
  <PinLock v-if="!unlocked" :configured="pinConfigured" @unlocked="unlocked = true" />
  <AppShell v-else>
    <RouterView />
  </AppShell>
</template>
