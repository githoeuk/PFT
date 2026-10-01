import { beforeEach, describe, expect, it } from 'vitest'
import { createPinia, setActivePinia } from 'pinia'

import { useErpStore } from '@/stores/erp'
import { localStorageErpRepository } from '@/repositories/localStorageErpRepository'
import type { ErpData } from '@/types/erp'

describe('erp store worker bank account', () => {
  beforeEach(() => {
    window.localStorage.clear()
    setActivePinia(createPinia())
  })

  it('clears only the selected worker bank account fields', async () => {
    const store = useErpStore()
    await store.hydrate()
    store.workers = [
      {
        id: 'worker-1',
        name: '홍길동',
        phone: '010-0000-0000',
        team: '도장팀',
        role: 'painter',
        dailyRate: 180_000,
        bankName: '국민은행',
        accountNumber: '123-456-789012',
        accountHolder: '홍길동',
        active: true,
        createdAt: '2026-09-01T00:00:00.000Z',
      },
    ]

    await store.clearWorkerBankAccount('worker-1')

    expect(store.workers[0]).toMatchObject({
      name: '홍길동',
      dailyRate: 180_000,
      bankName: '',
      accountNumber: '',
      accountHolder: '',
    })
  })

  it('replaces and persists all data when restoring a backup', async () => {
    const store = useErpStore()
    await store.hydrate()
    const restored: ErpData = {
      sites: [
        {
          id: 'site-restore',
          name: '복원 현장',
          client: '',
          address: '',
          startDate: '2026-09-30',
          endDate: '',
          status: 'active',
          createdAt: '2026-09-30T00:00:00.000Z',
        },
      ],
      workers: [],
      siteWorkerAssignments: [],
      attendanceRecords: [],
      payrollSettlements: [],
      siteExpenses: [],
    }

    await store.restoreData(restored)

    expect(store.sites).toEqual(restored.sites)
    await expect(localStorageErpRepository.load()).resolves.toEqual(restored)
  })
})
