import { createRouter, createWebHistory } from 'vue-router'

import AttendanceView from '@/views/AttendanceView.vue'
import DashboardView from '@/views/DashboardView.vue'
import SiteDetailView from '@/views/SiteDetailView.vue'
import SitesView from '@/views/SitesView.vue'
import WorkerDetailView from '@/views/WorkerDetailView.vue'
import WorkersView from '@/views/WorkersView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', name: 'dashboard', component: DashboardView },
    { path: '/attendance', name: 'attendance', component: AttendanceView },
    { path: '/sites', name: 'sites', component: SitesView },
    { path: '/sites/:siteId', name: 'site-detail', component: SiteDetailView },
    { path: '/workers', name: 'workers', component: WorkersView },
    { path: '/workers/:workerId', name: 'worker-detail', component: WorkerDetailView },
  ],
  scrollBehavior: () => ({ top: 0 }),
})

export default router
