import {
  CapacitorSQLite,
  SQLiteConnection,
  type capSQLiteSet,
  type SQLiteDBConnection,
} from '@capacitor-community/sqlite'

import { PFT_DATABASE_NAME, PFT_DATABASE_VERSION, PFT_SCHEMA } from '@/database/schema'
import type { ErpRepository } from '@/repositories/erpRepository'
import type {
  AttendanceRecord,
  AttendanceStatus,
  ErpData,
  Site,
  SiteStatus,
  SiteWorkerAssignment,
  Worker,
  WorkerRole,
  PayrollSettlement,
  PayrollSettlementStatus,
  SiteExpense,
} from '@/types/erp'

interface SiteRow {
  id: string
  name: string
  client: string
  address: string
  start_date: string
  end_date: string
  status: SiteStatus
  created_at: string
}

interface SiteExpenseRow {
  id: string
  site_id: string
  expense_date: string
  description: string
  amount: number
  note: string
  created_at: string
  updated_at: string
}

interface WorkerRow {
  id: string
  name: string
  phone: string
  team: string
  role: WorkerRole
  daily_rate: number
  bank_name: string
  account_number: string
  account_holder: string
  active: number
  created_at: string
}

interface AttendanceRow {
  id: string
  work_date: string
  site_id: string
  worker_id: string
  work_role: WorkerRole
  status: AttendanceStatus
  start_time: string
  end_time: string
  overtime_hours: number
  daily_rate: number
  note: string
  created_at: string
  updated_at: string
}

interface SiteWorkerAssignmentRow {
  id: string
  site_id: string
  worker_id: string
  work_role: WorkerRole
  daily_rate: number
  created_at: string
  updated_at: string
}

interface PayrollSettlementRow {
  id: string
  settlement_month: string
  worker_id: string
  status: PayrollSettlementStatus
  settled_amount: number
  paid_date: string
  note: string
  created_at: string
  updated_at: string
}

const siteInsert = `
  INSERT INTO sites
  (id, name, client, address, start_date, end_date, status, created_at)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?)
`

const workerInsert = `
  INSERT INTO workers
  (id, name, phone, team, role, daily_rate, bank_name, account_number,
   account_holder, active, created_at)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`

const attendanceInsert = `
  INSERT INTO attendance_records
  (id, work_date, site_id, worker_id, work_role, status, start_time, end_time,
   overtime_hours, daily_rate, note, created_at, updated_at)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`

const assignmentInsert = `
  INSERT INTO site_worker_assignments
  (id, site_id, worker_id, work_role, daily_rate, created_at, updated_at)
  VALUES (?, ?, ?, ?, ?, ?, ?)
`
const payrollSettlementInsert = `
  INSERT INTO payroll_settlements
  (id, settlement_month, worker_id, status, settled_amount,
   paid_date, note, created_at, updated_at)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
`

export class CapacitorSqliteErpRepository implements ErpRepository {
  readonly kind = 'sqlite' as const

  private readonly sqlite = new SQLiteConnection(CapacitorSQLite)
  private connection: SQLiteDBConnection | undefined

  async load(): Promise<ErpData> {
    const database = await this.getDatabase()
    const siteResult = await database.query('SELECT * FROM sites ORDER BY created_at DESC')
    const workerResult = await database.query('SELECT * FROM workers ORDER BY created_at DESC')
    const assignmentResult = await database.query(
      'SELECT * FROM site_worker_assignments ORDER BY created_at DESC',
    )
    const attendanceResult = await database.query(
      'SELECT * FROM attendance_records ORDER BY work_date DESC, created_at DESC',
    )
    const payrollSettlementResult = await database.query(
      `SELECT *
       FROM payroll_settlements
       ORDER BY settlement_month DESC, created_at DESC`,
    )

    const sites = (siteResult.values ?? []).map((row) => this.toSite(row as SiteRow))
    const expenseResult = await database.query(
      'SELECT * FROM site_expenses ORDER BY expense_date DESC, created_at DESC',
    )
    const siteExpenses = (expenseResult.values ?? []).map((value) => {
      const row = value as SiteExpenseRow
      return {
        id: row.id,
        siteId: row.site_id,
        date: row.expense_date,
        description: row.description,
        amount: Number(row.amount),
        note: row.note,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      }
    })
    const workers = (workerResult.values ?? []).map((row) => this.toWorker(row as WorkerRow))
    const siteWorkerAssignments = (assignmentResult.values ?? []).map((row) =>
      this.toAssignment(row as SiteWorkerAssignmentRow),
    )
    const attendanceRecords = (attendanceResult.values ?? []).map((row) =>
      this.toAttendance(row as AttendanceRow),
    )

    const payrollSettlements = (payrollSettlementResult.values ?? []).map((row) =>
      this.toPayrollSettlement(row as PayrollSettlementRow),
    )

    return {
      sites,
      workers,
      siteWorkerAssignments,
      attendanceRecords,
      payrollSettlements,
      siteExpenses,
    }
  }

