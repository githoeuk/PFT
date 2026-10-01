import { createPinia } from 'pinia'
import { flushPromises, mount } from '@vue/test-utils'
import { afterEach, describe, expect, it, vi } from 'vitest'
import SiteCostPanel from '@/components/payroll/SiteCostPanel.vue'
import { useErpStore } from '@/stores/erp'
import { localStorageErpRepository } from '@/repositories/localStorageErpRepository'

describe('daily site expenses', () => {
  afterEach(() => vi.restoreAllMocks())

  it('adds multiple expenses on a day, edits, filters and deletes without changing wages', async () => {
    window.localStorage.clear()
    const pinia = createPinia()
    const store = useErpStore(pinia)
    await store.hydrate()
    await store.addSite({
      name: '테스트 현장',
      client: '',
      address: '',
      startDate: '',
      endDate: '',
      status: 'active',
    })
    const wrapper = mount(SiteCostPanel, {
      props: { month: '2026-09' },
      global: { plugins: [pinia] },
    })
    const addButton = () =>
      wrapper.findAll('button').find((button) => button.text() === '경비 추가')!
    const fillAndSave = async (description: string, amount: number) => {
      await wrapper.get('input[type="date"]').setValue('2026-09-30')
      await wrapper.get('input[type="text"]').setValue(description)
      await wrapper.get('input[type="number"]').setValue(amount)
      await wrapper.get('form').trigger('submit')
      await flushPromises()
    }

    await addButton().trigger('click')
    await fillAndSave('점심 식사', 85000)
    await addButton().trigger('click')
    await fillAndSave('음료', 15000)
    expect(store.siteExpenses).toHaveLength(2)
    expect(wrapper.get('.cost-table tbody').text()).toContain('100,000')

    await wrapper.findAll('button[title="경비 수정"]')[0]!.trigger('click')
    await fillAndSave('음료 수정', 20000)
    expect(store.siteExpenses).toHaveLength(2)
    expect(wrapper.get('.cost-table tbody').text()).toContain('105,000')
    expect((await localStorageErpRepository.load()).siteExpenses).toEqual(
      store.exportData().siteExpenses,
    )

    await wrapper.get('.expense-toolbar input').setValue('2026-09-01')
    expect(wrapper.text()).toContain('선택한 기간의 경비가 없습니다')
    await wrapper.get('button[title="날짜 필터 초기화"]').trigger('click')
    expect(wrapper.findAll('.expense-table tbody tr')).toHaveLength(2)
    vi.spyOn(window, 'confirm').mockReturnValue(false)
    await wrapper.findAll('button[title="경비 삭제"]')[0]!.trigger('click')
    expect(store.siteExpenses).toHaveLength(2)
    vi.mocked(window.confirm).mockReturnValue(true)
    await wrapper.findAll('button[title="경비 삭제"]')[0]!.trigger('click')
    await flushPromises()
    expect(store.siteExpenses).toHaveLength(1)
    expect(store.payrollSettlements).toEqual([])
  })

  it('keeps existing expenses when storage fails', async () => {
    window.localStorage.clear()
    const pinia = createPinia()
    const store = useErpStore(pinia)
    await store.hydrate()
    store.sites = [
      {
        id: 's1',
        name: '현장',
        client: '',
        address: '',
        startDate: '',
        endDate: '',
        status: 'active',
        createdAt: '',
      },
    ]
    vi.spyOn(localStorageErpRepository, 'save').mockRejectedValue(new Error('disk full'))
    await expect(
      store.saveSiteExpense({
        siteId: 's1',
        date: '2026-09-30',
        description: '식비',
        amount: 85000,
        note: '',
      }),
    ).rejects.toThrow('disk full')
    expect(store.siteExpenses).toEqual([])
  })

  it('keeps expenses when ordinary ERP edits are queued at the same time', async () => {
    window.localStorage.clear()
    const pinia = createPinia()
    const store = useErpStore(pinia)
    await store.hydrate()
    const site = {
      name: '현장',
      client: '',
      address: '',
      startDate: '',
      endDate: '',
      status: 'active' as const,
    }
    await store.addSite(site)
    const id = store.sites[0]!.id
    const save = store.saveSiteExpense({
      siteId: id,
      date: '2026-09-30',
      description: '식비',
      amount: 85000,
      note: '',
    })
    const edit = store.updateSite(id, { ...site, name: '수정된 현장' })
    await save
    await edit
    await flushPromises()
    const loaded = await localStorageErpRepository.load()
    expect(loaded.siteExpenses).toHaveLength(1)
    expect(loaded.sites[0]!.name).toBe('수정된 현장')
  })
})
