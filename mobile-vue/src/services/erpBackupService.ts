import type {
  AttendanceRecord,
  ErpData,
  PayrollSettlement,
  Site,
  SiteWorkerAssignment,
  Worker,
  SiteExpense,
} from '@/types/erp'
import { validateSiteExpense } from '@/services/siteCostService'

export const ERP_BACKUP_FORMAT = 'pft-erp-backup'
export const ERP_BACKUP_VERSION = 2

export interface ErpBackupFile {
  format: typeof ERP_BACKUP_FORMAT
  version: typeof ERP_BACKUP_VERSION
  exportedAt: string
  data: ErpData
}

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null && !Array.isArray(value)

const hasString = (value: Record<string, unknown>, key: string): boolean =>
  typeof value[key] === 'string'

const hasNumber = (value: Record<string, unknown>, key: string): boolean =>
  typeof value[key] === 'number' && Number.isFinite(value[key])

const isSite = (value: unknown): value is Site =>
  isRecord(value) &&
  ['id', 'name', 'client', 'address', 'startDate', 'endDate', 'status', 'createdAt'].every((key) =>
    hasString(value, key),
  )

const isWorker = (value: unknown): value is Worker =>
  isRecord(value) &&
  [
    'id',
    'name',
    'phone',
    'team',
    'role',
    'bankName',
    'accountNumber',
    'accountHolder',
    'createdAt',
  ].every((key) => hasString(value, key)) &&
  hasNumber(value, 'dailyRate') &&
  typeof value.active === 'boolean'

const isAssignment = (value: unknown): value is SiteWorkerAssignment =>
  isRecord(value) &&
  ['id', 'siteId', 'workerId', 'workRole', 'createdAt', 'updatedAt'].every((key) =>
    hasString(value, key),
  ) &&
  hasNumber(value, 'dailyRate')

const isAttendance = (value: unknown): value is AttendanceRecord =>
  isRecord(value) &&
  [
    'id',
    'date',
    'siteId',
    'workerId',
    'workRole',
    'status',
    'startTime',
    'endTime',
    'note',
    'createdAt',
    'updatedAt',
  ].every((key) => hasString(value, key)) &&
  hasNumber(value, 'overtimeHours') &&
  hasNumber(value, 'dailyRate')

const isSettlement = (value: unknown): value is PayrollSettlement =>
  isRecord(value) &&
  ['id', 'month', 'workerId', 'status', 'paidDate', 'note', 'createdAt', 'updatedAt'].every((key) =>
    hasString(value, key),
  ) &&
  hasNumber(value, 'settledAmount')

const isExpense = (value: unknown): value is SiteExpense => {
  if (
    !isRecord(value) ||
    !['id', 'siteId', 'date', 'description', 'note', 'createdAt', 'updatedAt'].every((key) =>
      hasString(value, key),
    ) ||
    !hasNumber(value, 'amount')
  )
    return false
  return Boolean(value.id) && validateSiteExpense(value as unknown as SiteExpense) === ''
}

const isErpData = (value: unknown): value is ErpData => {
  if (!isRecord(value)) return false
  const sites = value.sites

  return (
    Array.isArray(sites) &&
    sites.every(isSite) &&
    Array.isArray(value.workers) &&
    value.workers.every(isWorker) &&
    Array.isArray(value.siteWorkerAssignments) &&
    value.siteWorkerAssignments.every(isAssignment) &&
    Array.isArray(value.attendanceRecords) &&
    value.attendanceRecords.every(isAttendance) &&
    Array.isArray(value.payrollSettlements) &&
    value.payrollSettlements.every(isSettlement) &&
    Array.isArray(value.siteExpenses) &&
    value.siteExpenses.every(isExpense) &&
    new Set(value.siteExpenses.map((expense) => expense.id)).size === value.siteExpenses.length &&
    value.siteExpenses.every((expense) => sites.some((site) => site.id === expense.siteId))
  )
}

export function createErpBackup(
  data: ErpData,
  exportedAt = new Date().toISOString(),
): ErpBackupFile {
  return {
    format: ERP_BACKUP_FORMAT,
    version: ERP_BACKUP_VERSION,
    exportedAt,
    data,
  }
}

export function serializeErpBackup(backup: ErpBackupFile): string {
  return JSON.stringify(backup, null, 2)
}

export function parseErpBackup(serialized: string): ErpBackupFile {
  let value: unknown

  try {
    value = JSON.parse(serialized)
  } catch {
    throw new Error('JSON 형식이 올바르지 않습니다')
  }

  if (!isRecord(value) || value.format !== ERP_BACKUP_FORMAT) {
    throw new Error('태광페인트 앱에서 만든 백업 파일이 아닙니다')
  }

  if (value.version !== 1 && value.version !== ERP_BACKUP_VERSION) {
    throw new Error('현재 앱에서 지원하지 않는 백업 버전입니다')
  }

  // Version 1 predates daily expenses. Upgrade only genuinely missing fields.
  const data =
    value.version === 1 && isRecord(value.data) && !('siteExpenses' in value.data)
      ? { ...value.data, siteExpenses: [] }
      : value.data

  if (typeof value.exportedAt !== 'string' || !isErpData(data)) {
    throw new Error('백업 파일의 데이터가 손상되었거나 누락되었습니다')
  }

  return {
    format: ERP_BACKUP_FORMAT,
    version: ERP_BACKUP_VERSION,
    exportedAt: value.exportedAt,
    data,
  }
}