  async save(data: ErpData): Promise<void> {
    const database = await this.getDatabase()
    await database.beginTransaction()

    try {
      await database.execute(
        `DELETE FROM site_expenses;
        DELETE FROM payroll_settlements;
        DELETE FROM attendance_records;
        DELETE FROM site_worker_assignments;
        DELETE FROM workers;
        DELETE FROM sites;`,
        false,
      )

      await this.executeSet(database, data.sites.map(this.siteStatement))
      await this.executeSet(database, data.workers.map(this.workerStatement))
      await this.executeSet(database, data.siteWorkerAssignments.map(this.assignmentStatement))
      await this.executeSet(database, data.attendanceRecords.map(this.attendanceStatement))
      await this.executeSet(database, data.payrollSettlements.map(this.payrollSettlementStatement))
      await this.executeSet(database, data.siteExpenses.map(this.expenseStatement))
      await database.commitTransaction()
    } catch (error) {
      await database.rollbackTransaction().catch(() => undefined)
      throw error
    }
  }

  private async getDatabase(): Promise<SQLiteDBConnection> {
    if (this.connection) return this.connection

    await this.sqlite.checkConnectionsConsistency()
    const existing = await this.sqlite.isConnection(PFT_DATABASE_NAME, false)
    const connection = existing.result
      ? await this.sqlite.retrieveConnection(PFT_DATABASE_NAME, false)
      : await this.sqlite.createConnection(
          PFT_DATABASE_NAME,
          false,
          'no-encryption',
          PFT_DATABASE_VERSION,
          false,
        )

    const open = await connection.isDBOpen()
    if (!open.result) await connection.open()

    await connection.execute(PFT_SCHEMA)
    await this.ensureWorkRoleColumn(connection)
    await this.ensureWorkerBankColumns(connection)
    this.connection = connection
    return connection
  }

  private async executeSet(
    database: SQLiteDBConnection,
    statements: capSQLiteSet[],
  ): Promise<void> {
    if (statements.length > 0) await database.executeSet(statements, false)
  }

  private readonly siteStatement = (site: Site): capSQLiteSet => ({
    statement: siteInsert,
    values: [
      site.id,
      site.name,
      site.client,
      site.address,
      site.startDate,
      site.endDate,
      site.status,
      site.createdAt,
    ],
  })

