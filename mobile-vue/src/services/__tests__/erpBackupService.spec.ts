import { describe, expect, it } from 'vitest'

import { createErpBackup, parseErpBackup, serializeErpBackup } from '@/services/erpBackupService'
import type { ErpData } from '@/types/erp'

const data: ErpData = {
  sites: [],
  workers: [],
  siteWorkerAssignments: [],
  attendanceRecords: [],
  payrollSettlements: [],
  siteExpenses: [],
}

describe('erpBackupService', () => {
  it('serializes and parses a versioned ERP backup', () => {
    const backup = createErpBackup(data, '2026-09-30T10:00:00.000Z')

    expect(parseErpBackup(serializeErpBackup(backup))).toEqual(backup)
  })

  it('rejects JSON that was not created by this app', () => {
    expect(() => parseErpBackup(JSON.stringify({ data }))).toThrow(
      '태광페인트 앱에서 만든 백업 파일이 아닙니다',
    )
  })

  it('rejects a backup with incomplete ERP data', () => {
    const backup = createErpBackup(data)
    const { workers: _workers, ...incompleteData } = backup.data

    expect(() => parseErpBackup(JSON.stringify({ ...backup, data: incompleteData }))).toThrow(
      '백업 파일의 데이터가 손상되었거나 누락되었습니다',
    )
  })

  it('upgrades old backups without expenses and preserves the rest of the data', () => {
    const { siteExpenses: _expenses, ...legacy } = data
    const restored = parseErpBackup(
      JSON.stringify({ ...createErpBackup(data), version: 1, data: legacy }),
    )
    expect(restored.version).toBe(2)
    expect(restored.data).toEqual(data)
  })

  it('rejects a v2 backup without expenses instead of silently dropping them', () => {
    const { siteExpenses: _expenses, ...missing } = data
    expect(() =>
      parseErpBackup(JSON.stringify({ ...createErpBackup(data), data: missing })),
    ).toThrow('누락')
  })

  it('round-trips expenses and rejects invalid amounts, duplicates and missing sites', () => {
    const site = {
      id: 's1',
      name: '현장',
      client: '',
      address: '',
      startDate: '',
      endDate: '',
      status: 'active' as const,
      createdAt: '2026-09-30',
    }
    const expense = {
      id: 'e1',
      siteId: site.id,
      date: '2026-09-30',
      description: '점심 식사',
      amount: 85000,
      note: '5명',
      createdAt: '2026-09-30',
      updatedAt: '2026-09-30',
    }
    const backup = createErpBackup({ ...data, sites: [site], siteExpenses: [expense] })
    expect(parseErpBackup(serializeErpBackup(backup)).data.siteExpenses).toEqual([expense])
    for (const expenses of [
      [{ ...expense, amount: -1 }],
      [expense, expense],
      [{ ...expense, siteId: 'missing' }],
    ]) {
      expect(() =>
        parseErpBackup(
          JSON.stringify({ ...backup, data: { ...backup.data, siteExpenses: expenses } }),
        ),
      ).toThrow('손상')
    }
  })
})
