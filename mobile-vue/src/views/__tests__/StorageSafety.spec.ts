import { createPinia } from 'pinia'
import { flushPromises, mount } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import App from '@/App.vue'
import SitesView from '@/views/SitesView.vue'
import WorkersView from '@/views/WorkersView.vue'
import AttendanceView from '@/views/AttendanceView.vue'
import { useErpStore } from '@/stores/erp'
import { localStorageErpRepository as repository } from '@/repositories/localStorageErpRepository'

vi.mock('vue-router', async (importOriginal) => ({
  ...(await importOriginal<typeof import('vue-router')>()),
  useRoute: () => ({ query: {} }),
}))

describe('storage failure UI', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.spyOn(console, 'error').mockImplementation(() => undefined)
    Element.prototype.scrollIntoView = vi.fn<Element['scrollIntoView']>()
  })
  afterEach(() => vi.restoreAllMocks())

  it('does not mount editable pages after failed hydration, and allows retry after PIN unlock', async () => {
    const pinia = createPinia()
    const store = useErpStore(pinia)
    vi.spyOn(repository, 'load').mockRejectedValueOnce(new Error('read failed'))
    await store.hydrate()
    const wrapper = mount(App, {
      global: {
        plugins: [pinia],
        stubs: {
          PinLock: { template: '<button @click="$emit(\'unlocked\')">unlock</button>' },
          AppShell: { template: '<div><slot /></div>' },
          RouterView: { template: '<div data-testid="editable-page" />' },
        },
      },
    })
    await wrapper.get('button').trigger('click')
    expect(wrapper.find('[data-testid="editable-page"]').exists()).toBe(false)
    expect(wrapper.get('[role="alert"]').text()).toContain('읽지 못했습니다')
    await wrapper.get('button').trigger('click')
    await flushPromises()
    expect(wrapper.find('[data-testid="editable-page"]').exists()).toBe(true)
  })

  it.each([
    { component: SitesView, name: '현장 입력 보존', collection: 'sites' as const },
    { component: WorkersView, name: '근로자 입력 보존', collection: 'workers' as const },
  ])(
    'keeps the form open after failed $collection save',
    async ({ component, name, collection }) => {
      const pinia = createPinia()
      const store = useErpStore(pinia)
      await store.hydrate()
      vi.spyOn(repository, 'save').mockRejectedValueOnce(new Error('disk full'))
      const wrapper = mount(component, { global: { plugins: [pinia], stubs: ['RouterLink'] } })
      await wrapper.get('.page-heading button').trigger('click')
      await wrapper.get('form input').setValue(name)
      await wrapper.get('form').trigger('submit')
      await flushPromises()
      expect(wrapper.find('form').exists()).toBe(true)
      expect((wrapper.get('form input').element as HTMLInputElement).value).toBe(name)
      expect(store[collection]).toHaveLength(0)
      expect(store.storageError).toContain('저장하지 못했습니다')
      await wrapper.get('form').trigger('submit')
      await flushPromises()
      expect(wrapper.find('form').exists()).toBe(false)
      expect(store[collection]).toHaveLength(1)
    },
  )

  it('does not display attendance success until the write succeeds', async () => {
    const pinia = createPinia()
    const store = useErpStore(pinia)
    await store.hydrate()
    await store.addSite({
      name: '현장',
      client: '',
      address: '',
      startDate: '',
      endDate: '',
      status: 'active',
    })
    await store.addWorker({
      name: '근로자',
      phone: '',
      team: '',
      role: 'painter',
      dailyRate: 170000,
      bankName: '',
      accountNumber: '',
      accountHolder: '',
      active: true,
    })
    await store.upsertSiteWorkerAssignment({
      siteId: store.sites[0]!.id,
      workerId: store.workers[0]!.id,
      dailyRate: 170000,
      workRole: 'painter',
    })
    vi.spyOn(repository, 'save').mockRejectedValueOnce(new Error('disk full'))
    const wrapper = mount(AttendanceView, { global: { plugins: [pinia], stubs: ['RouterLink'] } })
    await wrapper.get('.attendance-row select').setValue('present')
    await wrapper.get('input[placeholder="비고 입력"]').setValue('지워지면 안 되는 비고')
    await wrapper.get('.attendance-heading button').trigger('click')
    await flushPromises()
    expect(wrapper.text()).not.toContain('건을 저장했습니다')
    expect(store.attendanceRecords).toHaveLength(0)
    expect((wrapper.get('input[placeholder="비고 입력"]').element as HTMLInputElement).value).toBe(
      '지워지면 안 되는 비고',
    )
    await wrapper.get('.attendance-heading button').trigger('click')
    await flushPromises()
    expect(wrapper.text()).toContain('1건을 저장했습니다')
    expect(store.attendanceRecords).toHaveLength(1)
  })
})
