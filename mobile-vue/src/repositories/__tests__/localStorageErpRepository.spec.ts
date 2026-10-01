import { beforeEach, describe, expect, it } from 'vitest'

import { localStorageErpRepository } from '@/repositories/localStorageErpRepository'
import type { ErpData, PayrollSettlement } from '@/types/erp'

const STORAGE_KEY = 'pft.erp.v1'

const emptyData = (): ErpData => ({
  sites: [],
  workers: [],
  siteWorkerAssignments: [],
  attendanceRecords: [],
  payrollSettlements: [],
  siteExpenses: [],
})

describe('localStorageErpRepository', () => {
  beforeEach(() => window.localStorage.clear())

  it.each(['', '{bad json', '{}', 'null', JSON.stringify({ ...emptyData(), siteExpenses: null })])(
    'rejects unreadable data instead of treating it as an empty database: %s',
    async (raw) => {
      window.localStorage.setItem(STORAGE_KEY, raw)
      await expect(localStorageErpRepository.load()).rejects.toThrow('원본은 변경하지 않았습니다')
      expect(window.localStorage.getItem(STORAGE_KEY)).toBe(raw)
    },
  )

  it('returns an empty database only when no saved key exists', async () => {
    await expect(localStorageErpRepository.load()).resolves.toEqual(emptyData())
  })

  it('loads legacy data without payroll settlements', async () => {
    const { payrollSettlements: _payrollSettlements, ...legacyData } = emptyData()
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(legacyData))

    const loaded = await localStorageErpRepository.load()

    expect(loaded.payrollSettlements).toEqual([])
  })

  it('adds empty bank account fields to legacy workers', async () => {
    const legacyData = {
      ...emptyData(),
      workers: [
        {
          id: 'worker-1',
          name: '기존 근로자',
          phone: '',
          team: '',
          role: 'painter',
          dailyRate: 180_000,
          active: true,
          createdAt: '2026-09-01T00:00:00.000Z',
        },
      ],
    }
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(legacyData))

    const loaded = await localStorageErpRepository.load()

    expect(loaded.workers[0]).toMatchObject({
      bankName: '',
      accountNumber: '',
      accountHolder: '',
    })
  })

  it('persists payroll settlements', async () => {
    const settlement: PayrollSettlement = {
      id: 'settlement-1',
      month: '2026-09',
      workerId: 'worker-1',
      status: 'paid',
      settledAmount: 200_000,
      paidDate: '2026-09-30',
      note: '계좌 이체',
      createdAt: '2026-09-30T00:00:00.000Z',
      updatedAt: '2026-09-30T00:00:00.000Z',
    }
    const data = emptyData()
    data.payrollSettlements.push(settlement)

    await localStorageErpRepository.save(data)
    const loaded = await localStorageErpRepository.load()

    expect(loaded.payrollSettlements).toEqual([settlement])
  })
})
