import { describe, expect, it } from 'vitest'

import { calculateLaborCost, calculateWorkedDays, sumLaborCost } from '@/services/attendanceService'

describe('attendanceService', () => {
  it('calculates a full day with overtime', () => {
    expect(calculateLaborCost({ status: 'present', dailyRate: 160_000, overtimeHours: 2 })).toBe(
      220_000,
    )
  })

  it('calculates half-day labor without overtime', () => {
    expect(calculateLaborCost({ status: 'half_day', dailyRate: 180_000, overtimeHours: 0 })).toBe(
      90_000,
    )
  })

  it('does not assign labor cost to non-working statuses', () => {
    expect(calculateLaborCost({ status: 'absent', dailyRate: 200_000, overtimeHours: 3 })).toBe(0)
  })

  it('sums multiple attendance records', () => {
    expect(
      sumLaborCost([
        { status: 'present', dailyRate: 160_000, overtimeHours: 0 },
        { status: 'half_day', dailyRate: 180_000, overtimeHours: 0 },
      ]),
    ).toBe(250_000)
  })

  it('counts full and half work days', () => {
    expect(
      calculateWorkedDays([{ status: 'present' }, { status: 'half_day' }, { status: 'absent' }]),
    ).toBe(1.5)
  })
})
