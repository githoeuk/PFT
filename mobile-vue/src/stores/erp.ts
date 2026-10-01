import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

import type { ErpRepository } from '@/repositories/erpRepository'
import { createErpRepository } from '@/repositories/repositoryFactory'
import { calculateLaborCost, sumLaborCost } from '@/services/attendanceService'
import { validateSiteExpense } from '@/services/siteCostService'
import type {
  AttendanceInput,
  AttendanceRecord,
  NewSite,
  NewWorker,
  Site,
  SiteStatus,
  SiteWorkerAssignment,
  SiteWorkerAssignmentInput,
  Worker,
  PayrollSettlement,
  PayrollSettlementInput,
  ErpData,
  SiteExpense,
  SiteExpenseInput,
} from '@/types/erp'
import { todayIso } from '@/utils/formatters'

const createId = (prefix: string): string =>
  `${prefix}_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`

export const useErpStore = defineStore('erp', () => {
  const sites = ref<Site[]>([])
  const workers = ref<Worker[]>([])
  const siteWorkerAssignments = ref<SiteWorkerAssignment[]>([])
  const attendanceRecords = ref<AttendanceRecord[]>([])
  const payrollSettlements = ref<PayrollSettlement[]>([])
  const siteExpenses = ref<SiteExpense[]>([])
  const hydrated = ref(false)
  const loading = ref(false)
  const loadError = ref('')
  const loadErrorDetail = ref('')
  const pendingWrites = ref(0)
  const saving = computed(() => pendingWrites.value > 0)
  const storageMode = ref<ErpRepository['kind']>('browser')
  const storageError = ref('')

  let repository: ErpRepository | undefined
  let persistQueue = Promise.resolve()
  let loadOperation: Promise<void> | undefined

  const activeSites = computed(() => sites.value.filter((site) => site.status === 'active'))
  const activeWorkers = computed(() => workers.value.filter((worker) => worker.active))
  const todayRecords = computed(() =>
    attendanceRecords.value.filter((record) => record.date === todayIso()),
  )
  const currentMonthLaborCost = computed(() => {
    const month = todayIso().slice(0, 7)
    return sumLaborCost(attendanceRecords.value.filter((record) => record.date.startsWith(month)))
  })

  const snapshot = (): ErpData => ({
    sites: sites.value.map((site) => ({ ...site })),
    workers: workers.value.map((worker) => ({ ...worker })),
    siteWorkerAssignments: siteWorkerAssignments.value.map((assignment) => ({ ...assignment })),
    attendanceRecords: attendanceRecords.value.map((record) => ({ ...record })),
    payrollSettlements: payrollSettlements.value.map((settlement) => ({ ...settlement })),
    siteExpenses: siteExpenses.value.map((expense) => ({ ...expense })),
  })

  const applyData = (data: ErpData): void => {
    sites.value = data.sites.map((site) => ({ ...site }))
    workers.value = data.workers.map((worker) => ({ ...worker }))
    siteWorkerAssignments.value = data.siteWorkerAssignments.map((assignment) => ({
      ...assignment,
    }))
    attendanceRecords.value = data.attendanceRecords.map((record) => ({ ...record }))
    payrollSettlements.value = data.payrollSettlements.map((settlement) => ({ ...settlement }))
    siteExpenses.value = data.siteExpenses.map((expense) => ({ ...expense }))
  }

  function hydrate(): Promise<void> {
    if (hydrated.value) return Promise.resolve()
    if (loadOperation) return loadOperation
    loading.value = true
    loadError.value = ''
    loadErrorDetail.value = ''
    loadOperation = (async () => {
      try {
        repository ??= await createErpRepository()
        storageMode.value = repository.kind
        const data = await repository.load()
        const workerRoles = new Map(data.workers.map((worker) => [worker.id, worker.role]))
        applyData({
          ...data,
          attendanceRecords: data.attendanceRecords.map((record) => ({
            ...record,
            workRole: record.workRole || workerRoles.get(record.workerId) || 'painter',
          })),
          siteExpenses: data.siteExpenses ?? [],
        })
        hydrated.value = true
        storageError.value = ''
      } catch (error) {
        console.error('Failed to load ERP data', error)
        loadErrorDetail.value = error instanceof Error ? error.message : String(error)
        loadError.value =
          '저장된 데이터를 읽지 못했습니다. 기존 데이터 보호를 위해 입력을 중단했습니다.'
      } finally {
        loading.value = false
        loadOperation = undefined
      }
    })()
    return loadOperation
  }

  function exportData(): ErpData {
    if (!hydrated.value) throw new Error('저장소를 먼저 불러와야 합니다.')
    return snapshot()
  }

  // Keep memory and disk in sync: serialize writes and publish only committed snapshots.
  function commit<T>(update: (data: ErpData) => T): Promise<T> {
    if (!hydrated.value || !repository) {
      return Promise.reject(new Error('저장소를 읽지 못한 상태에서는 데이터를 변경할 수 없습니다.'))
    }
    const target = repository
    pendingWrites.value += 1
    const operation = persistQueue.then(async () => {
      const data = snapshot()
      const result = update(data)
      await target.save(data)
      applyData(data)
      storageError.value = ''
      return result
    })
    const completed = operation
      .catch((error: unknown) => {
        console.error('Failed to save ERP data', error)
        storageError.value =
          '저장하지 못했습니다. 입력 내용을 유지한 채 다시 저장해 주세요. 저장 공간도 확인해 주세요.'
        throw error
      })
      .finally(() => {
        pendingWrites.value -= 1
      })
    persistQueue = completed.then(
      () => undefined,
      () => undefined,
    )
    return completed
  }

  function saveSiteExpense(input: SiteExpenseInput, expenseId?: string): Promise<void> {
    const error = validateSiteExpense(input)
    if (error) return Promise.reject(new Error(error))
    if (!sites.value.some((site) => site.id === input.siteId)) {
      return Promise.reject(new Error('현장을 찾을 수 없습니다.'))
    }
    const normalized = { ...input, description: input.description.trim(), note: input.note.trim() }
    return commit((data) => {
      const expenses = data.siteExpenses
      const now = new Date().toISOString()
      if (expenseId) {
        const existing = expenses.find((expense) => expense.id === expenseId)
        if (!existing) throw new Error('경비 기록을 찾을 수 없습니다.')
        data.siteExpenses = expenses.map((expense) =>
          expense.id === expenseId ? { ...expense, ...normalized, updatedAt: now } : expense,
        )
        return
      }
      data.siteExpenses.unshift({
        ...normalized,
        id: createId('expense'),
        createdAt: now,
        updatedAt: now,
      })
    })
  }

  function removeSiteExpense(expenseId: string): Promise<void> {
    return commit((data) => {
      data.siteExpenses = data.siteExpenses.filter((expense) => expense.id !== expenseId)
    })
  }

  async function restoreData(data: ErpData): Promise<void> {
    const restored: ErpData = JSON.parse(JSON.stringify(data))
    await commit((current) => {
      Object.assign(current, restored)
    })
  }

  function addSite(input: NewSite) {
    const site = { ...input, id: createId('site'), createdAt: new Date().toISOString() }
    return commit((data) => {
      data.sites.unshift(site)
    })
  }

  function updateSite(siteId: string, input: NewSite) {
    const values = { ...input }
    return commit((data) => {
      const site = data.sites.find((candidate) => candidate.id === siteId)
      if (!site) throw new Error('현장을 찾을 수 없습니다.')
      Object.assign(site, values)
    })
  }

  function updateSiteStatus(siteId: string, status: SiteStatus) {
    return commit((data) => {
      const site = data.sites.find((candidate) => candidate.id === siteId)
      if (!site) throw new Error('현장을 찾을 수 없습니다.')
      site.status = status
    })
  }

  function addWorker(input: NewWorker) {
    const worker = { ...input, id: createId('worker'), createdAt: new Date().toISOString() }
    return commit((data) => {
      data.workers.unshift(worker)
    })
  }

  function updateWorker(workerId: string, input: NewWorker) {
    const values = { ...input }
    return commit((data) => {
      const worker = data.workers.find((candidate) => candidate.id === workerId)
      if (!worker) throw new Error('근로자를 찾을 수 없습니다.')
      Object.assign(worker, values)
    })
  }

  function clearWorkerBankAccount(workerId: string) {
    return commit((data) => {
      const worker = data.workers.find((candidate) => candidate.id === workerId)
      if (!worker) throw new Error('근로자를 찾을 수 없습니다.')
      worker.bankName = ''
      worker.accountNumber = ''
      worker.accountHolder = ''
    })
  }

  function toggleWorker(workerId: string) {
    return commit((data) => {
      const worker = data.workers.find((candidate) => candidate.id === workerId)
      if (!worker) throw new Error('근로자를 찾을 수 없습니다.')
      worker.active = !worker.active
    })
  }

  function upsertSiteWorkerAssignment(
    input: SiteWorkerAssignmentInput,
  ): Promise<SiteWorkerAssignment> {
    const values = { ...input }
    return commit((data) => {
      const existing = data.siteWorkerAssignments.find(
        (assignment) =>
          assignment.siteId === values.siteId && assignment.workerId === values.workerId,
      )
      const now = new Date().toISOString()

      if (existing) {
        Object.assign(existing, values, { updatedAt: now })
        return existing
      }

      const created: SiteWorkerAssignment = {
        ...values,
        id: createId('assignment'),
        createdAt: now,
        updatedAt: now,
      }
      data.siteWorkerAssignments.push(created)
      return created
    })
  }

  function removeSiteWorkerAssignment(assignmentId: string) {
    return commit((data) => {
      data.siteWorkerAssignments = data.siteWorkerAssignments.filter(
        (assignment) => assignment.id !== assignmentId,
      )
    })
  }

  function assignmentsForSite(siteId: string) {
    return siteWorkerAssignments.value.filter((assignment) => assignment.siteId === siteId)
  }

  function upsertAttendanceIn(data: ErpData, input: AttendanceInput): AttendanceRecord {
    const existing = data.attendanceRecords.find(
      (record) =>
        record.date === input.date &&
        record.siteId === input.siteId &&
        record.workerId === input.workerId,
    )
    const now = new Date().toISOString()

    if (existing) {
      Object.assign(existing, input, { updatedAt: now })
      return existing
    }

    const created: AttendanceRecord = {
      ...input,
      id: createId('attendance'),
      createdAt: now,
      updatedAt: now,
    }
    data.attendanceRecords.push(created)
    return created
  }

  function upsertAttendance(input: AttendanceInput): Promise<AttendanceRecord> {
    const values = { ...input }
    return commit((data) => upsertAttendanceIn(data, values))
  }

  function saveAttendanceRecords(inputs: AttendanceInput[]): Promise<AttendanceRecord[]> {
    const records = inputs.map((input) => ({ ...input }))
    return commit((data) => records.map((input) => upsertAttendanceIn(data, input)))
  }

  function attendanceFor(date: string, siteId: string) {
    return attendanceRecords.value.filter(
      (record) => record.date === date && record.siteId === siteId,
    )
  }

  function laborCostFor(date: string, siteId: string): number {
    return attendanceFor(date, siteId).reduce(
      (total, record) => total + calculateLaborCost(record),
      0,
    )
  }

  function payrollSettlementFor(month: string, workerId: string): PayrollSettlement | undefined {
    return payrollSettlements.value.find(
      (settlement) => settlement.month === month && settlement.workerId === workerId,
    )
  }

  function upsertPayrollSettlement(input: PayrollSettlementInput): Promise<PayrollSettlement> {
    const values = { ...input }
    return commit((data) => {
      const existing = data.payrollSettlements.find(
        (settlement) =>
          settlement.month === values.month && settlement.workerId === values.workerId,
      )
      const now = new Date().toISOString()

      if (existing) {
        Object.assign(existing, values, { updatedAt: now })
        return existing
      }

      const created: PayrollSettlement = {
        ...values,
        id: createId('settlement'),
        createdAt: now,
        updatedAt: now,
      }

      data.payrollSettlements.unshift(created)
      return created
    })
  }

  return {
    sites,
    workers,
    siteWorkerAssignments,
    attendanceRecords,
    hydrated,
    loading,
    loadError,
    loadErrorDetail,
    saving,
    storageMode,
    storageError,
    activeSites,
    activeWorkers,
    todayRecords,
    currentMonthLaborCost,
    hydrate,
    exportData,
    restoreData,
    addSite,
    updateSite,
    updateSiteStatus,
    addWorker,
    updateWorker,
    clearWorkerBankAccount,
    toggleWorker,
    upsertSiteWorkerAssignment,
    removeSiteWorkerAssignment,
    assignmentsForSite,
    upsertAttendance,
    saveAttendanceRecords,
    attendanceFor,
    laborCostFor,
    payrollSettlements,
    siteExpenses,
    saveSiteExpense,
    removeSiteExpense,
    payrollSettlementFor,
    upsertPayrollSettlement,
  }
})
