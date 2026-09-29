import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it } from 'vitest'

import { mount } from '@vue/test-utils'
import { todayIso } from '@/utils/formatters'
import { useErpStore } from '@/stores/erp'
import PayrollView from '@/views/PayrollView.vue'

describe('PayrollView', () => {
  beforeEach(() => window.localStorage.clear())

  it('saves a paid monthly settlement for a worker', async () => {
    const pinia = createPinia()
    setActivePinia(pinia)
    const store = useErpStore()
    const month = todayIso().slice(0, 7)

    store.workers = [
      {
        id: 'worker-1',
        name: '근로자 A',
        phone: '',
        team: '도장팀',
        role: 'painter',
        dailyRate: 200_000,
        active: true,
        createdAt: '2026-09-01T00:00:00.000Z',
      },
    ]
    store.sites = [
      {
        id: 'site-1',
        name: '현장 1',
        client: '',
        address: '',
        startDate: `${month}-01`,
        endDate: '',
        status: 'active',
        createdAt: '2026-09-01T00:00:00.000Z',
      },
    ]
    store.attendanceRecords = [
      {
        id: 'attendance-1',
        date: `${month}-01`,
        siteId: 'site-1',
        workerId: 'worker-1',
        workRole: 'painter',
        status: 'present',
        startTime: '08:00',
        endTime: '17:00',
        overtimeHours: 0,
        dailyRate: 200_000,
        note: '',
        createdAt: '2026-09-01T00:00:00.000Z',
        updatedAt: '2026-09-01T00:00:00.000Z',
      },
    ]

    const wrapper = mount(PayrollView, {
      global: {
        plugins: [pinia],
        stubs: {
          RouterLink: { template: '<a><slot /></a>' },
        },
      },
    })

    await wrapper.get('button[title="지급 정보 수정"]').trigger('click')
    await wrapper.get('select').setValue('paid')
    await wrapper.get('input[type="date"]').setValue(`${month}-30`)
    await wrapper.get('input[type="text"]').setValue('계좌 이체')
    await wrapper.get('form').trigger('submit')

    expect(store.payrollSettlements).toHaveLength(1)
    expect(store.payrollSettlements[0]).toMatchObject({
      month,
      workerId: 'worker-1',
      status: 'paid',
      settledAmount: 200_000,
      paidDate: `${month}-30`,
      note: '계좌 이체',
    })
    expect(wrapper.text()).toContain('지급 완료')
  })
})
