import type { AttendanceRecord, AttendanceStatus } from '@/types/erp'

const WORKDAY_HOURS = 8
const OVERTIME_MULTIPLIER = 1.5

const statusDayFactor: Record<AttendanceStatus, number> = {
  present: 1,
  half_day: 0.5,
  absent: 0,
  leave: 0,
  weather: 0,
  site_closed: 0,
}

export const calculateLaborCost = (
  record: Pick<AttendanceRecord, 'status' | 'dailyRate' | 'overtimeHours'>,
): number => {
  const baseCost = record.dailyRate * statusDayFactor[record.status]
  const overtimeCost =
    record.status === 'present' || record.status === 'half_day'
      ? (record.dailyRate / WORKDAY_HOURS) * OVERTIME_MULTIPLIER * record.overtimeHours
      : 0

  return Math.round(baseCost + overtimeCost)
}

export const sumLaborCost = (
  records: Array<Pick<AttendanceRecord, 'status' | 'dailyRate' | 'overtimeHours'>>,
): number => records.reduce((total, record) => total + calculateLaborCost(record), 0)

export const calculateWorkedDays = (records: Array<Pick<AttendanceRecord, 'status'>>): number =>
  records.reduce((total, record) => total + statusDayFactor[record.status], 0)
