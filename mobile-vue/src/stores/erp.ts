import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

import type { ErpRepository } from '@/repositories/erpRepository'
import { localStorageErpRepository } from '@/repositories/localStorageErpRepository'
import { createErpRepository } from '@/repositories/repositoryFactory'
import { calculateLaborCost, sumLaborCost } from '@/services/attendanceService'
import type {
  AttendanceInput,
  AttendanceRecord,
  NewSite,
  NewWorker,
  Site,
  SiteStatus,
  Worker,
} from '@/types/erp'
import { todayIso } from '@/utils/formatters'

const createId = (prefix: string): string =>
  `${prefix}_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`

export const useErpStore = defineStore('erp', () => {
  const sites = ref<Site[]>([])
  const workers = ref<Worker[]>([])
  const attendanceRecords = ref<AttendanceRecord[]>([])
  const hydrated = ref(false)
  const storageMode = ref<ErpRepository['kind']>('browser')
  const storageError = ref('')

  let repository: ErpRepository = localStorageErpRepository
  let persistQueue = Promise.resolve()

  const activeSites = computed(() => sites.value.filter((site) => site.status === 'active'))
  const activeWorkers = computed(() => workers.value.filter((worker) => worker.active))
  const todayRecords = computed(() =>
    attendanceRecords.value.filter((record) => record.date === todayIso()),
  )
  const currentMonthLaborCost = computed(() => {
    const month = todayIso().slice(0, 7)
    return sumLaborCost(attendanceRecords.value.filter((record) => record.date.startsWith(month)))
  })

  const snapshot = () => ({
    sites: sites.value.map((site) => ({ ...site })),
    workers: workers.value.map((worker) => ({ ...worker })),
    attendanceRecords: attendanceRecords.value.map((record) => ({ ...record })),
  })

  const persist = () => {
    const data = snapshot()
    persistQueue = persistQueue
      .then(() => repository.save(data))
      .then(() => {
        storageError.value = ''
      })
      .catch((error: unknown) => {
        console.error('Failed to save ERP data', error)
        storageError.value = '로컬 데이터를 저장하지 못했습니다'
      })
  }

  async function hydrate(): Promise<void> {
    if (hydrated.value) return

    try {
      repository = await createErpRepository()
      storageMode.value = repository.kind
      const data = await repository.load()
      const workerRoles = new Map(data.workers.map((worker) => [worker.id, worker.role]))
      sites.value = data.sites
      workers.value = data.workers
      attendanceRecords.value = data.attendanceRecords.map((record) => ({
        ...record,
        workRole: record.workRole || workerRoles.get(record.workerId) || 'painter',
      }))
    } catch (error) {
      console.error('Failed to load ERP data', error)
      storageError.value = '로컬 저장소를 열지 못했습니다'
    } finally {
      hydrated.value = true
    }
  }

  function addSite(input: NewSite) {
    sites.value.unshift({ ...input, id: createId('site'), createdAt: new Date().toISOString() })
    persist()
  }

  function updateSite(siteId: string, input: NewSite) {
    const site = sites.value.find((candidate) => candidate.id === siteId)
    if (!site) return
    Object.assign(site, input)
    persist()
  }

  function updateSiteStatus(siteId: string, status: SiteStatus) {
    const site = sites.value.find((candidate) => candidate.id === siteId)
    if (!site) return
    site.status = status
    persist()
  }

  function addWorker(input: NewWorker) {
    workers.value.unshift({ ...input, id: createId('worker'), createdAt: new Date().toISOString() })
    persist()
  }

  function updateWorker(workerId: string, input: NewWorker) {
    const worker = workers.value.find((candidate) => candidate.id === workerId)
    if (!worker) return
    Object.assign(worker, input)
    persist()
  }

  function toggleWorker(workerId: string) {
    const worker = workers.value.find((candidate) => candidate.id === workerId)
    if (!worker) return
    worker.active = !worker.active
    persist()
  }

  function upsertAttendance(input: AttendanceInput): AttendanceRecord {
    const existing = attendanceRecords.value.find(
      (record) =>
        record.date === input.date &&
        record.siteId === input.siteId &&
        record.workerId === input.workerId,
    )
    const now = new Date().toISOString()

    if (existing) {
      Object.assign(existing, input, { updatedAt: now })
      persist()
      return existing
    }

    const created: AttendanceRecord = {
      ...input,
      id: createId('attendance'),
      createdAt: now,
      updatedAt: now,
    }
    attendanceRecords.value.push(created)
    persist()
    return created
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

  return {
    sites,
    workers,
    attendanceRecords,
    hydrated,
    storageMode,
    storageError,
    activeSites,
    activeWorkers,
    todayRecords,
    currentMonthLaborCost,
    hydrate,
    addSite,
    updateSite,
    updateSiteStatus,
    addWorker,
    updateWorker,
    toggleWorker,
    upsertAttendance,
    attendanceFor,
    laborCostFor,
  }
})
