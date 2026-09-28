<script setup lang="ts">
import { computed, nextTick, ref } from 'vue'
import { HardHat, LockKeyhole } from '@lucide/vue'

import { isValidPin, savePin, verifyPin } from '@/services/pinSecurity'

const props = defineProps<{ configured: boolean }>()
const emit = defineEmits<{ unlocked: [] }>()

const pin = ref('')
const confirmation = ref('')
const errorMessage = ref('')
const submitting = ref(false)
const pinInput = ref<HTMLInputElement>()

const title = computed(() => (props.configured ? 'PIN 입력' : 'PIN 설정'))
const description = computed(() =>
  props.configured
    ? '저장된 현장 정보를 열려면 PIN을 입력하세요.'
    : '이 기기에서 사용할 숫자 4자리 PIN을 설정하세요.',
)

function sanitizePin(value: string): string {
  return value.replace(/\D/g, '').slice(0, 4)
}

function onPinInput(event: Event) {
  pin.value = sanitizePin((event.target as HTMLInputElement).value)
}

function onConfirmationInput(event: Event) {
  confirmation.value = sanitizePin((event.target as HTMLInputElement).value)
}

async function submit() {
  errorMessage.value = ''
  if (!isValidPin(pin.value)) {
    errorMessage.value = '숫자 4자리를 입력하세요.'
    return
  }
  if (!props.configured && pin.value !== confirmation.value) {
    errorMessage.value = 'PIN 확인 값이 일치하지 않습니다.'
    return
  }

  submitting.value = true
  try {
    if (props.configured) {
      if (!(await verifyPin(pin.value))) {
        errorMessage.value = 'PIN이 올바르지 않습니다.'
        pin.value = ''
        await nextTick()
        pinInput.value?.focus()
        return
      }
    } else {
      await savePin(pin.value)
    }
    emit('unlocked')
  } catch {
    errorMessage.value = 'PIN을 처리하지 못했습니다. 다시 시도하세요.'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <main class="pin-screen">
    <section class="pin-panel" aria-labelledby="pin-title">
      <div class="pin-brand"><HardHat :size="24" /><strong>PFT</strong></div>
      <span class="pin-icon"><LockKeyhole :size="24" /></span>
      <h1 id="pin-title">{{ title }}</h1>
      <p>{{ description }}</p>

      <form class="pin-form" @submit.prevent="submit">
        <label>
          <span>{{ configured ? 'PIN' : '새 PIN' }}</span>
          <input
            ref="pinInput"
            :value="pin"
            type="password"
            inputmode="numeric"
            pattern="[0-9]*"
            maxlength="4"
            autocomplete="off"
            autofocus
            placeholder="숫자 4자리"
            @input="onPinInput"
          />
        </label>
        <label v-if="!configured">
          <span>PIN 확인</span>
          <input
            :value="confirmation"
            type="password"
            inputmode="numeric"
            pattern="[0-9]*"
            maxlength="4"
            autocomplete="off"
            placeholder="한 번 더 입력"
            @input="onConfirmationInput"
          />
        </label>
        <p v-if="errorMessage" class="pin-error" role="alert">{{ errorMessage }}</p>
        <button class="button button-primary button-full" type="submit" :disabled="submitting">
          {{ submitting ? '확인 중...' : configured ? '잠금 해제' : 'PIN 저장' }}
        </button>
      </form>
      <small>PIN을 잊으면 앱 데이터를 초기화해야 합니다.</small>
    </section>
  </main>
</template>
