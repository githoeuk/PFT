// @vitest-environment node
import { DatabaseSync, type SQLInputValue } from 'node:sqlite'
import { mkdtempSync, rmdirSync, unlinkSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import type { capSQLiteSet } from '@capacitor-community/sqlite'
import type { ErpData } from '@/types/erp'

const connection = vi.hoisted(() => ({ database: {} as unknown }))
vi.mock('@capacitor-community/sqlite', () => ({
  CapacitorSQLite: {},
  SQLiteConnection: class {
    async checkConnectionsConsistency() {
      return {}
    }
    async isConnection() {
      return { result: false }
    }
    async createConnection() {
      return connection.database
    }
  },
}))

import { CapacitorSqliteErpRepository } from '@/repositories/sqliteErpRepository'

let database: DatabaseSync
let databaseDirectory: string | undefined
const sample = (): ErpData => ({
  sites: [
    {
      id: 's1',
      name: '현장',
      client: '',
      address: '',
      startDate: '',
      endDate: '',
      status: 'active',
      createdAt: '',
    },
  ],
  workers: [
    {
      id: 'w1',
      name: '근로자',
      phone: '',
      team: '',
      role: 'painter',
      dailyRate: 170000,
      bankName: '',
      accountNumber: '',
      accountHolder: '',
      active: true,
      createdAt: '',
    },
  ],
  siteWorkerAssignments: [],
  attendanceRecords: [],
  payrollSettlements: [
    {
      id: 'p1',
      month: '2026-09',
      workerId: 'w1',
      status: 'paid',
      settledAmount: 170000,
      paidDate: '2026-09-30',
      note: '',
      createdAt: '',
      updatedAt: '',
    },
  ],
  siteExpenses: [
    {
      id: 'e1',
      siteId: 's1',
      date: '2026-09-30',
      description: '점심 식사',
      amount: 85000,
      note: '5명',
      createdAt: '',
      updatedAt: '',
    },
  ],
})

describe('SQLite expenses and existing data', () => {
  beforeEach(() => {
    database = new DatabaseSync(':memory:')
    connection.database = {
      isDBOpen: async () => ({ result: true }),
      execute: async (sql: string) => database.exec(sql),
      query: async (sql: string) => ({ values: database.prepare(sql).all() }),
      beginTransaction: async () => database.exec('BEGIN'),
      commitTransaction: async () => database.exec('COMMIT'),
      rollbackTransaction: async () => database.exec('ROLLBACK'),
      executeSet: async (statements: capSQLiteSet[]) => {
        for (const entry of statements) {
          if (!entry.statement) throw new Error('Missing SQL statement')
          database.prepare(entry.statement).run(...(entry.values as SQLInputValue[]))
        }
      },
    }
  })
  afterEach(() => {
    database.close()
    if (databaseDirectory) {
      unlinkSync(join(databaseDirectory, 'restart.db'))
      rmdirSync(databaseDirectory)
      databaseDirectory = undefined
    }
  })

  it('retains all records after closing and reopening a real SQLite file', async () => {
    database.close()
    databaseDirectory = mkdtempSync(join(tmpdir(), 'pft-restart-test-'))
    const path = join(databaseDirectory, 'restart.db')
    database = new DatabaseSync(path)
    const firstLaunch = new CapacitorSqliteErpRepository()
    await firstLaunch.save(sample())
    database.close()
    database = new DatabaseSync(path)
    const nextLaunch = new CapacitorSqliteErpRepository()
    await expect(nextLaunch.load()).resolves.toEqual(sample())
  })

  it('round-trips Korean expenses and preserves existing payroll records', async () => {
    const repository = new CapacitorSqliteErpRepository()
    await repository.save(sample())
    await expect(repository.load()).resolves.toEqual(sample())
    const revised = sample()
    revised.siteExpenses[0]!.amount = 90000
    await repository.save(revised)
    await expect(repository.load()).resolves.toEqual(revised)
  })

  it('creates the new table for an existing database without removing payroll data', async () => {
    const repository = new CapacitorSqliteErpRepository()
    const legacy = { ...sample(), siteExpenses: [] }
    await repository.save(legacy)
    database.exec('DROP TABLE site_expenses')
    const upgraded = new CapacitorSqliteErpRepository()
    await expect(upgraded.load()).resolves.toEqual(legacy)
    await upgraded.save(sample())
    await expect(upgraded.load()).resolves.toEqual(sample())
  })

  it('rolls back all tables when an expense insert fails during restore', async () => {
    const repository = new CapacitorSqliteErpRepository()
    await repository.save(sample())
    const invalid = sample()
    invalid.sites[0]!.name = '저장되면 안 되는 변경'
    invalid.siteExpenses[0]!.siteId = 'missing-site'
    await expect(repository.save(invalid)).rejects.toThrow(/FOREIGN KEY/)
    await expect(repository.load()).resolves.toEqual(sample())
  })
})
