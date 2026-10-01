import { createPinia } from 'pinia'
import { flushPromises, mount } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const files = vi.hoisted(() => ({
  save: vi.fn<(name: string, contents: string) => Promise<string>>(),
  share: vi.fn<(name: string, contents: string) => Promise<string>>(),
}))
vi.mock('@/services/backupFileService', () => ({
  saveBackupFile: files.save,
  shareBackupFile: files.share,
  canShareBackupFile: () => true,
}))

import DataManagementView from '@/views/DataManagementView.vue'
import { useErpStore } from '@/stores/erp'

const render = async () => {
  const pinia = createPinia()
  const store = useErpStore(pinia)
  await store.hydrate()
  store.sites = [
    {
      id: 'site-1',
      name: '백업 현장',
      client: '',
      address: '',
      startDate: '2026-09-30',
      endDate: '',
      status: 'active',
      createdAt: '2026-09-30',
    },
  ]
  return mount(DataManagementView, { global: { plugins: [pinia] } })
}

describe('DataManagementView export actions', () => {
  beforeEach(() => {
    window.localStorage.clear()
    vi.resetAllMocks()
    files.save.mockResolvedValue('saved')
    files.share.mockResolvedValue('opened')
  })
  afterEach(() => vi.restoreAllMocks())

  it('exports the same complete backup from separate save and share buttons', async () => {
    const wrapper = await render()
    await wrapper.get('.backup-export-actions .button-primary').trigger('click')
    await flushPromises()
    expect(wrapper.get('[role="status"]').text()).toContain('저장했습니다')
    const saved = JSON.parse(files.save.mock.calls[0]![1])
    expect(saved.data.sites[0].name).toBe('백업 현장')
    expect(files.share).not.toHaveBeenCalled()

    await wrapper.get('.backup-export-actions .button-secondary').trigger('click')
    await flushPromises()
    expect(JSON.parse(files.share.mock.calls[0]![1]).data).toEqual(saved.data)
    expect(wrapper.get('[role="status"]').text()).toContain('공유 앱을 열었습니다')
  })

  it('blocks repeat exports while the save picker is pending and recovers after cancellation', async () => {
    let finish!: (result: string) => void
    files.save.mockReturnValue(
      new Promise((resolve) => {
        finish = resolve
      }),
    )
    const wrapper = await render()
    await wrapper.get('.backup-export-actions .button-primary').trigger('click')
    expect(
      wrapper
        .findAll('.backup-export-actions button')
        .every((button) => button.attributes('disabled') !== undefined),
    ).toBe(true)
    expect(wrapper.find('[role="status"]').exists()).toBe(false)

    finish('cancelled')
    await flushPromises()
    expect(wrapper.get('[role="status"]').text()).toContain('저장을 취소했습니다')
    expect(
      wrapper.get('.backup-export-actions .button-primary').attributes('disabled'),
    ).toBeUndefined()
    expect(wrapper.find('[role="alert"]').exists()).toBe(false)
  })

  it('shows write errors without claiming success or changing local records', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => undefined)
    files.save.mockRejectedValue(new Error('WRITE_FAILED'))
    const wrapper = await render()
    await wrapper.get('.backup-export-actions .button-primary').trigger('click')
    await flushPromises()
    expect(wrapper.get('[role="alert"]').text()).toContain('저장하지 못했습니다')
    expect(wrapper.find('[role="status"]').exists()).toBe(false)
    expect(wrapper.get('.backup-summary strong').text()).toBe('1')
  })
})
