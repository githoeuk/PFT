import { calculateWorkedDays, sumLaborCost } from '@/services/attendanceService'
import type { AttendanceRecord, Site, SiteExpense, SiteExpenseInput, Worker } from '@/types/erp'

export function validateSiteExpense(input: SiteExpenseInput): string {
  if (!input.siteId) return '현장을 선택해 주세요.'
  if (!/^\d{4}-\d{2}-\d{2}$/.test(input.date)) return '날짜를 확인해 주세요.'
  const date = new Date(`${input.date}T00:00:00.000Z`)
  if (!Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10) !== input.date) {
    return '날짜를 확인해 주세요.'
  }
  if (!input.description.trim() || input.description.trim().length > 120) {
    return '경비 내용을 1~120자로 입력해 주세요.'
  }
  if (!Number.isSafeInteger(input.amount) || input.amount <= 0) {
    return '금액은 1원 이상의 정수로 입력해 주세요.'
  }
  if (input.note.length > 500) return '비고는 500자 이내로 입력해 주세요.'
  return ''
}

export function buildSiteCostRows(
  sites: Site[],
  records: AttendanceRecord[],
  expenses: SiteExpense[],
  month: string,
) {
  const monthRecords = month ? records.filter((record) => record.date.slice(0, 7) === month) : []
  const monthExpenses = month
    ? expenses.filter((expense) => expense.date.slice(0, 7) === month)
    : []
  const siteIds = new Set([
    ...sites.map((site) => site.id),
    ...monthRecords.map((record) => record.siteId),
    ...monthExpenses.map((expense) => expense.siteId),
  ])
  return [...siteIds]
    .map((siteId) => {
      const site = sites.find((item) => item.id === siteId)
      const siteRecords = monthRecords.filter((record) => record.siteId === siteId)
      const siteExpenses = monthExpenses.filter((expense) => expense.siteId === siteId)
      const laborCost = sumLaborCost(siteRecords)
      const expenseCost = siteExpenses.reduce((total, expense) => total + expense.amount, 0)
      return {
        siteId,
        site,
        siteName: site?.name ?? '삭제된 현장',
        laborCost,
        expenseCost,
        totalCost: laborCost + expenseCost,
        workedDays: calculateWorkedDays(siteRecords),
        expenseCount: siteExpenses.length,
      }
    })
    .sort((a, b) => a.siteName.localeCompare(b.siteName, 'ko'))
}

export function buildSiteLaborRows(records: AttendanceRecord[], workers: Worker[]) {
  const byWorker = new Map<string, AttendanceRecord[]>()
  for (const record of records) {
    if (record.status !== 'present' && record.status !== 'half_day') continue
    const group = byWorker.get(record.workerId) ?? []
    group.push(record)
    byWorker.set(record.workerId, group)
  }
  return [...byWorker]
    .map(([workerId, entries]) => ({
      workerId,
      workerName: workers.find((worker) => worker.id === workerId)?.name ?? '삭제된 근로자',
      roles: [...new Set(entries.map((record) => record.workRole))],
      workedDays: calculateWorkedDays(entries),
      overtimeHours: entries.reduce((total, record) => total + record.overtimeHours, 0),
      minimumRate: Math.min(...entries.map((record) => record.dailyRate)),
      maximumRate: Math.max(...entries.map((record) => record.dailyRate)),
      laborCost: sumLaborCost(entries),
    }))
    .sort((a, b) => a.workerName.localeCompare(b.workerName, 'ko'))
}
