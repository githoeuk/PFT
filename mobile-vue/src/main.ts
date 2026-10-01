import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useErpStore } from './stores/erp'
import './styles/base.css'

import { syncSiteEndNotifications } from '@/services/siteEndNotificationService'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)

app.mount('#app')

const store = useErpStore(pinia)

void (async () => {
  await store.hydrate()

  if (store.hydrated) {
    await syncSiteEndNotifications(store.sites)
  }
})().catch((error) => {
  console.error('현장 종료 알림 설정 실패:', error)
})