  private readonly expenseStatement = (expense: SiteExpense): capSQLiteSet => ({
    statement: `INSERT INTO site_expenses
      (id, site_id, expense_date, description, amount, note, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    values: [expense.id, expense.siteId, expense.date, expense.description,
      expense.amount, expense.note, expense.createdAt, expense.updatedAt],
  })

  private readonly workerStatement = (worker: Worker): capSQLiteSet => ({
    statement: workerInsert,
    values: [
      worker.id,
      worker.name,
      worker.phone,
      worker.team,
      worker.role,
      worker.dailyRate,
      worker.bankName,
      worker.accountNumber,
      worker.accountHolder,
      worker.active ? 1 : 0,
      worker.createdAt,
    ],
  })

  private readonly attendanceStatement = (record: AttendanceRecord): capSQLiteSet => ({
    statement: attendanceInsert,
    values: [
      record.id,
      record.date,
      record.siteId,
      record.workerId,
      record.workRole,
      record.status,
      record.startTime,
      record.endTime,
      record.overtimeHours,
      record.dailyRate,
      record.note,
      record.createdAt,
      record.updatedAt,
    ],
  })

  private readonly assignmentStatement = (assignment: SiteWorkerAssignment): capSQLiteSet => ({
    statement: assignmentInsert,
    values: [
      assignment.id,
      assignment.siteId,
      assignment.workerId,
      assignment.workRole,
      assignment.dailyRate,
      assignment.createdAt,
      assignment.updatedAt,
    ],
  })

  private readonly payrollSettlementStatement = (settlement: PayrollSettlement): capSQLiteSet => ({
    statement: payrollSettlementInsert,
    values: [
      settlement.id,
      settlement.month,
      settlement.workerId,
      settlement.status,
      settlement.settledAmount,
      settlement.paidDate,
      settlement.note,
      settlement.createdAt,
      settlement.updatedAt,
    ],
  })

  private toSite(row: SiteRow): Site {
    return {
      id: row.id,
      name: row.name,
      client: row.client,
      address: row.address,
      startDate: row.start_date,
      endDate: row.end_date,
      status: row.status,
      createdAt: row.created_at,
    }
  }

  private async ensureWorkRoleColumn(database: SQLiteDBConnection): Promise<void> {
    const columns = await database.query('PRAGMA table_info(attendance_records)')
    const hasWorkRole = (columns.values ?? []).some(
      (column) => (column as { name?: string }).name === 'work_role',
    )

    if (!hasWorkRole) {
      await database.execute(
        "ALTER TABLE attendance_records ADD COLUMN work_role TEXT NOT NULL DEFAULT 'painter'",
        false,
      )
    }
  }

  private async ensureWorkerBankColumns(database: SQLiteDBConnection): Promise<void> {
    const columns = await database.query('PRAGMA table_info(workers)')
    const columnNames = new Set(
      (columns.values ?? []).map((column) => (column as { name?: string }).name),
    )
    const missingColumns = [
      ['bank_name', "TEXT NOT NULL DEFAULT ''"],
      ['account_number', "TEXT NOT NULL DEFAULT ''"],
      ['account_holder', "TEXT NOT NULL DEFAULT ''"],
    ] as const

    for (const [name, definition] of missingColumns) {
      if (!columnNames.has(name)) {
        await database.execute(`ALTER TABLE workers ADD COLUMN ${name} ${definition}`, false)
      }
    }
  }

  private toWorker(row: WorkerRow): Worker {
    return {
      id: row.id,
      name: row.name,
      phone: row.phone,
      team: row.team,
      role: row.role,
      dailyRate: Number(row.daily_rate),
      bankName: row.bank_name ?? '',
      accountNumber: row.account_number ?? '',
      accountHolder: row.account_holder ?? '',
      active: Number(row.active) === 1,
      createdAt: row.created_at,
    }
  }

  private toAssignment(row: SiteWorkerAssignmentRow): SiteWorkerAssignment {
    return {
      id: row.id,
      siteId: row.site_id,
      workerId: row.worker_id,
      workRole: row.work_role,
      dailyRate: Number(row.daily_rate),
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }
  }

  private toAttendance(row: AttendanceRow): AttendanceRecord {
    return {
      id: row.id,
      date: row.work_date,
      siteId: row.site_id,
      workerId: row.worker_id,
      workRole: row.work_role,
      status: row.status,
      startTime: row.start_time,
      endTime: row.end_time,
      overtimeHours: Number(row.overtime_hours),
      dailyRate: Number(row.daily_rate),
      note: row.note,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }
  }

  private toPayrollSettlement(row: PayrollSettlementRow): PayrollSettlement {
    return {
      id: row.id,
      month: row.settlement_month,
      workerId: row.worker_id,
      status: row.status,
      settledAmount: Number(row.settled_amount),
      paidDate: row.paid_date,
      note: row.note,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }
  }
}
