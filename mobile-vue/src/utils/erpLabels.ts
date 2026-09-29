import type { AttendanceStatus, PayrollSettlementStatus, SiteStatus, WorkerRole } from '@/types/erp'

export const siteStatusLabels: Record<SiteStatus, string> = {
  active: '진행 중',
  on_hold: '보류',
  completed: '완료',
}

export const workerRoleLabels: Record<WorkerRole, string> = {
  supervisor: '현장 관리자',
  team_lead: '팀장',
  painter: '도장공',
  helper: '보조공',
}

export const attendanceStatusLabels: Record<AttendanceStatus, string> = {
  present: '출근',
  half_day: '반일',
  absent: '결근',
  leave: '휴가',
  weather: '우천',
  site_closed: '현장 휴무',
}

export const payrollSettlementStatusLabels: Record<PayrollSettlementStatus, string> = {
  unpaid: '미지급',
  paid: '지급 완료',
}

export const attendanceStatusOptions = Object.entries(attendanceStatusLabels).map(
  ([value, label]) => ({ value: value as AttendanceStatus, label }),
)

export const workerRoleOptions = Object.entries(workerRoleLabels).map(([value, label]) => ({
  value: value as WorkerRole,
  label,
}))
