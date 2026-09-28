export type SiteStatus = 'active' | 'on_hold' | 'completed'

export type WorkerRole = 'supervisor' | 'team_lead' | 'painter' | 'helper'

export type AttendanceStatus =
  'present' | 'half_day' | 'absent' | 'leave' | 'weather' | 'site_closed'

export interface Site {
  id: string
  name: string
  client: string
  address: string
  startDate: string
  endDate: string
  status: SiteStatus
  createdAt: string
}

export interface Worker {
  id: string
  name: string
  phone: string
  team: string
  role: WorkerRole
  dailyRate: number
  active: boolean
  createdAt: string
}

export interface SiteWorkerAssignment {
  id: string
  siteId: string
  workerId: string
  workRole: WorkerRole
  dailyRate: number
  createdAt: string
  updatedAt: string
}

export interface AttendanceRecord {
  id: string
  date: string
  siteId: string
  workerId: string
  workRole: WorkerRole
  status: AttendanceStatus
  startTime: string
  endTime: string
  overtimeHours: number
  dailyRate: number
  note: string
  createdAt: string
  updatedAt: string
}

export interface ErpData {
  sites: Site[]
  workers: Worker[]
  siteWorkerAssignments: SiteWorkerAssignment[]
  attendanceRecords: AttendanceRecord[]
}

export type NewSite = Omit<Site, 'id' | 'createdAt'>
export type NewWorker = Omit<Worker, 'id' | 'createdAt'>
export type SiteWorkerAssignmentInput = Omit<
  SiteWorkerAssignment,
  'id' | 'createdAt' | 'updatedAt'
>
export type AttendanceInput = Omit<AttendanceRecord, 'id' | 'createdAt' | 'updatedAt'>
