import type { ErpRepository } from '@/repositories/erpRepository'
import type { ErpData } from '@/types/erp'

const STORAGE_KEY = 'pft.erp.v1'

const emptyData = (): ErpData => ({
  sites: [],
  workers: [],
  siteWorkerAssignments: [],
  attendanceRecords: [],
  payrollSettlements: [],
  siteExpenses: [],
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
    if (serialized === null) return emptyData()

    try {
      const parsed: unknown = JSON.parse(serialized)
      if (!isErpData(parsed)) throw new Error('Invalid ERP data')
      for (const key of ['siteWorkerAssignments', 'payrollSettlements', 'siteExpenses'] as const) {
        if (key in parsed && !Array.isArray(parsed[key])) throw new Error(`Invalid ${key}`)
      }

      return {
        ...parsed,
        siteExpenses: Array.isArray(parsed.siteExpenses) ? parsed.siteExpenses : [],
        workers: parsed.workers.map((worker) => ({
          ...worker,
          bankName: typeof worker.bankName === 'string' ? worker.bankName : '',
          accountNumber: typeof worker.accountNumber === 'string' ? worker.accountNumber : '',
          accountHolder: typeof worker.accountHolder === 'string' ? worker.accountHolder : '',
        })),
        siteWorkerAssignments: Array.isArray(parsed.siteWorkerAssignments)
          ? parsed.siteWorkerAssignments
          : [],
        payrollSettlements: Array.isArray(parsed.payrollSettlements)
          ? parsed.payrollSettlements
          : [],
      }
    } catch {
      throw new Error('저장된 데이터 형식을 읽지 못했습니다. 원본은 변경하지 않았습니다.')
    }
  }

  async save(data: ErpData): Promise<void> {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(data))
  }
}

export const localStorageErpRepository: ErpRepository = new LocalStorageErpRepository()
