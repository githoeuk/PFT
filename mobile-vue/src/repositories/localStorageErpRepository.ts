import type { ErpRepository } from '@/repositories/erpRepository'
import type { ErpData } from '@/types/erp'

const STORAGE_KEY = 'pft.erp.v1'

const emptyData = (): ErpData => ({
  sites: [],
  workers: [],
  siteWorkerAssignments: [],
  attendanceRecords: [],
  payrollSettlements: [],
})

const isErpData = (value: unknown): value is ErpData => {
  if (!value || typeof value !== 'object') return false

  const candidate = value as Partial<ErpData>
  return (
    Array.isArray(candidate.sites) &&
    Array.isArray(candidate.workers) &&
    Array.isArray(candidate.attendanceRecords)
  )
}

class LocalStorageErpRepository implements ErpRepository {
  readonly kind = 'browser' as const

  async load(): Promise<ErpData> {
    const serialized = window.localStorage.getItem(STORAGE_KEY)
    if (!serialized) return emptyData()

    try {
      const parsed: unknown = JSON.parse(serialized)
      if (!isErpData(parsed)) return emptyData()

      return {
        ...parsed,
        siteWorkerAssignments: Array.isArray(parsed.siteWorkerAssignments)
          ? parsed.siteWorkerAssignments
          : [],
        payrollSettlements: Array.isArray(parsed.payrollSettlements)
          ? parsed.payrollSettlements
          : [],
      }
    } catch {
      return emptyData()
    }
  }

  async save(data: ErpData): Promise<void> {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(data))
  }
}

export const localStorageErpRepository: ErpRepository = new LocalStorageErpRepository()
