import { describe, expect, it } from 'vitest'
import {
  buildSiteCostRows,
  buildSiteLaborRows,
  validateSiteExpense,
} from '@/services/siteCostService'
import type { AttendanceRecord, Site, SiteExpense, SiteExpenseInput } from '@/types/erp'

const sites: Site[] = ['s1', 's2', 's3'].map((id) => ({
  id,
  name: id,
  client: '',
  address: '',
  startDate: '',
  endDate: '',
  status: 'active',
  createdAt: '',
}))
const attendance: AttendanceRecord = {
  id: 'a1',
  date: '2026-09-30',
  siteId: 's1',
  workerId: 'w1',
  workRole: 'painter',
  status: 'present',
  startTime: '',
  endTime: '',
  overtimeHours: 0,
  dailyRate: 170000,
  note: '',
  createdAt: '',
  updatedAt: '',
}
const input: SiteExpenseInput = {
  siteId: 's1',
  date: '2026-09-30',
  description: '점심 식사',
  amount: 85000,
  note: '5명',
}
const expense: SiteExpense = { ...input, id: 'e1', createdAt: '', updatedAt: '' }

describe('site costs', () => {
  it('separates sites/months and includes expense-only sites and multiple daily expenses', () => {
    const rows = buildSiteCostRows(
      sites,
      [
        attendance,
        { ...attendance, id: 'a2', siteId: 's2', dailyRate: 200000 },
        { ...attendance, id: 'old', date: '2026-08-31' },
      ],
      [
        expense,
        { ...expense, id: 'e2', amount: 15000 },
        { ...expense, id: 'e3', siteId: 's3', amount: 32000 },
        { ...expense, id: 'old', date: '2026-08-31' },
      ],
      '2026-09',
    )
    expect(
      rows.map(({ laborCost, expenseCost, totalCost }) => ({ laborCost, expenseCost, totalCost })),
    ).toEqual([
      { laborCost: 170000, expenseCost: 100000, totalCost: 270000 },
      { laborCost: 200000, expenseCost: 0, totalCost: 200000 },
      { laborCost: 0, expenseCost: 32000, totalCost: 32000 },
    ])
  })

  it('uses attendance snapshots and handles half days, overtime and absence', () => {
    const rows = buildSiteLaborRows(
      [
        attendance,
        { ...attendance, id: 'a2', dailyRate: 200000, status: 'half_day', overtimeHours: 2 },
        { ...attendance, id: 'a3', status: 'absent' },
      ],
      [],
    )
    expect(rows[0]).toMatchObject({
      workedDays: 1.5,
      overtimeHours: 2,
      minimumRate: 170000,
      maximumRate: 200000,
      laborCost: 345000,
    })
  })

  it.each([
    { amount: -1 },
    { amount: 0 },
    { amount: 1.5 },
    { amount: NaN },
    { date: '2026-02-30' },
    { date: '' },
    { siteId: '' },
    { description: '  ' },
  ])('rejects invalid expense input %j', (change) => {
    expect(validateSiteExpense({ ...input, ...change })).not.toBe('')
  })
})
