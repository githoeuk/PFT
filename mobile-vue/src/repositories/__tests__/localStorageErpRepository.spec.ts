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
})

describe('localStorageErpRepository', () => {
  beforeEach(() => window.localStorage.clear())

  it('loads legacy data without payroll settlements', async () => {
    const { payrollSettlements: _payrollSettlements, ...legacyData } = emptyData()
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(legacyData))

    const loaded = await localStorageErpRepository.load()

    expect(loaded.payrollSettlements).toEqual([])
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
