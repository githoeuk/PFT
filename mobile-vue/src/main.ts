import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useErpStore } from './stores/erp'
import './styles/base.css'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)

void useErpStore(pinia)
  .hydrate()
  .finally(() => app.mount('#app'))
