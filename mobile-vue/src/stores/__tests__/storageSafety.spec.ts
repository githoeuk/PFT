import { createPinia } from 'pinia'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises } from '@vue/test-utils'
import { useErpStore } from '@/stores/erp'
import { localStorageErpRepository as repository } from '@/repositories/localStorageErpRepository'
import * as factory from '@/repositories/repositoryFactory'
import type { AttendanceInput, NewSite } from '@/types/erp'

const siteInput = (name = '보존할 현장'): NewSite => ({
  name,
  client: '',
  address: '',
  startDate: '',
  endDate: '',
  status: 'active',
})
const newStore = () => useErpStore(createPinia())

describe('ERP storage safety', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.spyOn(console, 'error').mockImplementation(() => undefined)
  })
  afterEach(() => vi.restoreAllMocks())

  it('blocks all writes and empty backups after a read failure, and can retry', async () => {
    const original = newStore()
    await original.hydrate()
    await original.addSite(siteInput())
    const saved = original.exportData()
    const load = vi.spyOn(repository, 'load').mockRejectedValueOnce(new Error('database locked'))
    const save = vi.spyOn(repository, 'save')
    const restarted = newStore()
    await restarted.hydrate()
    expect(restarted.hydrated).toBe(false)
    expect(restarted.loadError).toContain('읽지 못했습니다')
    await expect(restarted.addSite(siteInput('새 현장'))).rejects.toThrow('저장소를 읽지 못한 상태')
    await expect(restarted.restoreData(saved)).rejects.toThrow('저장소를 읽지 못한 상태')
    expect(() => restarted.exportData()).toThrow('저장소를 먼저 불러와야')
    expect(save).not.toHaveBeenCalled()
    await restarted.hydrate()
    expect(load).toHaveBeenCalledTimes(2)
    expect(restarted.hydrated).toBe(true)
    expect(restarted.loadError).toBe('')
    expect(restarted.exportData()).toEqual(saved)
  })

  it('does not silently fall back to browser storage when native initialization fails', async () => {
    vi.spyOn(factory, 'createErpRepository').mockRejectedValue(
      new Error('SQLite plugin unavailable'),
    )
    const save = vi.spyOn(repository, 'save')
    const store = newStore()
    await store.hydrate()
    await expect(store.addSite(siteInput())).rejects.toThrow('저장소를 읽지 못한 상태')
    expect(store.hydrated).toBe(false)
    expect(save).not.toHaveBeenCalled()
  })

  it('does not publish unsaved changes and keeps existing records after disk errors', async () => {
    const store = newStore()
    await store.hydrate()
    await store.addSite(siteInput())
    const before = store.exportData()
    vi.spyOn(repository, 'save').mockRejectedValueOnce(new Error('disk full'))
    await expect(store.addSite(siteInput('실패한 현장'))).rejects.toThrow('disk full')
    expect(store.saving).toBe(false)
    expect(store.storageError).toContain('저장하지 못했습니다')
    expect(store.exportData()).toEqual(before)
    const restarted = newStore()
    await restarted.hydrate()
    expect(restarted.exportData()).toEqual(before)
    await store.addSite(siteInput('재시도 성공'))
    expect(store.sites).toHaveLength(2)
    expect(store.storageError).toBe('')
  })

  it('waits for storage acknowledgement before exposing a saved record', async () => {
    const store = newStore()
    await store.hydrate()
    const originalSave = repository.save.bind(repository)
    let finish!: () => void
    vi.spyOn(repository, 'save').mockImplementationOnce(async (data) => {
      await new Promise<void>((resolve) => {
        finish = resolve
      })
      await originalSave(data)
    })
    const pending = store.addSite(siteInput())
    await flushPromises()
    expect(store.saving).toBe(true)
    expect(store.sites).toHaveLength(0)
    finish()
    await pending
    expect(store.saving).toBe(false)
    expect(store.sites).toHaveLength(1)
    await expect(repository.load()).resolves.toEqual(store.exportData())
  })

  it('serializes restore and later edits without dropping either operation', async () => {
    const store = newStore()
    await store.hydrate()
    await store.addSite(siteInput())
    const backup = store.exportData()
    const restore = store.restoreData(backup)
    const edit = store.addSite(siteInput('복원 후 추가'))
    await Promise.all([restore, edit])
    const restarted = newStore()
    await restarted.hydrate()
    expect(restarted.sites.map((site) => site.name)).toEqual(['복원 후 추가', '보존할 현장'])
  })

  it('saves the full attendance batch once and retains drafts on failure', async () => {
    const store = newStore()
    await store.hydrate()
    await store.addSite(siteInput())
    await store.addWorker({
      name: '근로자',
      phone: '',
      team: '',
      role: 'painter',
      dailyRate: 170000,
      bankName: '',
      accountNumber: '',
      accountHolder: '',
      active: true,
    })
    const entries: AttendanceInput[] = ['2026-09-28', '2026-09-29'].map((date) => ({
      date,
      siteId: store.sites[0]!.id,
      workerId: store.workers[0]!.id,
      workRole: 'painter',
      status: 'present',
      startTime: '08:00',
      endTime: '17:00',
      overtimeHours: 0,
      dailyRate: 170000,
      note: '보존할 입력',
    }))
    const save = vi.spyOn(repository, 'save').mockRejectedValueOnce(new Error('disk full'))
    await expect(store.saveAttendanceRecords(entries)).rejects.toThrow('disk full')
    expect(store.attendanceRecords).toEqual([])
    expect(entries[0]!.note).toBe('보존할 입력')
    await store.saveAttendanceRecords(entries)
    expect(save).toHaveBeenCalledTimes(2)
    expect(store.attendanceRecords).toHaveLength(2)
    const restarted = newStore()
    await restarted.hydrate()
    expect(restarted.attendanceRecords).toEqual(store.attendanceRecords)
  })
})
